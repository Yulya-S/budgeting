extends Page
	
# Обновление данных
func update_data() -> void: _find_objects($ScrollContainer/VBoxContainer)

# Поиск и запуск изменения списков и графиков
func _find_objects(obj: Variant) -> void:
	var filter_data: Dictionary = Filter.get_filter()
	if obj.get_parent().name == "Sections":
		filter_data.where = "s.month_limit>=0"
		filter_data.order = "value DESC"
	elif "Rep" in obj.get_parent().name: filter_data.where = obj.get_parent().name.replace("Rep", "").to_lower()
	Global.run_func(obj, "update_data", [filter_data])
	for i in obj.get_children(): _find_objects(i)
