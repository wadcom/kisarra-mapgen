extends RefCounted

signal changed

## Maps are always square.
var size := 22:
	set(value):
		size = clampi(value, 9, 120)
		changed.emit()

var player_count := 2:
	set(value):
		player_count = clampi(value, 2, 9)
		changed.emit()
