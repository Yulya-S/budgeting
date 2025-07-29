extends Control
# Подключение путей к объектам в сцене
@onready var FilterTitle = $Filters/Title
@onready var FilterYear = $Filters/Year
@onready var FilterMonth = $Filters/Month
@onready var FilterConsumptionIncome = $Filters/ConsumptionIncome
@onready var Objects = $ScrollContainer/VBoxContainer
@onready var PieChart = $PieChart

# Перечисления
var data = {"where": "", "date": Time.get_datetime_string_from_system()}
var lines = []
var obj_path = load("res://scenes/fragments/section.tscn")

# Стартовое применение фильтров
func _ready() -> void:
	_on_year_item_selected(-1)
	FilterMonth.selected = Time.get_datetime_dict_from_system().month - 1
	Global.connect("update_page", Callable(self, "update_page"))
	update_page()
	
# Динамическое заполнение страницы
func _process(_delta: float) -> void:
	if len(lines) > 0:
		Objects.add_child(obj_path.instantiate())
		Objects.get_child(-1).set_values(lines.pop_front())
		Objects.get_child(-1).Marker.color = PieChart.get_color(Objects.get_child(-1).m_index)

# Заполнение страницы
func update_page():
	for i in Objects.get_children():
		i.queue_free()
		Objects.remove_child(i)
	lines = Request.select_sections(data.date, data.where)
	PieChart.set_values(lines)
	Objects.add_child(obj_path.instantiate())
	Objects.get_child(-1).color = Color.html("#dfdfdf")

# Обработка выбора года
func _on_year_item_selected(index: int) -> void:
	var current_year: int = Time.get_datetime_dict_from_system().year
	var year: int = current_year
	if index != -1: year = int(FilterYear.get_item_text(index))
	for i in range(FilterYear.item_count): FilterYear.remove_item(0)
	for i in range(year-10, year+10, 1):
		if i + 1 > current_year: break
		FilterYear.add_item(str(i+1))
	FilterYear.selected = 9

# Применение фильтров
func _set_filters() -> void:
	data.where = Request.add_part_request_with_check("", "s.title", FilterTitle.get_text(), "LIKE")
	match FilterConsumptionIncome.selected:
		1:
			data.where = Request.add_part_request(data.where, "s.month_limit", 0, ">=")
			data.where = Request.add_part_request(data.where, "s.income", 0)
		2: data.where = Request.add_part_request(data.where, "s.income", 1)
		3: data.where = Request.add_part_request(data.where, "s.month_limit", -1)
	data.date = Time.get_datetime_dict_from_datetime_string("-".join([Global.get_OB_text(FilterYear), FilterMonth.selected+1, 1]), false)
	data.date = Time.get_datetime_string_from_datetime_dict(data.date, false)
	update_page()

# Обработка нажатия кнопки применения фильтров
func _on_filter_button_down() -> void: _set_filters()
	
# Обработка нажатия кнопки создания нового счета
func _on_add_sections_button_down() -> void: Global.emit_signal("open_window", Global.Pages.SECTION)

# Обработка нажатия кнопки создания движения средств
func _on_cash_flow_button_down() -> void:
	if len(Request.select(Request.Tables.WALLETS)) != 0 and Objects.obj_count > 2:
		Global.emit_signal("open_window", Global.Pages.CASH_FLOW)
