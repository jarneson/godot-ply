enum { UNKNOWN, LEFT, RIGHT }


static func invert(dir) -> int:
	match dir:
		LEFT:
			return RIGHT
		RIGHT:
			return LEFT
	return -1
