extends Calendar
# Подключение путей к объектам в сцене
@onready var Year = $Year
@onready var Month = $Month
# Переменная
@onready var selected_day: Dictionary = Global.get_date() # Номер выбранного дня

# Применение стартового значения
func _ready() -> void: _update_year_month()

# Изменение выбранной даты
func set_date(new_date: String) -> void:
	selected_day = Global.date_to_dict(new_date)
	_update_year_month(selected_day.duplicate())

# Получение выбранной в календаре даты
func get_date() -> String: return Global.date_to_str(selected_day)

# Обновление данных
func update_data(_filter: Variant = {}) -> void:
	super.update_data({"date": Global.date_to_str(selected_day)})

# Изменение настроек календаря
func _update_year_month(new_date: Dictionary = Global.sys_date.date) -> void:
	_on_year_item_selected()
	_update_month()
	selected_day.day = new_date.day

# Изменение номера дня
func update_day(day: int) -> void: selected_day.day = day

# Изменение значения месяца
func _update_month(value: int = 0) -> void:
	selected_day.month += value
	if selected_day.month > len(File.lang._Months): selected_day.month = 1
	elif selected_day.month <= 0: selected_day.month = len(File.lang._Months)
	Month.set_text(File.lang._Months[selected_day.month - 1])
	selected_day.day = 1
	update_data()

# Обработка нажатия кнопки следующего месяца
func _on_next_button_down() -> void: _update_month(1)

# Обработка нажатия кнопки предыдущего
func _on_previous_button_down() -> void: _update_month(-1)

# Обработка выбора года
func _on_year_item_selected(index: int = -1) -> void:
	Global.fill_year_OB(Year, index, selected_day.year)
	selected_day.day = 1
	update_data()
