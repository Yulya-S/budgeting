extends PageFragment
# Подключение путей к объектам в сцене
@onready var Count = $Count
@onready var Total = $Total

# Обработка нажатия клавиш мыши
func _input(event: InputEvent) -> void: pass

# Изменение значений
func set_values(data: Dictionary) -> void:
	Title.set_text(str(data.title))
	Count.set_text(str(data.count))
	Total.set_text(str(data.value))
