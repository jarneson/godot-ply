tool
extends Object

var toolbar = preload("../gui/toolbar/toolbar.tscn").instance()

var _plugin

func _init(plugin):
    _plugin = plugin

func startup():
    _plugin.add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT , toolbar)
    toolbar.visible = false
    _plugin.selector2.connect("selection_changed", self, "_on_selection_changed")
    toolbar.transform_toggle.visible = false 
    # _connect_toolbar_handlers()

func teardown():
    toolbar.visible = false
    _plugin.remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT , toolbar)
    _plugin.selector.disconnect("selection_changed", self, "_on_selection_changed")
    toolbar.queue_free()

func _on_selection_changed(selection):
    if selection:
        toolbar.visible = true
    else:
        toolbar.visible = false