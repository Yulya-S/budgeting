extends Control
class_name FillingCalendar
# Подключение пути к объекту в сцене
@onready var Calendar = $Calendar
# Экспортируемая переменная
@export var cell_count: int = 42  # Количество ячеек в календаре

# Переменные
var date: String = Global.date_to_str() # Выбранная дата
var day_count: int = Request.select_day_count(date) # Количество дней
var lines: Array = [] # Список объектов для создания
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
		var current_day: Dictionary = Global.date_to_dict(date)
		if current_day.weekday == 0: current_day.weedkay = 7
		current_day.weekday -= 1
		if cell_count < 28:
			current_day.day += Calendar.get_child_count() - 1
			if current_day.day >= day_count: current_day.day = int(Calendar.get_child(-1).Number.get_text()) + 1
		else: current_day.day = Calendar.get_child_count() - current_day.weekday
		if (current_day.day > 0 and current_day.day <= day_count) or cell_count < 28:
			# Применение значения номера ячейки
			Calendar.get_child(-1).set_object(current_day.day, Global.date_comparison(current_day, Global.get_date(), "=="),
				Global.date_comparison(current_day, Global.get_date(), "<"))

# Изменение текущей даты
func set_data() -> void:
	date = Global.date_to_str()
	day_count = Request.select_day_count(date)

# Заполнение страницы
func update_page(close_page: String = "") -> void:
	Global.clear_scene(Calendar)
	# Получение данных
	events_color = {}
	set_data()
	lines = Request.select_events(date)
	if Global.date_to_dict(date).day + cell_count > day_count:
		lines += Request.select_events(Global.dictionary_date_to_str(Global.get_other_month(date)))
	for i in lines: if i.event_id not in events_color.keys(): events_color[i.event_id] = "#ffffff"
	for i in range(len(events_color.keys())): events_color[events_color.keys()[i]] = ColorScheme.get_color(events_color.keys()[i]-1, Request.select(Request.Tables.EVENTS, "COUNT(id)-1 count")[0].count)
	# Обновление страницы родителя
	Global.run_func(get_parent(), "update_page", [close_page])
