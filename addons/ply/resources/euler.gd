const Side = preload("res://addons/ply/utils/direction.gd")

# Split-Edge-Make-Vert
# > x-----------x
# < x-----x-----x
static func semv(m, e):
    var o = m.edge_origin(e)
    var d = m.edge_destination(e)
    var mp = (o+d)/2
    var le = m.get_face_edges_starting_at(e, Side.LEFT).back()

    var ne = m.edge_count()
    m.expand_edges(1)
    var nv = m.vertex_count()
    m.expand_vertexes(1)

    m.set_vertex_all(nv, mp, e)

    m.set_vertex_edge(m.edge_destination_idx(e), ne)
    m.set_edge_face_left(ne, m.edge_face_left(e))
    m.set_edge_face_right(ne, m.edge_face_right(e))
    m.set_edge_origin_idx(ne, nv)
    m.set_edge_destination_idx(ne, m.edge_destination_idx(e))
    m.set_edge_left_cw(ne, e)
    m.set_edge_right_cw(ne, m.edge_right_cw(e))
    m.set_edge_destination_idx(e, nv)
    m.set_edge_right_cw(e, ne)

    # todo: fix vertex->edge
    if le != null:
        match m.edge_side(le, m.edge_face_left(e)):
            Side.LEFT:
                m.set_edge_left_cw(le, ne)
            Side.RIGHT:
                m.set_edge_right_cw(le, ne)
    
    return [nv, ne]

# Join-Edge-Kill-Vert
# > x-----x-----x
# < x-----------x
static func jekv(m, e1, e2):
    pass

# Split-Face-Make-Edge
# >
# x ------------- x
# |               |
# x v1            x v2
# |               |
# x ------------- x
# <
# x ------------- x
# |               |
# x ------------- x
# |               |
# x ------------- x
static func sfme(m, f, v1, v2):
    var nf = m.face_count()
    m.expand_faces(1)
    var ne = m.edge_count()
    m.expand_edges(1)

    var fes = m.get_face_edges(f)

    var v1e = []
    var v2e = []
    for fe in fes:
        if m.edge_origin_idx(fe) == v1 || m.edge_destination_idx(fe) == v1:
            v1e.push_back(fe)
        if m.edge_origin_idx(fe) == v2 || m.edge_destination_idx(fe) == v2:
            v2e.push_back(fe)

    # fix ordering
    var fe1 = m.get_face_edges_starting_at(v1e[0], m.edge_side(v1e[0], f))
    if fe1[1] != v1e[1]:
        var tmp = v1e[0]
        v1e[0] = v1e[1]
        v1e[1] = tmp
    var fe2 = m.get_face_edges_starting_at(v2e[0], m.edge_side(v2e[0], f))
    if fe2[1] != v2e[1]:
        var tmp = v2e[0]
        v2e[0] = v2e[1]
        v2e[1] = tmp

    m.set_edge_origin_idx(ne, v1)
    m.set_edge_destination_idx(ne, v2)
    m.set_edge_face_left(ne, f)
    m.set_edge_face_right(ne, nf)
    m.set_edge_left_cw(ne, v1e[1])
    m.set_edge_right_cw(ne, v2e[1])

    m.set_edge_cw(v1e[0], m.edge_side(v1e[0], f), ne)
    m.set_edge_cw(v2e[0], m.edge_side(v2e[0], f), ne)

    m.set_face_edge(nf, ne)
    m.set_face_surface(nf, m.face_surface(f))
    m.set_face_edge(f, ne)

    var u = v2e[1]
    var iters = 0
    while true:
        if iters > 100:
            assert(false, "exhausted iters")
        var s = m.edge_side(u, f)
        m.set_edge_face(u, s, nf)
        if u == v1e[0]:
            break
        u = m.edge_cw(u, s)
        iters += 1
    return [ne, nf]

# Join-Face-Kill-Edge
# >
# x ------------- x
# |               |
# x ------------- x
# |               |
# x ------------- x
# <
# x ------------- x
# |               |
# x v1            x v2
# |               |
# x ------------- x
static func jfke(m, f1, f2):
    pass