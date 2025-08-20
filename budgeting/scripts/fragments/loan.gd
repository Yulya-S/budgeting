extends PageFragment
# Подключение путей к объектам в сцене
@onready var WalletTitle = $WalletTitle
@onready var Value = $Value
@onready var Total = $Total

# Изменение значений
func set_values(data: Dictionary) -> void:
	var start_inf: Dictionary = Request.select("cash_flows cf", "cf.*, w.title title", "section_id=3 AND wallet_2_id="+str(data.id), "", "wallets w ON cf.wallet_id=w.id")[0]
	Title.set_object(data.title, data.id)
	WalletTitle.set_object(start_inf.title, start_inf.wallet_id)
	Value.set_text(str(start_inf.value))
	Total.set_text(str(data.total))
