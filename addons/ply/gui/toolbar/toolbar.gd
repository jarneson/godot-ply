@tool
extends Control

signal selection_mode_changed(mode)
signal gizmo_mode_changed(mode)

const SelectionMode = preload("res://addons/ply/utils/selection_mode.gd")
const GizmoMode = preload("res://addons/ply/utils/gizmo_mode.gd")

const Invert = preload("res://addons/ply/resources/reverse.gd")
const Extrude = preload("res://addons/ply/resources/extrude.gd")
const Subdivide = preload("res://addons/ply/resources/subdivide.gd")
const Triangulate = preload("res://addons/ply/resources/triangulate.gd")
const Loop = preload("res://addons/ply/resources/loop.gd")
const Collapse = preload("res://addons/ply/resources/collapse.gd")
const Connect = preload("res://addons/ply/resources/connect.gd")
const Generate = preload("res://addons/ply/resources/generate.gd")
const ExportMesh = preload("res://addons/ply/resources/export.gd")

var plugin: EditorPlugin

@onready var selection_mesh = $Mesh
@onready var selection_face = $Face
@onready var selection_edge = $Edge
@onready var selection_vertex = $Vertex

@onready var gizmo_global = $Global
@onready var gizmo_local = $Local
@onready var gizmo_normal = $Normal

@onready var mesh_tools = $MeshTools
@onready var mesh_subdivide = $MeshTools/Subdivide
@onready var mesh_triangulate = $MeshTools/Triangulate
@onready var mesh_invert_normals = $MeshTools/InvertNormals
@onready var mesh_export_to_obj = $MeshTools/ExportOBJ
@onready var mesh_generators = $MeshTools/Generators
@onready var generators_modal = $GeneratorsModal

@onready var face_tools = $FaceTools
@onready var face_select_loop_1 = $FaceTools/FaceLoop1
@onready var face_select_loop_2 = $FaceTools/FaceLoop2
@onready var face_extrude = $FaceTools/Extrude
@onready var face_connect = $FaceTools/Connect
@onready var face_subdivide = $FaceTools/Subdivide
@onready var face_triangulate = $FaceTools/Triangulate

@onready var face_set_shape_1 = $"FaceTools/Surfaces/1"
@onready var face_set_shape_2 = $"FaceTools/Surfaces/2"
@onready var face_set_shape_3 = $"FaceTools/Surfaces/3"
@onready var face_set_shape_4 = $"FaceTools/Surfaces/4"
@onready var face_set_shape_5 = $"FaceTools/Surfaces/5"
@onready var face_set_shape_6 = $"FaceTools/Surfaces/6"
@onready var face_set_shape_7 = $"FaceTools/Surfaces/7"
@onready var face_set_shape_8 = $"FaceTools/Surfaces/8"
@onready var face_set_shape_9 = $"FaceTools/Surfaces/9"

@onready var edge_tools = $EdgeTools
@onready var edge_select_loop = $EdgeTools/SelectLoop
@onready var edge_cut_loop = $EdgeTools/CutLoop
@onready var edge_subdivide = $EdgeTools/Subdivide
@onready var edge_collapse = $EdgeTools/Collapse

@onready var vertex_tools = $VertexTools


func _ready() -> void:
	var config = ConfigFile.new()
	var err = config.load("res://addons/ply/plugin.cfg")
	if err == OK:
		var version = config.get_value("plugin", "version")
		$TitleLabel/MarginContainer/HBoxContainer/Version.text = version
	selection_mesh.connect("toggled",Callable(self,"_update_selection_mode"),[SelectionMode.MESH])
	selection_face.connect("toggled",Callable(self,"_update_selection_mode"),[SelectionMode.FACE])
	selection_edge.connect("toggled",Callable(self,"_update_selection_mode"),[SelectionMode.EDGE])
	selection_vertex.connect("toggled",Callable(self,"_update_selection_mode"),[SelectionMode.VERTEX])

	gizmo_global.connect("toggled",Callable(self,"_update_gizmo_mode"),[GizmoMode.GLOBAL])
	gizmo_local.connect("toggled",Callable(self,"_update_gizmo_mode"),[GizmoMode.LOCAL])
	gizmo_normal.connect("toggled",Callable(self,"_update_gizmo_mode"),[GizmoMode.NORMAL])

	mesh_export_to_obj.connect("pressed",Callable(self,"_export_to_obj"))
	mesh_subdivide.connect("pressed",Callable(self,"_mesh_subdivide"))
	mesh_triangulate.connect("pressed",Callable(self,"_mesh_triangulate"))
	mesh_invert_normals.connect("pressed",Callable(self,"_mesh_invert_normals"))
	mesh_generators.connect("pressed",Callable(self,"_open_generators_modal"))
	generators_modal.connect("confirmed",Callable(self,"_on_generators_modal_confirmed"))

	face_set_shape_1.connect("pressed",Callable(self,"_set_face_surface"),[0])
	face_set_shape_2.connect("pressed",Callable(self,"_set_face_surface"),[1])
	face_set_shape_3.connect("pressed",Callable(self,"_set_face_surface"),[2])
	face_set_shape_4.connect("pressed",Callable(self,"_set_face_surface"),[3])
	face_set_shape_5.connect("pressed",Callable(self,"_set_face_surface"),[4])
	face_set_shape_6.connect("pressed",Callable(self,"_set_face_surface"),[5])
	face_set_shape_7.connect("pressed",Callable(self,"_set_face_surface"),[6])
	face_set_shape_8.connect("pressed",Callable(self,"_set_face_surface"),[7])
	face_set_shape_9.connect("pressed",Callable(self,"_set_face_surface"),[8])

	face_select_loop_1.connect("pressed",Callable(self,"_face_select_loop"),[0])
	face_select_loop_2.connect("pressed",Callable(self,"_face_select_loop"),[1])
	face_extrude.connect("pressed",Callable(self,"_face_extrude"))
	face_connect.connect("pressed",Callable(self,"_face_connect"))
	face_subdivide.connect("pressed",Callable(self,"_face_subdivide"))
	face_triangulate.connect("pressed",Callable(self,"_face_triangulate"))

	edge_select_loop.connect("pressed",Callable(self,"_edge_select_loop"))
	edge_cut_loop.connect("pressed",Callable(self,"_edge_cut_loop"))
	edge_subdivide.connect("pressed",Callable(self,"_edge_subdivide"))
	edge_collapse.connect("pressed",Callable(self,"_edge_collapse"))


func _process(_delta) -> void:
	_update_tool_visibility()


var selection_mode: int = SelectionMode.MESH


func _update_selection_mode(selected, mode) -> void:
	if selected:
		selection_mode = mode
		emit_signal("selection_mode_changed", mode)


var gizmo_mode: int = GizmoMode.LOCAL


func _update_gizmo_mode(selected, mode) -> void:
	if selected:
		gizmo_mode = mode
		emit_signal("gizmo_mode_changed", mode)


func _update_tool_visibility() -> void:
	mesh_tools.visible = selection_mesh.is_pressed()
	face_tools.visible = selection_face.is_pressed()
	edge_tools.visible = selection_edge.is_pressed()
	vertex_tools.visible = selection_vertex.is_pressed()


func set_selection_mode(mode) -> void:
	match mode:
		SelectionMode.MESH:
			selection_mesh.pressed = true
		SelectionMode.FACE:
			selection_face.pressed = true
		SelectionMode.EDGE:
			selection_edge.pressed = true
		SelectionMode.VERTEX:
			selection_vertex.pressed = true


func _open_generators_modal():
	generators_modal.popup_centered_clamped(Vector2(800, 600))


func _on_generators_modal_confirmed():
	var arr = generators_modal.get_selection()
	var shape = arr[0]
	var params = arr[1]
	match shape:
		"Plane":
			_generate_plane(params)
		"Cube":
			_generate_cube(params)
		"Icosphere":
			_generate_icosphere(params)
		"Cylinder":
			_generate_cylinder(params)


func _generate_cube(params = Array()):
	if plugin.ignore_inputs:
		return
	if not plugin.selection:
		return
	var size = 1
	var subdivisions = 0
	if params != Array():
		size = params[0]
		subdivisions = params[1]
	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	var vertexes = [
		size * Vector3(-0.5, 0, -0.5),
		size * Vector3(0.5, 0, -0.5),
		size * Vector3(0.5, 0, 0.5),
		size * Vector3(-0.5, 0, 0.5)
	]
	Generate.nGon(plugin.selection.ply_mesh, vertexes)
	Extrude.faces(plugin.selection.ply_mesh, [0], null, size)
	for i in range(subdivisions):
		Subdivide.object(plugin.selection.ply_mesh)
	plugin.selection.ply_mesh.commit_edit("Generate Cube", plugin.get_undo_redo(), pre_edit)


func _generate_plane(params = Array()):
	if plugin.ignore_inputs:
		return
	if not plugin.selection:
		return

	var size = 1
	var subdivisions = 0
	if params != Array():
		size = params[0]
		subdivisions = params[1]

	var vertexes = [
		size * Vector3(-0.5, 0, -0.5),
		size * Vector3(0.5, 0, -0.5),
		size * Vector3(0.5, 0, 0.5),
		size * Vector3(-0.5, 0, 0.5)
	]

	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Generate.nGon(plugin.selection.ply_mesh, vertexes)
	for i in range(subdivisions):
		Subdivide.object(plugin.selection.ply_mesh)
	plugin.selection.ply_mesh.commit_edit("Generate Plane", plugin.get_undo_redo(), pre_edit)


func _generate_cylinder(params = Array()):
	if plugin.ignore_inputs:
		return
	if not plugin.selection:
		return

	var radius = 1
	var depth = 1
	var num_points = 8
	var num_segments = 1
	if params != Array():
		radius = params[0]
		depth = params[1]
		num_points = params[2]
		num_segments = params[3]

	var vertexes = []
	for i in range(num_points):
		vertexes.push_back(
			Vector3(
				radius * cos(float(i) / num_points * 2 * PI),
				-depth / 2,
				radius * sin(float(i) / num_points * 2 * PI)
			)
		)

	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Generate.nGon(plugin.selection.ply_mesh, vertexes)
	for i in range(num_segments):
		Extrude.faces(plugin.selection.ply_mesh, [0], null, depth / num_segments)
	plugin.selection.ply_mesh.commit_edit("Generate Cylinder", plugin.get_undo_redo(), pre_edit)


func _generate_icosphere(params = Array()):
	if plugin.ignore_inputs:
		return
	if not plugin.selection:
		return

	var radius = 1.0
	var subdivides = 0
	if params != Array():
		radius = params[0]
		subdivides = params[1]

	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Generate.icosphere(plugin.selection.ply_mesh, radius, subdivides)
	plugin.selection.ply_mesh.commit_edit("Generate Icosphere", plugin.get_undo_redo(), pre_edit)


func _generate_mesh(arr):
	if plugin.ignore_inputs:
		return


func _face_select_loop(offset):
	if plugin.ignore_inputs:
		return
	if (
		not plugin.selection
		or selection_mode != SelectionMode.FACE
		or plugin.selection.selected_faces.size() != 1
	):
		return
	var loop = Loop.get_face_loop(
		plugin.selection.ply_mesh, plugin.selection.selected_faces[0], offset
	)[0]
	plugin.selection.selected_faces = loop


func _face_extrude():
	if plugin.ignore_inputs:
		return
	if (
		not plugin.selection
		or selection_mode != SelectionMode.FACE
		or plugin.selection.selected_faces.size() == 0
	):
		return
	Extrude.faces(
		plugin.selection.ply_mesh, plugin.selection.selected_faces, plugin.get_undo_redo(), 1
	)


func _face_connect():
	if plugin.ignore_inputs:
		return
	if (
		not plugin.selection
		or selection_mode != SelectionMode.FACE
		or plugin.selection.selected_faces.size() != 2
	):
		return
	Connect.faces(
		plugin.selection.ply_mesh,
		plugin.selection.selected_faces[0],
		plugin.selection.selected_faces[1],
		plugin.get_undo_redo()
	)


func _face_subdivide():
	if plugin.ignore_inputs:
		return
	if not plugin.selection or selection_mode != SelectionMode.FACE:
		return
	Subdivide.faces(
		plugin.selection.ply_mesh, plugin.selection.selected_faces, plugin.get_undo_redo()
	)


func _face_triangulate():
	if plugin.ignore_inputs:
		return
	if not plugin.selection or selection_mode != SelectionMode.FACE:
		return
	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Triangulate.faces(plugin.selection.ply_mesh, plugin.selection.selected_faces)
	plugin.selection.ply_mesh.commit_edit("Triangulate Faces", plugin.get_undo_redo(), pre_edit)


func _set_face_surface(s):
	if plugin.ignore_inputs:
		return
	if (
		not plugin.selection
		or selection_mode != SelectionMode.FACE
		or plugin.selection.selected_faces.size() == 0
	):
		return
	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	for f_idx in plugin.selection.selected_faces:
		plugin.selection.ply_mesh.set_face_surface(f_idx, s)
	plugin.selection.ply_mesh.commit_edit("Paint Face", plugin.get_undo_redo(), pre_edit)


func _edge_select_loop():
	if plugin.ignore_inputs:
		return
	if (
		not plugin.selection
		or selection_mode != SelectionMode.EDGE
		or plugin.selection.selected_edges.size() != 1
	):
		return
	var loop = Loop.get_edge_loop(plugin.selection.ply_mesh, plugin.selection.selected_edges[0])
	plugin.selection.selected_edges = loop


func _edge_cut_loop():
	if plugin.ignore_inputs:
		return
	if (
		not plugin.selection
		or selection_mode != SelectionMode.EDGE
		or plugin.selection.selected_edges.size() != 1
	):
		return
	Loop.edge_cut(
		plugin.selection.ply_mesh, plugin.selection.selected_edges[0], plugin.get_undo_redo()
	)


func _edge_subdivide():
	if plugin.ignore_inputs:
		return
	if (
		not plugin.selection
		or selection_mode != SelectionMode.EDGE
		or plugin.selection.selected_edges.size() != 1
	):
		return
	Subdivide.edge(
		plugin.selection.ply_mesh, plugin.selection.selected_edges[0], plugin.get_undo_redo()
	)


func _edge_collapse():
	if plugin.ignore_inputs:
		return
	if (
		not plugin.selection
		or selection_mode != SelectionMode.EDGE
		or plugin.selection.selected_edges.size() == 0
	):
		return
	if Collapse.edges(
		plugin.selection.ply_mesh, plugin.selection.selected_edges, plugin.get_undo_redo()
	):
		plugin.selection.selected_edges = []


func _export_to_obj():
	if plugin.ignore_inputs:
		return
	if not plugin.selection or selection_mode != SelectionMode.MESH:
		return
	var fd = FileDialog.new()
	fd.set_filters(PackedStringArray(["*.obj ; OBJ Files"]))
	var base_control = plugin.get_editor_interface().get_base_control()
	base_control.add_child(fd)
	fd.popup_centered(Vector2(480, 600))
	var file_name = await fd.file_selected
	var obj_file = File.new()
	obj_file.open(file_name, File.WRITE)
	ExportMesh.export_to_obj(plugin.selection.ply_mesh, obj_file)


func _mesh_subdivide():
	if plugin.ignore_inputs:
		return
	if not plugin.selection or selection_mode != SelectionMode.MESH:
		return
	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Subdivide.object(plugin.selection.ply_mesh)
	plugin.selection.ply_mesh.commit_edit("Subdivide Mesh", plugin.get_undo_redo(), pre_edit)


func _mesh_triangulate():
	if plugin.ignore_inputs:
		return
	if not plugin.selection or selection_mode != SelectionMode.MESH:
		return
	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Triangulate.object(plugin.selection.ply_mesh)
	plugin.selection.ply_mesh.commit_edit("Subdivide Mesh", plugin.get_undo_redo(), pre_edit)


func _mesh_invert_normals():
	if plugin.ignore_inputs:
		return
	if not plugin.selection or selection_mode != SelectionMode.MESH:
		return
	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Invert.normals(plugin.selection.ply_mesh)
	plugin.selection.ply_mesh.commit_edit("Invert Normals", plugin.get_undo_redo(), pre_edit)
