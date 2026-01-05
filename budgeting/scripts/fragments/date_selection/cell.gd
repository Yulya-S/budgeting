extends ColorRect
# Подключение пути к объекту в сцене
@onready var RectColor = $ColorRect

# Переменные
var id: int = 0 # Индекс объекта
var is_today: bool = false # Выбрана ли текущая ячейка
var state: Global.MouseOver = Global.MouseOver.NORMAL # Текущее состояние объекта

# Изменение цвета ячейки
func _process(_delta: float) -> void: update_color()

# Изменение номера дня
func set_object(obj_id: int, today: bool = false) -> void:
	id = obj_id
	if id > 0: $Number.set_text(str(id))
	is_today = today

# Изменение цвета ячейки
func update_color() -> void:
	if is_today: RectColor.color = Color.html("#f7cdcd")
	elif id != 0: RectColor.color = Color.html("#ffffff")
	else:
		RectColor.color = Color.html("#5f5f5f")
		return
	if state == Global.MouseOver.HOVER: color = Color.html("#39508e")
	else: color = Color.html("#000000")

# Обработка нажатия клавиш мыши 
func _input(event: InputEvent) -> void:
	if id == 0 or state == Global.MouseOver.NORMAL: return
	if event.is_action("click") and event.is_pressed(): get_parent().get_parent().update_day(id)

# Обработка наведения мыши на контейнер
func _on_color_rect_mouse_entered() -> void: state = Global.MouseOver.HOVER

func _on_color_rect_mouse_exited() -> void: state = Global.MouseOver.NORMAL
