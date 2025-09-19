extends ColorRect
# Подключение пути к объектам в сцене
@onready var Marker = $Marker
@onready var Date = $Date

# Изменение положения маркера страницы
func _ready() -> void:
	Marker.position.x = (5 * (Global.current_page + 3)) + (39.68 * (Global.current_page + 2)) - 1
	Date.set_text(Time.get_date_string_from_system())

# Обработка нажатия кнопки главная 
func _on_main_button_down() -> void: Global.emit_signal("open_new_page", Global.Pages.BASIC)

# Обработка нажатия кнопки кошелька 
func _on_wallet_button_down() -> void: Global.emit_signal("open_new_page", Global.Pages.WALLET)

# Обработка нажатия кнопки разделов
func _on_section_button_down() -> void: Global.emit_signal("open_new_page", Global.Pages.SECTION)

# Обработка нажатия кнопки движения средств 
func _on_flow_button_down() -> void: Global.emit_signal("open_new_page", Global.Pages.CASH_FLOW)

# Обработка нажатия кнопки кредита
func _on_loan_button_down() -> void: Global.emit_signal("open_new_page", Global.Pages.LOAN)

# Обработка нажатия кнопки событий 
func _on_calendar_button_down() -> void: pass

# Обработка нажатия кнопки отчетов 
func _on_report_button_down() -> void: pass
