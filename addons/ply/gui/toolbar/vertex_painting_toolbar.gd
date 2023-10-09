@tool
class_name  Vertex_Painting_Toolbar
extends HBoxContainer

var _plugin
@onready var chk_snap : CheckBox = $chk_snap

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_chk_vertex_painting_toggled(button_pressed):
	_plugin.vertex_painting_activated(button_pressed)

func snap_enabled():
	return chk_snap.button_pressed
