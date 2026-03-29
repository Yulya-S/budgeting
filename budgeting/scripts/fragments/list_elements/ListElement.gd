extends ColorRect
class_name ListElement

# Изменение размера контейнера по размеру родителя
func _ready() -> void:
	custom_minimum_size[0] = SF.g_p(self).size[0]
	_set_line_size()
	SF.color_and_lang(self)

# Получение имени строки со словом id
func _name_id(obj: Variant) -> String: return SF.l(obj).split("title")[0]+"id"

# Изменение высоты строки списка
func _set_line_size() -> void:
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
		if SF.l(i) not in data.keys(): continue # Отмена применения значения
		# Применение значений
		match i.get_class():
			"ProgressBar":
				i.value = data[SF.l(i)]
				i.modulate = ColorScheme.get_color(i.value, i.max_value, ColorScheme.scales_gradient)
			"ColorRect":
				if data[SF.l(i)] is bool: i.visible = data[SF.l(i)]
				elif data[SF.l(i)] is Color:
					i.color = data[SF.l(i)]
					i.visible = true
			"Label":
				if "title" not in SF.l(i) or not i.get("set_object"):
					i.set_text(str(data[SF.l(i)]))
				else:
					if _name_id(i) in data.keys():
						if data[_name_id(i)]: i.set_object(data[SF.l(i)],  data[_name_id(i)])
						elif data[SF.l(i)] == null: i.set_text("-")
	match scene_file_path.split("/")[-1].replace(".tscn", ""):
		"notification": $New.visible = bool(data.new)
		"event_legend": _event_values(data, "-" if data.event_type == 1 else "+")
		"event":
			_event_values(data, "__ET" + str(data.event_type))
			$Completed.modulate = color
			$Completed.visible = data.completed
			$Completed.size = custom_minimum_size
		"section":
			if SF.g_p(self).obj == Request.ObjectVariants.SUBSECTION:
				$Title.next_page = Global.Pages.SUBSECTION
				$Title.next_page_dir = Global.Dirs.WINDOWS
			else: $ConsumptionIncome.set_text("" if data.id <= 2 else "__CI" + str(data.income))
			$Progress.visible = not data.income and data.month_limit > 0
			$Marker.size[1] = custom_minimum_size[1]
			if data.month_limit <= 0 or data.income: $Month_Limit.set_text("")
		"cash_flow":
			match data.section_id:
				1: $Title.next_page = Global.Pages.TRANSFER
				2:
					if data.subsection_id == 2:
						$Wallet_2_Title.next_page = Global.Pages.LOAN
						$Title.next_page = Global.Pages.PAYMENT
					else:
						$Wallet_Title.next_page = Global.Pages.LOAN
						if data.subsection_id == 1: $Title.id = data.wallet_id
						else: $Wallet_2_Title.visible = false
						$Title.next_page = Global.Pages.LOAN if data.subsection_id == 1 else Global.Pages.PERCENT
				_:
					if data.income: $Wallet_Title.visible = false
					else: $Wallet_2_Title.visible = false
	File.set_lang(self)
	_set_line_size()

# Общая часть применения значений для объектов списков событий
func _event_values(data: Dictionary, et_text: String) -> void:
	$EventType.visible = data.event_type > 0
	$EventType.text = et_text
	$EventType/Value.text = str(data.value)
	# Отображение информации о нехватке средств для "расходных" событий
	if not data.completed and data.event_type == 1 and data.profit_accounting < 0:
		$EventType/Label.visible = true
