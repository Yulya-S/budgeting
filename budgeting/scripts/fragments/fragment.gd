extends ColorRect
class_name PageFragment
# Экспортируемая переменная
@export var special_elements: Dictionary = {} # Значения для переадресации

# Смена размера цветовой линии под размер родителя
func _ready() -> void:
	if get_parent().get_child_count() == 1: File.set_lang(self)
	custom_minimum_size[0] = get_parent().get_parent().size[0]
	update_minimum_size()
	ColorScheme.repainting(self)
	
# Изменение значений в сцене
func set_values(data: Dictionary) -> void:
	for i in get_children():
		if i.name.to_lower() not in data.keys(): continue # Отмена применения значения
		# Применение значений
		if "title" in i.name.to_lower():
			# Изменение значения переадресации Label
			var id: Variant = 0
			if i.name.to_lower().split("title")[0]+"id" in data.keys():
				id = data[i.name.to_lower().split("title")[0]+"id"]
			if i.name.to_lower() in special_elements.keys():
				id = []
				for l in special_elements[i.name.to_lower()]: if l in data.keys(): id.append(data[l])
			if data[i.name.to_lower()] == null: continue
			i.set_object(data[i.name.to_lower()], id)
		elif i is ProgressBar:
			i.value = data[i.name.to_lower()]
			i.modulate = ColorScheme.get_color(i.value, i.max_value, ColorScheme.scales_gradient)
		elif i is ColorRect:
			if data[i.name.to_lower()] is Color:
				i.color = data[i.name.to_lower()]
				i.visible = true
			elif data[i.name.to_lower()] is bool: i.visible = data[i.name.to_lower()]
		else: i.set_text(str(data[i.name.to_lower()]))
