extends Node
# Переменные
const BasesPath: String = "user://bases/" # Расположение директории пользовательских данных
# Файл конфигураций
var config: Dictionary = _empty_conf() # Конфигурации
const ConfigFilePath: String = BasesPath + "config.json" # Путь к файлу конфигураций
# Файл языка приложения
var lang: Dictionary = {} # Язык
const LangDir: String = BasesPath + "language/" # Директория языков

# Общая часть
# Создание папок для хранения данных
func create_dirs() -> void:
	for i in [BasesPath, LangDir]:
		if not DirAccess.dir_exists_absolute(i): DirAccess.make_dir_absolute(i)

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
func hide_data(data: String) -> String: return Marshalls.utf8_to_base64(data)

# Дешифрование данных
func show_data(data: String) -> String: return Marshalls.base64_to_utf8(data)

# Файл конфигураций
# Проверка наличия созданного файла конфигураций
func create_config() -> void:
	if FileAccess.file_exists(ConfigFilePath):
		var new: Dictionary = _read_file(ConfigFilePath)
		if new.keys() == config.keys():
			config = new
			return
	save_config()

# Сохранение данных конфигураций в файл
func save_config() -> void: _store_json(ConfigFilePath, config)

# Пустой словарь конфигурации
func _empty_conf() -> Dictionary: return {"enter": false, "lang": "ru", "login": "", "password": ""}

# Очистка данных пользователя
func clear_config() -> void:
	config = _empty_conf()
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
	return key

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
				if obj.get_item_text(i) == "" or (obj.get_item_text(i) not in lang.keys() and key not in lang.keys()):
					continue
				elif "__" in obj.get_item_text(i):
					obj.set_item_text(i, lang[obj.get_item_text(i)])
				elif lang[key] is Array:
					if idx >= len(lang[key]): return
					obj.set_item_text(i, lang[key][idx])
					idx += 1
		"ConfirmationDialog":
			if "_ConfirmationDialog" in lang.keys():
				for i in ["cancel", "ok"]:
					if i in lang._ConfirmationDialog.keys():
						obj.call("set_"+i+"_button_text", lang._ConfirmationDialog[i])
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
	if key != "" or obj is OptionButton: _lang_match(obj, key)
	for i in obj.get_children(): set_lang(i)

# Создание стандартных вариантов локализации
func _standard_language() -> Dictionary:
	return {
		# Шапка
		"Hints": "Инструкция", "Setting": "Настройки", "Cleaning": "Очистка данных", "Main": "Главная",
		"Wallet": "Кошельки", "Section": "Разделы", "Flow": "Движения средств", "Loan": "Кредиты",
		"Event": "События", "Report": "Отчеты", "Exit": "Выход", 
		# Уведомления
		"NBorderCleaning": "Очистить уведомлений", "NotificationTitle": "Событие",
		# Регистрация
		"Registration": "Регистрация", "Enter": "Вход", "LanguageLabel": "Язык:", "LoginLabel": "Логин:",
		"PasswordLabel": "Пароль:", "Remember": "Запомни меня", "Show": "Показать пароль",
		# Окна создания / изменения
		"Apply": "Сохранить", "Close": "Отменить изменения",
		# Настройки
		"DeleteUser": "Удалить пользователя", "ColorSchemePreLabel": "Цветовое оформление",
		"ColorSchemeCusLabel": "Количество цветов", "TestButton": "Пример кнопки", "ColorsColor": "Цвет",
		"TestLabel": "Пример текста", "Dark_Theme": ["Светлая тема", "Тёмная тема"],
		"Event_Page_Calendar": ["Календарь событий", "Список событий"],
		"Color_Preset": ["Предустановленная тема", "Пользовательская тема"],
		"ColorSchemePre": ["Стандартный", "Серый", "Лимон со смородиной", "Ржавый металл", "Лиса на поляне", "Ягода на ветке", "Ежевика", "Пингвин"],
		"ColorSchemeCus": ["Моно", "Контраст", "Триада", "Тетрада"],
		"SettingsConfirmationDialog": {"text": "Все данные пользователя будут удалены", "title": "Удаление пользователя"},
		# Окно очистки данных
		"CleaningCashFlows": "Очистить движения средств", "ClearEvents": "Очистить события", "CleaningLoans": "Очистить займы",
		"CleaningCashFlowsLabel": "Удаление данных о движениях средств, с даты создания которых прошло более 2-х лет",
		"ClearEventsLabel": 'Удаление данных о событиях, для которых было назначено повторение "один раз", с момента завершения которых прошло больше 2-х месяцев',
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
		"AddSection": "Создать раздел", "FilterConsumptionIncomeLabel": "Тип раздела",
		"AddSubsection": "Создать подраздел", "FilterConsumptionIncome": ["Все типы", "Расходы", "Доходы", "Стандартные разделы"],
		"SectionFilterOrder": ["По дате последней транзакции", "По возрастанию суммы", "По убыванию суммы", "По ежемесячному лимиту"],
		"SectionTitle": "Название раздела", "SectionValue": "Текущее значение", "Month_Limit": "Ограничение",
		"__CI0": "Расход", "__CI1": "Доход",
		# Страница движений средств
		"FilterWalletLabel": "Имя счёта", "FilterSectionLabel": "Раздел",
		"CashFlowFilterOrder": ["По разделу", "По возрастанию суммы", "По убыванию суммы"],
		"CashFlowTitle": "Название раздела", "CashFlowSub_title": "Подраздел",
		"CashFlowWallet_Title": "Источник", "CashFlowWallet_2_Title": "Цель",
		"CashFlowValue": "Сумма", "Date": "Дата",
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
		"SectionsLabel": "Расходы по разделам", "EventsLabel": "Ближайшие события",
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
		"MenuWalletLabel": "Информация о счете", "Back": "Назад", "Update": "Изменить",
		"Transactions": "Список транзакций", "TotalWLabel": "Значение счета:",
		"TLabel": "Итог:", "TotalCountLabel": "Количество транзакций:",
		"TotalCash_flowLabel": "Сумма:",
		# Страница информации о разделах
		"MenuSectionLabel": "Информация о разделе", "FilterSLabel": "Значение по разделу:",
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
		# Окно создания / изменения подраздела
		"SubsectionTitleLabel": "Название подраздела:", "SubsectionSection_idLabel": "Родительский раздел",
		"SubsectionWindowConfirmationDialog": { "title": "Удаление подраздела",
			"text": "Все данные подраздела будут удалены"},
		# Окно создания / изменения движений средств
		"CashFlowWindowWallet_idLabel": "Имя счета", "CashFlowWindowSection_idLabel": "Раздел",
		"ValueVLabel": "Сумма транзакции:",
		"TWindowConfirmationDialog": { "title": "Отмена транзакции",
			"text": "Транзакция будет отменена"},
		# Окно создания / изменения платежа по займу
		"Wallet_idWLabel": "Источник списания", "Wallet_2_idLLabel": "Выбранный займ",
		"PaymentValueLabel": "Сумма платежа:",
		"PaymentWindowConfirmationDialog": { "title": "Удаление платежа по займу",
			"text": "Платёж будет отменен"},
		# Окно создания / изменения процента по займу
		"PercentValueLabel": "Прибавка к займу",
		"PercentWindowConfirmationDialog": { "title": "Удаление процента по займу",
			"text": "Добавленные проценты по займу будут удалены"},
		# Окно создания / изменения займов
		"LoanWindowTitleLabel": "Имя займа:", "W2Label": "Целевой счет",
		"LoanWindowValueLabel": "Сумма займа:",
		"LoanWindowWindowConfirmationDialog": { "title": "Удаление займа",
			"text": "Все данные займа будут удалены"},
		# Окно создания / изменения события
		"EventWindowTitleLabel": "Название события:", "Event_typeLabel": "Тип события",
		"Repetition_rateLabel": "Частота повторения", "EventWindowValueLabel": "Значение:",
		"EventWindowWindowConfirmationDialog": { "title": "Удаление события",
			"text": "Все данные события будут удалены"},
		"Repetition_rate": ["Один раз", "Каждые два дня", "Раз в неделю",
			"Раз в месяц", "Раз в год"],
		"Event_type": ["Без типа"], "DateLabel": "Выбор даты:",
		# Общие фрагменты для фильтра сортировки (По id, по алфавиту)
		"__FO1": "По дате добавления", "__FO2": "По алфавиту",
		# Объекты из базы данных
		"__ST1": "Переводы", "__ST2": "Заём", "__SS1": "Получение",
		"__SS2": "Платеж", "__SS3": "Проценты", "__SS4": "Другое",
		# Загрузка
		"LoadLabel": "Загрузка уведомлений", "__L1": "Создаём список событий",
		"__L2": "Создаём уведомления",
		# Подсказки
		"_Hints": [
			'При выборе языка в соответствующем выпадающем списке, язык текста приложения будет изменен.\nВажно: в случае не полного перевода текст будет автоматически дополнен Русским переводом (создается по умолчанию)',
			"Для начала использования приложения необходимо создать аккаунт пользователя, для этого заполните поля логина (будет отображено в верхней части приложения) и пароля",
			'После чего нажмите кнопку "Регистрация", если пользователь существует, то при нажатии кнопки "Вход" будет совершен вход в его аккаунт.\nВажно: Имя пользователя должно быть уникальным!',
			'При установке галочки у параметра "Показать пароль" текст в поле пароля станет видимым',
			'При установке галочки у параметра "Запомни меня" следующий вход в аккаунт пользователя будет совершен автоматически',
			# Главная
			"После входа в аккаунт пользователя появится главная страница программы, здесь отображается обобщенная информация за текущий месяц",
			"В верхней части главной страницы отображается сумма значений всех кошельков, без учета займов, а также итоговое значение движений средств",
			"При прокрутке главной страницы можно увидеть календарь на две недели (текущую и следующую), в котором будут отмечены дни с событиями.\nВажно: прошедшие события отображаться не будут!",
			'При нажатии на знак "+" в правом нижнем углу экрана будет создано окно быстрого создания движения средств.\nВажно: Создание окна возможно при создании по крайней мере одного кошелька и раздела!',
			"Можно создавать не ограниченное количество окон быстрого создания движений средств, каждое из которых будет сохраняться и будет отображаться после повторного входа в аккаунт",
			'Нажатие на знак "-" в строке быстрого создания записей, приведет к удалению его из списка',
			'Нажатие на знак "+" в строке быстрого создания записей, позволит провести транзакцию, данные которой внесены в окно',
			'Для перехода в меню настроек приложения нужно нажать на кнопку "Настройки" в верхней части приложения',
			# Настройки
			"Изменения, внесенные на странице настроек, имеют только косметический характер и затрагивают только внешний вид приложения у текущего пользователя",
			"На выбор существуют 9 предустановленных цветовых тем, каждая из них отличается в зависимости от выбора между светлой и темной темой",
			"Кроме того пользователь может создать свою собственную цветовую тему при переключении режима предустановленной и пользовательской темы",
			"В пользовательской теме можно настроить количество используемых цветов (от 1 до 4).\nВажно: При выборе темной темы в пользовательской палитре, яркость и контраст выбранных цветов настраивается вручную",
			"Все изменения цветовой палитры будут отображаться в примере внешнего вида приложения.\nВажно: При смене между светлой и темной темой приложения меняются цветовые настройки текста и всех видов кнопок",
			"В настройках также можно выбрать в каком виде будет отображаться список событий (календарь или список)",
			'Нажатие кнопки "Удалить" удалит все данные о пользователе безвозвратно, предварительно предложив отменить решение об удалении пользователя',
			'Изменения в окне настроек будут сохранены только при нажатии кнопки "Сохранить", если закрыть окно нажатием на "Крестик" изменения будут отменены, за исключением выбора языка программы, который применяется без сохранения изменений',
			# Кошельки
			"При переходе на страницу кошельков отображается информация о созданных кошельках, а также приведена информация о сумме движений средств по кошелькам в течении текущего месяца",
			"Кнопки в верхней части страницы кошельков позволяют создавать новые кошельки, а также проводить транзакции с использованием уже созданных.\nВажно: При недостаточном количестве кошельков открыть окна создания транзакций будет невозможно",
			"При нажатии на имя кошелька в списке будет совершен переход на страницу информации о выбранном кошельке",
			# Информация о кошельке
			"На странице информации о кошельке отображаются данные о кошельке за текущий месяц, а также приведен список разделов, по которым проводились транзакции выбранного кошелька и их количество",
			"При проведении транзакций со страниц информации в форму создания объектов будет добавлена информация об объекте страницы информации, это относится к страницам информации о кошельках, разделах и займах",
			# Разделы
			"На странице разделов отображается список разделов, по которым могут быть проведены транзакции.\nВажно: При первом запуске будут автоматически созданы разделы переводов и займов, которые не могут быть изменены или удалены",
			"При проведении транзакций будет обновляться круговая диаграмма, которая отображает информации по каким разделам проводилось суммарно больше средств",
			"При наведении курсора мыши на строку раздела, по которой в выбранном месяце проводились средства, секция на диаграмме будет выделена цветом",
			"У расходных разделов отображается информация о том превысило ли количество проводимых средств в рамках раздела обозначенное максимальное значение в месяце",
			"При нажатии на название раздела будет совершен переход на страницу информации о выбранном разделе",
			# Информация о разделе
			"На странице информации будет отображаться список транзакций за текущий месяц, отсортированных по выбранному разделу",
			'При нажатии на кнопку "Создать подраздел" для раздела можно добавить дочерний элемент, который позволит создавать группы расходов и доходов',
			'У разделов с наличием дочерних элементов список на странице информации будет отображать информацию о проведенных транзакциях, отсортированную по подразделам.\nВажно: Подраздел "Другое" создается автоматически и не может быть изменен или удален',
			# Движения средств
			"При проведении любых транзакций записи о них будут отображаться на странице движений средств",
			"В верхней части списка транзакций отображается график движений средств, распределённых на текущий месяц",
			"Запись о движении средств можно изменить, нажав на имя раздела, по которому проводилась транзакция.\nВажно: Изменение транзакций о займах может быть заблокировано в случаях если заем начали погашать или к займу были добавлены проценты",
			# Займы
			"На странице займов отображается информация о всех ранее созданных займах",
			"Список отображает информацию о займах на текущий момент времени.\nВажно: Средний процент по займу высчитывается автоматически на основе проведенных с займом транзакций",
			"При нажатии на имя займа будет совершен переход на страницу информации о выбранном займе",
			# Информация о займах
			"На странице информации отображается список транзакций, которые проводились над займом.\nВажно: Не все транзакции на странице могут быть изменены после проведения последующих манипуляций над займом",
			"В верхней части страницы информации отображается график изменения значений займа",
			# События
			"На странице событий отображается календарь или список событий (изменяется в настройках) в выбранном месяце",
			"Если события отображаются в виде календаря, то при наведении на ячейку, в которой есть пометка о наличии события, в рядом стоящем списке отобразится список событий в выбранный день",
			"Если типом отображения событий является список, то будет отображен список всех событий за выбранный месяц отсортированный от старых к новым",
			'В день, когда будет происходить событие в верхней части экрана на кнопке "Уведомления" отобразится маркер нового сообщения, при открытии окна уведомлений можно узнать, что за события произошли и дату события',
			"Важно: Если событие произошло в тот момент пока пользователь не входил в приложение, событие всё равно будет добавлено в окно уведомлений",
			'Для очистки окна уведомлений можно нажать кнопку "Очистить" в нижней части окна уведомлений',
			"Событие может быть изменено в любой момент нажатием на его текст в списке событий или легенде календаря",
			# Создание событий
			"В окне создания и изменения событий можно определить частоту, с которой событие будет появляться в календаре.\nВажно: Для события определяется только дата с которой будет начат отсчет события, последующие повторения вычисляются автоматически",
			"Так же для события может быть определен его тип, если для события будет определен доходный или расходный тип, то у события будет отображаться сумма, которую определит пользователь.\nВажно: Событие с выбранным типом не проводит транзакции, только уведомляет о них",
			# Отчет
			"На странице отчета можно увидеть всю информацию о движениях средств за выбранный месяц, которая будет разделена по разделам",
			"При прокрутке страницы можно будет найти график движений средств за выбранный месяц, график учитывает движения средств за предыдущие месяцы",
			# Выход
			'Для того, чтобы выйти из аккаунта пользователя нужно нажать на кнопку "Выход".\nВажно: При выходе из аккаунта автоматический вход будет сброшен и авторизацию нужно будет повторить для входа в аккаунт текущего пользователя',
		],
		# Особые объекты
		"_Months": ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"],
		"_Errors": {
			"_E1": "Обязательные поля должны быть заполнены",
			"_E2": "Имя пользователя занято",
			"_E3": "Неверный логин или пароль",
			"_E4": "Объект с выбранным именем уже существует",
			"_E5": "Значение должно быть больше нуля",
			"_E6": "Выбранные для перевода счета должны различаться",
			"_E7": "Выбранная дата находится до даты оформления займа",
			"_E8": "Существуют транзакции, проведенные над займом после выбранной даты",
			"_E9": "Введенная сумма превышает необходимое значение для полного погашения займа"
		}}

# Русский
func _cr_ru() -> void: _cr_lang_file("ru", _standard_language())

# Английский
func _cr_en() -> void:
	_cr_lang_file("en", {
		# Шапка
		"Hints": "Instructions", "Setting": "Settings", "Cleaning": "Data cleaning", "Main": "Home",
		"Wallet": "Wallets", "Section": "Sections", "Flow": "Movements of funds", "Loan": "Loans",
		"Event": "Events", "Report": "Reports", "Exit": "Exit",
		# Уведомления
		"NBorderCleaning": "Clear notifications", "NotificationTitle": "Event",
		# Регистрация
		"Registration": "Registration", "Enter": "Entry", "LanguageLabel": "Language:", "LoginLabel": "Login:",
		"PasswordLabel": "Password:", "Remember": "Remember me", "Show": "Show password",
		# Окна создания / изменения
		"Apply": "Save", "Close": "Cancel changes",
		# Настройки
		"DeleteUser": "Delete user", "ColorSchemePreLabel": "Color design", "ColorsColor": "Color",
		"ColorSchemeCusLabel": "Number of colors", "TestButton": "Button example",
		"TestLabel": "Example text", "Dark_Theme": ["Light theme", "Dark theme"],
		"Event_Page_Calendar": ["Events calendar", "List of events"],
		"Color_Preset": ["Pre-installed theme", "Custom Theme"],
		"ColorSchemePre": ["Standard", "Grey", "Lemon with currants", "Rusty metal", "A fox in a clearing", "Berry on a branch", "Blackberry", "Penguin"],
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
		"AddSection": "Create a section", "FilterConsumptionIncomeLabel": "Article type",
		"AddSubsection": "Create subsection", "FilterConsumptionIncome": ["All types", "Expenses", "Income", "Standard sections"],
		"SectionFilterOrder": ["By last transaction date", "Ascending amount", "In descending order of amount", "By monthly limit"],
		"SectionTitle": "Section title", "SectionValue": "Current value", "Month_Limit": "Limit",
		"__CI0": "Expenditure", "__CI1": "Income",
		# Страница движений средств
		"FilterWalletLabel": "Account name", "FilterSectionLabel": "Article",
		"CashFlowFilterOrder": ["According to the article", "Ascending amount", "In descending order of amount"],
		"CashFlowTitle": "Section title", "CashFlowSub_title": "Subsection",
		"CashFlowWallet_Title": "Source", "CashFlowWallet_2_Title": "Target",
		"CashFlowValue": "Amount", "Date": "Date",
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
		# Страница информации о разделах
		"SectionLabel": "Section information", "FilterSLabel": "Value by section:",
		# Страница информации о займах
		"LoanLabel": "Loan information", "PercentLabel": "Average loan interest rate:",
		"TotalLLabel": "Remaining amount:", "TotalValueLabel": "Initial amount:",
		# Окно создания / изменения кошелька
		"WalletWindowTitleLabel": "Wallet name:", "WalletWindowValueLabel": "Wallet value:",
		"WalletWindowWindowConfirmationDialog": { "title": "Removing a wallet",
			"text": "All wallet data will be deleted."},
		# Окно создания / изменения раздела
		"SectionWindowTitleLabel": "Section title:", "SectionWindowIncome": ["Expenses", "Income"],
		"Month_LimitLabel": "Monthly limitation:",
		"SectionWindowWindowConfirmationDialog": { "title": "Deleting a partition",
			"text": "All data in this section will be deleted."},
		# Окно создания / изменения подраздела
		"SubsectionTitleLabel": "Subsection title:", "SubsectionSection_idLabel": "Parent section",
		"SubsectionWindowConfirmationDialog": { "title": "Deleting a subsection",
			"text": "All data in the subsection will be deleted"},
		# Окно создания / изменения движений средств
		"CashFlowWindowWallet_idLabel": "Wallet name", "CashFlowWindowSection_idLabel": "Section",
		"ValueVLabel": "Transaction amount:",
		"TWindowConfirmationDialog": { "title": "Cancel transaction",
			"text": "The transaction will be cancelled"},
		# Окно создания / изменения платежа по займу
		"Wallet_idWLabel": "Source of write-off", "Wallet_2_idLLabel": "Selected loan",
		"PaymentValueLabel": "Payment amount:",
		"PaymentWindowConfirmationDialog": { "title": "Deleting a loan payment",
			"text": "Payment will be canceled"},
		# Окно создания / изменения процента по займу
		"PercentValueLabel": "Loan addition",
		"PercentWindowConfirmationDialog": { "title": "Removing interest on a loan",
			"text": "Added interest on the loan will be removed"},
		# Окно создания / изменения займов
		"LoanWindowTitleLabel": "Loan name:", "W2Label": "Target wallet",
		"LoanWindowValueLabel": "Loan amount:",
		"LoanWindowWindowConfirmationDialog": { "title": "Delete a loan",
			"text": "All loan data will be deleted"},
		# Окно создания / изменения события
		"EventWindowTitleLabel": "Event name:", "Event_typeLabel": "Event type",
		"Repetition_rateLabel": "Repetition rate", "EventWindowValueLabel": "Value:",
		"EventWindowWindowConfirmationDialog": { "title": "Deleting an event",
			"text": "All event data will be deleted."},
		"Repetition_rate": ["Once", "Every two days", "Once a week", "Once a month", "Once a year"],
		"Event_type": ["No type"], "DateLabel": "Select date:",
		# Общие фрагменты для фильтра сортировки (По id, по алфавиту)
		"__FO1": "By date added", "__FO2": "Alphabetically",
		# Объекты из базы данных
		"__ST1": "Transfers", "__ST2": "Loan", "__SS1": "Getting а",
		"__SS2": "Payment", "__SS3": "Interest", "__SS4": "Other",
		# Загрузка
		"LoadLabel": "Loading notifications", "__L1": "Creating a list of events",
		"__L2": "Creating notifications",
		# Подсказки
		"_Hints": [
			'When you select a language from the corresponding drop-down list, the language of the application text will be changed.\nImportant: if the translation is incomplete, the text will be automatically supplemented with a Russian translation (created by default)',
			"To start using the application, you need to create a user account. To do this, fill in the login (will be displayed at the top of the application) and password fields",
			'Then click the "Register" button. If the user exists, then clicking the "Login" button will log you into his account.\nImportant: The username must be unique!',
			'By checking the "Show password" box, the text in the password field will become visible',
			'By checking the box next to the "Remember me" option, the next time you log into your user account, it will be done automatically',
			# Главная
			"After logging into the user account, the main page of the program will appear, where the summary information for the current month is displayed",
			"The top of the main page displays the sum of all wallet values, excluding loans, as well as the total value of fund movements",
			"When scrolling the main page, you can see a two-week calendar (current and next), which will highlight days with events.\nImportant: past events will not be displayed!",
			'Clicking the "+" sign in the lower right corner of the screen will create a quick funds movement window.\nImportant: This window can only be created if you have created at least one wallet and section!',
			"You can create an unlimited number of quick funds movement windows, each of which will be saved and will appear after you log back into your account",
			'Clicking the "-" sign in the quick entry creation line will remove it from the list',
			'Clicking the "+" sign in the quick entry creation line will execute the transaction whose data is entered in the window',
			'To access the app settings menu, click on the "Settings" button at the top of the app.',
			# Настройки
			"Changes made on the Settings page are cosmetic only and affect the app's appearance for the current user",
			"There are 9 preset color themes to choose from, each with a different color theme depending on whether you choose Light or Dark mode",
			"In addition, the user can create their own color theme by switching between preset and custom themes",
			"In the custom theme, you can customize the number of colors used (from 1 to 4).\nImportant: When selecting a dark theme in the custom palette, the brightness and contrast of the selected colors must be adjusted manually",
			"All color palette changes will be reflected in the sample app appearance.\nImportant: When switching between the light and dark app themes, the color settings for the text and all button types change",
			"In the settings, you can also choose how the event list will be displayed (calendar or list)",
			'Clicking the "Delete" button will permanently delete all user data, prompting you to cancel the deletion decision',
			'Changes in the settings window will only be saved when you click the "Save" button. Closing the window by clicking the "X" will discard the changes, with the exception of the program language selection, which is applied without saving the changes',
			# Кошельки
			"When you go to the Wallets page, information about created wallets is displayed, as well as the total amount of funds transferred across wallets during the current month",
			"The buttons at the top of the Wallets page allow you to create new wallets and conduct transactions using existing ones.\nImportant: If there are not enough wallets, it will be impossible to open the transaction creation windows",
			"Clicking on a wallet name in the list will redirect you to the information page for the selected wallet",
			# Информация о кошельке
			"The wallet information page displays wallet data for the current month, along with a list of sections where transactions for the selected wallet were conducted and their number",
			"When conducting transactions from information pages, information about the page object will be added to the object creation form. This applies to wallet, section, and loan information pages",
			# Разделы
			"The sections page displays a list of sections for which transactions can be processed.\nImportant: When you first launch the page, transfer and loan sections will be automatically created and cannot be modified or deleted",
			"When transactions are processed, a pie chart will update, displaying information about which sections had the highest total transactions",
			"When you hover over a section row where funds were processed in the selected month, the section on the chart will be highlighted",
			"Expense sections display information about whether the amount of funds processed within the section exceeded the specified maximum value for the month.",
			"Clicking on the section title will take you to the information page for the selected section",
			# Информация о разделе
			"The information page will display a list of transactions for the current month, sorted by the selected section",
			'By clicking the "Create Subsection" button, you can add a child element to the section, which will allow you to create expense and income groups',
			'For sections with child elements, the list on the information page will display information about completed transactions, sorted by subsection.\nImportant: The "Other" subsection is created automatically and cannot be changed or deleted',
			# Движения средств
			"When any transaction is conducted, records of them will be displayed on the Funds Movements page",
			"A chart of fund movements allocated for the current month is displayed at the top of the transaction list",
			"A fund movement record can be edited by clicking on the section name for which the transaction was conducted.\nImportant: Editing loan transactions may be blocked if the loan has begun to be repaid or interest has been added to the loan",
			# Займы
			"The loans page displays information about all previously created loans",
			"The list displays information about loans currently active.\nImportant: The average loan interest rate is calculated automatically based on transactions conducted with the loan",
			"Clicking on a loan name will redirect you to the information page for the selected loan",
			# Информация о займах
			"The information page displays a list of transactions performed on the loan.\nImportant: Not all transactions on the page can be changed after subsequent manipulations on the loan",
			"At the top of the information page, a graph of changes in loan values ​​is displayed",
			# События
			"The events page displays a calendar or a list of events (changeable in settings) for the selected month",
			"If events are displayed as a calendar, hovering over a cell marked with an event will display a list of events for the selected day in the adjacent list",
			"If the event display type is a list, a list of all events for the selected month will be displayed, sorted from oldest to newest",
			'On the day an event occurs, a new message marker will appear on the "Notifications" button at the top of the screen. When you open the notification window, you can see what events occurred and the event date',
			"Important: If an event occurs while the user is not logged in to the app, the event will still be added to the notification window",
			'To clear the notification window, you can click the "Clear" button at the bottom of the notification window',
			"An event can be edited at any time by clicking on its text in the event list or calendar legend",
			# Создание событий
			"In the event creation and editing window, you can determine the frequency with which an event will appear in the calendar.\nImportant: Only the start date is determined for an event; subsequent occurrences are calculated automatically",
			"You can also specify an event's type. If an event is assigned an income or expense type, the event will display the amount specified by the user.\nImportant: An event with the selected type does not process transactions; it only notifies about them",
			# Отчет
			"On the report page, you can see all the information about cash flows for the selected month, divided into sections",
			"When you scroll the page, you can find a graph of cash flows for the selected month. The graph takes into account cash flows for previous months",
			# Выход
			'To log out of a user account, click the "Log Out" button.\nImportant: When you log out of an account, automatic login will be reset and you will need to re-authorize to log into the current user\'s account',
		],
		# Особые объекты
		"_Months": ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
		"_Errors": {
			"_E1": "Required fields must be filled in",
			"_E2": "Username taken",
			"_E3": "Incorrect login or password",
			"_E4": "An object with the selected name already exists",
			"_E5": "Value must be greater than zero",
			"_E6": "The wallets selected for transfer must be different",
			"_E7": "The selected date is before the loan registration date",
			"_E8": "There are transactions carried out on the loan after the selected date",
			"_E9": "The amount entered exceeds the required amount for full repayment of the loan"
		}
	})
