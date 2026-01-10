extends GraphicsRenderer

# Получение значений для заполнения графика
func _update_values(values: Array, filter: Dictionary) -> Array:
	var total: float = Request.select_past_funds_movements(filter.date)
	for i in range(len(values)):
		values[i] += total
		total = values[i]
	return values
