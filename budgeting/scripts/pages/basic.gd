extends Control
# Подключение путей к объектам в сцене
@onready var Budget = $ColorRect/Budget/Value
@onready var Objects = $ColorRect/Wallets/ObjArray

# Создание главной страницы
func _ready() -> void:
	Budget.set_text(str(Request.select_value(Request.Tables.WALLETS, "SUM(value) value")))
	Budget.set_text(str(float(Budget.get_text()) - Request.select_value(Request.Tables.LOANS, "SUM(total) value")))
		
