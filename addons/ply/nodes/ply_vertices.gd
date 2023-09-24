@tool
extends MeshInstance3D

@onready var editor = get_parent()

var m = StandardMaterial3D.new()

func _ready() -> void:
	mesh = ArrayMesh.new()
	m.albedo_color = Color.WHITE
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	# m.flags_no_depth_test = true # enable for x-ray
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.use_point_size = true
	m.point_size = 10
	m.vertex_color_use_as_albedo = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(_delta) -> void:
	var ts = Time.get_ticks_usec()
	global_transform = editor.parent.global_transform

	var vtxs = PackedVector3Array()
	vtxs.resize(editor.editor.vertex_count())
	var colors = PackedColorArray()
	colors.resize(editor.editor.vertex_count())

	for i in range(editor.editor.vertex_count()):
		vtxs[i] = editor.editor.get_vertex(i).position()
		if editor.selected_vertices.has(i):
			colors[i] = Color.GREEN
		else:
			colors[i] = Color.BLUE

	mesh.clear_surfaces()
	var arrs = []
	arrs.resize(Mesh.ARRAY_MAX)
	arrs[Mesh.ARRAY_VERTEX] = vtxs
	arrs[Mesh.ARRAY_COLOR] = colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrs)
	mesh.surface_set_material(0, m)
	print("update verts took ", Time.get_ticks_usec() - ts, "us")
