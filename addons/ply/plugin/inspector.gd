@tool
extends EditorInspectorPlugin

const PlyEditor = preload("res://addons/ply/nodes/ply.gd")
const InspectorControl = preload("res://addons/ply/gui/inspector/inspector.tscn")

var plugin


func _init(p):
	plugin = p


func _can_handle(o: Object) -> bool:
	return o is PlyEditor


func _parse_begin(o: Object) -> void:
	var inst = InspectorControl.instantiate()
	inst.plugin = plugin
	add_custom_control(inst)
