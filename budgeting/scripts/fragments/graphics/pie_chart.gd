extends Control
# Переменные
var radius: float = 50 # Радиус графика
var values: Array = [] # Значения для построения графика
var higliter_idx = null # Индекс выделенного фрагмента

# Сокрытие маркера и изменение радиуса диаграммы
func _ready() -> void:
	radius = min(size.x, size.y)/2.
	$Marker.visible = false

# Отрисовка графика
func _draw() -> void:
	# База для графика
	draw_circle(Vector2(radius, radius), radius + 4, Color.WHITE, true)
	draw_circle(Vector2(radius, radius), radius, Color.BLACK, false, 3)
	# Получение значений для расчета
	if len(values) == 0: return
	var sum: float = 0
	for i in values: sum += i
	var deg: float = 2
	# Создание секций
	for i in range(len(values)):
		if values[i] <= 0: continue
		# Смена цвета для секции
		var new_color: Color = ColorScheme.highlighter_color if higliter_idx == i else ColorScheme.get_color(i, len(values) - 1.)
		var arc_size: float = (values[i] * 360.) / sum
		if arc_size < 2: continue
		# Отрисовка секции
		draw_arc(Vector2(radius, radius), (radius/2.)+2., deg_to_rad(deg-2.), deg_to_rad(deg+arc_size+2.), int(arc_size+4), Color.BLACK, radius)
		draw_arc(Vector2(radius, radius), (radius-2)/2., deg_to_rad(deg), deg_to_rad(deg+arc_size), int(arc_size), new_color, radius)
		deg += arc_size

# Заполнение списка значений
func update_data(filter: ColorRect = null, key: String = "value") -> void:
	var filter_data: Dictionary = {}
	if filter: filter_data = filter.get_filter()
	else: filter_data = {"date": Global.date_to_str(), "where": "", "order": ""}
	values = []
	for i in Request.select_sections_list(filter_data.where, filter_data.date, filter_data.order): values.append(i[key])
	queue_redraw()
	
# Выделение области
func set_highlighter(index: int) -> void:
	higliter_idx = index
	queue_redraw()

# Сброс выделения области
func reset_highlighter(index: int) -> void:
	if index != higliter_idx: return
	higliter_idx = null
	queue_redraw()
