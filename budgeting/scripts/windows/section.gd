extends CreationWindow
# Подключение пути к объектам в сцене
@onready var Income = $Income
@onready var Title = $Title
@onready var MonthLimit = $Month_Limit

# Переменная
var ml_value: String = "0.0"

# Изменение информации о счете
func set_object(obj_id: int, parent: Variant = null) -> void:
	super.set_object(obj_id, parent)
	if "-1" in MonthLimit.get_text(): $Window.on_close_button_down()

# Проверка введенных данных
func check_object() -> bool:
	super.check_object()
	if float(MonthLimit.get_text()) <= 0 and not Income.button_pressed: Error.set_state(Error.States._E05)
	return _set_error(Request.select(table, "id", 'title="'+Title.get_text()+'" AND income='+str(int(Income.button_pressed))))
	
# Изменение значения типа статьи
func _on_consumption_income_toggled(toggled_on: bool) -> void:
	Income.set_text("Доход" if toggled_on else "Расход")
	if toggled_on: ml_value = MonthLimit.get_text()
	else: MonthLimit.set_text(ml_value)
	if not MonthLimit.get_text() or toggled_on: MonthLimit.set_text("0.0")
	MonthLimit.visible = not Income.button_pressed
	check_object()
