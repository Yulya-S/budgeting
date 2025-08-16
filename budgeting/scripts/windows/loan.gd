extends CreationWindow
# Подключение путей к объектам в сцене
@onready var Wallet = $Wallet
@onready var Note = $Note
@onready var Date = $DateSelection

# Переменная
var loan_id = null # Индекс займа

# Заполнение выпадающих списков
func _ready() -> void: Global.fill_optionButton(Wallet, Request.select(Request.Tables.WALLETS))

# Изменение объекта
func set_object(obj_id, parent = null) -> void:
	match parent:
		Request.Tables.WALLETS:	_on_wallet_item_selected(obj_id) 
		Request.Tables.LOANS: set_loan(obj_id)
		_: set_all(obj_id) 

# Изменение всей информации об объекте
func set_all(obj_id) -> void:
	var value: Array = _get_obj_data(obj_id)
	if len(value) <= 0: return
	_on_wallet_item_selected(value[0].wallet_id - 1)
	set_loan(value[0].wallet_2_id)
	Value.set_text(str(value[0].value))
	Note.set_text(value[0].note)
	Date.set_date(value[0].date)

# Изменение выбранного займа
func set_loan(extra_idx: int = 0) -> void:
	loan_id = extra_idx
	Title.set_text(Request.select(table, "title", "id="+str(extra_idx))[0].title)

# Изменение выбранного счета
func _on_wallet_item_selected(index: int) -> void:
	Wallet.selected = index
	check_object()

# Проверка заполненности полей
func check_object() -> bool:
	Error.visible = super.check_object()
	if Value.get_text() == "": Global.set_error(Error, "Значение не должно быть пустым")
	elif float(Value.get_text()) <= 0: Global.set_error(Error, "Значение должно быть больше нуля")
	var values = Request.select(table, "id", 'title="'+Title.get_text()+'" AND total<>0')
	return _set_error(values)

# Изменение значение счета после проведения транзакции
func _update_wallet_value(delete: bool = false) -> void:
	var income: int = 1
	if delete: income = -1
	Request.update(Request.Tables.WALLETS, "value=value+"+str(income*float(Value.get_text())), "id="+str(Global.get_OB_id(Wallet)))

# Проведение обратной операции
func _back_wallet_value() -> void:
	set_all(id)
	_update_wallet_value(true)
	
# Создание или изменение объекта
func _create_update(values: Array) -> void:
	if id:
		Request.update_record(table, loan_id, ['"'+Title.get_text()+'"', float(Value.get_text()), '"'+Date.get_date()+'"'])
		Request.update_record(Request.Tables.CASH_FLOWS, id, values)
	else:
		Request.insert_record(table, ['"'+Title.get_text()+'"', '"'+Date.get_date()+'"', float(Value.get_text())])
		values[1] = Request.select(table, "id", "", "id DESC")[0].id
		Request.insert_record(Request.Tables.CASH_FLOWS, values)
	_apply_changes()

# Обработка нажатия кнопки сохранения / изменения
func _on_apply_button_down() -> void:
	if check_object(): return
	_update_wallet_value()
	var values: Array = [Global.get_OB_id(Wallet), loan_id, 3, float(Value.get_text()),
		'"'+Date.get_date()+'"', '"'+Note.get_text()+'"']
	if id: _back_wallet_value()
	_create_update(values)

# Обработка нажатия кнопки удаления
func _on_delete_button_down() -> void:
	_back_wallet_value()
	Request.delete(table, loan_id)
	Request.delete(Request.Tables.CASH_FLOWS, id)
	_apply_changes()
