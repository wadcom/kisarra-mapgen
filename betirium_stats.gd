extends PanelContainer


func update_stats():
	var bt_density = Model.get_betirium_density()

	var cells = 0
	var total = 0

	for column in bt_density:
		for b in column:
			cells += 1
			total += b

	%TotalLabel.text = "%d total" % [total]
	%PerCellLabel.text = "%d per cell" % [total / cells]
