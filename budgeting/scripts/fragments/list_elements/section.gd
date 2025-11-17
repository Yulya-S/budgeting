extends PageFragment
# Подключение путей к объектам в сцене
@onready var Title = $Title
@onready var Marker = $Marker
@onready var Progress = $Progress
@onready var MonthLimit = $Month_Limit
@onready var ConsumptionIncome = $ConsumptionIncome
@onready var Page = $"../../../"

# Переменная
var m_index: int = 0 # Индекс объекта для изменения цветового маркера

# Изменение значений
func set_values(data: Dictionary) -> void:
	super.set_values(data)
	if data.month_limit <= 0 or data.income: MonthLimit.set_text("")
	m_index = get_parent().get_child_count() - 2
	# Отображение типа статьи
	if data.income: ConsumptionIncome.set_text("Доход")
	elif data.month_limit > 0: ConsumptionIncome.set_text("Расход")
	Progress.visible = ConsumptionIncome.get_text() == "Расход"
	
# Обработка наведения мыши на контейнер
func _on_mouse_entered() -> void:
	if Title.id and Page.get("highlighting_graph_sections"): Page.highlighting_graph_sections(m_index)

func _on_mouse_exited() -> void:
	if Title.id and Page.get("highlighting_graph_sections"): Page.highlighting_graph_sections(m_index, false)
