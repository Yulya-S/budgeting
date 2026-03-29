extends InteractiveObj
# Экспортируемые переменные
@export var next_page: Global.Pages = Global.Pages.WALLET # Страниц перехода
@export var next_page_dir: Global.Dirs = Global.Dirs.PAGES # Директория перехода
# Переменная
var id: int = 0 # Индекс объекта

# Применение текстового значения и индекса целевого объекта
func set_object(new_text: String, new_id: int) -> void:
	set("text", new_text)
	id = new_id

# Под проверка возможности обработки нажатия на объект
func _other_check() -> bool: return not id

# Функция запускаемая при нажатии на объект
func _start_func() -> void:
	if next_page_dir == Global.Dirs.PAGES: SF.op_np(next_page)
	else: SF.op_w(next_page, id, next_page_dir)
