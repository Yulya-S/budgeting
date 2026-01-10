extends Page
	
# Получение данных фильтра
func _get_filter(obj: Variant) -> Array:
	var filter_data: Dictionary = Filter.get_filter()
	if "Rep" in obj.get_parent().name: filter_data.where = obj.get_parent().name.replace("Rep", "").to_lower()
	elif obj.get_parent().name == "Sections":
		filter_data.where = "s.month_limit>=0"
		filter_data.order = "value DESC"
	return [filter_data]
