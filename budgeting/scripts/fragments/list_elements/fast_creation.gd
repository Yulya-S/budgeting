extends ColorRect
# Подключение путей к объектам в сцене
@onready var Wallet = $Wallet
@onready var Section = $Section
@onready var Subsection = $Subsection
@onready var Value = $Value
# Переменная
var id: int = 0 # Индекс элемента

# Заполнение выпадающих списков
func _ready() -> void:
	Global.fill_optionButton(Wallet, Request.select_all("wallets"))
	Global.fill_optionButton(Section, Request.select_all("sections", "id>2"))
	SF.color_and_lang(self)

# Изменение значений в сцене
func set_values(data: Dictionary) -> void:
	id = data.id
	Wallet.select(data.wallet_id-1)
	Section.select(data.section_id-3)
	_update_section_visible(data.income)

# Фрагмент запроса на получение подразделов
func _select(text: String) -> Array:
	return Request.select_all("subsections", text + " AND section_id = "+str(Global.get_OB_id(Section)))

# Изменение видимости информации о разделе
func _update_section_visible(income: bool) -> void:
	$Section/ConsumptionIncome.set_text(File.lang["__CI" + str(int(income))])
	var values: Array = _select('"__SS4" != title') + _select('"__SS4" == title')
	Subsection.visible = len(values) > 0
	if len(values) > 0:
		Global.fill_optionButton(Subsection, values)
		Global.set_OB_id(Subsection, Request.select_all_id("fast_creations", id)[0].subsection_id)

# Обработка нажатий кнопок
# Удаление объекта быстрого создания записи
func _on_delete_button_down() -> void:
	Request.delete_fast_creation(id)
	SF.g_p(self, 4).fc_update()

# Создание движения средств
func _on_add_button_down() -> void:
	var values: Array = []
	for i in get_children():
		match i.get_class():
			"OptionButton": values.append(Global.get_OB_id(i))
			"TextEdit": values.append(Value.get_text())
	if not Subsection.visible: values[2] = null
	values.append(Global.date_to_str())
	Request._insert_cash_flow(values)
	Global.emit_signal("update_page")

# Выбранный кошелёк
func _on_wallet_item_selected(_index: int) -> void:
	Request.update_fc_wallet(id, Global.get_OB_id(Wallet))

# Выбранный раздел
func _on_section_item_selected(_index: int) -> void:
	_update_section_visible(Request.update_fc_section(id, Global.get_OB_id(Section)))

# Выбранный подраздел
func _on_subsection_item_selected(_index: int = 0) -> void:
	Request.update_fc_subsection(id, Global.get_OB_id(Subsection))

# Изменение значения
func _on_value_text_changed() -> void: Global.text_changed_TextEdit(Value, true)
