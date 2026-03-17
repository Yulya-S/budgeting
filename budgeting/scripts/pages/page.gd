extends Control
class_name Page
# Подключение путей к объектам в сцене
@onready var Objects = get_node_or_null("ObjArray")
@onready var Filter = get_node_or_null("Filter")
@onready var FilterSection = get_node_or_null("Filter/Section")
@onready var FilterWallet = get_node_or_null("Filter/Wallet")
@onready var PieChart = get_node_or_null("PieChart")

# Подключение сигнала
func _ready() -> void:
	if Global.current_page == Global.Pages.CASH_FLOW: # Заполнение списка кошельков
		Filter.set_OB_items(Request.Tables.WALLETS)
		Filter.set_OB_items(Request.Tables.SECTIONS)
	Global.connect_signal_update_page(self)

# Применение фильтра если переход на страницу произошел со страницы информации
func set_cash_flow_filter(idx: int, parent: Global.Pages) -> void:
	if parent == Global.Pages.WALLET: FilterWallet.selected = idx
	else: FilterSection.selected = idx
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
			var save_selected_section: int = FilterSection.selected
			Filter.set_OB_items(Request.Tables.SECTIONS) # Заполнение списка разделов
			FilterSection.selected = save_selected_section
			File.set_OB_elements(FilterSection) # Применение перевода для списка разделов

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

# Применение выделений секций на круговой диаграмме для страницы разделов
func highlighting_graph_sections(idx: int, set_highlighting: bool = true) -> void:
	if not PieChart: return
	if set_highlighting: PieChart.set_highlighter(idx)
	else: PieChart.reset_highlighter(idx)

# Обработка нажатий кнопок
# Общие обработки
# Cоздание движения средств
func _on_cash_flow_button_down() -> void: Request.match_check(Global.Pages.CASH_FLOW)

# Создания объектов
func _on_add_button_down() -> void:
	if Global.current_page != Global.Pages.LOAN or Request.check_wallet_count():
		SF.op_w(Global.current_page)

# Перевод средств между счетами
func _on_transaction_button_down() -> void: Request.match_check(Global.Pages.TRANSFER)

# Займы
# Добавление процентов по займу
func _on_Loan_add_interest_button_down() -> void: Request.match_check(Global.Pages.PERCENT)

# Погашение займа
func _on_Loan_add_payment_button_down() -> void: Request.match_check(Global.Pages.PAYMENT)

# Разделы
# Создания подраздела
func _on_Section_add_subsection_button_down() -> void: SF.op_w(Global.Pages.SUBSECTION)
