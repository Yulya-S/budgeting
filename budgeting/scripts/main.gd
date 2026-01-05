extends Node2D
# Подключение пути к объекту в сцене
@onready var DayTimer = $Timer

# Создание сцены
func _ready() -> void:
	# Подключение сигналов
	Global.connect("open_window", Callable(self, "_open_window"))
	Global.connect("open_new_page", Callable(self, "_open_new_page"))
	# Изменение значения оставшегося в сутках времени
	DayTimer.start((60. * 60. * 24.) - (Global.get_date().second + (60. * Global.get_date().minute) + (60. * 60. * Global.get_date().hour)))

# Обработка окончания работы таймера
func _on_timer_timeout() -> void:
	DayTimer.start(60. * 60. * 24.)
	Global.sys_date.set_value(Time.get_datetime_string_from_system())
	Global.emit_signal("update_page")
	for i in get_children(): Global.run_func(i, "new_day")

# Закрытие БД во время закрытия приложения
func _notification(what: int) -> void: if Request.db: if what == Window.NOTIFICATION_WM_CLOSE_REQUEST: Request.db.close_db()

# Открытие страницы
func _open_window(page: Global.Pages, id: Variant = null,
	dir: Global.Dirs = Global.Dirs.WINDOWS, parent: Variant = null) -> void:
	if get_child_count() > 0 and "Inf" in get_child(-1).name and Global.enum_key(Global.Pages, page).replace("_", "") == get_child(-1).name.to_lower(): return
	add_child(load("res://scenes/"+Global.enum_key(Global.Dirs, dir)+"/"+Global.enum_key(Global.Pages, page)+".tscn").instantiate())
	if id: Global.run_func(get_child(-1), "set_object", [id, parent])

# Очистка экрана и открытие новой страницы
func _open_new_page(page: Global.Pages, id: Variant = null, parent: Variant = null) -> void:
	Global.current_page = page
	for child in get_children():
		if child.name == "Timer": continue
		Global.delete_child(self, child)
	_open_window(page, id, Global.Dirs.PAGES, parent)
