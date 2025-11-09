extends Node
# Переменные
const BasesPath: String = "res://bases/"
# Файл конфигураций
var config: Dictionary = {"enter": false, "lang": "ru", "login": "", "password": ""} # Конфигурации
const ConfigFilePath: String = BasesPath + "config.json" # Путь к файлу конфигураций
# Файл языка приложения
var lang: Dictionary = {} # Язык
const LangDir: String = BasesPath + "language/" # Директория языков

# Общая часть
# Создание файлов
func _ready() -> void:
	_create_dirs()
	_create_config()
	_create_langs()

# Создание папок для хранения данных
func _create_dirs() -> void:
	if not DirAccess.dir_exists_absolute(BasesPath): DirAccess.make_dir_absolute(BasesPath)
	if not DirAccess.dir_exists_absolute(LangDir): DirAccess.make_dir_absolute(LangDir)

# Сохранение данных в файл
func _store_json(file_path: String, data: Dictionary) -> void:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_line(JSON.stringify(data))
	file.close()
	
# Чтение данных из файла
func _read_file(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	if not json.parse(file.get_line()) == OK: return {}
	file.close()
	return json.data
	
# Шифрование данных
func hide_data(data: String) -> String:	return Marshalls.utf8_to_base64(data)

# Дешифрование данных
func show_data(data: String) -> String: return Marshalls.base64_to_utf8(data)

# Файл конфигураций
# Проверка наличия созданного файла конфигураций
func _create_config() -> void:
	if FileAccess.file_exists(ConfigFilePath):
		read_config()
		return
	save_config()

# Сохранение данных конфигураций в файл
func save_config() -> void: _store_json(ConfigFilePath, config)
	
# Чтение файла конфигураций
func read_config() -> void: config = _read_file(ConfigFilePath)

# Очистка данных пользователя
func clear_config() -> void:
	config = {"enter": false, "lang": "ru", "login": "", "password": ""}
	save_config()

# Файл локализации
# Заполнение поля выбора языка
func load_lang(container: OptionButton) -> void:
	for i in DirAccess.get_files_at(LangDir):
		if "json" in i and len(i.split(".")) == 2:
			container.add_item(i.split(".")[0])
			# Применение языка, если он соответствует выбранному в файле конфигураций
			if i.split(".")[0] == config.lang:
				container.select(container.item_count-1)
				read_lang(container)
			
# Создание файлов языков
func _create_langs() -> void:
	# Убрать этот фрагмент - он нужен что бы не удалять каждый раз файлы локализации в ручную
	DirAccess.remove_absolute("res://bases/language/ru.json")
	DirAccess.remove_absolute("res://bases/language/en.json")
	
	_cr_ru()
	_cr_en()
	
# Создание файла перевода
func _cr_lang_file(f_name: String, value: Dictionary) -> void:
	if FileAccess.file_exists(LangDir+f_name+".json"): return
	_store_json(LangDir+f_name+".json", value)
	
# Считывание перевода
func read_lang(container: OptionButton) -> void:
	lang = _read_file(LangDir+Global.get_OB_text(container)+".json")
	set_lang(container.get_parent())
	# Сохранение выбора в файле конфигураций
	config.lang = Global.get_OB_text(container)
	save_config()

# Применение значение используя поиск корневой сцены
func pathfinding(obj) -> Variant:
	# Получение пути до main
	var path: Array = []
	while obj.name != "main":
		path.append(obj.name)
		obj = obj.get_parent()
	# Получение текстового фрагмента из словаря перевода
	var lang_fragment = lang.duplicate()
	while len(path) > 0:
		if path[-1] not in lang_fragment.keys(): return ""
		lang_fragment = lang_fragment[path[-1]]
		path.pop_back()
	return lang_fragment

# Изменение текста состояния кнопки переключателя
func set_CB(obj: CheckButton) -> void:
	var new_text = File.pathfinding(obj)
	if new_text is Array and len(new_text) >= 2: obj.set_text(new_text[int(obj.button_pressed)]) 

# Применение перевода - нужно изменить
func set_lang(obj, lang_fragment = lang) -> void:
	if lang_fragment is Dictionary and lang_fragment == lang: lang_fragment = lang[obj.name]
	if lang_fragment is String:
		obj.set_text(lang_fragment)
		return
	for i in obj.get_children():
		if i.name in lang_fragment.keys(): set_lang(i, lang_fragment[i.name])
		elif i.name == "Error": i.update_lang()

# Создание стандартных вариантов локализации
# Русский
func _cr_ru() -> void:
	_cr_lang_file("ru", {
		"Registration": {
			"Language": { "Label": "Язык:" },
			"Login": { "Label": "*Логин:" },
			"Password": { "Label": "*Пароль:", "Show": "Показать пароль" },
			"Remember": "Запомни меня",
			"Registration": "Регистрация",
			"Enter": "Вход",
		},
		"Settings": {
			"EventType": ["Календарь событий", "Список событий"],
			"Preinstalled": ["Предустановленная тема", "Пользовательская тема"],
			"DarkTheme": ["Светлая тема", "Тёмная тема"],
			"ColorSchemePre": {"Label": "Цветовое оформление"},
			"ColorSchemeCus": {"Label": "Количество цветов"},
			"Colors": {"Label": "Цвет"},
			"Delete": "Удалить пользователя",
			"Apply": "Сохранить",
		},
		"_Errors": {
			"_E01": "Обязательные поля должны быть заполнены",
			"_E02": "Имя пользователя занято",
			"_E03": "Неверный логин или пароль",
			"_E04": "Объект уже существует",
			"_E05": "Значение должно быть больше нуля",
			"_E06": "На счету недостаточно средств",
			"_E07": "Введенное значение привышает необходимое значение для полного погашения займа"
		}
	})

# Английский
func _cr_en() -> void:
	_cr_lang_file("en", {
		"Registration": {
			"Language": { "Label": "Language:" },
			"Login": { "Label": "*Login:" },
			"Password": { "Label": "*Password:", "Show": "Show password" },
			"Remember": "Remember me",
			"Registration": "Registration",
			"Enter": "Entry",
		},
		"Settings": {
			"Login": { "Label": "Login:" },
			"ColorPreset": {"Label": "Color theme:"},
			"DarkTheme": "Light theme",
			"Color": {"Label": "Color"},
			"Delete": "Delete user",
			"Apply": "Save",
		},
		"_Errors": {
			"_E01": "Required fields must be filled in",
			"_E02": "Username taken",
			"_E03": "Incorrect login or password",
			"_E04": "The object already exists",
			"_E05": "Value must be greater than zero",
			"_E06": "There are insufficient funds in the account",
			"_E07": "The entered value exceeds the required value for full repayment of the loan"
		}
	})
