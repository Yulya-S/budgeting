extends Page
# Подключение путей к объектам в сцене
@onready var Title = $Filter/Title
@onready var Total = $Filter/Total
@onready var TCount = $Total/Count
@onready var TValue = $Total/Value

# Переменные
var idx: int = 0 # Индекс выбранного объекта
var page_type: Global.Pages = Global.Pages.WALLET # Выбранный тип страницы информации
var filter_data: Dictionary = {"where": ""}

# Применение параметров страницы информации
func set_page(new_idx: int, new_page_type: Global.Pages = Global.Pages.WALLET) -> void:
	idx = new_idx
	page_type = new_page_type
	if page_type == Global.Pages.WALLET:
		Objects.obj = Request.ObjectVariants.WALLET_TRANSACTION
		filter_data = {"where": "cf.wallet_id = " + str(idx)}
	else:
		Objects.obj = Request.ObjectVariants.CASH_FLOW
		filter_data = {"where": "cf.section_id IN (2, 3, 4) AND cf.wallet_2_id"}
	if not page_type: pass
	update_data()

# #Обновление данных
func update_data() -> void:
	super.update_data()
	var data: Dictionary = Request.select_inf_data(filter_data.where, page_type)
	for i in [Title, Total, TCount, TValue]: i.set_text(str(data[i.name.to_lower()]))

# Получение данных фильтра
func _get_filter(_obj: Variant) -> Array: return [filter_data]

# Обработка нажатия кнопки "назад"
func _on_back_button_down() -> void: Global.delete_child(get_parent(), self)
