const Side = preload("../utils/direction.gd")

# only works for quads, adjust offset to change direction
static func get_face_loop(ply_mesh, f_idx, edge_offset=0):
    var out = [f_idx]
    var face_edges = ply_mesh.get_face_edges(f_idx)
    if face_edges.size() != 4:
        # not a quad
        return out
    var next_edge = face_edges[edge_offset]
    var next = ply_mesh.edge_face(next_edge, Side.invert(ply_mesh.edge_side(next_edge, f_idx)))
    while next != f_idx:
        face_edges = ply_mesh.get_face_edges_starting_at(next_edge, ply_mesh.edge_side(next_edge, next))
        if face_edges.size() != 4:
            break
        out.push_back(next)
        next_edge = face_edges[2]
        next = ply_mesh.edge_face(next_edge, Side.invert(ply_mesh.edge_side(next_edge, next)))
    if next == f_idx:
        # full loop
        return out
    # other side
    face_edges = ply_mesh.get_face_edges(f_idx)
    next_edge = face_edges[(edge_offset + 2)%4]
    next = ply_mesh.edge_face(next_edge, Side.invert(ply_mesh.edge_side(next_edge, f_idx)))
    while next != f_idx:
        face_edges = ply_mesh.get_face_edges_starting_at(next_edge, ply_mesh.edge_side(next_edge, next))
        if face_edges.size() != 4:
            break
        out.push_back(next)
        next_edge = face_edges[2]
        next = ply_mesh.edge_face(next_edge, Side.invert(ply_mesh.edge_side(next_edge, next)))
    
    return out