extends EditorNode3DGizmoPlugin

const PlyEditor = preload("res://addons/ply/nodes/ply.gd")

func _create_gizmo(n: Node3D):
	print("create_gizmo ", n)
	if n is PlyEditor:
		return EditorNode3DGizmo.new()
	return null