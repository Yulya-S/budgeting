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
	if get_child_count() > 0 and "Inf" in get_child(-1).name and Global.enum_key(Global.Pages, page).replace("_", "") == get_child(-1).name.to_lower(): return
	print("res://scenes/"+Global.enum_key(Global.Dirs, dir)+"/"+Global.enum_key(Global.Pages, page)+".tscn")
	add_child(load("res://scenes/"+Global.enum_key(Global.Dirs, dir)+"/"+Global.enum_key(Global.Pages, page)+".tscn").instantiate())
	if id and get_child(-1).get("set_object"): get_child(-1).set_object(id, parent)

# Очистка экрана и открытие новой страницы
func _open_new_page(page: Global.Pages, id = null, parent = null) -> void:
	Global.current_page = page
	for i in get_children():
		i.queue_free()
		remove_child(i)
	_open_window(page, id, Global.Dirs.PAGES, parent)
