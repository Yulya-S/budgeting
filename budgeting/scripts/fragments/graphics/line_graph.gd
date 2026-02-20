extends Control
# Перечисение
enum GraphTypes {CANDLESTICK, REPORT, LOAN} # Виды графиков
# Экспортируемая переменная
@export var graph_type: GraphTypes = GraphTypes.CANDLESTICK
# Переменная
var values: Array = [] # Данные для отображения

# Отрисовка графика
func _draw() -> void:
	if len(values) == 0: return
	var max_value: float = [values.max(), values.min() * -1].max()
	match  graph_type:
		GraphTypes.CANDLESTICK: _candlestick(max_value, size.x / len(values))
		GraphTypes.REPORT: _report(max_value, (size.x - 25) / (len(values) - 1))
		GraphTypes.LOAN: _loan(max_value, (size.x - 25) / (len(values) - 1))

# Перезапуск отрисовки графика
func update_data(filter: Variant = {}) -> void:
	ColorScheme.repainting(self)
	var filter_data: Dictionary = Global.get_filter(filter)
	var data: Array = []
	var req_res: Array = _get_data(filter_data)
	if graph_type == GraphTypes.LOAN: for i in req_res: data.append(i.value)
	else:
		for i in range(Request.select_day_count(filter_data.date)): data.append(0.0)
		for i in req_res: data[int(i.day) - 1] = i.value
	values = _update_values(data, filter_data)
	queue_redraw()

# Получение списка данных
func _get_data(filter: Dictionary = {}) -> Array:
	if graph_type == GraphTypes.LOAN: return Request.select_loan_graphics(get_parent().idx)
	return Request.select_cash_flow_graphics(filter.where, filter.date)

# Получение значений для заполнения графика
func _update_values(data: Array, filter: Dictionary) -> Array:
	if graph_type == GraphTypes.LOAN:for i in range(1, len(data)): data[i] += data[i - 1]
	elif graph_type == GraphTypes.REPORT:
		var total: float = Request.select_past_funds_movements(filter.date)
		for i in range(len(data)):
			data[i] += total
			total = data[i]
	return data

# Виды графиков
# Общая часть для линейных графиков
func _line(idx: int, values_array: Array, max_value: float, x_step: float, height: float) -> void:
	var y1_size: float = (height * values_array[idx] / max_value) * -1 + int(height + 5)
	var y2_size: float = (height * values_array[idx + 1] / max_value) * -1 + int(height + 5)
	draw_line(Vector2(x_step * idx + 10., y1_size), Vector2(x_step * (idx + 1) + 10., y2_size), Color.FIREBRICK, 2)
	draw_circle(Vector2(x_step * idx + 10., y1_size), 3, Color.FIREBRICK)
	draw_circle(Vector2(x_step * (idx + 1) + 10., y2_size), 3, Color.FIREBRICK)

# Линейный для отчетов
func _report(max_value: float, x_step: float) -> void:
	if len(values) < 2: return # Отмена отрисовки при недостаточном количестве данных
	for i in range(len(values)-1): _line(i, values, max_value, x_step, 55.)

# Линейный для займов
func _loan(max_value: float, x_step: float) -> void:
	if len(values) < 2: return # Отмена отрисовки при недостаточном количестве данных
	for i in range(len(values)-1): _line(i, values, max_value, x_step, 119.)

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
