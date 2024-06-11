@tool
extends Control

const working_on_gui = false

signal selection_mode_changed(mode)
signal gizmo_mode_changed(mode)

const SelectionMode = preload("res://addons/ply/utils/selection_mode.gd")
const GizmoMode = preload("res://addons/ply/utils/gizmo_mode.gd")

const Invert = preload("res://addons/ply/tools/reverse.gd")
const Extrude = preload("res://addons/ply/tools/extrude.gd")
const Subdivide = preload("res://addons/ply/tools/subdivide.gd")
const Triangulate = preload("res://addons/ply/tools/triangulate.gd")
const Loop = preload("res://addons/ply/tools/loop.gd")
const Collapse = preload("res://addons/ply/tools/collapse.gd")
const Connect = preload("res://addons/ply/tools/connect.gd")
const Generate = preload("res://addons/ply/tools/generate.gd")
const ExportMesh = preload("res://addons/ply/tools/export.gd")
const Import = preload("res://addons/ply/tools/import.gd")

var plugin: EditorPlugin

@onready var content_vbox = $Scroll/Content
@onready var selection_mesh = $Scroll/Content/Mesh
@onready var selection_face = $Scroll/Content/Face
@onready var selection_edge = $Scroll/Content/Edge
@onready var selection_vertex = $Scroll/Content/Vertex
@onready var select_all = $Scroll/Content/ToolModeLabel/MarginContainer/SelectAll
@onready var snap_checkbox = $Scroll/Content/SnapCheckbox

@onready var gizmo_global = $Scroll/Content/Global
@onready var gizmo_local = $Scroll/Content/Local
@onready var gizmo_normal = $Scroll/Content/Normal

@onready var mesh_tools = $Scroll/Content/MeshTools
@onready var mesh_subdivide = $Scroll/Content/MeshTools/Subdivide
@onready var mesh_triangulate = $Scroll/Content/MeshTools/Triangulate
@onready var mesh_invert_normals = $Scroll/Content/MeshTools/InvertNormals
@onready var mesh_import = $Scroll/Content/MeshTools/Import
@onready var mesh_export_to_obj = $Scroll/Content/MeshTools/ExportOBJ
@onready var mesh_generators = $Scroll/Content/MeshTools/Generators
@onready var generators_modal = $Scroll/Content/GeneratorsModal

@onready var face_tools = $Scroll/Content/FaceTools
@onready var face_select_loop_1 = $Scroll/Content/FaceTools/FaceLoop1
@onready var face_select_loop_2 = $Scroll/Content/FaceTools/FaceLoop2
@onready var face_extrude = $Scroll/Content/FaceTools/Extrude
@onready var face_connect = $Scroll/Content/FaceTools/Connect
@onready var face_subdivide = $Scroll/Content/FaceTools/Subdivide
@onready var face_triangulate = $Scroll/Content/FaceTools/Triangulate

@onready var zero_face_button = $'Scroll/Content/FaceTools/PaintSurfaces/MarginContainer/HboxContainer/0'
@onready var face_set_surfaces = $"Scroll/Content/FaceTools/Surfaces"
@onready var expand_surfaces_button = $"Scroll/Content/FaceTools/ExpandSurfaces"
@onready var face_color_picker = $Scroll/Content/FaceTools/VertexColorPicker

@onready var edge_tools = $Scroll/Content/EdgeTools
@onready var edge_select_loop = $Scroll/Content/EdgeTools/SelectLoop
@onready var edge_cut_loop = $Scroll/Content/EdgeTools/CutLoop
@onready var edge_subdivide = $Scroll/Content/EdgeTools/Subdivide
@onready var edge_collapse = $Scroll/Content/EdgeTools/Collapse

@onready var vertex_tools = $Scroll/Content/VertexTools
@onready var vertex_color_picker = $Scroll/Content/VertexTools/VertexColorPicker


var replacing_surface_idx_button: Button = null
var replacing_surface_label: Label = null
var hovered_button: Button = null


func _ready() -> void:
	var config = ConfigFile.new()
	var err = config.load("res://addons/ply/plugin.cfg")
	if err == OK:
		var version = config.get_value("plugin", "version")
		$TitleLabel/MarginContainer/HBoxContainer/Version.text = version
		
	selection_mesh.toggled.connect(_update_selection_mode.bind(SelectionMode.MESH))
	selection_face.toggled.connect(_update_selection_mode.bind(SelectionMode.FACE))
	selection_edge.toggled.connect(_update_selection_mode.bind(SelectionMode.EDGE))
	selection_vertex.toggled.connect(_update_selection_mode.bind(SelectionMode.VERTEX))
	
	
	select_all.pressed.connect(_select_all)
	snap_checkbox.toggled.connect(_on_snap_checkbox_toggle)

	gizmo_global.toggled.connect(_update_gizmo_mode.bind(GizmoMode.GLOBAL))
	gizmo_local.toggled.connect(_update_gizmo_mode.bind(GizmoMode.LOCAL))
	gizmo_normal.toggled.connect(_update_gizmo_mode.bind(GizmoMode.NORMAL))

	mesh_export_to_obj.pressed.connect(_export_to_obj)
	mesh_import.pressed.connect(_import_mesh)
	mesh_subdivide.pressed.connect(_mesh_subdivide)
	mesh_triangulate.pressed.connect(_mesh_triangulate)
	mesh_invert_normals.pressed.connect(_mesh_invert_normals)
	mesh_generators.pressed.connect(_open_generators_modal)
	generators_modal.confirmed.connect(_on_generators_modal_confirmed)
	
	face_color_picker.color_changed.connect(_on_face_color_changed)
	face_color_picker.pressed.connect(_on_face_color_pressed)
	face_color_picker.popup_closed.connect(_on_face_color_closed)

	for v: Button in (face_set_surfaces.get_children() + [zero_face_button]):
		v.pressed.connect(func() -> void:
			if replacing_surface_idx_button != null:
				_set_face_surface(v.name.to_int(), replacing_surface_idx_button.get_meta('faces', []))
				replacing_surface_idx_button = null
				hovered_button = null
				_on_geometry_selection_changed()
				return
			
			for v2: Button in face_set_surfaces.get_children():
				if v2 != v:
					v2.set_pressed_no_signal(false)
			
			_set_face_surface(v.name.to_int())
		)
		var unpress := func() -> void:
			_set_face_surface(0, v.get_meta('faces', []))
			v.set_pressed_no_signal(false)
		
		v.mouse_entered.connect(func() -> void:
			if replacing_surface_idx_button != null:
				hovered_button = v
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): #erase
				unpress.call()
		)
		v.mouse_exited.connect(func() -> void:
			if replacing_surface_idx_button != null:	hovered_button = null
		)
		
		v.gui_input.connect(func(event: InputEvent) -> void:
			if (event is InputEventMouseButton) and event.pressed:
				match event.button_index:
					MOUSE_BUTTON_RIGHT:
						unpress.call()
					
					MOUSE_BUTTON_MIDDLE:
						hovered_button = v
						replacing_surface_idx_button = v
		)
		
	
	
	
	expand_surfaces_button.pressed.connect(func() -> void:
		for v: Button in face_set_surfaces.get_children():
			if v.name.to_int() > 9:
				v.visible = expand_surfaces_button.button_pressed
			expand_surfaces_button.text = ('Less' if expand_surfaces_button.button_pressed else 'More')
	)
	
	
	face_select_loop_1.pressed.connect(_face_select_loop.bind(0))
	face_select_loop_2.pressed.connect(_face_select_loop.bind(1))
	
	face_extrude.pressed.connect(_face_extrude)
	face_connect.pressed.connect(_face_connect)
	face_subdivide.pressed.connect(_face_subdivide)
	face_triangulate.pressed.connect(_face_triangulate)
	
	edge_select_loop.pressed.connect(_edge_select_loop)
	edge_cut_loop.pressed.connect(_edge_cut_loop)
	edge_subdivide.pressed.connect(_edge_subdivide)
	edge_collapse.pressed.connect(_edge_collapse)
	
	vertex_color_picker.color_changed.connect(_on_vertex_color_changed)
	vertex_color_picker.pressed.connect(_on_face_color_pressed)
	vertex_color_picker.popup_closed.connect(_on_face_color_closed)
	
	if plugin:
		snap_checkbox.set_pressed_no_signal(plugin.current_settings.snap) #bool
		plugin.selection_changed.connect(_on_selection_changed)




var selected_mesh
func _on_selection_changed(selection):
	if selected_mesh and is_instance_valid(selected_mesh) and selected_mesh.has_signal("selection_changed"):
		selected_mesh.selection_changed.disconnect(_on_geometry_selection_changed)
	selected_mesh = selection
	if selected_mesh and is_instance_valid(selected_mesh) and selected_mesh.has_signal("selection_changed"):
		selected_mesh.selection_changed.connect(_on_geometry_selection_changed)
	

func _on_geometry_selection_changed():
	match selection_mode:
		SelectionMode.FACE:
			var color: Variant = null #Color?
			var surface_ids: Dictionary = {} #Dictionary[int, Array[int]]
			var many_different_colors = false
			
			replacing_surface_idx_button = null
			
			for f_idx: int in selected_mesh.selected_faces:
				var f_color = selected_mesh.ply_mesh.get_face_color(f_idx)
				var surface_id: int = selected_mesh.ply_mesh.face_surfaces[f_idx] if (selected_mesh.ply_mesh.face_surfaces.size() - 1) >= f_idx else 0
				
				if color == null:
					color = f_color
				
				
				if !surface_ids.has(surface_id):
					surface_ids[surface_id] = []
				surface_ids[surface_id].append(f_idx)
				
				if color != null and !color.is_equal_approx(f_color):
					many_different_colors = true
			
			if color == null:
				color = Color.WHITE
			
			
			var surface_ids_count := surface_ids.size()
			for v: Button in (face_set_surfaces.get_children() + [zero_face_button]):
				if v.has_meta('faces'):		v.remove_meta('faces')
				
				if surface_ids_count <= 0:
					v.set_pressed_no_signal(v.name.to_int() == surface_ids.keys()[0] if surface_ids_count > 0 else false)
				else:
					v.set_pressed_no_signal(surface_ids.has(v.name.to_int()))
					if v.button_pressed:
						v.set_meta('faces', surface_ids[v.name.to_int()] as Array[int])
			
			
			if many_different_colors:
				face_color_picker.color = Color.WHITE
				face_color_picker.get_node("Label").visible = true
			else:
				face_color_picker.color = color
				face_color_picker.get_node("Label").visible = false
		SelectionMode.EDGE:
			pass # TODO
		SelectionMode.VERTEX:
			var color
			var many = false
			for v_idx in selected_mesh.selected_vertices:
				var v_color = selected_mesh.ply_mesh.get_vertex_color(v_idx)
				if color == null:
					color = v_color
				if !color.is_equal_approx(v_color):
					many = true

			if color == null:
				color = Color.WHITE

			if many:
				vertex_color_picker.color = Color.WHITE
				vertex_color_picker.get_node("Label").visible = true
			else:
				vertex_color_picker.color = color
				vertex_color_picker.get_node("Label").visible = false

func _process(_delta) -> void:
	_update_tool_visibility()
	
	if replacing_surface_idx_button != null:
		if !replacing_surface_label:
			replacing_surface_label = Label.new()
			replacing_surface_label.top_level = true
			replacing_surface_label.name = '_replacing_surface_label'
			add_child(replacing_surface_label)
		
		
		replacing_surface_label.text = ('Replace %s -> %s (%s faces)' % [
			replacing_surface_idx_button.name,
			(hovered_button.name if hovered_button != null else '?'),
			(str(replacing_surface_idx_button.get_meta('faces').size()) if replacing_surface_idx_button.has_meta('faces') else '?'), #Array | String
		])
		replacing_surface_label.global_position = get_global_mouse_position()
		
		if !hovered_button:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				if replacing_surface_label != null:
					remove_child(replacing_surface_label)
					replacing_surface_label.queue_free()
					replacing_surface_label = null
					replacing_surface_idx_button = null
					hovered_button = null
	else:
		if replacing_surface_label != null:
			remove_child(replacing_surface_label)
			replacing_surface_label.queue_free()
			replacing_surface_label = null


var selection_mode: int = SelectionMode.MESH


func _update_selection_mode(selected, mode) -> void:
	if selected:
		var selection_button: Button = content_vbox.get_child(1 + mode)
		if selection_button != null:
			select_all.icon = selection_button.icon
		
		selection_mode = mode
		emit_signal("selection_mode_changed", mode)


var gizmo_mode: int = GizmoMode.LOCAL


func _update_gizmo_mode(selected, mode) -> void:
	if selected:
		gizmo_mode = mode
		emit_signal("gizmo_mode_changed", mode)


func _update_tool_visibility() -> void:
	mesh_tools.visible = selection_mesh.is_pressed() or working_on_gui
	face_tools.visible = selection_face.is_pressed() or working_on_gui
	edge_tools.visible = selection_edge.is_pressed() or working_on_gui
	vertex_tools.visible = selection_vertex.is_pressed() or working_on_gui


func set_selection_mode(mode) -> void:
	var selection_button: Button = null
	match mode:
		SelectionMode.MESH:
			selection_mesh.pressed = true
			selection_button = selection_mesh
		SelectionMode.FACE:
			selection_face.pressed = true
			selection_button = selection_face
		SelectionMode.EDGE:
			selection_edge.pressed = true
			selection_button = selection_edge
		SelectionMode.VERTEX:
			selection_vertex.pressed = true
			selection_button = selection_vertex
	
	print(selection_button)
	if selection_button != null:
		select_all.icon = selection_button.icon
		print(selection_button.icon, select_all)


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

func _select_all():
	if plugin.ignore_inputs:
		return
	if (
		not plugin.selection
	):
		return
	
	
	if selection_mode == SelectionMode.MESH:
		_update_selection_mode(true, SelectionMode.FACE)
	
	match selection_mode:
		SelectionMode.VERTEX:			plugin.selection.selected_vertices = range(plugin.selection.ply_mesh.vertexes.size())
		SelectionMode.EDGE:				plugin.selection.selected_edges = Array(plugin.selection.ply_mesh.vertex_edges)
		SelectionMode.FACE:				plugin.selection.selected_faces = Array(plugin.selection.ply_mesh.edge_faces)
	
	if selected_mesh != null and is_instance_valid(selected_mesh):
		selected_mesh.selection_changed.emit()



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


func _set_face_surface(s: int, for_faces: Array = []): #Array[int]
	if plugin.ignore_inputs:
		return
	if (
		not plugin.selection
		or selection_mode != SelectionMode.FACE
		or plugin.selection.selected_faces.size() == 0
	):
		return
	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	
	for f_idx: int in (for_faces if !for_faces.is_empty() else plugin.selection.selected_faces):
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



func _on_snap_checkbox_toggle(state: bool) -> void:
	plugin.change_settings_key('snap', state)



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
	var obj_file = FileAccess.open(file_name, FileAccess.WRITE)
	ExportMesh.export_to_obj(plugin.selection.ply_mesh, obj_file)


func _import_mesh():
	if plugin.ignore_inputs:
		return
	if not plugin.selection or selection_mode != SelectionMode.MESH:
		return
	var fd = FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.set_filters(PackedStringArray(["*.res,*.tres; Resources"]))
	var base_control = plugin.get_editor_interface().get_base_control()
	base_control.add_child(fd)
	fd.popup_centered(Vector2(480, 600))
	var file_name = await fd.file_selected
	var resource = load(file_name)
	if resource is ArrayMesh:
		Import.mesh(plugin.selection.ply_mesh, resource)


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

var color_pre_edit

func _on_face_color_pressed():
	color_pre_edit = plugin.selection.ply_mesh.begin_edit()

func _on_face_color_closed():
	plugin.selection.ply_mesh.commit_edit("Color Faces", plugin.get_undo_redo(), color_pre_edit)

func _on_face_color_changed(color: Color):
	if (
		not plugin.selection
		or selection_mode != SelectionMode.FACE
		or plugin.selection.selected_faces.size() == 0
	):
		return
	for f_idx in plugin.selection.selected_faces:
		plugin.selection.ply_mesh.set_face_color(f_idx, color)
	plugin.selection.ply_mesh.emit_change_signal()

func _on_vertex_color_pressed():
	color_pre_edit = plugin.selection.ply_mesh.begin_edit()

func _on_vertex_color_closed():
	plugin.selection.ply_mesh.commit_edit("Color Vertices", plugin.get_undo_redo(), color_pre_edit)

func _on_vertex_color_changed(color: Color):
	if (
		not plugin.selection
		or selection_mode != SelectionMode.VERTEX
		or plugin.selection.selected_vertices.size() == 0
	):
		return
	for v_idx in plugin.selection.selected_vertices:
		plugin.selection.ply_mesh.set_vertex_color(v_idx, color)
	plugin.selection.ply_mesh.emit_change_signal()
