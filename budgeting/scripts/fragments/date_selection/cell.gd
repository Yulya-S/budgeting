extends ColorRect
# Подключение пути к объекту в сцене
@onready var Number = $Number
# Переменная
var state: Global.MouseOver = Global.MouseOver.NORMAL # Текущее состояние объекта

# Запуск изменения цвета ячейки
func _ready() -> void: ColorScheme.repainting(self)

# Обработка смены ячейки в процессе работы программы
func _process(_delta: float) -> void:
	ColorScheme.set_DS_cell_color(self, Number.get_text(), SF.g_p(self).selected_day.day == SF.L_to_int(Number), bool(state))

# Изменение номера дня
func set_values(idx: int, _current_month: bool, _next_month: bool, day_count: int) -> void:
	if idx >= 0 and idx < day_count: Number.set_text(str(idx + 1))

# Обработка нажатия клавиш мыши 
func _input(event: InputEvent) -> void:
	if SF.L_is_empty(Number) or state == Global.MouseOver.NORMAL: return
	if event.is_action("click") and event.is_pressed():
		SF.g_p(self).update_day(SF.L_to_int(Number))

# Обработка наведения мыши на контейнер
func _on_mouse_entered() -> void:
	if SF.L_is_empty(Number): return
	state = Global.MouseOver.HOVER

func _on_mouse_exited() -> void: state = Global.MouseOver.NORMAL
