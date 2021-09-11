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
        return

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

func get_state():
    var editing_path = null
    var handle_path = null
    var cursor_path = null
    var root = _plugin.get_tree().get_edited_scene_root()
    if root:
        if editing:
            editing_path = root.get_path_to(editing)
        if handle:
            handle_path = root.get_path_to(handle)
        if cursor:
            cursor_path = root.get_path_to(cursor)

    var d = {
        "mode": mode,
        "editing": editing_path,
        "selection": selection,
        "handle": handle_path,
        "cursor": cursor_path
    }
    return d

func set_state(d):
    var root = _plugin.get_tree().get_edited_scene_root()
    if d and root:
        mode = d["mode"]
        selection = d["selection"]
        if root:
            if d["editing"]:
                editing = root.get_node_or_null(d["editing"])
            else:
                editing = null
            if d["handle"]:
                handle = root.get_node_or_null(d["handle"])
            else:
                handle = null
            if d["cursor"]:
                cursor = root.get_node_or_null(d["cursor"])
            else:
                cursor = null
    else:
        editing = null
        selection = []
        handle = null
        cursor = null

var _in_work = 0

func _enforce_selection():
    _editor_selection = _plugin.get_editor_interface().get_selection()
    var _selected_nodes = _editor_selection.get_selected_nodes()
    if mode == SelectionMode.MESH and editing:
        if _selected_nodes.size() == 1 and _selected_nodes[0] == editing:
            return
        _editor_selection.clear()
        _editor_selection.add_node(editing)
        return

    if handle and _plugin.hotbar.transform_toggle.pressed:
        if _selected_nodes.size() == 1 and _selected_nodes[0] == handle:
            return
        _editor_selection.clear()
        _editor_selection.add_node(handle)
        return


func _on_selection_change():
    if _in_work > 0:
        _in_work -= 1
        return
    var new_editing = editing

    _editor_selection = _plugin.get_editor_interface().get_selection()
    var _selected_nodes = _editor_selection.get_selected_nodes()

    match _selected_nodes.size():
        1:
            if _selected_nodes[0] is Handle:
                pass
            elif _selected_nodes[0] is PlyNode:
                new_editing = _selected_nodes[0]
            else:
                if not _plugin.hotbar.transform_toggle.pressed:
                    new_editing = null

    _set_selection(mode, new_editing, selection)
    _enforce_selection()
            
func _on_selection_mode_change(m):
    if _in_work > 0:
        _in_work -= 1
        return
    if m != mode:
        if m == SelectionMode.MESH:
            _set_selection(m, editing, [_mesh_index_sentry])
        else:
            _set_selection(m, editing, [])

func set_selection(nodes):
    _set_selection(mode, editing, nodes)

func toggle_selected(idx):
    var new_selection = selection.duplicate()
    if new_selection.has(idx):
        new_selection.erase(idx)
    else:
        new_selection.push_back(idx)
    _set_selection(mode, editing, new_selection)
    

func handle_click(camera, event):
    if event.pressed and editing and not _plugin.hotbar.transform_toggle.pressed:
        if mode == SelectionMode.MESH:
            return false
        var ray = camera.project_ray_normal(event.position) # todo: viewport scale
        var ray_pos = camera.project_ray_origin(event.position) # todo: viewport scale
        var root = _plugin.get_tree().get_edited_scene_root()
        var instances = VisualServer.instances_cull_ray(ray_pos, ray, root.get_world().scenario)
        var target = null
        match mode:
            SelectionMode.FACE:
                target = Face
            SelectionMode.EDGE:
                target = Edge
            SelectionMode.VERTEX:
                target = Vertex
        var hits = []
        for rid in instances:
            var inst = instance_from_id(rid)
            var parent = inst.get_parent()
            if parent and parent is target:
                hits.push_back(parent)
        
        var min_hit = null
        var min_dist = null
        for hit in hits:
            # TODO: apply transform first
            var dist = hit.intersect_ray_distance(ray_pos, ray)
            if dist and (not min_dist or dist < min_dist):
                min_dist = dist
                min_hit = hit

        if event.shift:
            if min_hit:
                toggle_selected(min_hit.get_idx())
        else:
            if min_hit:
                set_selection([min_hit.get_idx()])
            else:
                set_selection([])
        return true
    return false