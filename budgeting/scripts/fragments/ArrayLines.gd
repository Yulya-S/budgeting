extends Node
class_name ArrayLines
# Переменные
var lines: Array = [] # Список для создания
var change_list: Array = [] # Список для изменения
var path: Resource = null # Путь к сцене объекта для создания

# Изменение пути к объекту
func _init(new_path: String) -> void:
	path = load("res://scenes/fragments/list_elements/" + new_path + ".tscn")

# Обновление списков
func add_obj(parent: Variant, ObjectVariant: Request.ObjectVariants, requesting: Variant) -> void:
	if len(change_list) > 0: lines.append(Request.match_update_list_element(ObjectVariant, change_list.pop_front(), requesting))
	if len(lines) > 0: Global.add_new_child(parent, path, [lines.pop_front()])

# Очистка списка
func clear(values: Array, parent: Variant) -> void:
	Global.clear_scene(parent)
	if parent.get_parent().get("first_line") or parent.get_parent().name == "Events":
		parent.add_child(path.instantiate())
	change_list = values
	lines = []
