static func export_to_obj(ply_mesh, file):
    file.store_line("# Exported from godot-ply")
    file.store_line("o PlyMesh")
    for vtx in ply_mesh.vertexes:
        file.store_line("v %s %s %s" % [vtx.x, vtx.y, vtx.z])
    file.store_line("s off")
    for f in range(ply_mesh.face_edges.size()):
        var vtxs = ply_mesh.face_vertex_indexes(f)
        var s = "f"
        for vtx in vtxs:
            s = s +  " " + str(vtx+1)
        file.store_line(s)