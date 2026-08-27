extends "res://editor/layers/mountains.gd"
## Terrain built from ASCII rows, so a test can state an obstacle directly.
##
## A "#" is a mountain and any other character is sand. Rows run top to bottom,
## so rows[y][x] holds the cell at (x, y). Maps are square, so the number of
## rows gives the map size.
##
## Extends the real terrain layer and overrides only the cell query, so it
## passes anywhere a terrain layer is expected. The real layer builds itself
## from Perlin noise and offers no way to set one cell.
##
## ## Public API
##
## Methods: get_terrain_at(), size()

var _rows: Array


func _init(rows: Array) -> void:
	_rows = rows


func get_terrain_at(x: int, y: int) -> TerrainType:
	if _rows[y][x] == "#":
		return TerrainType.MOUNTAIN
	return TerrainType.SAND


## Returns the map size in cells along one side.
func size() -> int:
	return _rows.size()
