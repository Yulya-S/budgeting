extends Node2D

# Подключение сигналов
func _ready() -> void: Global.connect("open_window", Callable(self, "_open_window"))

# Открытие страницы изменения тайтла
func _open_window(page: Global.Pages, id = null, dir: Global.Dirs = Global.Dirs.WINDOWS) -> void:
	add_child(load("res://scenes/"+Global.enum_key(Global.Dirs, dir)+"/"+Global.enum_key(Global.Pages, page)+".tscn").instantiate())
	if id: get_child(-1).set_object(id)
