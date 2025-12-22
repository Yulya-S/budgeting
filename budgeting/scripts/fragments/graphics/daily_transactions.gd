extends ColorRect
# Параметр
var values: Array = [] # Данные для отображения
var date: String = Global.date_to_str() # Дата фильтрации

# Получение изначальных данных
func _ready() -> void: values = Request.select_cash_flow_graphics("", date)

# Отрисовка графика
func _draw() -> void:
	var day_count: int = Request.select_day_count(date) # Получение количества дней
	# Получение размеров объектов графика
	var max_value: float = 0.0
	for i in values: if max_value < abs(i.value): max_value = abs(i.value)
	var x_step: float = size.x / day_count
	# Отрисовка
	for i in range(day_count): draw_string(ThemeDB.fallback_font, Vector2(x_step*i, 120), str(i+1.), HORIZONTAL_ALIGNMENT_CENTER, x_step, 9, ColorScheme.get_sys_color(0, 1))
	for i in values:
		if i.value == 0: continue
		var y_size: float = 50. * abs(i.value) / abs(max_value)
		var data: Array = [ColorScheme.get_color(0, 1, ColorScheme.scales_gradient), y_size + 2, 90.]
		if i.value < 0: data = [ColorScheme.get_color(1, 1, ColorScheme.scales_gradient), 0., 30.]
		draw_rect(Rect2(Vector2(x_step*(int(i.day)-1) - 2, 60 - data[1] - 2), Vector2(x_step + 4, y_size + 4)), ColorScheme.get_sys_color(0, 1))
		draw_rect(Rect2(Vector2(x_step*(int(i.day)-1), 60 - data[1]), Vector2(x_step, y_size)), data[0])
		draw_string(ThemeDB.fallback_font, Vector2(x_step*(int(i.day)-1.), data[2]), str(i.value), HORIZONTAL_ALIGNMENT_CENTER, x_step, 9, ColorScheme.get_sys_color(0, 1))
	ColorScheme.repainting(self)
	
# Перезапуск отрисовки графика
func update_data(filter: Variant = {}) -> void:
	var filter_data: Dictionary = Global.get_filter(filter)
	date = filter_data.date
	values = Request.select_cash_flow_graphics(filter_data.where, date)
	queue_redraw()
