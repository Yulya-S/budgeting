extends ColorRect
# Параметр
var values: Array = [] # Данные для отображения

# Отрисовка графика
func _draw() -> void:
	if len(values) < 2: return # Отмена отрисовки при недостаточном количестве данных
	var max_value: float = values.max()
	var x_step: float = size.x / len(values)
	for i in range(0, len(values)-1):
		var y1_size: float = (55. * values[i] / max_value) * -1 + 60
		var y2_size: float = (55. * values[i + 1] / max_value) * -1 + 60
		draw_line(Vector2(x_step * i + 10., y1_size), Vector2(x_step * (i + 1) + 10., y2_size), Color.FIREBRICK, 2)
		draw_circle(Vector2(x_step * i + 10., y1_size), 3, Color.FIREBRICK)
		draw_circle(Vector2(x_step * (i + 1) + 10., y2_size), 3, Color.FIREBRICK)

# Перезапуск отрисовки графика
func update_data(filter: Variant = {}) -> void:
	ColorScheme.repainting(self) # Изменение цветовой темы
	var filter_data: Dictionary = Global.get_filter(filter)
	values = []
	var data: Array = Request.select_cash_flow_graphics(filter_data.where, filter_data.date)
	var total: float = Request.select_past_funds_movements(filter_data.date)
	for i in range(Request.select_day_count(filter_data.date)): values.append( 0.0)
	for i in data: values[int(i.day) - 1] = i.value
	for i in range(len(values)):
		values[i] += total
		total = values[i]
	queue_redraw()
