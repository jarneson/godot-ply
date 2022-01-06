static func geometric_median(vertices: Array, iters: int = 5) -> Vector3:
	var start = Vector3.ZERO
	if vertices.size() == 0:
		return start
	for v in vertices:
		start = start + v
	start = start / vertices.size()

	for i in range(iters):
		pass  # TODO: weiszfeld's

	return start
