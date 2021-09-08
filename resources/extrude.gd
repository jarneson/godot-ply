const Side = preload("../utils/direction.gd")

static func faces(ply_mesh, faces, distance=1):
    # walk the outside of the faces:
    # get face edges
    var face_edges = []
    var internal_edges = []
    var external_edges = []
    for f_idx in faces:
        var edges = ply_mesh.get_face_edges(f_idx)
        face_edges.push_back(edges)
        for e_idx in edges:
            if internal_edges.has(e_idx):
                continue
            if external_edges.has(e_idx):
                external_edges.erase(e_idx)
                internal_edges.push_back(e_idx)
            else:
                external_edges.push_back(e_idx)

    # find loops
    var loops = []
    var search = external_edges.duplicate()
    while search.size() > 0:
        var ordered_edges = []
        var ordered_edge_sides = []
        var curr_edge = search[0]
        while true: 
            var side = Side.LEFT
            if faces.has(ply_mesh.edge_face_right(curr_edge)):
                side = Side.RIGHT
            ordered_edges.push_back([curr_edge, side])
            search.erase(curr_edge)
            var face = ply_mesh.edge_face(curr_edge, side)
            curr_edge = ply_mesh.edge_cw(curr_edge, side)
            while internal_edges.has(curr_edge):
                side = Side.invert(ply_mesh.edge_side(curr_edge, face))
                face = ply_mesh.edge_face(curr_edge, side)
                curr_edge = ply_mesh.edge_cw(curr_edge, side)
            if not search.has(curr_edge):
                break
        loops.push_back(ordered_edges)
    # order external_edges

    # calculate average face normal
    var sum = Vector3.ZERO
    for f_idx in faces:
        sum = sum + ply_mesh.face_normal(f_idx)
    var extrude_direction = distance*sum/faces.size()

    ply_mesh.begin_edit()
    var old_to_new_edge = {}
    var old_to_new_vertex = {}
    # resize arrays
    for ordered_edges in loops:
        var vertex_start = ply_mesh.vertex_count()
        var face_start = ply_mesh.face_count()
        var edge_start = ply_mesh.edge_count()

        ply_mesh.expand_vertexes(ordered_edges.size())
        ply_mesh.expand_faces(ordered_edges.size())
        ply_mesh.expand_edges(ordered_edges.size()*2)

        # extrude border edges along distance*normal
        for oe_idx in range(ordered_edges.size()):
            var e_idx = ordered_edges[oe_idx][0]
            var direction = ordered_edges[oe_idx][1]
            var curr = oe_idx
            var next = oe_idx+1
            if next == ordered_edges.size():
                next = 0
            var prev = oe_idx-1
            if prev == -1:
                prev = ordered_edges.size()-1

            var x_face_idx = face_start+curr
            var x_edge_idx = edge_start+curr
            var new_edge_idx = edge_start+ordered_edges.size()+curr

            var existing_point_idx = -1
            var before_edit_cw_edge = null
            var face_idx = null
            match direction:
                Side.LEFT:
                    existing_point_idx = ply_mesh.edge_destination_idx(e_idx)    
                    before_edit_cw_edge = ply_mesh.edge_left_cw(e_idx)
                    face_idx = ply_mesh.edge_face_left(e_idx)
                    ply_mesh.set_edge_face_left(e_idx, x_face_idx)
                    ply_mesh.set_edge_left_cw(  e_idx, edge_start+next)
                Side.RIGHT:
                    existing_point_idx = ply_mesh.edge_origin_idx(e_idx)    
                    before_edit_cw_edge = ply_mesh.edge_right_cw(e_idx)
                    face_idx = ply_mesh.edge_face_right(e_idx)
                    ply_mesh.set_edge_face_right(e_idx, x_face_idx)
                    ply_mesh.set_edge_right_cw(  e_idx, edge_start+next)
            
            # maintain mapping
            old_to_new_edge[e_idx] = new_edge_idx
            old_to_new_vertex[existing_point_idx] = vertex_start+curr

            # create new vtx
            ply_mesh.vertexes[vertex_start+curr] = ply_mesh.vertexes[existing_point_idx]+extrude_direction
            ply_mesh.vertex_edges[vertex_start+curr] = x_edge_idx

            # face edge
            ply_mesh.face_edges[x_face_idx] = x_edge_idx
            ply_mesh.face_edges[face_idx] = new_edge_idx

            # extruded edge
            ply_mesh.set_edge_origin(     x_edge_idx, vertex_start+curr)
            ply_mesh.set_edge_destination(x_edge_idx, existing_point_idx)
            ply_mesh.set_edge_face_right( x_edge_idx, x_face_idx)
            ply_mesh.set_edge_right_cw(   x_edge_idx, e_idx)
            ply_mesh.set_edge_face_left(  x_edge_idx, face_start+prev)
            ply_mesh.set_edge_left_cw(    x_edge_idx, edge_start+ordered_edges.size()+prev)

            # new edge
            ply_mesh.set_edge_origin(     new_edge_idx, vertex_start+next)
            ply_mesh.set_edge_destination(new_edge_idx, vertex_start+curr)
            ply_mesh.set_edge_face_right( new_edge_idx, x_face_idx)
            ply_mesh.set_edge_right_cw(   new_edge_idx, x_edge_idx)
            ply_mesh.set_edge_face_left(  new_edge_idx, face_idx)
            if internal_edges.has(before_edit_cw_edge):
                ply_mesh.set_edge_left_cw(new_edge_idx, before_edit_cw_edge)
            else:
                ply_mesh.set_edge_left_cw(new_edge_idx, edge_start+ordered_edges.size()+next)

    # fix winding of internal edges (eg map winding from old edge to new)
    for e in internal_edges:
        ply_mesh.face_edges[ply_mesh.edge_face_left(e)] = e
        ply_mesh.face_edges[ply_mesh.edge_face_right(e)] = e
        ply_mesh.set_edge_origin_idx(e, old_to_new_vertex[ply_mesh.edge_origin_idx(e)])
        ply_mesh.set_edge_destination_idx(e, old_to_new_vertex[ply_mesh.edge_destination_idx(e)])
        for side in [Side.LEFT, Side.RIGHT]:
            var ee = ply_mesh.edge_cw(e, side)
            var e_idx = external_edges.find(ee)
            if e_idx >= 0:
                ply_mesh.set_edge_cw(e, side, old_to_new_edge[ee])
    ply_mesh.commit_edit()

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