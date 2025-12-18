extends Node
# Переменные
var chart_gradient: Gradient = Gradient.new() # Градиент для графиков
var scales_gradient: Gradient = Gradient.new() # Градиент для шкал
var system_gradient: Gradient = Gradient.new() # Градиент для системы
var highlighter_color: Color = Color.AQUAMARINE # Цвет подсветки

# Установка цветового градиента
func _ready() -> void:
	chart_gradient.colors = PackedColorArray([Color(1, 0, 0), Color(1, 1, 0)])
	chart_gradient.offsets = PackedFloat32Array([0, 1])
	scales_gradient.colors = PackedColorArray([Color.from_rgba8(0, 109, 0), Color(1, 1, 0), Color(1, 0, 0)])
	scales_gradient.offsets = PackedFloat32Array([0, 0.5, 1])

# Получение значения цвета из градиента по индексу объекта
func get_color(index: float, count: float, gradient: Gradient = chart_gradient) -> Color:
	if count == 0: count = 1
	return gradient.sample(index / count)

# Получение значения цвета из градиента системы
func get_sys_color(index: float, count: float = 6) -> Color: return get_color(index, count, system_gradient)

# Получение цветов из базы данных
func color_reading() -> void:
	var g_colors: PackedColorArray = PackedColorArray([])
	var g_offsets: PackedFloat32Array = PackedFloat32Array([])
	
	var data: Dictionary = Request.select(Request.Tables.SETTINGS)[0]
	var color_count: int = 0
	if data.color_preset: color_count = data.color_scheme + 1
	else: color_count = 1 if data.color_scheme == 1 else 2
	
	for i in range(color_count):
		g_colors.append(data["color_" + str(i + 1)])
		g_offsets.append(0.2 + ((0.8 / color_count) * i))
	color_assembly(g_colors, g_offsets, data.dark_theme)
	# Изменение градиента для графиков под выбранную цветовую тему
	chart_gradient.colors = PackedColorArray([get_sys_color(10, 100), get_sys_color(55, 100)])
	# Изменение цвета подсветки
	highlighter_color = Color.AQUAMARINE * get_sys_color(50, 100)
	
# Составление цветовой палитры
func color_assembly(g_colors: PackedColorArray, g_offsets: PackedFloat32Array, theme: bool) -> void:
	g_colors = PackedColorArray([Color(int(theme), int(theme), int(theme))]) + g_colors
	g_offsets = PackedFloat32Array([0]) + g_offsets
	g_colors.append(Color(int(not theme), int(not theme), int(not theme)))
	g_offsets.append(1)
	system_gradient.colors = g_colors
	system_gradient.offsets = g_offsets
	
# Замена цвета текста
func set_font_color(object, column: String = "font_color") -> void: object.add_theme_color_override(column, get_sys_color(0))
	
# Применение системного градиента к странице
func repainting(obj) -> void:
	match obj.name:
		"Head": obj.color = get_sys_color(1)
		"Menu", "Marker": obj.color = get_sys_color(2)
		"Background", "DailyTransactions": obj.color = get_sys_color(6)
		"Filter": obj.color = get_sys_color(3)
		"Gradient": obj.texture.gradient = ColorScheme.chart_gradient
		"X", "Border": obj.default_color = get_sys_color(0)
		"Frame": obj.default_color = get_sys_color(4)
		"SelectedCell": obj.default_color = get_sys_color(1)
		"Example": # Частный случай особого пакраса
			obj.get_child(1).color = get_sys_color(4)
			obj.get_child(2).color = get_sys_color(5)
		_:
			match obj.get_class():
				"CheckButton": for i in ["", "focus_", "pressed_"]: set_font_color(obj, "font_"+i+"color")
				"ColorRect":
					if obj.get_parent().get_class() == "VBoxContainer": obj.color = get_sys_color(4 + int(obj.get_parent().get_child_count() != 1))
					elif obj.get_parent().get_class() in ["GridContainer", "HBoxContainer"]:
						obj.color = get_sys_color(5)
				"Label":
					set_font_color(obj)
					obj.add_theme_color_override("font_outline_color", get_sys_color(6))
	for i in obj.get_children(): repainting(i)
