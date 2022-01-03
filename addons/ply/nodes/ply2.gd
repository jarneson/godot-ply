tool
extends Node

signal selection_changed
signal selection_mutated

const SelectionMode = preload("../utils/selection_mode.gd")
const GizmoMode = preload("../utils/gizmo_mode.gd")

const PlyMesh = preload("../resources/ply_mesh.gd")
const Wireframe = preload("./ply_wireframe.gd")
const Vertices = preload("./ply_vertices.gd")
const Faces = preload("./ply_faces.gd")

export(String) var parent_property = "mesh"
export(Resource) var ply_mesh setget set_ply_mesh,get_ply_mesh

var _ply_mesh: PlyMesh
func get_ply_mesh() -> Resource:
    return _ply_mesh

func set_ply_mesh(v: Resource):
    if v == null:
        if _ply_mesh && _ply_mesh.is_connected("mesh_updated", self, "_on_mesh_updated"):
            _ply_mesh.disconnect("mesh_updated", self, "_on_mesh_updated")
        _ply_mesh = v
        _clear_parent()
    if v is PlyMesh:
        if _ply_mesh && _ply_mesh.is_connected("mesh_updated", self, "_on_mesh_updated"):
            _ply_mesh.disconnect("mesh_updated", self, "_on_mesh_updated")
        _ply_mesh = v
        _ply_mesh.connect("mesh_updated", self, "_on_mesh_updated")
        _on_mesh_updated()
    else:
        print("assigned resource that is not a ply_mesh to ply editor")

onready var parent = get_parent()

func _ready():
    pass

func _enter_tree():
    if not Engine.editor_hint:
        return
    if not _ply_mesh:
        return
    if not _ply_mesh.is_connected("mesh_updated", self, "_on_mesh_updated"):
        _ply_mesh.connect("mesh_updated", self, "_on_mesh_updated")

func _exit_tree():
    if not Engine.editor_hint:
        return
    if not _ply_mesh:
        return
    if _ply_mesh.is_connected("mesh_updated", self, "_on_mesh_updated"):
        _ply_mesh.disconnect("mesh_updated", self, "_on_mesh_updated")

func _clear_parent():
    parent.set(parent_property, ArrayMesh.new())

func _on_mesh_updated():
    var remove = []
    for v in selected_vertices:
        if v >= _ply_mesh.vertex_count():
            remove.push_back(v)
    for v in remove:
        selected_vertices.erase(v)
    remove = []
    for e in selected_edges:
        if e >= _ply_mesh.edge_count():
            remove.push_back(e)
    for e in remove:
        selected_edges.erase(e)
    remove = []
    for f in selected_faces:
        if f >= _ply_mesh.face_count():
            remove.push_back(f)
    for f in remove:
        selected_faces.erase(f)
    if parent:
        parent.set(parent_property, _ply_mesh.get_mesh(parent.get(parent_property)))
    emit_signal("selection_mutated")

var selected: bool setget _set_selected,_get_selected
var _wireframe: Wireframe
var _vertices: Vertices
var _faces: Faces

func _set_selected(v: bool):
    if selected == v:
        return
    selected = v
    if not selected:
        _vertices.queue_free()
        _wireframe.queue_free()
        _faces.queue_free()
    if selected:
        _vertices = Vertices.new()
        add_child(_vertices)
        _wireframe = Wireframe.new()
        add_child(_wireframe)
        _faces = Faces.new()
        add_child(_faces)

func _get_selected() -> bool:
    return selected

class IntersectSorter:
    static func sort_ascending(a, b):
        if is_equal_approx(a[2], b[2]):
            if a[3] < b[3]:
                return true
        elif a[2] < b[2]:
            return true
        return false

func get_ray_intersection(origin: Vector3, direction: Vector3, mode: int):
    var scan_results = []
    if mode == SelectionMode.VERTEX:
        for v in range(_ply_mesh.vertex_count()):
            var pos = parent.global_transform.xform(_ply_mesh.vertexes[v])
            var dist = direction.cross(pos - origin).length()
            scan_results.push_back(["V", v, dist, (pos - origin).length()])

    if mode == SelectionMode.EDGE:
        for e in range(_ply_mesh.edge_count()):
            var e_origin = parent.global_transform.xform(_ply_mesh.edge_origin(e))
            var e_destination = parent.global_transform.xform(_ply_mesh.edge_destination(e))

            var p1 = e_origin
            var p2 = origin
            var v1 = e_destination - e_origin
            var v2 = direction * 1000
            var v21_0 = p2 -p1

            var v22 = v2.dot(v2)
            var v11 = v1.dot(v1)
            var v21 = v2.dot(v1)
            var v21_1 = v21_0.dot(v1)
            var v21_2 = v21_0.dot(v2)
            var denom = v21 * v21 - v22 * v11

            var s = 0.0
            var t = (v11 * s - v21_1) / v21
            if !is_equal_approx(denom, 0):
                s = (v21_2*v21 - v22*v21_1) / denom
                t = (-v21_1*v21 + v11*v21_2) / denom

            s = max(min(s, 1.0), 0.0)
            t = max(min(t, 1.0), 0.0)

            var p_a = p1 + s * v1
            var p_b = p2 + t * v2

            var dist = (p_b - p_a).length()
            scan_results.push_back(["E", e, dist, (p1 - origin).length()])

    if mode == SelectionMode.FACE:
        var ai = parent.global_transform.affine_inverse()
        var ai_origin = ai.xform(origin)
        var ai_direction = ai.basis.xform(direction).normalized()
        for f in range(_ply_mesh.face_count()):
            var dist = _ply_mesh.face_intersect_ray_distance(f, ai_origin, ai_direction)
            if dist != null:
                scan_results.push_back(["F", f, 0, dist])

    scan_results.sort_custom(IntersectSorter, "sort_ascending")
    return scan_results

var selected_vertices: Array = []
var selected_edges: Array = []
var selected_faces: Array = []

func select_geometry(hits: Array, toggle: bool):
    if not toggle:
        selected_vertices = []
        selected_edges = []
        selected_faces = []
    for h in hits:
        match h[0]:
            "V":
                if toggle:
                    if selected_vertices.has(h[1]):
                        selected_vertices.erase(h[1])
                    else:
                        selected_vertices.push_back(h[1])
                else:
                    selected_vertices.push_back(h[1])
            "E":
                if toggle:
                    if selected_edges.has(h[1]):
                        selected_edges.erase(h[1])
                    else:
                        selected_edges.push_back(h[1])
                else:
                    selected_edges.push_back(h[1])
            "F":
                if toggle:
                    if selected_faces.has(h[1]):
                        selected_faces.erase(h[1])
                    else:
                        selected_faces.push_back(h[1])
                else:
                    selected_faces.push_back(h[1])
    emit_signal("selection_changed")

var _current_edit
func begin_edit():
    _current_edit = _ply_mesh.begin_edit()

func commit_edit(name: String, undo_redo: UndoRedo):
    _ply_mesh.commit_edit(name, undo_redo, _current_edit)
    _current_edit = null

func abort_edit():
    _ply_mesh.reject_edit(_current_edit)
    _current_edit = null

func get_selection_transform(gizmo_mode: int = GizmoMode.LOCAL, basis_override = null):
    if selected_vertices.size() == 0 and selected_edges.size() == 0 and selected_faces.size() == 0:
        return null

    var verts = {}
    var normals = []
    if gizmo_mode != GizmoMode.NORMAL:
        normals = null
    for v in selected_vertices:
        verts[_ply_mesh.vertexes[v]] = true
        if normals != null:
            normals.push_back(_ply_mesh.vertex_normal(v))
    for e in selected_edges:
        verts[_ply_mesh.edge_origin(e)] = true
        verts[_ply_mesh.edge_destination(e)] = true
        if normals != null:
            normals.push_back(_ply_mesh.edge_normal(e))
    for f in selected_faces:
        for v in _ply_mesh.face_vertices(f):
            verts[v] = true
        if normals != null:
            normals.push_back(_ply_mesh.face_normal(f))

    var pos = _ply_mesh.geometric_median(verts.keys())

    var basis = parent.global_transform.basis
    if normals != null:
        var normal = Vector3.ZERO
        for n in normals:
            normal += n
        normal /= normals.size()
        normal = basis.xform(normal)
        var v_y = normal
        var v_x = basis.x
        var v_z = basis.z
        if v_y == v_x || v_y == -v_x:
            v_x = v_y.cross(v_z)
            v_z = v_y.cross(v_x)
        else:
            v_z = v_y.cross(v_x)
            v_x = v_y.cross(v_z)
        basis = Basis(v_x, v_y, v_z)
    if basis_override:
        basis = basis_override
    return Transform(basis.orthonormalized(), parent.global_transform.xform(pos))

func translate_selection(global_dir: Vector3):
    if not _current_edit:
        return
    var dir = parent.global_transform.basis.inverse().xform(global_dir)
    _ply_mesh.reject_edit(_current_edit, false)
    _ply_mesh.transform_faces(selected_faces, Transform(Basis.IDENTITY, dir))
    _ply_mesh.transform_edges(selected_edges, Transform(Basis.IDENTITY, dir))
    _ply_mesh.transform_vertexes(selected_vertices, Transform(Basis.IDENTITY, dir))
    emit_signal("selection_mutated")

func rotate_selection(axis: Vector3, rad: float):
    if not _current_edit:
        return
    axis = parent.global_transform.basis.inverse().xform(axis)
    var new_basis = Basis(axis, rad)
    _ply_mesh.reject_edit(_current_edit, false)
    _ply_mesh.transform_faces(selected_faces, Transform(new_basis, Vector3.ZERO))
    _ply_mesh.transform_edges(selected_edges, Transform(new_basis, Vector3.ZERO))
    _ply_mesh.transform_vertexes(selected_vertices, Transform(new_basis, Vector3.ZERO))
    emit_signal("selection_mutated")

func scale_selection(scale: Vector3):
    if not _current_edit:
        return
    if scale.x == 0:
        scale.x = 0.001
    if scale.y == 0:
        scale.y = 0.001
    if scale.z == 0:
        scale.z = 0.001
    var new_basis = Basis.IDENTITY.scaled(scale)
    _ply_mesh.reject_edit(_current_edit, false)
    _ply_mesh.transform_faces(selected_faces, Transform(new_basis, Vector3.ZERO))
    _ply_mesh.transform_edges(selected_edges, Transform(new_basis, Vector3.ZERO))
    _ply_mesh.transform_vertexes(selected_vertices, Transform(new_basis, Vector3.ZERO))
    emit_signal("selection_mutated")