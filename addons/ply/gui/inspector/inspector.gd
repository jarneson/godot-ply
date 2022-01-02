tool
extends VBoxContainer

const SpinSlider = preload("./spin_slider.gd")

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

var plugin = null
var gizmo_transform

func _prep_slider(s, l, mn, mx, st, mod, axis):
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

func _ready():
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
	_prep_slider(rotate_x, "x", -180, 180, 0.001, "Rotate", "X")
	rotate_y = SpinSlider.new()
	_prep_slider(rotate_y, "y", -180, 180, 0.001, "Rotate", "Y")
	rotate_z = SpinSlider.new()
	_prep_slider(rotate_z, "z", -180, 180, 0.001, "Rotate", "Z")
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
	hide()

var current_selection
func _on_selection_changed(selection):
	if current_selection:
		current_selection.disconnect("selection_changed", self, "_on_selected_geometry_changed")
		current_selection.disconnect("selection_mutated", self, "_on_selected_geometry_mutated")
	current_selection = selection
	gizmo_transform = null
	hide()
	if current_selection:
		current_selection.connect("selection_changed", self, "_on_selected_geometry_changed")
		current_selection.connect("selection_mutated", self, "_on_selected_geometry_mutated")

func _on_selected_geometry_changed():
	gizmo_transform = current_selection.get_selection_transform()
	if gizmo_transform:
		translate_x.value = gizmo_transform.origin.x
		translate_y.value = gizmo_transform.origin.y
		translate_z.value = gizmo_transform.origin.z
		show()
	else:
		hide()

func _on_selected_geometry_mutated():
	gizmo_transform = current_selection.get_selection_transform()
	translate_x.value = gizmo_transform.origin.x
	translate_y.value = gizmo_transform.origin.y
	translate_z.value = gizmo_transform.origin.z


var in_edit: bool
func _transform_axis_edit_started(s, mode, axis):
	in_edit = true
	current_selection.begin_edit()

func _transform_axis_edit_committed(value, s, mode, axis):
	current_selection.commit_edit("Ply: " + mode, plugin.get_undo_redo())
	in_edit = false

func _transform_axis_value_changed(val, s, mode, axis):
	match mode:
		"Translate":
			var v = Vector3(translate_x.value, translate_y.value, translate_z.value)
			var o = current_selection.get_selection_transform().origin
			current_selection.translate_selection(v-o)

