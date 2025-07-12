extends Node2D
# Пути к подгружаемым сценам
const WindowsDir: String = "res://scenes/windows/"

# Подключение сигналов
func _ready() -> void: Global.connect("open_window", Callable(self, "_open_window"))

# Открытие страницы изменения тайтла
func _open_window(page: Global.Pages, id = null) -> void:
	add_child(load(WindowsDir+Global.enum_key(Global.Pages, page)+".tscn").instantiate())
	if id: get_child(-1).set_object(id)
