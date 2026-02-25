extends ColorRect
# Подключение пути к объекту в сцене
@onready var Number = $Number
# Переменная
var state: Global.MouseOver = Global.MouseOver.NORMAL # Текущее состояние объекта

# Запуск изменения цвета ячейки
func _ready() -> void: ColorScheme.repainting(self)

# Обработка смены ячейки в процессе работы программы
func _process(delta: float) -> void:
	ColorScheme.set_DS_cell_color(self, Number.get_text(), Global.g_parent(self, 2).selected_day.day == int(Number.get_text()), bool(state))

# Изменение номера дня
func set_values(idx: int, _current_month: bool, _next_month: bool, day_count: int) -> void:
	if idx >= 0 and idx < day_count: Number.set_text(str(idx + 1))

# Обработка нажатия клавиш мыши 
func _input(event: InputEvent) -> void:
	if Number.get_text() == "" or state == Global.MouseOver.NORMAL: return
	if event.is_action("click") and event.is_pressed():
		Global.g_parent(self, 2).update_day(int(Number.get_text()))

# Обработка наведения мыши на контейнер
func _on_mouse_entered() -> void:
	if Number.get_text() == "": return
	state = Global.MouseOver.HOVER

func _on_mouse_exited() -> void: state = Global.MouseOver.NORMAL
