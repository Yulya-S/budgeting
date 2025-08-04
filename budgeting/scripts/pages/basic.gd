extends Control
# Подключение путей к объектам в сцене
@onready var Budget = $ColorRect/Budget/Value
@onready var PieChart = $ColorRect/ColorRect/PieChart
@onready var ObjectsSection = $ColorRect/ColorRect/ObjArray

# Создание главной страницы
func _ready() -> void:
	# Заменить вычисление бюджета на запрос к бд
	Budget.set_text(str(Request.select_value(Request.Tables.WALLETS, "SUM(value) value")))
	Budget.set_text(str(float(Budget.get_text()) - Request.select_value(Request.Tables.LOANS, "SUM(total) value")))
	
	ObjectsSection.data.where = "s.income = 0 and s.month_limit > 0"
	PieChart.set_values(Request.select_sections(Time.get_date_string_from_system(), ObjectsSection.data.where))
	Global.emit_signal("update_page")
