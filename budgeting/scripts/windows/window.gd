extends Control
class_name Windows
# Экспортируемая переменная
@export var page_type: Global.Pages = Global.Pages.WALLET # Тип создаваемого / Изменяемого объкта
# Переменная
var idx: int = 0 # Индекс изменяемого объекта

# Применение цветовой палитры окна
func _ready() -> void:
	ColorScheme.repainting(self)
	File.set_lang(self)
	if page_type in [Global.Pages.LOAN, Global.Pages.CASH_FLOW, Global.Pages.TRANSFER, Global.Pages.PAYMENT]:
		Global.fill_optionButton($Wallet_id, Request._select("* FROM wallets"))
	if page_type in [Global.Pages.CASH_FLOW, ]:
		Global.fill_optionButton($Section_id, Request._select("* FROM sections", "id > 2"))
		_on_section_id_item_selected()
	elif page_type == Global.Pages.SUBSECTION:
		Global.fill_optionButton($Parent_id, Request._select("* FROM sections", "id > 2"))
		_on_parent_id_item_selected()
	elif page_type == Global.Pages.TRANSFER:
		Global.fill_optionButton($Wallet_2_id, Request._select("* FROM wallets"))
	elif page_type in [Global.Pages.PERCENT, Global.Pages.PAYMENT]:
		Global.fill_optionButton($Wallet_2_id, Request._select("* FROM loans", "total > 0"))

# Смена значения займа
func _process(_delta: float) -> void:
	if page_type not in [Global.Pages.PAYMENT, Global.Pages.PERCENT]: return
	var total: float = Request.get_loan_total(idx, Global.get_OB_id($Wallet_2_id), $Date.get_date())
	if page_type == Global.Pages.PAYMENT: $Wallet_2_id/Total.set_text(str(total))
	elif page_type == Global.Pages.PERCENT:
		var value: float = 0.0 if $Value.get_text() == "" else float($Value.get_text())
		$Value/Count.set_text(str(total)+" + "+str(value)+" = "+str(total + value))

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
			if "id" in Global.lower(i):
				if data[Global.lower(i)] == null:
					$Window.on_close_button_down()
					return
				data[Global.lower(i)] = i.get_item_index(data[Global.lower(i)])
			if get(_create_func_name(i)): callv(_create_func_name(i), [data[Global.lower(i)]])
			i.selected = data[Global.lower(i)]
		elif i.name == "Date": i.set_date(data[Global.lower(i)])

# Сборка имени функции
func _create_func_name(obj: Variant) -> String:
	return "_on_" + Global.lower(obj) + "_item_selected"

# Проверка верности заполнения полей
func check_object() -> bool:
	match page_type:
		Global.Pages.WALLET: return _check_wallet()
		Global.Pages.SECTION: return _check_section()
		Global.Pages.CASH_FLOW: return _check_cash_flow()
		Global.Pages.TRANSFER: return _check_transfer()
		Global.Pages.PAYMENT: return _check_payment()
		Global.Pages.PERCENT: return _check_percent()
		Global.Pages.LOAN: return _check_loan()
		Global.Pages.EVENT: return _check_event()
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

# Проверка возможности создания раздела
func _check_cash_flow() -> bool: return $Value.get_text() != "" and float($Value.get_text()) > 0

# Проверка возможности создания перевода средств
func _check_transfer() -> bool:
	return $Value.get_text() != "" and float($Value.get_text()) > 0 and Global.get_OB_id($Wallet_id) != Global.get_OB_id($Wallet_2_id)

# Проверка возможности создания платежа по займу
func _check_payment() -> bool:
	if $Value.get_text() == "" or float($Value.get_text()) <= 0: return false
	if Request.loan_check_first_date(Global.get_OB_id($Wallet_2_id), $Date.get_date()): return false
	if Request._select("* FROM loans", "id = "+str(Global.get_OB_id($Wallet_2_id)))[0].total - float($Value.get_text()) < 0: return false
	return true
	
# Проверка возможности создания процентов по займу
func _check_percent() -> bool:
	if $Value.get_text() == "" or float($Value.get_text()) <= 0: return false
	if Request.loan_check_first_date(Global.get_OB_id($Wallet_2_id), $Date.get_date()): return false
	return true

# Проверка возможности создания займа
func _check_loan() -> bool:
	return $Value.get_text() != "" and float($Value.get_text()) > 0 and $Title.get_text() != ""

# Проверка возможности создания события
func _check_event() -> bool:
	return (($Value.get_text() != "" and float($Value.get_text()) > 0) or $Event_type.selected == 0) and $Title.get_text() != ""

# Получение значений со страницы
func get_values() -> Array:
	var values: Array = []
	for i in get_children():
		if i.get_class() == "TextEdit": values.append(i.get_text())
		elif i.get_class() == "CheckButton": values.append(str(i.button_pressed))
		elif i.get_class() == "OptionButton": values.append(str(Global.get_OB_id(i)))
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

# Изменение раздела
func _on_section_id_item_selected(index: int = 0) -> void:
	$Section_id/ConsumptionIncome.set_text(File.lang["__CI"+str(int(Request._select("* FROM sections")[index + 2].income))])

# Изменение родительского раздела
func _on_parent_id_item_selected(index: int = 0) -> void:
	var income: bool = Request._select("* FROM sections")[index + 2].income
	$Parent_id/ConsumptionIncome.set_text(File.lang["__CI"+str(int(income))])
	$Month_Limit.visible =  not income
