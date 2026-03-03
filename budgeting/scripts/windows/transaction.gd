extends Windows
# Экспортируемая переменная
@export var extra_type: Request.ObjectVariants = Request.ObjectVariants.CASH_FLOW # Подтип страницы создания / изменения Движений средств

# Применение цветовой палитры окна
func _ready() -> void:
	super._ready()
	if page_type == Request.ObjectVariants.CASH_FLOW:
		Global.fill_optionButton($Wallet_id, Request._select("* FROM wallets"))
	match extra_type:
		Request.ObjectVariants.CASH_FLOW:
			Global.fill_optionButton($Section_id, Request._select("* FROM sections", "id > 4"))
			_on_section_id_item_selected()

# Проверка верности заполнения полей
func check_object() -> bool:
	match extra_type:
		Request.ObjectVariants.CASH_FLOW: return _check_cash_flow()
	return false

# Проверка возможности создания раздела
func _check_cash_flow() -> bool: return $Value.get_text() != "" and float($Value.get_text()) > 0

# Обработка действий с элементами страницы
# Изменение раздела
func _on_section_id_item_selected(index: int = 0) -> void:
	var income: bool = Request._select("* FROM sections")[index + 4].income
	$Section_id/ConsumptionIncome.set_text(File.lang["__CI"+str(int(income))])
