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

# Получение значения цвета из градиента по индексу
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
	highlighter_color = Color.AQUAMARINE * get_sys_color(50, 100) # Изменение цвета подсветки
	
# Составление цветовой палитры
func color_assembly(g_colors: PackedColorArray, g_offsets: PackedFloat32Array, theme: bool) -> void:
	g_colors = PackedColorArray([Color(int(theme), int(theme), int(theme))]) + g_colors
	g_offsets = PackedFloat32Array([0]) + g_offsets
	g_colors.append(Color(int(not theme), int(not theme), int(not theme)))
	g_offsets.append(1)
	system_gradient.colors = g_colors
	system_gradient.offsets = g_offsets
	
# Замена цвета текста
func set_font_color(obj: Variant, column: String = "font_color", color_idx: int = 0) -> void: obj.add_theme_color_override(column, get_sys_color(color_idx))

# Изменение цвета кнопки
func _set_buttons_color(obj: Variant, a: float = 0.5, column: String = "normal") -> void:
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	style_box.bg_color = get_sys_color(0)
	style_box.bg_color.a = a
	style_box.set_corner_radius_all(2)
	obj.add_theme_stylebox_override(column, style_box)

# Изменение всех цветовых параметров кнопки
func _set_all_button_color_parametrs(obj: Variant) -> void:
	_set_buttons_color(obj)
	_set_buttons_color(obj, 0.8, "hover")
	_set_buttons_color(obj, 0.5, "pressed")
	for i in ["", "focus_", "hover_", "hover_pressed_", "pressed_"]: set_font_color(obj, "font_"+i+"color", 6)		

# Применение цветовой палитры к странице
func repainting(obj: Variant) -> void:
	match obj.name:
		"Head": obj.color = get_sys_color(1)
		"Menu", "Marker": obj.color = get_sys_color(2)
		"Background": obj.color = get_sys_color(6)
		"Filter": obj.color = get_sys_color(3)
		"Gradient": obj.texture.gradient = ColorScheme.chart_gradient
		"X", "Border", "Separator": obj.default_color = get_sys_color(0)
		"Frame": obj.default_color = get_sys_color(4)
		"SelectedCell": obj.default_color = get_sys_color(1)
		"Example": # Частный случай особого пакраса
			obj.get_child(1).color = get_sys_color(4)
			obj.get_child(2).color = get_sys_color(5)
		_:
			match obj.get_class():
				"Button", "TextEdit": _set_all_button_color_parametrs(obj)
				"OptionButton":
					_set_all_button_color_parametrs(obj)
					obj.add_theme_icon_override("arrow", load("res://img/godot_icon/arrow_"+str(int(Request.select(Request.Tables.SETTINGS)[0].dark_theme))+".png"))
				"CheckButton":
					var dark_theme: String = str(int(Request.select(Request.Tables.SETTINGS)[0].dark_theme))
					obj.add_theme_icon_override("checked", load("res://img/godot_icon/checked_"+dark_theme+".tres"))
					obj.add_theme_icon_override("unchecked", load("res://img/godot_icon/unchecked_"+dark_theme+".tres"))
					for i in ["", "focus_", "pressed_"]: set_font_color(obj, "font_"+i+"color")
					obj.add_theme_color_override("font_hover_color", get_sys_color(3))
				"ColorRect":
					if obj.get_parent().get_class() == "VBoxContainer": obj.color = get_sys_color(4 + int(obj.get_parent().get_child_count() != 1))
					elif obj.get_parent().get_class() in ["GridContainer", "HBoxContainer"]:
						obj.color = get_sys_color(5)
				"Label":
					set_font_color(obj)
					obj.add_theme_color_override("font_outline_color", get_sys_color(6))
	for i in obj.get_children(): repainting(i)
