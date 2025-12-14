extends Control
# Подключение пути к объектам в сцене
@onready var Legend = $Legend/VBoxContainer
@onready var Cells = $Cells

var filter: ColorRect = null # Сохранение ссылки на фильтр

# Переменные
var legend_element_path: Resource = load("res://scenes/fragments/list_elements/event_legend.tscn") # Путь к сцене элемента легенды
var cell_path: Resource = load("res://scenes/pages/events/cell.tscn") # Путь к сцене ячеек календаря

var lines: Array = [] # Список объектов для создания на странице
var change_list: Array = []
var event_days: Array = []

var day_count: int = 30
var date: Dictionary = {}

func data_update(new_filter: ColorRect) -> void:
	if not filter: filter = new_filter
	
	for i in [Cells, Legend]: for l in i.get_children():
		l.queue_free()
		i.remove_child(l)
	
	Legend.add_child(legend_element_path.instantiate())
	
	var data_filter: Dictionary = filter.get_filter()
	Request.create_multiplied_events_table(data_filter.date)
	date = Time.get_datetime_dict_from_datetime_string(data_filter.date, true)
	if date.weekday == 0: date.weekday = 7
	day_count = Request.select_day_count(data_filter.date)	
	event_days = Request._select_event_days()
	_update_legend()
	
func _update_legend(idx: int = 0) -> void:
	if not idx: idx = Global.date.day
	change_list = Request.select_multiplied_events_list(filter.get_filter().date, str(idx))

func _process(delta: float) -> void:
	if len(change_list) > 0: lines.append(Request.match_update_list_element(Request.ObjectVariants.EVENT, change_list.pop_front(), self))
	if len(lines) > 0:
		Legend.add_child(legend_element_path.instantiate())
		Legend.get_child(-1).set_values(lines.pop_front())
	if Cells.get_child_count() < day_count + date.weekday - 1 or Cells.get_child_count() % 7 != 0:
		Cells.add_child(cell_path.instantiate())
		Cells.get_child(-1).set_values(Cells.get_child_count() - date.weekday, Global.date_comparison(Global.date, date, "==", false), day_count)
	elif len(event_days) > 0:
		var value: Dictionary = event_days.pop_front()
		Cells.get_child(int(value.date.split("-")[-1]) + date.weekday - 2).add_event()


## Изменение параметров запроса
#func set_data(_where: String = "", new_date: String = "", _order: String = "") -> void:
	#if new_date != "":
		#date = new_date
		#day_count = Request.select_day_count(date)
	#if _where == "" and new_date == "" and _order == "": return
	#update_page()
	#
## Заполнение страницы
#func update_page(close_page: String = "") -> void:
	## Очистка страницы
	#for i in [Calendar, Legend]: for l in i.get_children():
		#l.queue_free()
		#i.remove_child(l)
	## Создание первой строки легенды
	#Legend.add_child(legend_element_path.instantiate())
	#Legend.get_child(-1).color = Color.html("#dfdfdf")
	## Получение данных
	#events_color = {}
	#lines = Request.select_events(date)
	#for i in lines: if i.event_id not in events_color.keys():
		#events_color[i.event_id] = "#ffffff"
		#legend_objects.append(i)
		#legend_objects[-1].id = i.event_id
	#for i in range(len(events_color.keys())):
		#events_color[events_color.keys()[i]] = ColorScheme.get_color(events_color.keys()[i]-1, Request.select(Request.Tables.EVENTS, "COUNT(id)-1 count")[0].count)
		#legend_objects[i].color = events_color[events_color.keys()[i]]
	## Обновление страницы родителя
	#if get_parent().get("update_page"):	get_parent().update_page(close_page)
#
## Выделение событий цветом
#func mark_event(id: int) -> void: for i in Calendar.get_children(): i.mark_event(id)
#
## Снятие выделения с события
#func deselect_event(id: int, color: Color) -> void: for i in Calendar.get_children(): i.deselect_event(id, color)
