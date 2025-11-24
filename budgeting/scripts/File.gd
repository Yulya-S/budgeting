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
func _ready() -> void: create_files()

# Создание необходимых для работы программы файлов
func create_files() -> void:
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
func read_config() -> void:
	var new: Dictionary = _read_file(ConfigFilePath)
	if new.keys() == config.keys(): config = new
	else: save_config()

# Очистка данных пользователя
func clear_config() -> void:
	config = {"enter": false, "lang": config.lang, "login": "", "password": ""}
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
	_supplement_translation() 
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

# Поиск ключа в базе перевода
func _find_lang_keys(obj, key: String = "") -> String:
	if obj.name == "main": return ""
	key = obj.name + key
	if "_" in key and len(key.split("_")) <= 2 and key.split("_")[1].is_valid_int(): key = key.split("_")[0]
	if key not in lang.keys(): return _find_lang_keys(obj.get_parent(), key)
	else: return key

# Изменение текста объекта в зависимости от типа объекта
func _lang_match(obj, key: String) -> void:
	match obj.get_class():
		"Label", "CheckBox":
			if obj.text != "" and "-" not in obj.text and not obj.text.is_valid_int() and not obj.text.is_valid_float():
				obj.set_text(lang[key])
		"Button":
			if obj.text in ["", "X"]: obj.tooltip_text = lang[key]
			else: obj.set_text(lang[key])
		"CheckButton": set_CB(obj)
		"ColorPickerButton": obj.get_child(0).set_text(lang[key]+" "+obj.name.split("_")[1])
		"OptionButton":
			if lang[key] is Array:
				var idx: int = 0
				for i in range(len(lang[key])):
					while idx < obj.get_item_count() and obj.get_item_text(idx) == "": idx += 1
					if idx > obj.get_item_count(): return
					obj.set_item_text(idx, lang[key][i])
					idx += 1
		"ConfirmationDialog":
			if "_ConfirmationDialog" in lang.keys():
				if "cancel" in lang._ConfirmationDialog.keys(): obj.set_cancel_button_text(lang._ConfirmationDialog.cancel)
				if "ok" in lang._ConfirmationDialog.keys(): obj.set_ok_button_text(lang._ConfirmationDialog.ok)
			if "text" in lang[key].keys(): obj.set_text(lang[key].text)
			if "title" in lang[key].keys(): obj.set_title(lang[key].title)
			
# Изменение текста состояния кнопки переключателя
func set_CB(obj: CheckButton) -> void:
	var key: String = _find_lang_keys(obj)
	if key == "": return
	if lang[key] is Array: if len(lang[key]) >= int(obj.button_pressed):
		obj.set_text(lang[key][int(obj.button_pressed)])
	else: obj.set_text(lang[key])

func set_OB_elements(obj: OptionButton) -> void:
	for i in range(obj.get_item_count()): if obj.get_item_text(i) in lang.keys(): obj.set_item_text(i, lang[obj.get_item_text(i)])

# Применение перевода
func set_lang(obj) -> void:
	var key: String = _find_lang_keys(obj)
	if obj is OptionButton and obj.name == "Month": key = "_Months"
	elif obj is Label and "__" in obj.text and obj.text in lang.keys(): key = obj.text
	if key != "": _lang_match(obj, key)
	for i in obj.get_children(): set_lang(i)

# Дополнение выбранного перевода отсутствующими фрагментами из стандартной локализации
func _supplement_translation() -> void: _supplement_cycle(lang, _standard_language())

# Цикл дополнения перевода недастающими фрагментами
func _supplement_cycle(lang_fragment: Dictionary, s_lang_fragment: Dictionary) -> void:
	for i in s_lang_fragment.keys():
		if i not in lang_fragment.keys() or typeof(lang_fragment[i]) != typeof(s_lang_fragment[i]):
			lang_fragment[i] = s_lang_fragment[i]
		elif lang_fragment[i] is Dictionary: _supplement_cycle(lang_fragment[i], s_lang_fragment[i])
		elif lang_fragment[i] is Array:
			for l in range(len(s_lang_fragment[i])):
				if len(lang_fragment[i]) <= l: lang_fragment[i].append(s_lang_fragment[i][l])
				elif typeof(lang_fragment[i][l]) != typeof(s_lang_fragment[i][l]):
					lang_fragment[i][l] = s_lang_fragment[i][l]

# Создание стандартных вариантов локализации
func _standard_language() -> Dictionary:
	return {
		# Шапка
		"Hints": "Инструкция", "Setting": "Настройки", "Main": "Главная", "Wallet": "Кошельки", "Section": "Разделы",
		"Flow": "Движения средств", "Loan": "Кредиты", "Event": "События", "Report": "Отчеты", "Exit": "Выход",
		# Регистрация
		"Registration": "Регистрация", "Enter": "Вход", "LanguageLabel": "Язык:", "LoginLabel": "*Логин:",
		"PasswordLabel": "*Пароль:", "Remember": "Запомни меня", "Show": "Показать пароль",
		# Настройки
		"DeleteUser": "Удалить пользователя", "ColorSchemePreLabel": "Цветовое оформление",
		"ColorSchemeCusLabel": "Количество цветов", "TestButton": "Пример кнопки", "ColorsColor": "Цвет",
		"TestLabel": "Пример текста", "DarkTheme": ["Светлая тема", "Тёмная тема"],
		"EventType": ["Календарь событий", "Список событий"],
		"Preinstalled": ["Предустановленная тема", "Пользовательская тема"],
		"ColorSchemePre": ["Стандартный", "Серый", "Лимон со смородиной", "Ржавый металл", "Лиса на поляне", "Ягода на ветке"],
		"ColorSchemeCus": ["Моно", "Контраст", "Триада", "Тетрада"],
		"SettingsConfirmationDialog": {"text": "Вы уверены? Все данные пользователя будут удалены", "title": "Удаление пользователя"},
		# Окна создания / изменения
		"Apply": "Сохранить", "Close": "Отменить изменения",
		# Фильтры
		"FilterTitleLabel": "Фрагмент названия", "FilterOrderLabel": "Порядок сортировки",
		"YearLabel": "Год фильтрации", "MonthLabel": "Месяц фильтрации", "FilterButton": "Применить",
		# Окно подтверждения
		"_ConfirmationDialog": {"cancel": "Нет", "ok": "Да"},
		# Страница кошельков
		"AddWallet": "Создать счет", "Transaction": "Переносить средства между счетами",
		"CashFlow": "Записать движение средств", "WalletTitle": "Название кошелька",
		"WalletFilterOrder": ["По дате добавления", "По алфавиту", "По текущей сумме"],
		"WalletValue": "Текущее значение счета", "WalletCash_Flow": "Движение средств",
		# Страница разделов
		"AddSections": "Создать раздел", "FilterConsumptionIncomeLabel": "Тип статьи",
		"FilterConsumptionIncome": ["Все типы", "Расходы", "Доходы", "Займы"],
		"SectionFilterOrder": ["По дате последней транзакции", "По дате добавления", "По алфавиту", "По возрастанию суммы", "По убыванию суммы", "По ежемесячному лимиту"],
		"SectionTitle": "Название раздела", "SectionValue": "Текущее значение", "Month_Limit": "Ограничение",
		"__CI0": "Расход", "__CI1": "Доход",
		# Страница движений средств
		"FilterWalletLabel": "Имя счёта", "FilterSectionLabel": "Статья",
		"CashFlowSectionFilterOrder": ["По дате добавления", "По статье", "По возрастанию суммы", "По убыванию суммы"],
		"CashFlowTitle": "Название раздела", "CashFlowWallet_Title": "Название кошелька",
		"CashFlowValue": "Сумма", "Date": "Дата",
		# Страница займов
		"AddLoan": "Создать займ", "AddInterest": "Добавить проценты по займу", "AddPayment": "Добавить платёж по займу",
		"FilterStatusLabel": "Статус", "FilterStatus": ["Выплачено", "В процессе"],
		"LoanFilterOrder": ["По дате добавления", "По алфавиту", "По оставшейся сумме"],
		"LoanTitle": "Название займа", "LoanWallet_Title": "Название целевого счета",
		"LoanValue": "Начальная сумма займа", "LoanTotal": "Оставшаяся сумма займа",
		# Объекты из базы данных
		"__ST1": "Переводы", "__ST2": "Заём", "__ST3": "Платежи по займам", "__ST4": "Проценты по займу",
		
		"_Months": ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"],
		"_Errors": {
			"_E01": "Обязательные поля должны быть заполнены",
			"_E02": "Имя пользователя занято",
			"_E03": "Неверный логин или пароль",
			"_E04": "Объект уже существует",
			"_E05": "Значение должно быть больше нуля",
			"_E06": "На счету недостаточно средств",
			"_E07": "Введенное значение привышает необходимое значение для полного погашения займа"
		}}

# Русский
func _cr_ru() -> void:
	_cr_lang_file("ru", _standard_language())

# Английский
func _cr_en() -> void:
	_cr_lang_file("en", {
		# Шапка
		"Hints": "Instructions", "Setting": "Settings", "Main": "Home", "Wallet": "Wallets", "Section": "Sections",
		"Flow": "Movements of funds", "Loan": "Loans", "Event": "Events", "Report": "Reports", "Exit": "Exit",
		# Регистрация
		"Registration": "Registration", "Enter": "Entry", "LanguageLabel": "Language:", "LoginLabel": "*Login:",
		"PasswordLabel": "*Password:", "Remember": "Remember me", "Show": "Show password",
		# Настройки
		"DeleteUser": "Delete user", "ColorSchemePreLabel": "Color design", "ColorsColor": "Color",
		"ColorSchemeCusLabel": "Number of colors", "TestButton": "Button example",
		"TestLabel": "Example text", "DarkTheme": ["Light theme", "Dark theme"],
		"EventType": ["Events calendar", "List of events"],
		"Preinstalled": ["Pre-installed theme", "Custom Theme"],
		"ColorSchemePre": ["Standard", "Grey", "Lemon with currants", "Rusty metal", "A fox in a clearing", "Berry on a branch"],
		"ColorSchemeCus": ["Mono", "Contrast", "Triad", "Tetrad"],
		"SettingsConfirmationDialog": {"text": "Are you sure? All user data will be deleted", "title": "Deleting a user"},
		# Окна создания / изменения
		"Apply": "Save", "Close": "Cancel changes",
		# Фильтры
		"FilterTitleLabel": "Title fragment", "FilterOrderLabel": "Sorting order",
		"YearLabel": "Year of filtration", "MonthLabel": "Month of filtering", "FilterButton": "Apply",
		# Окно подтверждения
		"_ConfirmationDialog": {"cancel": "No", "ok": "Yes"},
		# Страница кошельков
		"AddWallet": "Create an account", "Transaction": "Transfer funds between accounts",
		"CashFlow": "Record the movement of funds", "WalletTitle": "Wallet name",
		"WalletFilterOrder": ["By date added", "Alphabetically", "According to the current amount"],
		"WalletValue": "Current account value", "WalletCash_Flow": "Movement of funds",
		# Страница разделов
		"AddSections": "Create a section", "FilterConsumptionIncomeLabel": "Article type",
		"FilterConsumptionIncome": ["All types", "Expenses", "Income", "Loans"],
		"SectionFilterOrder": ["By last transaction date", "By date added", "Alphabetically", "Ascending amount", "In descending order of amount", "By monthly limit"],
		"SectionTitle": "Section title", "SectionValue": "Current value", "Month_Limit": "Limit",
		"__CI0": "Consumption", "__CI1": "Income",
		# Страница движений средств
		"FilterWalletLabel": "Account name", "FilterSectionLabel": "Article",
		"CashFlowFilterOrder": ["By date added", "According to the article", "Ascending amount", "In descending order of amount"],
		"CashFlowTitle": "Section title", "CashFlowWallet_Title": "Wallet name",
		"CashFlowValue": "Amount", "Date": "Date",
		# Страница займов
		"AddLoan": "Create a loan", "AddInterest": "Add interest to the loan", "AddPayment": "Add a loan payment",
		"FilterStatusLabel": "Status", "FilterStatus": ["Paid", "In progress"],
		"LoanFilterOrder": ["By date added", "Alphabetically", "by remaining amount"],
		"LoanTitle": "Loan name", "LoanWallet_Title": "Name of the target wallet",
		"LoanValue": "Initial loan amount", "LoanTotal": "The remaining loan amount",
		# Объекты из базы данных
		"__ST1": "Transfers", "__ST2": "Loan", "__ST3": "Loan Payments", "__ST4": "Loan Interest",
		
		"_Months": ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
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
