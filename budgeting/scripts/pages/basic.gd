extends Node2D
@onready var Wallets = $ColorRect/Wallets/ScrollContainer/VBoxContainer
var wallet_path = load("res://scenes/fragments/wallet.tscn")

# Создание главной страницы
func _ready() -> void: add_wallets()

# Заполнение списка счетов
func add_wallets():
	var wallets_array: Array = Requests.get_wallets()
	for i in wallets_array:
		Wallets.add_child(wallet_path.instantiate())
		Wallets.get_child(-1).set_values(i)
		
