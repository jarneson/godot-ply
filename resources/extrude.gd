const Side = preload("../utils/direction.gd")

static func face(ply_mesh, face_idx, distance=1):
    ply_mesh.begin_edit()
    # this is face normal extrusion, better default might be per vertex normal
    var extrude_direction = distance*ply_mesh.face_normal(face_idx)
    var existing_edges = ply_mesh.get_face_edges(face_idx)

    var vertex_start = ply_mesh.vertex_count()
    var face_start = ply_mesh.face_count()
    var edge_start = ply_mesh.edge_count()

    # expand arrays
    # adding k new vertices
    ply_mesh.expand_vertexes(existing_edges.size())
    ply_mesh.expand_faces(existing_edges.size())
    ply_mesh.expand_edges(existing_edges.size()*2)

    ply_mesh.face_edges[face_idx] = edge_start+existing_edges.size()

    for ee_idx in range(existing_edges.size()):
        var e_idx = existing_edges[ee_idx]
        var curr = ee_idx
        var next = ee_idx+1
        if next == existing_edges.size():
            next = 0
        var prev = ee_idx-1
        if prev == -1:
            prev = existing_edges.size()-1
        var direction = ply_mesh.edge_side(e_idx, face_idx)

        var x_face_idx = face_start+curr
        var x_edge_idx = edge_start+curr
        var new_edge_idx = edge_start+existing_edges.size()+curr

        var existing_point_idx = -1
        match direction:
            Side.LEFT:
                existing_point_idx = ply_mesh.edge_destination_idx(e_idx)    
                ply_mesh.set_edge_face_left(e_idx, x_face_idx)
                ply_mesh.set_edge_left_cw(  e_idx, edge_start+next)
            Side.RIGHT:
                existing_point_idx = ply_mesh.edge_origin_idx(e_idx)    
                ply_mesh.set_edge_face_right(e_idx, x_face_idx)
                ply_mesh.set_edge_right_cw(  e_idx, edge_start+next)

        # create new vtx
        ply_mesh.vertexes[vertex_start+curr] = ply_mesh.vertexes[existing_point_idx]+extrude_direction
        ply_mesh.vertex_edges[vertex_start+curr] = x_edge_idx

        ply_mesh.face_edges[x_face_idx] = x_edge_idx
        # extruded edge
        ply_mesh.set_edge_origin(     x_edge_idx, vertex_start+curr)
        ply_mesh.set_edge_destination(x_edge_idx, existing_point_idx)
        ply_mesh.set_edge_face_right( x_edge_idx, x_face_idx)
        ply_mesh.set_edge_right_cw(   x_edge_idx, e_idx)
        ply_mesh.set_edge_face_left(  x_edge_idx, face_start+prev)
        ply_mesh.set_edge_left_cw(    x_edge_idx, edge_start+existing_edges.size()+prev)

        # new edge
        ply_mesh.set_edge_origin(     new_edge_idx, vertex_start+next)
        ply_mesh.set_edge_destination(new_edge_idx, vertex_start+curr)
        ply_mesh.set_edge_face_right( new_edge_idx, x_face_idx)
        ply_mesh.set_edge_right_cw(   new_edge_idx, x_edge_idx)
        ply_mesh.set_edge_face_left(  new_edge_idx, face_idx)
        ply_mesh.set_edge_left_cw(    new_edge_idx, edge_start+existing_edges.size()+next)
    ply_mesh.commit_edit()