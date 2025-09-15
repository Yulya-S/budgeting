extends Control
# Подключение пути к объектам в сцене
@onready var Marker = $Marker

# Переменные
var radius: float = 50 # Радиус графика
var values: Array = [] # Значения для построения графика
var higliter_idx = null # Индекс выделенного фрагмента

# Сокрытие маркера и изменение радиуса диаграммы
func _ready() -> void:
	radius = min(size.x, size.y)/2.
	Marker.visible = false

# Отрисовка графика
func _draw() -> void:
	draw_circle(Vector2(radius, radius), radius, Color.BLACK, false)
	if len(values) == 0: return
	var sum: float = 0
	for i in values: sum += i
	var deg: float = 2
	for i in range(len(values)):
		if values[i] <= 0: continue
		# Смена цвета для секции
		var new_color: Color = ColorScheme.get_color(i, len(values) - 1.)
		if higliter_idx == i: new_color = Color.AQUAMARINE
		var arc_size: float = (values[i] * 360.) / sum
		if arc_size < 2: continue
		# Отрисовка секции
		draw_arc(Vector2(radius, radius), (radius/2.)+2., deg_to_rad(deg-2.), deg_to_rad(deg+arc_size+2.), int(arc_size+4), Color.BLACK, radius)
		draw_arc(Vector2(radius, radius), radius/2., deg_to_rad(deg), deg_to_rad(deg+arc_size), int(arc_size), new_color, radius)
		deg += arc_size

# Заполнение списка значений
func set_values(objects: Array, key: String = "value") -> void:
	values = []
	for i in objects: values.append(i[key])
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
		
	
	
