extends ColorRect

const _globals = preload("res://globals.gd")


func _ready():
	size = Vector2.ONE * (_globals.PIXELS_PER_CELL_SIDE - 1)
