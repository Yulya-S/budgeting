extends Control
# Подключение путей к объектам в сцене
@onready var Error = $Error
@onready var Title = $Title
@onready var Value = $Value
@onready var Delete = $Delete

var id = null # id изменяемого счета

# Изменение информации о счете
func set_object(obj_id: int) -> void:
	var value = Request.select(Request.Tables.WALLETS, "*", "id="+str(obj_id))
	if len(value) == 0: return
	id = obj_id
	Value.editable = id == null
	Delete.visible = id != null
	Title.set_text(value[0].title)
	Value.set_text(str(value[0].value))

# Проверка введенных данных
func check_title() -> bool:
	Error.visible = false
	var values = Request.select(Request.Tables.WALLETS, "id", 'title="'+Title.get_text()+'"')
	# Проверка заполнености полей
	if Title.get_text() == "": Global.set_error(Error, "Поле названия не должно быть пустым")
	# Проверка существуют ли подобные записи
	if len(values) == 0: return Error.visible
	elif not id: Global.set_error(Error, "Счет с введенным именем уже существует")
	else: for i in values: if id != i.id:  Global.set_error(Error, "Счет с введенным именем уже существует")
	return Error.visible

# Изменение значения названия кошелька
func _on_title_text_changed() -> void:
	Global.text_changed_TextEdit(Title)
	check_title()

# Изменение значения счета
func _on_value_text_changed() -> void: Global.text_changed_TextEdit(Value, true)

# Обработка нажатия кнопки отмены
func _on_close_button_down() -> void:
	self.queue_free()
	get_parent().remove_child(self)
	
func _apply_changes():
	Global.emit_signal("update_page")
	_on_close_button_down()

# Обработка нажатия кнопки удаления счета
func _on_delete_button_down() -> void:
	Request.delete(Request.Tables.WALLETS, id)
	_apply_changes()

# Обработка нажатия кнопки сохранения счета
func _on_apply_button_down() -> void:
	if id: Request.update_record(Request.Tables.WALLETS, id, ['"'+Title.get_text()+'"', float(Value.get_text())])
	else: Request.insert_record(Request.Tables.WALLETS, ['"'+Title.get_text()+'"', float(Value.get_text())])
	_apply_changes()
