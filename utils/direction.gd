enum { UNKNOWN, LEFT, RIGHT }

static func invert(dir):
    match dir:
        LEFT:
            return RIGHT
        RIGHT:
            return LEFT