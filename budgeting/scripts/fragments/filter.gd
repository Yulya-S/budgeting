extends ColorRect
# Экспортируемые переменные
@export var OB_items: Dictionary = {} # Дополнительные фильтры
@export var title_pref: String = "" # Приставка для запроса по названию

# Переменные
var filter: Dictionary = {"where": "", "date": "", "order": ""} # Параметры запроса фильтрации
var order_item_texts: Array = [] # Список параметров сортировки

# Стартовое заполнение фильтров времени
func _ready() -> void: reset_date_filters()

# Сброс фильтра месяца и года
func reset_date_filters() -> void:
	for i in get_children():
		match i.name:
			"Year": _on_year_item_selected()
			"Month": i.selected = Global.get_date().month - 1
			"Order": if len(order_item_texts) == 0: for l in range(i.get_item_count()): order_item_texts.append(i.get_item_text(l))
	
# Сброс перевода способа сортировки
func reset_order() -> void: if $Order: for i in range($Order.get_item_count()): $Order.set_item_text(i, order_item_texts[i])

# Применение значений фильтра
func set_filter(obj: Variant, value: int) -> void: obj.selected = value

# Заполнение выпадающего списка в фильтре
func set_OB_items(table: Request.Tables) -> void:
	var node_name: String = Global.enum_key(Request.Tables, table)
	var node: OptionButton = get_node(node_name[0].to_upper() + node_name.substr(1, len(node_name)-2))
	node.clear()
	node.add_item("", 0)
	Global.fill_optionButton(node, Request.select_all(table), false)

# Сборка фильтра
func get_filter() -> Dictionary:
	filter = {"where": "", "date": "", "order": ""} # Очистка фильтра
	for i in get_children():
		if "OR" in filter.where.split("AND")[-1] and filter.where[-1] != ")": filter.where = "("+filter.where+")"
		match i.name:
			"Title": filter.where = title_pref + 'title LIKE "%' + i.get_text() + '%"'
			"Year": filter.date = [Global.get_OB_text(i)]
			"Month": filter.date.append(i.selected + 1)
			"Button": continue
			_: _other_filters(i)
	# Добавление фильтра времени
	if filter.date is Array: filter.date = Global.date_to_sql_date("-".join(filter.date+[1]))
	return filter

# Получение списка ключей
func _get_keys(obj: Variant) -> Array: return OB_items[obj.name].keys()

func _update_value(obj: Variant, value_name: String, sep: String) -> void:
	if filter[value_name] != "": filter[value_name] += sep
	filter[value_name] += OB_items[obj.name][str(obj.selected)]

# Обработка дополнительных фильтров
func _other_filters(obj: Variant) -> void:
	if obj.name not in OB_items.keys(): return
	# Фильтры с добавлением объектов
	if "section" in _get_keys(obj):
		if Global.call("get_OB_id", obj) == 0: return
		if filter.where != "": filter.where += " AND "
		filter.where += OB_items[obj.name].text.replace("__id__", str(Global.call("get_OB_id", obj)))
		return
	if str(obj.selected) not in _get_keys(obj): return
	if "filter" not in _get_keys(obj): _update_value(obj, "where", " AND ")
	else: _update_value(obj, "order", ", ")

# Обработка выбора года
func _on_year_item_selected(index: int = -1) -> void: Global.fill_year_OB($Year, index)

# Обработка нажатия на кнопку применения фильтра
func _on_button_button_down() -> void: Global.run_func(get_parent(), "update_data")

# Изменение значения текстового контейнера
func _on_title_text_changed() -> void: Global.text_changed_TextEdit($Title)
