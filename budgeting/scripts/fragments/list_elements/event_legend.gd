extends PageFragment
# Подключение путей к объектам в сцене
@onready var Marker = $Marker
@onready var Title = $Title
@onready var ParentPage = $"../../../"

# Изменение значений
func set_values(data: Dictionary) -> void:
	super.set_values(data)
	$Marker.visible = true
	$Marker.color = ColorScheme.get_color(get_parent().get_child_count()-1, len(ParentPage.legend_objects)+get_parent().get_child_count()-1)

## Обработка наведения мыши на контейнер
#func _on_mouse_entered() -> void: if Title.id: Calendar.mark_event(Title.id)
#
#func _on_mouse_exited() -> void: if Title.id: Calendar.deselect_event(Title.id, Marker.color)
