extends ColorRect
# Экспортируемые переменные
@export var OB_items: Dictionary = {} # Дополнительные фильтры
@export var title_pref: String = "" # Приставка для запроса по названию

# Переменная
var filter: Dictionary = {"where": "", "date": "", "order": ""} # Параметры запроса фильтрации

# Стартовое заполнение фильтров времени
func _ready() -> void:
	for i in get_children():
		match i.name:
			"Year": _on_year_item_selected(-1)
			"Month": $Month.selected = Time.get_datetime_dict_from_system().month - 1

# Применение значений фильтра
func set_filter(obj, value: int) -> void: obj.selected = value

# Заполнение выпадающего списка в фильтре
func set_OB_items(table: Request.Tables) -> void:
	var node_name: String = Global.enum_key(Request.Tables, table)
	Global.fill_optionButton(get_node(node_name[0].to_upper() + node_name.substr(1, len(node_name)-2)), Request.select(table), false)

# Сборка фильтра
func get_filter() -> Dictionary:
	filter = {"where": "", "date": "", "order": ""} # Очистка прошлого запроса
	for i in get_children():
		if "OR" in filter.where.split("AND")[-1] and filter.where[-1] != ")": filter.where = "("+filter.where+")"
		match i.name:
			"Title": filter.where = Request.add_part_request_with_check("", title_pref+"title", i.get_text(), "LIKE")
			"Year": filter.date = [Global.get_OB_text(i)]
			"Month": filter.date.append(i.selected + 1)
			"Button": continue
			_: _other_filters(i)
	# Добавление фильтра времени
	if filter.date is Array: filter.date = Global.date_to_sql_date("-".join(filter.date+[1]))
	if get_parent().get("Objects"):	get_parent().Objects.set_data(filter.where, filter.date, filter.order)
	if get_parent().get("set_filter"): get_parent().set_filter()
	return filter

# Обработка дополнительных фильтров
func _other_filters(obj) -> void:
	if obj.name not in OB_items.keys(): return
	# Фильтры с добавлением объектов
	if "section" in OB_items[obj.name].keys():
		if Global.call("get_OB_"+OB_items[obj.name].section, obj) == 0: return
		if filter.where != "": filter.where += " AND "
		filter.where += OB_items[obj.name].text.replace("__"+OB_items[obj.name].section+"__", str(Global.call("get_OB_"+OB_items[obj.name].section, obj)))
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
func _on_button_button_down() -> void: if get_parent().get("update_date"): get_parent().update_date()
