extends Control
# Подключение путей к объектам в сцене
@onready var FilterTitle = $Filters/Title
@onready var FilterYear = $Filters/Year
@onready var FilterMonth = $Filters/Month
@onready var FilterConsumptionIncome = $Filters/ConsumptionIncome
@onready var Objects = $ObjArray

# Стартовое применение фильтров
func _ready() -> void:
	_on_year_item_selected(-1)
	FilterMonth.selected = Time.get_datetime_dict_from_system().month - 1

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
	var filter_text = Request.add_part_request_with_check("", "s.title", FilterTitle.get_text(), "LIKE")
	match FilterConsumptionIncome.selected:
		1:
			filter_text = Request.add_part_request(filter_text, "s.month_limit", 0, ">=")
			filter_text = Request.add_part_request(filter_text, "s.income", 0)
		2: filter_text = Request.add_part_request(filter_text, "s.income", 1)
		3: filter_text = Request.add_part_request(filter_text, "s.month_limit", -1)
	Objects.set_data("", filter_text, "", "-".join([Global.get_OB_text(FilterYear), FilterMonth.selected+1, 1]))

# Обработка нажатия кнопки применения фильтров
func _on_filter_button_down() -> void: _set_filters()
	
# Обработка нажатия кнопки создания нового счета
func _on_add_sections_button_down() -> void: Global.emit_signal("open_window", Global.Pages.SECTION)

# Обработка нажатия кнопки создания движения средств
func _on_cash_flow_button_down() -> void:
	if len(Request.select(Request.Tables.WALLETS)) != 0 and Objects.obj_count > 2:
		Global.emit_signal("open_window", Global.Pages.CASH_FLOW)
