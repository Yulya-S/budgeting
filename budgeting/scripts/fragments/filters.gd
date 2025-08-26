extends ColorRect
# Экспортируемая переменная
@export var OB_items: Dictionary = {} # Дополнительные фильтры

# Переменная
var filter: Dictionary = {"where": "", "date": "", "order": ""} # Параметры запроса фильтрации

# Стартовое заполнение фильтров времени
func _ready() -> void:
	for i in get_children():
		match i.name:
			"Year": _on_year_item_selected(-1)
			"Month": $Month.selected = Time.get_datetime_dict_from_system().month - 1

# Сборка фильтра
func get_filter() -> void:
	filter = {"where": "", "date": "", "order": ""} # Очистка прошлого запроса
	for i in get_children():
		if "OR" in filter.where: filter.where = "("+filter.where+")"
		match i.name:
			"Title": filter.where = Request.add_part_request_with_check("", "title", i.get_text(), "LIKE")
			"Year": filter.date = [Global.get_OB_text(i)]
			"Month": filter.date.append(i.selected + 1)
			"Button": continue
			_: _other_filters(i)
	# Добавление фильтра времени
	if filter.date is Array: filter.date = Global.date_to_sql_date("-".join(filter.date+[1]))

# Обработка дополнительных фильтров
func _other_filters(obj) -> void:
	if obj.name not in OB_items.keys(): return
	# Фильтры с добавлением объектов
	if "section" in OB_items[obj.name].keys():
		if filter.where != "": filter.where += " AND "
		filter.where += OB_items[obj.name].text.replase("__"+OB_items[obj.name].section+"__", Global.call("get_OB_"+OB_items[obj.name].section, obj))
		return
	if str(obj.selected) not in OB_items[obj.name].keys(): return
	if "filter" not in OB_items[obj.name].keys():
		if filter.where != "": filter.where += " AND "
		filter.where += OB_items[obj.name][str(obj.selected)]
	else:
		if filter.order != "": filter.order += ", "
		filter.order += OB_items[obj.name][str(obj.selected)]

# Обработка выбора года
func _on_year_item_selected(index: int) -> void:
	var current_year: int = Time.get_datetime_dict_from_system().year
	var year: int = current_year
	if index != -1: year = int($Year.get_item_text(index))
	for i in range($Year.item_count): $Year.remove_item(0)
	for i in range(year-10, year+10, 1):
		if i + 1 > current_year: break
		$Year.add_item(str(i+1))
	$Year.selected = 9

# Обработка нажатия на кнопку применения фильтра
func _on_button_button_down() -> void:
	get_filter()
	if get_parent().get("Objects"): get_parent().Objects.set_data(filter.where, filter.date, filter.order)
	if get_parent().get("set_filter"): get_parent().set_filter()
