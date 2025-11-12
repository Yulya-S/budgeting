extends Control
# Подключение пути к объектам в сцене
@onready var Filter = $Filter
@onready var Objects = $ObjArray

# Подключение сигнала
func _ready() -> void:
	Global.connect("update_page", Callable(self, "_update_page"))
	_update_page()

# Запуск обновления данных на странице
func _update_page() -> void:
	ColorScheme.repainting(self)
	File.set_lang(self)
	Filter.get_filter()
	Objects.data_update()

# Обработка нажатия кнопки создания нового счета
func _on_add_wallet_button_down() -> void: Global.emit_signal("open_window", Global.Pages.WALLET)

# Обработка нажатия кнопки создания движения средств
func _on_cash_flow_button_down() -> void:
	if Request.select_possibility_opening_cashFlow(): Global.emit_signal("open_window", Global.Pages.CASH_FLOW)

# Обработка нажатия кнопки переноса средств между счетами
func _on_transaction_button_down() -> void:
	if Objects.obj_count() > 2: Global.emit_signal("open_window", Global.Pages.TRANSFER)
