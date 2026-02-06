extends Label
# Экспортируемые переменные
@export var next_page: Global.Pages = Global.Pages.WALLET_INF # Страниц перехода
@export var page_type: Global.Pages = Global.Pages.WALLET
@export var next_page_dir: Global.Dirs = Global.Dirs.PAGES # Директория перехода

# Переменные
var id: int = 0 # Индекс объекта
var state: Global.MouseOver = Global.MouseOver.NORMAL # Текущее состояние объекта

# Применение текстового значения и индекса целевого объекта
func set_object(new_text: String, new_id: int) -> void:
	set_text(new_text)
	id = new_id

# Обработка нажатия
func _input(event: InputEvent) -> void:
	if state == Global.MouseOver.NORMAL or not id: return
	if event.is_action("click") and event.is_pressed(): Global.emit_signal("open_window", next_page, id, next_page_dir, page_type)

# Обработка наведения мыши
func _on_mouse_entered() -> void: state = Global.MouseOver.HOVER

func _on_mouse_exited() -> void: state = Global.MouseOver.NORMAL
