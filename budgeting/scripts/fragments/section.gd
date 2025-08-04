extends PageFragment
# Подключение путей к объектам в сцене
@onready var Marker = $Marker
@onready var Border = $Border
@onready var Value = $Value
@onready var Max = $Max
@onready var ConsumptionIncome = $ConsumptionIncome
@onready var PieChart = $"../../../PieChart"

# Переменная
var m_index: int = 0 # Индекс объекта для изменения цветового маркера

# Изменение значений
func set_values(data: Dictionary) -> void:
	id = data.id
	m_index = get_parent().get_child_count() - 2
	Marker.visible = true
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
	Title.set_text(data.title)
	Value.set_text(str(data.value))
	if data.month_limit > 0: Max.set_text(str(data.month_limit))
	else: Max.set_text("")
	
# Обработка нажатия клавиш мыши
func _input(event: InputEvent) -> void:
	if not ConsumptionIncome.get_text(): return
	super._input(event)

# Обработка наведения мыши на контейнер
func _on_mouse_entered() -> void: if id: PieChart.set_highlighter(m_index)

func _on_mouse_exited() -> void: if id: PieChart.reset_highlighter(m_index)
