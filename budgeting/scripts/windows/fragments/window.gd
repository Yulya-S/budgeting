extends ColorRect

# Обработка нажатия кнопки отмены
func on_close_button_down() -> void: Global.delete_child(get_parent().get_parent(), get_parent())

# Обработка нажатия кнопки сохранения / изменения
func _on_apply_button_down() -> void:
	if get_parent().check_object(): return
	get_parent().create_update()
	_apply_changes()

# Обработка нажатия кнопки удаления
func _on_delete_button_down() -> void:
	get_parent().delete_obj()
	Global.emit_signal("update_page", get_parent().name)
	on_close_button_down()

# Отправка сигнала о изменении объекта
func _apply_changes() -> void:
	Global.emit_signal("update_page")
	on_close_button_down()
