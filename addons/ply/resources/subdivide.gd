const Euler = preload("./euler.gd")
const Side = preload("../utils/direction.gd")

static func face(ply_mesh, face_idx, undo_redo=null):
    var pre_edit = null
    if undo_redo:
        pre_edit = ply_mesh.begin_edit()

    var edges = ply_mesh.get_face_edges(face_idx)
    if edges.size() == 4:
        var v1 = Euler.semv(ply_mesh, edges[0])
        var v2 = Euler.semv(ply_mesh, edges[2])
        var res = Euler.sfme(ply_mesh, face_idx, v1[0], v2[0])
        var ne = res[0]
        var nf = res[1]

        var e1 = ply_mesh.get_face_edges_starting_at(ne, ply_mesh.edge_side(ne, face_idx))[2]
        var e2 = ply_mesh.get_face_edges_starting_at(ne, ply_mesh.edge_side(ne, nf))[2]
        var v3 = Euler.semv(ply_mesh, ne)
        var v4 = Euler.semv(ply_mesh, e1)
        var v5 = Euler.semv(ply_mesh, e2)
        Euler.sfme(ply_mesh, face_idx, v3[0], v4[0])
        Euler.sfme(ply_mesh, nf, v3[0], v5[0])
    elif edges.size() == 3:
        var v0 = Euler.semv(ply_mesh, edges[0])[0]
        var v1 = Euler.semv(ply_mesh, edges[1])[0]
        var v2 = Euler.semv(ply_mesh, edges[2])[0]
        Euler.sfme(ply_mesh, face_idx, v0, v1)
        Euler.sfme(ply_mesh, ply_mesh.face_count()-1, v1, v2)
        Euler.sfme(ply_mesh, ply_mesh.face_count()-1, v0, v2)
    else:
        return

    if undo_redo:
        ply_mesh.commit_edit("Subdivide Edge", undo_redo, pre_edit)

# returns [new_edge_idx, new_vertex_idx]
static func edge(ply_mesh, edge_idx, undo_redo=null):
    var pre_edit = null
    if undo_redo:
        pre_edit = ply_mesh.begin_edit()
    
    var res = Euler.semv(ply_mesh, edge_idx)

    if undo_redo:
        ply_mesh.commit_edit("Subdivide Edge", undo_redo, pre_edit)
    return res
