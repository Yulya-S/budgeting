extends ColorRect
@onready var NotificationMarker = $Notification/New
@onready var NotificationObjects = $Notifications/ObjArray

# Изменение положения маркера страницы
func _ready() -> void:
	$Login.set_text(File.show_data(File.config.login))
	$Marker.position.x = 45. * (Global.current_page + 3.) + 2.5
	update_date()
	
# Обновление текста даты
func update_date() -> void:
	$Date.set_text(Global.date_to_str())
	NotificationMarker.visible = Request.presence_unread_notifications()

# Обработка нажатия кнопки выхода из аккаунта
func _on_exit_button_down() -> void:
	File.clear_config()
	Request.connection_user_db()
	_emit_onp(Global.Pages.REGISTRATION)
	
# Открытия окна уведомлений
func _on_notification_button_down() -> void:
	NotificationObjects.update_data()
	Request.update_notifications_new()
	$Notifications.visible = true
	NotificationMarker.visible = false

# Обработка нажатия кнопки очистки уведомлений
func _on_notification_cleaning_button_down() -> void:
	Request.clear_notifications()
	NotificationObjects.update_data()

# Вызов сигнала открытия окна поверх текущего
func _emit_ow(new_page: Global.Pages) -> void: Global.emit_signal("open_window", new_page, null, Global.Dirs.PAGES)

# Вызов сигнала открытия нового окна
func _emit_onp(new_page: Global.Pages) -> void: Global.emit_signal("open_new_page", new_page)

# Обработка перехода по страницам
func _on_hints_button_down() -> void: _emit_ow(Global.Pages.HINTS) # Подсказки

func _on_setting_button_down() -> void: _emit_ow(Global.Pages.SETTINGS) # Настройки

func _on_cleaning_button_down() -> void: _emit_ow(Global.Pages.CLEANING) # Очистка данных

func _on_main_button_down() -> void: _emit_onp(Global.Pages.BASIC) # Главная

func _on_wallet_button_down() -> void: _emit_onp(Global.Pages.WALLET) # Кошельки

func _on_section_button_down() -> void: _emit_onp(Global.Pages.SECTION) # Разделы

func _on_flow_button_down() -> void: _emit_onp(Global.Pages.CASH_FLOW) # Движения средств

func _on_loan_button_down() -> void: _emit_onp(Global.Pages.LOAN) # Займы

func _on_event_button_down() -> void: _emit_onp(Global.Pages.EVENT) # События

func _on_report_button_down() -> void: _emit_onp(Global.Pages.REPORT) # Отчеты
