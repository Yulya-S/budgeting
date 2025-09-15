extends Node
# Переменные
var chart_gradient: Gradient = Gradient.new() # Градиент для графиков
var scales_gradient: Gradient = Gradient.new() # Градиент для шкал

# Установка цветового градиента
func _ready() -> void:
	chart_gradient.colors = PackedColorArray([Color(1, 0, 0), Color.from_rgba8(255, 96, 0), Color.from_rgba8(255, 156, 0), Color(1, 1, 0)])
	chart_gradient.offsets = PackedFloat32Array([0, 0.33, 0.66, 1])
	scales_gradient.colors = PackedColorArray([Color.from_rgba8(0, 109, 0), Color(1, 1, 0), Color(1, 0, 0)])
	scales_gradient.offsets = PackedFloat32Array([0, 0.5, 1])

# Получение значения цвета из градиента по индексу объекта
func get_color(index: float, count: float, gradient: Gradient = chart_gradient) -> Color:
	return gradient.sample(index / count)
