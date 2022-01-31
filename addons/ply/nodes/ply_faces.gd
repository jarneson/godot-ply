extends MeshInstance3D

@onready var editor = get_parent()

var m = StandardMaterial3D.new()

func _ready() -> void:
	mesh = ImmediateMesh.new()
	m.albedo_color = Color(1, 1, 1, 0.5)
	m.flags_use_point_size = true
	m.flags_unshaded = true
	m.flags_transparent = true
	m.params_point_size = 10
	m.vertex_color_use_as_albedo = true
	m.params_grow = true
	m.params_grow_amount = 1.0
	# m.flags_no_depth_test = true # enable for xray
	# m.params_cull_mode = StandardMaterial3D.CULL_DISABLED # enable for xray


func _process(_delta) -> void:
	global_transform = editor.parent.global_transform
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.surface_set_color(Color(0, 1, 0, 0.5))
	for f in range(editor.ply_mesh.face_count()):
		if not editor.selected_faces.has(f):
			continue
		var normal = editor.ply_mesh.face_normal(f)
		var ft = editor.ply_mesh.face_tris(f)
		var verts = ft[0]
		var tris = ft[1]
		if verts.size() == 0:
			continue
		for tri in tris:
			mesh.surface_add_vertex(verts[tri[0]][0] + normal * 0.001)
			mesh.surface_add_vertex(verts[tri[1]][0] + normal * 0.001)
			mesh.surface_add_vertex(verts[tri[2]][0] + normal * 0.001)
	mesh.surface_end()
