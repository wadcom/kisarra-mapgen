extends Node2D

const _globals = preload("res://globals.gd")

func setup(p: Vector2i):
	position = p * _globals.PIXELS_PER_CELL_SIDE


func _ready() -> void:
	var size = Vector2(_globals.PIXELS_PER_CELL_SIDE, _globals.PIXELS_PER_CELL_SIDE)
	$ColorRect.size = size
	$LockSprite.position = size / 2.0


func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if $LockSprite.visible:
				$LockSprite.visible = false
			else:
				$LockSprite.visible = true
