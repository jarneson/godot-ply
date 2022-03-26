@tool
extends EditorInspectorPlugin

const PlyEditor = preload("res://addons/ply/nodes/ply.gd")
const InspectorControl = preload("res://addons/ply/gui/inspector/inspector.tscn")

var plugin


func _init(p):
	plugin = p
	print("inspector plugin created")


func _can_handle(o: Variant) -> bool:
	print("inspector plugin can handle ", o is PlyEditor)
	return o is PlyEditor


func _parse_begin(o: Object) -> void:
	print("inspector plugin parse begin ")
	var inst = InspectorControl.instantiate()
	print("instanced ", inst)
	inst.plugin = plugin
	add_custom_control(inst)
	print("added ", inst)
