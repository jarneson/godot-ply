tool
extends Resource
class_name PlyMesh

"""
███████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗     ███████╗
██╔════╝██║██╔════╝ ████╗  ██║██╔══██╗██║     ██╔════╝
███████╗██║██║  ███╗██╔██╗ ██║███████║██║     ███████╗
╚════██║██║██║   ██║██║╚██╗██║██╔══██║██║     ╚════██║
███████║██║╚██████╔╝██║ ╚████║██║  ██║███████╗███████║
╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝
"""
signal mesh_updated

"""
███████╗███╗   ██╗██╗   ██╗███╗   ███╗███████╗
██╔════╝████╗  ██║██║   ██║████╗ ████║██╔════╝
█████╗  ██╔██╗ ██║██║   ██║██╔████╔██║███████╗
██╔══╝  ██║╚██╗██║██║   ██║██║╚██╔╝██║╚════██║
███████╗██║ ╚████║╚██████╔╝██║ ╚═╝ ██║███████║
╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝
"""
const Side = preload("../utils/direction.gd")

"""
██╗   ██╗███████╗██████╗ ████████╗██╗ ██████╗███████╗███████╗
██║   ██║██╔════╝██╔══██╗╚══██╔══╝██║██╔════╝██╔════╝██╔════╝
██║   ██║█████╗  ██████╔╝   ██║   ██║██║     █████╗  ███████╗
╚██╗ ██╔╝██╔══╝  ██╔══██╗   ██║   ██║██║     ██╔══╝  ╚════██║
 ╚████╔╝ ███████╗██║  ██║   ██║   ██║╚██████╗███████╗███████║
  ╚═══╝  ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝╚══════╝╚══════╝
"""
export var vertexes = PoolVector3Array()
export var vertex_edges = PoolIntArray()

func evict_vertices(idxs, ignore_edges=[]):
    print("evict vertices %s not %s" % [idxs, ignore_edges])
    idxs.sort()
    idxs.invert()
    for idx in idxs:
        vertexes.remove(idx)
        vertex_edges.remove(idx)
        for e_idx in range(edge_vertexes.size()):
            if ignore_edges.has(e_idx/2):
                continue
            assert(edge_vertexes[e_idx] != idx, "trying to evict vertex %s in use by edge %s" % [idx, e_idx/2])
            if edge_vertexes[e_idx] > idx:
                edge_vertexes[e_idx] -= 1

func vertex_count():
    return vertexes.size()

func set_vertex(idx, pos):
    if vertexes[idx] == pos:
        return
    vertexes[idx] = pos
    emit_signal("mesh_updated")

func set_vertex_edge(idx, e_idx):
	vertex_edges[idx] = e_idx

func set_vertex_all(idx, pos, edge):
    vertexes[idx] = pos
    vertex_edges[idx] = edge

func expand_vertexes(more):
    vertexes.resize(vertexes.size()+more)
    vertex_edges.resize(vertex_edges.size()+more)

func geometric_median(verts, iters=5):
    var start = Vector3.ZERO
    if verts.size() == 0:
        return start
    for v in verts:
        start = start + v
    start = start / verts.size()

    for i in range(iters):
        pass # TODO: weiszfeld's
    
    return start

func average_vertex_normal(verts):
    var normal_sum = Vector3.ZERO
    for i in range(verts.size()):
        var left_idx = i-1 
        var right_idx = i+1
        if left_idx == -1:
            left_idx = verts.size()-1
        if right_idx == verts.size():
            right_idx = 0
        normal_sum = normal_sum + (verts[left_idx]-verts[i]).cross(verts[right_idx]-verts[i])
    return (normal_sum / verts.size()).normalized()

func get_vertex_edges(v_idx, start=null):
    if not start:
        start = vertex_edges[v_idx]
    var out = []

    var e = start
    var first = true
    while first or e != start:
        first = false
        out.push_back(e)
        if edge_origin_idx(e) == v_idx:
            e = edge_left_cw(e)
        elif edge_destination_idx(e) == v_idx:
            e = edge_right_cw(e)
        else:
            assert(false, "edge %s does not include vertex %s" % [start, v_idx])

    return out

"""
███████╗██████╗  ██████╗ ███████╗███████╗
██╔════╝██╔══██╗██╔════╝ ██╔════╝██╔════╝
█████╗  ██║  ██║██║  ███╗█████╗  ███████╗
██╔══╝  ██║  ██║██║   ██║██╔══╝  ╚════██║
███████╗██████╔╝╚██████╔╝███████╗███████║
╚══════╝╚═════╝  ╚═════╝ ╚══════╝╚══════╝
"""
# 2 vertices and faces per edge
# 2 connecting edges per edge, one way traversal
# 2*idx for left, 2*idx+1 for right
#         origin,       destination
export var edge_vertexes = PoolIntArray()
export var edge_faces = PoolIntArray()
export var edge_edges = PoolIntArray()

func evict_edges(idxs):
    print("evict edges %s" % [idxs])
    idxs.sort()
    idxs.invert()
    for idx in idxs:
        var l = 2*idx
        var r = 2*idx+1
        edge_vertexes.remove(r)
        edge_vertexes.remove(l)
        edge_faces.remove(r)
        edge_faces.remove(l)
        edge_edges.remove(r)
        edge_edges.remove(l)

        for i in range(edge_vertexes.size()):
            if idxs.has(i/2):
                continue
            assert(edge_edges[i] != idx, "attempting to evict edge %s in use by edge %s" % [idx, i/2])
            if edge_edges[i] > idx:
                print("decrement edge %s" % [i/2])
                edge_edges[i] -= 1
        
        for i in range(vertex_edges.size()):
            assert(vertex_edges[i] != idx, "attempting to evict edge %s in use by vertex %s" % [idx, i])
            if vertex_edges[i] > idx:
                print("decrement vertex %s" % [i])
                vertex_edges[i] -= 1
        
        for i in range(face_edges.size()):
            assert(face_edges[i] != idx, "attempting to evict edge %s in use by face %s" % [idx, i])
            if face_edges[i] > idx:
                print("decrement face %s" % [i])
                face_edges[i] -= 1

func edge_count():
    return edge_vertexes.size() / 2

func expand_edges(more):
    edge_vertexes.resize(edge_vertexes.size()+more*2)
    edge_faces.resize(edge_faces.size()+more*2)
    edge_edges.resize(edge_edges.size()+more*2)

func edge_side(e_idx, f_idx):
    if edge_face_left(e_idx) == f_idx:
        return Side.LEFT
    if edge_face_right(e_idx) == f_idx:
        return Side.RIGHT
    assert(false, "edge %s does not touch face %s" % [e_idx, f_idx])

func edge_face(e_idx, side):
    match side:
        Side.LEFT:
            return edge_face_left(e_idx)
        Side.RIGHT:
            return edge_face_right(e_idx)

func set_edge_face(e_idx, side, f_idx):
    match side:
        Side.LEFT:
            set_edge_face_left(e_idx, f_idx)
        Side.RIGHT:
            set_edge_face_right(e_idx, f_idx)

func get_face_edges_starting_at(start, side):
    var f_idx = edge_face(start, side)
    if f_idx < 0:
        return []
    var out = []
    out.push_back(start)
    var e = edge_next_cw(start, f_idx)
    while e != start:
        out.push_back(e)
        e = edge_next_cw(e, f_idx)
    return out

func edge_cw(idx, side):
    match side:
        Side.LEFT:
            return edge_left_cw(idx)
        Side.RIGHT:
            return edge_right_cw(idx)

func set_edge_cw(idx, side, e):
    match side:
        Side.LEFT:
            set_edge_left_cw(idx, e)
        Side.RIGHT:
            set_edge_right_cw(idx, e)

func edge_next_cw(edge, face):
    return edge_cw(edge, edge_side(edge, face))

func edge_left_cw(idx):
    return edge_edges[2*idx]

func set_edge_left_cw(idx, cw):
    edge_edges[2*idx] = cw

func edge_right_cw(idx):
    return edge_edges[2*idx+1]

func set_edge_right_cw(idx, cw):
    edge_edges[2*idx+1] = cw

func edge_face_left(idx):
    return edge_faces[2*idx]

func set_edge_face_left(idx, f):
    edge_faces[2*idx] = f

func edge_face_right(idx):
    return edge_faces[2*idx+1]

func set_edge_face_right(idx, f):
    edge_faces[2*idx+1] = f

func edge_origin_idx(idx):
    return edge_vertexes[2*idx]

func set_edge_origin_idx(e, v):
    edge_vertexes[2*e] = v

func edge_destination_idx(idx):
    return edge_vertexes[2*idx+1]

func set_edge_destination_idx(e, v):
    edge_vertexes[2*e+1] = v

func edge_origin(idx):
    return vertexes[edge_origin_idx(idx)]

func edge_destination(idx):
    return vertexes[edge_destination_idx(idx)]

func set_edge_origin(e, v):
    edge_vertexes[2*e] = v

func set_edge_destination(e, v):
    edge_vertexes[2*e+1] = v

func edge_midpoint(e):
    return (edge_origin(e) + edge_destination(e)) / 2

"""
███████╗ █████╗  ██████╗███████╗███████╗
██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝
█████╗  ███████║██║     █████╗  ███████╗
██╔══╝  ██╔══██║██║     ██╔══╝  ╚════██║
██║     ██║  ██║╚██████╗███████╗███████║
╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝╚══════╝
"""
export var face_edges = PoolIntArray()

func evict_faces(idxs, ignore_edges=[]):
    print("evict faces %s not %s" % [idxs, ignore_edges])
    idxs.sort()
    idxs.invert()
    for f_idx in idxs:
        face_edges.remove(f_idx)

        for i in range(edge_faces.size()):
            if ignore_edges.has(i/2):
                continue
            assert(edge_faces[i] != f_idx, "attempting to evict face %s in use by edge %s" % [f_idx, i/2])
            if edge_faces[i] > f_idx:
                edge_faces[i] -= 1

func face_count():
    return face_edges.size()

func expand_faces(more):
    face_edges.resize(face_edges.size()+more)

func set_face_edge(f, e):
	face_edges[f] = e

func get_face_edges(idx):
    return get_face_edges_starting_at(face_edges[idx], edge_side(face_edges[idx], idx))

func face_vertex_indexes(idx):
    var edges = get_face_edges(idx)
    assert(edges.size() > 0, "face %s has no edges" % [idx])
    var verts = PoolIntArray()
    for e in edges:
        if edge_face_left(e) == idx:
            verts.push_back(edge_origin_idx(e))
        elif edge_face_right(e) == idx:
            verts.push_back(edge_destination_idx(e))
        else:
            assert(false, "edge %s retured does not include face %s" % [e, idx])
    return verts

func face_vertices(idx):
    var vert_idxs = face_vertex_indexes(idx)
    var verts = PoolVector3Array()
    for idx in vert_idxs:
        verts.push_back(vertexes[idx])
    return verts

func face_normal(idx):
    return average_vertex_normal(face_vertices(idx))

func face_median(idx):
    return geometric_median(face_vertices(idx))

"""
██████╗ ███████╗███╗   ██╗██████╗ ███████╗██████╗ ██╗███╗   ██╗ ██████╗ 
██╔══██╗██╔════╝████╗  ██║██╔══██╗██╔════╝██╔══██╗██║████╗  ██║██╔════╝ 
██████╔╝█████╗  ██╔██╗ ██║██║  ██║█████╗  ██████╔╝██║██╔██╗ ██║██║  ███╗
██╔══██╗██╔══╝  ██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗██║██║╚██╗██║██║   ██║
██║  ██║███████╗██║ ╚████║██████╔╝███████╗██║  ██║██║██║ ╚████║╚██████╔╝
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
"""
func face_tris(f_idx):
    var verts = face_vertices(f_idx)
    if verts.size() == 0:
        return []

    var mapped_verts = []
    if true:
        var face_normal = face_normal(f_idx)
        var axis_a = (verts[verts.size()-1] - verts[0]).normalized()
        var axis_b = axis_a.cross(face_normal)
        var p_origin = verts[0]
        for vtx in verts:
            mapped_verts.push_back([vtx, Vector2((vtx-p_origin).dot(axis_a), (vtx-p_origin).dot(axis_b))])
    
    var tris = []
    var remaining = []
    remaining.resize(verts.size())
    for i in range(verts.size()):
        remaining[i] = i
    
    while remaining.size() > 3:
        var min_idx = null
        var min_dot = null
        for curr in range(remaining.size()):
            var prev = curr-1
            if prev < 0:
                prev = remaining.size()-1
            var next = curr+1
            if next >= remaining.size():
                next = 0

            var va = verts[remaining[prev]]
            var vb = verts[remaining[curr]]
            var vc = verts[remaining[next]]

            var ab = vb-va
            var bc = vc-vb

            var d = ab.dot(bc)

            if not min_dot or d < min_dot:
                min_idx = curr
                min_dot = d

        var curr = min_idx
        var prev = curr-1
        if prev < 0:
            prev = remaining.size()-1
        var next = curr+1
        if next >= remaining.size():
            next = 0
        tris.push_back([remaining[prev], remaining[curr], remaining[next]])
        remaining.remove(min_idx)

    if remaining.size() == 3:
        tris.push_back([remaining[0], remaining[1], remaining[2]])

    return [mapped_verts, tris]

func render_face(st, f_idx, offset=Vector3.ZERO, num_verts=0):
    var tri_res = face_tris(f_idx)
    var verts = tri_res[0]
    var tris = tri_res[1]

    if verts.size() == 0:
        return

    for vtx in verts:
        st.add_uv(vtx[1])
        st.add_vertex(vtx[0]+offset)

    for tri in tris:
        for val in tri:
            st.add_index(val+num_verts)

    return verts.size()

func get_mesh():
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    var num_verts = 0
    for v in range(face_edges.size()):
        num_verts += render_face(st, v, Vector3.ZERO, num_verts)
    
    st.generate_normals()
    return st.commit()

func set_mesh(vs, ves, fes, evs, efs, ees):
    vertexes = PoolVector3Array(vs)
    vertex_edges = PoolIntArray(ves)
    face_edges = PoolIntArray(fes)
    edge_vertexes = PoolIntArray(evs)
    edge_faces = PoolIntArray(efs)
    edge_edges = PoolIntArray(ees)
    emit_signal("mesh_updated")


func face_intersect_ray_distance(face_idx, ray_start, ray_dir):
    var tri_res = face_tris(face_idx)
    var vtxs = tri_res[0]
    var tris = tri_res[1]

    var min_dist = null

    for tri in tris:
        var verts = [
            vtxs[tri[0]][0],
            vtxs[tri[1]][0],
            vtxs[tri[2]][0]
        ]

        var normal = (verts[2]-verts[0]).cross(verts[1]-verts[0]).normalized()
        var denom = normal.dot(ray_dir)
        if is_equal_approx(0, denom):
            continue

        var t = -normal.dot(ray_start - verts[0])/normal.dot(ray_dir)
        var hit = ray_start + t * ray_dir

        var e0 = verts[1] - verts[0]
        var e1 = verts[2] - verts[1]
        var e2 = verts[0] - verts[2]
        var c0 = hit - verts[0]
        var c1 = hit - verts[1]
        var c2 = hit - verts[2]
        var x0 = c0.cross(e0)
        var x1 = c1.cross(e1)
        var x2 = c2.cross(e2)
        var in_tri = normal.dot(x0) >= 0 and normal.dot(x1) >= 0 and normal.dot(x2) >= 0
        if in_tri:
            if not min_dist or t < min_dist:
                min_dist = t
    return min_dist

"""
████████╗ ██████╗  ██████╗ ██╗     ███████╗
╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
   ██║   ██║   ██║██║   ██║██║     ███████╗
   ██║   ██║   ██║██║   ██║██║     ╚════██║
   ██║   ╚██████╔╝╚██████╔╝███████╗███████║
   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝
"""
func begin_edit():
    return [vertexes, vertex_edges, edge_vertexes, edge_faces, edge_edges, face_edges]

func emit_change_signal():
    emit_signal("mesh_updated")

func commit_edit(name, undo_redo, pre_edits):
    undo_redo.create_action(name)
    undo_redo.add_do_property(self, "vertexes", vertexes)
    undo_redo.add_undo_property(self, "vertexes", pre_edits[0])
    undo_redo.add_do_property(self, "vertex_edges", vertex_edges)
    undo_redo.add_undo_property(self, "vertex_edges", pre_edits[1])
    undo_redo.add_do_property(self, "edge_vertexes", edge_vertexes)
    undo_redo.add_undo_property(self, "edge_vertexes", pre_edits[2])
    undo_redo.add_do_property(self, "edge_faces", edge_faces)
    undo_redo.add_undo_property(self, "edge_faces", pre_edits[3])
    undo_redo.add_do_property(self, "edge_edges", edge_edges)
    undo_redo.add_undo_property(self, "edge_edges", pre_edits[4])
    undo_redo.add_do_property(self, "face_edges", face_edges)
    undo_redo.add_undo_property(self, "face_edges", pre_edits[5])
    undo_redo.add_do_method(self, "emit_change_signal")
    undo_redo.add_undo_method(self, "emit_change_signal")
    undo_redo.commit_action()
    emit_signal("mesh_updated")

"""
███████╗██████╗ ██╗████████╗██╗███╗   ██╗ ██████╗ 
██╔════╝██╔══██╗██║╚══██╔══╝██║████╗  ██║██╔════╝ 
█████╗  ██║  ██║██║   ██║   ██║██╔██╗ ██║██║  ███╗
██╔══╝  ██║  ██║██║   ██║   ██║██║╚██╗██║██║   ██║
███████╗██████╔╝██║   ██║   ██║██║ ╚████║╚██████╔╝
╚══════╝╚═════╝ ╚═╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
"""
func translate_face_by_median(f_idx, new_median):
    var v_idxs = face_vertex_indexes(f_idx)
    var vs = face_vertices(f_idx)
    var median = geometric_median(vs)
    var shift = new_median - median

    for idx in v_idxs:
        vertexes[idx] = vertexes[idx] + shift
    
    emit_signal("mesh_updated")

func transform_faces(faces, prev_xf, new_xf):
    var v_idxs = []
    for f in faces:
        for idx in face_vertex_indexes(f):
            if not v_idxs.has(idx):
                v_idxs.push_back(idx)
    
    transform_vertexes(v_idxs, prev_xf, new_xf)

func transform_edges(edges, prev_xf, new_xf):
    var v_idxs = []
    for e in edges:
        if not v_idxs.has(edge_origin_idx(e)):
            v_idxs.push_back(edge_origin_idx(e))
        if not v_idxs.has(edge_destination_idx(e)):
            v_idxs.push_back(edge_destination_idx(e))
    transform_vertexes(v_idxs, prev_xf, new_xf)

func transform_vertexes(vtxs, prev_xf, new_xf):
    var center = Vector3.ZERO
    for v in vtxs:
        center = center + vertexes[v]
    center = center / vtxs.size()

    var prev_rs = prev_xf.basis.inverse()
    var new_rs = new_xf.basis

    var dict = {}
    for idx in vtxs:
        vertexes[idx] = new_rs.xform(prev_rs.xform(vertexes[idx]-center))+center+new_xf.origin-prev_xf.origin

    emit_signal("mesh_updated")
