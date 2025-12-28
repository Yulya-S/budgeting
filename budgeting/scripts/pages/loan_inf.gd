extends InfPage
# Подключение пути к объектам в сцене
@onready var Objects = $ObjArray
@onready var Schedule = $LoanRepayment

# Смена индекса объекта
func set_object(obj_id: int, parent: Variant = null) -> void:
	Objects.data.date = ""
	Objects.set_data("cf.section_id IN (2,3,4) AND cf.wallet_2_id="+str(obj_id), "", "date DESC, id DESC")
	super.set_object(obj_id, parent)
	
func update_page(_close_page: String = "") -> void:
	Schedule.update_schedule()
	
# Обработка нажатия кнопки изменения счета
func _on_update_button_down() -> void: Global.emit_signal("open_window", Global.Pages.LOAN, id)

# Обработка нажатия кнопки погашения займа
func _on_add_payment_button_down() -> void: Global.emit_signal("open_window", Global.Pages.PAYMENT, id, Global.Dirs.WINDOWS, Request.Tables.LOANS)

# Обработка нажатия кнопки добавления процентов по займу
func _on_add_interest_button_down() -> void: Global.emit_signal("open_window", Global.Pages.PERCENT, id, Global.Dirs.WINDOWS, Request.Tables.LOANS)
