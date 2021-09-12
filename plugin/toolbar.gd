tool
extends Object

const SelectionMode = preload("../utils/selection_mode.gd")
const Extrude = preload("../resources/extrude.gd")
const Subdivide = preload("../resources/subdivide.gd")
const Loop = preload("../resources/loop.gd")

var toolbar = preload("../gui/toolbar/toolbar.tscn").instance()

var _plugin

func _init(plugin):
    _plugin = plugin

func _connect_toolbar_handlers():
    if toolbar.face_select_loop_1.is_connected("pressed", self, "_generate_cube"):
        return

    toolbar.connect("generate_plane", self, "_generate_plane")
    toolbar.connect("generate_cube", self, "_generate_cube")

    toolbar.face_select_loop_1.connect("pressed", self, "_face_select_loop", [0])
    toolbar.face_select_loop_2.connect("pressed", self, "_face_select_loop", [1])
    toolbar.face_extrude.connect("pressed", self, "_face_extrude")

    toolbar.edge_subdivide.connect("pressed", self, "_edge_subdivide")
    toolbar.edge_cut_loop.connect("pressed", self, "_edge_cut_loop")


func startup():
    _plugin.add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)
    toolbar.visible = false
    _connect_toolbar_handlers()
    _plugin.selector.connect("selection_changed", self, "_on_selection_changed")

func teardown():
    toolbar.visible = false
    _plugin.remove_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)
    _plugin.selector.disconnect("selection_changed", self, "_on_selection_changed")
    toolbar.queue_free()

func in_transform_mode():
    return toolbar.transform_toggle.pressed

func _on_selection_changed(mode, editing, _selection):
    if editing:
        toolbar.visible = true
    else:
        toolbar.visible = false

func _generate_cube():
    if not _plugin.selector.editing:
        return
    var pre_edit = _plugin.selector.editing.ply_mesh.begin_edit()
    _generate_plane(false)
    Extrude.face(_plugin.selector.editing.ply_mesh, 0)
    _plugin.selector.editing.ply_mesh.commit_edit("Generate Cube", _plugin.undo_redo, pre_edit)

func _generate_plane(undoable=true):
    if not _plugin.selector.editing:
        return

    var vertexes = [Vector3(0,0,0), Vector3(1,0,0), Vector3(0,0,1), Vector3(1,0,1)]
    var vertex_edges = [0, 0, 3, 3]
    var edge_vertexes = [ 0, 1, 1, 3, 3, 2, 2, 0 ]
    var face_edges = [0, 0]
    var edge_faces = [ 1 , 0, 1 , 0, 1 , 0, 1 , 0 ]
    var edge_edges = [ 3 , 1, 0 , 2, 1 , 3, 2 , 0 ]
    var pre_edit = null
    if undoable:
        pre_edit = _plugin.selector.editing.ply_mesh.begin_edit()
    _plugin.selector.editing.ply_mesh.set_mesh(vertexes, vertex_edges, face_edges, edge_vertexes, edge_faces, edge_edges)
    if undoable:
        _plugin.selector.editing.ply_mesh.commit_edit("Generate Plane", _plugin.undo_redo, pre_edit)

func _face_extrude():
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.FACE or _plugin.selector.selection.size() == 0:
        return
    Extrude.faces(_plugin.selector.editing.ply_mesh, _plugin.selector.selection, _plugin.undo_redo, 1)

func _edge_subdivide():
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.EDGE or _plugin.selector.selection.size() != 1:
        return
    Subdivide.edge(_plugin.selector.editing.ply_mesh, _plugin.selector.selection[0], _plugin.undo_redo)

func _edge_cut_loop():
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.EDGE or _plugin.selector.selection.size() != 1:
        return
    Loop.edge_cut(_plugin.selector.editing.ply_mesh, _plugin.selector.selection[0], _plugin.undo_redo)

func _face_select_loop(offset):
    if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.FACE or _plugin.selector.selection.size() != 1:
        return
    var loop = Loop.get_face_loop(_plugin.selector.editing.ply_mesh, _plugin.selector.selection[0], offset)[0]
    _plugin.selector.set_selection(loop)