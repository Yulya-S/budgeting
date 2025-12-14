extends PageFragment

# Изменение значений
func set_values(data: Dictionary) -> void:
	super.set_values(data)
	$EventType.visible = data.event_type > 0
	$EventType.text = "-" if data.event_type == 1 else "+"
	$EventType/Value.text = str(data.value)
	# Отображение информации о нехватке средств для "расходных" событий
	if not data.completed and data.event_type == 1 and data.profit_accounting < 0: $EventType/Label.visible = true
