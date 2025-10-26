extends Control
class_name FillingCalendar
# Подключение пути к объектам в сцене
@onready var Calendar = $Calendar

# Экспортируемая переменная
@export var cell_count: int = 42

# Переменные
var date: String = Time.get_date_string_from_system() # Выборанная дата
var day_count: int = Request.select_day_count(date) # Количество дней в выбранном месяце
var lines: Array = [] # Список объектов для создания на странице
var events_color: Dictionary = {} # Цвета добавленных событий
var cell_path: Resource = load("res://scenes/pages/events/cell.tscn") # Путь к сцене ячеек календаря

# Подключение сигнала
func _ready() -> void: Global.connect("update_page", Callable(self, "update_page"))

# Постепенное заполнение календаря
func _process(_delta: float) -> void:
	# Заполнение календаря
	if Calendar.get_child_count() < cell_count:
		Calendar.add_child(cell_path.instantiate()) # Добавление ячейки
		# Вычисление даты
		var current_day: Dictionary = Time.get_datetime_dict_from_datetime_string(date, true)
		if current_day.weekday == 0: current_day.weedkay = 7
		current_day.weekday -= 1
		if cell_count < 28:
			current_day.day += Calendar.get_child_count() - 1
			if current_day.day >= day_count: current_day.day = int(Calendar.get_child(-1).Number) + 1
		else: current_day.day = Calendar.get_child_count() - current_day.weekday
		if (current_day.day > 0 and current_day.day <= day_count) or cell_count < 28:
			# Применение значения номера ячейки
			Calendar.get_child(-1).set_object(current_day.day, Global.date_comparison(current_day, Time.get_datetime_dict_from_system(), "=="),
				Global.date_comparison(current_day, Time.get_datetime_dict_from_system(), "<"))

# Изменение текущей даты
func set_data() -> void:
	date = Time.get_date_string_from_system()
	day_count = Request.select_day_count(date)

# Заполнение страницы
func update_page(close_page: String = "") -> void:
	# Очистка страницы
	for i in Calendar.get_children():
		i.queue_free()
		Calendar.remove_child(i)
	# Получение данных
	events_color = {}
	set_data()
	lines = Request.select_events(date)
	if Time.get_datetime_dict_from_datetime_string(date, true).day + cell_count > day_count:
		lines += Request.select_events(Global.dictionary_date_to_str(Global.get_other_month(date)))
	for i in lines: if i.event_id not in events_color.keys(): events_color[i.event_id] = "#ffffff"
	for i in range(len(events_color.keys())): events_color[events_color.keys()[i]] = ColorScheme.get_color(events_color.keys()[i]-1, Request.select(Request.Tables.EVENTS, "COUNT(id)-1 count")[0].count)
	# Обновление страницы родителя
	if get_parent().get("update_page"):	get_parent().update_page(close_page)
