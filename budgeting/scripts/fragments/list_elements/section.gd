extends PageFragment
# Подключение путей к объектам в сцене
@onready var Title = $Title
@onready var Marker = $Marker
@onready var Border = $Border
@onready var MonthLimit = $Month_Limit
@onready var ConsumptionIncome = $ConsumptionIncome
@onready var PieChart = $"../../../PieChart"

# Переменная
var m_index: int = 0 # Индекс объекта для изменения цветового маркера

# Изменение значений
func set_values(data: Dictionary) -> void:
	super.set_values(data)
	if data.month_limit <= 0: MonthLimit.set_text("")
	m_index = get_parent().get_child_count() - 2
	Marker.visible = PieChart.visible
	Marker.color = ColorScheme.get_color(m_index, len(PieChart.values) - 1)
	# Отображение типа статьи
	if data.income: ConsumptionIncome.set_text("Доход")
	elif data.month_limit > 0: ConsumptionIncome.set_text("Расход")
	Border.visible = ConsumptionIncome.get_text() == "Расход"
	# Заполнение шкалы перерасхода
	if Border.visible:
		Border.get_child(0).size.x = (Border.size.x * data.value) / data.month_limit
		if Border.size.x < Border.get_child(0).size.x: Border.get_child(0).size.x = Border.size.x
		Border.get_child(0).color = ColorScheme.get_color(Border.get_child(0).size.x, Border.size.x, ColorScheme.scales_gradient)

# Обработка наведения мыши на контейнер
func _on_mouse_entered() -> void: if Title.id: PieChart.set_highlighter(m_index)

func _on_mouse_exited() -> void: if Title.id: PieChart.reset_highlighter(m_index)
