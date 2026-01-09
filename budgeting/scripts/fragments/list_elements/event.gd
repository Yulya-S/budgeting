extends Fragment
# Подключение пути к объекту в сцене
@onready var Completed = $Completed

# Изменение значений
func set_values(data: Dictionary) -> void:
	_event_values(data, "__ET" + str(data.event_type))
	super.set_values(data)
	# Изменение видимости маркера завершения
	Completed.modulate = color
	Completed.visible = data.completed
	Completed.size = custom_minimum_size
