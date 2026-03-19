extends Node2D
# Подключение пути к объекту в сцене
@onready var DayTimer = $Timer

# Создание сцены
func _ready() -> void:
	# Подключение сигналов
	Global.connect("open_window", Callable(self, "_open_window"))
	Global.connect("open_new_page", Callable(self, "_open_new_page"))
	# Изменение значения оставшегося в сутках времени
	DayTimer.start(_day_time() - (_date_f() + _date_f(1) + _date_f(2)))

# Закрытие БД во время закрытия приложения
func _notification(what: int) -> void:
	if Request.db and what == Window.NOTIFICATION_WM_CLOSE_REQUEST:
		Request.db.close_db()
		Request.db = null

# Получение суммарного значения времени в сутках
func _day_time() -> float: return 60. * 60. * 24.

# Получение суммарного значения времени в сутках
func _date_f(level: float = 0) -> float:
	return (60. ** level) * Global.get_date()[["second", "minute", "hour"][level]]

# Обновление даты последнего входа
func _update_last_entry() -> void:
	if Global.current_page == Global.Pages.REGISTRATION: return
	if Request.select_last_entry() == Global.date_to_str(): return
	Global.add_new_child(self, load("res://scenes/pages/load.tscn"))
	Request.update_last_entry()

# Обработка окончания работы таймера
func _on_timer_timeout() -> void:
	DayTimer.start(_day_time())
	Global.sys_date.set_value(Time.get_datetime_string_from_system())
	_update_last_entry()

# Запуск изменения данных на страницах
func start_update() -> void:
	Global.emit_signal("update_page")
	for i in get_children(): Global.run_func(i, "new_day")

# Открытие страницы
func _open_window(page: Global.Pages, id: Variant = null,
	dir: Global.Dirs = Global.Dirs.WINDOWS, parent: Variant = null) -> void:
	Global.add_new_child(self, load("res://scenes/"+Global.enum_key(Global.Dirs, dir)+"/"+Global.enum_key(Global.Pages, page)+".tscn"))
	if not _ch_inf(): get_child(-1).set_page(id, page)
	elif dir == Global.Dirs.WINDOWS and id:
		if parent != null: get_child(-1).set_from_page(id, parent)
		else: get_child(-1).set_page(id)
	if get_child_count() > 1 and _check_inf_page(): Global.delete_child(self, get_child(-1))

# Проверка имени крайней страницы
func _check_inf_page() -> bool:
	if _ch_inf(-2) or _ch_inf(): return false
	if _ch_par("page_type") and _ch_par(): return true
	return false

# Проверка что страница является инфомрационной
func _ch_inf(idx: int = -1) -> bool:
	return not _ch_name("@", idx) and not _ch_name("Inf", idx)
	
# Проверка фрагмена названия дочернего элемента
func _ch_name(text: String = "@", idx: int = -1) -> bool: return text in get_child(idx).name

# Проверка равенства параметров двух дочерних элементов
func _ch_par(param_name: String = "idx", idx_1: int = -1, idx_2: int = -2) -> bool:
	return get_child(idx_1).get(param_name) == get_child(idx_2).get(param_name)

# Очистка экрана и открытие новой страницы
func _open_new_page(page: Global.Pages, id: Variant = null, parent: Variant = null) -> void:
	if Global.current_page == Global.Pages.REGISTRATION: Global.update_sys_date()
	Global.current_page = page
	for child in get_children():
		if child.name == "Timer": continue
		Global.delete_child(self, child)
	_open_window(page, id, Global.Dirs.PAGES, parent)
	if page == Global.Pages.CASH_FLOW and id: get_child(-1).set_cash_flow_filter(id, parent)
	_update_last_entry()

# Проверка закрытия окна информации при удалении объекта
func close_inf_page() -> void:
	if not _ch_inf(-2) and get_child(-1).name != "Subsection": get_child(-2)._on_back_button_down()
