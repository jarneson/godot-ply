const PlyMesh = preload("res://addons/ply/resources/ply_mesh.gd")

static func hash_vert(mdt: MeshDataTool, v_idx: int) -> String:
	return "%s" % [
		mdt.get_vertex(v_idx)
	]
	pass

#TODO: undo/redo
static func mesh(p: PlyMesh, m: ArrayMesh):
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(m, 0)
	var vertices = PackedVector3Array()
	var vertex_edges = PackedInt32Array()
	var edge_vertexes = PackedInt32Array()
	var edge_faces = PackedInt32Array()
	var edge_edges = PackedInt32Array()
	var face_edges = PackedInt32Array()
	face_edges.resize(mdt.get_face_count())
	var face_surfaces = PackedInt32Array()
	face_surfaces.resize(mdt.get_face_count())

	var seen_verts = {}
	var vert_map = {}

	for vert_idx in mdt.get_vertex_count():
		var hash = hash_vert(mdt, vert_idx)
		if seen_verts.has(hash):
			vert_map[vert_idx] = seen_verts[hash]
			continue
		var new_idx = vertices.size()
		vertices.push_back(mdt.get_vertex(vert_idx))
		vertex_edges.push_back(0)
		seen_verts[hash] = new_idx
		vert_map[vert_idx] = new_idx
	print(vertices.size())

	var seen_edges = {}
	var edge_map = {}

	for edge_idx in mdt.get_edge_count():
		var o_idx = vert_map[mdt.get_edge_vertex(edge_idx, 0)]
		var d_idx = vert_map[mdt.get_edge_vertex(edge_idx, 1)]
		var hash = ""
		if o_idx < d_idx:
			hash = "%s-%s" % [o_idx, d_idx]
		else:
			hash = "%s-%s" % [d_idx, o_idx]
		if seen_edges.has(hash):
			edge_map[edge_idx] = seen_edges[hash]
			continue
		var new_idx = edge_vertexes.size() / 2
		edge_map[edge_idx] = new_idx
		seen_edges[hash] = new_idx

		edge_vertexes.push_back(o_idx)
		edge_vertexes.push_back(d_idx)
		vertex_edges[o_idx] = new_idx

	edge_faces.resize(edge_vertexes.size())
	edge_edges.resize(edge_vertexes.size())

	for face_idx in mdt.get_face_count():
		face_surfaces[face_idx] = 0
		face_edges[face_idx] = edge_map[mdt.get_face_edge(face_idx, 0)]
		for ii in 3:
			var e_idx = edge_map[mdt.get_face_edge(face_idx, ii)]
			var v_idx = vert_map[mdt.get_face_vertex(face_idx, ii)]
			if edge_vertexes[2*e_idx] == v_idx:
				edge_faces[2*e_idx] = face_idx
				edge_edges[2*e_idx] = edge_map[mdt.get_face_edge(face_idx, (ii+1)%3)]
			elif edge_vertexes[2*e_idx+1] == v_idx:
				edge_faces[2*e_idx+1] = face_idx
				edge_edges[2*e_idx+1] = edge_map[mdt.get_face_edge(face_idx, (ii+1)%3)]
			else:
				assert(false, "bomb")

	print("ok...")
	print(edge_edges)
	print(edge_faces)
	print(face_edges)

	if true:
		p.set_mesh(
			vertices, vertex_edges, face_edges, face_surfaces, edge_vertexes, edge_faces, edge_edges
		)
