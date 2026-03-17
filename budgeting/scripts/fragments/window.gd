extends ColorRect
@onready var Delete = $Delete

# Обработка нажатия кнопки отмены
func on_close_button_down() -> void:
	Global.delete_child(Global.g_parent(self, 2), get_parent())

# Запуск действий в бд
func _run_action(action_type: Request.ActionTypes) -> void:
	Request.match_actions(action_type, get_parent().page_type,
		str(get_parent().idx), get_parent().get_values())

# Обработка нажатия кнопки сохранения / изменения
func _on_apply_button_down() -> void:
	if not get_parent().check_object(): return
	if get_parent().idx == 0: _run_action(Request.ActionTypes.INSERT)
	else: _run_action(Request.ActionTypes.UPDATE)
	_apply_changes()

# Обработка нажатия кнопки удаления
func _on_delete_button_down() -> void: $ConfirmationDialog.visible = true

# Отправка сигнала о изменении объекта
func _apply_changes() -> void:
	Global.emit_signal("update_page")
	on_close_button_down()

# Обработка подтверждения удаления объекта
func _on_confirmation_dialog_confirmed() -> void:
	_run_action(Request.ActionTypes.DELETE)
	Global.g_parent(self, 2).close_inf_page()
	_apply_changes()
	
