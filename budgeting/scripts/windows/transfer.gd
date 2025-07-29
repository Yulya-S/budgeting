extends Movement

# Создание сцены
func _ready() -> void:
	super._ready()
	set_extra(1)

# Изменение раздела расхода
func set_extra(extra_idx: int = 0) -> void: Extra.selected = extra_idx

# Проведение дополнительных проверок на верность данных
func _extra_errors() -> bool:
	if Wallet.selected == Extra.selected: Global.set_error(Error, "Нельзя перевести средства на тот же счет")
	return Error.visible

# Изменение значение счета после проведения транзакции
func _update_wallet_value(delete: bool = false) -> void:
	var income = -1
	if delete: income = 1
	Request.update(Request.Tables.WALLETS, "value=value+"+str(income*float(Value.get_text())), "id="+str(Global.get_OB_id(Wallet)))
	Request.update(Request.Tables.WALLETS, "value=value+"+str(income*float(Value.get_text())*-1), "id="+str(Global.get_OB_id(Extra)))

# Создание или изменение объекта
func _create_update(values: Array) -> void:
	values[1] = 1
	super._create_update(values)
	values[2] *= -1
	if id: Request.update_record(table, id+1, values)
	else: Request.insert_record(table, values)

# Обработка нажатия кнопки удаления
func _on_delete_button_down() -> void:
	Request.delete(table, id+1)
	super._on_delete_button_down()
