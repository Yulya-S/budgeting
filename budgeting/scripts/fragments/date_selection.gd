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
var today: Dictionary = {} # Данные о текущем дне
var cell_path = load("res://scenes/fragments/calendar/cell.tscn") # Путь к сцене ячеек календаря

# Получение текущей даты и месяца
func _ready() -> void:
	today = Time.get_date_dict_from_system()
	month_idx = today.month
	# Заполнение списка выбора года
	for i in range(today.year-10, today.year, 1): Year.add_item(str(i+1))
	Year.selected = Year.item_count - 1
	create_days()

# Заполнение календаря ячейками дней
func create_days():
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
	var day_count = 27 + abs(next.weekday - (current.weekday))
	print(day_count)
	for i in range(42):
		if i-current.weekday > 26:
			if (i + 1) % 7 == next.weekday: start_draw = false
		elif current.weekday - 1 == i: start_draw = true
		Cells.add_child(cell_path.instantiate())
		if start_draw: Cells.get_child(-1).get_child(-1).set_text(str(i-current.weekday+2))
		if i - current.weekday + 2 == current.day and Year.get_item_text(Year.selected) == str(today.year) and month_idx == today.month:
			Cells.get_child(-1).get_child(0).color = Color.html("#f7cdcd")

# Обработка нажатия кнопки следующего месяца
func _on_next_button_down() -> void:
	month_idx += 1
	if month_idx > len(month_list): month_idx = 1
	create_days()

# Обработка нажатия кнопки предыдущего
func _on_previous_button_down() -> void:
	month_idx -= 1
	if month_idx <= 0: month_idx = len(month_list)
	create_days()

# Обработка выбора года
func _on_year_item_selected(index: int) -> void: create_days()
