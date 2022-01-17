tool
extends Object

const Loop = preload("res://addons/ply/resources/loop.gd")
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


func _point_to_segment_dist(v, a, b):
	var ab = b - a
	var av = v - a
	if av.dot(ab) <= 0.0:
		return av.length()
	var bv = v - b
	if bv.dot(ab) >= 0.0:
		return bv.length()
	return ab.cross(av).length() / ab.length()


func _scan_selection(camera: Camera, event: InputEventMouseButton):
	var ray = camera.project_ray_normal(event.position)
	var ray_pos = camera.project_ray_origin(event.position)
	var selection_mode = _plugin.toolbar.selection_mode

	var hits = _plugin.selection.get_ray_intersection(ray_pos, ray, selection_mode)
	var deselect = true
	if hits.size() > 0:
		deselect = false
		var handled = false
		if event.alt and selection_mode == SelectionMode.FACE:
			var hit_pos = hits[0][3]
			var f = hits[0][1]
			var edges = _plugin.selection._ply_mesh.get_face_edges(f)
			if edges.size() == 4:
				var min_idx = 0
				var min_dist = 1000000
				for idx in range(4):
					var dist = _point_to_segment_dist(
						hit_pos,
						_plugin.selection._ply_mesh.edge_origin(edges[idx]),
						_plugin.selection._ply_mesh.edge_destination(edges[idx])
					)
					if dist < min_dist:
						min_dist = dist
						min_idx = idx
				var loop = Loop.get_face_loop(_plugin.selection._ply_mesh, hits[0][1], min_idx)[0]
				_plugin.selection.selected_faces = loop
				handled = true
		elif event.alt and selection_mode == SelectionMode.EDGE:
			var loop = Loop.get_edge_loop(_plugin.selection._ply_mesh, hits[0][1])
			_plugin.selection.selected_edges = loop
			handled = true
		if not handled:
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
