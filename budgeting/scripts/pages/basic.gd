extends Control
# Подключение путей к объектам в сцене
@onready var Budget = $Menu/Budget
@onready var CashFlow = $Menu/CashFlow
@onready var Objects = $ScrollContainer/VBoxContainer
@onready var Cells = $ScrollContainer/VBoxContainer/Events/Calendar

# Переменные для календаря событий
var cell_path: Resource = load("res://scenes/pages/events/cell.tscn") # Путь к сцене ячеек календаря
var event_days: Array = [] # Список дат для маркировки в каллендаре
var date: Dictionary = {} # Сохранение выбранной даты
var day_count: int = 30 # Количество дней в выбранном месяце

# Создание главной страницы
func _ready() -> void:
	Global.connect("update_page", Callable(self, "_update_page"))
	_update_page()

# Постепенное создание элементов страницы
func _process(delta: float) -> void:
	if Cells.get_child_count() < 14:
		Cells.add_child(cell_path.instantiate())
		Cells.get_child(-1).set_values(date.day + Cells.get_child_count() - date.weekday - 1, true, true, day_count)
	elif len(event_days) > 0:
		var value: int = int(event_days.pop_front().date.split("-")[-1])
		if value <= date.day - date.weekday + 14: Cells.get_child(value - (date.day - date.weekday + 1)).add_event()
	
# Запуск обновления данных на странице
func _update_page() -> void:
	ColorScheme.repainting(self)
	
	Budget.set_text(str(Request.select_wallets_sum()))
	CashFlow.set_text(str(Request.select_funds_movements()))
	
	
	update_data()
	
	#File.set_lang(self)
	
# Обновление данных
func update_data() -> void:
	_find_objects(Objects)
	# Создание ячеек календаря
	# Очистка календаря
	for i in Cells.get_children():
		i.queue_free()
		Cells.remove_child(i)
	# Получение новых данных для создания на странице
	date = Global.date_to_dict()
	if date.weekday == 0: date.weekday = 7 # Смена индекса дня недели
	day_count = Request.select_day_count(Global.date_to_str())
	# Получение новых данных для создания заполнения легенды
	Request.create_multiplied_events_table("-".join([date.year, date.month, "01"]))
	event_days = Request.select_event_days("CAST(strftime('%d', date) AS INTEGER)>"+str(date.day-date.weekday))

# Поиск и запуск изменения списков и графиков
func _find_objects(obj: Variant) -> void:
	Global.run_func(obj, "update_data")
	for i in obj.get_children(): _find_objects(i)
	
