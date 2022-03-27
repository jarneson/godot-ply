extends SceneTree

func _init():
	var v1 = PackedVector3Array()
	v1.push_back(Vector3.RIGHT)
	v1.push_back(Vector3.DOWN)
	v1.push_back(Vector3.LEFT)

	var v2 = v1.duplicate()
	v1[1] = Vector3.RIGHT

	print(v2)
