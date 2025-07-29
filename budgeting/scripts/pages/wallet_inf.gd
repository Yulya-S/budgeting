extends Control
# Подключение путей к объектам в сцене
@onready var Title = $Wallet/Title
@onready var Value = $Wallet/Value
@onready var Objects = $ObjArray
@onready var TotalCount = $Total/Count
@onready var TotalValue = $Total/Value

# Переменные
var id = null # Индекс счета

# Смена индекса объекта
func set_object(obj_id: int, _parent = null) -> void:
	id = obj_id
	Objects.set_data("", "id="+str(id))

# Заполнение данных на странице
func update_page() -> void:
	if not id: return
	# Заполнение информации о кошельке
	var wallet_value: Array = Request.select(Request.Tables.WALLETS, "*", "id="+str(id))
	Title.set_text(wallet_value[0].title)
	Value.set_text(str(wallet_value[0].value))
	# Заполнение информации о движениях средств
	var cash_flow: Dictionary = Request.select_total_cash_flow(id)
	var total_v: float = Request.select_total_v(id)
	TotalValue.set_text(str(total_v))
	TotalCount.set_text(str(cash_flow.count))

# Обработка нажатия кнопки возврата к списку счетов
func _on_back_button_down() -> void:
	self.queue_free()
	get_parent().remove_child(self)
	Global.emit_signal("update_page")

# Обработка нажатия кнопки изменения счета
func _on_update_button_down() -> void: Global.emit_signal("open_window", Global.Pages.WALLET, id)

# Обработка нажатия кнопки добавления движения средств
func _on_cash_flow_button_down() -> void: Global.emit_signal("open_window", Global.Pages.CASH_FLOW, id, Global.Dirs.WINDOWS, Request.Tables.WALLETS)
