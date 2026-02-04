extends Page
var idx: int = 0 # Индекс выбранного объекта
var page_type: Global.Pages = Global.Pages.WALLET # Выбранный тип страницы информации

# Применение параметров страницы информации
func set_page(new_idx: int, new_page_type: Global.Pages = Global.Pages.WALLET) -> void:
	idx = new_idx
	page_type = new_page_type
	if page_type == Global.Pages.WALLET: Objects.obj = Request.ObjectVariants.WALLET_TRANSACTION
	if not page_type: pass
	update_data()

# #Обновление данных
func update_data() -> void:
	super.update_data()

# Обработка нажатия кнопки "назад"
func _on_back_button_down() -> void: Global.delete_child(get_parent(), self)
