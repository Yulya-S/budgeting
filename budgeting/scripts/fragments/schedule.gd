extends ColorRect
# Параметр
var values: Array = [] # Данные для отображения
var date: Dictionary = Time.get_datetime_dict_from_system() # Дата фильтрации

# Получение изначальных данных
func _ready() -> void: values = Request.select_daily_transactions("", Time.get_date_string_from_system())

# Отрисовка графика
func _draw() -> void:
	# Получение количества дней в выбранном месяце
	var next_month: int = date.month + 1
	var next_year: int = date.year
	if next_month >= 12:
		next_month = 1
		next_year += 1
	var current: Dictionary = Time.get_datetime_dict_from_datetime_string("-".join([date.year, date.month, 1]), true)
	var next: Dictionary = Time.get_datetime_dict_from_datetime_string("-".join([next_year, next_month, 1]), true)
	if current.weekday == 0: current.weekday = 7
	if next.weekday == 0: next.weekday = 7
	var day_count: int = 21 # 3 недели
	day_count += next.weekday + (7 - current.weekday)
	if day_count < 28: day_count += 7 # Если в месяце 4 целых недели
	# Получение размеров объектов графика
	var max_value: float = 0.0
	for i in values: if max_value < abs(i.value): max_value = abs(i.value)
	var x_step: float = size.x / day_count
	# Отрисовка
	for i in range(day_count): draw_string(ThemeDB.fallback_font, Vector2(x_step*i, 120), str(i+1.), HORIZONTAL_ALIGNMENT_CENTER, x_step, 9, Color.BLACK)
	for i in values:
		var y_size: float = 50. * abs(i.value) / abs(max_value)
		if i.value < 0:
			draw_rect(Rect2(Vector2(x_step*(int(i.day)-1), 60), Vector2(x_step, y_size)),Color.FIREBRICK)
			draw_string(ThemeDB.fallback_font, Vector2(x_step*(int(i.day)-1.), 30.), str(i.value), HORIZONTAL_ALIGNMENT_CENTER, x_step, 9, Color.BLACK)
		else:
			draw_rect(Rect2(Vector2(x_step*(int(i.day)-1), 60 - y_size), Vector2(x_step, y_size)),Color.WEB_GREEN)
			draw_string(ThemeDB.fallback_font, Vector2(x_step*(int(i.day)-1.), 90.), str(i.value), HORIZONTAL_ALIGNMENT_CENTER, x_step, 9, Color.BLACK)
	
# Перезапуск отрисовки графика
func update_schedule(where: String, new_date: String = Time.get_date_string_from_system()) -> void:
	date = Time.get_datetime_dict_from_datetime_string(new_date, false)
	values = Request.select_daily_transactions(where, new_date)
	queue_redraw()
