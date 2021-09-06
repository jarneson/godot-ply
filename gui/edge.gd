tool
extends Spatial

export(int) var edge_idx = -1
export(Resource) var ply_mesh

var plugin = null
var material = preload("./vertex_material.tres")
var selected_material = preload("./vertex_selected_material.tres")

onready var mesh_instance = $MeshInstance

func _process(_delta):
	if not plugin:
		return
	if edge_idx < 0 or not ply_mesh:
		return

	var origin = ply_mesh.edge_origin(edge_idx)
	var destination = ply_mesh.edge_destination(edge_idx)
	transform.origin = (origin+destination)/2
	var length = origin.distance_to(destination)

	var new_mesh = CubeMesh.new()
	new_mesh.size = Vector3(0.1, 0.1, length)
	mesh_instance.mesh = new_mesh

	var v_z = (destination - origin).normalized()
	var up = Vector3.UP
	if v_z == up or v_z == -up:
		up = Vector3.LEFT
	var v_x = up.cross(v_z).normalized()
	var v_y = v_z.cross(v_x).normalized()
	mesh_instance.transform.basis = Basis(v_x, v_y, v_z)

	if plugin.selector.selection.has(self):
		mesh_instance.set("material/0", selected_material)
	else:
		mesh_instance.set("material/0", material)