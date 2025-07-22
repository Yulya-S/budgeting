extends ColorRect
# Подключение путей к объектам в сцене
@onready var Title = $Title
@onready var Count = $Count
@onready var Total = $Total

# Смена размера цветовой линии под размер родителя
func _ready() -> void:
	custom_minimum_size[0] = get_parent().get_parent().size[0]
	update_minimum_size()

# Изменение значений
func set_values(data: Dictionary) -> void:
	Title.set_text(data.title)
	Count.set_text(str(data.count))
	Total.set_text(str(data.value))
