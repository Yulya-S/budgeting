extends CreationPage
# Подключение путей к объектам в сцене
@onready var Title = $Title
@onready var Value = $Value

# Изменение информации о счете
func set_object(obj_id: int) -> void:
	var value: Array = _get_obj_data(obj_id)
	if len(value) < 0: return
	Value.editable = id == null
	Title.set_text(value[0].title)
	Value.set_text(str(value[0].value))

# Проверка введенных данных
func check_title() -> bool:
	Error.visible = false
	var values = Request.select(table, "id", 'title="'+Title.get_text()+'"')
	# Проверка заполнености полей
	if Title.get_text() == "": Global.set_error(Error, "Поле названия не должно быть пустым")
	return _set_error(Error, values)

# Изменение значения названия кошелька
func _on_title_text_changed() -> void:
	Global.text_changed_TextEdit(Title)
	check_title()

# Изменение значения счета
func _on_value_text_changed() -> void: Global.text_changed_TextEdit(Value, true)

# Обработка нажатия кнопки удаления счета
func _on_delete_button_down() -> void:
	Request.delete(table, id)
	_apply_changes()

# Обработка нажатия кнопки сохранения счета
func _on_apply_button_down() -> void:
	_create_update(['"'+Title.get_text()+'"', float(Value.get_text())])
