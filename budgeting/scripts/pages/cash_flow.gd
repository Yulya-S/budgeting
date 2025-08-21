extends Control
# Подключение путей к объектам в сцене
@onready var FilterWallet = $Filters/Wallet
@onready var FilterSection = $Filters/Section
@onready var FilterYear = $Filters/Year
@onready var FilterMonth = $Filters/Month
@onready var Objects = $ObjArray
@onready var Schedule = $Schedule

# Переменная
var data = {"where": "", "date": Time.get_datetime_string_from_system()}

# Стартовое применение фильтров
func _ready() -> void:
	Global.fill_optionButton(FilterSection, Request.select(Request.Tables.SECTIONS), false)
	Global.fill_optionButton(FilterWallet, Request.select(Request.Tables.WALLETS), false)
	_on_year_item_selected(-1)
	FilterMonth.selected = Time.get_datetime_dict_from_system().month - 1
	Global.emit_signal("update_page")
	
# Изменение значений фильтрации извне
func set_object(obj_id, parent = null) -> void:
	if obj_id is Array:
		FilterWallet.selected = obj_id[0]
		FilterSection.selected = obj_id[1]
	else:
		match parent:
			Global.Pages.WALLET_INF: FilterWallet.selected = obj_id
	_set_filters()

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
	data.where = ""
	if FilterWallet.selected != 0:
		data.where = "(section_id=1 AND wallet_2_id="+str(Global.get_OB_id(FilterWallet))+")"
		data.where = Request.add_part_request(data.where, "wallet_id", Global.get_OB_id(FilterWallet), "=", " OR ")
	if FilterSection.selected != 0: data.where = Request.add_part_request("("+data.where+")", "section_id", Global.get_OB_id(FilterSection))
	data.date = Global.date_to_sql_date("-".join([Global.get_OB_text(FilterYear), FilterMonth.selected+1, 1]))
	Objects.set_data(data.where, data.date)
	Schedule.update_schedule(data.where, data.date)

# Обработка нажатия кнопки применения фильтров
func _on_filter_button_down() -> void: _set_filters()

# Обработка нажатия кнопки создания движения средств
func _on_cash_flow_button_down() -> void:
	if Request.select_possibility_opening_cashFlow():
		if FilterWallet.selected > 0 and FilterSection.selected > 3:
			Global.emit_signal("open_window", Global.Pages.CASH_FLOW, [Global.get_OB_id(FilterWallet)-1, Global.get_OB_id(FilterSection)-1])
		elif FilterWallet.selected > 0: Global.emit_signal("open_window", Global.Pages.CASH_FLOW, Global.get_OB_id(FilterWallet)-1, Global.Dirs.WINDOWS, Request.Tables.WALLETS)
		elif FilterSection.selected > 3: Global.emit_signal("open_window", Global.Pages.CASH_FLOW, Global.get_OB_id(FilterSection)-1, Global.Dirs.WINDOWS, Request.Tables.SECTIONS)
		else: Global.emit_signal("open_window", Global.Pages.CASH_FLOW)

# Обработка нажатия кнопки переноса средств между счетами
func _on_transaction_button_down() -> void:
	if Objects.obj_count() > 1:
		if FilterWallet.selected > 0: Global.emit_signal("open_window", Global.Pages.TRANSFER, Global.get_OB_id(FilterWallet)-1, Global.Dirs.WINDOWS, Request.Tables.WALLETS)
		else: Global.emit_signal("open_window", Global.Pages.TRANSFER)
