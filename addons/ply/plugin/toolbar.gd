tool
extends Object

const SelectionMode = preload("../utils/selection_mode.gd")
const Extrude = preload("../resources/extrude.gd")
const Subdivide = preload("../resources/subdivide.gd")
const Triangulate = preload("../resources/triangulate.gd")
const Loop = preload("../resources/loop.gd")
const Collapse = preload("../resources/collapse.gd")
const Connect = preload("../resources/connect.gd")
const Generate = preload("../resources/generate.gd")
const ExportMesh = preload("../resources/export.gd")

var toolbar = preload("../gui/toolbar/toolbar.tscn").instance()

var _plugin

func _init(plugin):
    _plugin = plugin

func _connect_toolbar_handlers():
    if toolbar.face_select_loop_1.is_connected("pressed", self, "_generate_cube"):
        return

    toolbar.mesh_export_to_obj.connect("pressed", self, "_export_to_obj")

    toolbar.connect("generate_plane", self, "_generate_plane")
    toolbar.connect("generate_cube", self, "_generate_cube")
    toolbar.connect("generate_mesh", self, "_generate_mesh")

    toolbar.face_select_loop_1.connect("pressed", self, "_face_select_loop", [0])
    toolbar.face_select_loop_2.connect("pressed", self, "_face_select_loop", [1])
    toolbar.face_extrude.connect("pressed", self, "_face_extrude")
    toolbar.face_connect.connect("pressed", self, "_face_connect")
    toolbar.face_subdivide.connect("pressed", self, "_face_subdivide")
    toolbar.face_triangulate.connect("pressed", self, "_face_triangulate")
    toolbar.connect("set_face_surface", self, "_set_face_surface")

    toolbar.edge_select_loop.connect("pressed", self, "_edge_select_loop")
    toolbar.edge_cut_loop.connect("pressed", self, "_edge_cut_loop")
    toolbar.edge_subdivide.connect("pressed", self, "_edge_subdivide")
    toolbar.edge_collapse.connect("pressed", self, "_edge_collapse")


func startup():
    _plugin.add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT , toolbar)
    toolbar.visible = false
    _connect_toolbar_handlers()
    _plugin.selector.connect("selection_changed", self, "_on_selection_changed")

func teardown():
    toolbar.visible = false
    _plugin.remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT , toolbar)
    _plugin.selector.disconnect("selection_changed", self, "_on_selection_changed")
    toolbar.queue_free()

func in_transform_mode():
    return toolbar.transform_toggle.pressed

func _on_selection_changed(mode, editing, _selection):
    if editing:
        toolbar.visible = true
    else:
        toolbar.visible = false

func _generate_cube(params = null):
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing:
        return
    var size = 1
    var subdivisions = 0
    if params != null:
        size = params[0]
        subdivisions = params[1]
    var pre_edit = _plugin.selector.editing.ply_mesh.begin_edit()
    var vertexes = [
        size*Vector3(-0.5,0,-0.5),
        size*Vector3(0.5,0,-0.5),
        size*Vector3(0.5,0,0.5),
        size*Vector3(-0.5,0,0.5)
    ]
    Generate.nGon(_plugin.selector.editing.ply_mesh, vertexes)
    Extrude.faces(_plugin.selector.editing.ply_mesh, [0], null, size)
    for i in range(subdivisions):
        Subdivide.object(_plugin.selector.editing.ply_mesh)
    _plugin.selector.editing.ply_mesh.commit_edit("Generate Cube", _plugin.undo_redo, pre_edit)

func _generate_plane(params = null):
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing:
        return

    var size = 1
    var subdivisions = 0
    if params != null:
        size = params[0]
        subdivisions = params[1]

    var vertexes = [
        size*Vector3(-0.5,0,-0.5),
        size*Vector3(0.5,0,-0.5),
        size*Vector3(0.5,0,0.5),
        size*Vector3(-0.5,0,0.5)
    ]

    var pre_edit = _plugin.selector.editing.ply_mesh.begin_edit()
    Generate.nGon(_plugin.selector.editing.ply_mesh, vertexes)
    for i in range(subdivisions):
        Subdivide.object(_plugin.selector.editing.ply_mesh)
    _plugin.selector.editing.ply_mesh.commit_edit("Generate Plane", _plugin.undo_redo, pre_edit)

func _generate_cylinder(params = null):
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing:
        return

    var radius = 1
    var depth = 1
    var num_points = 8
    var num_segments = 1
    if params:
        radius = params[0]
        depth = params[1]
        num_points = params[2]
        num_segments = params[3]

    var vertexes = []
    for i in range(num_points):
        vertexes.push_back(Vector3(
            radius*cos(float(i)/num_points*2*PI),
            -depth/2,
            radius*sin(float(i)/num_points*2*PI)
        ))

    var pre_edit = _plugin.selector.editing.ply_mesh.begin_edit()
    Generate.nGon(_plugin.selector.editing.ply_mesh, vertexes)
    for i in range(num_segments):
        Extrude.faces(_plugin.selector.editing.ply_mesh, [0], null, depth / num_segments)
    _plugin.selector.editing.ply_mesh.commit_edit("Generate Cylinder", _plugin.undo_redo, pre_edit)

func _generate_icosphere(params = null):
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing:
        return
    
    var radius = 1.0
    var subdivides = 0
    if params:
        radius = params[0]
        subdivides = params[1]
    
    var pre_edit = _plugin.selector.editing.ply_mesh.begin_edit()
    Generate.icosphere(_plugin.selector.editing.ply_mesh, radius, subdivides)
    _plugin.selector.editing.ply_mesh.commit_edit("Generate Icosphere", _plugin.undo_redo, pre_edit)

func _generate_mesh(arr):
    if _plugin.ignore_inputs:
        return
    var shape = arr[0]
    var params = arr[1]
    match shape:
        "Plane":
            _generate_plane(params)
        "Cube":
            _generate_cube(params)
        "Icosphere":
            _generate_icosphere(params)
        "Cylinder":
            _generate_cylinder(params)


func _face_select_loop(offset):
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.FACE or _plugin.selector.selection.size() != 1:
        return
    var loop = Loop.get_face_loop(_plugin.selector.editing.ply_mesh, _plugin.selector.selection[0], offset)[0]
    _plugin.selector.set_selection(loop)

func _face_extrude():
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.FACE or _plugin.selector.selection.size() == 0:
        return
    Extrude.faces(_plugin.selector.editing.ply_mesh, _plugin.selector.selection, _plugin.undo_redo, 1)

func _face_connect():
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.FACE or _plugin.selector.selection.size() != 2:
        return
    Connect.faces(_plugin.selector.editing.ply_mesh, _plugin.selector.selection[0], _plugin.selector.selection[1], _plugin.undo_redo)

func _face_subdivide():
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.FACE:
        return
    Subdivide.faces(_plugin.selector.editing.ply_mesh, _plugin.selector.selection, _plugin.undo_redo)

func _face_triangulate():
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.FACE:
        return
    var pre_edit = _plugin.selector.editing.ply_mesh.begin_edit()
    Triangulate.faces(_plugin.selector.editing.ply_mesh, _plugin.selector.selection)
    _plugin.selector.editing.ply_mesh.commit_edit("Triangulate Faces", _plugin.undo_redo, pre_edit)

func _set_face_surface(s):
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.FACE or _plugin.selector.selection.size() == 0:
        return
    var pre_edit = _plugin.selector.editing.ply_mesh.begin_edit()
    for f_idx in _plugin.selector.selection:
        _plugin.selector.editing.ply_mesh.set_face_surface(f_idx, s)
    _plugin.selector.editing.ply_mesh.commit_edit("Paint Face", _plugin.undo_redo, pre_edit)

func _edge_select_loop():
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.EDGE or _plugin.selector.selection.size() != 1:
        return
    var loop = Loop.get_edge_loop(_plugin.selector.editing.ply_mesh, _plugin.selector.selection[0])
    _plugin.selector.set_selection(loop)

func _edge_cut_loop():
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.EDGE or _plugin.selector.selection.size() != 1:
        return
    Loop.edge_cut(_plugin.selector.editing.ply_mesh, _plugin.selector.selection[0], _plugin.undo_redo)

func _edge_subdivide():
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.EDGE or _plugin.selector.selection.size() != 1:
        return
    Subdivide.edge(_plugin.selector.editing.ply_mesh, _plugin.selector.selection[0], _plugin.undo_redo)

func _edge_collapse():
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.EDGE or _plugin.selector.selection.size() == 0:
        return
    if Collapse.edges(_plugin.selector.editing.ply_mesh, _plugin.selector.selection, _plugin.undo_redo):
        _plugin.selector.set_selection([])

func _export_to_obj():
    if _plugin.ignore_inputs:
        return
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.MESH:
        return
    var fd = FileDialog.new()
    fd.set_filters(PoolStringArray(["*.obj ; OBJ Files"]))
    var base_control = _plugin.get_editor_interface().get_base_control()
    base_control.add_child(fd)
    fd.popup_centered(Vector2(480, 600))
    var file_name = yield(fd, "file_selected")
    var obj_file = File.new()
    obj_file.open(file_name, File.WRITE)
    ExportMesh.export_to_obj(_plugin.selector.editing.ply_mesh, obj_file)