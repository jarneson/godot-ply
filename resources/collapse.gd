const Side = preload("../utils/direction.gd")

static func edges(ply_mesh, edge_indices, undo_redo = null):
    print("collapse edges: ", edge_indices)
    var pre_edit
    if undo_redo:
        pre_edit = ply_mesh.begin_edit()
    # group edges into connected graphs
    var groups = [edge_indices]

    var evict_edges = []
    var evict_vertexes = []
    var evict_faces = []

    var vertex_updates = {}
    # foreach group
    for group in groups:
        print("collapse group: ", group)
        # create a new vertex at the mean of vertexes of connected edges
        var seen_vtxs = {}
        var sum = Vector3.ZERO
        for edge_idx in group:
            var o = ply_mesh.edge_origin_idx(edge_idx)
            var d = ply_mesh.edge_destination_idx(edge_idx)
            if not seen_vtxs.has(o):
                seen_vtxs[o] = true
                sum += ply_mesh.vertexes[o]
                evict_vertexes.push_back(o)
            if not seen_vtxs.has(d):
                seen_vtxs[d] = true
                sum += ply_mesh.vertexes[d]
                evict_vertexes.push_back(d)

        var new_vertex = ply_mesh.vertex_count()
        ply_mesh.expand_vertexes(1)
        ply_mesh.vertexes[new_vertex] = sum / seen_vtxs.size()

        for v_idx in seen_vtxs:
            var neighbors = ply_mesh.get_vertex_edges(v_idx)
            for neighbor in neighbors:
                if group.has(edge_indices):
                    continue
                ply_mesh.vertex_edges[new_vertex] = neighbor
                if ply_mesh.edge_origin_idx(neighbor) == v_idx:
                    ply_mesh.set_edge_origin_idx(neighbor, new_vertex)
                elif ply_mesh.edge_destination_idx(neighbor) == v_idx:
                    ply_mesh.set_edge_destination_idx(neighbor, new_vertex)
                else:
                    assert(false, "edge %s does not include vertex %s" % [neighbor, v_idx])

        # for each edge
        for edge_idx in group:
            print("collapse edge: ", edge_idx)
            # for each edge adjacent to origin, make it point to new vertex
            # for each edge adjacent to destination, make it point to new vertex
            if evict_edges.has(edge_idx):
                print("getting evicted")
                continue

            # fix winding for left face
            # fix winding for right face
            for side in [Side.LEFT, Side.RIGHT]:
                print("collapse edge side: ", side)
                print(ply_mesh.edge_edges)
                print(ply_mesh.edge_faces)
                var f_idx = ply_mesh.edge_face(edge_idx, side) 
                var boundary_edges = ply_mesh.get_face_edges_starting_at(edge_idx, side)
                if boundary_edges.size() == 3:
                    var winner = boundary_edges[1]
                    var loser = boundary_edges[2]
                    evict_faces.push_back(f_idx)
                    evict_edges.push_back(loser)

                    ply_mesh.set_edge_cw(
                        winner,
                        ply_mesh.edge_side(winner, f_idx),
                        ply_mesh.edge_cw(
                            loser,
                            Side.invert(ply_mesh.edge_side(loser, f_idx))
                        )
                    )

                    ply_mesh.set_edge_face(
                        winner,
                        ply_mesh.edge_side(winner, f_idx),
                        ply_mesh.edge_face(
                            loser,
                            Side.invert(ply_mesh.edge_side(loser, f_idx))
                        )
                    )

                    ply_mesh.set_vertex_edge(ply_mesh.edge_origin_idx(winner), winner)
                    ply_mesh.set_vertex_edge(ply_mesh.edge_destination_idx(winner), winner)

                    var fix_face = ply_mesh.edge_face(
                        loser,
                        Side.invert(ply_mesh.edge_side(loser, f_idx))
                    )

                    var fix_edge = ply_mesh.get_face_edges_starting_at(
                        loser,
                        Side.invert(ply_mesh.edge_side(loser, f_idx))
                    ).back()
                    ply_mesh.set_edge_cw(fix_edge, ply_mesh.edge_side(fix_edge, fix_face), winner)
                    ply_mesh.set_face_edge(fix_face, winner)
                    continue
                var last_edge = boundary_edges.back()
                ply_mesh.set_edge_cw(last_edge, ply_mesh.edge_side(last_edge, f_idx), boundary_edges[1])
                ply_mesh.face_edges[f_idx] = boundary_edges[1]

            evict_edges.push_back(edge_idx)
    print("computed it")
    ply_mesh.evict_vertices(evict_vertexes, evict_edges)
    ply_mesh.evict_faces(evict_faces, evict_edges)
    ply_mesh.evict_edges(evict_edges)
    print("Done")
    if undo_redo:
        ply_mesh.commit_edit("Collapse Edges", undo_redo, pre_edit)