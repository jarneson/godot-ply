const Side = preload("../utils/direction.gd")
const Subdivide = preload("./subdivide.gd")

# only works for quads, adjust offset to change direction
static func get_face_loop(ply_mesh, f_idx, edge_offset=0):
    var out = [f_idx]
    var face_edges = ply_mesh.get_face_edges(f_idx)
    if face_edges.size() != 4:
        # not a quad
        return [out, false]
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
        return [out, true]
    # other side
    face_edges = ply_mesh.get_face_edges(f_idx)
    next_edge = face_edges[(edge_offset + 2)%4]
    next = ply_mesh.edge_face(next_edge, Side.invert(ply_mesh.edge_side(next_edge, f_idx)))

    # this could be either left or right, need to look at both edges, and see which ones point to the destination
    while next != f_idx:
        face_edges = ply_mesh.get_face_edges_starting_at(next_edge, ply_mesh.edge_side(next_edge, next))
        if face_edges.size() != 4:
            break
        out.push_back(next)
        next_edge = face_edges[2]
        next = ply_mesh.edge_face(next_edge, Side.invert(ply_mesh.edge_side(next_edge, next)))
    
    return [out, false]

static func _apply_cut(ply_mesh, curr, next, walk, subdivides):
    var new_edge_idx = ply_mesh.edge_count()
    var new_face_idx = ply_mesh.face_count()
    ply_mesh.expand_edges(1)
    ply_mesh.expand_faces(1)

    var existing_face = ply_mesh.edge_face(walk[curr][0], walk[curr][1])
    print("process %s: <%s %s> = %s" % [walk[0], new_face_idx, existing_face, new_edge_idx])
    ply_mesh.face_edges[new_face_idx] = new_edge_idx
    ply_mesh.face_edges[existing_face] = new_edge_idx

    ply_mesh.set_edge_origin(new_edge_idx, subdivides[curr][2])
    ply_mesh.set_edge_destination(new_edge_idx, subdivides[next][2])
    ply_mesh.set_edge_face_left(new_edge_idx, new_face_idx)
    ply_mesh.set_edge_face_right(new_edge_idx, existing_face)

    var int_side = ply_mesh.edge_side(walk[curr][2], existing_face)
    match int_side:
        Side.LEFT:
            ply_mesh.set_edge_face_left(walk[curr][2], new_face_idx)
        Side.RIGHT:
            ply_mesh.set_edge_face_right(walk[curr][2], new_face_idx)

    match walk[curr][1]:
        Side.LEFT:
            ply_mesh.set_edge_left_cw(new_edge_idx, subdivides[curr][0])
            ply_mesh.set_edge_left_cw(subdivides[curr][1], new_edge_idx)
            ply_mesh.set_edge_face_left(subdivides[curr][0], new_face_idx)
        Side.RIGHT:
            ply_mesh.set_edge_left_cw(new_edge_idx, subdivides[curr][1])
            ply_mesh.set_edge_right_cw(subdivides[curr][0], new_edge_idx)
            ply_mesh.set_edge_face_right(subdivides[curr][1], new_face_idx)
    # inverted as it points to the next face!
    match walk[next][1]:
        Side.LEFT:
            ply_mesh.set_edge_right_cw(new_edge_idx, subdivides[next][1])
            ply_mesh.set_edge_right_cw(subdivides[next][0], new_edge_idx)
            ply_mesh.set_edge_face_right(subdivides[next][0], new_face_idx)
        Side.RIGHT:
            ply_mesh.set_edge_right_cw(new_edge_idx, subdivides[next][0])
            ply_mesh.set_edge_left_cw(subdivides[next][1], new_edge_idx)
            ply_mesh.set_edge_face_left(subdivides[next][1], new_face_idx)
    print("edge %s faces [ %s | %s ] edges [%s | %s]" % [new_edge_idx, new_face_idx, existing_face, ply_mesh.edge_left_cw(new_edge_idx), ply_mesh.edge_right_cw(new_edge_idx)])

static func _edge_cut_walk(ply_mesh, e_idx, dir):
    var walk = [[e_idx, dir, null]]
    var full_loop = false
    while true:
        var edge_idx = walk.back()[0]
        var side = walk.back()[1]
        var this_face_edges = ply_mesh.get_face_edges_starting_at(edge_idx, side)
        if this_face_edges.size() != 4:
            break
        walk.back()[2] = this_face_edges[1]
        var next_edge = this_face_edges[2]
        if next_edge == e_idx:
            full_loop = true
            break
        var next = [next_edge, Side.invert(ply_mesh.edge_side(next_edge, ply_mesh.edge_face(edge_idx, side))), null]
        walk.push_back(next)
    return [walk, full_loop]

static func edge_cut(ply_mesh, e_idx):
    print("cutting edge loop from edge: ", e_idx)
    ply_mesh.begin_edit()
    var walk_left_result = _edge_cut_walk(ply_mesh, e_idx, Side.LEFT)
    var walk_right = _edge_cut_walk(ply_mesh, e_idx, Side.RIGHT)[0]
    var walk_left = walk_left_result[0]
    var full_loop = walk_left_result[1]

    var subdivides = []
    if walk_left.size() > 0:
        for w in walk_left:
            var result = Subdivide.edge(ply_mesh, w[0], true)
            subdivides.push_back([w[0], result[0], result[1]])

        for idx in range(walk_left.size()-1):
            _apply_cut(ply_mesh, idx, idx+1, walk_left, subdivides)

    if not full_loop:
        print("going right")
        if walk_right.size() > 0:
            if subdivides.size() > 0:
                subdivides = [subdivides[0]]
                for w in walk_right.slice(1, walk_right.size()-1):
                    var result = Subdivide.edge(ply_mesh, w[0], true)
                    subdivides.push_back([w[0], result[0], result[1]])
                    pass
                pass
            else:
                for w in walk_right:
                    var result = Subdivide.edge(ply_mesh, w[0], true)
                    subdivides.push_back([w[0], result[0], result[1]])
                    pass

            for idx in range(walk_right.size()-1):
                _apply_cut(ply_mesh, idx, idx+1, walk_right, subdivides)
    else:
        # do last face cut
        _apply_cut(ply_mesh, walk_left.size()-1, 0, walk_left, subdivides)
    ply_mesh.commit_edit()