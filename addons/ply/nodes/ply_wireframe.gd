@tool
extends MeshInstance3D

@onready var editor = get_parent()

var m = StandardMaterial3D.new()

func _ready() -> void:
	mesh = ImmediateMesh.new()
	m.albedo_color = Color.WHITE
	# m.flags_no_depth_test = true # enable for xray
	m.flags_unshaded = true
	m.vertex_color_use_as_albedo = true


func _process(_delta) -> void:
	global_transform = editor.parent.global_transform
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, m)
	for e in range(editor.ply_mesh.edge_count()):
		if editor.selected_edges.has(e):
			mesh.surface_set_color(Color.GREEN)
		else:
			mesh.surface_set_color(Color.BLUE)
		var verts = editor.ply_mesh.edge(e)
		mesh.surface_add_vertex(verts[0])
		mesh.surface_add_vertex(verts[1])
	mesh.surface_end()
