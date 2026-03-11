extends Control
# Перечисление
enum GraphTypes {CANDLESTICK, REPORT, LOAN} # Виды графиков
# Экспортируемая переменная
@export var graph_type: GraphTypes = GraphTypes.CANDLESTICK # Выбранный вид графика
# Переменная
var values: Array = [] # Данные для отображения

# Отрисовка графика
func _draw() -> void:
	if len(values) == 0: return
	var max_value: float = [values.max(), values.min() * -1].max()
	match graph_type:
		GraphTypes.REPORT: _report(max_value)
		GraphTypes.LOAN: _loan(max_value)
		GraphTypes.CANDLESTICK: _candlestick(max_value)

# Проверка что типом графика являеся - займ
func _is_loan() -> bool: return graph_type == GraphTypes.LOAN

# Перезапуск отрисовки графика
func update_data(filter: Variant = {}) -> void:
	ColorScheme.repainting(self)
	var filter_data: Dictionary = Global.get_filter(filter)
	var data: Array = []
	var req_res: Array = _get_data(filter_data)
	if _is_loan(): for i in req_res: data.append(i.value)
	else:
		for i in range(Request.select_day_count(filter_data.date)): data.append(0.0)
		for i in req_res: data[int(i.day) - 1] = i.value
	values = _update_values(data, filter_data)
	queue_redraw()

# Получение списка данных
func _get_data(filter: Dictionary = {}) -> Array:
	if _is_loan(): return Request.select_loan_graphics(get_parent().idx)
	return Request.select_cash_flow_graphics(filter.where, filter.date)

# Получение значений для заполнения графика
func _update_values(data: Array, filter: Dictionary) -> Array:
	match graph_type:
		GraphTypes.LOAN: for i in range(1, len(data)): data[i] += data[i - 1]
		GraphTypes.REPORT:
			var total: float = Request.select_past_funds_movements(filter.date)
			for i in range(len(data)):
				data[i] += total
				total = data[i]
	return data

# Пересчет вектора значений позиции точки
func _get_vector(height: float, v_array: Array, max_v: float, step: float, idx: int) -> Vector2:
	return Vector2(step * idx + 10., (height * v_array[idx] / max_v) * -1 + int(height + 5))

# Отрисовка текста на графике
func _draw_str(x, y, text: String, step, border) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_CENTER, step, 9, border)

# Виды графиков
# Общая часть для линейных графиков
func _line(idx: int, values_array: Array, max_value: float, x_step: float, height: float) -> void:
	var vectors: Array = []
	for i in range(2): vectors.append(_get_vector(height, values_array, max_value, x_step, idx + i))
	draw_line(vectors[0], vectors[1], Color.FIREBRICK, 2)
	for i in range(2): draw_circle(vectors[i], 3, Color.FIREBRICK)

# Линейный для отчетов
func _report(max_value: float, x_step: float = (size.x - 25) / (len(values) - 1)) -> void:
	draw_line(Vector2(10, 116), Vector2(10, 6), ColorScheme.border_color(), 2)
	draw_line(Vector2(10, 60), Vector2(1142.0, 60), ColorScheme.border_color(), 2)
	for i in range(len(values)-1): _line(i, values, max_value, x_step, 55.)

# Линейный для займов
func _loan(max_value: float, x_step: float = (size.x - 25) / (len(values) - 1)) -> void:
	draw_multiline([Vector2(10, 6), Vector2(10, 120), Vector2(1142, 120)], ColorScheme.border_color(), 2)
	if len(values) == 1: draw_circle(Vector2(10., 55.), 3, Color.FIREBRICK)
	if len(values) < 2: return # Отмена отрисовки графика
	for i in range(len(values)-1): _line(i, values, max_value, x_step, 119.)

# Свечной
func _candlestick(max_value: float, x_step: float = size.x / len(values)) -> void:
	for i in range(len(values)):
		var x: float = x_step * i
		var border_color: Color = ColorScheme.border_color()
		_draw_str(x, 120, str(int(i) + 1), x_step, border_color)
		if values[i] == 0: continue # Отмена отрисовки если значение точки отсутствует
		var y_size: float = 50. * abs(values[i]) / abs(max_value)
		var data: Array = [ColorScheme.get_scale_color(0), 58 - y_size, 90.]
		if values[i] < 0: data = [ColorScheme.get_scale_color(1), 60, 30.]
		draw_rect(Rect2(Vector2(x - 2, data[1] - 2), Vector2(x_step + 2, y_size + 4)), border_color)
		draw_rect(Rect2(Vector2(x, data[1]), Vector2(x_step - 2, y_size)), data[0])
		_draw_str(x, data[2], str(values[i]), x_step, border_color)
