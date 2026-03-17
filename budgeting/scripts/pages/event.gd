extends Page
# Подгружаемые объекты
var objArray: Resource = load("res://scenes/fragments/obj_array.tscn")
var calendar: Resource = load("res://scenes/pages/events_calendar/calendar.tscn")
# Переменная
var start_update: bool = false # Был ли отправлен запрос на изменение страницы

# Начало создания объектов на странице
func _process(_delta: float) -> void:
	if Request.completion_creation_et and start_update:
		Objects.update_data(Filter)
		start_update = false

# Создание нового формата отображения событий
func _create() -> void:
	if not Request._select_all(Request.Tables.SETTINGS)[0].event_page_calendar: _create_calendar(calendar, Vector2(456, 473))
	else: _create_calendar(objArray, Vector2(1152, 473))

# Создание календаря
func _create_calendar(obj: Resource, new_size: Vector2) -> void:
	add_child(obj.instantiate())
	get_child(-1).size = new_size
	get_child(-1).position = Vector2(0, 170)
	Objects = get_child(-1) # Сохранение пути к списку событий

# Отправка запроса на обновление таблицы с событиями
func update_data() -> void:
	Request.start_create_multiplied_events_table(Filter.get_filter().date)
	start_update = true

# Обработка нажатия кнопки создания события
func _on_add_event_button_down() -> void: Global.emit_signal("open_window", Global.Pages.EVENT)
