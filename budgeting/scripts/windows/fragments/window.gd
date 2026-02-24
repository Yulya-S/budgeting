extends ColorRect

# Обработка нажатия кнопки отмены
func on_close_button_down() -> void:
	Global.delete_child(Global.g_parent(self, 2), get_parent())

# Обработка нажатия кнопки сохранения / изменения
func _on_apply_button_down() -> void:
	if not get_parent().check_object(): return
	if get_parent().idx == 0: Request.match_created(get_parent().page_type, get_parent().get_values())
	else: Request.match_updated(get_parent().idx, get_parent().page_type)
	_apply_changes()

# Обработка нажатия кнопки удаления
func _on_delete_button_down() -> void: $ConfirmationDialog.visible = true

# Отправка сигнала о изменении объекта
func _apply_changes() -> void:
	Global.emit_signal("update_page")
	on_close_button_down()

# Обработка подтверждения удаления объекта
func _on_confirmation_dialog_confirmed() -> void:
	Request.match_deleted(get_parent().idx, get_parent().page_type)
	_apply_changes()
