extends Control
# Подключение путей к объектам в сцене
@onready var Calendar = $HBoxContainer

# Переменные
var day_count: int = 30
var lines: Array = [] # Список объектов для создания на странице
var events_color: Dictionary = {} # Цвета добавленных событий
var cell_path: Resource = load("res://scenes/pages/events/cell.tscn") # Путь к сцене ячеек календаря

# Подключение сигнала
func _ready() -> void: Global.connect("update_page", Callable(self, "update_page"))

# Постепенное заполнение календаря
func _process(_delta: float) -> void:
	if Calendar.get_child_count() < 14:
		var day_number: int = int(Calendar.get_child(-1).Number.get_text()) + 1
		if day_number > day_count: day_number = 1
		add_cell(day_number, false)
		
func add_cell(number: int, first: bool = false) -> void:
	Calendar.add_child(cell_path.instantiate())
	Calendar.get_child(-1).size = Vector2(125, 125)
	Calendar.get_child(-1).set_object(number, first, false)

# Заполнение страницы
func update_page(close_page: String = "") -> void:
	# Очистка страницы
	for i in Calendar.get_children():
		i.queue_free()
		Calendar.remove_child(i)
	# Получение данных
	events_color = {}
	var date: Dictionary = Time.get_datetime_dict_from_system()
	day_count = Request.select_day_count(Global.dictionary_date_to_str(date))
	lines = Request.select_events(Global.dictionary_date_to_str(date))
	if date.day + 14 > day_count:
		lines += Request.select_events(Global.dictionary_date_to_str(Global.get_other_month(date)))
	for i in lines: if i.event_id not in events_color.keys(): events_color[i.event_id] = "#ffffff"
	for i in range(len(events_color.keys())): events_color[events_color.keys()[i]] = ColorScheme.get_color(events_color.keys()[i]-1, Request.select(Request.Tables.EVENTS, "COUNT(id)-1 count")[0].count)
	# Добавление первой ячейки
	Calendar.add_child(cell_path.instantiate())
	Calendar.get_child(-1).set_object(date.day, true, false)
	# Обновление страницы родителя
	if get_parent().get("update_page"):	get_parent().update_page(close_page)
