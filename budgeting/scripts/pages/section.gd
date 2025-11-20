extends Control
# Подключение путей к объектам в сцене
@onready var Objects = $ObjArray
@onready var PieChart = $PieChart

# Стартовое применение фильтров
func _ready() -> void:
	Global.connect("update_page", Callable(self, "_update_page"))
	_update_page()
	
# Запуск обновления данных на странице
func _update_page() -> void:
	ColorScheme.repainting(self)
	File.set_lang(self)
	update_date()

# Обновление данных
func update_date() -> void:
	Objects.data_update($Filter)
	PieChart.set_values($Filter)

# Применение выделений секций на круговой диаграмме
func highlighting_graph_sections(idx: int, set_highlighting: bool = true) -> void:
	PieChart.set_highlighter(idx) if set_highlighting else PieChart.reset_highlighter(idx)

# Обработка нажатия кнопки создания нового счета
func _on_add_sections_button_down() -> void: Global.emit_signal("open_window", Global.Pages.SECTION)

# Обработка нажатия кнопки создания движения средств
func _on_cash_flow_button_down() -> void:
	if Request.select_possibility_opening_cashFlow(): Global.emit_signal("open_window", Global.Pages.CASH_FLOW)
