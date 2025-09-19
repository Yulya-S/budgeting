extends CreationWindow
# Подключение путей к объектам в сцене
@onready var Title = $Title
@onready var Value = $Value
@onready var Wallet = $Wallet_Id
@onready var Note = $Note
@onready var Date = $Date

# Заполнение выпадающих списков
func _ready() -> void: Global.fill_optionButton(Wallet, Request.select(Request.Tables.WALLETS))

# Получение индекса займа
func get_loan_id() -> int: return Request.select(Request.Tables.CASH_FLOWS, "*", "id="+str(id))[0].wallet_2_id

# Проверка введенных данных
func check_object(_new_circle: bool = true) -> bool:
	Error.visible = false
	if float(Value.get_text()) <= 0: Global.set_error(Error, "Значение должно быть больше нуля")
	super.check_object(not Error.visible)
	return _set_error(Request.select(table, "id", 'title="'+Title.get_text()+'" AND total<>0'))

# Изменение значение счета после проведения транзакции
func _update_wallet_value(delete: bool = false) -> void:
	var income: int = 1
	if delete: income = -1
	Request.update(Request.Tables.WALLETS, "value=value+"+str(income*float(Value.get_text())), "id="+str(Global.get_OB_id(Wallet)))

# Проведение обратной операции
func _back_wallet_value() -> void:
	set_object(id)
	_update_wallet_value(true)
	
# Создание или изменение объекта
func create_update() -> void:
	var values: Array = get_values()
	var loan_values: Array = []
	for i in range(3): loan_values.append(values[i+1])
	values.insert(2, 2)
	_update_wallet_value()
	if id: _back_wallet_value()
	if id:
		Request.update_record(table, get_loan_id(), loan_values)
		values[1] = get_loan_id()
		Request.update_record(Request.Tables.CASH_FLOWS, id, values)
	else:
		Request.insert_record(table, loan_values)
		values[1] = Request.select(table, "id", "", "id DESC")[0].id
		Request.insert_record(Request.Tables.CASH_FLOWS, values)

# Обработка нажатия кнопки удаления
func delete_obj() -> void:
	_back_wallet_value()
	var loan_id: int = get_loan_id()
	Request.delete(table, loan_id)
	Request.delete(Request.Tables.CASH_FLOWS, id)
	Request.update(Request.Tables.CASH_FLOWS, "wallet_2_id=wallet_2_id-1", "section_id IN (2, 3, 4) AND wallet_2_id>"+str(loan_id))
