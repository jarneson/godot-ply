tool
extends EditorInspectorPlugin

const PlyEditor = preload("res://addons/ply/nodes/ply.gd")
const InspectorControl = preload("res://addons/ply/gui/inspector/inspector.tscn")

var plugin


func _init(p) -> void:
	plugin = p


func can_handle(o: Object) -> bool:
	return o is PlyEditor


func parse_begin(o: Object) -> void:
	var inst = InspectorControl.instance()
	inst.plugin = plugin
	add_custom_control(inst)
