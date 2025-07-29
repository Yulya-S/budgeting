extends Node
# Переменная
var gradient: Gradient = Gradient.new()

# Установка цветового градиента
func _ready() -> void: gradient.colors = PackedColorArray([Color(1, 0, 0), Color(1, 1, 0)])

# Получение значения цвета из градиента по индексу объектаd
func get_color(index: float, count: float) -> Color: return gradient.sample(index / count)
