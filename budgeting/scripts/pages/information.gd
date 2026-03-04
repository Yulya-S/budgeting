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
		Global.Pages.LOAN: filter_data = {"where": "cf.section_id IN (2, 3, 4) AND cf.wallet_2_id = " + str(idx), "date": ""}
		Global.Pages.SECTION: filter_data = {"where": "section_id = "+str(idx)}
	update_data()

# Обновление данных
func update_data() -> void:
	if idx == 0: return
	var data: Dictionary = Request.select_inf_data(filter_data.where, idx, page_type)
	for i in [$Filter/Title] + _get_labels(): Global.set_label_from_data(i, data)
	if page_type == Global.Pages.SECTION:
		File.set_lang($Filter/Title)
		$ObjArray.update_obj(Request.ObjectVariants.CASH_FLOW if len(Request._select("* FROM subsections WHERE parent_id = "+str(idx))) > 0 else Request.ObjectVariants.CASH_FLOW)
	super.update_data()

# Получение списка заголовков для применения значений
func _get_labels() -> Array:
	match page_type:
		Global.Pages.WALLET: return [$Filter/Total, $Total/Count, $Total/Cash_flow]
		Global.Pages.LOAN: return [$Filter/Percent, $Total/Total, $Total/Value]
		Global.Pages.SECTION: return [$Filter/Value]
	return []

# Получение данных фильтра
func _get_filter(_obj: Variant) -> Array: return [filter_data]

# Обработка нажатия кнопки "Назад"
func _on_back_button_down() -> void:
	Global.delete_child(get_parent(), self)
	idx = 0

# Обработка нажатия кнопки "Изменить"
func _on_update_button_down() -> void: Global.emit_signal("open_window", page_type, idx)
