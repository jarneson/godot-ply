const PlyMesh = preload("res://addons/ply/resources/ply_mesh.gd")

#TODO: undo/redo
static func mesh(p: PlyMesh, m: ArrayMesh):
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(m, 0)
	print(mdt.get_vertex_count())
	var vertices = PackedVector3Array()
	vertices.resize(mdt.get_vertex_count())
	var vertex_edges = PackedInt32Array()
	vertex_edges.resize(mdt.get_vertex_count())
	var edge_vertexes = PackedInt32Array()
	edge_vertexes.resize(mdt.get_edge_count()*2)
	var edge_faces = PackedInt32Array()
	edge_faces.resize(mdt.get_edge_count()*2)
	var edge_edges = PackedInt32Array()
	edge_edges.resize(mdt.get_edge_count()*2)
	var face_edges = PackedInt32Array()
	face_edges.resize(mdt.get_face_count())
	var face_surfaces = PackedInt32Array()
	face_surfaces.resize(mdt.get_face_count())

	for vert_idx in mdt.get_vertex_count():
		vertices[vert_idx] = mdt.get_vertex(vert_idx)
		print(mdt.get_vertex_meta(vert_idx))

	for edge_idx in mdt.get_edge_count():
		vertex_edges[mdt.get_edge_vertex(edge_idx, 0)] = edge_idx
		edge_vertexes[edge_idx*2] = mdt.get_edge_vertex(edge_idx, 0)
		edge_vertexes[edge_idx*2+1] = mdt.get_edge_vertex(edge_idx, 1)

	for face_idx in mdt.get_face_count():
		face_surfaces[face_idx] = 0
		face_edges[face_idx] = mdt.get_face_edge(face_idx, 0)
		for ii in 3:
			var e_idx = mdt.get_face_edge(face_idx, ii)
			var v_idx = mdt.get_face_vertex(face_idx, ii)
			if edge_vertexes[2*e_idx] == v_idx:
				edge_faces[2*e_idx] = face_idx
				edge_edges[2*e_idx] = mdt.get_face_edge(face_idx, (ii+1)%3)
			elif edge_vertexes[2*e_idx+1] == v_idx:
				edge_faces[2*e_idx+1] = face_idx
				edge_edges[2*e_idx+1] = mdt.get_face_edge(face_idx, (ii+1)%3)
			else:
				assert(false, "bomb")

	print("ok...")
	print(edge_edges)

	if false:
		p.set_mesh(
			vertices, vertex_edges, face_edges, face_surfaces, edge_vertexes, edge_faces, []
		)
