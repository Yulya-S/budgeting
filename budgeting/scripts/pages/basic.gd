extends Control
@onready var Wallets = $ColorRect/Wallets/ScrollContainer/VBoxContainer
@onready var Budget = $ColorRect/Budget/Value
var wallet_path = load("res://scenes/fragments/wallet.tscn")

# Создание главной страницы
func _ready() -> void:
	Budget.set_text(str(Request.select(Request.Tables.WALLETS, "SUM(value) value")[0].value))
	Budget.set_text(str(float(Budget.get_text()) - Request.select(Request.Tables.LOANS, "SUM(total) value")[0].value))
	add_wallets()

# Заполнение списка счетов
func add_wallets():
	var wallets_array: Array = Request.select(Request.Tables.WALLETS)
	for i in wallets_array:
		Wallets.add_child(wallet_path.instantiate())
		Wallets.get_child(-1).set_values(i)
		
