extends CreationPage
class_name Movement
# Подключение путей к объектам в сцене
@onready var Count = $Count
@onready var Wallet = $Wallet
@onready var Extra = $Extra
@onready var Value = $Value
@onready var Note = $Note
@onready var Date = $DateSelection

# Экспортируемые переменные
@export var second_table = Request.Tables.SECTIONS # Таблица связанная со вторым выпадающим списком

# Изменение информации о дополнительном параметре
func set_extra(_extra_idx: int = 0) -> void: pass

# Изменение значение счета после проведения транзакции
func _update_wallet_value(_delete: bool = false) -> void: pass

# Заполнение выпадающих списков
func _ready() -> void:
	Global.fill_optionButton(Wallet, Request.select(Request.Tables.WALLETS))
	if second_table == Request.Tables.SECTIONS: Global.fill_optionButton(Extra, Request.select(second_table, "*", "id>2"))
	else: Global.fill_optionButton(Extra, Request.select(second_table))
	set_wallet()
	set_extra()

# Получение названия колонки, отвечающей за связь таблиц
func _get_extra_name() -> String:
	var obj_name: String = Global.enum_key(Request.Tables, second_table)
	obj_name[-1] = "_"
	return obj_name + "id"
	
# Проведение дополнительных проверок на верность данных
func _extra_errors() -> bool: return Error.visible
	
# Изменение объекта
func set_object(obj_id: int, parent = null) -> void:
	match parent:
		Request.Tables.WALLETS:	set_wallet(obj_id - 1) 
		null: set_all(obj_id)
		_: set_extra(obj_id) 

# Изменение всей информации об объекте
func set_all(obj_id) -> void:
	var value: Array = _get_obj_data(obj_id)
	if len(value) <= 0: return
	set_wallet(value[0].wallet_id)
	set_extra(value[0][_get_extra_name()])
	Value.set_text(str(value[0].value))
	Note.set_text(value[0].note)
	Date.set_date(value[0].date)

# Изменение информации о счете
func set_wallet(wallet_idx: int = 0) -> void:
	Wallet.selected = wallet_idx
	Count.set_text(str(Request.select(Request.Tables.WALLETS, "*", "id="+str(Global.get_OB_id(Wallet)))[0].value))

# Проверка заполненности полей
func check_object() -> bool:
	Error.visible = false
	if Value.get_text() == "": Global.set_error(Error, "Значение не должно быть пустым")
	elif float(Value.get_text()) <= 0: Global.set_error(Error, "Значение должно быть больше нуля")
	return _extra_errors()

# Изменение значения движения средств
func _on_value_text_changed() -> void:
	Global.text_changed_TextEdit(Value, true)
	check_object()

# Изменение выбранного счета
func _on_wallet_item_selected(index: int) -> void:
	set_wallet(index)
	check_object()

# Изменение выбранного дополнительного параметра
func _on_extra_item_selected(index: int) -> void:
	set_extra(index)
	check_object()

# Проведение обратной операции
func _back_wallet_value() -> void:
	set_all(id)
	_update_wallet_value(true)

# Обработка нажатия кнопки сохранения / изменения
func _on_apply_button_down() -> void:
	if check_object(): return
	_update_wallet_value()
	var values: Array = [Global.get_OB_id(Wallet), Global.get_OB_id(Extra), float(Value.get_text()), '"'+Date.get_date()+'"', '"'+Note.get_text()+'"']
	if id: _back_wallet_value()
	_create_update(values)

# Обработка нажатия кнопки удаления
func _on_delete_button_down() -> void:
	_back_wallet_value()
	super._on_delete_button_down()
