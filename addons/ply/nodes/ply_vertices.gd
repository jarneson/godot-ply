extends MeshInstance3D

@onready var editor = get_parent()

var m = StandardMaterial3D.new()

func _ready() -> void:
	mesh = ImmediateMesh.new()
	m.albedo_color = Color.WHITE
	m.flags_use_point_size = true
	# m.flags_no_depth_test = true # enable for x-ray
	m.flags_unshaded = true
	m.params_point_size = 10
	m.vertex_color_use_as_albedo = true


func _process(_delta) -> void:
	global_transform = editor.parent.global_transform
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_POINTS)
	for v in range(editor.ply_mesh.vertex_count()):
		if editor.selected_vertices.has(v):
			mesh.surface_set_color(Color.GREEN)
		else:
			mesh.surface_set_color(Color.BLUE)
		mesh.surface_add_vertex(editor.ply_mesh.vertexes[v])
	mesh.surface_end()
