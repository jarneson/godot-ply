extends EditorNode3DGizmoPlugin

const PlyEditor = preload("res://addons/ply/nodes/ply.gd")
const SelectionMode = preload("res://addons/ply/utils/selection_mode.gd")
const Median = preload("res://addons/ply/resources/median.gd")

var _plugin

func _init(p):
	_plugin = p

func _has_gizmo(n: Node3D) -> bool:
	print("has gizmo ", n is PlyEditor)
	return n is PlyEditor

var last = 0

func _subgizmos_intersect_ray(gizmo: EditorNode3DGizmo, camera: Camera3D, screen_pos: Vector2):
	print("subgizmo intersect ray ", gizmo, screen_pos)

	var ray = camera.project_ray_normal(screen_pos)
	var ray_pos = camera.project_ray_origin(screen_pos)
	var selection_mode = _plugin.toolbar.selection_mode

	var hits = _plugin.selection.get_ray_intersection(ray_pos, ray, selection_mode)
	if hits:
		print("select subgizmo ", hits[0][1])
		return hits[0][1]
	return -1

# not implemented yet
func _subgizmos_intersect_frustum_nyi(gizmo: EditorNode3DGizmo, camera: Camera3D, frustum_planes: Array[Plane]) -> PackedInt32Array:
	print("subgizmo intersect frustum", gizmo, frustum_planes)
	return PackedInt32Array([1,2])

func _get_subgizmo_transform(gizmo: EditorNode3DGizmo, subgizmo_id: int):
	var verts = []
	match _plugin.toolbar.selection_mode:
		SelectionMode.MESH:
			verts.push_back(Vector3.ZERO)
		SelectionMode.FACE:
			verts = _plugin.selection._ply_mesh.face_vertices(subgizmo_id)
		SelectionMode.EDGE:
			verts.push_back(_plugin.selection._ply_mesh.edge_origin(subgizmo_id))
			verts.push_back(_plugin.selection._ply_mesh.edge_destination(subgizmo_id))
		SelectionMode.VERTEX:
			verts.push_back(_plugin.selection._ply_mesh.vertexes[subgizmo_id])

	var pos = Median.geometric_median(verts)
	print(verts, "->", pos)
	return Transform3D(Basis.IDENTITY, pos)