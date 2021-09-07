tool
extends EditorPlugin

"""
██████╗ ██████╗ ███████╗██╗      ██████╗  █████╗ ██████╗ ███████╗
██╔══██╗██╔══██╗██╔════╝██║     ██╔═══██╗██╔══██╗██╔══██╗██╔════╝
██████╔╝██████╔╝█████╗  ██║     ██║   ██║███████║██║  ██║███████╗
██╔═══╝ ██╔══██╗██╔══╝  ██║     ██║   ██║██╔══██║██║  ██║╚════██║
██║     ██║  ██║███████╗███████╗╚██████╔╝██║  ██║██████╔╝███████║
╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝
"""
const Selector = preload("./plugin/selector.gd")
const SpatialEditor = preload("./plugin/spatial_editor.gd")

const PlyNode = preload("./nodes/ply.gd")
const Face = preload("./gui/face.gd")
const Edge = preload("./gui/edge.gd")
const Editor = preload("./gui/editor.gd")
const Handle = preload("./plugin/handle.gd")

const DEBUG = true
func debug_print(s):
    if not DEBUG:
        return
    print(s)

var hotbar = preload("./gui/hotbar.tscn").instance()

var spatial_editor = null
var selector = null

"""
███████╗████████╗ █████╗ ██████╗ ████████╗██╗   ██╗██████╗   ██╗████████╗███████╗ █████╗ ██████╗ ██████╗  ██████╗ ██╗    ██╗███╗   ██╗
██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝██║   ██║██╔══██╗ ██╔╝╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██║    ██║████╗  ██║
███████╗   ██║   ███████║██████╔╝   ██║   ██║   ██║██████╔╝██╔╝    ██║   █████╗  ███████║██████╔╝██║  ██║██║   ██║██║ █╗ ██║██╔██╗ ██║
╚════██║   ██║   ██╔══██║██╔══██╗   ██║   ██║   ██║██╔═══╝██╔╝     ██║   ██╔══╝  ██╔══██║██╔══██╗██║  ██║██║   ██║██║███╗██║██║╚██╗██║
███████║   ██║   ██║  ██║██║  ██║   ██║   ╚██████╔╝██║   ██╔╝      ██║   ███████╗██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝██║ ╚████║
╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝   ╚═╝       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝
"""
func _enter_tree() -> void:
    add_custom_type("PlyInstance", "MeshInstance", preload("./nodes/ply.gd"), preload("./icon.png"))

    hotbar.hide()

    add_control_to_container(CONTAINER_SPATIAL_EDITOR_SIDE_LEFT , hotbar)
    
    connect("scene_changed", self, "_on_scene_change")

    selector = Selector.new(self)
    selector.startup()
    selector.connect("selection_changed", self, "_on_selection_changed")
    spatial_editor = SpatialEditor.new(self)
    spatial_editor.startup()

    var scene_root = get_tree().get_edited_scene_root()
    if scene_root:
        _on_scene_change(scene_root)

    debug_print("Ply initialized")

func _exit_tree() -> void:
    remove_custom_type("PlyInstance")

    spatial_editor.teardown()
    selector.teardown()

    hotbar.queue_free()

    disconnect("scene_changed", self, "_on_scene_change")
    debug_print("Ply torn down")

func _on_scene_change(root):
    spatial_editor.set_scene(root)
    selector.set_scene(root)

"""
██╗  ██╗ ██████╗ ████████╗██████╗  █████╗ ██████╗     ██╗     ██╗███████╗████████╗███████╗███╗   ██╗███████╗██████╗ ███████╗
██║  ██║██╔═══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗    ██║     ██║██╔════╝╚══██╔══╝██╔════╝████╗  ██║██╔════╝██╔══██╗██╔════╝
███████║██║   ██║   ██║   ██████╔╝███████║██████╔╝    ██║     ██║███████╗   ██║   █████╗  ██╔██╗ ██║█████╗  ██████╔╝███████╗
██╔══██║██║   ██║   ██║   ██╔══██╗██╔══██║██╔══██╗    ██║     ██║╚════██║   ██║   ██╔══╝  ██║╚██╗██║██╔══╝  ██╔══██╗╚════██║
██║  ██║╚██████╔╝   ██║   ██████╔╝██║  ██║██║  ██║    ███████╗██║███████║   ██║   ███████╗██║ ╚████║███████╗██║  ██║███████║
╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝    ╚══════╝╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚══════╝
"""
func _generate_cube():
    if not selector.editing:
        return
    _generate_plane()
    Extrude.face(selector.editing.ply_mesh, 0)

func _generate_plane():
    if not selector.editing:
        return
    var vertexes = [Vector3(0,0,0), Vector3(1,0,0), Vector3(0,0,1), Vector3(1,0,1)]
    var vertex_edges = [0, 0, 3, 3]
    var edge_vertexes = [ 0, 1, 1, 3, 3, 2, 2, 0 ]
    var face_edges = [0, 0]
    var edge_faces = [ 1 , 0, 1 , 0, 1 , 0, 1 , 0 ]
    var edge_edges = [ 3 , 1, 0 , 2, 1 , 3, 2 , 0 ]
    selector.editing.ply_mesh.set_mesh(vertexes, vertex_edges, face_edges, edge_vertexes, edge_faces, edge_edges)

const Extrude = preload("./resources/extrude.gd")
const Subdivide = preload("./resources/subdivide.gd")
const Loop = preload("./resources/loop.gd")

func _extrude():
    if not selector.editing:
        return
    if selector.selection.size() == 0:
        return
    if selector.selection.size() > 1:
        print("NYI: multiselect")
        return
    if not selector.selection[0] is Face:
        return
    Extrude.face(selector.editing.ply_mesh, selector.selection[0].face_idx)

func _subdivide_edge():
    if not selector.editing:
        return
    if selector.selection.size() == 0:
        return
    if selector.selection.size() > 1:
        print("NYI: multiselect")
        return
    if not selector.selection[0] is Edge:
        return
    Subdivide.edge(selector.editing.ply_mesh, selector.selection[0].edge_idx)

func _select_face_loop(offset):
    if not selector.editing:
        return
    if selector.selection.size() != 1:
        return
    if not selector.selection[0] is Face:
        return
    var loop = Loop.get_face_loop(selector.editing.ply_mesh, selector.selection[0].face_idx, offset)
    selector.set_selection(spatial_editor.get_nodes_for_indexes(loop))
    


"""
██╗   ██╗██╗███████╗██╗██████╗ ██╗██╗     ██╗████████╗██╗   ██╗
██║   ██║██║██╔════╝██║██╔══██╗██║██║     ██║╚══██╔══╝╚██╗ ██╔╝
██║   ██║██║███████╗██║██████╔╝██║██║     ██║   ██║    ╚████╔╝ 
╚██╗ ██╔╝██║╚════██║██║██╔══██╗██║██║     ██║   ██║     ╚██╔╝  
 ╚████╔╝ ██║███████║██║██████╔╝██║███████╗██║   ██║      ██║   
  ╚═══╝  ╚═╝╚══════╝╚═╝╚═════╝ ╚═╝╚══════╝╚═╝   ╚═╝      ╚═╝   
"""
func _on_selection_changed(mode, editing, selection):
    make_visible(editing != null)

func make_visible(vis):
    hotbar.set_visible(vis)
    if not hotbar.generate_cube.is_connected("pressed", self, "_generate_cube"):
        hotbar.generate_cube.connect("pressed", self, "_generate_cube")
        hotbar.generate_plane.connect("pressed", self, "_generate_plane")
        hotbar.face_extrude.connect("pressed", self, "_extrude")
        hotbar.edge_subdivide.connect("pressed", self, "_subdivide_edge")
        hotbar.face_select_loop_0.connect("pressed", self, "_select_face_loop", [0])
        hotbar.face_select_loop_1.connect("pressed", self, "_select_face_loop", [1])