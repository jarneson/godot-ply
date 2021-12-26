const Side = preload("../utils/direction.gd")

# returns [new_edge_idx, new_vertex_idx]
static func edge(ply_mesh, edge_idx, undo_redo=null):
    var origin = ply_mesh.edge_origin(edge_idx)
    var destination = ply_mesh.edge_destination(edge_idx)
    var midpoint = (origin+destination)/2

    var left_edge = ply_mesh.get_face_edges_starting_at(edge_idx, Side.LEFT).back()

    var new_vertex_idx = ply_mesh.vertex_count()
    var new_edge_idx = ply_mesh.edge_count()

    var pre_edit = null
    if undo_redo:
        pre_edit = ply_mesh.begin_edit()
    ply_mesh.expand_edges(1)
    ply_mesh.expand_vertexes(1)

    ply_mesh.set_vertex_all(new_vertex_idx, midpoint, edge_idx)

    ply_mesh.set_edge_face_left(new_edge_idx, ply_mesh.edge_face_left(edge_idx))
    ply_mesh.set_edge_face_right(new_edge_idx, ply_mesh.edge_face_right(edge_idx))
    ply_mesh.set_edge_origin_idx(new_edge_idx, new_vertex_idx)
    ply_mesh.set_edge_destination_idx(new_edge_idx, ply_mesh.edge_destination_idx(edge_idx))
    ply_mesh.set_edge_left_cw(new_edge_idx, edge_idx)
    ply_mesh.set_edge_right_cw(new_edge_idx, ply_mesh.edge_right_cw(edge_idx))

    ply_mesh.set_edge_destination_idx(edge_idx, new_vertex_idx)
    ply_mesh.set_edge_right_cw(edge_idx, new_edge_idx)

    # todo: fix vertex->edge
    if left_edge != null:
        match ply_mesh.edge_side(left_edge, ply_mesh.edge_face_left(edge_idx)):
            Side.LEFT:
                ply_mesh.set_edge_left_cw(left_edge, new_edge_idx)
            Side.RIGHT:
                ply_mesh.set_edge_right_cw(left_edge, new_edge_idx)
    
    if undo_redo:
        ply_mesh.commit_edit("Subdivide Edge", undo_redo, pre_edit)
    return [new_edge_idx, new_vertex_idx]
