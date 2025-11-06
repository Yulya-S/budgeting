extends ColorRect
# Подключение пути к объектам в сцене
@onready var Marker = $Marker
@onready var Date = $Date
@onready var DayEnd = $Timer
@onready var Login = $Login

# Изменение положения маркера страницы
func _ready() -> void:
	Login.set_text(Global.show_data(Global.config.login))
	Marker.position.x = (5 * (Global.current_page + 3)) + (39.68 * (Global.current_page + 2)) - 1
	Date.set_text(Global.dictionary_date_to_str(Global.date).split(" ")[0])
	DayEnd.start((60 - Global.date.second) + (60 * (60 - Global.date.minute)) + (60 * 60 * (24 - Global.date.hour)))

# Обработка нажатия кнопки настройки 
func _on_setting_button_down() -> void: Global.emit_signal("open_window", Global.Pages.SETTINGS, null, Global.Dirs.PAGES)

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
func _on_event_button_down() -> void: Global.emit_signal("open_new_page", Global.Pages.EVENT)

# Обработка нажатия кнопки отчетов 
func _on_report_button_down() -> void: pass

# Обработка окончания работы таймера
func _on_timer_timeout() -> void:
	DayEnd.start(60 * 60 * 24)
	Global.date = Time.get_datetime_dict_from_system()
	Date.set_text(Global.date)
