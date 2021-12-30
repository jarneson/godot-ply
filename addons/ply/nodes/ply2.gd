tool
extends Node

const PlyMesh = preload("../resources/ply_mesh.gd")
const Wireframe = preload("./ply_wireframe.gd")
const Vertices = preload("./ply_vertices.gd")

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
    print(parent.get(parent_property))

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
    if parent:
        parent.set(parent_property, _ply_mesh.get_mesh(parent.get(parent_property)))

var selected: bool setget _set_selected,_get_selected
var _wireframe: Wireframe
var _vertices: Vertices

func _set_selected(v: bool):
    if selected == v:
        return
    selected = v
    if not selected:
        _vertices.queue_free()
        _wireframe.queue_free()
    if selected:
        _vertices = Vertices.new()
        _vertices.copy_transform = parent
        _vertices.ply_mesh = _ply_mesh
        add_child(_vertices)
        _wireframe = Wireframe.new()
        _wireframe.copy_transform = parent
        _wireframe.ply_mesh = _ply_mesh
        add_child(_wireframe)

func _get_selected() -> bool:
    return selected

class IntersectSorter:
    static func sort_ascending(a, b):
        if a[2] < b[2]:
            return true
        return false

func get_ray_intersection(origin: Vector3, direction: Vector3):
    var scan_results = []
    for v in range(_ply_mesh.vertex_count()):
        var pos = _ply_mesh.vertexes[v] + parent.global_transform.origin
        var dist = direction.cross(pos - origin).length()
        scan_results.push_back(["V", v, dist])
    for e in range(_ply_mesh.edge_count()):
        var e_origin = _ply_mesh.edge_origin(e) + parent.global_transform.origin
        var e_destination = _ply_mesh.edge_destination(e) + parent.global_transform.origin

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
        scan_results.push_back(["E", e, dist])
    scan_results.sort_custom(IntersectSorter, "sort_ascending")
    return scan_results