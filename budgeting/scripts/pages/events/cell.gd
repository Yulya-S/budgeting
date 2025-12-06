extends ColorRect
# Подключение путей к объектам в сцене
@onready var Background = $Background
@onready var Number = $Label
@onready var Objects = $ScrollContainer/VBoxContainer
@onready var Completed = $Completed

# Подгружаемый объект
var event_path: Resource = load("res://scenes/fragments/list_elements/color_event.tscn")

# Изменение номера дня
func set_object(index: int, today: bool = false, complete: bool = false):
	Number.set_text(str(index))
	if today: Background.color = Color.html("#f7cdcd")
	else: Background.color = Color.html("#ffffff")
	Completed.visible = complete
	for i in range(len(get_parent().get_parent().lines)):
		if int(get_parent().get_parent().lines[0].date.split("-")[-1]) != index: break
		Objects.add_child(event_path.instantiate())
		Objects.get_child(-1).set_object(get_parent().get_parent().lines[0], get_parent().get_parent().events_color)
		get_parent().get_parent().lines.pop_front()

# Выделение событий цветом
func mark_event(id: int) -> void: for i in Objects.get_children(): if i.id == id: i.color = Color.AQUAMARINE

# Снятие выделения с события
func deselect_event(id: int, color: Color) -> void: for i in Objects.get_children(): if i.id == id: i.color = color
