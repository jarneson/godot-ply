tool
extends Object

const Editor = preload("../gui/editor.gd")

var _plugin

func _init(p: EditorPlugin):
    _plugin = p

var editor = null

func startup():
    var _err = _plugin.selector.connect("selection_changed", self, "_on_selection_change")

func teardown():
    var _err = _plugin.selector.disconnect("selection_changed", self, "_on_selection_change")

func _instantiate_editor():
    if editor:
        return
    var root = _plugin.get_tree().get_edited_scene_root()
    if root:
        editor = Editor.new()
        editor.name = "__ply__editor"
        editor.visible = false
        editor.plugin = _plugin
        root.add_child(editor)

func get_state():
    var path = null
    var root = _plugin.get_tree().get_edited_scene_root()
    if root and editor:
        path = root.get_path_to(editor)
    return {
        "editor": path
    }

func set_state(d):
    var root = _plugin.get_tree().get_edited_scene_root()
    if d and d["editor"] and root:
        editor = root.get_node_or_null(d["editor"])
    else:
        editor = null

func _on_selection_change(mode, editing, _selection):
    _instantiate_editor()
    if editor:
        editor.is_visible = editing && true
        if editing:
            editor.edited_node = editing
        else:
            editor.edited_node = null
        editor.mode = mode

func get_nodes_for_indexes(idxs):
    var out = []
    if not editor:
        return out
    for idx in idxs:
        out.push_back(editor.get_child(idx))
    return out