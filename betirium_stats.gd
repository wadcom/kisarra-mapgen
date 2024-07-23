extends PanelContainer


func update_stats(bt_density):
	var total = 0
	for b in bt_density:
		total += b

	%TotalLabel.text = "%d total" % [total]
	%PerCellLabel.text = "%d per cell" % [total / bt_density.size()]
