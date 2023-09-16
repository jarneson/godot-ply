@tool
extends MeshInstance3D

@onready var editor = get_parent()

var m = StandardMaterial3D.new()

func _ready() -> void:
	mesh = ImmediateMesh.new()
	m.albedo_color = Color.WHITE
	# m.flags_no_depth_test = true # enable for xray
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(_delta) -> void:
	global_transform = editor.parent.global_transform
	mesh.clear_surfaces()

	mesh.surface_begin(Mesh.PRIMITIVE_LINES, m)
	editor.editor.call_each_edge(func(e):
		if editor.selected_edges.has(e.id()):
			mesh.surface_set_color(Color.GREEN)
		else:
			mesh.surface_set_color(Color.BLUE)
		mesh.surface_add_vertex(e.origin().position())
		mesh.surface_add_vertex(e.destination().position())
	)
	mesh.surface_end()
