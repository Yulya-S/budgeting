extends ColorRect
# Переменные
var id: int = 0 # Индекс дня
var state: Global.MouseOver = Global.MouseOver.NORMAL # Текущее состояние объекта

# Изменение номера дня
func set_object(obj_id: int): id = obj_id

# Обработка нажатия клавиш мыши 
func _input(event: InputEvent) -> void:
	if id == 0: return
	if state == Global.MouseOver.NORMAL: return
	if event.is_action("click") and event.is_pressed():	get_parent().get_parent().update_day(id)

# Обработка наведения мыши на контейнер
func _on_color_rect_mouse_entered() -> void: state = Global.MouseOver.HOVER

func _on_color_rect_mouse_exited() -> void: state = Global.MouseOver.NORMAL
