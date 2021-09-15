tool
extends Spatial

export(int) var vertex_idx = -1
export(Resource) var ply_mesh

var plugin = null
var material = preload("./vertex_material.tres")
var selected_material = preload("./vertex_selected_material.tres")

onready var mesh_instance = $MeshInstance

func _ready():
	set_meta("_edit_lock_", true)
	mesh_instance.set_meta("_edit_lock", true)
	_on_mesh_updated()

func _enter_tree():
	if vertex_idx < 0 or not ply_mesh:
		return

	if plugin:
		plugin.selector.connect("selection_changed", self, "_on_selection_changed")
	if ply_mesh:
		ply_mesh.connect("mesh_updated", self, "_on_mesh_updated")

func _exit_tree():
	if plugin:
		plugin.selector.disconnect("selection_changed", self, "_on_selection_changed")
	if ply_mesh:
		ply_mesh.disconnect("mesh_updated", self, "_on_mesh_updated")

func _on_mesh_updated():
	transform.origin = ply_mesh.vertexes[vertex_idx]

func _on_selection_changed(_mode, _ply_instance, selection):
	if selection.has(vertex_idx):
		mesh_instance.set("material/0", selected_material)
	else:
		mesh_instance.set("material/0", material)

func get_idx():
	return vertex_idx

func intersect_ray_distance(ray_start, ray_dir):
	return (ray_start - global_transform.origin).length()