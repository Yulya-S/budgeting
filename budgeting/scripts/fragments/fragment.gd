extends ColorRect
class_name PageFragment
# Экспортируемая переменная
@export var special_elements: Dictionary = {} # Значения для переадресации

# Смена размера цветовой линии под размер родителя
func _ready() -> void:
	custom_minimum_size[0] = get_parent().get_parent().size[0]
	update_minimum_size()
	
# Изменение значений в сцене
func set_values(data: Dictionary) -> void:
	for i in get_children():
		if i.name.to_lower() not in data.keys(): continue # Отмена применения значения
		# Применение значений
		if "title" in i.name.to_lower():
			# Изменение значения переадресации Label
			var id = 0
			if i.name.to_lower().split("title")[0]+"id" in data.keys():
				id = data[i.name.to_lower().split("title")[0]+"id"]
			if i.name.to_lower() in special_elements.keys():
				id = []
				for l in special_elements[i.name.to_lower()]: id.append(data[l])
			if data[i.name.to_lower()] == null: continue
			i.set_object(data[i.name.to_lower()], id)
		elif i is ColorRect: i.visible = data[i.name.to_lower()]
		else: i.set_text(str(data[i.name.to_lower()]))
