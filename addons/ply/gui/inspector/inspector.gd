tool
extends VBoxContainer

const GizmoMode = preload("res://addons/ply/utils/gizmo_mode.gd")
const SpinSlider = preload("res://addons/ply/gui/inspector/spin_slider.gd")

onready var tool_grid = $"G"
onready var translate_container = $"G/TranslateInputs"
var translate_x
var translate_y
var translate_z
onready var rotate_container = $"G/RotateInputs"
var rotate_x
var rotate_y
var rotate_z
onready var scale_container = $"G/ScaleInputs"
var scale_x
var scale_y
var scale_z

onready var vertex_count = $"V/VertexCount"
onready var edge_count = $"V/EdgeCount"
onready var face_count = $"V/FaceCount"
onready var selection_text = $"V/Selection"

var plugin = null
var gizmo_transform


func _prep_slider(s, l, mn, mx, st, mod, axis) -> void:
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.label = l
	s.min_value = mn
	s.max_value = mx
	s.step = st
	s.allow_greater = true
	s.allow_lesser = true

	s.connect("edit_started", self, "_transform_axis_edit_started", [s, mod, axis])
	s.connect("value_changed", self, "_transform_axis_value_changed", [s, mod, axis])
	s.connect("edit_committed", self, "_transform_axis_edit_committed", [s, mod, axis])


func _ready() -> void:
	current_gizmo_mode = plugin.toolbar.gizmo_mode

	translate_x = SpinSlider.new()
	_prep_slider(translate_x, "x", -65535, 65535, 0.001, "Translate", "X")
	translate_y = SpinSlider.new()
	_prep_slider(translate_y, "y", -65535, 65535, 0.001, "Translate", "Y")
	translate_z = SpinSlider.new()
	_prep_slider(translate_z, "z", -65535, 65535, 0.001, "Translate", "Z")
	translate_container.add_child(translate_x)
	translate_container.add_child(translate_y)
	translate_container.add_child(translate_z)

	rotate_x = SpinSlider.new()
	_prep_slider(rotate_x, "x", -180, 180, 1, "Rotate", "X")
	rotate_y = SpinSlider.new()
	_prep_slider(rotate_y, "y", -180, 180, 1, "Rotate", "Y")
	rotate_z = SpinSlider.new()
	_prep_slider(rotate_z, "z", -180, 180, 1, "Rotate", "Z")
	rotate_container.add_child(rotate_x)
	rotate_container.add_child(rotate_y)
	rotate_container.add_child(rotate_z)

	scale_x = SpinSlider.new()
	_prep_slider(scale_x, "x", -65535, 65535, 0.001, "Scale", "X")
	scale_y = SpinSlider.new()
	_prep_slider(scale_y, "y", -65535, 65535, 0.001, "Scale", "Y")
	scale_z = SpinSlider.new()
	_prep_slider(scale_z, "z", -65535, 65535, 0.001, "Scale", "Z")
	scale_container.add_child(scale_x)
	scale_container.add_child(scale_y)
	scale_container.add_child(scale_z)

	plugin.connect("selection_changed", self, "_on_selection_changed")
	plugin.toolbar.connect("gizmo_mode_changed", self, "_on_gizmo_mode_changed")

	rotate_x.value = 0
	rotate_y.value = 0
	rotate_z.value = 0
	scale_x.value = 1
	scale_y.value = 1
	scale_z.value = 1

	tool_grid.hide()


func _get_origin() -> Vector3:
	match current_gizmo_mode:
		GizmoMode.GLOBAL:
			return gizmo_transform.origin
		GizmoMode.LOCAL:
			return current_selection.parent.global_transform.inverse().xform(gizmo_transform.origin)
		GizmoMode.NORMAL:
			return Vector3.ZERO
	return gizmo_transform.origin


func _reset_everything(exclude_rot_scale = false) -> void:
	gizmo_transform = current_selection.get_selection_transform(current_gizmo_mode)
	vertex_count.text = str(current_selection.ply_mesh.vertex_count())
	edge_count.text = str(current_selection.ply_mesh.edge_count())
	face_count.text = str(current_selection.ply_mesh.face_count())
	selection_text.text = str(
		(
			current_selection.selected_vertices
			+ current_selection.selected_edges
			+ current_selection.selected_faces
		)
	)
	if gizmo_transform != null:
		var v = _get_origin()
		if current_gizmo_mode != GizmoMode.NORMAL || !exclude_rot_scale:
			translate_x.value = v.x
			translate_y.value = v.y
			translate_z.value = v.z
		if not exclude_rot_scale:
			rotate_x.value = 0
			rotate_y.value = 0
			rotate_z.value = 0
			scale_x.value = 1
			scale_y.value = 1
			scale_z.value = 1
		tool_grid.show()
	else:
		tool_grid.hide()


var current_gizmo_mode


func _on_gizmo_mode_changed(mode) -> void:
	current_gizmo_mode = mode
	_reset_everything()


var current_selection


func _on_selection_changed(selection) -> void:
	if current_selection:
		current_selection.disconnect("selection_changed", self, "_on_selected_geometry_changed")
		current_selection.disconnect("selection_mutated", self, "_on_selected_geometry_mutated")
	current_selection = selection
	gizmo_transform = null
	if current_selection:
		current_selection.connect("selection_changed", self, "_on_selected_geometry_changed")
		current_selection.connect("selection_mutated", self, "_on_selected_geometry_mutated")
		_on_selected_geometry_changed()


func _on_selected_geometry_changed() -> void:
	_reset_everything()


func _on_selected_geometry_mutated() -> void:
	if not in_edit:
		_reset_everything()


var in_edit: bool


func _transform_axis_edit_started(s, mode, axis) -> void:
	in_edit = true
	current_selection.begin_edit()


func _transform_axis_edit_committed(value, s, mode, axis) -> void:
	current_selection.commit_edit("Ply: " + mode, plugin.get_undo_redo())
	in_edit = false

	rotate_x.value = 0
	rotate_y.value = 0
	rotate_z.value = 0
	scale_x.value = 1
	scale_y.value = 1
	scale_z.value = 1
	_reset_everything()


func _transform_axis_value_changed(val, s, mode, axis) -> void:
	match mode:
		"Translate":
			var v = Vector3(translate_x.value, translate_y.value, translate_z.value)
			match current_gizmo_mode:
				GizmoMode.LOCAL:
					v = current_selection.parent.global_transform.xform(v)
				GizmoMode.NORMAL:
					v = (
						gizmo_transform.origin
						+ translate_x.value * gizmo_transform.basis.x
						+ translate_y.value * gizmo_transform.basis.y
						+ translate_z.value * gizmo_transform.basis.z
					)
			var o = gizmo_transform.origin
			current_selection.translate_selection(v - o)
		"Rotate":
			var ax
			match axis:
				"X":
					ax = gizmo_transform.basis.x
				"Y":
					ax = gizmo_transform.basis.y
				"Z":
					ax = gizmo_transform.basis.z
			current_selection.rotate_selection(ax, deg2rad(s.value))
		"Scale":
			var plane_normal: Vector3
			var scale_factor: float
			match axis:
				"X":
					plane_normal = gizmo_transform.basis.x
					scale_factor = scale_x.value
				"Y":
					plane_normal = gizmo_transform.basis.y
					scale_factor = scale_y.value
				"Z":
					plane_normal = gizmo_transform.basis.z
					scale_factor = scale_z.value
			current_selection.scale_selection_along_plane_normal(plane_normal, scale_factor)
