extends ImmediateGeometry

onready var editor = get_parent()


func _ready():
	var m = SpatialMaterial.new()
	m.albedo_color = Color.white
	m.flags_use_point_size = true
	# m.flags_no_depth_test = true # enable for xray
	m.flags_unshaded = true
	m.params_point_size = 10
	m.vertex_color_use_as_albedo = true
	set_material_override(m)


func _process(_delta):
	global_transform = editor.parent.global_transform
	clear()
	begin(Mesh.PRIMITIVE_LINES)
	for e in range(editor.ply_mesh.edge_count()):
		if editor.selected_edges.has(e):
			set_color(Color.green)
		else:
			set_color(Color.blue)
		var verts = editor.ply_mesh.edge(e)
		add_vertex(verts[0])
		add_vertex(verts[1])
	end()
