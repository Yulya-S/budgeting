extends Control
# Перечисление
enum GraphTypes {CANDLESTICK, REPORT, LOAN} # Виды графиков
# Экспортируемая переменная
@export var graph_type: GraphTypes = GraphTypes.CANDLESTICK # Выбранный вид графика
# Переменная
var values: Array = [] # Данные для отображения

# Отрисовка графика
func _draw() -> void:
	if _is_loan():
		var values_count: int = values.pop_back().count
		var v: Array = []
		for i in values: v.append(i.value)
		_loan([v.max(), v.min() * -1].max(), (size.x - 25) / (values_count - 1))
		return
	var max_value: float = 0.
	if len(values) > 0: max_value = [values.max(), values.min() * -1].max()
	if graph_type == GraphTypes.REPORT: _report(max_value)
	else: _candlestick(max_value)

# Проверка что типом графика является - займ
func _is_loan() -> bool: return graph_type == GraphTypes.LOAN

# Перезапуск отрисовки графика
func update_data(filter: Variant = {}) -> void:
	ColorScheme.repainting(self)
	var filter_data: Dictionary = Global.get_filter(filter)
	if _is_loan(): values = Request.select_loan_graphics(get_parent().idx)
	else:
		for i in range(Request.select_day_count(filter_data.date)): values.append(0.0)
		for i in Request.select_cash_flow_graphics(filter_data.where, filter_data.date):
			values[int(i.day) - 1] = i.value
	match graph_type:
		GraphTypes.LOAN:
			for i in range(1, len(values) - 1): values[i].value += values[i - 1].value
		GraphTypes.REPORT:
			var total: float = Request.select_past_funds_movements(filter_data.date)
			for i in range(len(values)):
				values[i] += total
				total = values[i]
	queue_redraw()

# Виды графиков
# Отрисовка текста на графике
func _draw_str(x, y, text: String, step, border) -> void:
	if len(text) > 8: return
	draw_string(ThemeDB.fallback_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_CENTER, step, 8, border)

# Отрисовка точек на графике
func _line_and_dots(vectors: Array):
	draw_line(vectors[0], vectors[1], Color.FIREBRICK, 2)
	for i in range(2): draw_circle(vectors[i], 3, Color.FIREBRICK)

# Линейный для отчетов
func _report(max_value: float, x_step: float = (size.x - 25) / (len(values) - 1)) -> void:
	draw_line(Vector2(10, 116), Vector2(10, 6), ColorScheme.border_color(), 2)
	draw_line(Vector2(10, 60), Vector2(1142.0, 60), ColorScheme.border_color(), 2)
	for i in range(len(values)-1):
		var vectors: Array = []
		for l in range(2):
			vectors.append(Vector2(x_step * (i + l) + 10., (55. * values[i + l] / max_value) * -1 + 60))
		_line_and_dots(vectors)

# Линейный для займов
func _loan(max_value: float, x_step: float) -> void:
	draw_line(Vector2(10, 120), Vector2(10, 4), ColorScheme.border_color(), 2)
	draw_line(Vector2(10, 120), Vector2(1142, 120), ColorScheme.border_color(), 2)
	if len(values) == 1: draw_circle(Vector2(10., 55.), 3, Color.FIREBRICK)
	if len(values) < 2: return # Отмена отрисовки графика
	for i in range(len(values)-1):
		var vectors: Array = []
		for l in range(2):
			vectors.append(Vector2(x_step * (values[i + l].day - 1) + 10.,
				(102. * values[i + l].value / max_value) * -1 + 107))
		_line_and_dots(vectors)

# Свечной
func _candlestick(max_value: float, x_step: float = (size.x - 20.) / len(values)) -> void:
	for i in range(len(values)):
		var x: float = (x_step * i) + 10.
		var border_color: Color = ColorScheme.border_color()
		_draw_str(x, 120, str(int(i) + 1), x_step, border_color)
		if values[i] == 0: continue # Отмена отрисовки если значение точки отсутствует
		var y_size: float = 50. * abs(values[i]) / abs(max_value)
		var data: Array = [ColorScheme.get_scale_color(0), 58 - y_size, 90.]
		if values[i] < 0: data = [ColorScheme.get_scale_color(1), 60, 30.]
		draw_rect(Rect2(Vector2(x - 2, data[1] - 2), Vector2(x_step + 2, y_size + 4)), border_color)
		draw_rect(Rect2(Vector2(x, data[1]), Vector2(x_step - 2, y_size)), data[0])
		_draw_str(x, data[2], str(values[i]), x_step, border_color)
