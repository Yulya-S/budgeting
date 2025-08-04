extends Movement
# Подключение пути к объектам в сцене
@onready var ConsumptionIncome = $Extra/ConsumptionIncome

# Заполнение выпадающих списков
func _ready() -> void:
	super._ready()
	Global.fill_optionButton(Extra, Request.select(second_table, "*", "id>2"))

# Проведение дополнительных проверок на верность данных
func _extra_errors() -> bool:
	if ConsumptionIncome.get_text() == "Расход" and float(Count.get_text())-float(Value.get_text()) < 0:
		Global.set_error(Error, "На счету недостаточно средств")
	return Error.visible

# Изменение раздела расхода
func set_extra(extra_idx: int = 0) -> void:
	Extra.selected = extra_idx
	if Request.select(second_table, "income", "id="+str(Global.get_OB_id(Extra)))[0].income: ConsumptionIncome.set_text("Доход")
	else: ConsumptionIncome.set_text("Расход")

# Изменение значение счета после проведения транзакции
func _update_wallet_value(delete: bool = false) -> void:
	var income = int(ConsumptionIncome.get_text() == "Доход")
	if delete: income = int(not bool(income))
	if income == 0: income = -1
	Request.update(Request.Tables.WALLETS, "value=value+"+str(income*float(Value.get_text())), "id="+str(Global.get_OB_id(Wallet)))
