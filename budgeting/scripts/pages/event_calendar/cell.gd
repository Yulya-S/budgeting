extends ColorRect
# Подключение пути к объекту в сцене
@onready var Number = $Label

# Запуск изменения цвета ячейки
func _ready() -> void: ColorScheme.repainting(self)

# Изменение номера дня
func set_values(idx: int, current_month: bool, next_month: bool, day_count: int) -> void:
	if idx >= 0 and idx < day_count: Number.set_text(str(idx+1))
	ColorScheme.set_calendar_cell_color(self, get_parent().get_child_count() % 7 in [0, 6],
		current_month and Global.get_date().day == idx + 1,
		not next_month and (Global.get_date().day > idx + 1 or day_count <= idx or not current_month))

# Изменение видимости маркера наличия событий
func add_event() -> void: $Marker.visible = true

# Обработка наведения курсоры мыши на ячейку
func _on_mouse_entered() -> void: Global.run_func($"../../", "set_cell", [Number.text])

func _on_mouse_exited() -> void: Global.run_func($"../../", "reset_cell", [Number.text])
