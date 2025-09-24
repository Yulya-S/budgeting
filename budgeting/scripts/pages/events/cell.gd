extends ColorRect
# Подключение путей к объектам в сцене
@onready var Background = $Background
@onready var Number = $Label
@onready var Objects = $VBoxContainer

# Изменение номера дня
func set_object(lines: Array, index: int, today: bool = false):
	Number.set_text(str(index))
	if today: Background.color = Color.html("#f7cdcd")
	else: Background.color = Color.html("#ffffff")
