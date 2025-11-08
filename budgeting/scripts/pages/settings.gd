extends ColorRect
# Подключение путей к объектам в сцене
# Параметры
@onready var Language = $Language
@onready var Login = $Login
@onready var DarkTheme = $DarkTheme
@onready var Preinstalled = $Preinstalled
@onready var ColorSchemePre = $ColorSchemePre
@onready var ColorSchemeCus = $ColorSchemeCus
# Цвета
@onready var Colors = $Colors
@onready var color1 = $Colors/Color1
@onready var color2 = $Colors/Color2
# Пример оформления
@onready var Example = $Example

# Стартовое изменение страницы настроек
func _ready() -> void:
	Login.set_text(Global.show_data(Global.config.login))
	File.load_lang(Language)
	for i in get_children():
		if i is ColorPickerButton:
			var picker = i.get_picker()
			picker.picker_shape = 2
			picker.color_modes_visible = false
			picker.sliders_visible = false
			picker.presets_visible = false
	_on_color_scheme_pre_item_selected(ColorSchemePre.selected)

# Изменение цветов в примере отображения
func changed_color():
	_color_reading()
	var idx = 6
	for i in Example.get_children():
		i.color = ColorScheme.get_color(idx, 6, ColorScheme.system_gradient)
		idx -= 1
		
# Составление цветовой палитры
func _color_reading():
	var g_colors: PackedColorArray = PackedColorArray([])
	var g_offsets: PackedFloat32Array = PackedFloat32Array([])
	for i in range(ColorSchemeCus.selected + 1):
		g_colors.append(Colors.get_child(i).color)
		g_offsets.append(0.2 + ((0.8 / (ColorSchemeCus.selected + 1)) * i))
	ColorScheme.color_assembly(g_colors, g_offsets, DarkTheme.button_pressed)
	
# Скрытие параметров цвета
func hide_colors() -> void: for i in Colors.get_children(): i.visible = false

# Отображение параметров цвета
func show_colors() -> void:
	hide_colors()
	for i in range(ColorSchemeCus.selected + 1): Colors.get_child(i).visible = true
	
# Изменение цвета
func _contrast(c1: String, c2: String) -> void:
	color1.color = Color("#" + c1)
	color2.color = Color("#" + c2)

# Смена темы между светлой и тёмной
func _change_theme(c1_l: String, c2_l: String, c1_d: String, c2_d: String) -> void:
	if DarkTheme.button_pressed: _contrast(c1_d, c2_d)
	else: _contrast(c1_l, c2_l)

# Изменение цветов
func _on_color_1_color_changed(color: Color) -> void: changed_color()

func _on_color_2_color_changed(color: Color) -> void: changed_color()

func _on_color_3_color_changed(color: Color) -> void: changed_color()

func _on_color_4_color_changed(color: Color) -> void: changed_color()

# Обработка изменения языка приложения
func _on_language_item_selected(index: int) -> void: File.read_lang(Language)

# Обработка изменения Логина
func _on_login_text_changed() -> void: pass
	
# Обработка изменения темы оформления между предустановленной и персонализированной
func _on_preinstalled_toggled(toggled_on: bool) -> void:
	File.set_CB(Preinstalled)
	ColorSchemeCus.visible = toggled_on
	ColorSchemePre.visible = not toggled_on
	if toggled_on: show_colors()
	else: hide_colors()
	changed_color()
	
# Обработка изменения светлой и тёмной темы
func _on_dark_theme_toggled(_toggled_on: bool) -> void:
	File.set_CB(DarkTheme)
	if not Preinstalled.button_pressed: _on_color_scheme_pre_item_selected(ColorSchemePre.selected)
	else: changed_color()

# Обработка выбра количества цветов
func _on_color_scheme_cus_item_selected(_index: int) -> void:
	show_colors()
	changed_color()

# Стандартные цветовые схемы
func _on_color_scheme_pre_item_selected(index: int) -> void:
	ColorSchemeCus.selected = 1
	match index:
		0: _change_theme("3a9891", "c8c8c8", "3aa49c", "414141")
		2: _change_theme("aa76c6", "dfdf62", "6b6316", "52306a")
		3: _change_theme("ad5252", "808080", "813333", "3b3b3b")
		4: _change_theme("df8662", "72c8a3", "8f4e33", "2d5d57")
		5: _change_theme("e198ae", "b9e198", "801938", "44622b")
		_:
			ColorSchemeCus.selected = 0
			color1.color = Color("#484848")
	changed_color()
