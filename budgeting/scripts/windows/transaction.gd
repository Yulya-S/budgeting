extends Windows
# Экспортируемая переменная
@export var extra_type: Request.ObjectVariants = Request.ObjectVariants.CASH_FLOW # Подтип страницы создания / изменения Движений средств

# Применение цветовой палитры окна
func _ready() -> void:
	super._ready()
	if page_type != Request.ObjectVariants.LOAN:
		Global.fill_optionButton($Wallet_id, Request._select("* FROM wallets"))
	if extra_type == Request.ObjectVariants.CASH_FLOW:
		Global.fill_optionButton($Section_id, Request._select("* FROM sections", "id > 4"))
	else: Global.fill_optionButton($Wallet_2_id, Request._select("* FROM loans", "total > 0"))
	_on_extra_id_item_selected()

# Проверка верности заполнения полей
func check_object() -> bool:
	match extra_type:
		Request.ObjectVariants.CASH_FLOW: return _check_cash_flow()
	return false

# Получение значений объекта
func _get_elem(new_idx: int) -> Dictionary: return Request.match_cf_elem(str(new_idx), page_type)

# Проверка возможности создания раздела
func _check_cash_flow() -> bool: return $Value.get_text() != "" and float($Value.get_text()) > 0

# Функции применения изменений объекта
# Обработка создания
func match_created() -> void: Request.match_cf_created(page_type, get_values())

# Обработка изменения
func match_updated() -> void: Request.match_cf_updated(str(idx), page_type, get_values())

# Обработка удаления
func match_deleted() -> void: Request.match_cf_deleted(str(idx), page_type)

# Обработка действий с элементами страницы
# Изменение раздела
func _on_extra_id_item_selected(index: int = 0) -> void:
	match extra_type:
		Request.ObjectVariants.CASH_FLOW:
			$Section_id/ConsumptionIncome.set_text(File.lang["__CI"+str(int(Request._select("* FROM sections")[index + 4].income))])
		Request.ObjectVariants.WALLET:
			$Wallet_2_id/Total.set_text(str(Request._select("* FROM loans")[Global.get_OB_id($Wallet_2_id) - 1].total))
