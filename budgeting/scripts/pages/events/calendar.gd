extends Control
# Подключение путей к объектам в сцене
@onready var Cells = $Cells
@onready var SelectedCell = $SelectedCell
@onready var Legend = $Legend/VBoxContainer

# Переменные
# Ссылки
var legend_element_path: Resource = load("res://scenes/fragments/list_elements/event_legend.tscn") # Путь к сцене элемента легенды
var cell_path: Resource = load("res://scenes/pages/events/cell.tscn") # Путь к сцене ячеек календаря
# Списки
var lines: Array = [] # Список объектов для создания на странице
var change_list: Array = [] # Список для изменения объектов на странице
var event_days: Array = [] # Список дат для маркировки в каллендаре
# Обновляемые
var day_count: int = 30 # Количество дней в выбранном месяце
var date: Dictionary = {} # Сохранение выбранной даты
var select_cell: int = 0 # Индекс выбранной ячейки календаря
var filter: Dictionary = {} # Сохранение данные фильтра

func _ready() -> void: ColorScheme.repainting(SelectedCell)

# Постепенное создание элементов страницы
func _process(_delta: float) -> void:
	if len(change_list) > 0: lines.append(Request.match_update_list_element(Request.ObjectVariants.EVENT, change_list.pop_front(), self))
	if len(lines) > 0:
		Legend.add_child(legend_element_path.instantiate())
		Legend.get_child(-1).set_values(lines.pop_front())
	if Cells.get_child_count() < day_count + date.weekday - 1 or Cells.get_child_count() % 7 != 0:
		Cells.add_child(cell_path.instantiate())
		Cells.get_child(-1).set_values(Cells.get_child_count() - date.weekday, Global.date_comparison(Global.date, date, "==", false),
			Global.date_comparison(Global.date, date, "=<", false), day_count)
	elif len(event_days) > 0:
		var value: Dictionary = event_days.pop_front()
		Cells.get_child(int(value.date.split("-")[-1]) + date.weekday - 2).add_event()

# Обновление данных
func data_update(new_filter: ColorRect) -> void:
	# Очистка календаря
	for i in Cells.get_children():
		i.queue_free()
		Cells.remove_child(i)
	# Получение новых данных для создания на странице
	filter = new_filter.get_filter()
	Request.create_multiplied_events_table(filter.date)
	date = Global.date_to_dict(filter.date)
	if date.weekday == 0: date.weekday = 7 # Смена индекса дня недели
	day_count = Request.select_day_count(filter.date)	
	event_days = Request._select_event_days()
	_update_legend(select_cell)

# Основление списка событий в выбранном дне
func _update_legend(idx: int = 0) -> void:
	# Очистка списка
	for i in Legend.get_children():
		i.queue_free()
		Legend.remove_child(i)
	Legend.add_child(legend_element_path.instantiate()) # Создание заголовка
	var filter_date: Dictionary = Global.date_to_dict(filter.date)
	# Изменение индекса выбранной ячейки если она отсутствует
	if not idx:
		idx = Global.date.day
		if not Global.date_comparison(filter_date, Global.date, "==", false): idx = 1
	change_list = Request.select_multiplied_events_list(str(idx))
	# Изменение расположения маркера выбранной даты
	# Получение позиции по горизонтали
	var weekday: int = (filter_date.weekday - 1 + idx) % 7 - 1
	if weekday < 0: weekday = 6
	SelectedCell.position.x = (78 * weekday) + 45 - (2 * (weekday - 1))
	# Получение позиции по вертикали
	var week_number: int = int((filter_date.weekday - 1 + idx) / 7 - 1)
	if weekday == 6: week_number -= 1
	SelectedCell.position.y = (78 * week_number) + 80 - (2 * (week_number - 2))

# Изменение списка при выборе ячейки календаря
func set_cell(index: String) -> void:
	select_cell = int(index)
	_update_legend(select_cell)

# Изменение списка при сбросе выбора ячейки
func reset_cell(index: String) -> void:
	if int(index) != select_cell: return
	select_cell = 0
	_update_legend()
