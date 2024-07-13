static func make_octave(octave_size):
	var grad = []
	grad.resize(octave_size + 1)

	for x in (octave_size + 1):
		grad[x] = []
		grad[x].resize(octave_size + 1)

		for y in (octave_size + 1):
			grad[x][y] = Vector2(randf_range(-1, 1), randf_range(-1, 1))

	return grad


static func get_height(octave, map_size, p: Vector2):
	var octave_size = octave.size() - 1

	var octave_p = p / map_size * octave_size

	var c = Vector2i(octave_p)
	var f = octave_p - Vector2(c)

	var top_left = _interpolate_height(octave, c, f)
	var top_right = _interpolate_height(octave, c + Vector2i(1, 0), f)
	var t = lerp(top_left, top_right, f.x)

	var bottom_left = _interpolate_height(octave, c + Vector2i(0, 1), f)
	var bottom_right = _interpolate_height(octave, c + Vector2i(1, 1), f)
	var b = lerp(bottom_left, bottom_right, f.x)

	return lerp(t, b, f.y)

	
static func _interpolate_height(octave, c: Vector2i, p: Vector2):
	var d = p - Vector2(c)
	return d.dot(octave[c.x][c.y])
