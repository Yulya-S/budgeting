extends Page

# Переменные
var idx: int = 0 # Индекс выбранного объекта
@export var page_type: Global.Pages = Global.Pages.WALLET_INF # Выбранный тип страницы информации
var filter_data: Dictionary = {"where": ""}

# Применение параметров страницы информации
func set_page(new_idx: int, new_page_type: Global.Pages = Global.Pages.WALLET_INF) -> void:
	idx = new_idx
	page_type = new_page_type
	if _get_type(): filter_data = {"where": "cf.wallet_id = " + str(idx)}
	else: filter_data = {"where": "cf.section_id IN (2, 3, 4) AND cf.wallet_2_id = " + str(idx)}
	update_data()

# #Обновление данных
func update_data() -> void:
	super.update_data()
	var data: Dictionary = Request.select_inf_data(filter_data.where, page_type)
	for i in _get_labels():
		if i.name.to_lower() in data.keys():
				i.set_text(str(data[i.name.to_lower()]))

# Проверка типа страницы информации
func _get_type() -> bool:
	return page_type == Global.Pages.WALLET_INF

# Получение списка заголовков для применения значений
func _get_labels() -> Array:
	if _get_type(): return [$Filter/Title, $Filter/Total, $Total/Count, $Total/Value]
	return [$Filter/Title, $Filter/Percent, $Total/Total, $Total/Value]

# Получение данных фильтра
func _get_filter(_obj: Variant) -> Array: return [filter_data]

# Обработка нажатия кнопки "назад"
func _on_back_button_down() -> void: Global.delete_child(get_parent(), self)
