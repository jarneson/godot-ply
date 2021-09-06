tool
extends Object

const PlyNode = preload("../nodes/ply.gd")
const Face = preload("../gui/face.gd")
const Edge = preload("../gui/edge.gd")
const Vertex = preload("../gui/vertex.gd")
const SelectionMode = preload("../utils/selection_mode.gd")
const Handle = preload("./handle.gd")

signal selection_changed(mode, ply_instance, selection)

var _plugin

var mode = SelectionMode.MESH

func _init(p: EditorPlugin):
    _plugin = p

var _editor_selection

var cursor = null

func startup():
    _editor_selection = _plugin.get_editor_interface().get_selection()
    _editor_selection.connect("selection_changed", self, "_on_selection_change")
    _plugin.hotbar.connect("selection_mode_changed", self, "_on_selection_mode_change")

func teardown():
    _editor_selection.disconnect("selection_changed", self, "_on_selection_change")
    _plugin.hotbar.disconnect("selection_mode_changed", self, "_on_selection_mode_change")
    cursor.queue_free()

func _new_cursor():
    if cursor:
        return
    var root = _plugin.get_tree().get_edited_scene_root()
    if root:
        cursor = Spatial.new()
        cursor.name = "__ply__cursor"
        root.add_child(cursor)
        _on_selection_change()

func _free_cursor():
    if cursor:
        if is_instance_valid(cursor):
            cursor.queue_free()
        cursor = null

func set_scene(scene):
    _free_handle()
    _free_cursor()
    _new_cursor()
    selection = []
    editing = null
    emit_signal("selection_changed", mode, editing, selection)

var editing = null
var selection = []

var handle = null

func _free_handle():
    if handle:
        if is_instance_valid(handle):
            handle.queue_free()
        handle = null

func _create_handle():
    _free_handle()
    handle = Handle.new(_plugin)
    var sum = Vector3.ZERO
    for n in selection:
        sum = sum+n.transform.origin
    handle.transform.origin = sum / selection.size()
    cursor.add_child(handle)

func _select_handle():
    var editor_selection = _editor_selection.get_selected_nodes()
    if editor_selection.size() == 1 and selection[0] == handle:
        return
    _editor_selection.clear()
    _editor_selection.add_node(handle)
    _editor_selection = _plugin.get_editor_interface().get_selection()
    _plugin.get_editor_interface().inspect_object(handle)

func _prepare_handle():
    if not editing:
        _free_handle()
        return
    if selection.size() == 0:
        _free_handle()
        return
    if mode == SelectionMode.MESH:
        _free_handle()
        return
    _new_cursor()
    _create_handle()
    _select_handle()

func _position_cursor():
    if not cursor:
        return
    if selection.size() == 0:
        cursor.transform = Transform.IDENTITY
    else:
        cursor.transform = editing.global_transform

func _on_selection_change():
    _editor_selection = _plugin.get_editor_interface().get_selection()
    var selected = _editor_selection.get_selected_nodes()
    match selected.size():
        0:
            selection = []
        1:
            if selected[0] is Handle:
                return
            elif selected[0] is PlyNode:
                editing = selected[0]
                if mode == SelectionMode.MESH:
                    selection = selected
                else:
                    _editor_selection.remove_node(selected[0])
                    selection = []
            elif selected[0] is Face and mode == SelectionMode.FACE:
                selection = selected
            elif selected[0] is Edge and mode == SelectionMode.EDGE:
                selection = selected
            elif selected[0] is Vertex and mode == SelectionMode.VERTEX:
                selection = selected
            else:
                editing = null
                selection = []
        _:
            var ok = true
            for node in selected:
                if node is Handle:
                    continue
                match mode:
                    SelectionMode.MESH:
                        ok = ok and node is PlyNode
                    SelectionMode.FACE:
                        ok = ok and node is Face
                    SelectionMode.EDGE:
                        ok = ok and node is Edge
                    SelectionMode.VERTEX:
                        ok = ok and node is Vertex
                if not ok:
                    break
                if handle and selection.has(node):
                    selection.erase(node)
                elif not selection.has(node):
                    selection.push_back(node)
            if not ok:
                editing = null
                selection = []
    _prepare_handle()
    _position_cursor()
    emit_signal("selection_changed", mode, editing, selection)
            
func _on_selection_mode_change(m):
    if mode != m:
        _editor_selection.clear()
        selection = []
    mode = m
    if editing and mode == SelectionMode.MESH:
        _editor_selection.add_node(editing)
        _plugin.get_editor_interface().inspect_object(editing)
        selection = [editing]
    emit_signal("selection_changed", mode, editing, selection)