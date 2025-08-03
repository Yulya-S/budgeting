extends Movement
# Подключение путей к объектам в сцене
@onready var Total = $Extra/Total

# Создание сцены
func _ready() -> void:
	super._ready()
	Global.fill_optionButton(Extra, Request.select(second_table, "*", "total>0"))
	set_extra()

# Изменение раздела расхода
func set_extra(extra_idx: int = 0) -> void:
	Extra.selected = extra_idx
	Total.set_text(str(Request.select(second_table, "total", "id="+str(Global.get_OB_id(Extra)))[0].total))
	
# Проведение дополнительных проверок на верность данных
func _extra_errors() -> bool:
	if float(Total) < float(Value.get_text()): Global.set_error(Error, "Нельзя перевысить значение суммы кредита")
	return Error.visible

# Изменение значение счета после проведения транзакции
func _update_wallet_value(delete: bool = false) -> void:
	var income = -1
	if delete: income = 1
	Request.update(Request.Tables.WALLETS, "value=value+"+str(income*float(Value.get_text())), "id="+str(Global.get_OB_id(Wallet)))
	Request.update(Request.Tables.WALLETS, "total=total+"+str(income*float(Value.get_text())), "id="+str(Global.get_OB_id(Extra)))

# Создание или изменение объекта
func _create_update(values: Array) -> void:
	values[1] = 2
	super._create_update(values)
