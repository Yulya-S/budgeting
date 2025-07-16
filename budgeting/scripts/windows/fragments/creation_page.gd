extends Control
class_name CreationPage
# Подключение путей к объектам в сцене
@onready var Error = $Error
@onready var Delete = $Delete

# Переменные
var id = null # Индекс изменяемого объекта
var table: Request.Tables = Request.Tables.WALLETS # Связанная таблица

# Изменение информации о счете
func _get_obj_data(obj_id: int) -> Array:
	id = obj_id
	Delete.visible = id != null
	return Request.select(table, "*", "id="+str(obj_id))

# Проверка существуют ли подобные записи
func _set_error(Error: Label, values: Array) -> bool:
	if len(values) == 0: return Error.visible
	elif not id: Global.set_error(Error, "Объект уже существует")
	else: for i in values: if id != i.id:  Global.set_error(Error, "Объект уже существует")
	return Error.visible

# Обработка нажатия кнопки отмены
func _on_close_button_down() -> void:
	self.queue_free()
	get_parent().remove_child(self)

# Применение изменений
func _apply_changes() -> void:
	Global.emit_signal("update_page")
	_on_close_button_down()	

# Создание или изменение объекта
func _create_update(values: Array) -> void:
	if id: Request.update_record(table, id, values)
	else: Request.insert_record(table, values)
	_apply_changes()
	
# Обработка нажатия кнопки удаления счета
func _on_delete_button_down() -> void:
	Request.delete(table, id)
	_apply_changes()
