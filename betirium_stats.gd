extends PanelContainer


func update_stats():
	var bt_density = Model.get_betirium_density()
	var surface = Model.get_surface()

	assert(bt_density.size() == surface.size())

	var cells = 0
	var total = 0

	for x in bt_density.size():
		for y in bt_density[x].size():
			cells += 1

			if surface[x][y].type == Model.SurfaceType.SAND:
				total += bt_density[x][y]

	%TotalLabel.text = "%d total" % [total]
	%PerCellLabel.text = "%d per cell" % [total / cells]
