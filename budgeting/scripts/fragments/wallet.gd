extends Control
@onready var Title = $Title
@onready var Value = $Value
@onready var CashFlow = $CashFlow

# Изменение значений
func set_values(data: Dictionary) -> void:
	Title.set_text(data.title)
	Value.set_text(str(data.value))
