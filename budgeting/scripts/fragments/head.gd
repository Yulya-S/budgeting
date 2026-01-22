extends ColorRect

# Изменение положения маркера страницы
func _ready() -> void:
	$Login.set_text(File.show_data(File.config.login))
	$Marker.position.x = 45. * (Global.current_page + 3.) + 2.5
	update_date()
	
# Обновление текста даты
func update_date() -> void:
	$Date.set_text(Global.date_to_str())
	$Notification/New.visible = Request.presence_unread_notifications()

# Обработка нажатия кнопки выхода из аккаунта
func _on_exit_button_down() -> void:
	File.clear_config()
	Request.connection_user_db()
	Global.emit_signal("open_new_page", Global.Pages.REGISTRATION)

# Обработка нажатия кнопки подсказок
func _on_hints_button_down() -> void: Global.emit_signal("open_window", Global.Pages.HINTS, null, Global.Dirs.PAGES)

# Обработка нажатия кнопки настройки 
func _on_setting_button_down() -> void: Global.emit_signal("open_window", Global.Pages.SETTINGS, null, Global.Dirs.PAGES)

# Обработка нажатия кнопки очистки данных
func _on_cleaning_button_down() -> void: Global.emit_signal("open_window", Global.Pages.CLEANING, null, Global.Dirs.PAGES)

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
func _on_report_button_down() -> void: Global.emit_signal("open_new_page", Global.Pages.REPORT)

# Открытия окошка уведомлений
func _on_notification_button_down() -> void:
	$Notifications.visible = true

# Обработка нажатия кнопки очистки уведомлений
func _on_notification_cleaning_button_down() -> void:
	Request.clear_notifications()
	$Notifications/ObjArray.update_data()
