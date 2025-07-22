extends Control
# Подключение путей к объектам в сцене
@onready var Objects = $ObjArray

# Обработка нажатия кнопки создания нового счета
func _on_add_sections_button_down() -> void: pass

# Обработка нажатия кнопки создания движения средств
func _on_cash_flow_button_down() -> void: Global.emit_signal("open_window", Global.Pages.CASH_FLOW)
