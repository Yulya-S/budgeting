extends Fragment
# Подключение путей к объектам в сцене
@onready var Title = $Title
@onready var ParentPage = $"../../../"
# Переменная
var m_index: int = 0 # Индекс объекта для изменения цветового маркера

# Изменение значений
func set_values(data: Dictionary) -> void:
	super.set_values(data)
	$ConsumptionIncome.set_text("" if data.id <= 4 else "__CI" + str(data.income))
	$Progress.visible = not data.income and data.month_limit > 0
	$Marker.size[1] = custom_minimum_size[1]
	if data.month_limit <= 0 or data.income: $Month_Limit.set_text("")
	m_index = get_parent().get_child_count() - 2
	File.set_lang(self)
	
# Обработка наведения мыши на контейнер
func _on_mouse_entered() -> void: if Title.id: Global.run_func(ParentPage, "highlighting_graph_sections", [m_index])

func _on_mouse_exited() -> void: if Title.id: Global.run_func(ParentPage, "highlighting_graph_sections", [m_index, false])
