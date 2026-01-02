extends PageFragment

# Изменение значений в сцене
func set_values(data: Dictionary) -> void:
	super.set_values(data)
	$EventType.visible = data.event_type > 0
	$EventType.text = "__ET" + str(data.event_type)
	$EventType/Value.text = str(data.value)
	# Изменение видимости маркера завершения
	$Completed.modulate = color
	$Completed.visible = data.completed
	# Отображение информации о нехватке средств для "расходных" событий
	if not data.completed and data.event_type == 1 and data.profit_accounting < 0: $EventType/Label.visible = true
	if $Title.get_line_count() > 1: $Title.tooltip_text = $Title.text # Выход текста за границу контейнера
	File.set_lang(self) # Изменение перевода
