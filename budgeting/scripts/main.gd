extends Node2D

# Подключение сигналов
func _ready() -> void:
	Global.connect("open_window", Callable(self, "_open_window"))
	Global.connect("open_new_page", Callable(self, "_open_new_page"))

# Закрытие БД во время закрытия приложения
func _notification(what) -> void:
	if Request.db: if what == Window.NOTIFICATION_WM_CLOSE_REQUEST: Request.db.close_db()

# Открытие страницы
func _open_window(page: Global.Pages, id = null, dir: Global.Dirs = Global.Dirs.WINDOWS, parent = null) -> void:
	add_child(load("res://scenes/"+Global.enum_key(Global.Dirs, dir)+"/"+Global.enum_key(Global.Pages, page)+".tscn").instantiate())
	if id: get_child(-1).set_object(id, parent)

# Очистка экрана и открытие новой страницы
func _open_new_page(page: Global.Pages) -> void:
	Global.current_page = page
	for i in get_children():
		i.queue_free()
		remove_child(i)
	_open_window(page, null, Global.Dirs.PAGES)
