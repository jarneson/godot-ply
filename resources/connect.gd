const Side = preload("../utils/direction.gd")

static func faces(ply_mesh, f1, f2, undo_redo=null):
    print("connect faces: %s-> %s" % [f1, f2])
    var f1_edges = ply_mesh.get_face_edges(f1)
    var f2_edges = ply_mesh.get_face_edges(f2)

    if f1_edges.size() != f2_edges.size():
        print("faces have different number of edges")
        return
    print(f1_edges)
    print(f2_edges)

    var f10_origin = ply_mesh.edge_origin(f1_edges[0])
    var f10_destination = ply_mesh.edge_destination(f1_edges[0])
    var f10_side = ply_mesh.edge_side(f1_edges[0], f1)
    if f10_side == Side.RIGHT:
        var tmp = f10_origin
        f10_origin = f10_destination
        f10_destination = f10_origin

    var min_dist = null
    var min_e = null
    for e in f2_edges:
        var e_origin = ply_mesh.edge_origin(e)
        var e_destination = ply_mesh.edge_destination(e)
        var e_side = ply_mesh.edge_side(e, f2)
        if e_side == Side.RIGHT:
            var tmp = e_origin
            e_origin = e_destination
            e_destination = e_origin
        var dist = (e_destination-f10_origin).length() + (e_origin-f10_destination).length()
        if not min_dist or dist < min_dist:
            min_dist = dist
            min_e = e

    print(min_e, ": ", min_dist)
    f2_edges = ply_mesh.get_face_edges_starting_at(min_e, ply_mesh.edge_side(min_e, f2))
    var tmp = f2_edges.pop_front()
    f2_edges.invert()
    f2_edges.push_front(tmp)

    print(f1_edges)
    print(f2_edges)

    var pre_edit = ply_mesh.begin_edit()
    # insert faces between edge maps
    var edge_start = ply_mesh.edge_count()
    var face_start = ply_mesh.face_count()
    ply_mesh.expand_edges(f1_edges.size())
    ply_mesh.expand_faces(f1_edges.size())
    for arr_idx in range(f1_edges.size()):
        var prev = arr_idx-1
        if prev < 0:
            prev = f1_edges.size()-1
        var curr = arr_idx
        var next = arr_idx+1
        if next >= f1_edges.size():
            next = 0

        var e1 = f1_edges[arr_idx]
        var e1_side = ply_mesh.edge_side(e1, f1)
        var e2 = f2_edges[arr_idx]
        var e2_side = ply_mesh.edge_side(e2, f2)

        var origin = ply_mesh.edge_destination_idx(e1)
        if e1_side == Side.RIGHT:
            origin = ply_mesh.edge_origin_idx(e1)

        var destination = ply_mesh.edge_origin_idx(e2)
        if e2_side == Side.RIGHT:
            destination = ply_mesh.edge_destination_idx(e2)

        var new_face = face_start+curr
        var new_edge = edge_start+curr
        ply_mesh.set_edge_face(e1, e1_side, new_face)
        ply_mesh.set_edge_cw(e1, e1_side, edge_start+next)

        ply_mesh.set_edge_face(e2, e2_side, new_face)
        ply_mesh.set_edge_cw(e2, e2_side, edge_start+curr)

        ply_mesh.set_edge_origin_idx(new_edge, destination)
        ply_mesh.set_edge_destination_idx(new_edge, origin)
        ply_mesh.set_edge_face_right(new_edge, new_face)
        ply_mesh.set_edge_right_cw(new_edge, f1_edges[curr])
        ply_mesh.set_edge_face_left(new_edge, face_start+prev)
        ply_mesh.set_edge_left_cw(new_edge, f2_edges[prev])

        ply_mesh.set_face_edge(new_face, new_edge)
        ply_mesh.set_face_surface(new_face, ply_mesh.face_surface(f1))

    # remove old faces
    ply_mesh.evict_faces([f1, f2])

    if undo_redo:
        ply_mesh.commit_edit("Connect Faces", undo_redo, pre_edit)
    pass