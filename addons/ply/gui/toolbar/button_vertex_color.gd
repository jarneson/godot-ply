@tool
class_name ButtonVertexColor
extends ColorPickerButton

var has_mouse = false
# Called when the node enters the scene tree for the first time.
func _ready():
	text = "      "

func _input(event):
	if not has_mouse:
		return
		
	if event is InputEventMouseButton :
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			apply_vertex_color()
		
func _on_mouse_entered():
	has_mouse = true


func _on_mouse_exited():
	has_mouse = false

func apply_vertex_color():
	owner._on_face_color_changed(color)
	pass


func _on_color_changed(color):
	get_parent().save_color(name, color)
