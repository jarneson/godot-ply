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
var interop = null

func _enter_tree() -> void:
    interop = Interop.get_instance(self, "res://addons/ply/interop_node.gd")
    interop.register("ply", self)
    add_custom_type("PlyInstance", "MeshInstance", preload("./nodes/ply.gd"), preload("./icons/plugin.svg"))
    undo_redo = get_undo_redo()

    selector = Selector.new(self)
    spatial_editor = SpatialEditor.new(self)
    toolbar = Toolbar.new(self)

    selector.startup()
    spatial_editor.startup()
    toolbar.startup()

    set_input_event_forwarding_always_enabled()

func _exit_tree() -> void:
    interop.deregister("ply", self)
    remove_custom_type("PlyInstance")

    toolbar.teardown()
    spatial_editor.teardown()
    selector.teardown()

func get_state():
    return { 
        "selector": selector.get_state(),
        "spatial_editor": spatial_editor.get_state()
    }

func set_state(state):
    selector.set_state(state.get("selector"))
    spatial_editor.set_state(state.get("spatial_editor"))

"""
███████╗███████╗██╗     ███████╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗
██╔════╝██╔════╝██║     ██╔════╝██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║
███████╗█████╗  ██║     █████╗  ██║        ██║   ██║██║   ██║██╔██╗ ██║
╚════██║██╔══╝  ██║     ██╔══╝  ██║        ██║   ██║██║   ██║██║╚██╗██║
███████║███████╗███████╗███████╗╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║
╚══════╝╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
"""

func forward_spatial_gui_input(camera, event):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            return selector.handle_click(camera, event)
    return false