extends CreationWindow
class_name Movement
# Подключение путей к объектам в сцене
@onready var Count = $Count
@onready var Wallet = $Wallet_Id
@onready var Extra = $Extra
@onready var Value = $Value

# Экспортируемая переменная
@export var second_table: Request.Tables = Request.Tables.SECTIONS # Таблица связанная со вторым выпадающим списком
@export var second_column: String = "section_id"

# Заполнение выпадающих списков
func _ready() -> void:
	Global.fill_optionButton(Wallet, Request.select(Request.Tables.WALLETS))
	Global.fill_optionButton(Extra, Request.select(second_table))
	_on_wallet_item_selected(0, false)
	_on_extra_item_selected(0, false)
	
# Изменение объекта
func set_object(obj_id: Variant, parent: Variant = null) -> void:
	if obj_id is Array:
		_on_wallet_item_selected(obj_id[0], false)
		_on_extra_item_selected(obj_id[1], false)
		return
	match parent:
		Request.Tables.WALLETS:	_on_wallet_item_selected(obj_id, false) 
		null: set_all(obj_id)
		_: _on_extra_item_selected(obj_id, false) 

# Изменение всей информации об объекте
func set_all(obj_id: int) -> void:
	id = obj_id
	Delete.visible = true
	var value: Array = Request.select(table, "*", "id="+str(id))
	if len(value) < 0: return
	set_values(value[0])
	
# Изменение данных на странице
func set_values(data: Dictionary) -> void:
	for i in get_children():
		if i.name.to_lower() not in data.keys() + ["extra"]: continue
		match i.get_class():
			"TextEdit": i.set_text(str(data[i.name.to_lower()]))
			"ColorRect": if i.name == "Date": i.set_date(data[i.name.to_lower()])
			"OptionButton":
				if i.name == "Extra": _on_extra_item_selected(data[second_column] - 1, false)
				else: _on_wallet_item_selected(data.wallet_id - 1, false)

# Проверка заполненности полей
func check_object() -> bool:
	super.check_object()
	if float(Value.get_text()) <= 0: Error.set_state(Error.States._E05)
	return _extra_errors()
	
# Проведение дополнительных проверок на верность данных
func _extra_errors() -> bool: return Error.visible

# Изменение выбранного счета
func _on_wallet_item_selected(index: int = 0, check: bool = true) -> void:
	Wallet.selected = index
	set_wallet(index)
	if check: check_object()

# Изменение информации о счете
func set_wallet(_wallet_idx: int = 0) -> void:
	Count.set_text(str(Request.select(Request.Tables.WALLETS, "*", "id="+str(Global.get_OB_id(Wallet)))[0].value))

# Изменение выбранного дополнительного параметра
func _on_extra_item_selected(index: int = 0, check: bool = true) -> void:
	Extra.selected = index
	set_extra(index)
	if check: check_object()

# Изменение информации о дополнительном параметре
func set_extra(_extra_idx: int = 0) -> void: pass

# Проведение обратной операции
func _back_wallet_value() -> void:
	set_all(id)
	_update_wallet_value(true)
	
# Изменение значение счета после проведения транзакции
func _update_wallet_value(_delete: bool = false) -> void: pass

# Создание или изменение объекта
func create_update() -> void:
	var values: Array = get_values()
	_update_wallet_value()
	if id: _back_wallet_value()
	if id: Request.update_record(table, id, values)
	else: Request.insert_record(table, values)
	
# Получение значений из контейнеров окна создания объекта
func get_values() -> Array: return super.get_values()
	
# Обработка нажатия кнопки удаления
func delete_obj() -> void:
	_back_wallet_value()
	Request.delete(table, id)
