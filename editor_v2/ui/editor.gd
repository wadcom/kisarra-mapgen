extends MarginContainer

const EditorDocument = preload("res://editor_v2/document.gd")

var _document: EditorDocument


func _ready():
	_document = EditorDocument.new()
	%MapView.set_document(_document)
	%Terrain.set_document(_document)
	%Size.apply_recommended_size()

	# Auto-generate terrain on editor load so user sees terrain immediately
	_document.terrain_seed = randi_range(0, 1000)


func _on_size_changed(value: int):
	_document.size = value


func _on_player_count_changed(value: int):
	_document.player_count = value


func _on_quit_button_pressed():
	get_tree().quit()
