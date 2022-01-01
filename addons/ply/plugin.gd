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

const SelectionMode = preload("./utils/selection_mode.gd")
const TransformGizmo = preload("./plugin/transform_gizmo.gd")

const Interop = preload("./interop.gd")

const PlyEditor = preload("./nodes/ply2.gd")

func get_plugin_name():
    return "Ply"

var selector: Selector
var transform_gizmo: TransformGizmo

var toolbar = preload("./gui/toolbar/toolbar.tscn").instance()

func _enter_tree() -> void:
    Interop.register(self, "ply")
    add_custom_type("PlyEditor", "Node", preload("./nodes/ply2.gd"), preload("./icons/plugin.svg"))

    selector = Selector.new(self)
    transform_gizmo = TransformGizmo.new(self)

    transform_gizmo.startup()
    selector.startup()

    toolbar.plugin = self
    toolbar.visible = false
    add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT , toolbar)

func _exit_tree() -> void:
    remove_custom_type("PlyInstance")
    remove_custom_type("PlyEditor")

    remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT , toolbar)
    transform_gizmo.teardown()
    toolbar.queue_free()
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
    print("visible: ", vis)
    toolbar.visible = vis
    if selection:
        selection.selected = vis
    if not vis:
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
    return selector.handle_input(camera, event) 

func _process(_delta):
    if last_camera:
        transform_gizmo.process()