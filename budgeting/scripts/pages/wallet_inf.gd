extends InfPage
# Подключение пути к объектам в сцене
@onready var Objects = $ObjArray

# Смена индекса объекта
func set_object(obj_id: int, parent: Variant = null) -> void:
	Objects.set_data("id="+str(obj_id))
	super.set_object(obj_id, parent)

# Обработка нажатия кнопки изменения счета
func _on_update_button_down() -> void: Global.emit_signal("open_window", Global.Pages.WALLET, id)

# Обработка нажатия кнопки добавления движения средств
func _on_cash_flow_button_down() -> void: Global.emit_signal("open_window", Global.Pages.CASH_FLOW, id, Global.Dirs.WINDOWS, Request.Tables.WALLETS)

# Обработка нажатия кнопки перехода к списку транзакций
func _on_transactions_button_down() -> void: Global.emit_signal("open_new_page", Global.Pages.CASH_FLOW, id, Global.Pages.WALLET_INF)
