extends ColorRect
class_name PageFragment
# Подключение пути к объектам в сцене
@onready var Title = $Title

# Смена размера цветовой линии под размер родителя
func _ready() -> void:
	custom_minimum_size[0] = get_parent().get_parent().size[0]
	update_minimum_size()
