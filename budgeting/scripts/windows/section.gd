extends CreationPage
# Подключение путей к объектам в сцене
@onready var Title = $Title
@onready var ConsumptionIncome = $ConsumptionIncome
@onready var Value = $Value

# Изменение информации о счете
func set_object(obj_id: int, _parent = null) -> void:
	var value: Array = _get_obj_data(obj_id)
	if len(value) < 0: return
	ConsumptionIncome.disabled = id != null
	Title.set_text(value[0].title)
	ConsumptionIncome.button_pressed = value[0].income
	Value.set_text(str(value[0].month_limit))

# Проверка введенных данных
func check_object() -> bool:
	Error.visible = false
	var values = Request.select(table, "id", 'title="'+Title.get_text()+'" AND income='+str(int(ConsumptionIncome.button_pressed)))
	# Проверка заполнености полей
	if Title.get_text() == "" and Value.get_text() == "": Global.set_error(Error, "Все поля должны быть заполнены")
	elif float(Value.get_text()) <= 0 and not ConsumptionIncome.button_pressed: Global.set_error(Error, "Значение должно быть больше нуля")
	return _set_error(values)
	
# Изменение значения названия кошелька
func _on_title_text_changed() -> void:
	Global.text_changed_TextEdit(Title)
	check_object()

# Изменение значения счета
func _on_value_text_changed() -> void:
	Global.text_changed_TextEdit(Value, true)
	check_object()
	
# Изменение значения типа статьи
func _on_consumption_income_toggled(toggled_on: bool) -> void:
	if toggled_on:
		ConsumptionIncome.set_text("Доход")
		if not Value.get_text(): Value.set_text("0.0")
	else: ConsumptionIncome.set_text("Расход")
	Value.visible = ConsumptionIncome.get_text() == "Расход"
	check_object()
	
# Обработка нажатия кнопки сохранения счета
func _on_apply_button_down() -> void:
	if check_object(): return
	_create_update(['"'+Title.get_text()+'"', float(Value.get_text()), int(ConsumptionIncome.button_pressed)])
