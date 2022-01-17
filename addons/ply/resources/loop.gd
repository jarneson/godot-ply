const Side = preload("res://addons/ply/utils/direction.gd")
const Subdivide = preload("res://addons/ply/resources/subdivide.gd")
const Euler = preload("res://addons/ply/resources/euler.gd")


# only works for quads, adjust offset to change direction
static func get_face_loop(ply_mesh, f_idx, edge_offset = 0) -> Array:
	print("%s / %s" % [f_idx, edge_offset])
	var out = [f_idx]
	var face_edges = ply_mesh.get_face_edges(f_idx)
	if face_edges.size() != 4:
		# not a quad
		return [out, false]
	var next_edge = face_edges[edge_offset]
	var next = ply_mesh.edge_face(next_edge, Side.invert(ply_mesh.edge_side(next_edge, f_idx)))
	while next != f_idx:
		face_edges = ply_mesh.get_face_edges_starting_at(
			next_edge, ply_mesh.edge_side(next_edge, next)
		)
		if face_edges.size() != 4:
			break
		out.push_back(next)
		next_edge = face_edges[2]
		next = ply_mesh.edge_face(next_edge, Side.invert(ply_mesh.edge_side(next_edge, next)))
	if next == f_idx:
		# full loop
		return [out, true]
	# other side
	face_edges = ply_mesh.get_face_edges(f_idx)
	next_edge = face_edges[(edge_offset + 2) % 4]
	next = ply_mesh.edge_face(next_edge, Side.invert(ply_mesh.edge_side(next_edge, f_idx)))

	# this could be either left or right, need to look at both edges, and see which ones point to the destination
	while next != f_idx:
		face_edges = ply_mesh.get_face_edges_starting_at(
			next_edge, ply_mesh.edge_side(next_edge, next)
		)
		if face_edges.size() != 4:
			break
		out.push_back(next)
		next_edge = face_edges[2]
		next = ply_mesh.edge_face(next_edge, Side.invert(ply_mesh.edge_side(next_edge, next)))

	return [out, false]


# only works for verts with 4 edges
static func get_edge_loop(ply_mesh, e_idx) -> Array:
	var out = []
	var next_vtx = ply_mesh.edge_origin_idx(e_idx)
	var next_edge = e_idx
	var first = true
	var stopped = false
	while first or next_edge != e_idx:
		first = false
		out.push_back(next_edge)
		var neighbors = ply_mesh.get_vertex_edges(next_vtx, next_edge)
		if neighbors.size() != 4:
			stopped = true
			break
		next_edge = neighbors[2]
		if ply_mesh.edge_origin_idx(next_edge) == next_vtx:
			next_vtx = ply_mesh.edge_destination_idx(next_edge)
		elif ply_mesh.edge_destination_idx(next_edge) == next_vtx:
			next_vtx = ply_mesh.edge_origin_idx(next_edge)
		else:
			assert(false, "edge %s does not contain vertex %s" % [next_edge, next_vtx])

	if not stopped and next_edge == e_idx:
		# full loop
		return out

	next_vtx = ply_mesh.edge_destination_idx(e_idx)
	next_edge = e_idx
	first = true
	while first or next_edge != e_idx:
		if not first:  # don't double insert the start edge
			out.push_back(next_edge)
		first = false
		var neighbors = ply_mesh.get_vertex_edges(next_vtx, next_edge)
		if neighbors.size() != 4:
			break
		next_edge = neighbors[2]
		if ply_mesh.edge_origin_idx(next_edge) == next_vtx:
			next_vtx = ply_mesh.edge_destination_idx(next_edge)
		elif ply_mesh.edge_destination_idx(next_edge) == next_vtx:
			next_vtx = ply_mesh.edge_origin_idx(next_edge)
		else:
			assert(false, "edge %s does not contain vertex %s" % [next_edge, next_vtx])

	return out


static func edge_cut(ply_mesh, e_idx, undo_redo = null):
	# accumulate impacted faces and edges
	# walk left first
	var edges = {}
	var faces = {}
	var full_loop = false
	var curr_edge = e_idx
	var curr_side = Side.LEFT
	while true:
		var f_edges = ply_mesh.get_face_edges_starting_at(curr_edge, curr_side)
		if f_edges.size() != 4:
			break
		var f = ply_mesh.edge_face(curr_edge, curr_side)
		edges[f_edges[0]] = []
		edges[f_edges[2]] = []
		faces[f] = f_edges
		curr_edge = f_edges[2]
		if curr_edge == e_idx:
			full_loop = true
			break
		curr_side = Side.invert(ply_mesh.edge_side(curr_edge, f))
	if !full_loop:
		curr_edge = e_idx
		curr_side = Side.RIGHT
		while true:
			var f_edges = ply_mesh.get_face_edges_starting_at(curr_edge, curr_side)
			if f_edges.size() != 4:
				break
			var f = ply_mesh.edge_face(curr_edge, curr_side)
			edges[f_edges[0]] = []
			edges[f_edges[2]] = []
			faces[f] = f_edges
			curr_edge = f_edges[2]
			if curr_edge == e_idx:
				full_loop = true
				break
			curr_side = Side.invert(ply_mesh.edge_side(curr_edge, f))

	var pre_edit = null
	if undo_redo:
		pre_edit = ply_mesh.begin_edit()

	# semv on each edge
	for e in edges:
		edges[e] = Euler.semv(ply_mesh, e)

	# sfme on each face
	for f in faces:
		Euler.sfme(ply_mesh, f, edges[faces[f][0]][0], edges[faces[f][2]][0])

	if undo_redo:
		ply_mesh.commit_edit("Edge Loop Cut", undo_redo, pre_edit)
