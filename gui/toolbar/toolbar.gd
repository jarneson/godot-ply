tool
extends Control

const SelectionMode = preload("../../utils/selection_mode.gd")

signal selection_mode_changed(mode)
signal transform_mode_changed(mode)

onready var transform_toggle = $TransformToggle

onready var selection_mesh   = $Mesh
onready var selection_face   = $Face
onready var selection_edge   = $Edge
onready var selection_vertex = $Vertex

onready var face_select_loop_1 = $FaceTools/FaceLoop1
onready var face_select_loop_2 = $FaceTools/FaceLoop2
onready var face_extrude       = $FaceTools/Extrude

onready var edge_cut_loop  = $EdgeTools/CutLoop
onready var edge_subdivide = $EdgeTools/Subdivide

func _ready():
	transform_toggle.connect("toggled", self, "_update_transform_toggle")
	selection_mesh.connect("toggled", self, "_update_selection_mode", [SelectionMode.MESH])
	selection_face.connect("toggled", self, "_update_selection_mode", [SelectionMode.FACE])
	selection_edge.connect("toggled", self, "_update_selection_mode", [SelectionMode.EDGE])
	selection_vertex.connect("toggled", self, "_update_selection_mode", [SelectionMode.VERTEX])

func _update_transform_toggle(selected):
	emit_signal("transform_mode_changed", selected)

func _update_selection_mode(selected, mode):
	if selected:
		emit_signal("selection_mode_changed", mode)

func set_selection_mode(mode):
	print("set_selection_mode")
	match mode:
		SelectionMode.MESH:
			selection_mesh.pressed = true
		SelectionMode.FACE:
			selection_face.pressed = true
		SelectionMode.EDGE:
			selection_edge.pressed = true
		SelectionMode.VERTEX:
			selection_vertex.pressed = true