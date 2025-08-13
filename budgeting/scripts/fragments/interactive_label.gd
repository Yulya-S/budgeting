extends Label
class_name InteractiveLabel
# Экспортируемые переменные
@export var signal_name: String = "open_window" # Наименование сигнала, который будет отправлен при переходе
@export var next_page: Global.Pages = Global.Pages.WALLET_INF # Страница, на которую произойдет переход
@export var next_page_dir: Global.Dirs = Global.Dirs.PAGES # Директория, на которую произойдет переход

# Переменная
var id = null # Индекс объекта
var state: Global.MouseOver = Global.MouseOver.NORMAL  # Текущее состояние объекта

# Применение текстового значения и индекса целевого объекта
func set_object(new_text: String, new_id):
	set_text(new_text)
	id = new_id

# Обработка нажатия клавиш мыши
func _input(event: InputEvent) -> void:
	if state == Global.MouseOver.NORMAL or not id: return
	if event.is_action("click") and event.is_pressed():
		Global.emit_signal(signal_name, next_page, id, next_page_dir)

# Обработка наведения мыши на контейнер
func _on_mouse_entered() -> void: state = Global.MouseOver.HOVER

func _on_mouse_exited() -> void: state = Global.MouseOver.NORMAL
