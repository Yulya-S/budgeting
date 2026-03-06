extends ColorRect
# Подключение путей к объекту в сцене
@onready var Wallet = $Wallet
@onready var Section = $Section
@onready var Value = $Value
# Переменная
var id: int = 0 # Индекс элемента

# Заполнение выпадающих списков
func _ready() -> void:
	Global.fill_optionButton(Wallet, Request.select("wallets"))
	Global.fill_optionButton(Section, Request.select("sections", "*", "id>4"))
	ColorScheme.repainting(self)

# Изменение значений в сцене
func set_values(data: Dictionary) -> void:
	id = data.id
	Wallet.select(data.wallet_id-1)
	Section.select(data.section_id-3)
	_set_CI_text(data.income)
	File.set_lang(self)

# Применение значения разела (Доход/Расход)
func _set_CI_text(income: int) -> void: $ConsumptionIncome.set_text(File.lang["__CI" + str(income)])

# Обработка нажатия кнопки удаления объекта быстрого создания записи
func _on_delete_button_down() -> void:
	Request.delete_fast_creation(id)
	Global.g_parent(self, 4).fc_update()

# Обработка нажатия кнопки создания движений средств
func _on_add_button_down() -> void:
	Request.insert_cash_flow(Global.get_OB_id(Wallet), Global.get_OB_id(Section), Value.get_text())
	Global.emit_signal("update_page")
	
# Обработка изменения выбранного кошелька
func _on_wallet_item_selected(_index: int) -> void: Request.update_fc_wallet(id, Global.get_OB_id(Wallet))

# Обработка изменения выбранного раздела
func _on_section_item_selected(_index: int) -> void: _set_CI_text(Request.update_fc_section(id, Global.get_OB_id(Section)))

# Обработка изменения значения
func _on_value_text_changed() -> void: Global.text_changed_TextEdit(Value, true)
