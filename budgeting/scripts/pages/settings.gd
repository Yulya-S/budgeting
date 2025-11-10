extends ColorRect
# Подключение путей к объектам в сцене
# Параметры
@onready var Language = $Language
@onready var EventType = $EventType
@onready var Preinstalled = $Preinstalled
@onready var DarkTheme = $DarkTheme
@onready var ColorSchemePre = $ColorSchemePre
@onready var ColorSchemeCus = $ColorSchemeCus
# Цвета
@onready var Colors = $Colors
@onready var color1 = $Colors/Color_1
@onready var color2 = $Colors/Color_2
# Пример оформления
@onready var Example = $Example

# Стартовое изменение страницы настроек
func _ready() -> void:
	File.load_lang(Language)
	var data: Dictionary = Request.select(Request.Tables.SETTINGS)[0] # Получение настроек
	EventType.button_pressed = bool(data.event_page_calendar)
	# Настройка выбора цвета
	for i in Colors.get_children():
		if i is ColorPickerButton:
			var picker = i.get_picker()
			picker.picker_shape = 2
			picker.color_modes_visible = false
			picker.sliders_visible = false
			picker.presets_visible = false
			i.color = Color("#"+data[i.name.to_lower()])
	_on_preinstalled_toggled(bool(data.color_preset))
	DarkTheme.button_pressed = bool(data.dark_theme)
	if data.color_preset: _on_color_scheme_cus_item_selected(data.color_scheme)
	else: _on_color_scheme_pre_item_selected(data.color_scheme)

# Изменение цветов в примере отображения
func changed_color() -> void:
	_color_reading()
	ColorScheme.repainting(Example)
		
# Составление цветовой палитры
func _color_reading() -> void:
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

# Обработка изменения способа отображения календаря
func _on_event_type_toggled(toggled_on: bool) -> void: File.set_CB(EventType)

# Обработка изменения темы оформления между предустановленной и персонализированной
func _on_preinstalled_toggled(toggled_on: bool) -> void:
	Preinstalled.button_pressed = toggled_on
	File.set_CB(Preinstalled)
	# Изменение отображения параметров оформления
	ColorSchemeCus.visible = toggled_on
	ColorSchemePre.visible = not toggled_on
	if toggled_on: _on_color_scheme_cus_item_selected(ColorSchemeCus.selected)
	else: _on_color_scheme_pre_item_selected(ColorSchemePre.selected)
	changed_color()
	
# Обработка изменения светлой и тёмной темы
func _on_dark_theme_toggled(_toggled_on: bool) -> void:
	File.set_CB(DarkTheme)
	if not Preinstalled.button_pressed: _on_color_scheme_pre_item_selected(ColorSchemePre.selected)
	else: changed_color()

# Обработка выбора количества цветов
func _on_color_scheme_cus_item_selected(index: int) -> void:
	ColorSchemeCus.selected = index
	show_colors()
	changed_color()

# Стандартные цветовые схемы
func _on_color_scheme_pre_item_selected(index: int) -> void:
	hide_colors()
	ColorSchemePre.selected = index
	ColorSchemeCus.selected = 1
	match index:
		0: _change_theme("3a9891", "c8c8c8", "3aa49c", "414141") # Стандартная
		2: _change_theme("aa76c6", "dfdf62", "6b6316", "52306a") # Лимон со смородиной
		3: _change_theme("ad5252", "808080", "813333", "3b3b3b") # Ржавый металл
		4: _change_theme("df8662", "72c8a3", "8f4e33", "2d5d57") # Лиса на поляне
		5: _change_theme("e198ae", "b9e198", "801938", "44622b") # Ягода на ветке
		_: # Серая
			ColorSchemeCus.selected = 0
			color1.color = Color("#636363")
	changed_color()

# Обработка нажатия кнопки закрытия окна
func _on_close_button_down() -> void:
	queue_free()
	get_parent().remove_child(self)

# Обработка нажатия кнопки удаления пользователя
func _on_delete_button_down() -> void: $ConfirmationDialog.visible = true

# Обработка подтверждения удаления пользователя
func _on_confirmation_dialog_confirmed() -> void:
	Request.delete_user()
	Global.emit_signal("open_new_page", Global.Pages.REGISTRATION)

# Обработка нажатия кнопки сохранения настроек
func _on_apply_button_down() -> void:
	# Получение данных со страницы
	var values: Array = []
	for i in get_children():
		if not i.visible: continue
		match i.get_class():
			"CheckButton": values.append(i.button_pressed)
			"OptionButton": values.append(i.selected)
			"Control": for l in i.get_children(): values.append('"'+l.color.to_html()+'"')
	values.pop_front()
	values.append('"'+Time.get_date_string_from_system()+'"')
	# Сохранение записи в базе данных
	Request.update_record(Request.Tables.SETTINGS, 1, values)
	_on_close_button_down()
