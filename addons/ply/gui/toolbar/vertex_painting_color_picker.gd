@tool
extends ScrollContainer

@onready var color_picker = $VBoxContainer/ColorPicker
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_color():
	return color_picker.color
