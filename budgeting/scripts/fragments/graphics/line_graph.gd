extends Control
# Переменная
var values: Array = [] # Данные для отображения

# Отрисовка графика
func _draw() -> void:
	var max_value: float = [values.max(), values.min() * -1].max()
	var step: float = size.x / len(values)
	if name == "DailyTransactions": _candlestick(max_value, step)
	else: _line(max_value, step)

# Перезапуск отрисовки графика
func update_data(filter: Variant = {}) -> void:
	ColorScheme.repainting(self)
	var filter_data = Global.get_filter(filter)
	var data: Array = []
	var req_res: Array = Request.select_cash_flow_graphics(filter_data.where, filter_data.date)
	for i in range(Request.select_day_count(filter_data.date)): data.append(0.0)
	for i in req_res: data[int(i.day) - 1] = i.value
	values = _update_values(data, filter_data)
	queue_redraw()

# Получение значений для заполнения графика
func _update_values(data: Array, filter: Dictionary) -> Array:
	if name == "DailyTransactions": return data
	else:
		var total: float = Request.select_past_funds_movements(filter.date)
		for i in range(len(data)):
			data[i] += total
			total = data[i]
		return data

# Виды графиков
# Линейный
func _line(max_value: float, x_step: float) -> void:
	if len(values) < 2: return # Отмена отрисовки при недостаточном количестве данных
	for i in range(0, len(values)-1):
		var y1_size: float = (55. * values[i] / max_value) * -1 + 60
		var y2_size: float = (55. * values[i + 1] / max_value) * -1 + 60
		draw_line(Vector2(x_step * i + 10., y1_size), Vector2(x_step * (i + 1) + 10., y2_size), Color.FIREBRICK, 2)
		draw_circle(Vector2(x_step * i + 10., y1_size), 3, Color.FIREBRICK)
		draw_circle(Vector2(x_step * (i + 1) + 10., y2_size), 3, Color.FIREBRICK)

# Свечной
func _candlestick(max_value: float, x_step: float) -> void:
	for i in range(len(values)):
		draw_string(ThemeDB.fallback_font, Vector2(x_step*i, 120), str(int(i)+1), HORIZONTAL_ALIGNMENT_CENTER, x_step, 9, ColorScheme.get_sys_color(0, 1))
		if values[i] == 0: continue
		var y_size: float = 50. * abs(values[i]) / abs(max_value)
		var data: Array = [ColorScheme.get_color(0, 1, ColorScheme.scales_gradient), y_size + 2, 90.]
		if values[i] < 0: data = [ColorScheme.get_color(1, 1, ColorScheme.scales_gradient), 0., 30.]
		draw_rect(Rect2(Vector2(x_step * i - 2, 60 - data[1] - 2), Vector2(x_step + 4, y_size + 4)), ColorScheme.get_sys_color(0, 1))
		draw_rect(Rect2(Vector2(x_step * i, 60 - data[1]), Vector2(x_step, y_size)), data[0])
		draw_string(ThemeDB.fallback_font, Vector2(x_step * i, data[2]), str(values[i]), HORIZONTAL_ALIGNMENT_CENTER, x_step, 9, ColorScheme.get_sys_color(0, 1))
