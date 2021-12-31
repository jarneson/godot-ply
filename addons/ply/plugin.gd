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
const Selector = preload("./plugin/selector2.gd")
const Toolbar = preload("./plugin/toolbar2.gd")

const SelectionMode = preload("./utils/selection_mode.gd")
const TransformGizmo = preload("./plugin/transform_gizmo.gd")

const Interop = preload("./interop.gd")

const PlyEditor = preload("./nodes/ply2.gd")

func get_plugin_name():
    return "Ply"

var selector: Selector
var selector2: Selector
var toolbar: Toolbar
var toolbar2: Toolbar
var transform_gizmo: TransformGizmo

func _enter_tree() -> void:
    Interop.register(self, "ply")
    add_custom_type("PlyEditor", "Node", preload("./nodes/ply2.gd"), preload("./icons/plugin.svg"))

    selector = Selector.new(self)
    selector2 = selector
    toolbar = Toolbar.new(self)
    toolbar2 = toolbar
    transform_gizmo = TransformGizmo.new(self)

    transform_gizmo.startup()
    selector.startup()
    toolbar.startup()

func _exit_tree() -> void:
    remove_custom_type("PlyInstance")
    remove_custom_type("PlyEditor")

    toolbar.teardown()
    toolbar.free()
    selector.teardown()
    selector.free()
    Interop.deregister(self)

func handles(o: Object):
    return o is PlyEditor

func clear():
    print("clear")

var selection # nullable PlyEditor

func edit(o: Object):
    assert(o is PlyEditor)
    selection = o

func make_visible(vis: bool):
    toolbar.toolbar.visible = vis
    if selection:
        selection.selected = vis
    if vis:
        transform_gizmo.startup()
    else:
        transform_gizmo.teardown()
        selection = null

var ignore_inputs = false

func _interop_notification(caller_plugin_id: String, code: int, _id, _args):
    if caller_plugin_id == "gsr":
        match code:
            Interop.NOTIFY_CODE_WORK_STARTED:
                ignore_inputs = true
            Interop.NOTIFY_CODE_WORK_ENDED:
                ignore_inputs = false

var last_camera: Camera

func forward_spatial_gui_input(camera: Camera, event: InputEvent):
    last_camera = camera
    return selector2.handle_input(camera, event) 

func _process(_delta):
    if not selection:
        return
    if last_camera:
        transform_gizmo.process()