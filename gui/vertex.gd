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

func get_idx():
	return vertex_idx

func _process(_delta):
	if not plugin:
		return
	if vertex_idx < 0 or not ply_mesh:
		return
	# todo: move this out of process to improve performance
	transform.origin = ply_mesh.vertexes[vertex_idx]

	if plugin.selector.selection.has(vertex_idx):
		mesh_instance.set("material/0", selected_material)
	else:
		mesh_instance.set("material/0", material)

func intersect_ray_distance(ray_start, ray_dir):
	return (ray_start - global_transform.origin).length()