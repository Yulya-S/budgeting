extends Node
# Сигналы
signal open_window(page: Pages, id, dir: Dirs, parent: Variant) # Открытие окна
signal open_new_page(page: Pages, id, parent: Variant) # Открытие страницы
signal update_page(close_page: String) # Обновление данных на странице

# Перечисления
enum Pages {BASIC, WALLET, SECTION, CASH_FLOW, LOAN, EVENT, REPORT, TRANSFER, PAYMENT, PERCENT, SUBSECTION, REGISTRATION, HINTS, SETTINGS, CLEANING} # Страницы приложения
enum Dirs {PAGES, WINDOWS, INFORMATION} # Директории
enum MouseOver {NORMAL, HOVER} # Состояния курсора мыши
# Переменные
var current_page: Pages = Pages.REGISTRATION # Текущая страница
@onready var sys_date: NewDate = NewDate.new() # Текущая дата

# Создание директорий и файлов приложения
func _ready() -> void:
	for i in [File.create_dirs, File.create_config, File.create_langs]: i.call()
	Request.connection_user_db()

# Перезагрузка системной даты
func update_sys_date() -> void: sys_date = NewDate.new()

# Заполнение выпадающего списка объектами
func fill_optionButton(container: OptionButton, objects: Array, clear_OB: bool = true) -> void:
	if not container: return
	if clear_OB: container.clear()
	for i in objects: container.add_item(i.title, i.id)
	File.set_lang(container)

# Применить значение объекта выпадающего списка по его id
func set_OB_id(container: OptionButton, idx: int) -> void: container.selected = container.get_item_index(idx)

# Получение имени объекта из перечисления
func enum_key(enums: Dictionary, obj: int) -> String: return enums.keys()[obj].to_lower()

# Получение результата работы функции get_filter, на случай пустого фильтра
func get_filter(filter: Variant = {}) -> Dictionary:
	if filter is not Dictionary:
		if not filter.get("get_filter"): return _empty_filter()
		return filter.get_filter()
	var new_filter: Dictionary = _empty_filter()
	filter = filter.duplicate()
	for i in new_filter.keys(): if i not in filter.keys(): filter[i] = new_filter[i]
	return filter

# Получение даты
func get_date() -> Dictionary: return sys_date.date.duplicate()

# Получение количества дней в текущем месяце
func get_day_count() -> int: return sys_date.day_count 

# Перевод словоря даты в текстовый формат
func date_to_str(date_to_update: Dictionary = get_date()) -> String:
	var value: String = Time.get_datetime_string_from_datetime_dict(date_to_update, true)
	return value.split(" ")[0]

# Перевод текстовой даты в формат словаря
func date_to_dict(date_to_update: String = date_to_str(get_date())) -> Dictionary:
	return Time.get_datetime_dict_from_datetime_string(date_to_update, true)

# Изменение даты под формат запроса
func date_to_sql_date(text: String) -> String: return date_to_str(date_to_dict(text))

# Получение индекса выбранного элемента выпадающего списка
func get_OB_id(button: OptionButton) -> int: return button.get_item_id(button.selected)

# Получение текста выбранного элемента выпадающего списка
func get_OB_text(button: OptionButton) -> String: return button.get_item_text(button.selected)

# Получение следующего/предыдущего месяца
func get_other_month(date: Variant, next: bool = false) -> Variant:
	var new_date: Dictionary = date.duplicate() if date is Dictionary else date_to_dict(date)
	new_date.month += 1 if next else -1
	new_date.day = 1
	if next:
		if new_date.month > len(File.lang._Months):
			new_date.year += 1
			new_date.month = 1
	else:
		if new_date.month <= 0:
			new_date.year -= 1
			new_date.month = len(File.lang._Months)
	if date is Dictionary: return new_date
	return date_to_str(new_date)

# Получение пустого фильтра
func _empty_filter() -> Dictionary: return {"date": date_to_str(), "where": "", "order": ""}

# Вызов функции у родителя, если она у него есть
func run_func(obj: Variant, func_name: String, args: Array = []) -> void:
	if obj.get(func_name): obj.callv(func_name, args)

# Проверка равенства года и месяца
func _check_equality(d1: Dictionary, d2: Dictionary) -> bool:
	return d1.year == d2.year and d1.month == d2.month

# Проверка что одна дата меньше или больше другой
func _check_more_less(d1: Dictionary, d2: Dictionary,
		less: bool, column: String) -> bool:
	return (d1[column] < d2[column]) if less else (d1[column] > d2[column])

# Фрагмент проверки даты
func _check_date(d1: Dictionary, d2: Dictionary, less: bool, account_day) -> bool:
	if _check_more_less(d1, d2, less, "year") or (d1.year == d2.year and
		_check_more_less(d1, d2, true, "month")): return true
	return account_day and _check_equality(d1, d2) and _check_more_less(d1, d2, less, "day")

# Проверка что дата (больше или равна) или (меньше или равна)
func _check_complex_date(d1: Dictionary, d2: Dictionary, less: bool, account_day: bool) -> bool:
	return date_comparison(d1, d2, "==", account_day) or \
		date_comparison(d1, d2, "<" if less else ">", account_day)

# Сравнение дат
func date_comparison(d1: Dictionary, d2: Dictionary, operator: String = "==", account_day: bool = true) -> bool:
	match operator:
		"=>": return _check_complex_date(d1, d2, false, account_day)
		"=<": return _check_complex_date(d1, d2, true, account_day)
		"==": if _check_equality(d1, d2): return not account_day or d1.day == d2.day
		">": return _check_date(d1, d2, false, account_day)
		"<": return _check_date(d1, d2, true, account_day)
	return false

# Проверка что текст - это число
func text_is_number(text: String) -> bool:
	return text.is_valid_int() or text.is_valid_float()

# Преобразование текста в числовой формат
func _valide_numeric_text(text_container: TextEdit) -> void:
	var text: String = text_container.get_text()
	if len(text) > 0:
		# Удаление лишних точек дроби
		var text_copy: PackedStringArray = text.split(".")
		if len(text_copy) > 2:
			for i in range(1, len(text_copy) - 1, 1):
				text_copy[0] += text_copy[1]
				text_copy.remove_at(1)
		# Проверка что фрагменты текста, кроме одной точки является числами
		var filtered_text: Variant = []
		for i in text_copy:
			filtered_text.append("")
			for l in i: if l.is_valid_int(): filtered_text[-1] += l
		filtered_text = ".".join(filtered_text)
		# Проверка отличается ли результат от начального значения
		if filtered_text != text:
			var caret: int = text_container.get_caret_column()
			text_container.set_text(filtered_text)
			text_container.set_caret_column(caret - (len(text) - len(filtered_text)))

# Изменение текста в TextEdit
func text_changed_TextEdit(container: TextEdit, is_numeric: bool = false) -> void:
	var text: String = container.get_text()
	if is_numeric: _valide_numeric_text(container)
	if len(text) > 0 and ("\t" in text or "\n" in text):
		container.set_text(container.get_text().replace("\t", "").replace("\n", ""))
		if container.find_next_valid_focus(): container.find_next_valid_focus().grab_focus()

# Удаление объекта сцены
func delete_child(parent: Variant, child: Variant) -> void:
	child.queue_free()
	parent.remove_child(child)

# Очистка сцены
func clear_scene(obj: Variant) -> void: for child in obj.get_children(): delete_child(obj, child)

# Создание и изменение значения элемента
func add_new_child(parent: Variant, path: Resource, values: Array = [], func_name: String = "set_values") -> void:
	parent.add_child(path.instantiate())
	run_func(parent.get_child(-1), func_name, values)

# Проверка наличия ключа в данных и применение при наличии
func set_label_from_data(obj: Label, data: Dictionary) -> void:
	if SF.l(obj) in data.keys(): obj.set_text(str(data[SF.l(obj)]))

# Функция заполнения OptionButton для данных по году
func fill_year_OB(container: OptionButton, idx: int, year: int = Global.get_date().year) -> void:
	var last_month: bool = Global.get_date().month == 12
	if idx != -1: year = int(container.get_item_text(idx))
	for i in range(container.item_count): container.remove_item(0)
	for i in range(year-10, year+10+int(last_month), 1):
		if i + 1 > Global.get_date().year+int(last_month): break
		container.add_item(str(i+1))
	container.selected = 9
