extends Page
var idx: int = 0 # Индекс выбранного объекта
var page_type: Global.Pages = Global.Pages.WALLET # Выбранный тип страницы информации

# Применение параметров страницы информации
func set_page(new_idx: int, new_page_type: Global.Pages = Global.Pages.WALLET) -> void:
	idx = new_idx
	page_type = new_page_type
	if page_type == Global.Pages.WALLET: Objects.obj = Request.ObjectVariants.WALLET_TRANSACTION
	else: Objects.obj = Request.ObjectVariants.CASH_FLOW
	if not page_type: pass
	update_data()

# #Обновление данных
func update_data() -> void:
	super.update_data()
	
# Получение данных фильтра
func _get_filter(_obj: Variant) -> Array:
	if page_type == Global.Pages.WALLET: return [{"where": "cf.wallet_id = " + str(idx)}]
	return [{"where": "cf.section_id IN (2, 3, 4) AND cf.wallet_2_id"}]

# Обработка нажатия кнопки "назад"
func _on_back_button_down() -> void: Global.delete_child(get_parent(), self)
