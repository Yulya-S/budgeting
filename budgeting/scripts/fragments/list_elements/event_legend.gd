extends PageFragment

# Изменение значений
func set_values(data: Dictionary) -> void:
	super.set_values(data)
	_event_values(data, "-" if data.event_type == 1 else "+")
