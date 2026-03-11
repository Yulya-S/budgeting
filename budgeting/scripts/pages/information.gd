extends Page
# Переменные
var idx: int = 0 # Индекс выбранного объекта
@export var page_type: Global.Pages = Global.Pages.WALLET # Выбранный тип страницы информации
var filter_data: Dictionary = {"where": ""}

# Применение параметров страницы информации
func set_page(new_idx: int, new_page_type: Global.Pages = Global.Pages.WALLET) -> void:
	idx = new_idx
	page_type = new_page_type
	match page_type:
		Global.Pages.WALLET: filter_data = {"where": "((cf.section_id = 1 AND cf.wallet_2_id = "+str(idx)+") OR cf.wallet_id = " + str(idx) + ") AND " + Request.where_date(Global.date_to_str(), "cf.date")}
		Global.Pages.LOAN: filter_data = {"where": "cf.section_id=2 AND cf.wallet_2_id = " + str(idx), "date": ""}
		Global.Pages.SECTION: filter_data = {"where": "section_id = "+str(idx)}
	update_data()

# отмена запуска дополнительных изменений на странице
func _match_other_update() -> void: pass

# Обновление данных
func update_data() -> void:
	if idx == 0: return
	var data: Dictionary = Request.select_inf_data(filter_data.where, idx, page_type)
	for i in [$Filter/Title] + _get_labels(): Global.set_label_from_data(i, data)
	if page_type == Global.Pages.SECTION:
		File.set_lang($Filter/Title)
		$ObjArray.update_section_inf_obj(len(Request._select("* FROM subsections WHERE parent_id = "+str(idx))) > 0)
	_run_update()

# Получение списка заголовков для применения значений
func _get_labels() -> Array:
	match page_type:
		Global.Pages.WALLET: return [$Filter/Total, $Total/Count, $Total/Cash_flow]
		Global.Pages.LOAN: return [$Filter/Percent, $Total/Total, $Total/Value]
		Global.Pages.SECTION: return [$Filter/Value]
	return []

# Получение данных фильтра
func _get_filter(_obj: Variant) -> Array: return [filter_data]

# Обработки нажатий кнопок
# Назад
func _on_back_button_down() -> void:
	Global.delete_child(get_parent(), self)
	idx = 0

# Изменить
func _on_update_button_down() -> void: SF.op_w(page_type, idx)

# Создать движение средств
func _on_cash_flow_button_down() -> void: SF.op_w(Global.Pages.CASH_FLOW)

# Список транзакций
func _on_transactions_button_down() -> void: SF.op_np(Global.Pages.CASH_FLOW, idx, page_type)

# Создать подраздел
func _on_add_subsection_button_down() -> void: SF.op_w(Global.Pages.SUBSECTION)

# Добавить процент по займу
func _on_add_interest_button_down() -> void: SF.op_w(Global.Pages.PERCENT)

# Добавить платёж по займу
func _on_add_payment_button_down() -> void: SF.op_w(Global.Pages.PAYMENT)
