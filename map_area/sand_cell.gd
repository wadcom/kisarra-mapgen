extends ColorRect

@export var full_betirium_color: Color
@export var no_betirium_color: Color

const _globals = preload("res://globals.gd")


func _ready():
	size = Vector2.ONE * (_globals.PIXELS_PER_CELL_SIDE - 1)


func set_bt_density(bt):
	color = no_betirium_color.lerp(full_betirium_color, clamp(bt, 0, 100) / 100.0)
