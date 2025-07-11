extends Control
# Подключение путей к объектам в сцене
@onready var Error = $Error
@onready var Title = $Title
@onready var Value = $Value
@onready var Delete = $Delete

var object_id = null # id изменяемого счета

# Изменение информации о счете
func set_object(obj_id: int) -> void:
	var value = Request.select(Request.Tables.WALLETS, "*", "id="+str(obj_id))
	if len(value) == 0: return
	object_id = obj_id
	Value.editable = object_id == null
	Delete.visible = object_id != null
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
	elif not object_id: Global.set_error(Error, "Счет с введенным именем уже существует")
	else: for i in values: if object_id != i.id:  Global.set_error(Error, "Счет с введенным именем уже существует")
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

# Обработка нажатия кнопки удаления счета
func _on_delete_button_down() -> void: _on_close_button_down()

# Обработка нажатия кнопки сохранения счета
func _on_apply_button_down() -> void:
	pass # Replace with function body.
