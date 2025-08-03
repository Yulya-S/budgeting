extends NewWindow
class_name CreationWindow
# Подключение путей к объектам в сцене
@onready var Title = $Title
@onready var Value = $Value

# Проверка введенных данных
func check_object() -> bool:
	Error.visible = false
	if Title.get_text() == "": Global.set_error(Error, "Поле названия не должно быть пустым")
	return Error.visible

# Изменение значения названия кошелька
func _on_title_text_changed() -> void:
	Global.text_changed_TextEdit(Title)
	check_object()
	
# Изменение значения счета
func _on_value_text_changed() -> void:
	Global.text_changed_TextEdit(Value, true)
	check_object()

# Сохранение данных
func apply_change(other_parametrs: Array = []):
	if check_object(): return
	_create_update(['"'+Title.get_text()+'"', float(Value.get_text())] + other_parametrs)
