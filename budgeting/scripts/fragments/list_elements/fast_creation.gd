extends ColorRect
# Подключение путей к объекту в сцене
@onready var Wallet = $Wallet
@onready var Section = $Section
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
	Section.select(data.section_id-5)
	$ConsumptionIncome.set_text("__CI" + str(data.income))
	File.set_lang(self)

# Обработка нажатия кнопки удаления объекта быстрого создания записи
func _on_delete_button_down() -> void:
	Request.delete_fast_creation(id)
	get_parent().get_parent().get_parent().get_parent().fc_update()

# Обработка нажатия кнопки создания движений средств
func _on_add_button_down() -> void:
	Request.insert_cash_flow(Global.get_OB_id(Wallet), Global.get_OB_id(Section), $Value.get_text())
	Global.emit_signal("update_page")
