extends GridContainer
# Переменные
var date: String = Time.get_date_string_from_system() # Выборанная дата
var day_count: int = Request.select_day_count(date) # Количество дней в выбранном месяце
var lines: Array = [] # Список объектов для создания на странице
var events: Dictionary = {} # Цвета добавленных событий	
var cell_path: Resource = load("res://scenes/pages/events/cell.tscn") # Путь к сцене ячеек календаря

# Постепенное заполнение календаря
func _process(_delta: float) -> void:
	if get_child_count() < 42:
		add_child(cell_path.instantiate()) # Добавление ячейки
		# Вычисление даты
		var current_day: Dictionary = Time.get_datetime_dict_from_datetime_string(date, true)
		if current_day.weekday == 0: current_day.weedkay = 7
		current_day.weekday -= 1
		current_day.day = get_child_count() - current_day.weekday
		if current_day.day > 0 and current_day.day <= day_count:
			# Применение значения номера ячейки
			get_child(-1).set_object(current_day.day, Global.date_comparison(current_day, Time.get_datetime_dict_from_system(), "=="),
				Global.date_comparison(current_day, Time.get_datetime_dict_from_system(), "<"))
	
# Изменение параметров запроса
func set_data(_where: String = "", new_date: String = "", _order: String = "") -> void:
	if new_date != "":
		date = new_date
		day_count = Request.select_day_count(date)
	update_page()
	
# Заполнение страницы
func update_page(close_page: String = ""):
	for i in get_children():
		i.queue_free()
		self.remove_child(i)
	events = {}
	lines = Request.select_events(date)
	for i in lines: if i.event_id not in events.keys(): events[i.event_id] = "#ffffff"
	for i in range(len(events.keys())): events[events.keys()[i]] = ColorScheme.get_color(events.keys()[i]-1, Request.select(Request.Tables.EVENTS, "COUNT(id)-1 count")[0].count)
	if get_parent().get("update_page"):	get_parent().update_page(close_page)
