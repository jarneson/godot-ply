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
    selected_idxs = _selection
    

var previous_xform = Transform.IDENTITY
export var selected_idxs = []

var _has_begun = false
func begin():
    previous_xform = transform
    set_notify_transform(true)

func stop():
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