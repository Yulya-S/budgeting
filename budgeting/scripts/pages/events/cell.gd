extends ColorRect
# Подключение пути к объектам в сцене
@onready var Parent = $"../../"

# Запуск изменения цвета ячейки
func _ready() -> void: ColorScheme.repainting(self)

# Изменение номера дня
func set_values(idx: int, current_month: bool, next_month: bool, day_count: int) -> void:
	if idx >= 0 and idx < day_count: $Label.set_text(str(idx+1))
	elif not $Label.text: color = ColorScheme.get_color(6, 6, ColorScheme.system_gradient)
	if $Label.text and get_parent().get_child_count() % 7 in [0, 6]: color = ColorScheme.get_color(4.7, 6, ColorScheme.system_gradient)
	if not next_month or Global.date.day > idx + 1 or day_count <= idx or not $Label.text:
		$Completed.visible = true
		$Completed.modulate = ColorScheme.get_color(95, 100)
	elif current_month and Global.date.day == idx + 1: color = ColorScheme.get_color(3, 6, ColorScheme.system_gradient)

# Изменение видимости маркера наличия событий
func add_event(): $Marker.visible = true
	
# Обработка наведения курсоры мыши на ячейку
func _on_mouse_entered() -> void: Parent.set_cell($Label.text)

func _on_mouse_exited() -> void: Parent.reset_cell($Label.text)
