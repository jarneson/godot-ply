tool
extends Spatial

export(int) var vertex_idx = -1
export(Resource) var ply_mesh

var plugin = null
var material = preload("./vertex_material.tres")
var selected_material = preload("./vertex_selected_material.tres")

onready var mesh_instance = $MeshInstance

func _process(_delta):
	if not plugin:
		return
	if vertex_idx < 0 or not ply_mesh:
		return
	# todo: move this out of process to improve performance
	transform.origin = ply_mesh.vertexes[vertex_idx]

	if plugin.selector.selection.has(self):
		mesh_instance.set("material/0", selected_material)
	else:
		mesh_instance.set("material/0", material)