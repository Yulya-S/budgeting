extends Movement
# Подключение пути к объектам в сцене
@onready var Total = $Extra/Total

# Создание сцены
func _ready() -> void:
	super._ready()
	Global.fill_optionButton(Extra, Request.select(second_table, "*", "total>0"))

# Проведение дополнительных проверок на верность данных
func _extra_errors() -> bool:
	if float(Count.get_text())-float(Value.get_text()) < 0: Error.set_state(Error.States._E06)
	elif float(Total.get_text())-float(Value.get_text()) < 0: Error.set_state(Error.States._E07)
	return Error.visible
	
# Изменение раздела расхода
func set_extra(extra_idx: int = 0) -> void:
	Extra.selected = Request.select(Request.Tables.LOANS, "COUNT(id) id", "total>0 and id<"+str(extra_idx))[0].id
	Total.set_text(str(Request.select(second_table, "total", "id="+str(Global.get_OB_id(Extra)))[0].total))	

# Изменение значение счета после проведения транзакции
func _update_wallet_value(delete: bool = false) -> void:
	var income: int = -1 if not delete else 1
	Request.update(Request.Tables.WALLETS, "value=value+"+str(income*float(Value.get_text())), "id="+str(Global.get_OB_id(Wallet)))
	Request.update(second_table, "total=total+"+str(income*float(Value.get_text())), "id="+str(Global.get_OB_id(Extra)))

# Получение значений из контейнеров окна создания объекта
func get_values() -> Array:
	var values: Array = super.get_values()
	values.insert(2, 3)
	return values
