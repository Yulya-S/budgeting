extends Control
# Подключение пути к объектам в сцене
@onready var Objects = $ObjArray

# Подключение сигнала
func _ready() -> void: Global.emit_signal("update_page")

# Обработка нажатия кнопки создания нового займа
func _on_add_loan_button_down() -> void:
	if len(Request.select(Request.Tables.WALLETS)) > 0: Global.emit_signal("open_window", Global.Pages.LOAN)

# Обработка нажатия кнопки погашения займа
func _on_add_payment_button_down() -> void:
	if Request.select_possibility_opening_payment(): Global.emit_signal("open_window", Global.Pages.PAYMENT)

## Обработка нажатия кнопки переноса средств между счетами
#func _on_transaction_button_down() -> void:
	#if Objects.obj_count() > 1: Global.emit_signal("open_window", Global.Pages.TRANSFER)
