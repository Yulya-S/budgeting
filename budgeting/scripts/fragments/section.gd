extends ColorRect
# Подключение путей к объектам в сцене
@onready var Border = $Border
@onready var Value = $Value
@onready var Max = $Max
@onready var ConsumptionIncome = $ConsumptionIncome
@onready var Title = $Title

# Смена размера цветовой линии под размер родителя
func _ready() -> void:
	custom_minimum_size[0] = get_parent().get_parent().size[0]
	update_minimum_size()

# Изменение значений
func set_values(data: Dictionary) -> void:
	var value = Request.select(Request.Tables.CASH_FLOWS, "SUM(value) value", "section_id="+str(data.id)+" AND strftime('%Y-%m', date) = strftime('%Y-%m', DATE())")
	if len(value) == 0 or not value[0].value: value = 0.0
	else: value = value[0].value
	Border.visible = true
	Border.get_child(0).size.x = (Border.size.x * value) / data.month_limit
	if Border.size.x < Border.get_child(0).size.x:
		Border.get_child(0).size.x = Border.size.x
		Border.get_child(0).color = Color.html("#990027")
	elif Border.size.x / 2. <  Border.get_child(0).size.x: Border.get_child(0).color = Color.html("#978800")
	Value.set_text(str(value))
	Max.set_text(str(data.month_limit))
	if data.income: ConsumptionIncome.set_text("Доход")
	else: ConsumptionIncome.set_text("Расход")
	Title.set_text(data.title)
