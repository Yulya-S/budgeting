extends ColorRect
# Подключение путей к объектам в сцене
@onready var Marker = $Marker

# Изменение положения маркера страницы
func _ready() -> void:
	match Global.current_page:
		Global.Pages.WALLET: Marker.position.x = $Wallet.position.x - 2
		_: Marker.position.x = $Main.position.x - 2

# Обработка нажатия кнопки главная 
func _on_main_button_down() -> void: pass

# Обработка нажатия кнопки кошелька 
func _on_wallet_button_down() -> void: Global.emit_signal("open_new_page", Global.Pages.WALLET)
	

# Обработка нажатия кнопки кредита 
func _on_loan_button_down() -> void: pass

# Обработка нажатия кнопки событий 
func _on_calendar_button_down() -> void: pass

# Обработка нажатия кнопки ждвижения средств 
func _on_flow_button_down() -> void: pass

# Обработка нажатия кнопки отчетов 
func _on_report_button_down() -> void: pass
