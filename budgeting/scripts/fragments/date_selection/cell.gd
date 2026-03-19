extends InteractiveObj
# Подключение пути к объекту в сцене
@onready var Number = $Number

# Запуск изменения цвета ячейки
func _ready() -> void: ColorScheme.repainting(self)

# Обработка смены цвета ячейки в процессе работы программы
func _process(_delta: float) -> void:
	ColorScheme.set_DS_cell_color(self, Number.get_text(), SF.g_p(self).selected_day.day == SF.L_to_int(Number), bool(state))

# Изменение номера дня
func set_values(idx: int, _current_month: bool, _next_month: bool, day_count: int) -> void:
	if idx >= 0 and idx < day_count: Number.set_text(str(idx + 1))

# Под проверка возможности обработки нажатия на объект
func _other_check() -> bool: return SF.L_is_empty(Number)

# Функция запускаемая при нажатии на объект
func _start_func() -> void: SF.g_p(self).update_day(SF.L_to_int(Number))

# Обработка наведения мыши на контейнер
func _on_mouse_entered() -> void:
	if SF.L_is_empty(Number): return
	super._on_mouse_entered()
