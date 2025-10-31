extends Movement

# Создание сцены
func _ready() -> void:
	super._ready()
	_on_extra_item_selected(1, false)
	
# Проведение дополнительных проверок на верность данных
func _extra_errors() -> bool:
	if float(Count.get_text())-float(Value.get_text()) < 0: Error.set_state(Error.States._E06)
	return Error.visible

# Изменение информации о счете
func set_wallet(wallet_idx: int = 0) -> void:
	super.set_wallet(wallet_idx)
	# Автоматическая смена счета
	Extra.selected = 0 if wallet_idx + 1 >= Extra.item_count else wallet_idx + 1

# Изменение раздела расхода
func set_extra(extra_idx: int = 0) -> void:
	# Автоматическая смена счета
	Wallet.selected = Wallet.item_count - 1 if extra_idx == 0 else extra_idx - 1

# Изменение значение счета после проведения транзакции
func _update_wallet_value(delete: bool = false) -> void:
	var income = -1
	if delete: income = 1
	Request.update(Request.Tables.WALLETS, "value=value+"+str(income*float(Value.get_text())), "id="+str(Global.get_OB_id(Wallet)))
	Request.update(Request.Tables.WALLETS, "value=value+"+str(income*float(Value.get_text())*-1), "id="+str(Global.get_OB_id(Extra)))

# Получение значений из контейнеров окна создания объекта
func get_values() -> Array:
	var values: Array = super.get_values()
	values.insert(2, 1)
	return values
