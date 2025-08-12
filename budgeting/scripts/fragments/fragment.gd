extends ColorRect
class_name PageFragment
# Подключение пути к объектам в сцене
@onready var Title = $Title

# Переменные
var id = 0 # Индекс объекта
var state: Global.MouseOver = Global.MouseOver.NORMAL # Текущее состояние объекта

# Смена размера цветовой линии под размер родителя
func _ready() -> void:
	custom_minimum_size[0] = get_parent().get_parent().size[0]
	update_minimum_size()

# Обработка нажатия клавиш мыши
func _input(event: InputEvent) -> void:
	if state == Global.MouseOver.NORMAL or not id: return
	if event.is_action("click") and event.is_pressed():
		var parent = get_parent().get_parent()
		Global.emit_signal(parent.signal_name, parent.next_page, id, parent.next_page_dir)

# Обработка наведения мыши на контейнер
func _on_title_mouse_entered() -> void: state = Global.MouseOver.HOVER

func _on_title_mouse_exited() -> void: state = Global.MouseOver.NORMAL
