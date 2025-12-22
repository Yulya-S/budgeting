extends Node
# Сигналы
signal open_window(page: Pages, id, dir: Dirs, parent) # Открытие окна
signal open_new_page(page: Pages, id, parent) # Открытие окна с предварительной очисткой
signal update_page(close_page: String) # Обновление данных на странице

# Перечисления
enum Pages {BASIC, WALLET, SECTION, CASH_FLOW, LOAN, EVENT, TRANSFER, PAYMENT, PERCENT, WALLET_INF, LOAN_INF, REPORTS, REGISTRATION, SETTINGS} # Страницы приложения
enum Dirs {PAGES, WINDOWS} # Директории
enum MouseOver {NORMAL, HOVER} # Состояния курсора мыши

# Переменные
var current_page: Pages = Pages.BASIC # Текущая страница
var date: Dictionary = Time.get_datetime_dict_from_system() # Текущая дата

# Изменение даты под формат запроса
func date_to_sql_date(text: String) -> String: return date_to_str(date_to_dict(text))

# Получить имя объекта из перечисления
func enum_key(enums, object) -> String: return enums.keys()[object].to_lower()

# Получить индекс выбранного элемента выпадающего списка
func get_OB_id(button: OptionButton) -> int: return button.get_item_id(button.selected)

# Получить текст выбранного элемента выпадающего списка
func get_OB_text(button: OptionButton) -> String: return button.get_item_text(button.selected)

# Проверка что текст — это число
func valide_numeric_text(text_container: TextEdit) -> void:
	var text = text_container.get_text()
	if len(text) > 0:
		# Удаление лишних точек дроби
		var text_copy: PackedStringArray = text.split(".")
		if len(text_copy) > 2:
			for i in range(1, len(text_copy) - 1, 1):
				text_copy[0] += text_copy[1]
				text_copy.remove_at(1)
		# Проверка что фрагменты текста, кроме одной точки является числами
		var filtered_text = []
		for i in text_copy:
			filtered_text.append("")
			for l in i: if l.is_valid_int(): filtered_text[-1] += l
		filtered_text = ".".join(filtered_text)
		# Проверка отличается ли результат от начального значения
		if filtered_text != text:
			var caret = text_container.get_caret_column()
			text_container.set_text(filtered_text)
			text_container.set_caret_column(caret - (len(text) - len(filtered_text)))

# Изменение текста в TextEdit
func text_changed_TextEdit(container: TextEdit, is_numeric: bool = false) -> void:
	var text = container.get_text()
	if is_numeric: Global.valide_numeric_text(container)
	if len(text) > 0 and ("\t" in text or "\n" in text):
		container.set_text(container.get_text().replace("\t", "").replace("\n", ""))
		if container.find_next_valid_focus(): container.find_next_valid_focus().grab_focus()

# Заполнение выпадающего списка объектами
func fill_optionButton(container: OptionButton, objects: Array, clear_OB: bool = true) -> void:
	if not container: return
	if clear_OB: container.clear()
	for i in objects: container.add_item(i.title, i.id)
	
# Получение следующего/предыдущего месяца
func get_other_month(date: Variant, next: bool = false) -> Variant:
	var new_date = date.duplicate() if date is Dictionary else Global.date_to_dict(date)
	if next:
		new_date.month += 1
		if new_date.month > 12:
			new_date.year +=1
			new_date.month = 1
	else:
		new_date.day = 1
		new_date.month -= 1
		if new_date.month <= 0:
			new_date.year -= 1
			new_date.month = 1
	if date is Dictionary: return new_date
	return date_to_str(new_date)

# Сравнение дат	
func date_comparison(date1: Dictionary, date2: Dictionary, operator: String = "==", account_day: bool = true) -> bool:
	match operator:
		"=>": return date_comparison(date1, date2, "==", account_day) or date_comparison(date1, date2, ">", account_day)
		"=<": return date_comparison(date1, date2, "==", account_day) or date_comparison(date1, date2, "<", account_day)
		"==":
			if date1.year == date2.year and date1.month == date2.month:
				return not account_day or date1.day == date2.day
		">":
			if date1.year > date2.year: return true
			if date1.year == date2.year and date1.month > date2.month: return true
			return account_day and date1.year == date2.year and date1.month == date2.month and date1.day > date2.day
		"<":
			if date1.year < date2.year: return true
			if date1.year == date2.year and date1.month < date2.month: return true
			return account_day and date1.year == date2.year and date1.month == date2.month and date1.day < date2.day
	return false

# Перевод словоря даты в текстовый формат
func date_to_str(date_to_update: Dictionary = date, split_text: bool = false) -> String:
	var value: String = Time.get_datetime_string_from_datetime_dict(date_to_update, true)
	return value.split(" ")[0] if split_text else value

# Перевод текстовой даты в формат словаря
func date_to_dict(date_to_update: String = date_to_str(date)) -> Dictionary: return Time.get_datetime_dict_from_datetime_string(date_to_update, true)

# Функция вызова функции у родителя если она у него есть
func run_func(obj: Variant, func_name: String, args: Array = []) -> void: if obj.get(func_name): obj.callv(func_name, args)

# Получение результата работы функции get_filter на случай нулевого фильтра
func get_filter(filter: Variant = {}) -> Dictionary:
	if filter is not Dictionary: return filter.get_filter()
	var new_filter: Dictionary = {"date": Global.date_to_str(), "where": "", "order": ""}
	filter = filter.duplicate()
	for i in new_filter.keys(): if i not in filter.keys(): filter[i] = new_filter[i]
	return filter
