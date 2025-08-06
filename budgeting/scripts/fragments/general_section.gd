extends ColorRect
# Подключение путей к объектам в сцене
@onready var Border = $Border
@onready var Value = $Value
@onready var Max = $Max
@onready var Objects = $"../ObjArray"

# Подключение сигнала
func _ready() -> void: Global.connect("update_page", Callable(self, "_update_page"))

# Вычисление сумм
func _update_page() -> void:
	var data: Array = Objects.select()
	var result: Dictionary = {"value": 0.0, "month_limit": 0.0}
	for i in data:
		if i.income or i.month_limit <= 0: continue
		result.value += i.value
		result.month_limit += i.month_limit
	if Border.visible and result.month_limit > 0:
		Border.get_child(0).size.x = (Border.size.x * result.value) / result.month_limit
		if Border.size.x < Border.get_child(0).size.x: Border.get_child(0).size.x = Border.size.x
		Border.get_child(0).color = ColorScheme.get_color(Border.get_child(0).size.x, Border.size.x, ColorScheme.scales_gradient)
	Value.set_text(str(result.value))
	Max.set_text(str(result.month_limit))
	
