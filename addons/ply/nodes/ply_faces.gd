@tool
extends MeshInstance3D

const MeshTools = preload("res://addons/ply/utils/mesh.gd")

@onready var editor = get_parent()

var m = StandardMaterial3D.new()

func _ready() -> void:
	mesh = ImmediateMesh.new()
	m.albedo_color = Color(0, 1, 0, 0.04)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	# m.flags_no_depth_test = true # enable for xray
	# m.params_cull_mode = StandardMaterial3D.CULL_DISABLED # enable for xray


func _process(_delta) -> void:
	global_transform = editor.parent.global_transform
	mesh.clear_surfaces()
	if editor.selected_faces == null or editor.selected_faces.size() == 0:
		return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, m)
	
	editor.editor.call_each_face(func(f):
		if not editor.selected_faces.has(f.id()):
			return
		var normal = f.normal()
		var tris = f.tris()
		for i in range(0, tris.size(), 3):
			mesh.surface_add_vertex(tris[i] + normal * 0.001)
			mesh.surface_add_vertex(tris[i+1] + normal * 0.001)
			mesh.surface_add_vertex(tris[i+2] + normal * 0.001)
	)
	mesh.surface_end()
