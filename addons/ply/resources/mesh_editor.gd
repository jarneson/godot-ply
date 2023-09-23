@tool
extends Resource
class_name PlyMeshEditor

const Math = preload("res://addons/ply/utils/math.gd")
const MeshTools = preload("res://addons/ply/utils/mesh.gd")
const PlyMesh = preload("res://addons/ply/resources/ply_mesh.gd")

var _pm: PlyMesh

var v_memo: Array[Vertex]
var e_memo: Array[Edge]
var f_memo: Array[Face]

func _init(pm: PlyMesh):
	_pm = pm
	pm.mesh_updated.connect(_on_mesh_updated)
	_on_mesh_updated()

func _on_mesh_updated():
	clear_memo()

func clear_memo():
	v_memo = []
	v_memo.resize(_pm.vertex_count())
	e_memo = []
	e_memo.resize(_pm.edge_count())
	f_memo = []
	f_memo.resize(_pm.face_count())

func get_vertex(i: int) -> Vertex:
	if v_memo[i] == null:
		v_memo[i] = Vertex.new(self, i)
	return v_memo[i]

func get_edge(i: int) -> Edge:
	if e_memo[i] == null:
		e_memo[i] = Edge.new(self, i)
	return e_memo[i]

func get_face(i: int) -> Face:
	if f_memo[i] == null:
		f_memo[i] = Face.new(self, i)
	return f_memo[i]

#########################################
# Vertices
#########################################
class Vertex:
	extends RefCounted

	var _p: PlyMeshEditor
	var _i: int

	func id() -> int:
		return _i

	func _init(p: PlyMeshEditor, idx: int):
		_i = idx
		_p = p
	
	func position() -> Vector3:
		return _p._pm.vertexes[_i]

	func intersects_ray(origin: Vector3, direction: Vector3) -> float:
		var dist = position().distance_to(origin)
		var hit = Geometry3D.segment_intersects_sphere(
			origin, origin + direction * 1000.0, position(), sqrt(dist) / 32.0
		)
		if hit:
			return hit[0].distance_to(origin)
		return -1.0

	func is_inside_frustum(planes: Array[Plane], camera_position: Vector3) -> bool:
		return Math.point_inside_frustum(position(), planes) and not _p.point_is_occluded_from(position(), camera_position)

func call_each_vertex(fn: Callable) -> void:
	for i in range(_pm.vertex_count()):
		fn.call(get_vertex(i))

#########################################
# Edges
#########################################
class Edge:
	extends RefCounted

	var _p: PlyMeshEditor
	var _i: int

	func _init(p: PlyMeshEditor, idx: int):
		_i = idx
		_p = p

	func id() -> int:
		return _i

	func origin() -> Vertex:
		return _p.get_vertex(_p._pm.edge_vertexes[_i*2])

	func destination() -> Vertex:
		return _p.get_vertex(_p._pm.edge_vertexes[_i*2+1])

	func midpoint() -> Vector3:
		return (origin().position() + destination().position()) / 2.0

	func direction() -> Vector3:
		return (destination().position() - origin().position()).normalized()

	func length() -> float:
		return destination().position().distance_to(origin().position())

	func next_clockwise_edge(f: Face) -> Edge:
		if _p._pm.edge_faces[_i*2] == f.id():
			return _p.get_edge(_p._pm.edge_edges[_i*2])
		else:
			return _p.get_edge(_p._pm.edge_edges[_i*2+1])

	func intersects_ray(origin: Vector3, direction: Vector3) -> float:
		var nearest = Geometry3D.get_closest_points_between_segments(
			origin,
			origin + direction * 1000.0,
			self.origin().position(),
			self.destination().position(),
		)
		var dist = nearest[0].distance_to(nearest[1]) 
		if dist < sqrt(origin.distance_to(nearest[0])) / 32.0:
			return dist
		return -1

	func is_inside_frustum(planes: Array[Plane], camera_position: Vector3) -> bool:
		# TODO(hints): just checking points may select surprising edges that are occluded in practice,
		# we could slide along the edge a small amount to see if it's occluded instead.
		if origin().is_inside_frustum(planes, camera_position):
			return true
		if destination().is_inside_frustum(planes, camera_position):
			return true

		var hit = Geometry3D.segment_intersects_convex(origin().position(), destination().position(), planes)
		if hit and not _p.point_is_occluded_from(hit[0], camera_position):
			return true
		return false

func call_each_edge(fn: Callable) -> void:
	for i in range(_pm.edge_count()):
		fn.call(get_edge(i))

#########################################
# Faces
#########################################
class Face:
	extends RefCounted

	var _p: PlyMeshEditor
	var _i: int
	var edges_memo: Array[Edge]
	var verts_memo: Array[Vertex]
	var tris_memo: PackedVector3Array

	func id() -> int:
		return _i

	func _init(p: PlyMeshEditor, idx: int):
		_i = idx
		_p = p

	func edges() -> Array[Edge]:
		if edges_memo.size() == 0:
			var start = _p._pm.face_edges[_i]
			edges_memo.push_back(_p.get_edge(start))
			var e = edges_memo[0].next_clockwise_edge(self)
			while e.id() != edges_memo[0].id():
				edges_memo.push_back(e)
				e = e.next_clockwise_edge(self)
		return edges_memo

	func raw_vertices() -> PackedVector3Array:
		var out = PackedVector3Array()
		for v in vertices():
			out.push_back(v.position())
		return out

	func vertices() -> Array[Vertex]:
		if verts_memo.size() == 0:
			for e in self.edges():
				if _p._pm.edge_faces[2*e.id()] == id():
					verts_memo.push_back(e.destination())
				else:
					verts_memo.push_back(e.origin())
		return verts_memo

	func normal() -> Vector3:
		return Math.face_normal(self.raw_vertices())

	func tris() -> PackedVector3Array:
		if tris_memo.size() == 0:
			tris_memo = MeshTools.wing_clip(raw_vertices())
		return tris_memo

	func intersects_ray(origin: Vector3, direction: Vector3) -> float:
		var t = tris()
		var min_dist = -1.0
		for i in range(0, t.size(), 3):
			var hit = Geometry3D.segment_intersects_triangle(
				origin,
				origin + direction * 1000.0,
				t[i],
				t[i+1],
				t[i+2],
			)
			if hit:
				var dist = origin.distance_to(hit)
				if min_dist < 0.0 or dist < min_dist:
					min_dist = dist
		return min_dist

	func is_inside_frustum(planes: Array[Plane], camera_position: Vector3) -> bool:
		for e in edges():
			if e.is_inside_frustum(planes, camera_position):
				return true

		var f_normal = normal()
		var f_plane = Plane(f_normal, edges()[0].origin().position())
		var f_tris = tris()

		var neighbor_planes = [
			[planes[0], planes[1]],
			[planes[1], planes[2]],
			[planes[2], planes[3]],
			[planes[3], planes[4]],
		]
		for np in neighbor_planes:
			var intersect = f_plane.intersect_3(np[0], np[1])
			if intersect == null:
				return false
			if not Math.point_inside_frustum(intersect, planes):
				return false
			for i in range(0, f_tris.size(), 3):
				var hit = Geometry3D.segment_intersects_triangle(
					intersect + f_normal, intersect - f_normal,
					f_tris[i], f_tris[i+1], f_tris[i+2]
				)
				if hit and not _p.point_is_occluded_from(hit, camera_position):
					return true
		return false

func call_each_face(fn: Callable) -> void:
	for i in range(_pm.face_count()):
		fn.call(get_face(i))


func point_is_occluded_from(point: Vector3, from: Vector3) -> bool:
	var distances = []
	var ray = (point - from).normalized()
	call_each_face(func(f):
		var dist = f.intersects_ray(from, ray)
		if dist >= 0.0:
			distances.push_back(dist)
	)
	var target_dist = point.distance_to(from)
	for d in distances:
		if d - target_dist < -0.001:
			return true
	return false
