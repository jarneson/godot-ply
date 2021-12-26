tool
extends Spatial

export(int) var face_idx = -1
export(Resource) var ply_mesh

var plugin

onready var mesh_instance = $MeshInstance

var material = preload("./face_material.tres")
var selected_material = preload("./face_selected_material.tres")

var vertex_idxs = PoolIntArray()
var vertexes = PoolVector3Array()
var geometric_median 
var face_normal
var is_selected = false

func get_idx():
	return face_idx

func _enter_tree():
	if face_idx < 0 or not ply_mesh:
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

func _ready():
	set_meta("_edit_lock_", true)
	mesh_instance.set_meta("_edit_lock", true)
	is_selected = plugin.selector.selection.has(face_idx)
	_on_mesh_updated()

var prev_vertexes = null
func _on_mesh_updated():
	if face_idx >= ply_mesh.face_count():
		# about to be freed
		return
	vertex_idxs = ply_mesh.face_vertex_indexes(face_idx)
	vertexes.resize(0)
	vertexes.resize(vertex_idxs.size())
	for i in range(vertex_idxs.size()):
		vertexes[i] = ply_mesh.vertexes[vertex_idxs[i]]

	if prev_vertexes and prev_vertexes.size() == vertexes.size():
		var skip = true
		for idx in range(prev_vertexes.size()):
			if prev_vertexes[idx] != vertexes[idx]:
				skip = false
				break
		if skip:
			return
	prev_vertexes = vertexes

	geometric_median = ply_mesh.geometric_median(vertexes)
	face_normal = ply_mesh.average_vertex_normal(vertexes)
	self.transform.origin = geometric_median + 0.0001 * face_normal

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	ply_mesh.render_face(st, face_idx, -geometric_median)
	st.generate_normals()
	mesh_instance.mesh = st.commit()
	if is_selected:
		mesh_instance.set("material/0", selected_material)
	else:
		mesh_instance.set("material/0", material)

func _on_selection_changed(_mode, _ply_instance, selection):
	is_selected = selection.has(face_idx)
	if is_selected:
		mesh_instance.set("material/0", selected_material)
	else:
		mesh_instance.set("material/0", material)

func intersect_ray_distance(ray_start, ray_dir):
	return ply_mesh.face_intersect_ray_distance(face_idx, ray_start, ray_dir)