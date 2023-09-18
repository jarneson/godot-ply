static func tri_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	return (b - a).cross(c - a).normalized()

static func face_normal(verts) -> Vector3:
	var normal_sum = Vector3.ZERO
	for i in range(verts.size()):
		var left_idx = i - 1
		var right_idx = i + 1
		if left_idx == -1:
			left_idx = verts.size() - 1
		if right_idx == verts.size():
			right_idx = 0
		normal_sum = normal_sum + tri_normal(verts[i], verts[left_idx], verts[right_idx]).normalized()
	return (normal_sum / verts.size())

static func point_inside_frustum(pos: Vector3, planes: Array[Plane]) -> bool:
	for p in planes:
		var dir = pos - p.project(pos)
		if dir.dot(p.normal) > 0:
			return false
	return true
