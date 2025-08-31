extends CreationWindow
# Подключение путей к объектам в 
@onready var Title = $Title
@onready var Value = $Value
	
	# Проверка введенных данных
func check_object() -> bool:
	super.check_object()
	return _set_error(Request.select(table, "id", 'title="'+Title.get_text()+'"'))

# Изменение значения названия кошелька
func _on_title_text_changed() -> void:
	Global.text_changed_TextEdit(Title)
	check_object()
	
# Изменение значения счета
func _on_value_text_changed() -> void:
	Global.text_changed_TextEdit(Value, true)
	check_object()
