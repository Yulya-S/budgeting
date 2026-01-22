extends ColorRect
class_name Fragment
# Подключение пути к объекту в сцене
@onready var Title = get_node_or_null("Title")

# Изменение размера контейнера по размеру родителя
func _ready() -> void:
	if get_parent().get_child_count() == 1: File.set_lang(self)
	custom_minimum_size[0] = get_parent().get_parent().size[0]
	set_line_size()
	ColorScheme.repainting(self)
	
# Изменение высоты строки списка
func set_line_size() -> void:
	var max_count: int = 1
	var front_size: int = 16
	for i in get_children(): if i is Label: if i.get_line_count() > max_count:
		max_count = i.get_line_count() 
		front_size = i.get_theme_font_size("front_size")
	custom_minimum_size[1] = max_count * front_size + ((max_count - 1) * 2) + 10.
	for i in get_children(): if i.get("size"): i.size[1] = custom_minimum_size[1]
	
# Изменение значений в сцене
func set_values(data: Dictionary) -> void:
	for i in get_children():
		if i.name.to_lower() not in data.keys(): continue # Отмена применения значения
		# Применение значений
		match i.get_class():
			"ProgressBar":
				i.value = data[i.name.to_lower()]
				i.modulate = ColorScheme.get_color(i.value, i.max_value, ColorScheme.scales_gradient)
			"ColorRect":
				if data[i.name.to_lower()] is bool: i.visible = data[i.name.to_lower()]
				elif data[i.name.to_lower()] is Color:
					i.color = data[i.name.to_lower()]
					i.visible = true
			"Label":
				if "title" not in i.name.to_lower() or not i.get("set_object"):
					i.set_text(str(data[i.name.to_lower()]))
				else:
					if i.name.to_lower().split("title")[0]+"id" in data.keys(): i.set_object(data[i.name.to_lower()],  data[i.name.to_lower().split("title")[0]+"id"])
					elif data[i.name.to_lower()] == null: continue
	_set_special_values(data)
	File.set_lang(self)
	set_line_size()

# Применение значений для особых элементов списка
func _set_special_values(data: Dictionary) -> void:
	match scene_file_path.split("/")[-1].replace(".tscn", ""):
		"notification": $New.visible = bool(data.new)
		"event_legend": _event_values(data, "-" if data.event_type == 1 else "+")
		"event":
			_event_values(data, "__ET" + str(data.event_type))
			$Completed.modulate = color
			$Completed.visible = data.completed
			$Completed.size = custom_minimum_size
		"section":
			$ConsumptionIncome.set_text("" if data.id <= 4 else "__CI" + str(data.income))
			$Progress.visible = not data.income and data.month_limit > 0
			$Marker.size[1] = custom_minimum_size[1]
			if data.month_limit <= 0 or data.income: $Month_Limit.set_text("")
		"cash_flow":
			match data.section_id:
				1: Title.next_page = Global.Pages.TRANSFER
				2, 4:
					$Wallet_Title.next_page = Global.Pages.LOAN_INF
					Title.next_page = Global.Pages.LOAN if data.section_id == 2 else Global.Pages.PERCENT
				3:
					$Wallet_2_Title.next_page = Global.Pages.LOAN_INF
					Title.next_page = Global.Pages.PAYMENT
				_: $Wallet_2_Title.visible = false
		
# Общая часть применения значений для объектов списков событий
func _event_values(data: Dictionary, et_text: String) -> void:
	$EventType.visible = data.event_type > 0
	$EventType.text = et_text
	$EventType/Value.text = str(data.value)
	# Отображение информации о нехватке средств для "расходных" событий
	if not data.completed and data.event_type == 1 and data.profit_accounting < 0: $EventType/Label.visible = true
