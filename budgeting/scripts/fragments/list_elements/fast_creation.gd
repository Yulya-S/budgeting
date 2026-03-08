extends ColorRect
# Подключение путей к объекту в сцене
@onready var Wallet = $Wallet
@onready var Section = $Section
@onready var Subsection = $Subsection
@onready var Value = $Value
# Переменная
var id: int = 0 # Индекс элемента

# Заполнение выпадающих списков
func _ready() -> void:
	Global.fill_optionButton(Wallet, Request.select("wallets"))
	Global.fill_optionButton(Section, Request.select("sections", "*", "id>2"))
	ColorScheme.repainting(self)
	File.set_lang(self)

# Изменение значений в сцене
func set_values(data: Dictionary) -> void:
	id = data.id
	Wallet.select(data.wallet_id-1)
	Section.select(data.section_id-3)
	_update_section_visible(data.income)

# Применение значения разела (Доход/Расход)
func _set_CI_text(income: int) -> void: $Section/ConsumptionIncome.set_text(File.lang["__CI" + str(income)])

# Обработка нажатия кнопки удаления объекта быстрого создания записи
func _on_delete_button_down() -> void:
	Request.delete_fast_creation(id)
	Global.g_parent(self, 4).fc_update()

# Обработка нажатия кнопки создания движений средств
func _on_add_button_down() -> void:
	var sub_id: Variant = Global.get_OB_id(Subsection)
	if not Subsection.visible: sub_id = null
	Request.insert_cash_flow(Global.get_OB_id(Wallet), Global.get_OB_id(Section), sub_id, Value.get_text())
	Global.emit_signal("update_page")
	
# Обработка изменения выбранного кошелька
func _on_wallet_item_selected(_index: int) -> void: Request.update_fc_wallet(id, Global.get_OB_id(Wallet))

func _update_section_visible(income: bool) -> void:
	_set_CI_text(income)
	var values: Array = Request._select("* FROM subsections", '"__SS4" != title AND parent_id = '+str(Global.get_OB_id(Section))) + Request._select("* FROM subsections", '"__SS4" == title AND parent_id = '+str(Global.get_OB_id(Section)))
	Subsection.visible = len(values) > 0
	if len(values) > 0:
		Global.fill_optionButton(Subsection, values)
		Global.set_OB_id(Subsection, Request._select("* FROM fast_creations", "id = "+str(id))[0].subsection_id)

# Обработка изменения выбранного раздела
func _on_section_item_selected(_index: int) -> void:
	_update_section_visible(Request.update_fc_section(id, Global.get_OB_id(Section)))

# Обработка ихменения выбранного подраздела
func _on_subsection_item_selected(_index: int = 0) -> void: Request.update_fc_subsection(id, Global.get_OB_id(Subsection))

# Обработка изменения значения
func _on_value_text_changed() -> void: Global.text_changed_TextEdit(Value, true)
