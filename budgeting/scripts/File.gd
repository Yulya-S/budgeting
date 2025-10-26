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
				read_lang(i.split(".")[0])
			
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
func read_lang(l_name: String) -> void:
	var file = FileAccess.open(LangDir+l_name+".json", FileAccess.READ)
	var json = JSON.new()
	if not json.parse(file.get_line()) == OK: return
	lang = json.data
	file.close()
	
# Применение перевода
func set_lang(obj, lang_fragment = lang) -> void:
	if lang_fragment is Dictionary and lang_fragment == lang: lang_fragment = lang[obj.name]
	if lang_fragment is String:
		obj.set_text(lang_fragment)
		return
	for i in obj.get_children(): if i.name in lang_fragment.keys(): set_lang(i, lang_fragment[i.name])

# Создание базовых языков
# Русский
func _cr_ru() -> void:
	_cr_lang_file("ru", JSON.stringify({
		"Registration": {
			"Language": { "Label": "Язык:" },
			"Login": { "Label": "Логин" },
			"Password": { "Label": "Пароль", "Show": "Показать пароль" },
			"Remember": "Запомни меня",
			"Registration": "Регистрация",
			"Enter": "Вход",
		}
	}))

# Английский
func _cr_en() -> void:
	_cr_lang_file("en", JSON.stringify({
		"Registration": {
			"Language": { "Label": "Language:" },
			"Login": { "Label": "Login" },
			"Password": { "Label": "Password", "Show": "Show password" },
			"Remember": "Remember me",
			"Registration": "Registration",
			"Enter": "Entry",
		}
	}))
