extends ColorRect
# Переменные
var id = null # Индекс объекта
var state: Global.MouseOver = Global.MouseOver.NORMAL  # Текущее состояние объекта

# Применение текстового значения и индекса целевого объекта
func set_values(data: Dictionary) -> void:
	id = data.event_id
	tooltip_text = data.title
	var second_color = data.marker
	if data.event_type == 1 and not data.completed and data.profit_accounting < 0: second_color = Color.FIREBRICK
	$ColorEvent.texture = GradientTexture2D.new()
	$ColorEvent.texture.gradient = Gradient.new()
	$ColorEvent.texture.gradient.colors = PackedColorArray([data.marker, data.marker, second_color])
	$ColorEvent.texture.gradient.offsets = PackedFloat32Array([0., 0.7, 1.])

# Обработка нажатия клавиш мыши
#func _input(event: InputEvent) -> void:
	#if state == Global.MouseOver.NORMAL or not id: return
	#if event.is_action("click") and event.is_pressed():
		#Global.emit_signal("open_window", Global.Pages.EVENT, id, Global.Dirs.WINDOWS)
#
## Обработка наведения мыши на контейнер
#func _on_mouse_entered() -> void: state = Global.MouseOver.HOVER
#
#func _on_mouse_exited() -> void: state = Global.MouseOver.NORMAL


func _on_mouse_entered() -> void:
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	pass # Replace with function body.
