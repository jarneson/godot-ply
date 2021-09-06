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
enum Side {UNKNOWN, LEFT, RIGHT}

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

func edge_side(e_idx, f_idx):
	if edge_face_left(e_idx) == f_idx:
		return Side.LEFT
	if edge_face_right(e_idx) == f_idx:
		return Side.RIGHT
	assert(false, "edge %s does not touch face %s" % [e_idx, f_idx])

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

func edge_destination_idx(idx):
	return edge_vertexes[2*idx+1]

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

func face_edges(idx):
	var start = face_edges[idx]
	var edges = PoolIntArray()
	edges.push_back(start)
	var e = start
	if edge_face_left(e) == idx:
		e = edge_left_cw(e)
	elif edge_face_right(e) == idx:
		e = edge_right_cw(e)
	var iters = 0
	while iters < 100 and e != start:
		edges.push_back(e)
		if edge_face_left(e) == idx:
			e = edge_left_cw(e)
		elif edge_face_right(e) == idx:
			e = edge_right_cw(e)
		else:
			assert(false, "bad iter for face %s with start %s halted on %s" % [idx, start, e])
		iters = iters + 1
	if iters >= 100:
		assert(false, "too many iters for face %s with start %s halted on %s" % [idx, start, e])
	return edges

func face_vertex_indexes(idx):
	var edges = face_edges(idx)
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

func extrude_face(f_idx, distance=1):
	# this is face normal extrusion, better default might be per vertex normal
	var extrude_direction = distance*face_normal(f_idx)
	var existing_edges = face_edges(f_idx)

	var vertex_start = vertexes.size()
	var face_start = face_edges.size()
	var edge_start = edge_vertexes.size()/2

	# expand arrays
	# adding k new vertices
	vertexes.resize(vertexes.size()+existing_edges.size())
	vertex_edges.resize(vertex_edges.size()+existing_edges.size())
	# adding k+1 new faces 
	face_edges.resize(face_edges.size()+existing_edges.size())
	# adding 2*k new edges
	edge_vertexes.resize(edge_vertexes.size()+existing_edges.size()*2*2)
	edge_faces.resize(edge_faces.size()+existing_edges.size()*2*2)
	edge_edges.resize(edge_edges.size()+existing_edges.size()*2*2)

	face_edges[f_idx] = edge_start+existing_edges.size()
	# how to keep track of and assign new vertexes?
	for ee_idx in range(existing_edges.size()):
		var e_idx = existing_edges[ee_idx]
		var curr = ee_idx
		var next = ee_idx+1
		if next == existing_edges.size():
			next = 0
		var prev = ee_idx-1
		if prev == -1:
			prev = existing_edges.size()-1
		var direction = edge_side(e_idx, f_idx)

		var x_face_idx = face_start+curr
		var x_edge_idx = edge_start+curr
		var new_edge_idx = edge_start+existing_edges.size()+curr

		match direction:
			Side.LEFT:
				# create new vtx
				vertexes[vertex_start+curr] = edge_destination(e_idx)+extrude_direction
				vertex_edges[vertex_start+curr] = x_edge_idx

				face_edges[x_face_idx] = x_edge_idx

				# update edge face and cw
				set_edge_face_left(e_idx, x_face_idx)
				set_edge_left_cw(  e_idx, x_edge_idx)

				# extruded edge
				set_edge_origin(     x_edge_idx, vertex_start+curr)
				set_edge_destination(x_edge_idx, edge_destination_idx(e_idx))
				set_edge_face_right( x_edge_idx, x_face_idx)
				set_edge_right_cw(   x_edge_idx, new_edge_idx)
				set_edge_face_left(  x_edge_idx, face_start+next)
				set_edge_left_cw(    x_edge_idx, existing_edges[next])

				# new edge
				set_edge_origin(     new_edge_idx, vertex_start+prev)
				set_edge_destination(new_edge_idx, vertex_start+curr)
				set_edge_face_right( new_edge_idx, x_face_idx)
				set_edge_right_cw(   new_edge_idx, edge_start+prev)
				set_edge_face_left(  new_edge_idx, f_idx)
				set_edge_left_cw(    new_edge_idx, edge_start+existing_edges.size()+next)
			Side.RIGHT:
				# create new vtx
				vertexes[vertex_start+curr] = edge_origin(e_idx)+extrude_direction
				vertex_edges[vertex_start+curr] = x_edge_idx

				face_edges[x_face_idx] = x_edge_idx

				# update edge face and cw
				set_edge_face_right(e_idx, x_face_idx)
				set_edge_right_cw(  e_idx, x_edge_idx)

				# extruded edge
				set_edge_origin(     x_edge_idx, vertex_start+curr)
				set_edge_destination(x_edge_idx, edge_origin_idx(e_idx))
				set_edge_face_right( x_edge_idx, x_face_idx)
				set_edge_right_cw(   x_edge_idx, new_edge_idx)
				set_edge_face_left(  x_edge_idx, face_start+next)
				set_edge_left_cw(    x_edge_idx, existing_edges[next])

				# new edge
				set_edge_origin(     new_edge_idx, vertex_start+prev)
				set_edge_destination(new_edge_idx, vertex_start+curr)
				set_edge_face_right( new_edge_idx, x_face_idx)
				set_edge_right_cw(   new_edge_idx, edge_start+prev)
				set_edge_face_left(  new_edge_idx, f_idx)
				set_edge_left_cw(    new_edge_idx, edge_start+existing_edges.size()+next)
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