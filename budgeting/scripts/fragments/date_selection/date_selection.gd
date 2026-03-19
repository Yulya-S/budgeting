extends Calendar
# Подключение путей к объектам в сцене
@onready var Year = $Year
@onready var Month = $Month
# Переменная
@onready var selected_day: Dictionary = Global.get_date() # Выбранный день

# Применение стартового значения
func _ready() -> void: _update_year_month()

# Изменение выбранной даты
func set_date(new_date: String) -> void:
	selected_day = Global.date_to_dict(new_date)
	_update_year_month(selected_day)

# Получение выбранной в календаре даты
func get_date() -> String: return Global.date_to_str(selected_day)

# Обновление данных
func update_data(_filter: Variant = {}) -> void:
	super.update_data({"date": Global.date_to_str(selected_day)})

# Изменение настроек календаря
func _update_year_month(new_date: Dictionary = Global.sys_date.date) -> void:
	_on_year_item_selected()
	_update_month()
	update_day(new_date.day)

# Изменение значения месяца
func _update_month(value: int = 0) -> void:
	if value != 0: selected_day = Global.get_other_month(selected_day, value > 0)
	Month.set_text(File.lang._Months[selected_day.month - 1])
	update_data()

# Изменение номера дня
func update_day(day: int) -> void: selected_day.day = day

# Обработка нажатий кнопок
# Следующий месяц
func _on_next_button_down() -> void: _update_month(1)

# Предыдущий месяц
func _on_previous_button_down() -> void: _update_month(-1)

# Выбор года
func _on_year_item_selected(index: int = -1) -> void:
	if index > -1: selected_day.year = int(Global.get_OB_text(Year))
	Global.fill_year_OB(Year, index, selected_day.year)
	if index > -1: selected_day.day = 1
	update_data()
