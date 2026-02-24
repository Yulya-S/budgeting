extends Control
# Экспортируемая переменная
@export var page_type: Request.ObjectVariants = Request.ObjectVariants.WALLET # Тип создаваемого / Изменяемого объкта
# Переменная
var idx: int = 0 # Индекс изменяемого объекта

# Применение цветовой палитры окна
func _ready() -> void:
	ColorScheme.repainting(self)
	File.set_lang(self)

# Обновление данных на странице
func set_page(new_idx: int) -> void:
	var data: Dictionary = Request.match_elem(str(new_idx), page_type)
	if data == {}:
		$Window.on_close_button_down()
		return
	idx = new_idx
	$Window/Delete.visible = true
	for i in get_children():
		if i.get_class() == "TextEdit": i.set_text(str(data[Global.lower(i)]))
		elif i.get_class() == "CheckButton":
			i.button_pressed = data[Global.lower(i)]
			_on_income_toggled(data[Global.lower(i)])

# Проверка верности заполнения полей
func check_object() -> bool:
	match page_type:
		Request.ObjectVariants.WALLET: return _check_wallet()
	return false

# Проверка что имя 
func _check_textEdit(obj: TextEdit) -> bool:
	if obj.get_text() == "": return false
	return Request.check_obj_name(obj.get_text(), idx, page_type)

# Проверка возможности создания кошелька
func _check_wallet() -> bool: return $Value.get_text() != "" and _check_textEdit($Title)

# Получение значений со страницы
func get_values() -> Array:
	var values: Array = []
	for i in get_children():
		if i.get_class() == "TextEdit": values.append(i.get_text())
	return values

# Обработка переключения переключателя
func _on_income_toggled(toggled_on: bool) -> void:
	File.set_CB($Income)
	$Month_Limit.visible = not toggled_on

# Обработка действий с элементами страницы
# Изменение названия объекта
func _on_title_text_changed() -> void: Global.text_changed_TextEdit($Title)

# Изменение значения объекта
func _on_value_text_changed() -> void: Global.text_changed_TextEdit($Value, true)
