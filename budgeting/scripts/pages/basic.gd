extends Control
# Подключение путей к объектам в сцене
@onready var Budget = $Menu/Budget
@onready var CashFlow = $Menu/CashFlow
@onready var ObjectsSection = $ScrollContainer/VBoxContainer/Sections/ObjArray

# Создание главной страницы
func _ready() -> void:
	Budget.set_text(str(Request.select_budget()))
	CashFlow.set_text(str(Request.select_general_wallets_movement()))
	ObjectsSection.data.where = "s.income = 0 and s.month_limit > 0"
	Global.emit_signal("update_page")
