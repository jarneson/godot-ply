@tool
extends MeshInstance3D

@onready var editor = get_parent()

var m = StandardMaterial3D.new()

func _ready() -> void:
	mesh = ArrayMesh.new()
	m.albedo_color = Color.WHITE
	# m.flags_no_depth_test = true # enable for xray
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(_delta) -> void:
	global_transform = editor.parent.global_transform

	var vtxs = PackedVector3Array()
	vtxs.resize(2 * editor.editor.edge_count())
	var colors = PackedColorArray()
	colors.resize(2 * editor.editor.edge_count())

	for i in range(editor.editor.edge_count()):
		var e = editor.editor.get_edge(i)
		vtxs[2*i] = e.origin().position()
		vtxs[2*i+1] = e.destination().position()
		if editor.selected_edges.has(i):
			colors[2*i] = Color.GREEN
			colors[2*i+1] = Color.GREEN
		else:
			colors[2*i] = Color.BLUE
			colors[2*i+1] = Color.BLUE

	mesh.clear_surfaces()
	if vtxs.size() == 0:
		return
	var arrs = []
	arrs.resize(Mesh.ARRAY_MAX)
	arrs[Mesh.ARRAY_VERTEX] = vtxs
	arrs[Mesh.ARRAY_COLOR] = colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrs)
	mesh.surface_set_material(0, m)
