extends Control
# Подключение пути к объектам в сцене
@onready var ShowPassword = $Password/Show
@onready var Password = $Password
@onready var Remember = $Remember
@onready var Error = $Error

func _process(delta: float) -> void: if Global.config.enter: _on_enter_button_down(false)

# Обработка изменения параметра отображения пароля
func _on_show_password_toggled(toggled_on: bool) -> void:
	Password.add_theme_color_override("font_color", Color.WHITE if toggled_on else Color.html("#00000000"))

# Проверка возможности использования пароля
func check_user(login: bool = true, check_field: bool = true) -> bool:
	Error.visible = false
	# Заполнение файла конфигурации
	if check_field: for i in get_children():
		if i is TextEdit:
			if i.get_text() == "": return not Global.set_error(Error, "Все поля должны быть заполнены")
			Global.config[i.name.to_lower()] = Global.hide_data(i.get_text())
	# Получение результата из базы данных
	var req: String = 'login="'+Global.config["login"]+'"'
	if login: req += ' AND password="'+Global.config["password"]+'"'
	return Request.select(Request.Tables.USERS, "COUNT(id)=="+str(int(login))+" res", req)[0].res

# Генерация названия базы данных
func generate_db_name() -> String:
	var base_name: String = ""
	const chars: String = 'abcdefghijklmnopqrstuvwxyz1234567890'
	for i in range(10): base_name += chars[randi()%len(chars)]
	return Global.hide_data(base_name)

# Вход в программу
func entrance() -> void:
	Global.config.enter = Remember.button_pressed
	var user_data: Array = []
	for i in Global.config.keys():
		if i == "enter": continue
		user_data.append(i+'="'+Global.config[i]+'"')
	var data: Dictionary = Request.select(Request.Tables.USERS, "*", " AND ".join(user_data))[0]
	if Global.config.enter: Global.update_config()
	Request.connection_db(Global.show_data(data.base))
	Global.emit_signal("open_new_page", Global.Pages.BASIC)

# Обработка нажатия кнопки регистрации
func _on_registration_button_down() -> void:
	if not check_user(false):
		if not Error.visible: Global.set_error(Error, "Имя пользователя занято")
		return
	Request.insert_record(Request.Tables.USERS, ['"'+Global.config.login+'"', '"'+Global.config.password+'"', '"'+generate_db_name()+'"'])
	entrance()

# Обработка нажатия кнопки входа
func _on_enter_button_down(check_field: bool = true) -> void:
	if not check_user(true, check_field):
		if not Error.visible: Global.set_error(Error, "Неверный логин или пароль")
		return
	entrance()
