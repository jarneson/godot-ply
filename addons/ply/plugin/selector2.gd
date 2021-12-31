tool
extends Object

signal selection_changed(selection)

const SelectionMode = preload("../utils/selection_mode.gd")
const PlyEditor = preload("../nodes/ply2.gd")

var _plugin: EditorPlugin
var _editor_selection: EditorSelection

var selection: PlyEditor

func _init(p: EditorPlugin):
    _plugin = p

func startup():
    _editor_selection = _plugin.get_editor_interface().get_selection()
    _editor_selection.connect("selection_changed", self, "_on_selection_change")
    _plugin.toolbar2.toolbar.connect("selection_mode_changed", self, "_on_selection_mode_changed")
    pass

func teardown():
    pass

func _on_selection_change():
    _plugin.transform_gizmo.transform = null
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
        emit_signal("selection_changed", selection)

func _on_selection_mode_changed(_mode):
    selection.select_geometry([], false)

const fuzziness = {
    SelectionMode.MESH: 0.0001,
    SelectionMode.FACE: 0.0001,
    SelectionMode.EDGE: 0.01,
    SelectionMode.VERTEX: 0.007,
}

func _scan_selection(camera: Camera, event: InputEventMouseButton):
    var ray = camera.project_ray_normal(event.position) 
    var ray_pos = camera.project_ray_origin(event.position) 
    var selection_mode = _plugin.toolbar2.toolbar.selection_mode

    var hits = selection.get_ray_intersection(ray_pos, ray, selection_mode)
    var deselect = true
    if hits.size() > 0:
        if hits[0][2]/hits[0][3] < fuzziness[selection_mode]:
            deselect = false
            selection.select_geometry([hits[0]], event.shift)
    if deselect and not event.shift:
        selection.select_geometry([], false)

func handle_input(camera: Camera, event: InputEvent):
    if _plugin.ignore_inputs:
        return false
    if event is InputEventMouseButton:
        match event.button_index:
            BUTTON_LEFT:
                if event.pressed:
                    if _plugin.transform_gizmo.select(camera, event.position):
                        return true
                    if selection:
                        _scan_selection(camera, event)
                        return true
                else:
                    _plugin.transform_gizmo.end_edit()
    if event is InputEventMouseMotion:
        _plugin.transform_gizmo.select(camera, event.position, true)
        if event.button_mask & BUTTON_MASK_LEFT:
            _plugin.transform_gizmo.compute_edit(camera, event.position)
    return false