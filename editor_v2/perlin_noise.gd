## Perlin noise terrain generation.
##
## Generates height maps for procedural terrain using multi-octave Perlin noise.
##
## Typical usage:
##   var rng := RandomNumberGenerator.new()
##   rng.seed = my_seed
##   var config := [{size = 8, weight = 0.5}, {size = 1, weight = 0.5}]
##   var height_map := PerlinNoise.generate_height_map(config, map_size, rng)


## Generates a 2D height map by sampling at each cell center.
## Config is an array of {size: int, weight: float}. Weights are normalized internally.
## Returns height_map[x][y] with values typically in range [-1, 1].
static func generate_height_map(config: Array[Dictionary], map_size: int, rng: RandomNumberGenerator) -> Array:
	var octaves := _make_octaves(config, rng)
	var height_map: Array = []
	height_map.resize(map_size)

	for x in map_size:
		height_map[x] = []
		height_map[x].resize(map_size)
		for y in map_size:
			var pos := Vector2(x + 0.5, y + 0.5)
			height_map[x][y] = _sample_height(octaves, map_size, pos)

	return height_map


static func _make_octaves(config: Array[Dictionary], rng: RandomNumberGenerator) -> Array:
	var total_weight := 0.0
	for entry in config:
		total_weight += entry.weight

	var octaves: Array = []
	for entry in config:
		var normalized_weight: float = entry.weight / total_weight if total_weight > 0 else 0.0
		octaves.append({
			grid = _make_octave(entry.size, rng),
			weight = normalized_weight,
		})
	return octaves


static func _sample_height(octaves: Array, map_size: int, p: Vector2) -> float:
	var combined := 0.0
	for octave in octaves:
		var h := _get_height(octave.grid, map_size, p)
		combined += h * octave.weight
	return combined


## Creates a single octave grid of the given size using the provided RNG.
static func _make_octave(octave_size: int, rng: RandomNumberGenerator) -> Array:
	var grad := []
	grad.resize(octave_size + 1)

	for x in (octave_size + 1):
		grad[x] = []
		grad[x].resize(octave_size + 1)

		for y in (octave_size + 1):
			grad[x][y] = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))

	return grad


## Samples height at position p within a map of given size (single octave).
static func _get_height(octave: Array, map_size: int, p: Vector2) -> float:
	var octave_size := octave.size() - 1

	var octave_p := p / map_size * octave_size

	var c := Vector2i(octave_p)
	var f := octave_p - Vector2(c)

	var top_left := _interpolate_height(octave, c, f)
	var top_right := _interpolate_height(octave, c + Vector2i(1, 0), f)
	var t := lerpf(top_left, top_right, f.x)

	var bottom_left := _interpolate_height(octave, c + Vector2i(0, 1), f)
	var bottom_right := _interpolate_height(octave, c + Vector2i(1, 1), f)
	var b := lerpf(bottom_left, bottom_right, f.x)

	return lerpf(t, b, f.y)


static func _interpolate_height(octave: Array, c: Vector2i, p: Vector2) -> float:
	var d := p - Vector2(c)
	return d.dot(octave[c.x][c.y])
