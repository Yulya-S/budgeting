extends Fragment

# Изменение значений в сцене
func set_values(data: Dictionary) -> void:
	super.set_values(data)
	_event_values(data, "__ET" + str(data.event_type))
	# Изменение видимости маркера завершения
	$Completed.modulate = color
	$Completed.visible = data.completed
	File.set_lang(self) # Изменение перевода
