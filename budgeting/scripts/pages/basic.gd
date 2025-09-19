extends Control
# Подключение путей к объектам в сцене
@onready var Budget = $Menu/Budget
@onready var CashFlow = $Menu/CashFlow

# Создание главной страницы
func _ready() -> void:
	Budget.set_text(str(Request.select_budget()))
	CashFlow.set_text(str(Request.select_general_wallets_movement()))
	Global.emit_signal("update_page")
