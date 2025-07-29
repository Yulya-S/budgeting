extends PageFragment
# Подключение путей к объектам в сцене
@onready var Value = $Value
@onready var CashFlow = $CashFlow

# Изменение значений
func set_values(data: Dictionary) -> void:
	id = data.id
	Title.set_text(data.title)
	Value.set_text(str(data.value))
	CashFlow.set_text(str(Request.select_total_cash_flow(id).value))
