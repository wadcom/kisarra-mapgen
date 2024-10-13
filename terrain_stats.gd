extends PanelContainer

func update_stats():
	var surface = Model.get_surface()

	var mountains = 0
	var sand = 0
	var total = 0
	for column in surface:
		for cell in column:
			total += 1

			if cell.type == Model.SurfaceType.SAND:
				sand += 1
			elif cell.type == Model.SurfaceType.MOUNTAINS:
				mountains += 1
			
	@warning_ignore("integer_division")
	%SandLabel.text = "Sand: %d%%" % [100 * sand / total]

	@warning_ignore("integer_division")
	%MountainsLabel.text = "Mountains: %d%%" % [100 * mountains / total]
