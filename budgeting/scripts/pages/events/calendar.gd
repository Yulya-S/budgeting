extends FillingCalendar
# Подключение пути к объектам в сцене
@onready var Legend = $Legend/VBoxContainer

# Переменные
var legend_objects: Array = [] # Список объектов для заполнения легенды
var legend_element_path: Resource = load("res://scenes/fragments/list_elements/event_legend.tscn") # Путь к сцене элемента легенды

# Подключение сигнала
func _ready() -> void: Global.connect("update_page", Callable(self, "update_page"))

# Постепенное заполнение календаря
func _process(delta: float) -> void:
	super._process(delta)
	# Заполнение легенды
	if len(legend_objects) > 0:
		Legend.add_child(legend_element_path.instantiate())
		Legend.get_child(-1).set_values(legend_objects.pop_front())

# Изменение параметров запроса
func set_data(_where: String = "", new_date: String = "", _order: String = "") -> void:
	if new_date != "":
		date = new_date
		day_count = Request.select_day_count(date)
	if _where == "" and new_date == "" and _order == "": return
	update_page()
	
# Заполнение страницы
func update_page(close_page: String = "") -> void:
	# Очистка страницы
	for i in [Calendar, Legend]: for l in i.get_children():
		l.queue_free()
		i.remove_child(l)
	# Создание первой строки легенды
	Legend.add_child(legend_element_path.instantiate())
	Legend.get_child(-1).color = Color.html("#dfdfdf")
	# Получение данных
	events_color = {}
	lines = Request.select_events(date)
	for i in lines: if i.event_id not in events_color.keys():
		events_color[i.event_id] = "#ffffff"
		legend_objects.append(i)
		legend_objects[-1].id = i.event_id
	for i in range(len(events_color.keys())):
		events_color[events_color.keys()[i]] = ColorScheme.get_color(events_color.keys()[i]-1, Request.select(Request.Tables.EVENTS, "COUNT(id)-1 count")[0].count)
		legend_objects[i].color = events_color[events_color.keys()[i]]
	# Обновление страницы родителя
	if get_parent().get("update_page"):	get_parent().update_page(close_page)

# Выделение событий цветом
func mark_event(id: int) -> void: for i in Calendar.get_children(): i.mark_event(id)

# Снятие выделения с события
func deselect_event(id: int, color: Color) -> void: for i in Calendar.get_children(): i.deselect_event(id, color)
