tool
extends Control

const SelectionMode = preload("../../utils/selection_mode.gd")

signal generate_plane
signal generate_cube
signal generate_mesh(arr)
signal set_face_surface(s)

signal selection_mode_changed(mode)
signal transform_mode_changed(mode)

onready var transform_toggle = $TransformToggle

onready var selection_mesh   = $Mesh
onready var selection_face   = $Face
onready var selection_edge   = $Edge
onready var selection_vertex = $Vertex

onready var mesh_tools = $MeshTools
onready var mesh_subdivide = $MeshTools/Subdivide
onready var mesh_triangulate = $MeshTools/Triangulate
onready var mesh_export_to_obj = $MeshTools/ExportOBJ
onready var mesh_quick_generators = $MeshTools/QuickGenerators
onready var mesh_generators = $MeshTools/Generators
onready var generators_modal = $GeneratorsModal

onready var face_tools = $FaceTools
onready var face_select_loop_1 = $FaceTools/FaceLoop1
onready var face_select_loop_2 = $FaceTools/FaceLoop2
onready var face_extrude       = $FaceTools/Extrude
onready var face_connect       = $FaceTools/Connect
onready var face_subdivide     = $FaceTools/Subdivide
onready var face_triangulate   = $FaceTools/Triangulate

onready var face_set_shape_1 = $"FaceTools/Surfaces/1"
onready var face_set_shape_2 = $"FaceTools/Surfaces/2"
onready var face_set_shape_3 = $"FaceTools/Surfaces/3"
onready var face_set_shape_4 = $"FaceTools/Surfaces/4"
onready var face_set_shape_5 = $"FaceTools/Surfaces/5"
onready var face_set_shape_6 = $"FaceTools/Surfaces/6"
onready var face_set_shape_7 = $"FaceTools/Surfaces/7"
onready var face_set_shape_8 = $"FaceTools/Surfaces/8"
onready var face_set_shape_9 = $"FaceTools/Surfaces/9"

onready var edge_tools = $EdgeTools
onready var edge_select_loop = $EdgeTools/SelectLoop
onready var edge_cut_loop  = $EdgeTools/CutLoop
onready var edge_subdivide = $EdgeTools/Subdivide
onready var edge_collapse = $EdgeTools/Collapse

onready var vertex_tools = $VertexTools

func _ready():
	transform_toggle.connect("toggled", self, "_update_transform_toggle")
	selection_mesh.connect("toggled", self, "_update_selection_mode", [SelectionMode.MESH])
	selection_face.connect("toggled", self, "_update_selection_mode", [SelectionMode.FACE])
	selection_edge.connect("toggled", self, "_update_selection_mode", [SelectionMode.EDGE])
	selection_vertex.connect("toggled", self, "_update_selection_mode", [SelectionMode.VERTEX])

	face_set_shape_1.connect("pressed", self, "_set_face_surface", [0])
	face_set_shape_2.connect("pressed", self, "_set_face_surface", [1])
	face_set_shape_3.connect("pressed", self, "_set_face_surface", [2])
	face_set_shape_4.connect("pressed", self, "_set_face_surface", [3])
	face_set_shape_5.connect("pressed", self, "_set_face_surface", [4])
	face_set_shape_6.connect("pressed", self, "_set_face_surface", [5])
	face_set_shape_7.connect("pressed", self, "_set_face_surface", [6])
	face_set_shape_8.connect("pressed", self, "_set_face_surface", [7])
	face_set_shape_9.connect("pressed", self, "_set_face_surface", [8])

	mesh_quick_generators.get_popup().connect("id_pressed", self, "_on_generators_id_pressed")
	mesh_generators.connect("pressed", self, "_open_generators_modal")
	generators_modal.connect("confirmed", self, "_on_generators_modal_confirmed")

func _process(_delta):
	_update_tool_visibility()

func _update_transform_toggle(selected):
	emit_signal("transform_mode_changed", selected)

func _update_selection_mode(selected, mode):
	if selected:
		emit_signal("selection_mode_changed", mode)

func _update_tool_visibility():
	mesh_tools.visible = selection_mesh.pressed
	face_tools.visible = selection_face.pressed
	edge_tools.visible = selection_edge.pressed
	vertex_tools.visible = selection_vertex.pressed

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

func _on_generators_id_pressed(idx):
	match mesh_quick_generators.get_popup().get_item_text(idx):
		"Plane":
			emit_signal("generate_plane")
		"Cube":
			emit_signal("generate_cube")

func _open_generators_modal():
	generators_modal.popup_centered_minsize(Vector2(800, 600))

func _on_generators_modal_confirmed():
	emit_signal("generate_mesh", generators_modal.get_selection())

func _set_face_surface(idx):
	emit_signal("set_face_surface", idx)