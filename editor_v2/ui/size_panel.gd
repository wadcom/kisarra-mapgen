extends VBoxContainer

const DesignTokens = preload("res://editor_v2/ui/design_tokens.gd")

signal size_changed(value: int)
signal player_count_changed(value: int)

var _cells_per_player := 250
var _player_count := 2


func _ready():
	%RecommendedLabel.add_theme_color_override("font_color", DesignTokens.COLOR_MUTED)
	%CellsPerPlayerLabel.text = str(_cells_per_player)
	_update_recommended_size()


func apply_recommended_size():
	%SizeSpinBox.value = _calculate_recommended_size()


func _calculate_recommended_size() -> int:
	return ceili(sqrt(_player_count * _cells_per_player))


func _update_recommended_size():
	var recommended := _calculate_recommended_size()
	var current_size := int(%SizeSpinBox.value)
	var differs := recommended != current_size
	%RecommendedSizeLabel.text = str(recommended)
	%RecommendedSizeLabel.add_theme_color_override(
		"font_color", DesignTokens.COLOR_ACCENT if differs else DesignTokens.COLOR_MUTED
	)
	%UseRecommendedButton.disabled = not differs


func _on_cells_per_player_value_changed(value: float):
	_cells_per_player = int(value)
	%CellsPerPlayerLabel.text = str(_cells_per_player)
	_update_recommended_size()


func _on_player_count_value_changed(value: float):
	_player_count = int(value)
	_update_recommended_size()
	player_count_changed.emit(_player_count)


func _on_size_value_changed(value: float):
	_update_recommended_size()
	size_changed.emit(int(value))
