extends MarginContainer

const EditorDocument = preload("res://editor_v2/document.gd")

var document: EditorDocument


func _ready():
	document = EditorDocument.new()
	%MapView.document = document
	%DimensionsPanel.apply_recommended_size()


func _on_size_changed(value: int):
	document.dimensions.size = value


func _on_player_count_changed(value: int):
	document.dimensions.player_count = value


func _on_quit_button_pressed():
	get_tree().quit()
