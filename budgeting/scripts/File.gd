extends Node
# Файл конфигураций
var config: Dictionary = {"enter": false, "lang": "ru"} # Конфигурации
const ConfigFilePath: String = "res://bases/config.json" # Путь к файлу конфигураций

# Файл языка приложения
var lang: Dictionary = {} # Язык
const LangDir: String = "res://bases/language/" # Директория языков

# Стартовый вызов функций
func _ready() -> void: _create_langs()
	
# Заполнение поля выбора языка
func load_lang(container: OptionButton) -> void:
	for i in DirAccess.get_files_at(LangDir):
		if "json" in i and len(i.split(".")) == 2:
			container.add_item(i.split(".")[0])
			if i.split(".")[0] == config.lang:
				container.select(container.item_count-1)
				read_lang(container)
			
# Создание файлов языков
func _create_langs() -> void:
	_cr_ru()
	_cr_en()
	
# Создание файла
func _cr_lang_file(f_name: String, value: String) -> void:
	if FileAccess.file_exists(LangDir+f_name+".json"): return
	var file = FileAccess.open(LangDir+f_name+".json", FileAccess.WRITE)
	file.store_line(value)
	file.close()

# Считывание перевода
func read_lang(container: OptionButton) -> void:
	var file = FileAccess.open(LangDir+Global.get_OB_text(container)+".json", FileAccess.READ)
	var json = JSON.new()
	if not json.parse(file.get_line()) == OK: return
	lang = json.data
	file.close()
	set_lang(container.get_parent())

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

# Изменениие текста состояния кнопки переключателя
func set_CB(obj: CheckButton) -> void:
	var new_text = File.pathfinding(obj)
	if new_text is Array and len(new_text) >= 2: obj.set_text(new_text[int(obj.button_pressed)]) 

# Применение перевода
func set_lang(obj, lang_fragment = lang) -> void:
	if lang_fragment is Dictionary and lang_fragment == lang: lang_fragment = lang[obj.name]
	if lang_fragment is String:
		obj.set_text(lang_fragment)
		return
	for i in obj.get_children():
		if i.name in lang_fragment.keys(): set_lang(i, lang_fragment[i.name])
		elif i.name == "Error": i.update_lang()

# Создание базовых языков
# Русский
func _cr_ru() -> void:
	_cr_lang_file("ru", JSON.stringify({
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
	}))

# Английский
func _cr_en() -> void:
	_cr_lang_file("en", JSON.stringify({
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
	}))
