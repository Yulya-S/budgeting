extends Control
# Подключение путей к объектам в сцене
@onready var Objects = $ObjArray

# Обработка нажатия кнопки создания нового счета
func _on_add_wallet_button_down() -> void: Global.emit_signal("open_window", Global.Pages.WALLET)

# Обработка нажатия кнопки создания движения средств
func _on_cash_flow_button_down() -> void: Global.emit_signal("open_window", Global.Pages.CASH_FLOW)

# Обработка нажатия кнопки переноса средств между счетами
func _on_transaction_button_down() -> void: if Objects.obj_count() > 1: Global.emit_signal("open_window", Global.Pages.TRANSFER)
