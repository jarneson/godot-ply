const Euler = preload("res://addons/ply/resources/euler.gd")


static func object(ply_mesh):
	var f = []
	for i in range(ply_mesh.face_count()):
		f.push_back(i)
	return faces(ply_mesh, f)


static func faces(ply_mesh, face_indices) -> void:
	for face_idx in face_indices:
		var verts = ply_mesh.face_vertex_indexes(face_idx)
		while verts.size() > 3:
			var min_dot = null
			var min_pair = null
			for curr in range(verts.size()):
				var prev = curr - 1
				if curr < 0:
					prev = verts.size() - 1
				var next = curr + 1
				if next >= verts.size():
					next = 0

				var va = ply_mesh.vertexes[verts[prev]]
				var vb = ply_mesh.vertexes[verts[curr]]
				var vc = ply_mesh.vertexes[verts[next]]
				var ab = vb - va
				var bc = vc - vb
				var d = ab.dot(bc)
				if not min_dot or d < min_dot:
					min_pair = [verts[prev], verts[next]]
					min_dot = d
			Euler.sfme(ply_mesh, face_idx, min_pair[1], min_pair[0])

			verts = ply_mesh.face_vertex_indexes(face_idx)
