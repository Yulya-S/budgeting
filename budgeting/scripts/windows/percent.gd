extends CreationWindow
# Подключение путей к объектам в сцене
@onready var Count = $Count
@onready var Loan = $Loan
@onready var Value = $Value

# Переменная
var last_value: float = 0.0 # Старое значение на которое было изменено значение займа

# Заполнение выпадающих списков
func _ready() -> void:
	Global.fill_optionButton(Loan, Request.select(Request.Tables.LOANS, "*", "total>0"))
	_on_loan_item_selected(0, false)
	
# Изменение объекта
func set_object(obj_id, parent = null) -> void:
	if not parent:  set_all(obj_id)
	else: _on_loan_item_selected(obj_id, false)

# Изменение всей информации об объекте
func set_all(obj_id: int) -> void:
	id = obj_id
	Delete.visible = true
	var value: Array = Request.select(table, "*", "id="+str(id))
	if len(value) < 0: return
	for i in get_children():
		if i.name.to_lower() not in value[0].keys() + ["extra"]: continue
		match i.get_class():
			"TextEdit": i.set_text(str(value[0][i.name.to_lower()]))
			"ColorRect": if i.name == "Date": i.set_date(value[0][i.name.to_lower()])
			"OptionButton": _on_loan_item_selected(value[0].wallet_2_id - 1, false)
	last_value = float(Value.get_text())
	set_result()
	
# Проверка заполненности полей
func check_object(_new_circle: bool = true) -> bool:
	Error.visible = false
	if float(Count.get_text().split(" ")[0]) <= 0: Global.set_error(Error, "Значение должно быть больше нуля")
	super.check_object(not Error.visible)
	return Error.visible

# Установка текста результата добавления процентов по займу
func set_result() -> void:
	var loan_value: float = Request.select(Request.Tables.LOANS, "*", "id="+str(Global.get_OB_id(Loan)))[0].total
	Count.set_text(str(loan_value-last_value) + " + " + str(float(Value.get_text())) + " = " + str(loan_value-last_value+float(Value.get_text())))

# Изменение выбранного дополнительного параметра
func _on_loan_item_selected(index: int = 0, check: bool = true) -> void:
	Loan.selected = Request.select(Request.Tables.LOANS, "COUNT(id) id", "total>0 and id<"+str(index))[0].id
	set_result()
	if check: check_object()
	
# Изменение значения счета
func _on_value_text_changed() -> void:
	Global.text_changed_TextEdit(Value, true)
	set_result()
	check_object()

# Проведение обратной операции
func _back_wallet_value() -> void:
	set_all(id)
	_update_wallet_value(true)
	
# Изменение значение счета после проведения транзакции
func _update_wallet_value(delete: bool = false) -> void:
	var income: int = 1 if not delete else -1
	Request.update(Request.Tables.LOANS, "total=total+"+str(income*float(Value.get_text())), "id="+str(Global.get_OB_id(Loan)))

# Создание или изменение объекта
func create_update() -> void:
	var values: Array = get_values()
	_update_wallet_value()
	if id: _back_wallet_value()
	if id: Request.update_record(table, id, values)
	else: Request.insert_record(table, values)
	
# Получение значений из контейнеров окна создания объекта
func get_values() -> Array:
	var values: Array = super.get_values()
	values.insert(1, 4)
	values.insert(0, 0)
	return values
	
# Обработка нажатия кнопки удаления
func delete_obj() -> void:
	_back_wallet_value()
	Request.delete(table, id)
