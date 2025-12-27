extends ColorRect
# Подключение путей к объектам в сцене
@onready var Parent = $"../../"
@onready var Number = $Label

# Запуск изменения цвета ячейки
func _ready() -> void: ColorScheme.repainting(self)

# Изменение номера дня
func set_values(idx: int, current_month: bool, next_month: bool, day_count: int) -> void:
	if idx >= 0 and idx < day_count:
		Number.set_text(str(idx+1))
		if get_parent().get_child_count() % 7 in [0, 6]: color = ColorScheme.get_sys_color(4.7)
		if current_month and Global.date.day == idx + 1: color = ColorScheme.get_sys_color(3)
	else: color = ColorScheme.get_sys_color(6)
	if (not next_month or not Number.text) and (Global.date.day > idx + 1 or day_count <= idx or not current_month):
		$Completed.visible = true
		$Completed.modulate = ColorScheme.get_color(95, 100)
	
# Изменение видимости маркера наличия событий
func add_event(): $Marker.visible = true
	
# Обработка наведения курсоры мыши на ячейку
func _on_mouse_entered() -> void: Global.run_func(Parent, "set_cell", [Number.text])

func _on_mouse_exited() -> void: Global.run_func(Parent, "reset_cell", [Number.text])
