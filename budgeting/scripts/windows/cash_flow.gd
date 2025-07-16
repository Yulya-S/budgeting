extends Movement
# Подключение путей к объектам в сцене
@onready var ConsumptionIncome = $Extra/ConsumptionIncome

# Изменение раздела расхода
func set_extra(extra_id: int) -> void:
	Extra.selected = extra_id - 1
	if Request.select(second_table, "income", "id="+str(extra_id))[0].income:
		ConsumptionIncome.set_text("Доход")

# Изменение значение счета после проведения транзакции
func _update_wallet_value(delete: bool = false):
	var income = int(ConsumptionIncome.get_text() == "Доход")
	if delete: income = int(not bool(income))
	if income == 0: income = -1
	Request.update(Request.Tables.WALLETS, "value=value+"+str(income*float(Value.get_text())), "id="+str(Wallet.selected+1))
