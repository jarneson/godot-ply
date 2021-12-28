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
    _plugin.toolbar.toolbar.connect("selection_mode_changed", self, "_on_selection_mode_change")
    _plugin.toolbar.toolbar.connect("transform_mode_changed", self, "_on_transform_mode_change")

func teardown():
    _editor_selection.disconnect("selection_changed", self, "_on_selection_change")
    _plugin.toolbar.toolbar.disconnect("selection_mode_changed", self, "_on_selection_mode_change")
    _plugin.toolbar.toolbar.disconnect("transform_mode_changed", self, "_on_transform_mode_change")
    show_spatial_gizmo()

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
        ur.add_do_method(_plugin.toolbar.toolbar, "set_selection_mode", new_mode)
        ur.add_undo_method(_plugin.toolbar.toolbar, "set_selection_mode", mode)

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
        ur.add_do_reference(new_cursor)
        ur.add_do_reference(new_handle)
        ur.add_do_method(root, "add_child", new_cursor)
        ur.add_undo_method(root, "remove_child", new_cursor)
        ur.add_do_property(new_cursor, "transform", new_editing.global_transform)
        ur.add_do_method(new_cursor, "add_child", new_handle)
        ur.add_undo_method(new_cursor, "remove_child", new_handle)
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

    ur.add_do_method(self, "_enforce_selection")
    ur.add_undo_method(self, "_enforce_selection")

    ur.add_do_property(self, "_in_work", expected_do_work)
    ur.add_undo_property(self, "_in_work", expected_undo_work)
    ur.commit_action()

const _scene_sentry_node_name = "__ply__scene_sentry"
func _scene_startup_check(root):
    if root.get_node_or_null(_scene_sentry_node_name):
        return true
    var s = Node.new()
    s.name = _scene_sentry_node_name
    root.add_child(s)
    return false

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
    _enforce_selection()
    return d

func set_state(d):
    var root = _plugin.get_tree().get_edited_scene_root()
    if d and root and _scene_startup_check(root):
        mode = d["mode"]
        selection = d["selection"]
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
    _enforce_selection()

var _in_work = 0

func _enforce_selection():
    _editor_selection = _plugin.get_editor_interface().get_selection()
    var _selected_nodes = _editor_selection.get_selected_nodes()

    while true:
        if mode == SelectionMode.MESH and editing:
            if _selected_nodes.size() == 1 and _selected_nodes[0] == editing:
                break
            _editor_selection.clear()
            _editor_selection.add_node(editing)
            _plugin.get_editor_interface().inspect_object(editing)
            break

        if editing and handle:
            if _selected_nodes.size() == 1 and _selected_nodes[0] == handle:
                break
            _editor_selection.clear()
            _editor_selection.add_node(handle)
            _plugin.get_editor_interface().inspect_object(handle)
            break
        break
    
    if is_selecting():
        hide_spatial_gizmo()
    else:
        show_spatial_gizmo()

    _plugin.toolbar.toolbar.set_selection_mode(mode)

func _on_selection_change():
    if _in_work > 0:
        _in_work -= 1
        return
    var new_editing = editing

    _editor_selection = _plugin.get_editor_interface().get_selection()
    var _selected_nodes = _editor_selection.get_selected_nodes()

    match _selected_nodes.size():
        0:
            pass
        1:
            if _selected_nodes[0] is Handle:
                pass
            elif _selected_nodes[0] is PlyNode:
                new_editing = _selected_nodes[0]
            else:
                if not _plugin.toolbar.in_transform_mode():
                    new_editing = null
        _:
            for n in _selected_nodes:
                if n is Handle:
                    continue
                if not n is PlyNode:
                    new_editing = null
                    break
                new_editing = n 

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
    
func is_selecting():
    return editing and not _plugin.toolbar.in_transform_mode() and mode != SelectionMode.MESH

func handle_click(camera, event):
    if event.pressed and is_selecting() and !_plugin.ignore_inputs:
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
        var ai = editing.global_transform.affine_inverse()
        for hit in hits:
            var dist = hit.intersect_ray_distance(ai.xform(ray_pos), ai.basis.xform(ray).normalized())
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

var _spatial_gizmo_hidden = false
var _user_gizmo_size = null
func hide_spatial_gizmo():
    if _spatial_gizmo_hidden:
        return

    var editor_settings = _plugin.get_editor_interface().get_editor_settings()
    _user_gizmo_size = editor_settings.get_setting("editors/3d/manipulator_gizmo_size")
    editor_settings.set_setting("editors/3d/manipulator_gizmo_size", 0)
    _spatial_gizmo_hidden = true

func show_spatial_gizmo():
    if not _spatial_gizmo_hidden:
        return

    var editor_settings = _plugin.get_editor_interface().get_editor_settings()
    editor_settings.set_setting("editors/3d/manipulator_gizmo_size", _user_gizmo_size)
    _spatial_gizmo_hidden = false

func _on_transform_mode_change(on):
    if is_selecting():
        hide_spatial_gizmo()
    else:
        show_spatial_gizmo()