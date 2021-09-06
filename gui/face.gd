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

func _enter_tree():
	if face_idx < 0 or not ply_mesh:
		return
	calculate_vertex_data()

	if ply_mesh:
		ply_mesh.connect("mesh_updated", self, "calculate_vertex_data")

func _exit_tree():
	if ply_mesh:
		ply_mesh.disconnect("mesh_updated", self, "calculate_vertex_data")

func calculate_vertex_data():
	if not ply_mesh or face_idx < 0 or face_idx >= ply_mesh.face_edges.size():
		return 
	vertex_idxs = ply_mesh.face_vertex_indexes(face_idx)
	vertexes.resize(0)
	for idx in vertex_idxs:
		vertexes.push_back(ply_mesh.vertexes[idx])
	geometric_median = ply_mesh.geometric_median(vertexes)
	face_normal = ply_mesh.average_vertex_normal(vertexes)
	self.transform.origin = geometric_median + 0.0001 * face_normal

func _process(delta):
	if not plugin:
		return
	if not ply_mesh or face_idx < 0 or face_idx >= ply_mesh.face_edges.size():
		queue_free()
		return
	if not geometric_median:
		return

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	ply_mesh.render_face(st, face_idx, -geometric_median)
	st.generate_normals()
	mesh_instance.mesh = st.commit()

	if plugin.selector.selection.has(self):
		mesh_instance.set("material/0", selected_material)
	else:
		mesh_instance.set("material/0", material)