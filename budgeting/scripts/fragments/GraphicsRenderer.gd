extends Control
class_name GraphicsRenderer
# Подключение пути к объекту в сцене
@onready var DrawingArea = $ColorRect

# Перезапуск отрисовки графика
func update_data(filter: Variant = {}) -> void:
	ColorScheme.repainting(self)
	var filter_data = Global.get_filter(filter)
	var values: Array = []
	var data: Array = Request.select_cash_flow_graphics(filter_data.where, filter_data.date)
	for i in range(Request.select_day_count(filter_data.date)): values.append(0.0)
	for i in data: values[int(i.day) - 1] = i.value
	DrawingArea.set_values(_update_values(values, filter_data))

# Получение значений для заполнения графика
func _update_values(values: Array, _filter: Dictionary) -> Array: return values
