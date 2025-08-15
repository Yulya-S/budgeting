extends CreationWindow

# Изменение информации о счете
func set_object(obj_id: int, _parent = null) -> void:
	var value: Array = _get_obj_data(obj_id)
	if len(value) < 0: return
	Value.editable = id == null
	Title.set_text(value[0].title)
	Value.set_text(str(value[0].value))

# Проверка введенных данных
func check_object() -> bool:
	Error.visible = super.check_object()
	var values = Request.select(table, "id", 'title="'+Title.get_text()+'"')
	return _set_error(values)

# Обработка нажатия кнопки сохранения счета
func _on_apply_button_down() -> void: apply_change()
