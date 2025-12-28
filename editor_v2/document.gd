extends RefCounted

const DimensionsLayer = preload("res://editor_v2/layers/dimensions.gd")

## The dimensions layer containing map size and player count.
var dimensions: DimensionsLayer


func _init():
	dimensions = DimensionsLayer.new()
