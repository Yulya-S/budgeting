extends Page
# Подключение пути к объекту в сцене
@onready var PieChart = $PieChart

# Применение выделений секций на круговой диаграмме
func highlighting_graph_sections(idx: int, set_highlighting: bool = true) -> void:
	if set_highlighting: PieChart.set_highlighter(idx)
	else: PieChart.reset_highlighter(idx)

# Обработка нажатия кнопки создания нового счета
func _on_add_sections_button_down() -> void: Global.emit_signal("open_window", Global.Pages.SECTION)

# Обработка нажатия кнопки создания движения средств
func _on_cash_flow_button_down() -> void:
	if Request.select_possibility_opening_cashFlow(): Global.emit_signal("open_window", Global.Pages.CASH_FLOW)
