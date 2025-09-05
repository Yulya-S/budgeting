extends Control
class_name CreationWindow
# Подключение путей к объектам в сцене
@onready var Error = $Error
@onready var Delete = $Window/Delete

# Экспортируемая переменная
@export var table: Request.Tables = Request.Tables.WALLETS # Связанная таблица

# Переменная
var id = null # Индекс изменяемого объекта

# Изменение информации о счете
func set_object(obj_id: int, _parent = null) -> void:
	id = obj_id
	Delete.visible = true
	if "@" in name: name = get_parent().get_child(-2).name.to_lower().replace("inf", "")
	var value: Array = Request.call("select_"+name.to_lower(), id)
	if len(value) < 0: return
	set_values(value[0])

# Изменение данных на странице
func set_values(data: Dictionary) -> void:
	for i in get_children():
		if i.name.to_lower() not in data.keys(): continue
		match i.get_class():
			"CheckButton": i.button_pressed = data[i.name.to_lower()]
			"TextEdit": i.set_text(str(data[i.name.to_lower()]))
			"OptionButton": i.selected = data[i.name.to_lower()] - 1
			"ColorRect": if i.name == "Date": i.set_date(data[i.name.to_lower()])

# Получение значений из контейнеров окна создания объекта
func get_values() -> Array:
	var values: Array = []
	for i in get_children():
		match i.name:
			"Title", "Note": values.append('"'+i.get_text()+'"')
			"Value", "Month_Limit": values.append(float(i.get_text()))
			"Income": values.append(int(i.button_pressed))
			"Date": values.append('"'+i.get_date()+'"')
			"Wallet_Id", "Wallet", "Extra": values.append(Global.get_OB_id(i))
	return values
	
# Проверка введенных данных
func check_object(new_circle: bool = true) -> bool:
	Error.visible = not new_circle
	for i in get_children():
		if i is TextEdit and i.name != "Note" and i.get_text() == "":
			Global.set_error(Error, "Все поля должны быть заполнены")
			return Error.visible
	return Error.visible
		
# Проверка существуют ли подобные записи
func _set_error(values: Array) -> bool:
	if len(values) == 0: return Error.visible
	elif not id: Global.set_error(Error, "Объект уже существует")
	else: for i in values: if id != i.id:  Global.set_error(Error, "Объект уже существует")
	return Error.visible
	
# Создание или изменение объекта
func create_update() -> void:
	if id: Request.update_record(table, id, get_values())
	else: Request.insert_record(table, get_values())

# Удаление объекта
func delete_obj() -> void: Request.delete(table, id)

# Изменение значения названия кошелька
func _on_title_text_changed() -> void:
	Global.text_changed_TextEdit($Title)
	check_object()
	
# Изменение значения счета
func _on_value_text_changed() -> void:
	Global.text_changed_TextEdit($Value, true)
	check_object()
	
# Изменение значения счета
func _on_month_limit_text_changed() -> void:
	Global.text_changed_TextEdit($Month_Limit, true)
	check_object()

# Изменение выбранного счета
func _on_wallet_item_selected(index: int) -> void: check_object()
