extends Node2D
@onready var Wallets = $Background/ScrollContainer/VBoxContainer
var wallet_path = load("res://scenes/fragments/wallet.tscn")

# Подключение сигналов
func _ready() -> void:
	Global.connect("update_page", Callable(self, "_update_page"))
	_update_page()

# Заполнение страницы
func _update_page():
	for i in Wallets.get_children():
		i.queue_free()
		Wallets.remove_child(i)
	var wallets_array: Array = Request.get_wallets()
	for i in wallets_array:
		Wallets.add_child(wallet_path.instantiate())
		Wallets.get_child(-1).set_values(i)

# Обработка нажатия кнопки создания нового счета
func _on_add_wallet_button_down() -> void: Global.emit_signal("open_window", Global.Pages.WALLET)
