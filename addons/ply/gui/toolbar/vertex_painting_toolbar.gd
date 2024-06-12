@tool
class_name  Vertex_Painting_Toolbar
extends HBoxContainer

var _plugin : EditorPlugin
@onready var chk_snap : CheckBox = $chk_snap

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_chk_vertex_painting_toggled(button_pressed):
	_plugin.vertex_painting_activated(button_pressed)

func snap_enabled():
	return chk_snap.button_pressed


func _on_btn_ply_box_button_down():
	ply_box_new(false)
	pass # Replace with function body.


func _on_btn_ply_box_with_collision_button_down():
	ply_box_new(true)
	
	pass # Replace with function body.

func ply_box_new(collision = false):
	var node_root = _plugin.get_editor_interface().get_edited_scene_root()
	var mesh := MeshInstance3D.new()
	var ply = load("res://addons/ply/nodes/ply.gd").new()
	mesh.add_child(ply)
	node_root.add_child(mesh)
	mesh.owner = node_root
	mesh.name = "PlyMesh"
	ply.owner = node_root
	ply.name = "PlyEditor"
	_plugin.get_editor_interface().edit_node(ply)
	_plugin.toolbar._generate_cube([1,0])
	if collision:
		create_collision(node_root, mesh)
	
func create_collision(node_root, mesh):
	var staticbody := StaticBody3D.new()
	var colshape := CollisionShape3D.new()
	var shape = ConcavePolygonShape3D.new()
	mesh.add_child(staticbody)
	staticbody.add_child(colshape)
	staticbody.owner = node_root
	staticbody.name = "StaticBody3D"
	colshape.owner = node_root
	colshape.shape = shape
	colshape.name = "CollisionShape3D"


func _on_popup_menu_index_pressed(index):
	match index:
		0:
			ply_box_new(false)
		1:
			ply_box_new(true)
