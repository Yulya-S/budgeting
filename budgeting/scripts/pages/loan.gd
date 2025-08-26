extends Control
# Подключение пути к объектам в сцене
#@onready var Total = $Total
@onready var Objects = $ObjArray

# Подключение сигнала
func _ready() -> void: Global.emit_signal("update_page")

# Изменение значения итоговой суммы по счетам
# func update_page() -> void: Total.set_text(str(Request.select(Request.Tables.LOANS, "COALESCE(SUM(total), 0) value")[0].value))

# Обработка нажатия кнопки создания нового займа
func _on_add_loan_button_down() -> void: Global.emit_signal("open_window", Global.Pages.LOAN)

## Обработка нажатия кнопки создания движения средств
#func _on_cash_flow_button_down() -> void:
	#if Request.select_possibility_opening_cashFlow(): Global.emit_signal("open_window", Global.Pages.CASH_FLOW)
#
## Обработка нажатия кнопки переноса средств между счетами
#func _on_transaction_button_down() -> void:
	#if Objects.obj_count() > 1: Global.emit_signal("open_window", Global.Pages.TRANSFER)
