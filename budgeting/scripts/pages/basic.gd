extends Page
# Подключение пути к объекту в сцене
@onready var Cells = $ObjArray/VBoxContainer/Events/Calendar

# Переменные для календаря событий
var cell_path: Resource = load("res://scenes/pages/events/cell.tscn") # Путь к сцене ячеек календаря
var event_days: Array = [] # Список дат для маркировки
var start_update: bool = false # Был ли отправлен запрос на изменение страницы

# Постепенное создание элементов страницы
func _process(_delta: float) -> void:
	if Cells.get_child_count() < 14:
		var day_number: int = Global.get_date().day + Cells.get_child_count() - Global.get_date().weekday
		if day_number >= Global.get_day_count(): day_number -= Global.get_day_count()
		Global.add_new_child(Cells, cell_path, [day_number, true, true, Global.get_day_count()])
	elif Request.completion_creation_et and start_update:
		start_update = false
		event_days = Request.select_event_days('date >= "'+Global.date_to_str()+'" AND date < DATE("'+Global.date_to_str()+'", "+14 days")')
	elif len(event_days) > 0:
		var value: int = int(event_days.pop_front().date.split("-")[-1])
		var idx: int = value - (Global.get_date().day - Global.get_date().weekday + 1)
		if idx < 0: idx = Global.get_day_count() - Global.get_date().day + value + Global.get_date().weekday - 1
		if idx < Cells.get_child_count(): Cells.get_child(idx).add_event()		
	
# Запуск обновления данных на странице
func _update_page() -> void:
	$Menu/Budget.set_text(str(Request.select_wallets_sum()))
	$Menu/CashFlow.set_text(str(Request.select_funds_movements()))
	super._update_page()
	
# Обновление данных
func update_data() -> void:
	super.update_data()
	Global.clear_scene(Cells)
	# Отправка запроса на обновление таблицы с событиями
	Request.start_create_multiplied_events_table(Global.date_to_str())
	start_update = true
	
# Получение данных фильтра
func _get_filter(obj: Variant) -> Array: return [] if obj.get_parent().name != "Sections" else [{"where":"s.month_limit>=0", "order": "value DESC"}]
