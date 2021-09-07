tool
extends Resource
class_name PlyMesh

"""
███████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗     ███████╗
██╔════╝██║██╔════╝ ████╗  ██║██╔══██╗██║     ██╔════╝
███████╗██║██║  ███╗██╔██╗ ██║███████║██║     ███████╗
╚════██║██║██║   ██║██║╚██╗██║██╔══██║██║     ╚════██║
███████║██║╚██████╔╝██║ ╚████║██║  ██║███████╗███████║
╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝
"""
signal mesh_updated

"""
███████╗███╗   ██╗██╗   ██╗███╗   ███╗███████╗
██╔════╝████╗  ██║██║   ██║████╗ ████║██╔════╝
█████╗  ██╔██╗ ██║██║   ██║██╔████╔██║███████╗
██╔══╝  ██║╚██╗██║██║   ██║██║╚██╔╝██║╚════██║
███████╗██║ ╚████║╚██████╔╝██║ ╚═╝ ██║███████║
╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝
"""
const Side = preload("../utils/direction.gd")

"""
██╗   ██╗███████╗██████╗ ████████╗██╗ ██████╗███████╗███████╗
██║   ██║██╔════╝██╔══██╗╚══██╔══╝██║██╔════╝██╔════╝██╔════╝
██║   ██║█████╗  ██████╔╝   ██║   ██║██║     █████╗  ███████╗
╚██╗ ██╔╝██╔══╝  ██╔══██╗   ██║   ██║██║     ██╔══╝  ╚════██║
 ╚████╔╝ ███████╗██║  ██║   ██║   ██║╚██████╗███████╗███████║
  ╚═══╝  ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝╚══════╝╚══════╝
"""
export var vertexes = PoolVector3Array()
export var vertex_edges = PoolIntArray()

func vertex_count():
	return vertexes.size()

func set_vertex(idx, pos):
	if vertexes[idx] == pos:
		return
	vertexes[idx] = pos
	emit_signal("mesh_updated")

func set_vertex_all(idx, pos, edge):
	vertexes[idx] = pos
	vertex_edges[idx] = edge

func expand_vertexes(more):
	vertexes.resize(vertexes.size()+more)
	vertex_edges.resize(vertex_edges.size()+more)

func geometric_median(verts, iters=5):
	var start = Vector3.ZERO
	if verts.size() == 0:
		return start
	for v in verts:
		start = start + v
	start = start / verts.size()

	for i in range(iters):
		pass # TODO: weiszfeld's
	
	return start

func average_vertex_normal(verts):
	var normal_sum = Vector3.ZERO
	for i in range(verts.size()):
		var left_idx = i-1 
		var right_idx = i+1
		if left_idx == -1:
			left_idx = verts.size()-1
		if right_idx == verts.size():
			right_idx = 0
		normal_sum = normal_sum + (verts[left_idx]-verts[i]).cross(verts[right_idx]-verts[i])
	return (normal_sum / verts.size()).normalized()

"""
███████╗██████╗  ██████╗ ███████╗███████╗
██╔════╝██╔══██╗██╔════╝ ██╔════╝██╔════╝
█████╗  ██║  ██║██║  ███╗█████╗  ███████╗
██╔══╝  ██║  ██║██║   ██║██╔══╝  ╚════██║
███████╗██████╔╝╚██████╔╝███████╗███████║
╚══════╝╚═════╝  ╚═════╝ ╚══════╝╚══════╝
"""
# 2 vertices and faces per edge
# 2 connecting edges per edge, one way traversal
# 2*idx for left, 2*idx+1 for right
#         origin,       destination
export var edge_vertexes = PoolIntArray()
export var edge_faces = PoolIntArray()
export var edge_edges = PoolIntArray()

func edge_count():
	return edge_vertexes.size() / 2

func expand_edges(more):
	edge_vertexes.resize(edge_vertexes.size()+more*2)
	edge_faces.resize(edge_faces.size()+more*2)
	edge_edges.resize(edge_edges.size()+more*2)

func edge_side(e_idx, f_idx):
	if edge_face_left(e_idx) == f_idx:
		return Side.LEFT
	if edge_face_right(e_idx) == f_idx:
		return Side.RIGHT
	assert(false, "edge %s does not touch face %s" % [e_idx, f_idx])

func edge_face(e_idx, side):
	match side:
		Side.LEFT:
			return edge_face_left(e_idx)
		Side.RIGHT:
			return edge_face_right(e_idx)

func get_face_edges_starting_at(start, side):
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

func edge_cw(idx, side):
	match side:
		Side.LEFT:
			return edge_left_cw(idx)
		Side.RIGHT:
			return edge_right_cw(idx)

func edge_next_cw(edge, face):
	return edge_cw(edge, edge_side(edge, face))

func edge_left_cw(idx):
	return edge_edges[2*idx]

func set_edge_left_cw(idx, cw):
	edge_edges[2*idx] = cw

func edge_right_cw(idx):
	return edge_edges[2*idx+1]

func set_edge_right_cw(idx, cw):
	edge_edges[2*idx+1] = cw

func edge_face_left(idx):
	return edge_faces[2*idx]

func set_edge_face_left(idx, f):
	edge_faces[2*idx] = f

func edge_face_right(idx):
	return edge_faces[2*idx+1]

func set_edge_face_right(idx, f):
	edge_faces[2*idx+1] = f

func edge_origin_idx(idx):
	return edge_vertexes[2*idx]

func set_edge_origin_idx(e, v):
	edge_vertexes[2*e] = v

func edge_destination_idx(idx):
	return edge_vertexes[2*idx+1]

func set_edge_destination_idx(e, v):
	edge_vertexes[2*e+1] = v

func edge_origin(idx):
	return vertexes[edge_origin_idx(idx)]

func edge_destination(idx):
	return vertexes[edge_destination_idx(idx)]

func set_edge_origin(e, v):
	edge_vertexes[2*e] = v

func set_edge_destination(e, v):
	edge_vertexes[2*e+1] = v

"""
███████╗ █████╗  ██████╗███████╗███████╗
██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝
█████╗  ███████║██║     █████╗  ███████╗
██╔══╝  ██╔══██║██║     ██╔══╝  ╚════██║
██║     ██║  ██║╚██████╗███████╗███████║
╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝╚══════╝
"""
export var face_edges = PoolIntArray()

func face_count():
	return face_edges.size()

func expand_faces(more):
	face_edges.resize(face_edges.size()+more)

func get_face_edges(idx):
	return get_face_edges_starting_at(face_edges[idx], edge_side(face_edges[idx], idx))

func face_vertex_indexes(idx):
	var edges = get_face_edges(idx)
	assert(edges.size() > 0, "face %s has no edges" % [idx])
	var verts = PoolIntArray()
	for e in edges:
		if edge_face_left(e) == idx:
			verts.push_back(edge_origin_idx(e))
		elif edge_face_right(e) == idx:
			verts.push_back(edge_destination_idx(e))
		else:
			assert(false, "edge %s retured does not include face %s" % [e, idx])
	return verts

func face_vertices(idx):
	var vert_idxs = face_vertex_indexes(idx)
	var verts = PoolVector3Array()
	for idx in vert_idxs:
		verts.push_back(vertexes[idx])
	return verts

func face_normal(idx):
	return average_vertex_normal(face_vertices(idx))

"""
██████╗ ███████╗███╗   ██╗██████╗ ███████╗██████╗ ██╗███╗   ██╗ ██████╗ 
██╔══██╗██╔════╝████╗  ██║██╔══██╗██╔════╝██╔══██╗██║████╗  ██║██╔════╝ 
██████╔╝█████╗  ██╔██╗ ██║██║  ██║█████╗  ██████╔╝██║██╔██╗ ██║██║  ███╗
██╔══██╗██╔══╝  ██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗██║██║╚██╗██║██║   ██║
██║  ██║███████╗██║ ╚████║██████╔╝███████╗██║  ██║██║██║ ╚████║╚██████╔╝
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
"""
func render_face(st, f_idx, offset=Vector3.ZERO):
	var verts = face_vertices(f_idx)
	var uvs = PoolVector2Array()
	var offset_verts = PoolVector3Array()

	if verts.size() == 0:
		return

	var face_normal = face_normal(f_idx)
	var axis_a = (verts[verts.size()-1] - verts[0]).normalized()
	var axis_b = axis_a.cross(face_normal)
	var p_origin = verts[0]
	for vtx in verts:
		offset_verts.push_back(vtx + offset)
		# todo: flatten somehow. probably rotations or something:
		# calculate vertex normal, rotate into flattening.
		uvs.push_back(Vector2((vtx-p_origin).dot(axis_a), (vtx-p_origin).dot(axis_b)))
	st.add_triangle_fan(offset_verts, uvs)

func get_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for v in range(face_edges.size()):
		render_face(st, v)
	
	st.generate_normals()
	return st.commit()

func set_mesh(vs, ves, fes, evs, efs, ees):
	vertexes = PoolVector3Array(vs)
	vertex_edges = PoolIntArray(ves)
	face_edges = PoolIntArray(fes)
	edge_vertexes = PoolIntArray(evs)
	edge_faces = PoolIntArray(efs)
	edge_edges = PoolIntArray(ees)
	emit_signal("mesh_updated")

"""
████████╗ ██████╗  ██████╗ ██╗     ███████╗
╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
   ██║   ██║   ██║██║   ██║██║     ███████╗
   ██║   ██║   ██║██║   ██║██║     ╚════██║
   ██║   ╚██████╔╝╚██████╔╝███████╗███████║
   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝
"""
func begin_edit():
	pass

func commit_edit():
	emit_signal("mesh_updated")

"""
███████╗██████╗ ██╗████████╗██╗███╗   ██╗ ██████╗ 
██╔════╝██╔══██╗██║╚══██╔══╝██║████╗  ██║██╔════╝ 
█████╗  ██║  ██║██║   ██║   ██║██╔██╗ ██║██║  ███╗
██╔══╝  ██║  ██║██║   ██║   ██║██║╚██╗██║██║   ██║
███████╗██████╔╝██║   ██║   ██║██║ ╚████║╚██████╔╝
╚══════╝╚═════╝ ╚═╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
"""
func translate_face_by_median(f_idx, new_median):
	var v_idxs = face_vertex_indexes(f_idx)
	var vs = face_vertices(f_idx)
	var median = geometric_median(vs)
	var shift = new_median - median

	for idx in v_idxs:
		vertexes[idx] = vertexes[idx] + shift
	
	emit_signal("mesh_updated")

func transform_faces(faces, prev_xf, new_xf):
	var v_idxs = []
	for f in faces:
		for idx in face_vertex_indexes(f):
			if not v_idxs.has(idx):
				v_idxs.push_back(idx)
	
	transform_vertexes(v_idxs, prev_xf, new_xf)

func transform_edges(edges, prev_xf, new_xf):
	var v_idxs = []
	for e in edges:
		if not v_idxs.has(edge_origin_idx(e)):
			v_idxs.push_back(edge_origin_idx(e))
		if not v_idxs.has(edge_destination_idx(e)):
			v_idxs.push_back(edge_destination_idx(e))
	transform_vertexes(v_idxs, prev_xf, new_xf)

func transform_vertexes(vtxs, prev_xf, new_xf):
	var center = Vector3.ZERO
	for v in vtxs:
		center = center + vertexes[v]
	center = center / vtxs.size()

	var prev_rs = prev_xf.basis.inverse()
	var new_rs = new_xf.basis

	var dict = {}
	for idx in vtxs:
		vertexes[idx] = new_rs.xform(prev_rs.xform(vertexes[idx]-center))+center+new_xf.origin-prev_xf.origin

	emit_signal("mesh_updated")