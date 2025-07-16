extends CreationPage
class_name Movement
# Подключение путей к объектам в сцене
@onready var Count = $Count
@onready var Wallet = $Wallet
@onready var Extra = $Extra
@onready var Value = $Value
@onready var Note = $Note
@onready var Date = $DateSelection

# Переменные
var second_table = Request.Tables.SECTIONS # Таблица связанная со вторым выпадающим списком

# Изменение раздела расхода
func set_extra(extra_id: int) -> void: pass

# Изменение значение счета после проведения транзакции
func _update_wallet_value(delete: bool = false) -> void: pass

# Создание сцены
func _ready() -> void:
	if table == Request.Tables.WALLETS: table = Request.Tables.CASH_FLOWS # Смена связанной таблицы
	# Заполнение выпадающих списков
	Global.fill_optionButton(Wallet, Request.select(Request.Tables.WALLETS))
	Global.fill_optionButton(Extra, Request.select(second_table))
	set_wallet(1)
	set_extra(1)
	
func _get_extra_name() -> String:
	var name = Global.enum_key(Request.Tables, second_table)
	name[-1] = "_"
	return name + "id"
	
# Изменение объекта
func set_object(obj_id: int, parent = null) -> void:
	match parent:
		Request.Tables.WALLETS: set_wallet(obj_id) 
		null: set_all(obj_id)
		_: set_extra(obj_id) 

# Изменение информации
func set_all(obj_id) -> void:
	var value: Array = _get_obj_data(obj_id)
	if len(value) <= 0: return
	set_wallet(value[0].wallet_id)
	set_extra(value[0][_get_extra_name()])
	Value.set_text(str(value[0].value))
	Note.set_text(value[0].note)
	Date.set_date(value[0].date)

# Изменение счета
func set_wallet(wallet_id: int) -> void:
	Wallet.selected = wallet_id - 1
	Count.set_text(str(Request.select(Request.Tables.WALLETS, "*", "id="+str(wallet_id))[0].value))

# Изменение значение счета после проведения транзакции
func _extra_errors() -> bool: return Error.visible

# Проверка заполнености полей
func check_object() -> bool:
	Error.visible = false
	if Value.get_text() == "": Global.set_error(Error, "Значение не должно быть пустым")
	elif float(Value.get_text()) <= 0: Global.set_error(Error, "Значение должно быть больше нуля")
	elif float(Count.get_text())-float(Value.get_text()) < 0: Global.set_error(Error, "На счету недостаточно средств")
	return _extra_errors()

# Изменение значения движения средств
func _on_value_text_changed() -> void:
	Global.text_changed_TextEdit(Value, true)
	check_object()

# Изменение выбранного счета
func _on_wallet_item_selected(index: int) -> void: set_wallet(index + 1)

# Изменение выбранного раздела
func _on_extra_item_selected(index: int) -> void: set_extra(index + 1)

# Обработка нажатия кнопки сохранения / изменения
func _on_apply_button_down() -> void:
	if check_object(): return
	_update_wallet_value()
	var values: Array = [Wallet.selected+1, Extra.selected+1, float(Value.get_text()), '"'+Date.get_date()+'"', '"'+Note.get_text()+'"']
	if id:
		set_all(id)
		_update_wallet_value(true)
	_create_update(values)

# Обработка нажатия кнопки удаления
func _on_delete_button_down() -> void:
	set_all(id)
	_update_wallet_value(true)
	super._on_delete_button_down()
