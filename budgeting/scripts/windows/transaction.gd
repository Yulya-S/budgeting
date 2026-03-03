extends Windows

# Применение цветовой палитры окна
func _ready() -> void:
	super._ready()
	if page_type != Global.Pages.PERCENT:
		Global.fill_optionButton($Wallet_id, Request._select("* FROM wallets"))
	if page_type == Global.Pages.CASH_FLOW:
		Global.fill_optionButton($Section_id, Request._select("* FROM sections", "id > 4"))
		_on_section_id_item_selected()
	else:
		Global.fill_optionButton($Wallet_2_id, Request._select("* FROM loans", "total > 0"))
	
# Смена значения займа
func _process(_delta: float) -> void:
	var total: float = Request.get_loan_total(idx, Global.get_OB_id($Wallet_2_id), $Date.get_date())
	if page_type == Global.Pages.PAYMENT: $Wallet_2_id/Total.set_text(str(total))
	elif page_type == Global.Pages.PERCENT:
		var value: float = 0.0 if $Value.get_text() == "" else float($Value.get_text())
		$Value/Count.set_text(str(total)+" + "+str(value)+" = "+str(total + value))
		
# Обработка действий с элементами страницы
# Изменение раздела
func _on_section_id_item_selected(index: int = 0) -> void:
	$Section_id/ConsumptionIncome.set_text(File.lang["__CI"+str(int(Request._select("* FROM sections")[index + 4].income))])
