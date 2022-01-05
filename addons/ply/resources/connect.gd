const Side = preload("res://addons/ply/utils/direction.gd")

static func faces(ply_mesh, f1, f2, undo_redo=null):
    var f1_edges = ply_mesh.get_face_edges(f1)
    var f2_edges = ply_mesh.get_face_edges(f2)

    if f1_edges.size() != f2_edges.size():
        print("faces have different number of edges")
        return

    var seen_verts = {}
    for e in f1_edges:
        seen_verts[ply_mesh.edge_origin_idx(e)] = true
        seen_verts[ply_mesh.edge_destination_idx(e)] = true
    for e in f2_edges:
        if seen_verts.has(ply_mesh.edge_origin_idx(e)) or seen_verts.has(ply_mesh.edge_destination_idx(e)):
            print("faces share a vertex")
            return

    # there must be a better way to do this
    var min_dist = null
    var min_pair = null
    # we should project f2 onto the plane for e1_0
    for e1 in f1_edges:
        var e1_origin = ply_mesh.edge_origin(e1)
        var e1_destination = ply_mesh.edge_destination(e1)
        var e1_side = ply_mesh.edge_side(e1, f1)
        if e1_side == Side.RIGHT:
            var tmp = e1_origin
            e1_origin = e1_destination
            e1_destination = tmp
        for e2 in f2_edges:
            var e2_origin = ply_mesh.edge_origin(e2)
            var e2_destination = ply_mesh.edge_destination(e2)
            var e2_side = ply_mesh.edge_side(e2, f2)
            if e2_side == Side.RIGHT:
                var tmp = e2_origin
                e2_origin = e2_destination
                e2_destination = tmp
            var dist = (e2_destination-e1_origin).length() + (e2_origin-e1_destination).length()
            if not min_dist or dist < min_dist:
                min_dist = dist
                min_pair = [e1, e2]

    f1_edges = ply_mesh.get_face_edges_starting_at(min_pair[0], ply_mesh.edge_side(min_pair[0], f1))
    f2_edges = ply_mesh.get_face_edges_starting_at(min_pair[1], ply_mesh.edge_side(min_pair[1], f2))
    f2_edges.invert()
    f2_edges.push_front(f2_edges.pop_back())

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

    var manifold_err = ply_mesh.is_manifold()
    if manifold_err:
        ply_mesh.reject_edit(pre_edit)
        print("Collapse would result in non-manifold mesh: ", manifold_err)
        return false

    if undo_redo:
        ply_mesh.commit_edit("Connect Faces", undo_redo, pre_edit)
    pass