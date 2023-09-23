@tool
extends Node

signal selection_changed
signal selection_mutated

const default_materials: Array[Material] = [
	preload("res://addons/ply/materials/debug_material_light.tres"),
	preload("res://addons/ply/materials/debug_material_medium.tres"),
	preload("res://addons/ply/materials/debug_material_dark.tres"),
	preload("res://addons/ply/materials/debug_material_red.tres"),
	preload("res://addons/ply/materials/debug_material_orange.tres"),
	preload("res://addons/ply/materials/debug_material_yellow.tres"),
	preload("res://addons/ply/materials/debug_material_green.tres"),
	preload("res://addons/ply/materials/debug_material_blue.tres"),
	preload("res://addons/ply/materials/debug_material_purple.tres"),
]

const SelectionMode = preload("res://addons/ply/utils/selection_mode.gd")
const GizmoMode = preload("res://addons/ply/utils/gizmo_mode.gd")
const Median = preload("res://addons/ply/resources/median.gd")
const Math = preload("res://addons/ply/utils/math.gd")

const PlyMesh = preload("res://addons/ply/resources/ply_mesh.gd")
const PlyMeshEditor = preload("res://addons/ply/resources/mesh_editor.gd")
const Wireframe = preload("res://addons/ply/nodes/ply_wireframe.gd")
const Vertices = preload("res://addons/ply/nodes/ply_vertices.gd")
const Faces = preload("res://addons/ply/nodes/ply_faces.gd")

const valid_classes = ["MeshInstance3D", "CSGMesh3D"]

@export var parent_property: String = "mesh"
@export var ply_mesh: Resource :
	get:
		return _ply_mesh
	set(v):
		if v == null:
			if _ply_mesh && _ply_mesh.mesh_updated.is_connected(_on_mesh_updated):
				_ply_mesh.mesh_updated.disconnect(_on_mesh_updated)
			_ply_mesh = v
			editor = null
			_clear_parent()
		if v is PlyMesh:
			if _ply_mesh && _ply_mesh.mesh_updated.is_connected(_on_mesh_updated):
				_ply_mesh.mesh_updated.disconnect(_on_mesh_updated)
			_ply_mesh = v
			_ply_mesh.mesh_updated.connect(_on_mesh_updated)
			editor = PlyMeshEditor.new(_ply_mesh)
			_on_mesh_updated()
		else:
			print("assigned resource that is not a ply_mesh to ply editor")

@export var materials : Array[Material]:
	set=set_materials # (Array, Material)

var _ply_mesh: PlyMesh
var editor: PlyMeshEditor


func set_materials(v) -> void:
	materials = v
	_paint_faces()


@onready var parent = get_parent()


func _ready() -> void:
	if not Engine.is_editor_hint():
		return

	elif not _ply_mesh:
		ply_mesh = PlyMesh.new()
	_compute_materials()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	
	if not get_parent().get_class() in valid_classes:
		warnings.append("Must be a child of one of the following classes: " + ", ".join(valid_classes))
		
	return PackedStringArray(warnings)

func _compute_materials() -> void:
	var res = default_materials.duplicate()
	var paints = _ply_mesh.face_paint_indices()
	if parent is MeshInstance3D and parent.mesh:
		for surface in parent.mesh.get_surface_count():
			var mat = parent.get_surface_override_material(surface)
			if mat:
				res[paints[surface]] = parent.get_surface_override_material(surface)
	elif parent is CSGMesh3D:
		res[0] = parent.material
	materials = res


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return

	if _ply_mesh and not _ply_mesh.mesh_updated.is_connected(_on_mesh_updated):
		_ply_mesh.mesh_updated.connect(_on_mesh_updated)


func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		return
	if not _ply_mesh:
		return
	if _ply_mesh.mesh_updated.is_connected(_on_mesh_updated):
		_ply_mesh.mesh_updated.disconnect(_on_mesh_updated)


func _clear_parent() -> void:
	parent.set(parent_property, ArrayMesh.new())


func _paint_faces() -> void:
	if parent is MeshInstance3D and parent.mesh:
		var paints = _ply_mesh.face_paint_indices()
		for i in range(parent.mesh.get_surface_count()):
			if paints.size() > i and materials.size() > paints[i]:
				parent.set_surface_override_material(i, materials[paints[i]])

	if parent is CSGMesh3D:
		parent.material = materials[0]


func _on_mesh_updated() -> void:
	var remove = []
	for v in selected_vertices:
		if v >= _ply_mesh.vertex_count():
			remove.push_back(v)
	for v in remove:
		selected_vertices.erase(v)
	remove = []
	for e in selected_edges:
		if e >= _ply_mesh.edge_count():
			remove.push_back(e)
	for e in remove:
		selected_edges.erase(e)
	remove = []
	for f in selected_faces:
		if f >= _ply_mesh.face_count():
			remove.push_back(f)
	for f in remove:
		selected_faces.erase(f)
	if parent:
		var m = parent.get(parent_property)
		if not m:
			m = ArrayMesh.new()
		parent.set(parent_property, _ply_mesh.get_mesh(m))
		if parent is MeshInstance3D:
			var collision_shape = parent.get_node_or_null("StaticBody3D/CollisionShape3D")
			if collision_shape:
				collision_shape.shape = parent.mesh.create_trimesh_shape()
	_paint_faces()
	emit_signal("selection_mutated")

var _selected: bool
var selected: bool:
	get:
		return _selected # TODOConverter40 Copy here content of _get_selected
	set(v):
		if _selected == v:
			return
		_selected = v
		if not _selected:
			_vertices.queue_free()
			_wireframe.queue_free()
			_faces.queue_free()
		if _selected:
			_compute_materials()
			_vertices = Vertices.new()
			_vertices.name = "ply_vertices"
			add_child(_vertices)
			_wireframe = Wireframe.new()
			_wireframe.name = "ply_wireframe"
			add_child(_wireframe)
			_faces = Faces.new()
			_faces.name = "ply_faces"
			add_child(_faces)
var _wireframe: Wireframe
var _vertices: Vertices
var _faces: Faces


class IntersectSorter:
	static func sort_ascending(a, b) -> bool:
		if a[2] < b[2]:
			return true
		return false


func get_frustum_intersection(planes: Array[Plane], mode: int, camera: Camera3D) -> Array:
	var ts = Time.get_ticks_usec()
	var scan_results = []
	var ai = parent.global_transform.affine_inverse()
	var ai_planes: Array[Plane] = []
	ai_planes.resize(planes.size())
	for i in  range(planes.size()):
		ai_planes[i] = ai * planes[i]

	if mode == SelectionMode.VERTEX:
		editor.call_each_vertex(func(v):
			if v.is_inside_frustum(ai_planes):
				scan_results.push_back(["V", v.id()])
		)

	if mode == SelectionMode.EDGE:
		editor.call_each_edge(func(e):
			if e.is_inside_frustum(ai_planes):
				scan_results.push_back(["E", e.id()])
		)

	if mode == SelectionMode.FACE:
		editor.call_each_face(func(f):
			if f.is_inside_frustum(ai_planes):
				scan_results.push_back(["F", f.id()])
		)

	print("frustum took ", Time.get_ticks_usec() - ts, "us")
	return scan_results

func get_ray_intersection(origin: Vector3, direction: Vector3, mode: int) -> Array:
	var scan_results = []

	var ai = parent.global_transform.affine_inverse()
	var ai_origin = ai * origin
	var ai_direction = (ai.basis * direction).normalized()

	var ts = Time.get_ticks_usec()

	if mode == SelectionMode.VERTEX:
		editor.call_each_vertex(func(v):
			var hit_dist = v.intersects_ray(ai_origin, ai_direction)
			if hit_dist >= 0.0:
				scan_results.push_back(["V", v.id(), hit_dist])
		)

	if mode == SelectionMode.EDGE:
		editor.call_each_edge(func(e):
			var hit_dist = e.intersects_ray(ai_origin, ai_direction)
			if hit_dist >= 0.0:
				scan_results.push_back(["E", e.id(), hit_dist])
		)

	if mode == SelectionMode.FACE:
		editor.call_each_face(func(f):
			var hit_dist = f.intersects_ray(ai_origin, ai_direction)
			if hit_dist >= 0.0:
				scan_results.push_back(["F", f.id(), hit_dist])
		)

	scan_results.sort_custom(Callable(IntersectSorter, "sort_ascending"))
	print("ray cast took ", Time.get_ticks_usec() - ts, "us")
	return scan_results


var selected_vertices: Array = []
var selected_edges: Array = []
var selected_faces: Array = []


func select_geometry(hits: Array, toggle: bool) -> void:
	if not toggle:
		selected_vertices = []
		selected_edges = []
		selected_faces = []
	for h in hits:
		match h[0]:
			"V":
				if toggle:
					if selected_vertices.has(h[1]):
						selected_vertices.erase(h[1])
					else:
						selected_vertices.push_back(h[1])
				else:
					selected_vertices.push_back(h[1])
			"E":
				if toggle:
					if selected_edges.has(h[1]):
						selected_edges.erase(h[1])
					else:
						selected_edges.push_back(h[1])
				else:
					selected_edges.push_back(h[1])
			"F":
				if toggle:
					if selected_faces.has(h[1]):
						selected_faces.erase(h[1])
					else:
						selected_faces.push_back(h[1])
				else:
					selected_faces.push_back(h[1])
	emit_signal("selection_changed")


var _current_edit


func begin_edit() -> void:
	_current_edit = _ply_mesh.begin_edit()


func commit_edit(name: String, undo_redo: EditorUndoRedoManager) -> void:
	_ply_mesh.commit_edit(name, undo_redo, _current_edit)
	_current_edit = null


func abort_edit() -> void:
	_ply_mesh.reject_edit(_current_edit)
	_current_edit = null


func get_selection_transform(gizmo_mode: int = GizmoMode.LOCAL, basis_override = null):
	if selected_vertices.size() == 0 and selected_edges.size() == 0 and selected_faces.size() == 0:
		return null

	var verts = {}
	var normals = []
	if gizmo_mode != GizmoMode.NORMAL:
		normals = null
	for v in selected_vertices:
		verts[_ply_mesh.vertexes[v]] = true
		if normals != null:
			normals.push_back(_ply_mesh.vertex_normal(v))
	for e in selected_edges:
		verts[_ply_mesh.edge_origin(e)] = true
		verts[_ply_mesh.edge_destination(e)] = true
		if normals != null:
			normals.push_back(_ply_mesh.edge_normal(e))
	for f in selected_faces:
		for v in _ply_mesh.face_vertices(f):
			verts[v] = true
		if normals != null:
			normals.push_back(_ply_mesh.face_normal(f))

	var pos = Median.geometric_median(verts.keys())

	var basis = parent.global_transform.basis
	if normals != null:
		var normal = Vector3.ZERO
		for n in normals:
			normal += n
		normal /= normals.size()
		normal = basis * normal
		var v_y = normal
		var v_x = basis.x
		var v_z = basis.z
		if v_y == v_x || v_y == -v_x:
			v_x = v_y.cross(v_z)
			v_z = v_y.cross(v_x)
		else:
			v_z = v_y.cross(v_x)
			v_x = v_y.cross(v_z)
		basis = Basis(v_x, v_y, v_z).transposed()
	if gizmo_mode == GizmoMode.GLOBAL:
		basis = Basis.IDENTITY
	if basis_override:
		basis = basis_override
	return Transform3D(basis.orthonormalized(), parent.global_transform * pos)


func translate_selection(global_dir: Vector3) -> void:
	if _current_edit == null:
		return
	var dir = parent.global_transform.basis.inverse() * global_dir
	_ply_mesh.reject_edit(_current_edit, false)
	_ply_mesh.transform_faces(selected_faces, Transform3D(Basis.IDENTITY, dir))
	_ply_mesh.transform_edges(selected_edges, Transform3D(Basis.IDENTITY, dir))
	_ply_mesh.transform_vertexes(selected_vertices, Transform3D(Basis.IDENTITY, dir))
	emit_signal("selection_mutated")


func rotate_selection(axis: Vector3, rad: float) -> void:
	if _current_edit == null:
		return
	axis = (parent.global_transform.basis.inverse() * axis).normalized()
	var new_basis = Basis(axis, rad)
	_ply_mesh.reject_edit(_current_edit, false)
	_ply_mesh.transform_faces(selected_faces, Transform3D(new_basis, Vector3.ZERO))
	_ply_mesh.transform_edges(selected_edges, Transform3D(new_basis, Vector3.ZERO))
	_ply_mesh.transform_vertexes(selected_vertices, Transform3D(new_basis, Vector3.ZERO))
	emit_signal("selection_mutated")


func scale_selection_along_plane(plane_normal: Vector3, axes: Array, scale_factor: float) -> void:
	if _current_edit == null:
		return
	var b = parent.global_transform.basis.orthonormalized().inverse()
	plane_normal = b * plane_normal.normalized()
	axes = [b * axes[0].normalized(), (b*axes[1]).normalized()]
	_ply_mesh.reject_edit(_current_edit, false)
	_ply_mesh.scale_faces(selected_faces, plane_normal, axes, scale_factor)
	_ply_mesh.scale_edges(selected_edges, plane_normal, axes, scale_factor)
	_ply_mesh.scale_vertices(selected_vertices, plane_normal, axes, scale_factor)
	emit_signal("selection_mutated")


func scale_selection_along_plane_normal(plane_normal: Vector3, scale_factor: float) -> void:
	if _current_edit == null:
		return
	plane_normal = (parent.global_transform.basis.orthonormalized().inverse() * plane_normal).normalized()
	_ply_mesh.reject_edit(_current_edit, false)
	_ply_mesh.scale_faces_along_axis(selected_faces, plane_normal, scale_factor)
	_ply_mesh.scale_edges_along_axis(selected_edges, plane_normal, scale_factor)
	_ply_mesh.scale_vertices_along_axis(selected_vertices, plane_normal, scale_factor)
	emit_signal("selection_mutated")
