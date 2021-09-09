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
var _editor_selection

func _init(p: EditorPlugin):
    _plugin = p

func startup():
    _editor_selection = _plugin.get_editor_interface().get_selection()
    _editor_selection.connect("selection_changed", self, "_on_selection_change")
    _plugin.hotbar.connect("selection_mode_changed", self, "_on_selection_mode_change")

func teardown():
    _editor_selection.disconnect("selection_changed", self, "_on_selection_change")
    _plugin.hotbar.disconnect("selection_mode_changed", self, "_on_selection_mode_change")
    cursor.queue_free()

var mode = SelectionMode.MESH
var editing = null
var selection = []

var cursor = null
var handle = null

var _mesh_index_sentry = -90

func _set_selection(new_mode, new_editing, new_selection):
    var selection_compare = selection.duplicate()
    for s in new_selection:
        selection_compare.erase(s)
    if mode == new_mode and editing == new_editing and selection.size() == new_selection.size() and selection_compare.size() == 0:
        # print("selection equal %s==%s %s==%s %s==%s" % [mode,new_mode,editing,new_editing,selection,new_selection])
        return
    # print("not selection equal %s==%s %s==%s %s==%s" % [mode,new_mode,editing,new_editing,selection,new_selection])

    var expected_do_work = 0
    var expected_undo_work = 0
    var ur = _plugin.undo_redo
    ur.create_action("Ply Selection Changed")
    if cursor:
        ur.add_do_method(cursor.get_parent(), "remove_child", cursor)
        ur.add_undo_method(cursor.get_parent(), "add_child", cursor)
        ur.add_undo_reference(cursor)
        if handle:
            ur.add_do_method(cursor, "remove_child", handle)
            ur.add_undo_method(cursor, "add_child", handle)
            ur.add_undo_reference(handle)

    ur.add_do_property(self, "mode", new_mode)
    ur.add_undo_property(self, "mode", mode)
    if mode != new_mode:
        ur.add_do_method(_plugin.hotbar, "set_selection_mode", new_mode)
        ur.add_undo_method(_plugin.hotbar, "set_selection_mode", mode)

    ur.add_do_property(self, "editing", new_editing)
    ur.add_undo_property(self, "editing", editing)

    ur.add_do_property(self, "selection", new_selection)
    ur.add_undo_property(self, "selection", selection)

    var new_cursor = null
    var new_handle = null
    var root = _plugin.get_tree().get_edited_scene_root()
    if root and new_editing and new_selection.size() > 0 and new_mode != SelectionMode.MESH:
        # print("creating new handle: %s %s %s!=%s" % [new_editing, new_selection.size(), mode, SelectionMode.MESH])
        new_cursor = Spatial.new()
        new_handle = Handle.new(new_mode, new_editing, new_selection)
        var sum = Vector3.ZERO
        for idx in new_selection:
            match new_mode:
                SelectionMode.FACE:
                    sum += new_editing.ply_mesh.face_median(idx)
                SelectionMode.EDGE:
                    sum += new_editing.ply_mesh.edge_midpoint(idx)
                SelectionMode.VERTEX:
                    sum += new_editing.ply_mesh.vertexes[idx]
        ur.add_do_reference(new_cursor)
        ur.add_do_reference(new_handle)
        ur.add_do_method(root, "add_child", new_cursor)
        ur.add_undo_method(root, "remove_child", new_cursor)
        ur.add_do_property(new_cursor, "transform", new_editing.global_transform)
        ur.add_do_property(new_handle, "transform", Transform(Basis.IDENTITY, sum / new_selection.size()))
        ur.add_do_method(new_cursor, "add_child", new_handle)
        ur.add_undo_method(new_cursor, "remove_child", new_handle)
        ur.add_do_method(new_handle, "begin")
        ur.add_undo_method(new_handle, "begin")
    ur.add_do_property(self, "cursor", new_cursor)
    ur.add_undo_property(self, "cursor", cursor)
    ur.add_do_property(self, "handle", new_handle)
    ur.add_undo_property(self, "handle", handle)

    var new_safe_editing = new_editing
    if not new_safe_editing:
        new_safe_editing = false
    ur.add_do_method(self, "emit_signal", "selection_changed", new_mode, new_safe_editing, new_selection)
    var safe_editing = editing
    if not editing:
        safe_editing = false
    ur.add_undo_method(self, "emit_signal", "selection_changed", mode, safe_editing, selection)

    _editor_selection = _plugin.get_editor_interface().get_selection()

    if editing:
        expected_undo_work += 1
        ur.add_undo_method(_editor_selection, "clear")
        if mode == SelectionMode.MESH and selection.size() == 1 and selection[0] == _mesh_index_sentry:
            ur.add_undo_method(_editor_selection, "add_node", editing)
            ur.add_undo_method(_plugin.get_editor_interface(), "inspect_object", editing)
        elif handle:
            ur.add_undo_method(_editor_selection, "add_node", handle)
            ur.add_undo_method(_plugin.get_editor_interface(), "inspect_object", handle)

    if new_editing:
        expected_do_work += 1
        ur.add_do_method(_editor_selection, "clear")
        if new_mode == SelectionMode.MESH and new_selection.size() == 1 and new_selection[0] == _mesh_index_sentry: 
            ur.add_do_method(_editor_selection, "add_node", new_editing)
            ur.add_do_method(_plugin.get_editor_interface(), "inspect_object", new_editing)
        elif new_handle:
            ur.add_do_method(_editor_selection, "add_node", new_handle)
            ur.add_do_method(_plugin.get_editor_interface(), "inspect_object", new_handle)

    ur.add_do_property(self, "_in_work", expected_do_work)
    ur.add_undo_property(self, "_in_work", expected_undo_work)
    ur.commit_action()

func set_scene(scene):
    _set_selection(mode, null, [])

var _in_work = false setget _set_in_work

func _set_in_work(val):
    _in_work = val

func _on_selection_change():
    if _in_work:
        _in_work -= 1
        return
    _editor_selection = _plugin.get_editor_interface().get_selection()
    var selected = _editor_selection.get_selected_nodes()
    var new_selection = selection.duplicate()
    var new_editing = editing
    match selected.size():
        0:
            new_selection = []
        1:
            if selected[0] is Handle:
                return
            elif selected[0] is PlyNode:
                new_editing = selected[0]
                if mode == SelectionMode.MESH:
                    new_selection = [_mesh_index_sentry]
                else:
                    _editor_selection.remove_node(selected[0])
                    new_selection = []
            elif selected[0] is Face and mode == SelectionMode.FACE:
                new_selection = [selected[0].face_idx]
            elif selected[0] is Edge and mode == SelectionMode.EDGE:
                new_selection = [selected[0].edge_idx]
            elif selected[0] is Vertex and mode == SelectionMode.VERTEX:
                new_selection = [selected[0].vertex_idx]
            else:
                new_editing = null
                new_selection = []
        _:
            var ok = true
            for node in selected:
                if node is Handle:
                    continue
                var idx = -1
                match mode:
                    SelectionMode.MESH:
                        ok = ok and node is PlyNode
                        idx = _mesh_index_sentry
                    SelectionMode.FACE:
                        ok = ok and node is Face
                        idx = node.face_idx
                    SelectionMode.EDGE:
                        ok = ok and node is Edge
                        idx = node.edge_idx
                    SelectionMode.VERTEX:
                        ok = ok and node is Vertex
                        idx = node.vertex_idx
                if not ok:
                    break
                if handle and selection.has(idx):
                    new_selection.erase(idx)
                elif not selection.has(idx):
                    new_selection.push_back(idx)
            if not ok:
                new_editing = null
                new_selection = []

    _set_selection(mode, new_editing, new_selection)
            
func _on_selection_mode_change(m):
    if _in_work:
        _in_work -= 1
        return
    if m != mode:
        if m == SelectionMode.MESH:
            _set_selection(m, editing, [_mesh_index_sentry])
        else:
            _set_selection(m, editing, [])

func set_selection(nodes):
    _set_selection(mode, editing, nodes)