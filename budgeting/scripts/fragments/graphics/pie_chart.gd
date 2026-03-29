extends Control
# Переменные
var values: Array = [] # Значения для построения графика
var higliter_idx: Variant = null # Индекс выделенного фрагмента

# Сокрытие маркера и изменение радиуса диаграммы
func _ready() -> void: $Marker.visible = false

# Отрисовка графика
func _draw() -> void:
	# База для графика
	var vector: Vector2 = Vector2(_radius(), _radius())
	draw_circle(vector, _radius() + 4., Color.WHITE, true)
	draw_circle(vector, _radius(), Color.BLACK, false, 3)
	# Получение значений для расчета
	if len(values) == 0: return
	var sum: float = 0
	for i in values: sum += i
	var deg: float = 2
	# Создание секций
	for i in range(len(values)):
		if values[i] <= 0: continue
		var arc_step: float = (values[i] * 360.) / sum
		if arc_step < 2: continue
		_draw_arc((_radius()/2.) + 2., deg - 2., deg + arc_step+2., int(arc_step + 4), Color.BLACK)
		_draw_arc((_radius()/2.) - 1., deg, deg + arc_step, int(arc_step),
			ColorScheme.highlighter_color if higliter_idx == i else ColorScheme.get_color(i, len(values) - 1.))
		deg += arc_step

# Отрисовка сегмента графика
func _draw_arc(radius: float, start_a: float, end_a: float, p_c: int, color: Color) -> void:
	draw_arc(Vector2(_radius(), _radius()), radius, deg_to_rad(start_a), deg_to_rad(end_a), p_c, color, _radius())

# Получение радиуса графика
func _radius() -> float: return min(size.x, size.y)/2.

# Заполнение списка значений
func update_data(filter: Variant = {}, key: String = "value") -> void:
	var filter_data: Dictionary = Global.get_filter(filter)
	values = []
	for i in Request.select_sections_list(filter_data.where, filter_data.date, filter_data.order): values.append(i[key])
	queue_redraw()

# Выделение области
# Применение
func set_highlighter(index: Variant = null) -> void:
	higliter_idx = index
	queue_redraw()

# Сброс
func reset_highlighter(index: int) -> void:
	if index != higliter_idx: return
	set_highlighter()
