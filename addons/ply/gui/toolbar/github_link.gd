tool
extends ToolButton


func _ready():
	connect("pressed", self, "_on_pressed")


func _on_pressed():
	OS.shell_open("https://github.com/jarneson/godot-ply")
