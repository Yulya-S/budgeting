extends Calendar
# Подключение путей к объектам в сцене
@onready var SelectedCell = $SelectedCell
@onready var Events = $Events/VBoxContainer

# Переменные
@onready var lines: ArrayLines = ArrayLines.new("event_legend") # Объект для создания строк списка
var event_days: Array = [] # Список дат для маркировки
var select_cell: int = 0 # Индекс выбранной ячейки календаря

# Постепенное создание элементов страницы
func _process(delta: float) -> void:
	super._process(delta)
	lines.add_obj(Events, Request.ObjectVariants.EVENT, self)
	if not _end_create():
		if len(event_days) > 0: Cells.get_child(int(event_days.pop_front().date.split("-")[-1]) + date.weekday() - 1).add_event()
		SelectedCell.visible = true

# Обновление данных
func update_data(filter: Variant = {}) -> void:
	super.update_data(filter)
	ColorScheme.repainting(self)
	SelectedCell.visible = false
	event_days = Request.select_event_days()
	_update_legend(select_cell)

# Обновление списка событий
func _update_legend(idx: int = 0) -> void:
	# Изменение индекса выбранной ячейки если она отсутствует
	if not idx:
		idx = Global.get_date().day
		if not date.date_comparison(Global.sys_date, "==", false): idx = 1
	lines.clear(Request.select_multiplied_events_list(str(idx)), Events)
	# Изменение расположения маркера выбранной даты
	# Получение позиции по горизонтали
	var weekday: int = (date.weekday() + idx) % 7 - 1
	if weekday < 0: weekday = 6
	SelectedCell.position.x = (78 * weekday) + 45 - (2 * (weekday - 1))
	# Получение позиции по вертикали
	var week_number: int = int((date.weekday() + idx) / 7.) - 1
	if weekday == 6: week_number -= 1
	SelectedCell.position.y = (78 * week_number) + 80 - (2 * (week_number - 2))

# Изменение списка при выборе ячейки календаря
func set_cell(index: String = "0") -> void:
	select_cell = int(index)
	_update_legend(select_cell)

# Изменение списка при сбросе выбора ячейки
func reset_cell(index: String) -> void:
	if int(index) != select_cell: return
	set_cell()
