extends Control
class_name Windows
# Подключение пути к объекту в сцене
@onready var Error = get_child(0).get_child(2)
# Экспортируемая переменная
@export var page_type: Global.Pages = Global.Pages.WALLET # Тип создаваемого / Изменяемого объекта
# Переменная
var idx: int = 0 # Индекс изменяемого объекта

# Применение цветовой палитры окна
func _ready() -> void:
	SF.color_and_lang(self)
	if page_type in [Global.Pages.LOAN, Global.Pages.CASH_FLOW, Global.Pages.TRANSFER, Global.Pages.PAYMENT]:
		Global.fill_optionButton($Wallet_id, Request.select("* FROM wallets"))
	match page_type:
		Global.Pages.CASH_FLOW:
			Global.fill_optionButton($Section_id, Request.select("* FROM sections", "id > 2"))
			_on_section_id_item_selected()
		Global.Pages.SUBSECTION:
			Global.fill_optionButton($Section_id, Request.select("* FROM sections", "id > 2"))
			_on_parent_id_item_selected()
		Global.Pages.TRANSFER: Global.fill_optionButton($Wallet_2_id, Request.select("* FROM wallets"))
		Global.Pages.PERCENT, Global.Pages.PAYMENT:
			Global.fill_optionButton($Wallet_2_id, Request.select("* FROM loans", "total > 0"))

# Смена значения займа
func _process(_delta: float) -> void:
	if page_type not in [Global.Pages.PAYMENT, Global.Pages.PERCENT]: return
	var total: float = Request.get_loan_total(idx, Global.get_OB_id($Wallet_2_id), $Date.get_date())
	match page_type:
		Global.Pages.PAYMENT: $Wallet_2_id/Total.set_text(str(total))
		Global.Pages.PERCENT:
			var value: float = 0.0 if SF.L_is_empty($Value) else SF.L_to_float($Value)
			$Value/Count.set_text(str(total)+" + "+str(value)+" = "+str(total + value))

# Обновление данных на сранице с учётом родительской страницы
func set_from_page(obj_idx: int, parent: Global.Pages) -> void:
	match page_type:
		Global.Pages.CASH_FLOW:
			if parent == Global.Pages.WALLET: $Wallet_id.selected = obj_idx - 1
			else: _on_section_id_item_selected(obj_idx-3)
		Global.Pages.SUBSECTION: _on_parent_id_item_selected(obj_idx-3)
		_: Global.set_OB_id($Wallet_2_id, obj_idx)

# Обновление данных на странице
func set_page(new_idx: int) -> void:
	var data: Dictionary = Request.match_elem(str(new_idx), page_type)
	if data == {}:
		_window().on_close_button_down()
		return
	idx = new_idx
	_window().Delete.visible = true
	for i in get_children():
		match i.get_class():
			"TextEdit": i.set_text(str(data[SF.l(i)]))
			"CheckButton":
				i.button_pressed = data[SF.l(i)]
				_on_income_toggled(data[SF.l(i)])
			"OptionButton":
				if "id" in SF.l(i):
					if data[SF.l(i)] == null:
						if SF.l(i) != "wallet_id": continue
						_window().on_close_button_down()
						return
					data[SF.l(i)] = i.get_item_index(data[SF.l(i)])
				if get(_create_func_name(i)): call(_create_func_name(i), data[SF.l(i)])
				else: i.selected = data[SF.l(i)]
		if i.name == "Date": i.set_date(data[SF.l(i)])

# Получение пути к Window
func _window() -> Node: return get_child(0)

# Сборка имени функции
func _create_func_name(obj: Variant) -> String: return "_on_" + SF.l(obj) + "_item_selected"

# Получение значений со страницы
func get_values() -> Array:
	var values: Array = []
	for i in get_children():
		match i.get_class():
			"CheckButton": values.append(str(i.button_pressed))
			"OptionButton": values.append(str(Global.get_OB_id(i)))
			"TextEdit":
				values.append(i.get_text())
				if "title" in SF.l(i): values[-1] = '"'+values[-1]+'"'
			_: if i.name == "Date": values.append('"'+i.get_date()+'"')
	return values

# Проверка верности заполнения полей
func check_object() -> bool:
	Error.clear()
	match page_type:
		Global.Pages.WALLET: return _check_wallet()
		Global.Pages.SECTION: return _check_with_title($Month_Limit, not $Income.button_pressed, _check_name())
		Global.Pages.SUBSECTION: return _check_with_title($Month_Limit, $Month_Limit.visible, _check_name([Global.get_OB_id($Section_id)]))
		Global.Pages.CASH_FLOW: return _check_value($Value)
		Global.Pages.TRANSFER: return _check_transfer()
		Global.Pages.PAYMENT: return _check_payment()
		Global.Pages.PERCENT: return _check_value($Value) and _check_first_date()
		Global.Pages.LOAN: return _check_with_title($Value)
		Global.Pages.EVENT: return _check_with_title($Value, $Event_type.selected != 0)
	return false

# Проверка для числовых полей
func _check_value(obj: TextEdit, other: bool = true) -> bool:
	if (SF.L_is_empty(obj) or SF.L_to_float(obj) <= 0) and other:
		return Error.set_state(Error.States._E5)
	return true

# Проверка имени файла
func _check_name(other: Array = []) -> bool:
	if not Request.callv("check_"+Global.enum_key(Global.Pages, page_type)+"_name", [$Title.get_text(), idx] + other):
		return Error.set_state(Error.States._E4)
	return true

# Проверка названия объекта и его значение
func _check_with_title(value_node: Node, other_value: bool = true, other_check: bool = true) -> bool:
	if Error.check($Title): return false
	return other_check and _check_value(value_node, other_value)

# Проверка возможности создания кошелька
func _check_wallet() -> bool:
	if Error.check_mandatory_fields([$Title, $Value]): return false
	return _check_name()

# Проверка возможности создания перевода средств
func _check_transfer() -> bool:
	if Global.get_OB_id($Wallet_id) == Global.get_OB_id($Wallet_2_id):
		return Error.set_state(Error.States._E6)
	return _check_value($Value)

# Проверка даты создания займа
func _check_first_date() -> bool:
	if Request.loan_check_first_date(Global.get_OB_id($Wallet_2_id), $Date.get_date()):
		return Error.set_state(Error.States._E7)
	return true

# Проверка возможности создания платежа по займу
func _check_payment() -> bool:
	if not _check_value($Value) or not _check_first_date(): return false
	if Request.check_loan_manipulations(idx, Global.get_OB_id($Wallet_2_id), $Date.get_date()):
		return Error.set_state(Error.States._E8)
	if Request.select_all_id("loans", Global.get_OB_id($Wallet_2_id))[0].total - SF.L_to_float($Value) < 0:
		return Error.set_state(Error.States._E9)
	return false

# Обработка нажатий кнопок
# Переключатель
func _on_income_toggled(toggled_on: bool) -> void:
	File.set_CB($Income)
	$Month_Limit.visible = not toggled_on

# Изменение названия объекта
func _on_title_text_changed() -> void: Global.text_changed_TextEdit($Title)

# Изменение значения объекта
func _on_value_text_changed() -> void: Global.text_changed_TextEdit($Value, true)

# Изменение типа события
func _on_event_type_item_selected(index: int) -> void:
	$Event_type.selected = index
	$Value.visible = index > 0

# Изменение объекта с именем Section_id
func _on_Section_id(index: int) -> void:
	$Section_id.selected = index
	var income: bool = Request.select_all("sections")[index + 2].income
	$Section_id/ConsumptionIncome.set_text(File.lang["__CI"+str(int(income))])

# Изменение раздела
func _on_section_id_item_selected(index: int = 0) -> void:
	_on_Section_id(index)
	var values: Array = Request.select_all("subsections", '"__SS4" != title AND section_id = '+str(index+3)) + Request.select_all("subsections", '"__SS4" == title AND section_id = '+str(index+3))
	$Subsection_id.visible = len(values) > 0
	$Value.position.y = 407.0 if len(values) > 0 else 357.0
	if len(values) > 0: Global.fill_optionButton($Subsection_id, values)

# Изменение родительского раздела
func _on_parent_id_item_selected(index: int = 0) -> void:
	_on_Section_id(index)
	$Month_Limit.visible =  not Request.select_all("sections")[index + 2].income
