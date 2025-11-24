extends Control
# Подключение пути к объектам в сцене
@onready var Objects = $ObjArray

# Подключение сигнала
func _ready() -> void:
	Global.connect("update_page", Callable(self, "_update_page"))
	_update_page()

# Запуск обновления данных на странице
func _update_page() -> void:
	ColorScheme.repainting(self)
	File.set_lang(self)
	update_date()
	
# Обновление данных
func update_date() -> void: Objects.data_update($Filter)

# Обработка нажатия кнопки создания нового займа
func _on_add_loan_button_down() -> void:
	if len(Request.select(Request.Tables.WALLETS)) > 0: Global.emit_signal("open_window", Global.Pages.LOAN)

# Обработка нажатия кнопки погашения займа
func _on_add_payment_button_down() -> void:
	if Request.select_possibility_opening_payment(): Global.emit_signal("open_window", Global.Pages.PAYMENT)

# Обработка нажатия кнопки добавления процентов по займу
func _on_add_interest_button_down() -> void:
	if len(Request.select(Request.Tables.LOANS, "*", "total>0")) > 0: Global.emit_signal("open_window", Global.Pages.PERCENT)
