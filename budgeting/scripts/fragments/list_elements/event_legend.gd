extends PageFragment
# Подключение путей к объектам в сцене
@onready var Marker = $Marker
@onready var Title = $Title
@onready var Calendar = $"../../../"

# Изменение значений
func set_values(data: Dictionary) -> void:
	super.set_values(data)
	Marker.visible = true
	Marker.color = data.color

# Обработка наведения мыши на контейнер
func _on_mouse_entered() -> void: if Title.id: Calendar.mark_event(Title.id)

func _on_mouse_exited() -> void: if Title.id: Calendar.deselect_event(Title.id, Marker.color)
