extends Node2D
@onready var Wallets = $Background/ScrollContainer/VBoxContainer
var wallet_path = load("res://scenes/fragments/wallet.tscn")

func _ready() -> void:
	var wallets_array: Array = Request.get_wallets()
	for i in wallets_array:
		Wallets.add_child(wallet_path.instantiate())
		Wallets.get_child(-1).set_values(i)
