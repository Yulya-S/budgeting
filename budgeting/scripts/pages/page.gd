extends Control
class_name Page
# Подключение путей к объектам в сцене
@onready var Objects = get_node_or_null("ObjArray")
@onready var Filter = get_node_or_null("Filter")

# Подключение сигнала
func _ready() -> void:
	if Global.current_page == Global.Pages.CASH_FLOW: # Заполнение списка кошельков
		Filter.set_OB_items(Request.Tables.WALLETS)
		Filter.set_OB_items(Request.Tables.SECTIONS)
	Global.connect_signal_update_page(self)

# Применение фильтра если переход на страницу произошел со страницы информации
func set_cash_flow_filter(idx: int, parent: Global.Pages) -> void:
	if parent == Global.Pages.WALLET: $Filter/Wallet.selected = idx
	else: $Filter/Section.selected = idx
	update_data()

# Запуск обновления данных на странице
func _update_page() -> void:
	_match_other_update()
	SF.color_and_lang(self)
	update_data()

# Дополнительные изменения на странице
func _match_other_update() -> void:
	match Global.current_page:
		Global.Pages.BASIC:
			$Menu/Budget.set_text(str(Request.select_wallets_sum()))
			$Menu/CashFlow.set_text(str(Request.select_funds_movements()))
		Global.Pages.EVENT:
			Global.delete_child(self, get_child(-1)) # Удаление предыдущего формата отображения событий
			Global.run_func(self, "_create")
		Global.Pages.CASH_FLOW:
			var save_selected_section: int = $Filter/Section.selected
			Filter.set_OB_items(Request.Tables.SECTIONS) # Заполнение списка разделов
			$Filter/Section.selected = save_selected_section
			File.set_OB_elements($Filter/Section) # Применение перевода для списка разделов

# Обновление данных
func update_data() -> void:
	_run_update()
	if Global.current_page == Global.Pages.BASIC:
		Global.clear_scene(get("Cells"))
		# Отправка запроса на обновление таблицы с событиями
		Request.start_create_multiplied_events_table(Global.date_to_str())
		set("start_update", true)
		Global.run_func(self, "_fc_size_match")
	
# Запуск функции изменения данных
func _run_update(obj: Variant = self) -> void:
	if obj != self: Global.run_func(obj, "update_data", _get_filter(obj))
	for i in obj.get_children(): _run_update(i)
	
# Получение данных фильтра
func _get_filter(obj: Variant) -> Array:
	match Global.current_page:
		Global.Pages.BASIC: return [] if obj.get_parent().name != "Sections" else [{"where":"s.month_limit>=0", "order": "value DESC"}]
		Global.Pages.REPORT:
			var filter_data: Dictionary = Filter.get_filter()
			if "Rep" in obj.get_parent().name: filter_data.where = obj.get_parent().name.replace("Rep", "").to_lower()
			elif obj.get_parent().name == "Sections":
				filter_data.where = "s.month_limit>=0"
				filter_data.order = "value DESC"
			return [filter_data]
	return [Filter]

# Изменение данных после смены дня
func new_day() -> void:
	if Filter: Filter.reset_date_filters()
	$Head.update_date()
	update_data()

# Обработка нажатий кнопок
# Обработка нажатия кнопки создания движения средств
func _on_CashFlow_cash_flow_button_down() -> void:
	Global.emit_signal("open_window", Global.Pages.CASH_FLOW)
	#if Request.select_possibility_opening_cashFlow():
		#if FilterWallet.selected > 0 and FilterSection.selected > 4: Global.emit_signal("open_window", Global.Pages.CASH_FLOW, [Global.get_OB_id(FilterWallet)-1, Global.get_OB_id(FilterSection)-1])
		#elif FilterWallet.selected > 0: Global.emit_signal("open_window", Global.Pages.CASH_FLOW, Global.get_OB_id(FilterWallet)-1, Global.Dirs.WINDOWS, Request.Tables.WALLETS)
		#elif FilterSection.selected > 4: Global.emit_signal("open_window", Global.Pages.CASH_FLOW, Global.get_OB_id(FilterSection)-1, Global.Dirs.WINDOWS, Request.Tables.SECTIONS)
		#else: Global.emit_signal("open_window", Global.Pages.CASH_FLOW)

# Обработка нажатия кнопки переноса средств между счетами
func _on_CashFlow_transaction_button_down() -> void:
	if len(Request.select(Request.Tables.WALLETS)) > 1:
		if $Filter/Wallet.selected > 0: Global.emit_signal("open_window", Global.Pages.TRANSFER, Global.get_OB_id($Filter/Wallet)-1, Global.Dirs.WINDOWS, Request.Tables.WALLETS)
		else: Global.emit_signal("open_window", Global.Pages.TRANSFER)
		
# Обработка нажатия кнопки создания нового займа
func _on_Loan_add_loan_button_down() -> void:
	if len(Request.select(Request.Tables.WALLETS)) > 0: Global.emit_signal("open_window", Global.Pages.LOAN)

# Обработка нажатия кнопки добавления процентов по займу
func _on_Loan_add_interest_button_down() -> void:
	if len(Request.select(Request.Tables.LOANS, "*", "total>0")) > 0: Global.emit_signal("open_window", Global.Pages.PERCENT)

# Обработка нажатия кнопки погашения займа
func _on_Loan_add_payment_button_down() -> void:
	if Request.select_possibility_opening_payment(): Global.emit_signal("open_window", Global.Pages.PAYMENT)

# Разделы
# Применение выделений секций на круговой диаграмме
func highlighting_graph_sections(idx: int, set_highlighting: bool = true) -> void:
	if set_highlighting: $PieChart.set_highlighter(idx)
	else: $PieChart.reset_highlighter(idx)

# Обработка нажатия кнопки создания нового счета
func _on_Section_add_section_button_down() -> void: Global.emit_signal("open_window", Global.Pages.SECTION)

# Обработка нажатия кнопки создания движения средств
func _on_Section_cash_flow_button_down() -> void:
	if Request.select_possibility_opening_cashFlow(): Global.emit_signal("open_window", Global.Pages.CASH_FLOW)

# Обработка нажатия кнопки создания подраздела
func _on_Section_add_subsection_button_down() -> void: Global.emit_signal("open_window", Global.Pages.SUBSECTION)

# Кошельки
# Обработка нажатия кнопки создания нового счета
func _on_Wallet_add_wallet_button_down() -> void: Global.emit_signal("open_window", Global.Pages.WALLET)

# Обработка нажатия кнопки создания движения средств
func _on_Wallet_cash_flow_button_down() -> void:
	if Request.select_possibility_opening_cashFlow(): Global.emit_signal("open_window", Global.Pages.CASH_FLOW)

# Обработка нажатия кнопки переноса средств между счетами
func _on_Wallet_transaction_button_down() -> void:
	if Objects.obj_count() > 2: Global.emit_signal("open_window", Global.Pages.TRANSFER)
