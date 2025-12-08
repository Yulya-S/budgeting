extends ColorRect
# Экспортируемые переменные
@export var OB_items: Dictionary = {} # Дополнительные фильтры
@export var title_pref: String = "" # Приставка для запроса по названию

# Переменные
var filter: Dictionary = {"where": "", "date": "", "order": ""} # Параметры запроса фильтрации
var order_item_texts: Array = []

# Стартовое заполнение фильтров времени
func _ready() -> void: reset_date_filters()

# Сброс фильтра месяца и года
func reset_date_filters() -> void:
	for i in get_children():
		match i.name:
			"Year": _on_year_item_selected(-1)
			"Month": i.selected = Time.get_datetime_dict_from_system().month - 1
			"Order": if len(order_item_texts) == 0: for l in range(i.get_item_count()): order_item_texts.append(i.get_item_text(l))
	
# Сброс перевода способа сортировки
func reset_order() -> void: if $Order: for i in range($Order.get_item_count()): $Order.set_item_text(i, order_item_texts[i])

# Применение значений фильтра
func set_filter(obj, value: int) -> void: obj.selected = value

# Заполнение выпадающего списка в фильтре
func set_OB_items(table: Request.Tables) -> void:
	var node_name: String = Global.enum_key(Request.Tables, table)
	var node: OptionButton = get_node(node_name[0].to_upper() + node_name.substr(1, len(node_name)-2))
	node.clear()
	node.add_item("", 0)
	Global.fill_optionButton(node, Request.select(table), false)

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
func _on_button_button_down() -> void: if get_parent().get("update_data"): get_parent().update_data()
