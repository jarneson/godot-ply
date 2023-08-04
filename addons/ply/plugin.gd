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


func _edit(o: Object) -> void:
	if selection:
		selection.selected = false

	selection = o
	emit_signal("selection_changed", selection)


func _make_visible(vis: bool) -> void:
	toolbar.visible = vis


var ignore_inputs = false


func _interop_notification(caller_plugin_id: String, code: int, _id, _args) -> void:
	if caller_plugin_id == "gsr":
		match code:
			Interop.NOTIFY_CODE_WORK_STARTED:
				ignore_inputs = true
			Interop.NOTIFY_CODE_WORK_ENDED:
				ignore_inputs = false


var last_camera: Camera3D


func _forward_3d_draw_over_viewport(overlay):
	selector.draw_box_selection(overlay)


func _forward_3d_gui_input(camera: Camera3D, event: InputEvent):
	last_camera = camera
	return selector.handle_input(camera, event)


func _process(_delta) -> void:
	if last_camera:
		transform_gizmo.process()
