static func wing_clip(verts: Array) -> Array:
	var out = []
	var remaining = []
	remaining.resize(verts.size())
	for i in range(verts.size()):
		remaining[i] = i

	while remaining.size() > 3:
		var min_idx = null
		var min_dot = null
		for curr in range(remaining.size()):
			var prev = curr - 1
			if prev < 0:
				prev = remaining.size() - 1
			var next = curr + 1
			if next >= remaining.size():
				next = 0

			var va = verts[remaining[prev]]
			var vb = verts[remaining[curr]]
			var vc = verts[remaining[next]]

			var ab = vb - va
			var bc = vc - vb

			var d = ab.dot(bc)

			if not min_dot or d < min_dot:
				min_idx = curr
				min_dot = d

		var curr = min_idx
		var prev = curr - 1
		if prev < 0:
			prev = remaining.size() - 1
		var next = curr + 1
		if next >= remaining.size():
			next = 0
		out.push_back([remaining[prev], remaining[curr], remaining[next]])
		remaining.remove_at(min_idx)
	if remaining.size() == 3:
		out.push_back([remaining[0], remaining[1], remaining[2]])

	return out
