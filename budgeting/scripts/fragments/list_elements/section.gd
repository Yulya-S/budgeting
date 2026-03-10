extends List_element
# Подключение пути к объекту в сцене
@onready var ParentPage = $"../../../"
# Переменная
var m_index: int = 0 # Индекс объекта для изменения цветового маркера

# Изменение значений
func set_values(data: Dictionary) -> void:
	super.set_values(data)
	m_index = get_parent().get_child_count() - 2
	$Progress.size[1] -= 10
	
# Обработка наведения мыши на контейнер
func _on_mouse_entered() -> void: if Title.id: Global.run_func(ParentPage, "highlighting_graph_sections", [m_index])

func _on_mouse_exited() -> void: if Title.id: Global.run_func(ParentPage, "highlighting_graph_sections", [m_index, false])
