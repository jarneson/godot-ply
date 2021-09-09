tool
extends VBoxContainer

const SelectionMode = preload("../utils/selection_mode.gd")

signal selection_mode_changed(mode)

onready var selection_mesh = $"Selection/SelectionModes/SelectMesh"
onready var selection_face = $"Selection/SelectionModes/SelectFace"
onready var selection_edge = $"Selection/SelectionModes/SelectEdge"
onready var selection_vertex = $"Selection/SelectionModes/SelectVertex"
onready var generate_cube = $"Generators/Generators/GenerateCube"
onready var generate_plane = $"Generators/Generators/GeneratePlane"
onready var generate_sphere = $"Generators/Generators/GenerateSphere"
onready var generate_cylinder = $"Generators/Generators/GenerateCylinder"

onready var face_extrude = $"FaceContainer/Tools/Extrude"

onready var face_select_loop_0 = $"FaceContainer/LoopSelect/Offset0"
onready var face_select_loop_1 = $"FaceContainer/LoopSelect/Offset1"

onready var edge_subdivide = $"EdgeContainer/Tools/Subdivide"
onready var edge_cut_loop = $"EdgeContainer/Tools/EdgeLoop"

func _ready():
	selection_mesh.connect("toggled", self, "_update_selection_mode", [SelectionMode.MESH])
	selection_face.connect("toggled", self, "_update_selection_mode", [SelectionMode.FACE])
	selection_edge.connect("toggled", self, "_update_selection_mode", [SelectionMode.EDGE])
	selection_vertex.connect("toggled", self, "_update_selection_mode", [SelectionMode.VERTEX])

func _update_selection_mode(selected, mode):
	if selected:
		emit_signal("selection_mode_changed", mode)

func set_selection_mode(mode):
	match mode:
		SelectionMode.MESH:
			selection_mesh.pressed = true
		SelectionMode.FACE:
			selection_face.pressed = true
		SelectionMode.EDGE:
			selection_edge.pressed = true
		SelectionMode.VERTEX:
			selection_vertex.pressed = true