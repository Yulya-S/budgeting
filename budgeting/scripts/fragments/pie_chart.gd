extends Control
# Экпортируемые переменные
@export var gradient: Gradient = Gradient.new() # Цветовой градиент

# Переменные
var radius: float = 50 # Радиус графика
var values: Array = [] # Значения для построения

# Сокрытие маркера и изменение радиуса диаграммы
func _ready() -> void:
	radius = min(size.x, size.y)/2.
	$Marker.visible = false

# Получение значения цвета по индексу объекта
func get_color(index) -> Color:
	return gradient.sample(index / (len(values) - 1.))
	
#Отрисовка графика
func _draw() -> void:
	if len(values) == 0: return
	var sum: float = 0
	for i in values: sum += i
	var deg: float = 2
	for i in range(len(values)):
		var arc_size: float = (values[i]*360.)/sum
		draw_arc(Vector2(radius/2., radius/2.), radius+2, deg_to_rad(deg-2), deg_to_rad(deg+arc_size+2), arc_size+4, Color.BLACK, radius*2.)
		draw_arc(Vector2(radius/2., radius/2.), radius, deg_to_rad(deg), deg_to_rad(deg+arc_size), arc_size, get_color(i), radius*2.)
		deg += arc_size

# Заполнение списка значений
func set_values(objects: Array, key: String = "value") -> void:
	values = []
	for i in objects: if i[key] > 0: values.append(i[key])
	queue_redraw()
		
	
	
