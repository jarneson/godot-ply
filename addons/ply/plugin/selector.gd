@tool
extends Object

const Loop = preload("res://addons/ply/tools/loop.gd")
const SelectionMode = preload("res://addons/ply/utils/selection_mode.gd")
const PlyEditor = preload("res://addons/ply/nodes/ply.gd")

var _plugin: EditorPlugin

var selection: PlyEditor

enum _MODE {
	NORMAL,
	GSR,
}

enum _GSR_MODE {
	GRAB, SCALE, ROTATE
}

var mode = _MODE.NORMAL
var gsr_mode = _GSR_MODE.GRAB
var gsr_apply = false

enum TransformMode { NONE, TRANSLATE, ROTATE, SCALE, MAX }
enum TransformAxis { X, Y, Z, YZ, XZ, XY, MAX }

var axis = TransformAxis.XZ

func _init(p: EditorPlugin):
	_plugin = p


func startup() -> void:
	_plugin.toolbar.selection_mode_changed.connect(_on_selection_mode_changed)


func teardown() -> void:
	_plugin.toolbar.selection_mode_changed.disconnect(_on_selection_mode_changed)


func _on_selection_mode_changed(_mode) -> void:
	_plugin.selection.select_geometry([], false)


func _point_to_segment_dist(v, a, b) -> float:
	var ab = b - a
	var av = v - a
	if av.dot(ab) <= 0.0:
		return av.length()
	var bv = v - b
	if bv.dot(ab) >= 0.0:
		return bv.length()
	return ab.cross(av).length() / ab.length()

func _box_select(camera: Camera3D, v1: Vector2, v2: Vector2, additive: bool) -> void:
	var is_orthogonal = camera.projection == Camera3D.PROJECTION_ORTHOGONAL
	var z_offset = max(0.0, 5.0 - camera.near)
	var box2d = [
		Vector2(min(v1.x, v2.x), min(v1.y, v2.y)),
		Vector2(max(v1.x, v2.x), min(v1.y, v2.y)),
		Vector2(max(v1.x, v2.x), max(v1.y, v2.y)),
		Vector2(min(v1.x, v2.x), max(v1.y, v2.y)),
	]
	var box3d = [
		camera.project_position(box2d[0], z_offset),
		camera.project_position(box2d[1], z_offset),
		camera.project_position(box2d[2], z_offset),
		camera.project_position(box2d[3], z_offset),
	]
	
	var planes: Array[Plane] = []
	for i in range(4):
		var a = box3d[i]
		var b = box3d[(i+1) % 4]
		if is_orthogonal:
			planes.push_back(Plane((a-b).normalized(), a))
		else:
			planes.push_back(Plane(a, b, camera.global_transform.origin))
	var near = Plane(camera.global_transform.basis[2], camera.global_transform.origin)
	near.d -= camera.near
	planes.push_back(near)
	
	var far = -near
	far.d += camera.far
	planes.push_back(far)
	var hits = _plugin.selection.get_frustum_intersection(planes, _plugin.toolbar.selection_mode, camera)
	_plugin.selection.select_geometry(hits, additive)

func _scan_selection(camera: Camera3D, event: InputEventMouseButton) -> void:
	var ray = camera.project_ray_normal(event.position)
	var ray_pos = camera.project_ray_origin(event.position)
	var selection_mode = _plugin.toolbar.selection_mode

	var hits = _plugin.selection.get_ray_intersection(ray_pos, ray, selection_mode)
	var deselect = true
	if hits.size() > 0:
		deselect = false
		var handled = false
		if event.alt_pressed and selection_mode == SelectionMode.FACE:
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
		elif event.alt_pressed and selection_mode == SelectionMode.EDGE:
			var loop = Loop.get_edge_loop(_plugin.selection._ply_mesh, hits[0][1])
			_plugin.selection.selected_edges = loop
			handled = true
		if not handled:
			_plugin.selection.select_geometry([hits[0]], event.shift_pressed)
	if deselect and not event.shift_pressed:
		_plugin.selection.select_geometry([], false)


var click_position: Vector2
var drag_position: Vector2
var in_click: bool
var in_edit: bool
func handle_input(camera: Camera3D, event: InputEvent) -> bool:
	if _plugin.ignore_inputs:
		return false
	if mode == _MODE.NORMAL:
		if event is InputEventMouseButton:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					if gsr_apply:
						gsr_apply = false
						return true
					if event.pressed:
						if not event.shift_pressed and _plugin.transform_gizmo.select(camera, event.position):
							in_edit = true
							return true
						click_position = event.position
						drag_position = event.position
						in_click = true
						return true
					else:
						var was_in_click = in_click
						in_click = false
						if was_in_click and click_position.distance_to(drag_position) > 5:
							_box_select(camera, click_position, drag_position, event.shift_pressed)
							_plugin.update_overlays()
							return true
							
						if in_edit:
							in_edit = false
							_plugin.transform_gizmo.end_edit()
							return true
						if _plugin.selection:
							_scan_selection(camera, event)
							return true
				MOUSE_BUTTON_RIGHT:
					in_edit = false
					_plugin.transform_gizmo.abort_edit()
		if event is InputEventMouseMotion:
			if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
				var snap = 0.0
				if in_click:
					drag_position = event.position
					_plugin.update_overlays()
					return true
				if event.ctrl_pressed:
					match _plugin.transform_gizmo.edit_mode:
						1:  # translate
							snap = _plugin.snap_values.translate
						2:  # rotate
							snap = _plugin.snap_values.rotate  # to radians?
						3:  # scale
							snap = _plugin.snap_values.scale
				_plugin.transform_gizmo.compute_edit(camera, event.position, snap)
			else:
				_plugin.transform_gizmo.select(camera, event.position, true)
				
		gsr_apply = false
		
		if event is InputEventKey:
			if event.keycode == KEY_G and event.pressed:
				start_grab()
			if event.keycode == KEY_R and event.pressed:
				start_rotate()
			if event.keycode == KEY_S and event.pressed:
				start_scale()
				
	elif mode == _MODE.GSR:
		in_edit = true
		in_click = true
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_G:
				if gsr_mode == _GSR_MODE.GRAB:
					mode = _MODE.NORMAL
				else:
					start_grab()
					
			if event.keycode == KEY_S:
				if gsr_mode == _GSR_MODE.SCALE:
					mode = _MODE.NORMAL
				else:
					start_scale()
			if event.keycode == KEY_R:
				if gsr_mode == _GSR_MODE.ROTATE:
					mode = _MODE.NORMAL
				else:
					start_rotate()
					
			if event.keycode == KEY_X:
				if not event.shift_pressed:
					axis = TransformAxis.X
				else:
					axis = TransformAxis.YZ
			if event.keycode == KEY_Y:
				if not event.shift_pressed:
					axis = TransformAxis.Y
				else:
					axis = TransformAxis.XZ
			if event.keycode == KEY_Z:
				if not event.shift_pressed:
					axis = TransformAxis.Z
				else:
					axis = TransformAxis.XY
		_plugin.transform_gizmo.edit_axis = axis
			
		if event is InputEventMouseMotion:
			var snap = 0.0
			if event.ctrl_pressed:
				match _plugin.transform_gizmo.edit_mode:
					1:  # translate
						snap = _plugin.snap_values.translate
					2:  # rotate
						snap = _plugin.snap_values.rotate  # to radians?
					3:  # scale
						snap = _plugin.snap_values.scale
			_plugin.transform_gizmo.compute_edit(camera, event.position, snap)
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					in_edit = false
					in_click = false
					_plugin.transform_gizmo.end_edit()
					mode = _MODE.NORMAL
					gsr_apply = true
					_plugin.set_timer_ignore_input()
				return true
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				in_edit = false
				in_click = false
				_plugin.transform_gizmo.abort_edit()
				mode = _MODE.NORMAL
				_plugin.set_timer_ignore_input()
				return true
				
	return false

func draw_box_selection(overlay):
	if in_click and click_position.distance_to(drag_position) > 5:
		overlay.draw_rect(Rect2(click_position, drag_position-click_position), Color(0.5, 0.5, 0.7, 0.3), true)
		overlay.draw_rect(Rect2(click_position, drag_position-click_position), Color(0.7, 0.7, 1.0, 1.0), false)

func start_grab():
	mode = _MODE.GSR
	gsr_mode == _GSR_MODE.GRAB
	_plugin.transform_gizmo.in_edit = true
	_plugin.transform_gizmo.edit_mode = TransformMode.TRANSLATE
	axis = TransformAxis.XZ
	_plugin.selection.begin_edit()
	
func start_rotate():
	mode = _MODE.GSR
	gsr_mode == _GSR_MODE.ROTATE
	_plugin.transform_gizmo.in_edit = true
	_plugin.transform_gizmo.edit_mode = TransformMode.ROTATE
	axis = TransformAxis.Y
	_plugin.selection.begin_edit()
	
func start_scale():
	mode = _MODE.GSR
	gsr_mode == _GSR_MODE.SCALE
	_plugin.transform_gizmo.in_edit = true
	_plugin.transform_gizmo.edit_mode = TransformMode.SCALE
	axis = TransformAxis.XZ
	_plugin.selection.begin_edit()
