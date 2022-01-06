const Subdivide = preload("res://addons/ply/resources/subdivide.gd")


static func nGon(ply_mesh, vertices, undo_redo = null, action_name = "Generate N-Gon"):
	var vertex_edges = []
	var edge_vertexes = []
	var face_edges = [0, 0]
	var face_surfaces = [0, 0]
	var edge_faces = []
	var edge_edges = []

	for v_idx in range(vertices.size()):
		var curr = v_idx
		var prev = v_idx - 1
		if prev < 0:
			prev = vertices.size() - 1
		var next = v_idx + 1
		if next >= vertices.size():
			next = 0
		vertex_edges.push_back(curr)
		edge_vertexes.push_back(curr)
		edge_vertexes.push_back(next)
		edge_faces.push_back(1)
		edge_faces.push_back(0)
		edge_edges.push_back(prev)
		edge_edges.push_back(next)

	var pre_edit = ply_mesh.begin_edit()
	ply_mesh.set_mesh(
		vertices, vertex_edges, face_edges, face_surfaces, edge_vertexes, edge_faces, edge_edges
	)
	if undo_redo:
		ply_mesh.commit_edit(action_name, undo_redo, pre_edit)


static func icosphere(ply_mesh, radius, subdivides):
	var t = (1.0 + sqrt(5.0)) / 2.0
	var vertices = [
		Vector3(-1, t, 0),
		Vector3(1, t, 0),
		Vector3(-1, -t, 0),
		Vector3(1, -t, 0),
		Vector3(0, -1, t),
		Vector3(0, 1, t),
		Vector3(0, -1, -t),
		Vector3(0, 1, -t),
		Vector3(t, 0, -1),
		Vector3(t, 0, 1),
		Vector3(-t, 0, -1),
		Vector3(-t, 0, 1),
	]
	var vertex_edges = []
	vertex_edges.resize(12)
	var face_edges = []
	var face_surfaces = []
	face_edges.resize(20)
	face_surfaces.resize(20)
	var edge_vertexes = [
		# around 0
		0,
		5,  #0
		5,
		11,  #1
		11,
		0,  #2
		0,
		1,  #3
		1,
		5,  #4
		0,
		7,  #5
		7,
		1,  #6
		0,
		10,  #7
		10,
		7,  #8
		11,
		10,  #9
		# adjacent
		1,
		9,  #10
		9,
		5,  #11
		5,
		4,  #12
		4,
		11,  #13
		11,
		2,  #14
		2,
		10,  #15
		10,
		6,  #16
		6,
		7,  #17
		7,
		8,  #18
		8,
		1,  #19
		# around 3
		3,
		4,  #20
		4,
		9,  #21
		9,
		3,  #22
		3,
		2,  #23
		2,
		4,  #24
		3,
		6,  #25
		6,
		2,  #26
		3,
		8,  #27
		8,
		6,  #28
		9,
		8,  #29
	]

	var edge_edges = [
		3,
		1,
		12,
		2,
		9,
		0,
		5,
		4,
		10,
		0,
		7,
		6,
		18,
		3,
		2,
		8,
		16,
		5,
		14,
		7,
		19,
		11,
		21,
		4,
		11,
		13,
		24,
		1,
		13,
		15,
		26,
		9,
		15,
		17,
		28,
		8,
		17,
		19,
		29,
		6,
		23,
		21,
		12,
		22,
		29,
		20,
		25,
		24,
		14,
		20,
		27,
		26,
		16,
		23,
		22,
		28,
		18,
		25,
		10,
		27,
	]

	var edge_faces = [
		1,
		0,
		6,
		0,
		4,
		0,
		2,
		1,
		5,
		1,
		3,
		2,
		9,
		2,
		4,
		3,
		8,
		3,
		7,
		4,
		17,
		5,
		16,
		5,
		16,
		6,
		15,
		6,
		15,
		7,
		19,
		7,
		19,
		8,
		18,
		8,
		18,
		9,
		17,
		9,
		11,
		10,
		16,
		10,
		14,
		10,
		12,
		11,
		15,
		11,
		13,
		12,
		19,
		12,
		14,
		13,
		18,
		13,
		17,
		14,
	]

	for ei in range(edge_vertexes.size() / 2):
		vertex_edges[edge_vertexes[ei * 2]] = ei
		vertex_edges[edge_vertexes[ei * 2 + 1]] = ei
		face_edges[edge_faces[ei * 2]] = ei
		face_edges[edge_faces[ei * 2 + 1]] = ei

	for idx in range(20):
		face_surfaces[idx] = 0
	ply_mesh.set_mesh(
		vertices, vertex_edges, face_edges, face_surfaces, edge_vertexes, edge_faces, edge_edges
	)

	for i in range(subdivides):
		Subdivide.object(ply_mesh)
		for v_idx in ply_mesh.vertex_count():
			ply_mesh.set_vertex_all(
				v_idx, ply_mesh.vertexes[v_idx].normalized() * radius, ply_mesh.vertex_edges[v_idx]
			)
