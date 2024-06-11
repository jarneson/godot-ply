@tool
extends EditorPlugin

signal selection_changed(selection)

const Selector = preload("res://addons/ply/plugin/selector.gd")

const SelectionMode = preload("res://addons/ply/utils/selection_mode.gd")
const TransformGizmo = preload("res://addons/ply/plugin/transform_gizmo.gd")
const Inspector = preload("res://addons/ply/plugin/inspector.gd")

const Interop = preload("res://addons/ply/interop.gd")
const Settings = preload("res://addons/ply/settings.gd")

const PlyEditor = preload("res://addons/ply/nodes/ply.gd")

var editor_settings = get_editor_interface().get_editor_settings()
var snap_values = {translate=1.0, rotate=15.0, scale=0.1}

func _get_plugin_name() -> String:
	return "Ply"


var selector: Selector
var transform_gizmo: TransformGizmo
var inspector: Inspector
var ignore_inputs = false

const DEFAULT_SETTINGS: Dictionary = { #Dictionary[String, Variant]
	'snap': true,
}
var current_settings := DEFAULT_SETTINGS



func save_settings(default := false):
	var settings_file := FileAccess.open('res://addons/ply/settings.json', FileAccess.WRITE_READ)
	print(settings_file)
	settings_file.store_line(JSON.stringify(DEFAULT_SETTINGS if default else current_settings))
	settings_file.close()
	if default:
		current_settings = DEFAULT_SETTINGS

func load_settings():
	if not FileAccess.file_exists('res://addons/ply/settings.json'):
		save_settings(true) #create file
	
	var settings_file := FileAccess.open('res://addons/ply/settings.json', FileAccess.READ)
	var data: Variant = JSON.parse_string(settings_file.get_as_text()) if settings_file != null else null
	if data != null:
		current_settings = data
	else:
		save_settings(true) #overwrite file to default if error


var toolbar = preload("res://addons/ply/gui/toolbar/toolbar.tscn").instantiate()


func _enter_tree() -> void:
	Interop.register(self, "ply")
	Settings.initialize_plugin_settings(editor_settings)
	
	add_custom_type(
		"PlyEditor",
		"Node",
		preload("res://addons/ply/nodes/ply.gd"),
		preload("res://addons/ply/icons/plugin.svg")
	)

	selector = Selector.new(self)
	transform_gizmo = TransformGizmo.new(self)
	inspector = Inspector.new(self)

	transform_gizmo.startup()
	selector.startup()
	add_inspector_plugin(inspector)

	load_settings()
	toolbar.plugin = self
	toolbar.visible = false
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, toolbar)
	
	snap_values.translate = editor_settings.get_setting('editors/ply_gizmos/snap_increments/translate')
	snap_values.rotate = editor_settings.get_setting('editors/ply_gizmos/snap_increments/rotate')
	snap_values.scale = editor_settings.get_setting('editors/ply_gizmos/snap_increments/scale')


func _exit_tree() -> void:
	remove_custom_type("PlyInstance")
	remove_custom_type("PlyEditor")

	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, toolbar)
	remove_inspector_plugin(inspector)
	transform_gizmo.teardown()
	toolbar.queue_free()
	selector.teardown()
	selector.free()
	Interop.deregister(self)


func _handles(o: Object) -> bool:
	return o is PlyEditor


func _clear() -> void:
	pass


var selection	# nullable PlyEditor


func change_settings_key(key: String, value: Variant) -> void:
	if !DEFAULT_SETTINGS.has(key):
		printerr('PlyEditor: Not found "', key, '" key')
		return
	current_settings[key] = value
	save_settings()



func _edit(o: Object) -> void:
	if selection and not selection.is_queued_for_deletion():
		selection.selected = false
		selection = null
	
	if o == null:
		toolbar.visible = false
	else:
		selection = o
		selection.selected = true
		emit_signal("selection_changed", selection)


func _make_visible(vis: bool) -> void:
	toolbar.visible = vis


var last_camera: Camera3D


func _forward_3d_draw_over_viewport(overlay):
	selector.draw_box_selection(overlay)


func _forward_3d_gui_input(camera: Camera3D, event: InputEvent):
	last_camera = camera
	return selector.handle_input(camera, event)


func _process(_delta) -> void:
	if last_camera:
		transform_gizmo.process()
