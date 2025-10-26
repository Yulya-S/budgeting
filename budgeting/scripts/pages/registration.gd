extends Control
# Подключение пути к объектам в сцене
@onready var ShowPassword = $Password/Show
@onready var Password = $Password
@onready var Remember = $Remember
@onready var Error = $Error

# Обработка изменения параметра отображения пароля
func _on_show_password_toggled(toggled_on: bool) -> void:
	Password.add_theme_color_override("font_color", Color.WHITE if toggled_on else Color.html("#00000000"))

# Проверка возможности использования пароля
func check_user(login: bool = true) -> bool:
	Error.visible = false
	# Заполнение файла конфигурации
	for i in get_children():
		if len(Global.config.keys()) > 2: break
		if i is TextEdit:
			if i.get_text() == "": return not Global.set_error(Error, "Все поля должны быть заполнены")
			Global.config[i.name.to_lower()] = Global.hide_data(i.get_text())
	# Получение результата из базы данных
	var req: String = 'login="'+Global.config["login"]+'"'
	if login: req += ' AND password="'+Global.config["password"]+'"'
	return Request.select("users", "COUNT(id)=="+str(int(login))+" res", req)[0].res

# Обработка нажатия кнопки регистрации
func _on_registration_button_down() -> void:
	if not check_user(false):
		if not Error.visible: Global.set_error(Error, "Имя пользователя занято")
		return
	pass # Replace with function body.

# Обработка нажатия кнопки входа
func _on_enter_button_down() -> void:
	if not check_user():
		if not Error.visible: Global.set_error(Error, "Неверный логин или пароль")
		return
	pass # Replace with function body.
