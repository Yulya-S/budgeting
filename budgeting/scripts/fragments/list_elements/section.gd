extends List_element
# Переменная
var m_index: int = 0 # Индекс объекта для изменения цветового маркера

# Изменение значений
func set_values(data: Dictionary) -> void:
	super.set_values(data)
	m_index = get_parent().get_child_count() - 2
	$Progress.size[1] -= 10
	
# Вызов функции подстветки сектора на графике
func _highlighting(set_highlighting: bool = true) -> void:
	if $Title.id: Global.run_func($"../../../", "highlighting_graph_sections", [m_index, set_highlighting])
	
# Обработка наведения мыши на контейнер
func _on_mouse_entered() -> void: _highlighting(true)

func _on_mouse_exited() -> void: _highlighting(false)
