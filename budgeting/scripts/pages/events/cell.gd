extends ColorRect
# Подключение путей к объектам в сцене
@onready var Background = $Background
@onready var Number = $Label
@onready var Objects = $ScrollContainer/VBoxContainer
@onready var Completed = $Completed

# Переменная
var event_path: Resource = load("res://scenes/fragments/list_elements/color_event.tscn")

# Изменение номера дня
func set_object(index: int, today: bool = false, complete: bool = false):
	Number.set_text(str(index))
	if today: Background.color = Color.html("#f7cdcd")
	else: Background.color = Color.html("#ffffff")
	Completed.visible = complete
	for i in range(len(get_parent().lines)):
		if int(get_parent().lines[0].date.split("-")[-1]) != index: break
		Objects.add_child(event_path.instantiate())
		Objects.get_child(-1).set_object(get_parent().lines[0], get_parent().events)
		get_parent().lines.pop_front()
	
