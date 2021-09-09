tool
extends Spatial

export(int) var edge_idx = -1
export(Resource) var ply_mesh

var plugin = null
var material = preload("./vertex_material.tres")
var selected_material = preload("./vertex_selected_material.tres")

onready var mesh_instance = $MeshInstance
var is_selected = false

func _enter_tree():
	if plugin:
		plugin.selector.connect("selection_changed", self, "_on_selection_changed")
	if ply_mesh:
		ply_mesh.connect("mesh_updated", self, "_on_mesh_updated")

func _exit_tree():
	if plugin:
		plugin.selector.disconnect("selection_changed", self, "_on_selection_changed")
	if ply_mesh:
		ply_mesh.disconnect("mesh_updated", self, "_on_mesh_updated")

func _ready():
	_on_mesh_updated()

func _on_mesh_updated():
	if edge_idx >= ply_mesh.edge_count():
		# about to be freed
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

	if is_selected:
		mesh_instance.set("material/0", selected_material)
	else:
		mesh_instance.set("material/0", material)

func _on_selection_changed(_mode, _ply_instance, selection):
	is_selected = selection.has(self)

	if is_selected:
		mesh_instance.set("material/0", selected_material)
	else:
		mesh_instance.set("material/0", material)