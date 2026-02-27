extends Node
# Переменные
const BasesPath: String = "user://bases/" # Расположение директории пользовательских данных
# Файл конфигураций
var config: Dictionary = {"enter": false, "lang": "ru", "login": "", "password": ""} # Конфигурации
const ConfigFilePath: String = BasesPath + "config.json" # Путь к файлу конфигураций
# Файл языка приложения
var lang: Dictionary = {} # Язык
const LangDir: String = BasesPath + "language/" # Директория языков

# Общая часть
# Создание папок для хранения данных
func create_dirs() -> void:
	if not DirAccess.dir_exists_absolute(BasesPath): DirAccess.make_dir_absolute(BasesPath)
	if not DirAccess.dir_exists_absolute(LangDir): DirAccess.make_dir_absolute(LangDir)

# Сохранение данных в файл
func _store_json(file_path: String, data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_line(JSON.stringify(data))
	file.close()
	
# Чтение данных из файла
func _read_file(file_path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var json: JSON = JSON.new()
	if not json.parse(file.get_line()) == OK: return {}
	file.close()
	return json.data
	
# Шифрование данных
func hide_data(data: String) -> String:	return Marshalls.utf8_to_base64(data)

# Дешифрование данных
func show_data(data: String) -> String: return Marshalls.base64_to_utf8(data)

# Файл конфигураций
# Проверка наличия созданного файла конфигураций
func create_config() -> void:
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
	for i in DirAccess.get_files_at(LangDir): if "json" in i and len(i.split(".")) == 2:
		container.add_item(i.split(".")[0])
		# Применение языка, если он соответствует выбранному в файле конфигураций
		if i.split(".")[0] == config.lang:
			container.select(container.item_count-1)
			read_lang(container)
			
# Создание файлов языков
func create_langs() -> void:
	# Убрать этот фрагмент - он нужен чтобы не удалять каждый раз файлы локализации вручную
	DirAccess.remove_absolute(BasesPath + "language/ru.json")
	DirAccess.remove_absolute(BasesPath + "language/en.json")
	
	_cr_ru()
	_cr_en()
	
# Создание файла перевода
func _cr_lang_file(f_name: String, value: Dictionary) -> void:
	if FileAccess.file_exists(LangDir+f_name+".json"): return
	_store_json(LangDir+f_name+".json", value)
	
# Считывание перевода
func read_lang(container: OptionButton) -> void:
	lang = _read_file(LangDir+Global.get_OB_text(container)+".json")
	lang.merge(_standard_language())
	set_lang(container.get_parent())
	# Сохранение выбора в файле конфигураций
	config.lang = Global.get_OB_text(container)
	save_config()

# Поиск ключа в базе перевода
func _find_lang_keys(obj: Variant, key: String = "") -> String:
	if not obj or obj.name == "main": return ""
	key = obj.name + key
	if "_" in key and len(key.split("_")) <= 2 and key.split("_")[1].is_valid_int(): key = key.split("_")[0]
	if key not in lang.keys(): return _find_lang_keys(obj.get_parent(), key)
	else: return key

# Изменение текста объекта в зависимости от типа объекта
func _lang_match(obj: Variant, key: String) -> void:
	match obj.get_class():
		"CheckButton": set_CB(obj)
		"ColorPickerButton": obj.get_child(0).set_text(lang[key]+" "+obj.name.split("_")[1])
		"Label", "CheckBox":
			if obj.text != "" and "-" not in obj.text and not Global.text_is_number(obj.text):
				obj.set_text(lang[key])
		"Button":
			if obj.text in ["", "X"]: obj.tooltip_text = lang[key]
			else: obj.set_text(lang[key])
		"OptionButton":
			if obj.name == "Order": obj.get_parent().reset_order()
			var idx: int = 0
			for i in range(obj.get_item_count()):
				if obj.get_item_text(i) == "": continue
				elif obj.get_item_text(i) in lang.keys() and "__" in obj.get_item_text(i):
					obj.set_item_text(i, lang[obj.get_item_text(i)])
				elif lang[key] is Array:
					if idx >= len(lang[key]): return
					obj.set_item_text(i, lang[key][idx])
					idx += 1
		"ConfirmationDialog":
			if "_ConfirmationDialog" in lang.keys():
				if "cancel" in lang._ConfirmationDialog.keys(): obj.set_cancel_button_text(lang._ConfirmationDialog.cancel)
				if "ok" in lang._ConfirmationDialog.keys(): obj.set_ok_button_text(lang._ConfirmationDialog.ok)
			if "text" in lang[key].keys(): obj.set_text(lang["__sure"]+" "+lang[key].text)
			if "title" in lang[key].keys(): obj.set_title(lang[key].title)
			
# Изменение текста состояния кнопки переключателя
func set_CB(obj: CheckButton) -> void:
	var key: String = _find_lang_keys(obj)
	if key == "": return
	if lang[key] is Array: if len(lang[key]) >= int(obj.button_pressed): obj.set_text(lang[key][int(obj.button_pressed)])
	else: obj.set_text(lang[key])

# Замена текста элементов выпадающего списка
func set_OB_elements(obj: OptionButton) -> void:
	for i in range(obj.get_item_count()): if obj.get_item_text(i) in lang.keys(): obj.set_item_text(i, lang[obj.get_item_text(i)])

# Применение перевода
func set_lang(obj: Variant) -> void:
	var key: String = _find_lang_keys(obj)
	if obj is OptionButton and obj.name == "Month": key = "_Months"
	elif obj is Label and "__" in obj.text and obj.text in lang.keys(): key = obj.text
	if key != "": _lang_match(obj, key)
	for i in obj.get_children(): set_lang(i)

# Создание стандартных вариантов локализации
func _standard_language() -> Dictionary:
	return {
		# Шапка
		"Hints": "Инструкция", "Setting": "Настройки", "HeadCleaning": "Очистка данных", "Main": "Главная",
		"Wallet": "Кошельки", "Section": "Разделы", "Flow": "Движения средств", "Loan": "Кредиты",
		"Event": "События", "Report": "Отчеты", "Exit": "Выход", 
		# Уведомления
		"NBorderCleaning": "Очистить уведомлений", "NotificationTitle": "Событие",
		# Регистрация
		"Registration": "Регистрация", "Enter": "Вход", "LanguageLabel": "Язык:", "LoginLabel": "*Логин:",
		"PasswordLabel": "*Пароль:", "Remember": "Запомни меня", "Show": "Показать пароль",
		# Окна создания / изменения
		"Apply": "Сохранить", "Close": "Отменить изменения",
		# Настройки
		"DeleteUser": "Удалить пользователя", "ColorSchemePreLabel": "Цветовое оформление",
		"ColorSchemeCusLabel": "Количество цветов", "TestButton": "Пример кнопки", "ColorsColor": "Цвет",
		"TestLabel": "Пример текста", "DarkTheme": ["Светлая тема", "Тёмная тема"],
		"SettingsEventType": ["Календарь событий", "Список событий"],
		"Preinstalled": ["Предустановленная тема", "Пользовательская тема"],
		"ColorSchemePre": ["Стандартный", "Серый", "Лимон со смородиной", "Ржавый металл", "Лиса на поляне", "Ягода на ветке", "Ежевика"],
		"ColorSchemeCus": ["Моно", "Контраст", "Триада", "Тетрада"],
		"SettingsConfirmationDialog": {"text": "Все данные пользователя будут удалены", "title": "Удаление пользователя"},
		# Окно очистки данных
		"CleaningCashFlows": "Очистить движения средств", "ClearEvents": "Очистить события", "CleaningLoans": "Очистить займы",
		"CleaningCashFlowsLabel": "Удаление данных о движениях средств, с даты создания которых прошло более 2-х лет",
		"ClearEventsLabel": 'Удаление данных о событиях для которых было назначено повторение "один раз", с момента завершения которых прошло больше 2-х месяцев',
		"CleaningLoansLabel": "Удаление данных о выплаченных займах, с момента погашения которых прошло больше 2-х месяцев", 
		# Фильтры
		"FilterTitleLabel": "Фрагмент названия", "FilterOrderLabel": "Порядок сортировки",
		"YearLabel": "Год фильтрации", "MonthLabel": "Месяц фильтрации", "FilterButton": "Применить",
		# Окно подтверждения
		"_ConfirmationDialog": {"cancel": "Нет", "ok": "Да"}, "__sure": "Вы уверены?",
		# Страница кошельков
		"AddWallet": "Создать счет", "Transaction": "Переносить средства между счетами",
		"CashFlow": "Записать движение средств", "WalletTitle": "Название кошелька",
		"WalletFilterOrder": ["По текущей сумме"],
		"WalletValue": "Текущее значение счета", "WalletCash_Flow": "Движение средств",
		# Страница разделов
		"AddSections": "Создать раздел", "FilterConsumptionIncomeLabel": "Тип статьи",
		"FilterConsumptionIncome": ["Все типы", "Расходы", "Доходы", "Займы"],
		"SectionFilterOrder": ["По дате последней транзакции", "По возрастанию суммы", "По убыванию суммы", "По ежемесячному лимиту"],
		"SectionTitle": "Название раздела", "SectionValue": "Текущее значение", "Month_Limit": "Ограничение",
		"__CI0": "Расход", "__CI1": "Доход",
		# Страница движений средств
		"FilterWalletLabel": "Имя счёта", "FilterSectionLabel": "Статья",
		"CashFlowFilterOrder": ["По статье", "По возрастанию суммы", "По убыванию суммы"],
		"CashFlowTitle": "Название раздела", "CashFlowWallet_Title": "Источник",
		"CashFlowWallet_2_Title": "Цель", "CashFlowValue": "Сумма", "Date": "Дата",
		# Страница займов
		"AddLoan": "Создать займ", "AddInterest": "Добавить проценты по займу", "AddPayment": "Добавить платёж по займу",
		"FilterStatusLabel": "Статус", "FilterStatus": ["Выплачено", "В процессе"],
		"LoanFilterOrder": ["По оставшейся сумме"], "LoanTitle": "Название займа",
		"LoanWallet_Title": "Название целевого счета", "LoanPercent": "Процент по займу",
		"LoanValue": "Начальная сумма займа", "LoanTotal": "Оставшаяся сумма займа",
		# Страница событий
		"AddEvent": "Создать событие", "EventTitle": "Название события", "EventTypeLabel": "Недостаточно средств",
		"__ET1": "Списание", "__ET2": "Приход",
		# Главная страница
		"BudgetLabel": "Бюджет:", "CashFlowLabel": "Денежный поток:", "WalletsLabel": "Список счетов",
		"SectionsLabel": "Расходы по статьям", "EventsLabel": "Ближайшие события",
		"Cash_flowsLabel": "Распределение движений средств",
		"Delete": "Удалить", "FastCreationAdd": "Добавить запись",
		"FastCreationsAdd": "Добавить окно быстрого создания записи",
		# Страница отчетов
		"ReportTitle": "Название", "ReportCash_Flow": "Остаток", "ReportIncome": "Доход",
		"ReportExpenditure": "Расход", "ReportValue": "Итог",
		"WalletsRepLabel": "Общая информация о счетах", "SectionsRepLabel": "Информация по разделам",
		# Страница информации о кошельках
		"WalletTransactionTitle": "Название раздела", "WalletTransactionValue": "Сумма за месяц",
		"WalletTransactionCount": "Количество транзакций за месяц",
		"WalletLabel": "Информация о счете", "Back": "Назад", "Update": "Изменить",
		"Transactions": "Список транзакций", "TotalWLabel": "Значение счета:",
		"TLabel": "Итог:", "TotalCountLabel": "Количество транзакций:",
		"TotalCash_flowLabel": "Сумма:",
		# Страница информации о займах
		"LoanLabel": "Информация о займе", "PercentLabel": "Средний процент по займу:",
		"TotalLLabel": "Оставшаяся сумма:", "TotalValueLabel": "Изначальная сумма:",
		# Окно создания / изменения кошелька
		"WalletWindowTitleLabel": "Название кошелька:",
		"WalletWindowValueLabel": "Значение счета:",
		"WalletWindowWindowConfirmationDialog": { "title": "Удаление кошелька",
			"text": "Все данные кошелька будут удалены"},
		# Окно создания / изменения раздела
		"SectionWindowTitleLabel": "Название раздела:", "SectionWindowIncome": ["Расход", "Доход"],
		"Month_LimitLabel": "Ежемесячное ограничение:",
		"SectionWindowWindowConfirmationDialog": { "title": "Удаление раздела",
			"text": "Все данные раздела будут удалены"},
		# Окно создания / изменения события
		"EventWindowTitleLabel": "Название события:", "Event_typeLabel": "Тип события",
		"Repetition_rateLabel": "Частота повторения", "ValueLabel": "Значение:",
		"EventWindowWindowConfirmationDialog": { "title": "Удаление события",
			"text": "Все данные события будут удалены"},
		"Repetition_rate": ["Один раз", "Каждые два дня", "Раз в неделю",
			"Раз в месяц", "Раз в год"],
		"Event_type": ["Без типа"], "DateLabel": "Выбор даты:",
		# Общие фрагменты для фильтра сортировки (По id, по алфавиту)
		"__FO1": "По дате добавления", "__FO2": "По алфавиту",
		# Объекты из базы данных
		"__ST1": "Переводы", "__ST2": "Заём", "__ST3": "Платежи по займам", "__ST4": "Проценты по займу",
		# Загрузка
		"LoadLabel": "Загрузка уведомлений", "__L1": "Создаём список событий",
		"__L2": "Создаём уведомления",
		# Подсказки
		"__H1": "hello", "__H2": "by",
		# Особые объекты
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
func _cr_ru() -> void: _cr_lang_file("ru", _standard_language())

# Английский
func _cr_en() -> void:
	_cr_lang_file("en", {
		# Шапка
		"Hints": "Instructions", "Setting": "Settings", "HeadCleaning": "Data cleaning", "Main": "Home",
		"Wallet": "Wallets", "Section": "Sections", "Flow": "Movements of funds", "Loan": "Loans",
		"Event": "Events", "Report": "Reports", "Exit": "Exit",
		# Уведомления
		"NBorderCleaning": "Clear notifications", "NotificationTitle": "Event",
		# Регистрация
		"Registration": "Registration", "Enter": "Entry", "LanguageLabel": "Language:", "LoginLabel": "*Login:",
		"PasswordLabel": "*Password:", "Remember": "Remember me", "Show": "Show password",
		# Окна создания / изменения
		"Apply": "Save", "Close": "Cancel changes",
		# Настройки
		"DeleteUser": "Delete user", "ColorSchemePreLabel": "Color design", "ColorsColor": "Color",
		"ColorSchemeCusLabel": "Number of colors", "TestButton": "Button example",
		"TestLabel": "Example text", "DarkTheme": ["Light theme", "Dark theme"],
		"SettingsEventType": ["Events calendar", "List of events"],
		"Preinstalled": ["Pre-installed theme", "Custom Theme"],
		"ColorSchemePre": ["Standard", "Grey", "Lemon with currants", "Rusty metal", "A fox in a clearing", "Berry on a branch", "Blackberry"],
		"ColorSchemeCus": ["Mono", "Contrast", "Triad", "Tetrad"],
		"SettingsConfirmationDialog": {"text": "All user data will be deleted", "title": "Deleting a user"},
		# Окно очистки данных
		"CleaningCashFlows": "Clear funds movements", "ClearEvents": "Clear events", "CleaningLoans": "Clear loans",
		"CleaningCashFlowsLabel": "Deleting data on fund movements that were created more than 2 years ago",
		"ClearEventsLabel": 'Deleting data on events that were scheduled to repeat "once" and that were completed more than 2 months ago',
		"CleaningLoansLabel": "Deleting data on repaid loans that were repaid more than 2 months ago", 
		# Фильтры
		"FilterTitleLabel": "Title fragment", "FilterOrderLabel": "Sorting order",
		"YearLabel": "Year of filtration", "MonthLabel": "Month of filtering", "FilterButton": "Apply",
		# Окно подтверждения
		"_ConfirmationDialog": {"cancel": "No", "ok": "Yes"}, "__sure": "Are you sure?",
		# Страница кошельков
		"AddWallet": "Create an account", "Transaction": "Transfer funds between accounts",
		"CashFlow": "Record the movement of funds", "WalletTitle": "Wallet name",
		"WalletFilterOrder": ["According to the current amount"],
		"WalletValue": "Current account value", "WalletCash_Flow": "Movement of funds",
		# Страница разделов
		"AddSections": "Create a section", "FilterConsumptionIncomeLabel": "Article type",
		"FilterConsumptionIncome": ["All types", "Expenses", "Income", "Loans"],
		"SectionFilterOrder": ["By last transaction date", "Ascending amount", "In descending order of amount", "By monthly limit"],
		"SectionTitle": "Section title", "SectionValue": "Current value", "Month_Limit": "Limit",
		"__CI0": "Expenditure", "__CI1": "Income",
		# Страница движений средств
		"FilterWalletLabel": "Account name", "FilterSectionLabel": "Article",
		"CashFlowFilterOrder": ["According to the article", "Ascending amount", "In descending order of amount"],
		"CashFlowTitle": "Section title", "CashFlowWallet_Title": "Source",
		"CashFlowWallet_2_Title": "Target", "CashFlowValue": "Amount", "Date": "Date",
		# Страница займов
		"AddLoan": "Create a loan", "AddInterest": "Add interest to the loan", "AddPayment": "Add a loan payment",
		"FilterStatusLabel": "Status", "FilterStatus": ["Paid", "In progress"],
		"LoanFilterOrder": ["By remaining amount"], "LoanTitle": "Loan name",
		"LoanWallet_Title": "Name of the target wallet", "LoanPercent": "Interest on a loan",
		"LoanValue": "Initial loan amount", "LoanTotal": "The remaining loan amount",
		# Страница событий
		"AddEvent": "Create an event", "EventTitle": "Event name", "EventTypeLabel": "Insufficient funds",
		"__ET1": "Write-off", "__ET2": "Receipt",
		# Главная страница
		"BudgetLabel": "Budget:", "CashFlowLabel": "Cash flow:", "WalletsLabel": "List of wallets",
		"SectionsLabel": "Expenses by section", "EventsLabel": "Upcoming events",
		"Cash_flowsLabel": "Distribution of cash flows",
		"Delete": "Delete", "FastCreationAdd": "Add entry",
		"FastCreationsAdd": "Add a quick entry creation window",
		# Страница отчетов
		"ReportTitle": "Title", "ReportCash_Flow": "Balance", "ReportIncome": "Income",
		"ReportExpenditure": "Expense", "ReportValue": "Total",
		"WalletsRepLabel": "General information about wallets",
		"SectionsRepLabel": "Information by section",
		# Страница иноформации о кошельках
		"WalletTransactionTitle": "Section title", "WalletTransactionValue": "Amount per month",
		"WalletTransactionCount": "Number of transactions per month",
		"WalletLabel": "Wallet information", "Back": "Back", "Update": "Change",
		"Transactions": "List of transactions", "TotalWLabel": "Wallet value:",
		"TLabel": "Total:", "TotalCountLabel": "Number of transactions:",
		"TotalCash_flowLabel": "Sum:",
		# Страница информации о займах
		"LoanLabel": "Loan information", "PercentLabel": "Average loan interest rate:",
		"TotalLLabel": "Remaining amount:", "TotalValueLabel": "Initial amount:",
		# Окно создания / изменения кошелька
		"WalletWindowTitleLabel": "Wallet name:", "WalletWindowValueLabel": "Wallet value:",
		"WalletWindowWindowConfirmationDialog": { "title": "Removing a wallet",
			"text": "All wallet data will be deleted."},
		# Окно создания / изменения раздела
		"SectionWindowTitleLabel": "Section title:", "Income": ["Expenses", "Income"],
		"Month_LimitLabel": "Monthly limitation:",
		"SectionWindowWindowConfirmationDialog": { "title": "Deleting a partition",
			"text": "All data in this section will be deleted."},
		# Окно создания / изменения события
		"EventWindowTitleLabel": "Event name:", "Event_typeLabel": "Event type",
		"Repetition_rateLabel": "Repetition rate", "ValueLabel": "Value:",
		"EventWindowWindowConfirmationDialog": { "title": "Deleting an event",
			"text": "All event data will be deleted."},
		"Repetition_rate": ["Once", "Every two days", "Once a week", "Once a month", "Once a year"],
		"Event_type": ["No type"], "DateLabel": "Select date:",
		# Общие фрагменты для фильтра сортировки (По id, по алфавиту)
		"__FO1": "By date added", "__FO2": "Alphabetically",
		# Объекты из базы данных
		"__ST1": "Transfers", "__ST2": "Loan", "__ST3": "Loan Payments", "__ST4": "Loan Interest",
		# Загрузка
		"LoadLabel": "Loading notifications", "__L1": "Creating a list of events",
		"__L2": "Creating notifications",
		# Особые объекты
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
