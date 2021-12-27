const Euler = preload("./euler.gd")
const Side = preload("../utils/direction.gd")

static func object(ply_mesh, undo_redo=null):
    var f = []
    for i in range(ply_mesh.face_count()):
        f.push_back(i)
    return faces(ply_mesh, f, undo_redo)

static func faces(ply_mesh, face_indices, undo_redo=null):
    var pre_edit = null
    if undo_redo:
        pre_edit = ply_mesh.begin_edit()

    var seen_edges = {}
    var face_edges = {}
    for face_idx in face_indices:
        var edges = ply_mesh.get_face_edges(face_idx)
        if edges.size() != 4 && edges.size() != 3:
            continue

        face_edges[face_idx] = edges
        for e in edges:
            seen_edges[e] = []
        
    for edge in seen_edges:
        seen_edges[edge] = Euler.semv(ply_mesh, edge)

    for face_idx in face_indices:
        var edges = face_edges[face_idx]
        if edges.size() == 4:
            var v1 = seen_edges[edges[0]][0]
            var v2 = seen_edges[edges[2]][0]
            var res = Euler.sfme(ply_mesh, face_idx, v1, v2)
            var ne = res[0]
            var nf = res[1]

            var v3 = Euler.semv(ply_mesh, ne)[0]
            var v4 = seen_edges[edges[1]][0]
            var v5 = seen_edges[edges[3]][0]
            Euler.sfme(ply_mesh, face_idx, v3, v4)
            Euler.sfme(ply_mesh, nf, v3, v5)
        if edges.size() == 3:
            var v0 = seen_edges[edges[0]][0]
            var v1 = seen_edges[edges[1]][0]
            var v2 = seen_edges[edges[2]][0]
            Euler.sfme(ply_mesh, face_idx, v0, v1)
            Euler.sfme(ply_mesh, ply_mesh.face_count()-1, v1, v2)
            Euler.sfme(ply_mesh, ply_mesh.face_count()-1, v0, v2)

    if undo_redo:
        ply_mesh.commit_edit("Subdivide Faces", undo_redo, pre_edit)

    var result = []
    for e in seen_edges:
        result.push_back(seen_edges[e][0])
    return result

# returns [new_edge_idx, new_vertex_idx]
static func edge(ply_mesh, edge_idx, undo_redo=null):
    var pre_edit = null
    if undo_redo:
        pre_edit = ply_mesh.begin_edit()
    
    var res = Euler.semv(ply_mesh, edge_idx)

    if undo_redo:
        ply_mesh.commit_edit("Subdivide Edge", undo_redo, pre_edit)
    return res
