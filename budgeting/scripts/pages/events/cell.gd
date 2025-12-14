extends ColorRect

var lines: Array = []

# Запуск изменения цвета ячейки
func _ready() -> void: ColorScheme.repainting(self)

# Изменение номера дня
func set_values(idx: int, current_month: bool, day_count: int) -> void:
	if idx >= 0 and idx < day_count: $Label.set_text(str(idx+1))
	else: color = ColorScheme.get_color(6, 6, ColorScheme.system_gradient)
	if not current_month or Global.date.day > idx + 1 or day_count <= idx:
		$Completed.visible = true
		$Completed.modulate = ColorScheme.get_color(95, 100)
	elif Global.date.day == idx + 1: color = ColorScheme.get_color(3, 6, ColorScheme.system_gradient)
	
	
	#Number.set_text(str(index))
	#if today: Background.color = Color.html("#f7cdcd")
	#else: Background.color = Color.html("#ffffff")
	#Completed.visible = complete
	#for i in range(len(get_parent().get_parent().lines)):
		#if int(get_parent().get_parent().lines[0].date.split("-")[-1]) != index: break
		#Objects.add_child(event_path.instantiate())
		#Objects.get_child(-1).set_object(get_parent().get_parent().lines[0], get_parent().get_parent().events_color)
		#get_parent().get_parent().lines.pop_front()

func add_event(): $Marker.visible = true
	

## Выделение событий цветом
#func mark_event(id: int) -> void: for i in Objects.get_children(): if i.id == id: i.color = Color.AQUAMARINE
#
## Снятие выделения с события
#func deselect_event(id: int, color: Color) -> void: for i in Objects.get_children(): if i.id == id: i.color = color
