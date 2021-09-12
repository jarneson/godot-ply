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
    _editing.ply_mesh.connect("mesh_updated", self, "_on_mesh_updated")
    _move_to_median()

var previous_xform = Transform.IDENTITY
export var selected_idxs = []

func _ready():
    previous_xform = transform
    set_notify_transform(true)

func _notification(what):
    if what == Spatial.NOTIFICATION_TRANSFORM_CHANGED:
        if transform == previous_xform:
            return
        match _mode:
            SelectionMode.FACE:
                _editing.ply_mesh.transform_faces(selected_idxs, previous_xform, transform)
            SelectionMode.EDGE:
                _editing.ply_mesh.transform_edges(selected_idxs, previous_xform, transform)
            SelectionMode.VERTEX:
                _editing.ply_mesh.transform_vertexes(selected_idxs, previous_xform, transform)
        previous_xform = transform

func _move_to_median():
    var sum = Vector3.ZERO
    for idx in _selection:
        match _mode:
            SelectionMode.FACE:
                sum += _editing.ply_mesh.face_median(idx)
            SelectionMode.EDGE:
                sum += _editing.ply_mesh.edge_midpoint(idx)
            SelectionMode.VERTEX:
                sum += _editing.ply_mesh.vertexes[idx]
    previous_xform.origin = sum / _selection.size()
    self.transform.origin = previous_xform.origin

func _on_mesh_updated():
    if is_inside_tree():
        _move_to_median()