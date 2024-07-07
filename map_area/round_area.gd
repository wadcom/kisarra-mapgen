extends Sprite2D

const _globals = preload("res://globals.gd")


func set_radius(kms):
	var image_size = texture.get_size()

	var desired = Vector2.ONE * kms / _globals.CELL_SIDE_KMS * _globals.PIXELS_PER_CELL_SIDE

	scale = desired / image_size
