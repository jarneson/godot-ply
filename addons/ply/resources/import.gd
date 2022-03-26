const PlyMesh = preload("res://addons/ply/resources/ply_mesh.gd")

# ahhh

static func mesh(p: PlyMesh, m: ArrayMesh):
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(m, 0)
	var vertices: PackedVector3Array = []
	vertices.resize(mdt.get_vertex_count())
	var vertex_edges: PackedInt32Array
	var edge_vertexes: PackedInt32Array
	var face_edges: PackedInt32Array
	var face_surfaces: PackedInt32Array
	var edge_faces: PackedInt32Array
	var edge_edges: PackedInt32Array
	for vert_i in mdt.get_vertex_count():
		vertices[vert_i] = mdt.get_vertex(vert_i)
		var new_vertex_edges = mdt.get_vertex_edges(vert_i)
		vertex_edges.append_array(new_vertex_edges)
		for edge in new_vertex_edges:
			for vert_i in 2:
				var new_edge_vertex = mdt.get_edge_vertex(edge, vert_i)
				edge_vertexes.push_back(new_edge_vertex)
				for edge_i in mdt.get_vertex_edges(new_edge_vertex):
					if edge_i == edge:
						edge_edges.push_back(edge_i)
						break
	for edge_i in edge_edges:
		for face_i in mdt.get_edge_faces(edge_i):
			face_edges.push_back(mdt.get_face_edge(face_i, 2))
			face_edges.push_back(mdt.get_face_edge(face_i, 1))
			face_edges.push_back(mdt.get_face_edge(face_i, 0))
			edge_faces.push_back(face_i)
	face_surfaces.push_back(0)

	p.set_mesh(
		vertices, vertex_edges, face_edges, face_surfaces, edge_vertexes, edge_faces, []
	)
