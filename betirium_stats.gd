extends PanelContainer


func update_stats():
	var stats = Model.calculate_bt_stats()
	%TotalLabel.text = "%d total" % [stats.total]
	%PerCellLabel.text = "%d per cell" % [stats.per_cell]
