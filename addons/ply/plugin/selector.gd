tool
extends Object

const SelectionMode = preload("res://addons/ply/utils/selection_mode.gd")
const PlyEditor = preload("res://addons/ply/nodes/ply.gd")

var _plugin: EditorPlugin

var selection: PlyEditor


func _init(p: EditorPlugin):
	_plugin = p


func startup():
	_plugin.toolbar.connect("selection_mode_changed", self, "_on_selection_mode_changed")


func teardown():
	_plugin.toolbar.disconnect("selection_mode_changed", self, "_on_selection_mode_changed")


func _on_selection_mode_changed(_mode):
	_plugin.selection.select_geometry([], false)


const fuzziness = {
	SelectionMode.MESH: 0.0001,
	SelectionMode.FACE: 0.0001,
	SelectionMode.EDGE: 0.01,
	SelectionMode.VERTEX: 0.007,
}


func _scan_selection(camera: Camera, event: InputEventMouseButton):
	var ray = camera.project_ray_normal(event.position)
	var ray_pos = camera.project_ray_origin(event.position)
	var selection_mode = _plugin.toolbar.selection_mode

	var hits = _plugin.selection.get_ray_intersection(ray_pos, ray, selection_mode)
	var deselect = true
	if hits.size() > 0:
		if hits[0][2] / hits[0][3] < fuzziness[selection_mode]:
			deselect = false
			_plugin.selection.select_geometry([hits[0]], event.shift)
	if deselect and not event.shift:
		_plugin.selection.select_geometry([], false)


func handle_input(camera: Camera, event: InputEvent):
	if _plugin.ignore_inputs:
		return false
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_LEFT:
				if event.pressed:
					if _plugin.transform_gizmo.select(camera, event.position):
						return true
					if _plugin.selection:
						_scan_selection(camera, event)
						return true
				else:
					_plugin.transform_gizmo.end_edit()
			BUTTON_RIGHT:
				_plugin.transform_gizmo.abort_edit()
	if event is InputEventMouseMotion:
		if event.button_mask & BUTTON_MASK_LEFT:
			var snap = null
			if event.control:
				match _plugin.transform_gizmo.edit_mode:
					1:  # translate
						snap = 1.0
					2:  # rotate
						snap = 15.0  # to radians?
					3:  # scale
						snap = 0.1
			_plugin.transform_gizmo.compute_edit(camera, event.position, snap)
		else:
			_plugin.transform_gizmo.select(camera, event.position, true)
	return false
