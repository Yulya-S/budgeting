extends ColorRect
# Переменные
var id = null # Индекс объекта
var state: Global.MouseOver = Global.MouseOver.NORMAL  # Текущее состояние объекта

# Применение текстового значения и индекса целевого объекта
func set_object(data: Dictionary, colors: Dictionary) -> void:
	id = data.event_id
	tooltip_text = data.title
	color = colors[data.event_id]

# Обработка нажатия клавиш мыши
func _input(event: InputEvent) -> void:
	if state == Global.MouseOver.NORMAL or not id: return
	if event.is_action("click") and event.is_pressed():
		Global.emit_signal("open_window", Global.Pages.EVENT, id, Global.Dirs.WINDOWS)

# Обработка наведения мыши на контейнер
func _on_mouse_entered() -> void: state = Global.MouseOver.HOVER

func _on_mouse_exited() -> void: state = Global.MouseOver.NORMAL
