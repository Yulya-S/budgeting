extends Page
# Подключение путей к объектам в сцене
@onready var Filter = $Filter
@onready var FilterWallet = $Filter/Wallet
@onready var FilterSection = $Filter/Section
@onready var Schedule = $DailyTransactions

# Подключение сигнала
func _ready() -> void:
	Filter.set_OB_items(Request.Tables.WALLETS) # Заполнение списка кошельков
	super._ready()
	
# Запуск обновления данных на странице
func _update_page() -> void:
	# Изменение списка разделов что бы при смене языка названия разделов переводились
	var save_selected_section: int = FilterSection.selected
	Filter.set_OB_items(Request.Tables.SECTIONS) # Заполнение списка разделов
	FilterSection.selected = save_selected_section
	File.set_OB_elements(FilterSection) # Применение перевода для списка разделов
	super._update_page() # Обновление данных на странице
	
# Обновление данных
func update_date() -> void:
	super.update_data()
	Schedule.update_schedule(Filter)
	
# Изменение значений фильтрации извне
func set_object(obj_id, _parent = null) -> void:
	if obj_id is Array:
		Filter.set_filter(FilterWallet, obj_id[0])
		Filter.set_filter(FilterSection, obj_id[1])
	else: Filter.set_filter(FilterWallet, obj_id)
	Filter.get_filter()

# Обработка нажатия кнопки создания движения средств
func _on_cash_flow_button_down() -> void:
	if Request.select_possibility_opening_cashFlow():
		if FilterWallet.selected > 0 and FilterSection.selected > 4: Global.emit_signal("open_window", Global.Pages.CASH_FLOW, [Global.get_OB_id(FilterWallet)-1, Global.get_OB_id(FilterSection)-1])
		elif FilterWallet.selected > 0: Global.emit_signal("open_window", Global.Pages.CASH_FLOW, Global.get_OB_id(FilterWallet)-1, Global.Dirs.WINDOWS, Request.Tables.WALLETS)
		elif FilterSection.selected > 4: Global.emit_signal("open_window", Global.Pages.CASH_FLOW, Global.get_OB_id(FilterSection)-1, Global.Dirs.WINDOWS, Request.Tables.SECTIONS)
		else: Global.emit_signal("open_window", Global.Pages.CASH_FLOW)

# Обработка нажатия кнопки переноса средств между счетами
func _on_transaction_button_down() -> void:
	if len(Request.select(Request.Tables.WALLETS)) > 1:
		if FilterWallet.selected > 0: Global.emit_signal("open_window", Global.Pages.TRANSFER, Global.get_OB_id(FilterWallet)-1, Global.Dirs.WINDOWS, Request.Tables.WALLETS)
		else: Global.emit_signal("open_window", Global.Pages.TRANSFER)
