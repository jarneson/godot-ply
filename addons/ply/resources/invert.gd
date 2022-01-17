const Side = preload("res://addons/ply/utils/direction.gd")


static func normals(ply_mesh) -> void:
	# reverse the winding
	var new_edge_edges = PoolIntArray()
	var new_edge_vertexes = PoolIntArray()
	new_edge_edges.resize(ply_mesh.edge_count() * 2)
	new_edge_vertexes.resize(ply_mesh.edge_count() * 2)
	for e in range(ply_mesh.edge_count()):
		for side in [Side.LEFT, Side.RIGHT]:
			var cw = ply_mesh.edge_cw(e, side)
			var f = ply_mesh.edge_face(e, side)
			var new_side = ply_mesh.edge_side(cw, f)
			new_edge_edges[cw * 2 + (new_side - 1)] = e
			new_edge_vertexes[e * 2] = ply_mesh.edge_destination_idx(e)
			new_edge_vertexes[e * 2 + 1] = ply_mesh.edge_origin_idx(e)
	ply_mesh.set_edge_vertexes(new_edge_vertexes)
	ply_mesh.set_edge_edges(new_edge_edges)
