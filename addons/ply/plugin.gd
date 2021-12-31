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
const Toolbar2 = preload("./plugin/toolbar2.gd")

const SelectionMode = preload("./utils/selection_mode.gd")
const PlyNode = preload("./nodes/ply.gd")
const Face = preload("./gui/face.gd")
const Edge = preload("./gui/edge.gd")
const Editor = preload("./gui/editor.gd")
const Handle = preload("./plugin/handle.gd")
const TransformGizmo = preload("./plugin/transform_gizmo.gd")

const Interop = preload("./interop.gd")

const PlyEditor = preload("./nodes/ply2.gd")

func get_plugin_name():
    return "Ply"

var spatial_editor = null
var selector = null
var selector2: Selector2 
var toolbar = null
var toolbar2: Toolbar2
var transform_gizmo: TransformGizmo

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
    toolbar2 = Toolbar2.new(self)
    transform_gizmo = TransformGizmo.new(self)

    transform_gizmo.startup()
    selector2.startup()
    selector.startup()
    spatial_editor.startup()
    toolbar.startup()
    toolbar2.startup()

    set_force_draw_over_forwarding_enabled()
    set_input_event_forwarding_always_enabled()

func _exit_tree() -> void:
    remove_custom_type("PlyInstance")
    remove_custom_type("PlyEditor")

    toolbar.teardown()
    toolbar2.teardown()
    toolbar2.free()
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

var last_camera: Camera

func forward_spatial_gui_input(camera: Camera, event: InputEvent):
    last_camera = camera
    return selector2.handle_input(camera, event) 

func forward_spatial_force_draw_over_viewport(overlay: Control):
    pass

func _process(_delta):
    if last_camera:
        transform_gizmo.process()