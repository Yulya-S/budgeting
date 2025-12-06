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
	# Здесь добавить код изменения при недостатке средств к моменту события "расхода"
	File.set_lang(self) # Изменение перевода
	
