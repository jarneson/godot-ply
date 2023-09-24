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
	reset_physics()

func clear_memo():
	v_memo = []
	v_memo.resize(_pm.vertex_count())
	e_memo = []
	e_memo.resize(_pm.edge_count())
	f_memo = []
	f_memo.resize(_pm.face_count())

func vertex_count() -> int:
	return v_memo.size()

func edge_count() -> int:
	return v_memo.size()

func face_count() -> int:
	return v_memo.size()

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

	func is_inside_frustum(planes: Array[Plane], camera: Transform3D, projection: Camera3D.ProjectionType) -> bool:
		return Math.point_inside_frustum(position(), planes) and not _p.point_is_occluded_from(position(), camera, projection)

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

	# NOTE(hints): this fails to select correctly when the endpoints are occluded, but the edge is not entirely occluded.
	func is_inside_frustum(planes: Array[Plane], camera: Transform3D, projection: Camera3D.ProjectionType) -> bool:
		# just checking endpoints can select edges that are entirely occluded visually, so also check they are not occluded slightly inwards on the edge
		if origin().is_inside_frustum(planes, camera, projection) and not _p.point_is_occluded_from(origin().position().lerp(destination().position(), 0.01), camera, projection):
			return true
		if destination().is_inside_frustum(planes, camera, projection) and not _p.point_is_occluded_from(destination().position().lerp(origin().position(), 0.01), camera, projection):
			return true

		var hit = Geometry3D.segment_intersects_convex(origin().position(), destination().position(), planes)
		if hit and not _p.point_is_occluded_from(hit[0], camera, projection):
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
	var aabb_memo: AABB

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
		var min_dist = -1.0
		if true:
			if aabb().intersects_ray(origin, direction) == null:
				return min_dist
		var t = tris()
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

	func is_inside_frustum(planes: Array[Plane], camera: Transform3D, projection: Camera3D.ProjectionType) -> bool:
		for e in edges():
			# TODO(hints): this will incorrectly select faces that are entirely occluded by wrapping around edges
			if e.is_inside_frustum(planes, camera, projection):
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
				if hit and not _p.point_is_occluded_from(hit, camera, projection):
					return true
		return false

	func aabb() -> AABB:
		if aabb_memo.size == Vector3.ZERO:
			var verts = raw_vertices()
			var from = verts[0]
			var to = verts[0]
			for v in verts:
				if v.x < from.x:
					from.x = v.x
				if v.y < from.y:
					from.y = v.y
				if v.z < from.z:
					from.z = v.z
				if v.x > to.x:
					to.x = v.x
				if v.y > to.y:
					to.y = v.y
				if v.z > to.z:
					to.z = v.z
			aabb_memo = AABB(from, to - from)
		return aabb_memo

func call_each_face(fn: Callable) -> void:
	for i in range(_pm.face_count()):
		fn.call(get_face(i))

#########################################
# Occlusion
#########################################

var space_rid: RID
var body_rid: RID
var shape_rid: RID

func reset_physics():
	if space_rid.is_valid():
		PhysicsServer3D.free_rid(body_rid)
		PhysicsServer3D.free_rid(shape_rid)
		PhysicsServer3D.free_rid(space_rid)
		body_rid = RID()
		shape_rid = RID()
		space_rid = RID()

func physics_space() -> PhysicsDirectSpaceState3D:
	if not space_rid.is_valid():
		space_rid = PhysicsServer3D.space_create()
		body_rid = PhysicsServer3D.body_create()
		print(PhysicsServer3D.body_get_mode(body_rid))
		PhysicsServer3D.body_set_mode(body_rid, PhysicsServer3D.BODY_MODE_STATIC)

		shape_rid = PhysicsServer3D.concave_polygon_shape_create()
		var vtxs = PackedVector3Array()
		call_each_face(func(f):
			vtxs.append_array(f.tris())
		)
		print("set vtxs: ", vtxs.size())
		PhysicsServer3D.shape_set_data(shape_rid, {
			"faces": vtxs,
		})
		PhysicsServer3D.body_add_shape(body_rid, shape_rid)

		PhysicsServer3D.body_set_space(body_rid, space_rid)
		PhysicsServer3D.space_set_active(space_rid, true)
	return PhysicsServer3D.space_get_direct_state(space_rid)

func point_is_occluded_from(point: Vector3, camera: Transform3D, projection: Camera3D.ProjectionType) -> bool:
	var ps = physics_space()

	var from = camera.origin
	var ray = (point - from).normalized()

	if projection == Camera3D.PROJECTION_ORTHOGONAL:
		ray = -camera.basis[2]
		from = Plane(camera.basis[2], camera.origin).project(point)

	var params = PhysicsRayQueryParameters3D.create(from, from + ray * 10000.0)
	var hit = ps.intersect_ray(params)
	if hit.has("position"):
		if hit["position"].distance_to(from) - point.distance_to(from) < -0.001:
			return true
	return false
