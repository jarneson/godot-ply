static func wing_clip_indices(verts: PackedVector3Array) -> PackedInt32Array:
	var out = PackedInt32Array()
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
		out.push_back(remaining[prev])
		out.push_back(remaining[curr])
		out.push_back(remaining[next])
		remaining.remove_at(min_idx)
	if remaining.size() == 3:
		out.push_back(remaining[0])
		out.push_back(remaining[1])
		out.push_back(remaining[2])

	return out

static func wing_clip(verts: PackedVector3Array) -> PackedVector3Array:
	var indices = wing_clip_indices(verts)
	var out = PackedVector3Array()
	out.resize(indices.size())
	for i in range(indices.size()):
		out[i] = verts[indices[i]]
	return out
