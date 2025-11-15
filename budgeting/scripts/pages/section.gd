extends Control
# Подключение путей к объектам в сцене
@onready var Filter = $Filter
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
	Filter.get_filter()
	Objects.data_update()

# Изменение данных на графике
func update_page(_close_page: String = ""): PieChart.set_values(Request.select_sections(Filter.filter.where, Filter.filter.date, Filter.filter.order))
	
# Обработка нажатия кнопки создания нового счета
func _on_add_sections_button_down() -> void: Global.emit_signal("open_window", Global.Pages.SECTION)

# Обработка нажатия кнопки создания движения средств
func _on_cash_flow_button_down() -> void:
	if Request.select_possibility_opening_cashFlow(): Global.emit_signal("open_window", Global.Pages.CASH_FLOW)
