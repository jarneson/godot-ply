tool
extends Spatial

const SelectionMode = preload("../utils/selection_mode.gd")

var _mode = null
var _editing = null
var _selection = null

func _init(mode, editing, selection):
    _mode = mode
    _editing = editing
    _selection = selection

var previous_xform = Transform.IDENTITY
export var selected_idxs = []

func _enter_tree() -> void:
    previous_xform = transform
    set_notify_transform(true)
    _set_selected_idxs()

func _exit_tree() -> void:
    set_notify_transform(false)

func _notification(what):
    if what == Spatial.NOTIFICATION_TRANSFORM_CHANGED:
        match _mode:
            SelectionMode.FACE:
                _editing.ply_mesh.transform_faces(selected_idxs, previous_xform, transform)
            SelectionMode.EDGE:
                _editing.ply_mesh.transform_edges(selected_idxs, previous_xform, transform)
            SelectionMode.VERTEX:
                _editing.ply_mesh.transform_vertexes(selected_idxs, previous_xform, transform)
        previous_xform = transform

func _set_selected_idxs():
    self.selected_idxs = []
    for n in _selection:
        if not n:
            continue
        match _mode:
            SelectionMode.FACE:
                self.selected_idxs.push_back(n.face_idx)
            SelectionMode.EDGE:
                self.selected_idxs.push_back(n.edge_idx)
            SelectionMode.VERTEX:
                self.selected_idxs.push_back(n.vertex_idx)