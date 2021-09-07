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

func _free_editor():
    if editor:
        if is_instance_valid(editor):
            editor.queue_free()
        editor = null

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

func set_scene(scene):
    _free_editor()
    _instantiate_editor()

func _on_selection_change(mode, editing, selection):
    _instantiate_editor()
    if editor:
        editor.is_visible = editing != null
        editor.edited_node = editing
        editor.mode = mode

func get_nodes_for_indexes(idxs):
    var out = []
    if not editor:
        return out
    for idx in idxs:
        out.push_back(editor.get_child(idx))
    return out