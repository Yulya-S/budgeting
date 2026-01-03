extends ColorRect
# Подключение путей к объектам в сцене
@onready var Year = $Year
@onready var Month = $Month
@onready var Cells = $GridContainer

# Список месяцев в календаре
const month_list: Array = ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
							"Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]

# Переменные
var selected_day: Dictionary = {} # Номер выбранного дня
var cell_path: Resource = load("res://scenes/fragments/calendar/cell.tscn") # Путь к сцене ячеек календаря

# Получение текущей даты
func _ready() -> void:
	selected_day = Global.date
	_update_calendar()

# Изменение текущей даты из базы данных
func set_date(new_date: String) -> void:
	selected_day = Global.date_to_dict(new_date)
	_update_calendar()

# Получение выбранной в календаре даты
func get_date() -> String: return Global.date_to_str(selected_day).split(" ")[0]

# Изменение настроек календаря
func _update_calendar() -> void:
	var current: Dictionary = Global.date
	# Заполнение списка выбора года
	for i in range(Year.item_count): Year.remove_item(0)
	for i in range(selected_day.year-10, selected_day.year+10, 1):
		if i + 1 > current.year: break
		Year.add_item(str(i+1))
	Year.selected = 9
	_create_days()
	
# Заполнение календаря ячейками дней
func _create_days() -> void:
	Month.set_text(month_list[selected_day.month-1].to_upper()) # Смена имени месяца
	# Очистка ячеек
	for i in Cells.get_children():
		i.queue_free()
		Cells.remove_child(i)
	# Получение данных о месяце
	var current_month: Dictionary = Global.date_to_dict("-".join([selected_day.year, selected_day.month, 1]))
	var day_count: int = Request.select_day_count(Global.date_to_str(current_month).split(" ")[0])
	if current_month.weekday == 0: current_month.weekday = 7 # Смена индекса воскресения
	current_month.weekday -= 1
	# Создание ячеек
	var start_draw: bool = false
	for i in range(1, 43):
		if i - current_month.weekday > day_count: start_draw = false
		elif i >= current_month.weekday: start_draw = true
		Cells.add_child(cell_path.instantiate())
		if start_draw: Cells.get_child(-1).set_object(i-current_month.weekday, i-current_month.weekday== selected_day.day)

# Изменение номера дня
func update_day(day: int) -> void:
	selected_day.day = day
	for i in Cells.get_children(): i.is_today = i.id == day

# Изменение значения месяца
func _update_month(value: int = 1) -> void:
	selected_day.month += value
	if selected_day.month > len(month_list): selected_day.month = 1
	elif selected_day.month <= 0: selected_day.month = len(month_list)
	selected_day.day = 1
	_create_days()

# Обработка нажатия кнопки следующего месяца
func _on_next_button_down() -> void: _update_month(1)

# Обработка нажатия кнопки предыдущего
func _on_previous_button_down() -> void: _update_month(-1)

# Обработка выбора года
func _on_year_item_selected(index: int) -> void:
	selected_day.year = int(Year.get_item_text(index))
	selected_day.day = 1
	_update_calendar()
