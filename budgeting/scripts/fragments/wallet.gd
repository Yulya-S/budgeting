extends PageFragment
# Подключение путей к объектам в сцене
@onready var Value = $Value
@onready var CashFlow = $CashFlow

# Изменение значений
func set_values(data: Dictionary) -> void:
	Title.set_object(data.title, data.id)
	Value.set_text(str(data.value))
	CashFlow.set_text(str(Request.select_wallets_movement(data.id)[0]))
