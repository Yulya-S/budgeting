extends CreationPage
@onready var Count = $Count
@onready var Wallet = $Wallet
@onready var Section = $Section
@onready var Value = $Value
@onready var ConsumptionIncome = $Section/ConsumptionIncome
@onready var Note = $Note
@onready var Date = $DateSelection

# Создание сцены
func _ready() -> void:
	table = Request.Tables.CASH_FLOWS # Смена связанной таблицы
	# Заполнение выпадающих списков
	Global.fill_optionButton(Wallet, Request.select(Request.Tables.WALLETS))
	Global.fill_optionButton(Section, Request.select(Request.Tables.SECTIONS))
	set_wallet(1)
	set_section(1)

# Изменение объекта
func set_object(obj_id: int, parent = null) -> void:
	match parent:
		Request.Tables.WALLETS: set_wallet(obj_id) 
		Request.Tables.SECTIONS: set_section(obj_id) 
		_: set_all(obj_id)

# Изменение информации о счете
func set_all(obj_id: int):
	var value: Array = _get_obj_data(obj_id)
	if len(value) < 0: return
	set_wallet(value[0].wallet_id)
	set_section(value[0].section_id)
	Value.set_text(str(value[0].value))
	Note.set_text(value[0].note)
	Date.set_date(value[0].date)

# Изменение счета
func set_wallet(wallet_id: int) -> void:
	Wallet.selected = wallet_id - 1
	Count.set_text(str(Request.select(Request.Tables.WALLETS, "*", "id="+str(wallet_id))[0].value))

# Изменение раздела расхода
func set_section(section_id: int) -> void:
	Section.selected = section_id - 1
	if Request.select(Request.Tables.SECTIONS, "income", "id="+str(section_id))[0].income:
		ConsumptionIncome.set_text("Доход")

# Проверка заполнености полей
func check_object() -> bool:
	Error.visible = false
	if Value.get_text() == "": Global.set_error(Error, "Значение не должно быть пустым")
	elif float(Value.get_text()) <= 0: Global.set_error(Error, "Значение должно быть больше нуля")
	return Error.visible

# Изменение значение счета на кошельке после проведения транзакции
func _update_wallet_value(delete: bool = false):
	var income = int(ConsumptionIncome.get_text() == "Доход")
	if delete: income = int(not bool(income))
	if income == 0: income = -1
	Request.update(Request.Tables.WALLETS, "value=value+"+str(income*float(Value.get_text())), "id="+str(Wallet.selected+1))

# Изменение значения движения средств
func _on_value_text_changed() -> void:
	Global.text_changed_TextEdit(Value, true)
	check_object()

# Изменение выбранного счета
func _on_wallet_item_selected(index: int) -> void: set_wallet(index + 1)

# Изменение выбранного раздела
func _on_section_item_selected(index: int) -> void: set_section(index + 1)

# Обработка нажатия кнопки сохранения / изменения
func _on_apply_button_down() -> void:
	if check_object(): return
	if id:
		var new_value = Value.get_text()
		Value.set_text(str(Request.select(Request.Tables.CASH_FLOWS, "value", "id="+str(id))[0].value))
		_update_wallet_value(true)
		Value.set_text(new_value)
	_update_wallet_value()
	_create_update([Wallet.selected+1, Section.selected+1, float(Value.get_text()), '"'+Date.get_date()+'"', '"'+Note.get_text()+'"'])

# Обработка нажатия кнопки удаления
func _on_delete_button_down() -> void:
	Value.set_text(str(Request.select(Request.Tables.CASH_FLOWS, "value", "id="+str(id))[0].value))
	_update_wallet_value(true)
	super._on_delete_button_down()
