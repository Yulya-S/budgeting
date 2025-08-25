extends Control
class_name InfPage
# Подключение путей к объектам в сцене
@onready var Info = $Info

# Экспортируемая переменная
@export var table: Request.Tables = Request.Tables.WALLETS # Таблица 

# Переменная
var id = null # Индекс счета

# Смена индекса объекта
func set_object(obj_id: int, _parent = null) -> void:
	id = obj_id
	Global.emit_signal("update_page")

# Заполнение данных на странице
func update_page() -> void:
	var table_name: String = Global.enum_key(Request.Tables, table)
	table_name[-1] = "_"
	if not id: return
	var value: Dictionary = Request.call("select_"+table_name+"inf", id)
	_replace_values(Info, value)

# Изменение текстовых значений в сцене
func _replace_values(obj, value: Dictionary) -> void:
	for i in obj.get_children():
		if i is Label and i.name.to_lower() in value.keys(): i.set_text(str(value[i.name.to_lower()]))
		else: _replace_values(i, value)

# Обработка нажатия кнопки возврата к списку счетов
func _on_back_button_down() -> void:
	self.queue_free()
	get_parent().remove_child(self)
	Global.emit_signal("update_page")
