extends Control
# Подключение путей к объектам в сцене
@onready var Title = $Loan/Title
@onready var Total = $Loan/Total
@onready var Value = $Loan/Value
@onready var Objects = $ObjArray

# Переменная
var id = null # Индекс счета

# Смена индекса объекта
func set_object(obj_id: int, _parent = null) -> void:
	id = obj_id
	Objects.data.date = ""
	Objects.set_data("", "cf.section_id IN (2,3,4) AND cf.wallet_2_id="+str(id))
	Global.emit_signal("update_page")

# Заполнение данных на странице
func update_page() -> void:
	# Заполнение информации о кошельке
	var loan_value: Array = Request.select(Request.Tables.LOANS, "*", "id="+str(id))
	Title.set_text(loan_value[0].title)
	Total.set_text(str(loan_value[0].total))
	Value.set_text(str(Request.select(Request.Tables.CASH_FLOWS, "*", "section_id=3 AND wallet_2_id="+str(id))[0].value))

# Обработка нажатия кнопки возврата к списку счетов
func _on_back_button_down() -> void:
	self.queue_free()
	get_parent().remove_child(self)
	Global.emit_signal("update_page")
