tool
extends ToolButton


func _ready() -> void:
	connect("pressed", self, "_on_pressed")


func _on_pressed() -> void:
	OS.shell_open("https://github.com/jarneson/godot-ply")
