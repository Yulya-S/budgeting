extends Control
# Экспортируемая переменная
@export var page_type: Request.ObjectVariants = Request.ObjectVariants.WALLET # Тип создаваемого / Изменяемого объкта
# Переменная
var idx: int = 0 # Индекс изменяемого объекта

# Применение цветовой палитры окна
func _ready() -> void:
	ColorScheme.repainting(self)
	File.set_lang(self)
	if page_type == Request.ObjectVariants.LOAN:
		Global.fill_optionButton($Wallet_Id, Request._select("* FROM wallets"))

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
		elif i.get_class() == "OptionButton":
			if get(_create_func_name(i)): callv(_create_func_name(i), [data[Global.lower(i)]])
			if "id" in Global.lower(i):
				if data[Global.lower(i)] == null:
					$Window.on_close_button_down()
					return
				data[Global.lower(i)] -= 1
			i.selected = data[Global.lower(i)]
		elif i.name == "Date": i.set_date(data[Global.lower(i)])

# Сборка имени функции
func _create_func_name(obj: Variant) -> String:
	return "_on_" + Global.lower(obj) + "_item_selected"

# Проверка верности заполнения полей
func check_object() -> bool:
	match page_type:
		Request.ObjectVariants.WALLET: return _check_wallet()
		Request.ObjectVariants.SECTION: return _check_section()
		#Request.ObjectVariants.LOAN: return _check_loan()
		Request.ObjectVariants.EVENT: return _check_event()
	return false

# Проверка что имя 
func _check_textEdit(obj: TextEdit) -> bool:
	if obj.get_text() == "": return false
	return Request.check_obj_name(obj.get_text(), idx, page_type)

# Проверка возможности создания кошелька
func _check_wallet() -> bool: return $Value.get_text() != "" and _check_textEdit($Title)

# Проверка возможности создания раздела
func _check_section() -> bool:
	return (($Month_Limit.get_text() != "" and float($Month_Limit.get_text()) > 0) or $Income.button_pressed) and _check_textEdit($Title)

# Проверка возможности создания события
func _check_event() -> bool:
	return (($Value.get_text() != "" and float($Value.get_text()) > 0) or $Event_type.selected == 0) and $Title.get_text() != ""

# Получение значений со страницы
func get_values() -> Array:
	var values: Array = []
	for i in get_children():
		if i.get_class() == "TextEdit": values.append(i.get_text())
		elif i.get_class() == "CheckButton": values.append(str(i.button_pressed))
		elif i.get_class() == "OptionButton": values.append(Global.get_OB_id(i))
		elif i.name == "Date": values.append(i.get_date())
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

# Изменение типа события
func _on_event_type_item_selected(index: int) -> void: $Value.visible = index > 0
