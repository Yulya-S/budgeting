extends Node
class_name NewDate
# Переменные
@onready var date: Dictionary = Time.get_date_dict_from_system() # Дата
var day_count: int = 30 # Количество дней в месяце

func _init(new_date: Variant) -> void: set_value(new_date)

# Изменение значений переменных
func set_value(new_date: Variant):
	date = new_date.duplicate() if new_date is Dictionary else Global.date_to_dict(new_date)
	day_count = Request.select_day_count(Global.date_to_str(date))
	if date.weekday == 0: date.weekday = 7

# Номер дня недели
func weekday() -> int: return date.weekday - 1

# Суммарное количество ячеек календаря
func calendar_cells() -> int:
	var whole: int = day_count + weekday()
	return whole if whole % 7 == 0 else whole + (7 - whole % 7)

# Сравнение дат
func date_comparison(other_date: Variant, operator: String = "==", account_day: bool = false) -> bool:
	if other_date is NewDate: other_date = other_date.date
	return Global.date_comparison(date, other_date, operator, account_day)
