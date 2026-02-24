extends Page

# Переменные
var idx: int = 0 # Индекс выбранного объекта
@export var page_type: Global.Pages = Global.Pages.WALLET # Выбранный тип страницы информации
var filter_data: Dictionary = {"where": ""}

# Применение параметров страницы информации
func set_page(new_idx: int, new_page_type: Global.Pages = Global.Pages.WALLET) -> void:
	idx = new_idx
	page_type = new_page_type
	if _get_type(): filter_data = {"where": "cf.wallet_id = " + str(idx) + " AND " + Request.where_date(Global.date_to_str(), "cf.date")}
	else: filter_data = {"where": "cf.section_id IN (2, 3, 4) AND cf.wallet_2_id = " + str(idx)}
	update_data()

# #Обновление данных
func update_data() -> void:
	super.update_data()
	var data: Dictionary = Request.select_inf_data(filter_data.where, idx, page_type)
	for i in _get_labels(): Global.set_label_from_data(i, data)

# Проверка типа страницы информации
func _get_type() -> bool:
	return page_type == Global.Pages.WALLET

# Получение списка заголовков для применения значений
func _get_labels() -> Array:
	if _get_type(): return [$Filter/Title, $Filter/Total, $Total/Count, $Total/Cash_flow]
	return [$Filter/Title, $Filter/Percent, $Total/Total, $Total/Value]

# Получение данных фильтра
func _get_filter(_obj: Variant) -> Array: return [filter_data]

# Обработка нажатия кнопки "Назад"
func _on_back_button_down() -> void: Global.delete_child(get_parent(), self)

# Обработка нажатия кнопки "Изменить"
func _on_update_button_down() -> void: Global.emit_signal("open_window", page_type, idx)
