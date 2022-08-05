@tool
extends Resource
class_name PlyMesh

const Median = preload("res://addons/ply/resources/median.gd")
const Side = preload("res://addons/ply/utils/direction.gd")

signal mesh_updated


func emit_change_signal() -> void:
	emit_signal("mesh_updated")


@export var vertexes = PackedVector3Array()
@export var vertex_edges = PackedInt32Array()
@export var vertex_colors = PackedColorArray()

@export var edge_vertexes = PackedInt32Array()
@export var edge_faces = PackedInt32Array()
@export var edge_edges = PackedInt32Array()

@export var face_edges = PackedInt32Array()
@export var face_surfaces = PackedInt32Array()
@export var face_colors = PackedColorArray()

#########################################
# Primary API
#########################################


func vertex_count() -> int:
	return vertexes.size()


func vertex(i: int) -> Vector3:
	return vertexes[i]


func vertex_normal(v_idx: int) -> Vector3:
	var faces = get_vertex_faces(v_idx)
	var normal = Vector3.ZERO
	for f in faces:
		normal += face_normal(f)
	normal /= faces.size()
	return normal


func edge_count() -> int:
	return edge_vertexes.size() / 2


func edge(i: int) -> Array:
	return [edge_origin(i), edge_destination(i)]


func edge_normal(e: int) -> Vector3:
	var face_normal_left = face_normal(edge_face_left(e))
	var face_normal_right = face_normal(edge_face_right(e))
	return (face_normal_left + face_normal_right) / 2


func face_count() -> int:
	return face_edges.size()


func face_vertices(idx) -> PackedVector3Array:
	var vert_idxs = face_vertex_indexes(idx)
	var verts = PackedVector3Array()
	for v_idx in vert_idxs:
		verts.push_back(vertexes[v_idx])
	return verts


func face_tris(f_idx: int) -> Array:
	var verts = face_vertex_indexes(f_idx)
	if verts.size() == 0:
		return []

	var mapped_verts = []
	if true:
		var face_normal = face_normal(f_idx)
		var axis_a = (vertexes[verts[verts.size() - 1]] - vertexes[verts[0]]).normalized()
		var axis_b = axis_a.cross(face_normal)
		var p_origin = vertexes[verts[0]]
		for vtx in verts:
			mapped_verts.push_back(
				[vertexes[vtx], Vector2((vertexes[vtx] - p_origin).dot(axis_a), (vertexes[vtx] - p_origin).dot(axis_b)), vtx]
			)

	var tris = []
	var remaining = []
	remaining.resize(verts.size())
	for i in range(verts.size()):
		remaining[i] = i

	while remaining.size() > 3:
		var min_idx = null
		var min_dot = null
		for curr in range(remaining.size()):
			var prev = curr - 1
			if prev < 0:
				prev = remaining.size() - 1
			var next = curr + 1
			if next >= remaining.size():
				next = 0

			var va = vertexes[verts[remaining[prev]]]
			var vb = vertexes[verts[remaining[curr]]]
			var vc = vertexes[verts[remaining[next]]]

			var ab = vb - va
			var bc = vc - vb

			var d = ab.dot(bc)

			if not min_dot or d < min_dot:
				min_idx = curr
				min_dot = d

		var curr = min_idx
		var prev = curr - 1
		if prev < 0:
			prev = remaining.size() - 1
		var next = curr + 1
		if next >= remaining.size():
			next = 0
		tris.push_back([remaining[prev], remaining[curr], remaining[next]])
		remaining.remove_at(min_idx)

	if remaining.size() == 3:
		tris.push_back([remaining[0], remaining[1], remaining[2]])

	return [mapped_verts, tris]


func face_normal(idx: int) -> Vector3:
	return average_vertex_normal(face_vertices(idx))


func face_surface(idx: int) -> int:
	return face_surfaces[idx]


func set_face_surface(idx: int, s: int):
	face_surfaces[idx] = s


func begin_edit() -> Array:
	return [
		vertexes.duplicate(), vertex_edges.duplicate(), vertex_colors.duplicate(),
		edge_vertexes.duplicate(), edge_faces.duplicate(), edge_edges.duplicate(),
		face_edges.duplicate(), face_surfaces.duplicate(), face_colors.duplicate()
	]


func reject_edit(pre_edits: Array, emit: bool = true) -> void:
	vertexes = pre_edits[0].duplicate()
	vertex_edges = pre_edits[1].duplicate()
	vertex_colors = pre_edits[2].duplicate()
	edge_vertexes = pre_edits[3].duplicate()
	edge_faces = pre_edits[4].duplicate()
	edge_edges = pre_edits[5].duplicate()
	face_edges = pre_edits[6].duplicate()
	face_surfaces = pre_edits[7].duplicate()
	face_colors = pre_edits[8].duplicate()
	if emit:
		emit_change_signal()


func face_paint_indices() -> Array:
	var surfaces = []
	var surface_map = {}
	for f_idx in range(face_surfaces.size()):
		var s = face_surfaces[f_idx]
		if surface_map.has(s):
			continue
		surface_map[s] = true
		surfaces.push_back(s)
	surfaces.sort()
	return surfaces


func get_mesh(mesh: Mesh = null) -> ArrayMesh:
	var max_surface = 0
	var surface_map = {}
	for f_idx in range(face_surfaces.size()):
		var s = face_surfaces[f_idx]
		if surface_map.has(s):
			surface_map[s].push_back(f_idx)
		else:
			if s > max_surface:
				max_surface = s
			surface_map[s] = [f_idx]
	var surfaces = []
	surfaces.resize(max_surface + 1)
	if not mesh:
		mesh = ArrayMesh.new()
	mesh.clear_surfaces()
	for s_idx in range(surfaces.size()):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		if surface_map.has(s_idx):
			var num_verts = 0
			var faces = surface_map[s_idx]
			for v in faces:
				num_verts += render_face(st, v, Vector3.ZERO, num_verts)
		surfaces[s_idx] = st.commit(mesh)
	return mesh


func commit_edit(name: String, undo_redo: UndoRedo, pre_edits: Array) -> void:
	undo_redo.create_action(name)
	undo_redo.add_do_property(self, "vertexes", vertexes)
	undo_redo.add_undo_property(self, "vertexes", pre_edits[0])
	undo_redo.add_do_property(self, "vertex_edges", vertex_edges)
	undo_redo.add_undo_property(self, "vertex_edges", pre_edits[1])
	undo_redo.add_do_property(self, "vertex_colors", vertex_colors)
	undo_redo.add_undo_property(self, "vertex_colors", pre_edits[2])
	undo_redo.add_do_property(self, "edge_vertexes", edge_vertexes)
	undo_redo.add_undo_property(self, "edge_vertexes", pre_edits[3])
	undo_redo.add_do_property(self, "edge_faces", edge_faces)
	undo_redo.add_undo_property(self, "edge_faces", pre_edits[4])
	undo_redo.add_do_property(self, "edge_edges", edge_edges)
	undo_redo.add_undo_property(self, "edge_edges", pre_edits[5])
	undo_redo.add_do_property(self, "face_edges", face_edges)
	undo_redo.add_undo_property(self, "face_edges", pre_edits[6])
	undo_redo.add_do_property(self, "face_surfaces", face_surfaces)
	undo_redo.add_undo_property(self, "face_surfaces", pre_edits[7])
	undo_redo.add_do_property(self, "face_colors", face_colors)
	undo_redo.add_undo_property(self, "face_colors", pre_edits[8])
	undo_redo.add_do_method(self, "emit_change_signal")
	undo_redo.add_undo_method(self, "emit_change_signal")
	undo_redo.commit_action()
	emit_change_signal()


func transform_faces(faces: Array, new_xf: Transform3D) -> void:
	var v_idxs = []
	for f in faces:
		for idx in face_vertex_indexes(f):
			if not v_idxs.has(idx):
				v_idxs.push_back(idx)

	transform_vertexes(v_idxs, new_xf)


func transform_edges(edges: Array, new_xf: Transform3D) -> void:
	var v_idxs = []
	for e in edges:
		if not v_idxs.has(edge_origin_idx(e)):
			v_idxs.push_back(edge_origin_idx(e))
		if not v_idxs.has(edge_destination_idx(e)):
			v_idxs.push_back(edge_destination_idx(e))
	transform_vertexes(v_idxs, new_xf)


func transform_vertexes(vtxs: Array, new_xf: Transform3D) -> void:
	var center = Vector3.ZERO
	for v in vtxs:
		center = center + vertexes[v]
	center = center / vtxs.size()

	var dict = {}
	for idx in vtxs:
		vertexes[idx] = new_xf.basis * (vertexes[idx] - center) + center + new_xf.origin


func scale_faces(faces: Array, plane_normal: Vector3, axes: Array, scale_factor: float) -> void:
	var v_idxs = []
	for f in faces:
		for idx in face_vertex_indexes(f):
			if not v_idxs.has(idx):
				v_idxs.push_back(idx)

	scale_vertices(v_idxs, plane_normal, axes, scale_factor)


func scale_edges(edges: Array, plane_normal: Vector3, axes: Array, scale_factor: float) -> void:
	var v_idxs = []
	for e in edges:
		if not v_idxs.has(edge_origin_idx(e)):
			v_idxs.push_back(edge_origin_idx(e))
		if not v_idxs.has(edge_destination_idx(e)):
			v_idxs.push_back(edge_destination_idx(e))
	scale_vertices(v_idxs, plane_normal, axes, scale_factor)


func scale_vertices(vtxs: Array, plane_normal: Vector3, axes: Array, scale_factor: float) -> void:
	var verts = []
	for v in vtxs:
		verts.push_back(vertexes[v])
	var center = Median.geometric_median(verts)

	for idx in vtxs:
		var v = vertexes[idx]
		v = v - center
		var dist = plane_normal.cross(-v).length()
		var delta = dist * (scale_factor - 1)
		var dir = (axes[0].dot(v) * axes[0] + axes[1].dot(v) * axes[1]).normalized()
		vertexes[idx] = v + dir * delta + center


func scale_faces_along_axis(idxs: Array, plane_normal: Vector3, scale_factor: float) -> void:
	var v_idxs = []
	for f in idxs:
		for idx in face_vertex_indexes(f):
			if not v_idxs.has(idx):
				v_idxs.push_back(idx)

	scale_vertices_along_axis(v_idxs, plane_normal, scale_factor)


func scale_edges_along_axis(idxs: Array, plane_normal: Vector3, scale_factor: float) -> void:
	var v_idxs = []
	for e in idxs:
		if not v_idxs.has(edge_origin_idx(e)):
			v_idxs.push_back(edge_origin_idx(e))
		if not v_idxs.has(edge_destination_idx(e)):
			v_idxs.push_back(edge_destination_idx(e))
	scale_vertices_along_axis(v_idxs, plane_normal, scale_factor)


func scale_vertices_along_axis(vtxs: Array, plane_normal: Vector3, scale_factor: float) -> void:
	var verts = []
	for v in vtxs:
		verts.push_back(vertexes[v])
	var center = Median.geometric_median(verts)

	for idx in vtxs:
		var v = vertexes[idx]
		v = v - center
		var dist = plane_normal.dot(v) / plane_normal.length()
		var delta = dist * (scale_factor - 1)
		vertexes[idx] = v + plane_normal * delta + center


#########################################
# End Primary API
#########################################


func is_manifold() -> String:
	if edge_count() == 0:
		return ""

	var arr = []
	for idx in range(edge_count()):
		arr.push_back(idx)

	var q = [arr.pop_front()]
	while q.size() > 0:
		var e = q.pop_front()
		for vtx in [edge_origin_idx(e), edge_destination_idx(e)]:
			var neighbors = get_vertex_edges(vtx, e)
			for n in neighbors:
				if arr.has(n):
					arr.erase(n)
					q.push_back(n)

	if arr.size() != 0:
		return "Could not reach all edges."

	var seen_edges = {}
	for e in range(edge_count()):
		seen_edges[e] = 0
	for f in range(face_count()):
		for e in get_face_edges(f):
			seen_edges[e] += 1

	for e in seen_edges:
		if seen_edges[e] != 2:
			return "Edge %s has %s face(s)." % [e, seen_edges[e]]
	return ""


func evict_vertices(idxs, ignore_edges = []) -> void:
	idxs.sort()
	idxs.reverse()
	for idx in idxs:
		vertexes.remove_at(idx)
		vertex_edges.remove_at(idx)
		vertex_colors.remove_at(idx)
		for e_idx in range(edge_vertexes.size()):
			if ignore_edges.has(e_idx / 2):
				continue
			if edge_vertexes[e_idx] == idx:
				push_error("trying to evict vertex %s in use by edge %s" % [idx, e_idx / 2])
				assert(false)
			if edge_vertexes[e_idx] > idx:
				edge_vertexes[e_idx] -= 1


func set_vertex(idx, pos) -> void:
	if vertexes[idx] == pos:
		return
	vertexes[idx] = pos
	emit_signal("mesh_updated")


func set_vertex_edge(idx, e_idx) -> void:
	vertex_edges[idx] = e_idx


func set_vertex_all(idx, pos, edge) -> void:
	vertexes[idx] = pos
	vertex_edges[idx] = edge


func set_vertex_color(idx, color) -> void:
	vertex_colors[idx] = color


func get_vertex_color(idx) -> Color:
	return vertex_colors[idx]


func expand_vertexes(more) -> void:
	vertexes.resize(vertexes.size() + more)
	vertex_edges.resize(vertex_edges.size() + more)
	var last = vertex_colors.size()
	vertex_colors.resize(vertex_colors.size() + more)
	for i in range(last, vertex_colors.size()):
		vertex_colors[i] = Color.WHITE


func average_vertex_normal(verts) -> Vector3:
	var normal_sum = Vector3.ZERO
	for i in range(verts.size()):
		var left_idx = i - 1
		var right_idx = i + 1
		if left_idx == -1:
			left_idx = verts.size() - 1
		if right_idx == verts.size():
			right_idx = 0
		normal_sum = normal_sum + (verts[left_idx] - verts[i]).cross(verts[right_idx] - verts[i])
	return (normal_sum / verts.size()).normalized()


func get_vertex_edges(v_idx, start = null) -> Array:
	if not start:
		start = vertex_edges[v_idx]
	var out = []

	var e = start
	var first = true
	while first or e != start:
		first = false
		out.push_back(e)
		if edge_origin_idx(e) == v_idx:
			e = edge_left_cw(e)
		elif edge_destination_idx(e) == v_idx:
			e = edge_right_cw(e)
		else:
			push_error("edge %s does not include vertex %s" % [start, v_idx])
			assert(false)

	return out


func get_vertex_faces(v_idx) -> Array:
	var edges = get_vertex_edges(v_idx)
	var faces = {}
	for e in edges:
		faces[edge_face_left(e)] = true
		faces[edge_face_right(e)] = true
	return faces.keys()


# 2 vertices and faces per edge
# 2 connecting edges per edge, one way traversal
# 2*idx for left, 2*idx+1 for right
#         origin,       destination
func evict_edges(idxs) -> void:
	idxs.sort()
	idxs.reverse()
	var ignore = idxs.duplicate()
	for idx in idxs:
		ignore.erase(idx)
		var l = 2 * idx
		var r = 2 * idx + 1
		edge_vertexes.remove_at(r)
		edge_vertexes.remove_at(l)
		edge_faces.remove_at(r)
		edge_faces.remove_at(l)
		edge_edges.remove_at(r)
		edge_edges.remove_at(l)

		for i in range(edge_edges.size()):
			if ignore.has(i / 2):
				continue
			if edge_edges[i] == idx:
				push_error("attempting to evict edge %s in use by edge %s" % [idx, i / 2])
				assert(false)
			if edge_edges[i] > idx:
				edge_edges[i] -= 1

		for i in range(vertex_edges.size()):
			if vertex_edges[i] == idx:
				push_error( "attempting to evict edge %s in use by vertex %s" % [idx, i])
				assert(false)
			if vertex_edges[i] > idx:
				vertex_edges[i] -= 1

		for i in range(face_edges.size()):
			if face_edges[i] == idx:
				push_error("attempting to evict edge %s in use by face %s" % [idx, i])
				assert(false)
			if face_edges[i] > idx:
				face_edges[i] -= 1


func expand_edges(more) -> void:
	edge_vertexes.resize(edge_vertexes.size() + more * 2)
	edge_faces.resize(edge_faces.size() + more * 2)
	edge_edges.resize(edge_edges.size() + more * 2)


func set_edge_vertexes(arr: PackedInt32Array) -> void:
	edge_vertexes = arr


func set_edge_edges(arr: PackedInt32Array) -> void:
	edge_edges = arr


func edge_side(e_idx, f_idx) -> int:
	if edge_face_left(e_idx) == f_idx:
		return Side.LEFT
	if edge_face_right(e_idx) == f_idx:
		return Side.RIGHT
	push_error("edge %s does not touch face %s" % [e_idx, f_idx])
	assert(false)
	return Side.UNKNOWN


func edge_face(e_idx, side) -> int:
	match side:
		Side.LEFT:
			return edge_face_left(e_idx)
		Side.RIGHT:
			return edge_face_right(e_idx)
	return -1


func set_edge_face(e_idx, side, f_idx) -> void:
	match side:
		Side.LEFT:
			set_edge_face_left(e_idx, f_idx)
		Side.RIGHT:
			set_edge_face_right(e_idx, f_idx)


func get_face_edges_starting_at(start, side) -> Array:
	var f_idx = edge_face(start, side)
	if f_idx < 0:
		return []
	var out = []
	out.push_back(start)
	var e = edge_next_cw(start, f_idx)
	while e != start:
		out.push_back(e)
		e = edge_next_cw(e, f_idx)
	return out


func edge_cw(idx, side) -> int:
	match side:
		Side.LEFT:
			return edge_left_cw(idx)
		Side.RIGHT:
			return edge_right_cw(idx)
	return -1


func set_edge_cw(idx, side, e) -> void:
	match side:
		Side.LEFT:
			set_edge_left_cw(idx, e)
		Side.RIGHT:
			set_edge_right_cw(idx, e)


func edge_next_cw(edge, face) -> int:
	return edge_cw(edge, edge_side(edge, face))


func edge_left_cw(idx) -> int:
	return edge_edges[2 * idx]


func set_edge_left_cw(idx, cw) -> void:
	edge_edges[2 * idx] = cw


func edge_right_cw(idx) -> int:
	return edge_edges[2 * idx + 1]


func set_edge_right_cw(idx, cw) -> void:
	edge_edges[2 * idx + 1] = cw


func edge_face_left(idx) -> int:
	return edge_faces[2 * idx]


func set_edge_face_left(idx, f) -> void:
	edge_faces[2 * idx] = f


func edge_face_right(idx) -> int:
	return edge_faces[2 * idx + 1]


func set_edge_face_right(idx, f) -> void:
	edge_faces[2 * idx + 1] = f


func edge_origin_idx(idx) -> int:
	return edge_vertexes[2 * idx]


func set_edge_origin_idx(e, v) -> void:
	edge_vertexes[2 * e] = v


func edge_destination_idx(idx) -> int:
	return edge_vertexes[2 * idx + 1]


func set_edge_destination_idx(e, v) -> void:
	edge_vertexes[2 * e + 1] = v


func edge_origin(idx) -> Vector3:
	return vertexes[edge_origin_idx(idx)]


func edge_destination(idx) -> Vector3:
	return vertexes[edge_destination_idx(idx)]


func set_edge_origin(e, v):
	edge_vertexes[2 * e] = v


func set_edge_destination(e, v):
	edge_vertexes[2 * e + 1] = v


func evict_faces(idxs, ignore_edges = []):
	idxs.sort()
	idxs.reverse()
	for f_idx in idxs:
		face_edges.remove_at(f_idx)
		face_surfaces.remove_at(f_idx)
		face_colors.remove_at(f_idx)

		for i in range(edge_faces.size()):
			if ignore_edges.has(i / 2):
				continue
			if edge_faces[i] == f_idx:
				push_error("attempting to evict face %s in use by edge %s" % [f_idx, i / 2])
				assert(false)
			if edge_faces[i] > f_idx:
				edge_faces[i] -= 1


func expand_faces(more):
	face_edges.resize(face_edges.size() + more)
	face_surfaces.resize(face_surfaces.size() + more)
	var last = face_colors.size()
	face_colors.resize(face_colors.size() + more)
	for i in range(last, face_colors.size()):
		face_colors[i] = Color.WHITE


func set_face_edge(f, e):
	face_edges[f] = e


func get_face_edges(idx):
	return get_face_edges_starting_at(face_edges[idx], edge_side(face_edges[idx], idx))


func set_face_color(f, color):
	face_colors[f] = color


func get_face_color(f):
	return face_colors[f]


func face_vertex_indexes(idx):
	var edges = get_face_edges(idx)
	assert(edges.size() > 0) #,"face %s has no edges" % [idx])
	var verts = PackedInt32Array()
	for e in edges:
		if edge_face_left(e) == idx:
			verts.push_back(edge_origin_idx(e))
		elif edge_face_right(e) == idx:
			verts.push_back(edge_destination_idx(e))
		else:
			push_error("edge %s retured does not include face %s" % [e, idx])
			assert(false)
	return verts


func render_face(st, f_idx, offset = Vector3.ZERO, num_verts = 0):
	var tri_res = face_tris(f_idx)
	var verts = tri_res[0]
	if verts.size() < 3:
		return

	var tris = tri_res[1]
	var norm = face_normal(f_idx)
	var p = Plane(norm, verts[0][0])
	
	var y = norm
	var x = (p.project(verts[1][0]) - p.project(verts[0][0])).normalized()
	var z = y.cross(x)
	var b = Basis(x,y,z)
	for vtx in verts:
		var uv = b * (p.project(vtx[0]) - p.project(verts[0][0]));
		if face_colors[f_idx] == Color.WHITE:
			st.set_color(vertex_colors[vtx[2]])
		else:
			st.set_color(face_colors[f_idx])
		st.set_uv(Vector2(uv.x, uv.z))
		st.set_normal(norm)
		st.add_vertex(vtx[0] + offset)

	for tri in tris:
		for val in tri:
			st.add_index(val + num_verts)

	return verts.size()


func set_mesh(vs, ves, fes, fss, evs, efs, ees):
	vertexes = PackedVector3Array(vs)
	vertex_edges = PackedInt32Array(ves)
	vertex_colors = PackedColorArray()
	vertex_colors.resize(vs.size())
	for i in range(vertex_colors.size()):
		vertex_colors[i] = Color.WHITE
	face_edges = PackedInt32Array(fes)
	face_surfaces = PackedInt32Array(fss)
	face_colors = PackedColorArray()
	face_colors.resize(fes.size())
	for i in range(face_colors.size()):
		face_colors[i] = Color.WHITE
	edge_vertexes = PackedInt32Array(evs)
	edge_faces = PackedInt32Array(efs)
	edge_edges = PackedInt32Array(ees)
	emit_signal("mesh_updated")


func face_intersect_ray_distance(face_idx, ray_start, ray_dir):
	var tri_res = face_tris(face_idx)
	var vtxs = tri_res[0]
	var tris = tri_res[1]

	var min_dist = null

	for tri in tris:
		var verts = [vtxs[tri[0]][0], vtxs[tri[1]][0], vtxs[tri[2]][0]]

		var normal = (verts[2] - verts[0]).cross(verts[1] - verts[0]).normalized()
		var denom = normal.dot(ray_dir)
		if is_equal_approx(0, denom):
			continue

		var t = -normal.dot(ray_start - verts[0]) / normal.dot(ray_dir)
		var hit = ray_start + t * ray_dir

		var e0 = verts[1] - verts[0]
		var e1 = verts[2] - verts[1]
		var e2 = verts[0] - verts[2]
		var c0 = hit - verts[0]
		var c1 = hit - verts[1]
		var c2 = hit - verts[2]
		var x0 = c0.cross(e0)
		var x1 = c1.cross(e1)
		var x2 = c2.cross(e2)
		var in_tri = normal.dot(x0) >= 0 and normal.dot(x1) >= 0 and normal.dot(x2) >= 0
		if in_tri:
			if not min_dist or t < min_dist:
				min_dist = t
	return min_dist
