extends ColorRect
# Подключение путей к объектам в сцене
@onready var Year = $Year
@onready var Month = $Month
@onready var Cells = $GridContainer

# Список месяцев в календаре
const month_list: Array = ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
							"Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]

# Переменные
var month_idx: int = 0 # Номер выбранного месяца
var selected_day: Dictionary = {} # Номер вывбранного дня
var cell_path = load("res://scenes/fragments/calendar/cell.tscn") # Путь к сцене ячеек календаря

# Получение текущей даты
func _ready() -> void:
	selected_day = Time.get_date_dict_from_system()
	_update_calendar()

# Изменение настроек календаря
func _update_calendar() -> void:
	month_idx = selected_day.month
	var current: Dictionary = Time.get_date_dict_from_system()
	# Заполнение списка выбора года
	for i in range(Year.item_count): Year.remove_item(0)
	for i in range(selected_day.year-10, selected_day.year+10, 1):
		if i + 1 > current.year: break
		Year.add_item(str(i+1))
	Year.selected = 9
	_create_days()
	
# Изменение текущей даты из базы данных
func set_date(new_date: String) -> void:
	selected_day = Time.get_datetime_dict_from_datetime_string(new_date, true)
	_update_calendar()

# Получение выбранной в календаре даты
func get_date() -> String: return Time.get_datetime_string_from_datetime_dict(selected_day, true).split(" ")[0]

# Заполнение календаря ячейками дней
func _create_days():
	Month.set_text(month_list[month_idx-1].to_upper()) # Смена имени месяца
	# Очистка ячеек
	for i in Cells.get_children():
		i.queue_free()
		Cells.remove_child(i)
	
	# Сдвиг месяца и года
	var next_month_idx = month_idx + 1
	var next_year: int = int(Year.get_item_text(Year.selected))
	if next_month_idx > len(month_list):
		next_month_idx = 1
		next_year += 1
	
	# Получение первых чисел этого и следующего месяцев
	var current: Dictionary = Time.get_datetime_dict_from_datetime_string("-".join([Year.get_item_text(Year.selected), month_idx, 1]), true)
	var next: Dictionary = Time.get_datetime_dict_from_datetime_string("-".join([next_year, next_month_idx, 1]), true)
	# Смена индекса воскресения
	if current.weekday == 0: current.weekday = 7
	if next.weekday == 0: next.weekday = 7
	# Создание ячеекв
	var start_draw: bool = false
	for i in range(42):
		if i-current.weekday > 26:
			if (i + 1) % 7 == next.weekday: start_draw = false
		elif current.weekday - 1 == i: start_draw = true
		Cells.add_child(cell_path.instantiate())
		if start_draw:
			Cells.get_child(-1).set_object(i-current.weekday+2, i-current.weekday+2 == selected_day.day)

# Изменение номера дня
func update_day(day: int):
	selected_day.day = day
	for i in Cells.get_children(): i.is_today = i.id == day

# Изменение значения месяца
func _update_month(value: int = 1) -> void:
	month_idx += value
	if month_idx > len(month_list): month_idx = 1
	elif month_idx <= 0: month_idx = len(month_list)
	selected_day.month = month_idx
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
