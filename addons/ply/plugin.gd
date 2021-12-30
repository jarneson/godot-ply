tool
extends EditorPlugin

"""
██████╗ ██████╗ ███████╗██╗      ██████╗  █████╗ ██████╗ ███████╗
██╔══██╗██╔══██╗██╔════╝██║     ██╔═══██╗██╔══██╗██╔══██╗██╔════╝
██████╔╝██████╔╝█████╗  ██║     ██║   ██║███████║██║  ██║███████╗
██╔═══╝ ██╔══██╗██╔══╝  ██║     ██║   ██║██╔══██║██║  ██║╚════██║
██║     ██║  ██║███████╗███████╗╚██████╔╝██║  ██║██████╔╝███████║
╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝
"""
const Selector = preload("./plugin/selector.gd")
const Selector2 = preload("./plugin/selector2.gd")
const SpatialEditor = preload("./plugin/spatial_editor.gd")
const Toolbar = preload("./plugin/toolbar.gd")

const SelectionMode = preload("./utils/selection_mode.gd")
const PlyNode = preload("./nodes/ply.gd")
const Face = preload("./gui/face.gd")
const Edge = preload("./gui/edge.gd")
const Editor = preload("./gui/editor.gd")
const Handle = preload("./plugin/handle.gd")

const Interop = preload("./interop.gd")

func get_plugin_name():
    return "Ply"

var spatial_editor = null
var selector = null
var selector2: Selector2 
var toolbar = null

var undo_redo = null

"""
███████╗████████╗ █████╗ ██████╗ ████████╗██╗   ██╗██████╗   ██╗████████╗███████╗ █████╗ ██████╗ ██████╗  ██████╗ ██╗    ██╗███╗   ██╗
██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝██║   ██║██╔══██╗ ██╔╝╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██║    ██║████╗  ██║
███████╗   ██║   ███████║██████╔╝   ██║   ██║   ██║██████╔╝██╔╝    ██║   █████╗  ███████║██████╔╝██║  ██║██║   ██║██║ █╗ ██║██╔██╗ ██║
╚════██║   ██║   ██╔══██║██╔══██╗   ██║   ██║   ██║██╔═══╝██╔╝     ██║   ██╔══╝  ██╔══██║██╔══██╗██║  ██║██║   ██║██║███╗██║██║╚██╗██║
███████║   ██║   ██║  ██║██║  ██║   ██║   ╚██████╔╝██║   ██╔╝      ██║   ███████╗██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝██║ ╚████║
╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝   ╚═╝       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝
"""

func _enter_tree() -> void:
    Interop.register(self, "ply")
    add_custom_type("PlyInstance", "MeshInstance", preload("./nodes/ply.gd"), preload("./icons/plugin.svg"))
    add_custom_type("PlyEditor", "Node", preload("./nodes/ply2.gd"), preload("./icons/plugin.svg"))
    undo_redo = get_undo_redo()

    selector = Selector.new(self)
    selector2 = Selector2.new(self)
    spatial_editor = SpatialEditor.new(self)
    toolbar = Toolbar.new(self)

    selector2.startup()
    selector.startup()
    spatial_editor.startup()
    toolbar.startup()

    set_input_event_forwarding_always_enabled()

func _exit_tree() -> void:
    remove_custom_type("PlyInstance")
    remove_custom_type("PlyEditor")

    toolbar.teardown()
    spatial_editor.teardown()
    selector.teardown()
    selector2.teardown()
    selector2.free()
    Interop.deregister(self)

func get_state():
    return { 
        "selector": selector.get_state(),
        "spatial_editor": spatial_editor.get_state()
    }

func set_state(state):
    selector.set_state(state.get("selector"))
    spatial_editor.set_state(state.get("spatial_editor"))

var ignore_inputs = false

func _interop_notification(caller_plugin_id, code, _id, _args):
    if caller_plugin_id == "gsr":
        match code:
            Interop.NOTIFY_CODE_WORK_STARTED:
                ignore_inputs = true
            Interop.NOTIFY_CODE_WORK_ENDED:
                ignore_inputs = false

"""
███████╗███████╗██╗     ███████╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗
██╔════╝██╔════╝██║     ██╔════╝██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║
███████╗█████╗  ██║     █████╗  ██║        ██║   ██║██║   ██║██╔██╗ ██║
╚════██║██╔══╝  ██║     ██╔══╝  ██║        ██║   ██║██║   ██║██║╚██╗██║
███████║███████╗███████╗███████╗╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║
╚══════╝╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
"""

func forward_spatial_gui_input(camera: Camera, event: InputEvent):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            return selector2.handle_click(camera, event) || selector.handle_click(camera, event)
    return false