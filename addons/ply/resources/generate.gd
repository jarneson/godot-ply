static func nGon(ply_mesh, vertices, undo_redo=null, action_name="Generate N-Gon"):
    var vertex_edges = []
    var edge_vertexes = []
    var face_edges = [0,0]
    var face_surfaces = [0,0]
    var edge_faces = []
    var edge_edges = []

    for v_idx in range(vertices.size()):
        var curr = v_idx
        var prev = v_idx-1
        if prev < 0:
            prev = vertices.size()-1
        var next = v_idx+1
        if next >= vertices.size():
            next = 0
        vertex_edges.push_back(curr)
        edge_vertexes.push_back(curr)
        edge_vertexes.push_back(next)
        edge_faces.push_back(1)
        edge_faces.push_back(0)
        edge_edges.push_back(prev)
        edge_edges.push_back(next)

    var pre_edit = ply_mesh.begin_edit()
    ply_mesh.set_mesh(vertices, vertex_edges, face_edges, face_surfaces, edge_vertexes, edge_faces, edge_edges)
    if undo_redo:
        ply_mesh.commit_edit(action_name, undo_redo, pre_edit)
