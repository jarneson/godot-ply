extends ImmediateGeometry

onready var editor = get_parent()


func _ready():
	var m = SpatialMaterial.new()
	m.albedo_color = Color(1, 1, 1, 0.5)
	m.flags_use_point_size = true
	m.flags_unshaded = true
	m.flags_transparent = true
	m.params_point_size = 10
	m.vertex_color_use_as_albedo = true
	m.params_grow = true
	m.params_grow_amount = 1.0
	# m.flags_no_depth_test = true # enable for xray
	# m.params_cull_mode = SpatialMaterial.CULL_DISABLED # enable for xray
	set_material_override(m)


func _process(_delta):
	global_transform = editor.parent.global_transform
	clear()
	begin(Mesh.PRIMITIVE_TRIANGLES)
	set_color(Color(0, 1, 0, 0.5))
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
			add_vertex(verts[tri[0]][0] + normal * 0.001)
			add_vertex(verts[tri[1]][0] + normal * 0.001)
			add_vertex(verts[tri[2]][0] + normal * 0.001)
	end()
