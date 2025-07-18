extends Control
# Подключение путей к объектам в сцене
@onready var Wallets = $ScrollContainer/VBoxContainer

# Путь к подгружаемой сцене транзакции
var wallet_path = load("res://scenes/fragments/wallet.tscn")

# Переменная
var lines: Array = [] # Список объектов для создания на странице

# Подключение сигналов
func _ready() -> void:
	Global.connect("update_page", Callable(self, "_update_page"))
	_update_page()

# Динамическое заполнение страницы
func _process(_delta: float) -> void:
	if len(lines) > 0:
		Wallets.add_child(wallet_path.instantiate())
		Wallets.get_child(-1).set_values(lines.pop_front())

# Заполнение страницы
func _update_page() -> void:
	for i in Wallets.get_children():
		i.queue_free()
		Wallets.remove_child(i)
	lines = Request.select(Request.Tables.WALLETS)

# Обработка нажатия кнопки создания нового счета
func _on_add_wallet_button_down() -> void: Global.emit_signal("open_window", Global.Pages.WALLET)

# Обработка нажатия кнопки создания движения средств
func _on_cash_flow_button_down() -> void: Global.emit_signal("open_window", Global.Pages.CASH_FLOW)

# Обработка нажатия кнопки переноса средств между счетами
func _on_transaction_button_down() -> void:
	if Wallets.get_child_count() > 1: Global.emit_signal("open_window", Global.Pages.TRANSFER)
