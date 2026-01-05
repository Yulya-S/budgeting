extends ColorRect
# Параметры
var values: Array = [] # Данные для отображения
var date: NewDate = NewDate.new() # Выбранная дата

# Получение стартовых данных
func _ready() -> void: update_data()

# Отрисовка графика
func _draw() -> void:
	# Получение размеров объектов графика
	var max_value: float = 0.0
	for i in values: if max_value < abs(i.value): max_value = abs(i.value)
	var x_step: float = size.x / date.day_count
	# Отрисовка
	for i in range(date.day_count): draw_string(ThemeDB.fallback_font, Vector2(x_step*i, 120), str(int(i)+1), HORIZONTAL_ALIGNMENT_CENTER, x_step, 9, ColorScheme.get_sys_color(0, 1))
	for i in values:
		if i.value == 0: continue
		var y_size: float = 50. * abs(i.value) / abs(max_value)
		var data: Array = [ColorScheme.get_color(0, 1, ColorScheme.scales_gradient), y_size + 2, 90.]
		if i.value < 0: data = [ColorScheme.get_color(1, 1, ColorScheme.scales_gradient), 0., 30.]
		draw_rect(Rect2(Vector2(x_step*(int(i.day)-1) - 2, 60 - data[1] - 2), Vector2(x_step + 4, y_size + 4)), ColorScheme.get_sys_color(0, 1))
		draw_rect(Rect2(Vector2(x_step*(int(i.day)-1), 60 - data[1]), Vector2(x_step, y_size)), data[0])
		draw_string(ThemeDB.fallback_font, Vector2(x_step*(int(i.day)-1.), data[2]), str(i.value), HORIZONTAL_ALIGNMENT_CENTER, x_step, 9, ColorScheme.get_sys_color(0, 1))
	
# Перезапуск отрисовки графика
func update_data(filter: Variant = {}) -> void:
	ColorScheme.repainting(self) # Изменение цветовой темы
	var filter_data: Dictionary = Global.get_filter(filter)
	date.set_value(filter_data.date)
	values = Request.select_cash_flow_graphics(filter_data.where, filter_data.date)
	queue_redraw()
