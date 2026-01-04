extends Node
class_name NewDate
# Переменные
var date: Dictionary = Time.get_date_dict_from_system() # Дата
var day_count: int = 30 # Количество дней в месяце

# Изменение значений переменных
func set_value(new_date: Variant):
	date = new_date.duplicate() if new_date is Dictionary else Global.date_to_dict(new_date)
	day_count = Request.select_day_count(Global.date_to_str(date))
	if date.weekday == 0: date.weekday = 7

# Номер дня недели
func weekday() -> int: return date.weekday - 1

# Суммарне количество ячеек календаря
func calendar_cells() -> int:
	var whole: int = day_count + date.weekday - 1
	return whole + (7 - whole % 7)

# Сравнение дат
func date_comparison(other_date: Variant, operator: String = "==", account_day: bool = false) -> bool:
	return Global.date_comparison(date, other_date, operator, account_day)
