@tool
extends Object

const Loop = preload("res://addons/ply/tools/loop.gd")
const SelectionMode = preload("res://addons/ply/utils/selection_mode.gd")
const PlyEditor = preload("res://addons/ply/nodes/ply.gd")
const OperationMode = preload("res://addons/ply/utils/operation_mode.gd")
const GsrMode = preload("res://addons/ply/utils/gsr_mode.gd")
const TransformAxis = preload("res://addons/ply/utils/transform_axis.gd")
const TransformMode = preload("res://addons/ply/utils/transform_mode.gd")

var _plugin: EditorPlugin
var _vertex_painting_toolbar : Vertex_Painting_Toolbar
var selection: PlyEditor

var mode = OperationMode.NORMAL
var gsr_mode = GsrMode.GRAB
var gsr_applied = false

var vertex_painting_operating = false
var vertex_painting_timer = 0.0
var vertex_painting_camera 
var vertex_painting_event 

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
	match mode:
		OperationMode.NORMAL:
			if gsr_applied:
				gsr_applied = false
				return true
			if event is InputEventMouseButton:
				match event.button_index:
					MOUSE_BUTTON_LEFT:
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
					
					if in_click:
						drag_position = event.position
						_plugin.update_overlays()
						return true
					var snap = get_snap(event)
					_plugin.transform_gizmo.compute_edit(camera, event.position, snap)
				else:
					_plugin.transform_gizmo.select(camera, event.position, true)
			
			if event is InputEventKey and event.pressed:
				if event.keycode == KEY_G:
					start_grab()
				if event.keycode == KEY_R:
					start_rotate()
				if event.keycode == KEY_S and not event.ctrl_pressed:
					start_scale()
				if event.keycode == KEY_A:
					if not event.alt_pressed:
						try_select_all()
					else:
						_plugin.selection.select_geometry([], false)
					
		OperationMode.GSR:
			if event is InputEventKey and event.pressed:
				if event.keycode == KEY_G:
					if gsr_mode == GsrMode.GRAB:
						mode = OperationMode.NORMAL
					else:
						start_grab()
						
				if event.keycode == KEY_S and not event.ctrl_pressed:
					if gsr_mode == GsrMode.SCALE:
						mode = OperationMode.NORMAL
					else:
						start_scale()
				if event.keycode == KEY_R:
					if gsr_mode == GsrMode.ROTATE:
						mode = OperationMode.NORMAL
					else:
						start_rotate()
						
				if event.keycode == KEY_X:
					if event.shift_pressed and gsr_mode != GsrMode.ROTATE:
						axis = TransformAxis.YZ
					elif not event.shift_pressed:
						axis = TransformAxis.X
				if event.keycode == KEY_Y:
					if event.shift_pressed and gsr_mode != GsrMode.ROTATE:
						axis = TransformAxis.XZ
					elif not event.shift_pressed:
						axis = TransformAxis.Y
				if event.keycode == KEY_Z  and not event.ctrl_pressed:
					if event.shift_pressed and gsr_mode != GsrMode.ROTATE:
						axis = TransformAxis.XY
					elif not event.shift_pressed:
						axis = TransformAxis.Z
						
			_plugin.transform_gizmo.edit_axis = axis
				
			if event is InputEventMouseMotion:
				var snap = get_snap(event)
				_plugin.transform_gizmo.compute_edit(camera, event.position, snap)
				
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT:
					if event.pressed:
						in_edit = false
						in_click = false
						_plugin.transform_gizmo.end_edit()
						mode = OperationMode.NORMAL
						_plugin.set_timer_ignore_input()
						gsr_applied = true
					return true
				elif event.button_index == MOUSE_BUTTON_RIGHT:
					in_edit = false
					in_click = false
					_plugin.transform_gizmo.abort_edit()
					mode = OperationMode.NORMAL
					_plugin.set_timer_ignore_input()
					gsr_applied = true
					return true
					
		OperationMode.VERTEX_PAINTING:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				if event.is_pressed():
					vertex_painting_operating = true
					in_click = true
				if event.is_released():
					vertex_painting_operating = false
					in_click = false
				return true
						
			if event is InputEventMouseMotion:
				if not vertex_painting_operating and in_click:
					vertex_painting_operating = true
					
			if vertex_painting_operating:
				var position = camera.get_viewport().get_mouse_position()
				var start = position + Vector2(-16,-16)
				var end = position + Vector2(16,16)
				_box_select(camera, start, end, false)
				_plugin.update_overlays()
				vertex_painting_try()
				vertex_painting_operating = false
				_plugin.set_timer_ignore_input()
				return true
			
	return false

func draw_box_selection(overlay):
	if in_click and click_position.distance_to(drag_position) > 5:
		overlay.draw_rect(Rect2(click_position, drag_position-click_position), Color(0.5, 0.5, 0.7, 0.3), true)
		overlay.draw_rect(Rect2(click_position, drag_position-click_position), Color(0.7, 0.7, 1.0, 1.0), false)

func start_grab():
	mode = OperationMode.GSR
	gsr_mode = GsrMode.GRAB
	_plugin.transform_gizmo.in_edit = true
	_plugin.transform_gizmo.edit_mode = TransformMode.TRANSLATE
	axis = TransformAxis.XZ
	_plugin.selection.begin_edit()
	
func start_rotate():
	mode = OperationMode.GSR
	gsr_mode = GsrMode.ROTATE
	_plugin.transform_gizmo.in_edit = true
	_plugin.transform_gizmo.edit_mode = TransformMode.ROTATE
	axis = TransformAxis.Y
	_plugin.selection.begin_edit()
	
func start_scale():
	mode = OperationMode.GSR
	gsr_mode = GsrMode.SCALE
	_plugin.transform_gizmo.in_edit = true
	_plugin.transform_gizmo.edit_mode = TransformMode.SCALE
	axis = TransformAxis.XZ
	_plugin.selection.begin_edit()

var toolbar_selection_mode_prev = SelectionMode.MESH
func vertex_painting_start():
	mode = OperationMode.VERTEX_PAINTING
	toolbar_selection_mode_prev = _plugin.toolbar.selection_mode
	_plugin.toolbar.selection_mode = SelectionMode.VERTEX
	
func vertex_painting_end():
	mode = OperationMode.NORMAL
	_plugin.toolbar.selection_mode = toolbar_selection_mode_prev

func vertex_painting_try():
	if _plugin.selection:
		var mesh = _plugin.selection
		var color = _plugin.vertexPainting_color_picker.get_color()
		for idx in mesh.selected_vertices:
			_plugin.selection.ply_mesh.set_vertex_color(idx, color)
			
		_plugin.selection.ply_mesh.emit_change_signal()

func get_snap(event):
	var snap = 0.0
	if _vertex_painting_toolbar.snap_enabled(): #snap is activated
		match _plugin.transform_gizmo.edit_mode:
			1:  # translate
				snap = _plugin.snap_values.translate
			2:  # rotate
				snap = _plugin.snap_values.rotate  # to radians?
			3:  # scale
				snap = _plugin.snap_values.scale
		if event.ctrl_pressed:
			snap = 0.0
	else:
		#snap is inactive
		if event.ctrl_pressed:
			match _plugin.transform_gizmo.edit_mode:
				1:  # translate
					snap = _plugin.snap_values.translate
				2:  # rotate
					snap = _plugin.snap_values.rotate  # to radians?
				3:  # scale
					snap = _plugin.snap_values.scale
		else:
			snap = 0.0
	return snap

func try_select_all():
	if not _plugin.toolbar:
		return
	var selection_mode = _plugin.toolbar.selection_mode
	match selection_mode :
		SelectionMode.FACE:
			var arr = []
			#for i in _plugin.selection.ply_mesh.vertex_count():
			for i in range(_plugin.selection.ply_mesh.face_surfaces.size()):
				var arr_data = []
				arr_data.append("F")
				arr_data.append(i)
				arr.append(arr_data)
			_plugin.selection.select_geometry(arr, false)
		SelectionMode.VERTEX:
			var arr = []
			for i in _plugin.selection.ply_mesh.vertex_count():
				var arr_data = []
				arr_data.append("V")
				arr_data.append(i)
				arr.append(arr_data)
			_plugin.selection.select_geometry(arr, false)
