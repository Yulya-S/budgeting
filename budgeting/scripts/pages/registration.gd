extends Control
# Подключение путей к объектам в сцене
@onready var Language = $Language
@onready var Password = $Password
@onready var ShowPassword = $Password/Show
@onready var Remember = $Remember
@onready var Error = $Error

# Заполнение списка языков программы
func _ready() -> void: File.load_lang(Language)

# Автоматический вход
func _process(_delta: float) -> void: if File.config.enter: _on_enter_button_down(false, true)

# Проверка возможности использования пароля
func _check_user(login: bool, check_field: bool = true) -> bool:
	Error.clear()
	# Заполнение файла конфигурации
	if check_field: for i in get_children():
		if i is TextEdit:
			if Error.check_mandatory_fields(i):	return false
			File.config[i.name.to_lower()] = File.hide_data(i.get_text())
	return Request.select_existence_user(login) # Получение результата проверки из базы данных

# Генерация названия базы данных
func _generate_db_name() -> String:
	var base_name: String = ""
	const chars: String = 'abcdefghijklmnopqrstuvwxyz1234567890'
	for i in range(10): base_name += chars[randi()%len(chars)]
	return File.hide_data(base_name)

# Вход в программу
func _entrance(auto: bool = false) -> void:
	# Сохранение файла конфигурации для автоматического входа
	if not auto:
		File.config.enter = Remember.button_pressed
		if File.config.enter: File.save_config()
	# Вход в аккаунт
	var data: Dictionary = Request.select_user()
	Request.connection_db(File.show_data(data.base))
	ColorScheme.color_reading()
	Global.emit_signal("open_new_page", Global.Pages.WALLET)

# Обработка изменения параметра отображения пароля
func _on_show_password_toggled(toggled_on: bool) -> void:
	Password.add_theme_color_override("font_color", Color.WHITE if toggled_on else Color.html("#00000000"))

# Обработка смены языка интерфейса
func _on_language_item_selected(_index: int) -> void: File.read_lang(Language)

# Обработка нажатия кнопки регистрации
func _on_registration_button_down() -> void:
	if not _check_user(false):
		Error.set_state(Error.States._E02)
		return
	Request.insert_record(Request.Tables.USERS, ['"'+File.config.login+'"', '"'+File.config.password+'"', '"'+_generate_db_name()+'"'])
	_entrance()

# Обработка нажатия кнопки входа
func _on_enter_button_down(check_field: bool = true, auto: bool = false) -> void:
	if not _check_user(true, check_field):
		File.clear_config()
		Error.set_state(Error.States._E03)
		return
	_entrance(auto)
