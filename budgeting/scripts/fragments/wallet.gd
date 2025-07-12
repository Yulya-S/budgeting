extends ColorRect
# Подключение путей к объектам в сцене
@onready var Title = $Title
@onready var Value = $Value
@onready var CashFlow = $CashFlow

# Переменные
var id: int = 0
var state: Global.MouseOver = Global.MouseOver.NORMAL # Текущее состояние объекта

# Смена размера цветовой линии под размер родителя
func _ready() -> void:
	custom_minimum_size[0] = get_parent().get_parent().size[0]
	update_minimum_size()

# Изменение значений
func set_values(data: Dictionary) -> void:
	id = data.id
	Title.set_text(data.title)
	Value.set_text(str(data.value))
	
func _input(event: InputEvent) -> void:
	if state == Global.MouseOver.NORMAL: return
	if event.is_action("click") and event.is_pressed(): Global.emit_signal("open_window", Global.Pages.WALLET, id)

# Обработка наведения мыши на контейнер
func _on_title_mouse_entered() -> void: state = Global.MouseOver.HOVER

func _on_title_mouse_exited() -> void: state = Global.MouseOver.NORMAL
