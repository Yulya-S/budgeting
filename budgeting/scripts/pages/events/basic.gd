extends HBoxContainer
# Переменные
var cell_path: Resource = load("res://scenes/pages/events/cell.tscn") # Путь к сцене ячеек календаря
var event_days: Array = [] # Список дат для маркировки в каллендаре
var date: Dictionary = {} # Сохранение выбранной даты
var day_count: int = 30 # Количество дней в выбранном месяце

# Постепенное создание элементов страницы
func _process(delta: float) -> void:
	if get_child_count() < 14:
		add_child(cell_path.instantiate())
		get_child(-1).set_values(date.day + get_child_count() - date.weekday - 1, true, true, day_count)
	elif len(event_days) > 0:
		var value: int = int(event_days.pop_front().date.split("-")[-1])
		if value <= date.day - date.weekday + 14: get_child(value - (date.day - date.weekday + 1)).add_event()

# Обновление данных
func data_update() -> void:
	# Очистка календаря
	for i in get_children():
		i.queue_free()
		remove_child(i)
	# Получение новых данных для создания на странице
	date = Global.date_to_dict()
	if date.weekday == 0: date.weekday = 7 # Смена индекса дня недели
	day_count = Request.select_day_count(Global.date_to_str())
	# Получение новых данных для создания заполнения легенды
	Request.create_multiplied_events_table("-".join([date.year, date.month, "01"]))
	event_days = Request.select_event_days("CAST(strftime('%d', date) AS INTEGER)>"+str(date.day-date.weekday))
