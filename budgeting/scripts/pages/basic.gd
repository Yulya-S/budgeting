extends Control
# Подключение путей к объектам в сцене
@onready var Budget = $ColorRect/Budget/Value
@onready var Objects = $ColorRect/Wallets/ObjArray

# Создание главной страницы
func _ready() -> void:
	Budget.set_text(str(Request.select(Request.Tables.WALLETS, "SUM(value) value")[0].value))
	Budget.set_text(str(float(Budget.get_text()) - Request.select(Request.Tables.LOANS, "SUM(total) value")[0].value))
		
