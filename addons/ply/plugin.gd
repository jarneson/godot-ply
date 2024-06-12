@tool
extends EditorPlugin

signal selection_changed(selection)

const Selector = preload("res://addons/ply/plugin/selector.gd")

const SelectionMode = preload("res://addons/ply/utils/selection_mode.gd")
const TransformGizmo = preload("res://addons/ply/plugin/transform_gizmo.gd")
const Inspector = preload("res://addons/ply/plugin/inspector.gd")

#const Interop = preload("res://addons/ply/interop.gd")
const Settings = preload("res://addons/ply/settings.gd")

const PlyEditor = preload("res://addons/ply/nodes/ply.gd")

var vertexPainting_toolbar = load("res://addons/ply/gui/toolbar/vertex_painting_toolbar.tscn").instantiate()
var vertexPainting_color_picker = load("res://addons/ply/gui/toolbar/vertex_painting_color_picker.tscn").instantiate()

var editor_interface = get_editor_interface()
var editor_settings = get_editor_interface().get_editor_settings()
var snap_values = {translate=0.5, rotate=15.0, scale=0.1}
var snap := false

var editor_camera : Camera3D

func _get_plugin_name() -> String:
	return "Ply"


var selector: Selector
var transform_gizmo: TransformGizmo
var inspector: Inspector
var ignore_inputs = false

var toolbar = preload("res://addons/ply/gui/toolbar/toolbar.tscn").instantiate()


func _enter_tree() -> void:
	#Interop.register(self, "ply")
	Settings.initialize_plugin_settings(editor_settings)
	
	add_custom_type(
		"PlyEditor",
		"PlyEditor",
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
	
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, vertexPainting_toolbar)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, vertexPainting_color_picker)
	
	vertexPainting_toolbar._plugin = self
	selector._vertex_painting_toolbar = vertexPainting_toolbar
	vertexPainting_color_picker.hide()
	
func _exit_tree() -> void:
	remove_custom_type("PlyInstance")
	remove_custom_type("PlyEditor")
	
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, vertexPainting_toolbar)
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, vertexPainting_color_picker)


	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, toolbar)
	remove_inspector_plugin(inspector)
	transform_gizmo.teardown()
	toolbar.queue_free()
	selector.teardown()
	selector.free()
	#Interop.deregister(self)


func _handles(o: Object) -> bool:
	return o is PlyEditor


func _clear() -> void:
	pass


var selection	# nullable PlyEditor
var selected_node_parent

func _edit(o: Object) -> void:
	if selection and not selection.is_queued_for_deletion():
		selection.selected = false
		selection = null
	elif selection:
		if not (weakref(selection).get_ref()):
			selection.selected = false
			selection = null
	
	if o == null:
		toolbar.visible = false
	else:
		selection = o
		selection.selected = true
		emit_signal("selection_changed", selection)
	if (o is PlyEditor):
		transform_gizmo.valid_selection = true
		selected_node_parent = o.get_parent()
	else:
		transform_gizmo.valid_selection = false
		transform_gizmo.transform = null
		selected_node_parent = null
		
		

func _make_visible(vis: bool) -> void:
	toolbar.visible = vis


var last_camera: Camera3D


func _forward_3d_draw_over_viewport(overlay):
	selector.draw_box_selection(overlay)


func _forward_3d_gui_input(camera: Camera3D, event: InputEvent):
	editor_camera = camera
	last_camera = camera
	
	return selector.handle_input(camera, event)

func _process(_delta) -> void:
	if last_camera:
		transform_gizmo.process()
	
	
func set_timer_ignore_input():
	ignore_inputs = true
	await get_tree().create_timer(0.1).timeout
	ignore_inputs = false

func vertex_painting_activated(_par):
	if _par:
		toolbar.hide()
		vertexPainting_color_picker.show()
		selector.vertex_painting_start()
	else:
		toolbar.show()
		vertexPainting_color_picker.hide()
		selector.vertex_painting_end()
