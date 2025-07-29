extends ColorRect
class_name PageFragment
# Подключение путей к объектам в сцене
@onready var Title = $Title

# Экспортируемые переменные
@export var next_page: Global.Pages = Global.Pages.WALLET_INF # Страница на которую произойдет переход
@export var next_page_dir: Global.Dirs = Global.Dirs.PAGES # Директория на которую произойдет переход
@export var signal_name: String = "open_window" # Наименование сигнала который будет отправлен при переходе

# Переменные
var id: int = 0 # Индекс объекта
var state: Global.MouseOver = Global.MouseOver.NORMAL # Текущее состояние объекта

# Смена размера цветовой линии под размер родителя
func _ready() -> void:
	custom_minimum_size[0] = get_parent().get_parent().size[0]
	update_minimum_size()

# Обработка нажатия клавиш мыши
func _input(event: InputEvent) -> void:
	if state == Global.MouseOver.NORMAL or not id: return
	if event.is_action("click") and event.is_pressed(): Global.emit_signal(signal_name, next_page, id, next_page_dir)

# Обработка наведения мыши на контейнер
func _on_title_mouse_entered() -> void: state = Global.MouseOver.HOVER

func _on_title_mouse_exited() -> void: state = Global.MouseOver.NORMAL
