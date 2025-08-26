extends Control
# Подключение путей к объектам в сцене
@onready var Filter = $Filter
@onready var FilterWallet = $Filter/Wallet
@onready var FilterSection = $Filter/Section
@onready var Objects = $ObjArray
@onready var Schedule = $Schedule

# Стартовое применение фильтров
func _ready() -> void:
	for i in [Request.Tables.SECTIONS, Request.Tables.WALLETS]: Filter.set_OB_items(i)
	Filter.get_filter()
	Global.emit_signal("update_page")
	
# Изменение значений фильтрации извне
func set_object(obj_id, _parent = null) -> void:
	if obj_id is Array:
		Filter.set_filter(FilterWallet, obj_id[0])
		Filter.set_filter(FilterSection, obj_id[1])
	else: Filter.set_filter(FilterWallet, obj_id)
	Filter.get_filter()

# Применение фильтров
func set_filter() -> void:
	if not Filter: return
	Schedule.update_schedule(Filter.filter.where, Filter.filter.date)

## Обработка нажатия кнопки создания движения средств
#func _on_cash_flow_button_down() -> void:
	#if Request.select_possibility_opening_cashFlow():
		#if FilterWallet.selected > 0 and FilterSection.selected > 3:
			#Global.emit_signal("open_window", Global.Pages.CASH_FLOW, [Global.get_OB_id(FilterWallet)-1, Global.get_OB_id(FilterSection)-1])
		#elif FilterWallet.selected > 0: Global.emit_signal("open_window", Global.Pages.CASH_FLOW, Global.get_OB_id(FilterWallet)-1, Global.Dirs.WINDOWS, Request.Tables.WALLETS)
		#elif FilterSection.selected > 3: Global.emit_signal("open_window", Global.Pages.CASH_FLOW, Global.get_OB_id(FilterSection)-1, Global.Dirs.WINDOWS, Request.Tables.SECTIONS)
		#else: Global.emit_signal("open_window", Global.Pages.CASH_FLOW)
#
## Обработка нажатия кнопки переноса средств между счетами
#func _on_transaction_button_down() -> void:
	#if Objects.obj_count() > 1:
		#if FilterWallet.selected > 0: Global.emit_signal("open_window", Global.Pages.TRANSFER, Global.get_OB_id(FilterWallet)-1, Global.Dirs.WINDOWS, Request.Tables.WALLETS)
		#else: Global.emit_signal("open_window", Global.Pages.TRANSFER)
