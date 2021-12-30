tool
extends Object

const PlyEditor = preload("../nodes/ply2.gd")

var _plugin: EditorPlugin
var _editor_selection: EditorSelection

var selection: PlyEditor

func _init(p: EditorPlugin):
    _plugin = p

func startup():
    _editor_selection = _plugin.get_editor_interface().get_selection()
    _editor_selection.connect("selection_changed", self, "_on_selection_change")
    pass

func teardown():
    pass

func _on_selection_change():
    var new_selection = null
    var selected_nodes = _editor_selection.get_selected_nodes()
    if selected_nodes.size() != 1:
        return
    if selected_nodes[0] is PlyEditor:
        new_selection = selected_nodes[0]
    if new_selection != selection:
        if selection:
            selection.selected = false
        selection = new_selection
        if selection:
            selection.selected = true

func handle_click(camera: Camera, event: InputEventMouseButton):
    if !event.pressed or !selection or _plugin.ignore_inputs:
        return false
    var ray = camera.project_ray_normal(event.position) # todo: viewport scale
    var ray_pos = camera.project_ray_origin(event.position) # todo: viewport scale
    print("1: ", selection.get_ray_intersection(ray_pos, ray)[0])
    print("2: ", selection.get_ray_intersection(ray_pos, ray)[1])
    print("3: ", selection.get_ray_intersection(ray_pos, ray)[2])
    return true