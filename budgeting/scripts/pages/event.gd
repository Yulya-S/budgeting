extends Page
# Подгружаемыу объекты
var objArray = load("res://scenes/fragments/obj_array.tscn")
var calendar = load("res://scenes/pages/events/calendar.tscn")
# Переменная
var start_update: bool = false # Был ли отправлен запрос на изменение страницы

# Начало создания объектов на странице
func _process(delta: float) -> void:
	if Request.completion_creation_et and start_update:
		Objects.update_data($Filter)
		start_update = false

# Запуск обновления данных на странице
func _update_page() -> void:
	# Применение цвета и перевода страницы
	ColorScheme.repainting(self)
	File.set_lang(self)
	# Удаление предыдущего формата отображения событий
	get_child(-1).queue_free()
	remove_child(get_child(-1))
	# Создание нового формата отображения событий
	if not Request.select(Request.Tables.SETTINGS)[0].event_page_calendar:
		add_child(calendar.instantiate())
		get_child(-1).size = Vector2(456, 473)
		get_child(-1).position = Vector2(0, 170)
	else:
		add_child(objArray.instantiate())
		get_child(-1).size = Vector2(1152, 473)
		get_child(-1).position = Vector2(0, 170)
	Objects = get_child(-1) # Получение пути к списку событий
	update_data() # Обновлениие данных в списке событий

# Отправка запроса на обновление таблицы с событиями
func update_data() -> void:
	start_update = true
	Request.start_create_multiplied_events_table($Filter.get_filter().date)

# Обработка нажатия кнопки создания события
func _on_add_event_button_down() -> void: Global.emit_signal("open_window", Global.Pages.EVENT)
