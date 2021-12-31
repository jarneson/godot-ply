tool
extends Object

var toolbar = preload("../gui/toolbar/toolbar.tscn").instance()

var _plugin

func _init(plugin):
    _plugin = plugin

func startup():
    _plugin.add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT , toolbar)
    toolbar.visible = false
    toolbar.transform_toggle.visible = false 

func teardown():
    toolbar.visible = false
    _plugin.remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT , toolbar)
    toolbar.queue_free()
