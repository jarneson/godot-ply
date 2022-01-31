enum { UNKNOWN, LEFT, RIGHT }


static func reverse(dir) -> int:
	match dir:
		LEFT:
			return RIGHT
		RIGHT:
			return LEFT
	return UNKNOWN
