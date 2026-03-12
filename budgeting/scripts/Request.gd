extends Node
# Перечисление
enum Tables {WALLETS, SECTIONS, SUBSECTIONS, CASH_FLOWS, LOANS, EVENTS, SETTINGS, NOTIFICATIONS, SQLITE_SEQUENCE, USERS} # Таблицы в базе данных
enum ObjectVariants {WALLET, SECTION, CASH_FLOW, LOAN, EVENT, REPORT_W, REPORT_S, NOTIFICATION, FAST_CREATION, WALLET_TRANSACTION, SUBSECTION} # Варианты списков объектов по которым могут быть запросы

# Переменная
var db: SQLite = null # Подключенная база данных
# Для заполнения таблицы событий
var events: Array = [] # Список событий для постепенного увеличения их количества
var completion_creation_et: bool = false # Маркер завершения заполнения таблицы событий
@onready var selected_date: NewDate = NewDate.new(Time.get_datetime_string_from_system()) # Выбранная дата
@onready var next_month: NewDate = NewDate.new(Time.get_datetime_string_from_system())  # Следующий месяц
var last_month_day_count: int = 30 # количество дней в предыдущем месяце

# Открытие базы данных
func _open_db(db_name: String = "users") -> void:
	db = SQLite.new()
	db.path = File.BasesPath + db_name + ".db"
	db.open_db()

# Подключение базы данных пользователей
func connection_user_db() -> void:
	_open_db()
	_create_table("users", "login VARCHAR(255), password VARCHAR(255), base VARCHAR(255)")

# Подключение базы данных
func connection_db(db_name: String) -> void:
	_open_db(db_name)
	# Создание таблиц в базе
	_create_table("wallets", "title VARCHAR(255), value FLOAT")
	_create_table("sections", "title VARCHAR(255), month_limit FLOAT, income BOOLEAN")
	_create_table("subsections", "parent_id INT, title VARCHAR(255), month_limit FLOAT", ["(`parent_id`) REFERENCES `sections`(`id`)"])
	_create_table("cash_flows", "wallet_id INT, wallet_2_id INT, section_id INT, subsection_id INT, value FLOAT, date DATE",
		["(`wallet_id`) REFERENCES `wallets`(`id`)", "(`section_id`) REFERENCES `sections`(`id`)", "(`subsection_id`) REFERENCES `subsections`(`id`)"])
	_create_table("loans", "title VARCHAR(255), total FLOAT")
	_create_table("events", "title VARCHAR(255), event_type INT, value FLOAT, repetition_rate INT, date DATE")
	_create_table("multiplied_events", "title VARCHAR(255), event_type INT, value FLOAT, date DATE, completed BOOLEAN, event_id INT")
	# Создание таблиц для персонализации приложения
	_create_table("settings", "color_preset BOOLEAN, color_scheme INT, color_1 VARCHAR(255), color_2 VARCHAR(255), color_3 VARCHAR(255), color_4 VARCHAR(255), dark_theme BOOLEAN, event_page_calendar BOOLEAN, last_entry DATE")
	_create_table("notifications", "event_id INT, new BOOL, date DATE", ["(`event_id`) REFERENCES `events`(`id`)"])
	_create_table("fast_creations", "wallet_id INT, section_id INT, subsection_id INT",
		["(`wallet_id`) REFERENCES `wallets`(`id`)", "(`section_id`) REFERENCES `sections`(`id`)", "(`subsection_id`) REFERENCES `subsections`(`id`)"])
	if len(select(Tables.SECTIONS)) == 0: for i in ["__ST1", "__ST2"]: insert_record(Tables.SECTIONS, ['"'+i+'"', -1, false])
	if len(select(Tables.SUBSECTIONS)) == 0: for i in ["__SS1", "__SS2", "__SS3"]: insert_record(Tables.SUBSECTIONS, [2, '"'+i+'"', -1])
	if len(select(Tables.SETTINGS)) == 0: db.query('INSERT INTO settings (color_preset, color_scheme, color_1, color_2, color_3, color_4, dark_theme, event_page_calendar, last_entry) VALUES (0, 0, "3a9891ff", "c8c8c8ff", "000000ff", "000000ff", 0, 0, "'+Global.date_to_str()+'")')

# Запрос на создание таблицы
func _create_table(title: String, columns: String, foreign: Array = []) -> void:
	if len(foreign) != 0: foreign = [""] + foreign
	db.query("CREATE TABLE IF NOT EXISTS "+title+" (id INTEGER PRIMARY KEY AUTOINCREMENT, "+columns+", FOREIGN KEY ".join(foreign)+");")

# Получить название таблицы из enum Tables
func _get_table_name(table: Variant) -> String:
	if table is String: return table
	return Global.enum_key(Tables, table)

# Получить названия колонок
func _get_columns(table: Variant) -> Array:
	db.query("PRAGMA table_info(`"+_get_table_name(table)+"`)")
	var result: Array = []
	for i in db.query_result: result.append(i.name)
	result.pop_front()
	return result
	
# Добавление фрагмента текста в запрос
func add_part_request(text: String, column: String, value: Variant, operator: String = "=", sep: String = " AND ") -> String:
	if text: text += sep 
	if operator == "LIKE": value = '"%' + str(value) + '%"'
	text += column + " " + operator + " " + str(value)
	return text
	
# Добавление фрагмента текста в запрос с проверкой что значение не null
func add_part_request_with_check(text: String, column: String, value: Variant, operator: String = "=", sep: String = " AND ") -> String:
	if not value: return text
	return add_part_request(text, column, value, operator, sep)

# Отправка запроса на создание записи таблице
func insert(table: Variant, columns: Array, values: Array) -> void:
	if table is Tables: table = _get_table_name(table)
	db.query("INSERT INTO `"+_get_table_name(table)+"` ("+",".join(columns)+") VALUES ("+",".join(values)+");")

# Добавление записи
func insert_record(table: Variant, values: Array) -> void:
	insert(table, _get_columns(table), values)

# Отправка запроса на изменение записей в таблице
func update(table: Variant, values: String, where: String) -> void:
	db.query("UPDATE `"+_get_table_name(table)+"` SET "+values+" WHERE "+where + ";")

# Изменение записи
func update_record(table: Variant, id: int, values: Array) -> void:
	var request_text: String = ""
	var columns: Array = _get_columns(table)
	for i in len(values): request_text = add_part_request(request_text, columns[i], values[i], "=", ", ")
	update(table, request_text, "id=" + str(id))

# Отправка запроса на удаление записи в таблице
func delete(table: Variant, id: int) -> void:
	db.query("DELETE FROM `"+_get_table_name(table)+"` WHERE id="+str(id)+";")
	update(Tables.SQLITE_SEQUENCE, "seq=seq-1", 'name="'+_get_table_name(table)+'"')
	update(table, "id=id-1", "id>"+str(id))

# Сборка даты
func where_date(date: String = Global.date_to_str(), column: String = "date", operator: String = "=") -> String:
	return "strftime('%Y-%m', "+column+")"+operator+"strftime('%Y-%m', '"+date+"')"

# Получение данных из таблиц
func select(table: Variant, columns: String = "*", where: String = "", order: String = "", left: String = "") -> Array:
	if left: left = " LEFT JOIN "+left
	return _select(columns+" FROM "+_get_table_name(table)+left, where, order)

# Проверка достаточно ли данных в базе для создания движения средств
func select_possibility_opening_cashFlow() -> bool:
	return len(select(Tables.WALLETS)) != 0 and len(select(Tables.SECTIONS)) > 4

# Проверка достаточно ли данных в базе для создания платежа и добавления процентов по займу
func select_possibility_opening_payment() -> bool:
	return len(select(Tables.WALLETS)) != 0 and len(select(Tables.LOANS, "*", "total>0")) != 0
	
# Получение названия объекта под определенным индексом
func _select_title(table: Tables, id: int) -> String: return select(table, "title", "id="+str(id))[0].title

# Получение информации об объекте с учетом возможности его отсутствия
func select_inf_value(table: Tables, id: int) -> Dictionary:
	var value: Array = select(table, "*", "id="+str(id))
	if len(value) == 0: return {}
	return value[0]
	
# Получение информации о займе
func select_loan_inf(id: int) -> Dictionary:
	var value: Dictionary = select_inf_value(Tables.LOANS, id)
	if value == {}: return value
	value["value"] = select(Tables.CASH_FLOWS, "*", "section_id=2 AND subsection_id=1 AND wallet_2_id="+str(id))[0].value
	value["percents"] = str(select_loan_percent(id)) + "%"
	return value

# Получение кошелька по индексу
func select_wallet(id: int) -> Array: return select(Tables.WALLETS, "*", "id="+str(id))

# Получение раздела по индексу
func select_section(id: int) -> Array: return select(Tables.SECTIONS, "*", "id="+str(id))

# Получение займа по индексу
func select_loan(id: int) -> Array: return select("cash_flows cf", "cf.*, l.title", "section_id=2 AND subsection_id=2 AND wallet_2_id="+str(id), "", "loans l ON l.id=wallet_2_id")

# Получение события по индексу
func select_event(id: int) -> Array:
	var results: Array = select(Tables.EVENTS, "*", "id="+str(id))
	for i in range(len(results)): results[i].repetition_rate += 1
	return results

# Получение среднего процента по займу при учете процесса погашения займа
func select_loan_percent(id: int) -> int:
	var summ: float = 0.0
	var percents: Array = []
	for i in _select("* FROM cash_flows", "section_id=2 AND wallet_2_id="+str(id), "date"):
		match i.subsection_id:
			1: summ = i.value
			2: summ -= i.value
			3:
				percents.append((i.value * 100.) / summ)
				summ += i.value
	if len(percents) == 0: return 0
	var result: float = 0
	for i in percents:
		result += i
	return int(round(result / len(percents)))

# Годится
# Постепенное создание событий в таблице событий
func _process(_delta: float) -> void:
	if not completion_creation_et:
		if len(events) == 0:
			completion_creation_et = true
			return
		var value: Dictionary = events.pop_front()
		var new_date: Dictionary = Global.date_to_dict(value.new_date)
		match value.repetition_rate:
			1: _insert_events_with_step(value, new_date, selected_date.day_count, 2)
			2: _insert_events_with_step(value, new_date, selected_date.day_count, 7)
			0:
				if selected_date.date_comparison(new_date, "=="): _insert_event(value, new_date)					
				if selected_date.date.day != 1 and Global.date_comparison(next_month.date, new_date, "==", false): _insert_event(value, new_date)
			3, 4:
				_insert_events_to_repetition_rate_3_4(value, new_date, selected_date.date)
				if selected_date.date.day != 1: _insert_events_to_repetition_rate_3_4(value, new_date, next_month.date)

# Получение данных из таблиц
func _select(req_text: String, where: String = "", order: String = "", group: String = "") -> Array:
	if where: where = " WHERE " + where
	if group: group = " GROUP BY " + group
	if order: order = " ORDER BY " + order
	db.query("SELECT " + req_text + where + group + order + ";")
	return db.query_result

func select_value(table: Variant, column: String) -> Variant:
	var value: Array = select(table)
	if len(value) > 0: return value[0][column]
	return null

# Проверка существует выбранный пользователь
func select_existence_user(login: bool) -> bool:
	var req: String = 'login="'+File.config["login"]+'"'
	if login: req += ' AND password="'+File.config["password"]+'"'
	var res: Array = Request.select(Tables.USERS, "COUNT(id)=="+str(int(login))+" res", req)
	if len(res) == 0: return false
	return res[0].res

# Получение пользователя
func select_user() -> Dictionary:
	var user_data: Array = []
	for i in File.config.keys(): if i in _get_columns(Tables.USERS): user_data.append(i+'="'+File.config[i]+'"')
	return Request.select(Tables.USERS, "*", " AND ".join(user_data))[0]

# Удаление пользователя
func delete_user() -> void:
	Request.connection_user_db()
	var data: Dictionary = select(Tables.USERS, "*", 'login="'+File.config.login+'"')[0]
	DirAccess.remove_absolute("res://bases/"+File.show_data(data.base)+".db")
	delete(Tables.USERS, data.id)
	File.clear_config()
	
# Получение количества дней в текущем месяце
func select_day_count(date: String) -> int:
	if not db: return 30
	return int(_select("STRFTIME('%d', DATE('"+date+"', 'start of month', '+1 month', '-1 day')) day_count")[0].day_count)

# Получение текущего суммарного бюджета
func select_wallets_sum() -> float:
	return _select("COALESCE((SELECT COALESCE(SUM(value),0.0) FROM wallets) - (SELECT COALESCE(SUM(total),0.0) FROM loans), 0.0) value")[0].value

# Текст для запроса движений средств
func _funds_movements_text() -> String:
	return "COALESCE(SUM(CASE WHEN cf.section_id=1 OR cf.subsection_id=3 THEN 0 WHEN cf.subsection_id=2 OR (s.income = 0 AND s.month_limit<>-1) THEN cf.value * -1 ELSE cf.value END),0.0) value
		FROM cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id"

# Получить сумму движений средств за время до выбранной даты
func select_past_funds_movements(date: String = Global.date_to_str()) -> float:
	return _select(_funds_movements_text(), where_date(date, "date", "<"))[0].value

# Получение движения средств
func select_funds_movements() -> float: return _select(_funds_movements_text(), where_date())[0].value

# Запрос на получение списка кошельков
func _select_wallets_list(where: String, order: String) -> Array:
	return _select("*, (SELECT cf.date FROM cash_flows cf WHERE (cf.section_id!=2
		AND cf.wallet_2_id=w.id) OR cf.wallet_id=w.id ORDER BY cf.date DESC) last_date FROM wallets w",where,order)

# Запрос на изменение списка кошельков
func _update_wallets_list(line: Dictionary, date: String = Global.date_to_str()) -> Dictionary:
	var value: Array = _select("SUM(IIF((cf.section_id=1 and cf.wallet_id="+str(line.id)+")OR cf.subsection_id=2 OR (s.income=0 and cf.section_id>2 and cf.wallet_id="+str(line.id)+"), cf.value*-1, cf.value)) value
		FROM cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id", "(cf.wallet_id="+str(line.id)+" or (cf.wallet_2_id="+str(line.id)+" and cf.section_id=1)) AND "+where_date(date, "cf.date"))
	line["cash_flow"] = value[0].value if value[0].value else 0.
	return line
	
# Запрос на получение списка разделов
func select_sections_list(where: String = "", date: String = Global.date_to_str(), order: String = "") -> Array:
	return _select("s.*, COALESCE(j.v, 0.0) value, j.last_date, j.last_id FROM `sections` s LEFT JOIN (SELECT cf.section_id, SUM(cf.value) v,
		cf.date last_date, cf.id last_id FROM `cash_flows` cf WHERE "+where_date(date)+" GROUP BY cf.section_id) j ON s.id=j.section_id",where,order)

# Запрос на изменение списка разделов
func _update_sections_list(line: Dictionary, parent: Variant) -> Dictionary:
	line["marker"] = ColorScheme.get_color(parent.obj_count(), len(parent.lines.change_list) + parent.obj_count())
	line["progress"] = (100. * line.value) / line.month_limit
	return line
	
# Запрос на получение списка подразделов
func _select_subsections_list(where: String = "") -> Array:
	return _select("ss.*, s.income, COALESCE(j.v, 0.0) value, j.last_date, j.last_id FROM subsections ss LEFT JOIN sections s ON ss.parent_id = s.id
		LEFT JOIN (SELECT SUM(value) v, date last_date, id last_id, subsection_id FROM cash_flows cf GROUP BY section_id, subsection_id) j ON j.subsection_id = ss.id",
		"ss.parent_id = "+where.split(" = ")[-1], "last_date DESC, id DESC")

# Запрос на получение списка движений средств
func _select_cash_flows_list(where: String = "", date: String = Global.date_to_str(), order: String = "") -> Array:
	if date != "":
		if where != "": where = " AND " + where
		where = where_date(date) + where
	return _select("cf.*, s.title, COALESCE(ss.title, '') sub_title, s.income, w.title wallet_title FROM `cash_flows` cf LEFT JOIN sections s ON cf.section_id=s.id
		LEFT JOIN wallets w ON cf.wallet_id=w.id LEFT JOIN subsections ss ON cf.subsection_id=ss.id", where, order)

# Запрос на изменение списка разделов
func _update_cash_flows_list(line: Dictionary) -> Dictionary:
	match line.section_id:
		1: line["wallet_2_title"] = _select_title(Tables.WALLETS, line.wallet_2_id)
		2:
			if line.subsection_id == 1: line["wallet_2_title"] = _select_title(Tables.LOANS, line.wallet_2_id)
			else:
				line["wallet_2_title"] = line.wallet_title
				line.wallet_title = _select_title(Tables.LOANS, line.wallet_2_id)
				var save_id: int = line.wallet_id if line.wallet_id else 0
				line.wallet_id = line.wallet_2_id
				line.wallet_2_id = save_id
		_: if line.income:
			line["wallet_2_title"] = line.wallet_title
			line.wallet_2_id = line.wallet_id
	return line
	
# Получение суммы движений средств распределенных по дням
func select_cash_flow_graphics(where: String, date: String = Global.date_to_str()) -> Array:
	if where: where = " AND " + where
	return _select("SUM(CASE WHEN cf.section_id=1 OR cf.subsection_id=3 THEN 0 WHEN cf.subsection_id = 2 OR (s.income = 0 AND s.month_limit<>-1)  THEN cf.value * -1 ELSE cf.value END) value,
		strftime('%d', cf.date) day FROM cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id ", where_date(date)+where, "", "cf.date")

# Получение списка займов
func _select_loans_list(where: String = "", order: String = "") -> Array:
	return _select("l.*, cf.wallet_id, w.title wallet_title, cf.value FROM loans l LEFT JOIN cash_flows cf ON cf.subsection_id=1 AND cf.wallet_2_id=l.id LEFT JOIN wallets w ON cf.wallet_id=w.id", where, order)

# Добавление событий во временную таблицу
func _insert_event(value: Dictionary, date: Dictionary) -> void:
	var text_date: String = Global.date_to_str(date).split(" ")[0]
	insert_record("multiplied_events", ["'"+value.title+"'", value.event_type, value.value, "'"+text_date+"'", Global.date_comparison(Global.get_date(), date, ">"), value.id])

# Добавление событий во временную таблицу с выбранным шагом
func _insert_events_with_step(value: Dictionary, new_date: Dictionary, day_count: int, step: int) -> void:
	var two_week: int = 0
	if selected_date.date.day != 1 and new_date.month != next_month.date.month: two_week = 14
	while new_date.day <= day_count + two_week:
		var date_dup: Dictionary = new_date.duplicate()
		if new_date.day > day_count:
			date_dup = next_month.date.duplicate()
			date_dup.day = new_date.day - day_count
		elif date_dup.day > next_month.day_count: break
		_insert_event(value, date_dup)
		new_date.day += step

# Создание событий для частоты раз в месяц и раз в год
func _insert_events_to_repetition_rate_3_4(value: Dictionary, new_date: Dictionary, date: Dictionary) -> void:
	new_date.year = date.year
	if value.repetition_rate == 3:
		new_date.month = date.month
		if last_month_day_count < new_date.day: _insert_event(value, new_date)
		if selected_date.day_count >= new_date.day: _insert_event(value, new_date)
	elif new_date.month == date.month and selected_date.day_count >= new_date.day: _insert_event(value, new_date)
	elif new_date.month == Global.get_other_month(date).month and last_month_day_count < new_date.day: _insert_event(value, new_date)
		
# Получение событий в текущем месяце с датой первого появления
func _select_events_list(date: String, date2: String) -> Array:
	return _select("*, Date(julianday(date) + juli + CASE WHEN juli<0 THEN juli*-1 WHEN repetition_rate=1 THEN juli%2
		WHEN repetition_rate=2 THEN 7-juli%7 ELSE juli*-1 END) new_date FROM (SELECT *, (julianday(Date('"+date+\
		"'))-julianday(date)) juli FROM events) AS event", where_date(date2, "date", "<="), "new_date")
	
# Начало создания таблицы событий
func start_create_multiplied_events_table(date: String) -> void:
	selected_date.set_value(date)
	next_month.set_value(Global.get_other_month(selected_date.date, true))
	last_month_day_count = select_day_count(Global.get_other_month(date))
	events = _select_events_list(date, date if selected_date.date.day < selected_date.day_count - 14 else Global.date_to_str(next_month.date))
	db.query("DELETE FROM multiplied_events")
	update(Tables.SQLITE_SEQUENCE, "seq=0", 'name="multiplied_events"')
	completion_creation_et = false
	
func select_multiplied_events_list(where: String = "") -> Array:
	if where: where = "CAST(strftime('%d', date) AS INTEGER) = "+where
	return select("multiplied_events", "*", where, "date")

# Запрос на изменение списка разделов
func _update_events_list(line: Dictionary) -> Dictionary:
	if line.event_type == 1: line["profit_accounting"] = select("wallets", "COALESCE(SUM(value), 0.0) value")[0].value + select("multiplied_events", "COALESCE(SUM(value), 0.0) value", 'event_type=2 AND date<"'+line.date+'"')[0].value - line.value
	return line
	
# Запрос на получение списка событий без дубликации записей
func _select_unique_events() -> Array: return _select("title, event_id FROM multiplied_events GROUP BY event_id")

# Получение списка дней с покрайней мере одним событием
func select_event_days(where: String = "") -> Array: return _select("date FROM multiplied_events", where, "", "date")

# Запрос на получение списка отчета по счетам
func _select_wallets_report(date: String = Global.date_to_str()) -> Array:
	return _select("w.id, w.title,
		COALESCE((SELECT SUM(cf.value) FROM cash_flows cf LEFT JOIN sections s on cf.section_id=s.id WHERE ((cf.wallet_id=w.id AND (s.income=1 OR cf.subsection_id=1)) OR (cf.section_id=1 AND cf.wallet_2_id=w.id)) AND "+where_date(date, "cf.date")+"), 0.0) income,
		COALESCE((SELECT SUM(cf.value) FROM cash_flows cf LEFT JOIN sections s on cf.section_id=s.id WHERE ((cf.wallet_id=w.id AND ((s.income=0 AND cf.section_id>2) OR cf.subsection_id = 2)) OR (cf.section_id=1 AND cf.wallet_id=w.id)) AND "+where_date(date, "cf.date")+"), 0.0) expenditure,
		COALESCE((SELECT SUM(IIF((cf.section_id=1 and cf.wallet_id=w.id)OR cf.subsection_id=2 OR (s.income=0 and cf.section_id>2 and cf.wallet_id=w.id), cf.value*-1, cf.value)) FROM cash_flows cf LEFT JOIN sections s on cf.section_id=s.id WHERE (cf.wallet_id=w.id or (cf.wallet_2_id=w.id and cf.section_id=1)) AND "+where_date(date, "cf.date", "<")+"), 0.0) cash_flow
		FROM wallets w")

# Запрос на получение списка отчета по разделам
func _select_sections_report(date: String = Global.date_to_str()) -> Array:
	return _select("* FROM (SELECT t.id, t.title,
		COALESCE((SELECT SUM(cf.value) FROM cash_flows cf LEFT JOIN sections s on cf.section_id=s.id WHERE (s.income=1 OR cf.subsection_id=1) AND cf.section_id=t.id AND "+where_date(date, "cf.date")+"), 0.0) income,
		COALESCE((SELECT SUM(cf.value) FROM cash_flows cf LEFT JOIN sections s on cf.section_id=s.id WHERE s.income=0 AND (cf.section_id>2 OR cf.subsection_id=2) AND cf.section_id=t.id AND "+where_date(date, "cf.date")+"), 0.0) expenditure
		FROM sections t WHERE t.id != 1) WHERE (income != 0 OR expenditure != 0)")
	
# Запрос на изменение списка отчета
func _update_reports_list(line: Dictionary) -> Dictionary:
	line["value"] = line.cash_flow + line.income - line.expenditure
	return line

# Распределение запросов для заполнения списков на страницах
func match_select(list_element: ObjectVariants, filter_data: Dictionary) -> Array:
	match list_element:
		ObjectVariants.WALLET: return _select_wallets_list(filter_data.where, filter_data.order)
		ObjectVariants.SECTION: return select_sections_list(filter_data.where, filter_data.date, filter_data.order)
		ObjectVariants.SUBSECTION: return _select_subsections_list(filter_data.where)
		ObjectVariants.CASH_FLOW: return _select_cash_flows_list(filter_data.where, filter_data.date, filter_data.order)
		ObjectVariants.LOAN: return _select_loans_list(filter_data.where, filter_data.order)
		ObjectVariants.EVENT: return select_multiplied_events_list()
		ObjectVariants.REPORT_W: return _select_wallets_report(filter_data.date)
		ObjectVariants.REPORT_S: return _select_sections_report(filter_data.date)
		ObjectVariants.NOTIFICATION: return _select_notifications_list()
		ObjectVariants.FAST_CREATION: return _select_fast_creations_list()
		ObjectVariants.WALLET_TRANSACTION: return _select_wts_list(filter_data.where)
	return []

# Распределение запросов на обновление элементов списков на страницах
func match_update_list_element(list_element: ObjectVariants, line: Dictionary, parent = null) -> Dictionary:
	match list_element:
		ObjectVariants.WALLET: return _update_wallets_list(line)
		ObjectVariants.SECTION, ObjectVariants.SUBSECTION:	return _update_sections_list(line, parent)
		ObjectVariants.CASH_FLOW: return _update_cash_flows_list(line)
		ObjectVariants.LOAN: return _update_loans_list(line)
		ObjectVariants.EVENT: return _update_events_list(line)
		ObjectVariants.REPORT_W: return _update_reports_list(line)
	return line

# Функции очистки данных
# Изменение значений id в таблице движений средств
func _table_ids_update(table: String = "cash_flows") -> void:
	_create_table("temp_table", "old_id INTEGER")
	db.query("INSERT INTO temp_table (old_id) SELECT ROWID FROM " + table + ";")
	var sel: String = "(SELECT id FROM temp_table WHERE old_id = " + table + ".id)"
	db.query("UPDATE " + table + " SET id = " + sel + " WHERE EXISTS " + sel + ";")
	db.query('UPDATE sqlite_sequence SET seq = (SELECT COUNT(*) FROM ' + table + ') WHERE name = "' + table + '";')
	db.query("DROP TABLE temp_table;")

# Очистка движений средств
func clear_cash_flows() -> void:
	db.query('DELETE FROM cash_flows WHERE CAST(strftime("%Y", "'+Global.date_to_str()+'") AS INTAGER) - CAST(strftime("%Y", date) AS INTAGER) > 2;')
	_table_ids_update()

# Фрагмент запроса получение числового значения фрагмента даты
func _cast_strftime(format: String, date: String) -> String:
	return 'CAST(strftime("%'+format+'", '+date+') AS INTAGER)'

# Фрагмент запроса получения количества месяцев от выбранной даты
func _month_count(date: String = '"'+Global.date_to_str()+'"') -> String:
	return "("+_cast_strftime("Y", date)+" * 12 + "+_cast_strftime("m", date)+")"

# Фрагмент запроса проверки прошло ли два месяца от выбранной даты
func _month_difference() -> String:
	return _month_count()+" - "+_month_count("date")+" > 2"

# Очистка событий
func clear_events() -> void:
	var lines: Array = _select("id FROM events", _month_difference() + " AND repetition_rate = 0")
	for i in lines:
		db.query("DELETE FROM notifications WHERE event_id = " + str(i.id) + ";")
		_table_ids_update("notifications")
	db.query("DELETE FROM events WHERE " + _month_difference() + " AND repetition_rate = 0;")
	_table_ids_update("events")

# Очистка займов
func clear_loans() -> void:
	var values: Array = _select("wallet_2_id AS id FROM cash_flows WHERE wallet_2_id IN (SELECT id FROM loans WHERE total = 0) AND subsection_id = 2 AND" + _month_difference())
	for i in values:
		db.query("DELETE FROM cash_flows WHERE section_id = 2 AND wallet_2_id="+str(i.id)+";")
		db.query("DELETE FROM loans WHERE id = " + str(i.id) + ";")
		db.query("UPDATE loans SET id = id - 1 WHERE id > " + str(i.id) + ";")
		db.query('UPDATE sqlite_sequence SET seq = seq - 1 WHERE name = "loans";')
		db.query("UPDATE cash_flows SET wallet_2_id = wallet_2_id - 1 WHERE wallet_2_id > "+str(i.id)+" AND section_id=2;")
	_table_ids_update()
	
# Работа с уведомлениями
# Запрос на поиск непрочитанных уведомлений
func presence_unread_notifications() -> bool: return _select("COUNT(id) count FROM notifications", "new")[0].count != 0

# Проверка наличия уведомлений за текущую дату
func checking_notifications() -> bool: return len(_select("* FROM notifications", ' date == "'+Global.date_to_str()+'"')) > 0

# Получение списка событий для создания уведомлений
func select_notif_events(date: String) -> Array: return _select("* FROM multiplied_events", ' date <= "'+Global.date_to_str()+'" AND date > "'+date+'" AND strftime("%m", date) = strftime("%m", "'+date+'")')

# Создание уведомления из события
func insert_notifications(line: Dictionary) -> void: insert_record(Tables.NOTIFICATIONS, [line.event_id, true, '"'+line.date+'"'])

# Запрос на получение списка уведомлений
func _select_notifications_list() -> Array: return _select("e.title, n.* FROM notifications n LEFT JOIN events e ON n.event_id=e.id", "", "n.date DESC")

# Удаление пометки о нивизне уведомления
func update_notifications_new() -> void: db.query("UPDATE notifications SET new = 0;")

# Очистка таблицы уведомлений
func clear_notifications() -> void:
	db.query("DELETE FROM notifications")
	db.query('UPDATE sqlite_sequence SET seq = 0 WHERE name = "notifications";')
	
# Последний вход в программу
# Запрос на получение даты последнего входа в программу
func select_last_entry() -> String: return _select("last_entry FROM settings")[0].last_entry

# Изменение даты последнего входа в программу
func update_last_entry() -> void: db.query('UPDATE settings SET last_entry = "'+Global.date_to_str()+'";')

# Быстрое создание записей
# Запрос на получение списка для быстрого создания записей
func _select_fast_creations_list() -> Array: return _select("fc.*, w.title, s.title, s.income FROM fast_creations fc LEFT JOIN sections s ON fc.section_id=s.id LEFT JOIN wallets w ON fc.wallet_id=w.id")

# Запрос на удаление объекта быстрого создания записей
func delete_fast_creation(idx: int) -> void:
	db.query("DELETE FROM fast_creations WHERE id = " + str(idx) + ";")
	db.query("UPDATE fast_creations SET id = id - 1 WHERE id > " + str(idx) + ";")
	db.query('UPDATE sqlite_sequence SET seq = seq - 1 WHERE name = "fast_creations";')

# Проверка наличия достаточного количества кошельков и разделов для создания движений средств
func check_sections_and_wallets() -> bool:
	return _select("COUNT(id) c FROM wallets")[0].c >= 1 and _select("COUNT(id) c FROM sections")[0].c > 2

# Запрос на создание объекта быстрого создания записей
func insert_fast_creation() -> void:
	var subs_id = null if len(_select("* FROM subsections", "parent_id = 3")) == 0 else _select("* FROM subsections", "parent_id = 3")[0].id
	db.query("INSERT INTO `fast_creations` (wallet_id, section_id, subsection_id) VALUES (1, 3,"+str(subs_id)+");")

# Запрос на создание движения средств
func insert_cash_flow(wallet_id: int, section_id: int, subsection_id: Variant, value: String, date: String = Global.date_to_str()) -> void:
	db.query("INSERT INTO `cash_flows` (wallet_id, section_id, subsection_id, value, date) VALUES ("+str(wallet_id)+", "+str(section_id)+", "+str(subsection_id)+", "+value+', "'+date+'");')

# Изменение значения кошелька для объекта быстрого создания записей
func update_fc_wallet(idx: int, wallet_id: int) -> void:
	db.query("UPDATE fast_creations SET wallet_id = "+str(wallet_id)+" WHERE id = "+str(idx)+";")

# Изменение значения раздела для объекта быстрого создания записей
func update_fc_section(idx: int, section_id: int) -> int:
	db.query("UPDATE fast_creations SET section_id = "+str(section_id)+" WHERE id = "+str(idx)+";")
	if len(_select("* FROM subsections", "parent_id="+str(section_id))) == 0: update_fc_subsection(idx, "null")
	else: update_fc_subsection(idx, _select("* FROM subsections", 'title == "__SS4" AND parent_id='+str(section_id))[0].id)
	return int(_select("* FROM fast_creations fc LEFT JOIN sections s ON fc.section_id=s.id", "fc.id = "+str(idx))[0].income)

# Изменение значения подраздела для быстрого создания записей
func update_fc_subsection(idx: int, subsection_id: Variant) -> void:
	db.query("UPDATE fast_creations SET subsection_id = "+str(subsection_id)+" WHERE id = "+str(idx)+";")
	
# Страница информации
# Запрос на получение списка транзакций для выбранного кошелька
func _select_wts_list(where: String) -> Array:
	var idx: String = where.split(")")[0].split("_id = ")[-1]
	return _select("s.id, s.title, COUNT(cf.id) count, SUM(IIF((NOT s.income AND cf.section_id!= 1 AND cf.subsection_id!=1) OR cf.subsection_id = 2 OR (cf.section_id = 1 AND cf.wallet_id = "+idx+"), cf.value * -1, cf.value)) value FROM cash_flows cf LEFT JOIN sections s ON s.id = cf.section_id ", where, "", "cf.section_id")

# Запрос на получение общей информаци об объекте
func select_inf_data(where: String, idx: int, type: Global.Pages) -> Dictionary:
	if where == "": return {}
	var value: Dictionary = {}
	match type:
		Global.Pages.WALLET:
			value = _select("*, value as total FROM wallets", "id = "+str(idx))[0]
			value.merge(_select("coalesce(COUNT(cf.id), 0) count FROM cash_flows cf", where)[0])
			return _update_wallets_list(value)
		Global.Pages.LOAN:
			value = _select("l.*, (SELECT value FROM cash_flows WHERE subsection_id = 1 and wallet_2_id = l.id) value FROM loans l", "l.id = " + str(idx))[0]
			value["percent"] = _select_loan_percent(idx)
			return value
	return select_sections_list("s.id = "+str(idx))[0]

# Получение среднего процента от займа
func _select_loan_percent(idx: int) -> String:
	var summ: float = 0.0
	var result: float = 0.0
	var count: int = 0
	for i in _select("* FROM cash_flows", "section_id=2 AND wallet_2_id = " + str(idx)):
		match i.subsection_id:
			1: summ = i.value
			2: summ -= i.value
			3:
				result += (i.value * 100) / summ
				summ += i.value
				count += 1
	if count == 0: return str(0) + " %"
	return str(int(round(result / count))) + " %"
	
# Запрос на изменение списка займов
func _update_loans_list(line: Dictionary) -> Dictionary:
	line["percent"] = _select_loan_percent(line.id)
	return line

# Получение значений для построения графика займов
func select_loan_graphics(idx: int) -> Array:
	if idx == 0: return []
	return _select("SUM(IIF(subsection_id=2, value*-1, value)) value, date as day FROM cash_flows", "wallet_2_id = " + str(idx) + " AND section_id=2", "", "day")

# Запросы связанные с окнами создания / изменения объектов
# Распределение запросов для получения объектов таблиц
func match_elem(idx: String, obj_type: Global.Pages) -> Dictionary:
	match obj_type:
		Global.Pages.WALLET: return _select_wallet_obj(idx)
		Global.Pages.SECTION: if int(idx) > 2: return _select_section_obj(idx)
		Global.Pages.SUBSECTION: if int(idx) > 3: return _select_subsection_obj(idx)
		Global.Pages.LOAN: return _select_loan_obj(idx)
		Global.Pages.EVENT: return _select_event_obj(idx)
		_: return _select_cash_flow_obj(idx)
	return {}
	
# Запрос на получение объекта таблицы счетов
func _select_wallet_obj(idx: String) -> Dictionary:
	return _select("* FROM wallets", "id = " + idx)[0]

# Запрос на получение объекта таблицы разделов
func _select_section_obj(idx: String) -> Dictionary:
	var value: Dictionary = _select("* FROM sections", "id = " + idx)[0]
	if value.month_limit == -1.0: value.month_limit = 0.0
	return value
	
# Запрос на получение объекта таблицы подразделов
func _select_subsection_obj(idx: String) -> Dictionary:
	var value: Dictionary = _select("* FROM subsections", "id = " + idx)[0]
	if value.title == "__SS4": return {}
	if value.month_limit == -1.0: value.month_limit = 0.0
	return value

# Запрос на получение объекта таблицы движений средств
func _select_cash_flow_obj(idx: String) -> Dictionary:
	return _select("* FROM cash_flows", "id = " + idx)[0]

# Запрос на получение объекта таблицы займов
func _select_loan_obj(idx: String) -> Dictionary:
	if _select("COUNT(id) count FROM cash_flows", "subsection_id IN (2, 3) AND wallet_2_id = " + idx)[0].count > 0: return {}
	return _select("cf.*, l.title FROM cash_flows cf LEFT JOIN loans l ON cf.wallet_2_id=l.id", "subsection_id=1 AND wallet_2_id = " + idx)[0]

# Запрос на получение обекта таблицы событий
func _select_event_obj(idx: String) -> Dictionary:
	idx = str(_select("* FROM multiplied_events", "id = " + idx)[0].event_id)
	return _select("* FROM events", "id = " + idx)[0]
	
# Распределение запросов на удаление объектов таблицы
func match_deleted(idx: String, obj_type: Global.Pages) -> void:
	match obj_type:
		Global.Pages.WALLET: return _delete_wallet_obj(idx)
		Global.Pages.SECTION: return _delete_section_obj(idx)
		Global.Pages.SUBSECTION: return _delete_subsection_obj(idx)
		Global.Pages.CASH_FLOW: return _delete_cash_flow_obj(idx)
		Global.Pages.TRANSFER: return _delete_transfer_obj(idx)
		Global.Pages.PAYMENT: return _delete_payment_obj(idx)
		Global.Pages.PERCENT: return _delete_percent_obj(idx)
		Global.Pages.LOAN: return _delete_loan_obj(idx)
		Global.Pages.EVENT: return _delete_event_obj(idx)

# Запрос на удаление кошелька
func _delete_wallet_obj(idx: String) -> void:
	# Удаление кошелька
	db.query("DELETE FROM wallets WHERE id = "+idx+";")
	db.query("UPDATE wallets SET id = id - 1 WHERE id > " + idx + ";")
	db.query('UPDATE sqlite_sequence SET seq = seq - 1 WHERE name = "wallets";')
	# Удаление данных о движениях средств
	db.query("UPDATE cash_flows SET wallet_id = null WHERE wallet_id = "+idx+" AND subsection_id IN (1, 2);")
	db.query("DELETE FROM cash_flows WHERE wallet_id = "+idx+" OR (wallet_2_id = "+idx+" AND section_id = 1);")
	db.query("UPDATE cash_flows SET wallet_id = wallet_id - 1 WHERE wallet_id > " + idx + ";")
	db.query("UPDATE cash_flows SET wallet_2_id = wallet_2_id - 1 WHERE section_id = 1 AND wallet_2_id > " + idx + ";")
	_table_ids_update("cash_flows")
	# Удаление быстрых созданий записей
	db.query("DELETE FROM fast_creations WHERE wallet_id = "+idx+";")
	db.query("UPDATE fast_creations SET wallet_id = wallet_id - 1 WHERE wallet_id > " + idx + ";")
	_table_ids_update("fast_creations")

# Запрос на удаление раздела
func _delete_section_obj(idx: String) -> void:
	# Удаление раздела
	db.query("DELETE FROM sections WHERE id = "+idx+";")
	db.query("UPDATE sections SET id = id - 1 WHERE id > " + idx + ";")
	db.query('UPDATE sqlite_sequence SET seq = seq - 1 WHERE name = "sections";')
	# Удаление данных о движениях средств
	db.query("DELETE FROM cash_flows WHERE section_id = "+idx+";")
	db.query("UPDATE cash_flows SET section_id = section_id - 1 WHERE section_id > " + idx + ";")
	_table_ids_update("cash_flows")
	# Удаление быстрых созданий записей
	db.query("DELETE FROM fast_creations WHERE section_id = "+idx+";")
	db.query("UPDATE fast_creations SET section_id = section_id - 1 WHERE section_id > " + idx + ";")
	_table_ids_update("fast_creations")
	# Удваление подразделов
	db.query("UPDATE cash_flows SET subsection_id = subsection_id - (SELECT COUNT(s.id) FROM subsections s, cash_flows cf WHERE s.parent_id = "+idx+" AND cf.subsection_id > s.id AND s.id != cf.subsection_id) WHERE section_id != "+idx+";")
	db.query("UPDATE subsections SET parent_id = parent_id - 1 WHERE parent_id > " + idx + ";")
	db.query("DELETE FROM subsections WHERE parent_id = "+idx+";")
	_table_ids_update("subsections")

# Запрос на удаление подраздела
func _delete_subsection_obj(idx: String) -> void:
	var value: Dictionary = _select("* FROM subsections", "id = "+idx)[0]
	# Удаление раздела
	db.query("DELETE FROM subsections WHERE id = "+idx+";")
	db.query("UPDATE subsections SET id = id - 1 WHERE id > " + idx + ";")
	db.query('UPDATE sqlite_sequence SET seq = seq - 1 WHERE name = "subsections";')
	# Удаление данных о движениях средств
	db.query("DELETE FROM cash_flows WHERE subsection_id = "+idx+";")
	db.query("UPDATE cash_flows SET subsection_id = subsection_id - 1 WHERE subsection_id > " + idx + ";")
	_table_ids_update("cash_flows")
	# Удаление быстрых созданий записей
	db.query("DELETE FROM fast_creations WHERE subsection_id = "+idx+";")
	db.query("UPDATE fast_creations SET subsection_id = subsection_id - 1 WHERE subsection_id > " + idx + ";")
	_table_ids_update("fast_creations")
	if len(_select("* FROM subsections", "parent_id = "+str(value.parent_id))) == 1:
		_delete_subsection_obj(str(_select("* FROM subsections", "parent_id = "+str(value.parent_id)+' AND title = "__SS4"')[0].id))

# Запрос на удаление движения средств
func _delete_cash_flow_obj(idx: String) -> void:
	# Отмена транзакции
	var data: Dictionary = _select("cf.*, s.income FROM cash_flows cf LEFT JOIN sections s ON cf.section_id = s.id", "cf.id = "+idx)[0]
	if not data.income: data.value *= -1
	db.query("UPDATE wallets SET value = value - "+str(data.value)+" WHERE id ="+str(data.wallet_id)+";")
	# Удаление движения средств
	db.query("DELETE FROM cash_flows WHERE id = "+idx+";")
	db.query("UPDATE cash_flows SET id = id - 1 WHERE id > " + idx + ";")
	db.query('UPDATE sqlite_sequence SET seq = seq - 1 WHERE name = "cash_flows";')

# Запрос на удаление перевода средств
func _delete_transfer_obj(idx) -> void:
	var data: Dictionary = _select("* FROM cash_flows", "id = "+idx)[0]
	db.query("UPDATE wallets SET value = value + "+str(data.value)+" WHERE id = "+str(data.wallet_id)+";")
	db.query("UPDATE wallets SET value = value - "+str(data.value)+" WHERE id = "+str(data.wallet_2_id)+";")
	db.query("DELETE FROM cash_flows WHERE id = " + idx + ";")

# Запрос на удаление платежа по займу
func _delete_payment_obj(idx: String) -> void:
	var data: Dictionary = _select("* FROM cash_flows", "id = "+idx)[0]
	db.query("UPDATE wallets SET value = value + "+str(data.value)+" WHERE id = "+str(data.wallet_id)+";")
	db.query("UPDATE loans SET total = total + "+str(data.value)+" WHERE id = "+str(data.wallet_2_id)+";")
	db.query("DELETE FROM cash_flows WHERE id = " + idx + ";")
	
# Запрос на удаление процента по займу
func _delete_percent_obj(idx: String) -> void:
	var data: Dictionary = _select("* FROM cash_flows", "id = "+idx)[0]
	db.query("UPDATE loans SET total = total - "+str(data.value)+" WHERE id = "+str(data.wallet_2_id)+";")
	db.query("DELETE FROM cash_flows WHERE id = " + idx + ";")

# Запрос на удаление займа
func _delete_loan_obj(idx: String) -> void:
	# Удаление займа
	db.query("DELETE FROM loans WHERE id = "+idx+";")
	db.query("UPDATE loans SET id = id - 1 WHERE id > " + idx + ";")
	db.query('UPDATE sqlite_sequence SET seq = seq - 1 WHERE name = "loans";')
	# Отмена транзакции
	var values: Dictionary = _select("* FROM cash_flows", "subsection_id=1 AND wallet_2_id = "+idx)[0]
	if values.wallet_id != null: db.query("UPDATE wallets SET value = value - "+str(values.value)+" WHERE id = "+str(values.wallet_id)+";")
	# Удаление движений средств
	db.query("DELETE FROM cash_flows WHERE section_id = 2 AND wallet_2_id = "+idx+";")
	db.query("UPDATE cash_flows SET wallet_2_id = wallet_2_id - 1 WHERE section_id=2 AND wallet_2_id > " + idx + ";")
	_table_ids_update("cash_flows")

# Запрос на удаление события
func _delete_event_obj(idx: String) -> void:
	# Удаление события
	idx = str(_select("* FROM multiplied_events", "id = " + idx)[0].event_id)
	db.query("DELETE FROM events WHERE id = "+idx+";")
	db.query("UPDATE events SET id = id - 1 WHERE id > " + idx + ";")
	db.query('UPDATE sqlite_sequence SET seq = seq - 1 WHERE name = "events";')
	# Удаление уведомлений
	db.query("DELETE FROM notifications WHERE event_id = "+idx+";")
	db.query("UPDATE notifications SET event_id = event_id - 1 WHERE event_id > " + idx + ";")
	_table_ids_update("notifications")

# Распределение запросов на изменение объектов таблицы
func match_updated(idx: String, obj_type: Global.Pages, values: Array) -> void:
	match obj_type:
		Global.Pages.WALLET: return _update_wallet(idx, values)
		Global.Pages.SECTION: return _update_section(idx, values)
		Global.Pages.SUBSECTION: return _update_subsection(idx, values)
		Global.Pages.CASH_FLOW: return _update_cash_flow(idx, values)
		Global.Pages.TRANSFER: return _update_transfer(idx, values)
		Global.Pages.PAYMENT: return _update_payment(idx, values)
		Global.Pages.PERCENT: return _update_percent(idx, values)
		Global.Pages.LOAN: return _update_loan(idx, values)
		Global.Pages.EVENT: return _update_event(idx, values)

# Запрос на изменение кошелька
func _update_wallet(idx: String, values: Array) -> void:
	db.query('UPDATE wallets SET title = "'+values[0]+'", value ='+values[1]+" WHERE id = "+idx+";")

# Запрос на изменение раздела
func _update_section(idx: String, values: Array) -> void:
	if values[1] == "true": values[2] = "-1.0"
	db.query('UPDATE sections SET title = "'+values[0]+'", income ='+values[1]+", month_limit = "+values[2]+" WHERE id = "+idx+";")

# Запрос на изменене подраздела
func _update_subsection(idx, values) -> void:
	if _select("* FROM sections", "id = "+values[1])[0].income == 1: values[2] = "-1.0"
	db.query('UPDATE subsections SET title = "'+values[0]+'", parent_id ='+values[1]+", month_limit = "+values[2]+" WHERE id = "+idx+";")

# Запрос на изменение движения средств
func _update_cash_flow(idx: String, values: Array) -> void:
	var data: Dictionary = _select("cf.*, s.income FROM cash_flows cf LEFT JOIN sections s ON s.id = cf.section_id", "cf.id = "+idx)[0]
	if not data.income: data.value *= -1
	db.query("UPDATE wallets SET value = value - "+str(data.value)+" WHERE id = "+str(data.wallet_id)+";")
	db.query("UPDATE cash_flows SET wallet_id = "+values[0]+", section_id = "+values[1]+", value = "+values[2]+', date = "'+values[3]+'" WHERE id = '+idx+";")
	if not _select("* FROM sections", "id = "+values[1])[0].income: values[2] = str(float(values[2]) * -1)
	db.query("UPDATE wallets SET value = value + "+values[2]+" WHERE id = "+values[0]+";")

# Запрос на изменение перевода средств
func _update_transfer(idx: String, values: Array) -> void:
	var data: Dictionary = _select("* FROM cash_flows", "id = "+idx)[0]
	db.query("UPDATE wallets SET value = value + "+str(data.value)+" WHERE id = "+str(data.wallet_id)+";")
	db.query("UPDATE wallets SET value = value - "+str(data.value)+" WHERE id = "+str(data.wallet_2_id)+";")
	db.query("UPDATE cash_flows SET wallet_id = "+values[0]+", wallet_2_id = "+values[1]+", value = "+values[2]+', date = "'+values[3]+'" WHERE id = '+idx+";")
	db.query("UPDATE wallets SET value = value - "+values[2]+" WHERE id = "+values[0]+";")
	db.query("UPDATE wallets SET value = value + "+values[2]+" WHERE id = "+values[1]+";")

# Запрос на изменение погашения займа
func _update_payment(idx: String, values: Array) -> void:
	var data: Dictionary = _select("* FROM cash_flows", "id = "+idx)[0]
	db.query("UPDATE wallets SET value = value + "+str(data.value)+" WHERE id = "+str(data.wallet_id)+";")
	db.query("UPDATE loans SET total = total + "+str(data.value)+" WHERE id = "+str(data.wallet_2_id)+";")
	db.query("UPDATE cash_flows SET wallet_id = "+values[0]+", wallet_2_id = "+values[1]+", value = "+values[2]+', date = "'+values[3]+'" WHERE id = '+idx+";")
	db.query("UPDATE wallets SET value = value - "+values[2]+" WHERE id = "+values[0]+";")
	db.query("UPDATE loans SET total = total - "+values[2]+" WHERE id = "+values[1]+";")

# Запрос на изменение процента по займу
func _update_percent(idx: String, values: Array) -> void:
	var data: Dictionary = _select("* FROM cash_flows", "id = "+idx)[0]
	db.query("UPDATE loans SET total = total - "+str(data.value)+" WHERE id = "+str(data.wallet_2_id)+";")
	db.query("UPDATE cash_flows SET wallet_2_id = "+values[0]+", value = "+values[1]+', date = "'+values[2]+'" WHERE id = '+idx+";")
	db.query("UPDATE loans SET total = total + "+values[1]+" WHERE id = "+values[0]+";")

# Запрос на изменение раздела
func _update_loan(idx: String, values: Array) -> void:
	db.query('UPDATE loans SET title = "'+values[0]+'", total = '+values[2]+" WHERE id = "+idx+";")
	var last_value: Dictionary = _select("* FROM cash_flows", "subsection_id=1 AND wallet_2_id = "+idx)[0]
	db.query("UPDATE wallets SET value = value - "+str(last_value.value)+" WHERE id = "+str(last_value.wallet_id)+";")
	db.query("UPDATE wallets SET value = value + "+values[2]+" WHERE id = "+values[1]+";")
	db.query("UPDATE cash_flows SET wallet_id = "+values[1]+", value = "+values[2]+', date = "'+values[3]+'" WHERE subsection_id=1 AND wallet_2_id = '+idx+";")

# Запрос на изменение раздела
func _update_event(idx: String, values: Array) -> void:
	if int(values[2]) == 0: values[3] = "0.0"
	idx = str(_select("* FROM multiplied_events", "id = " + idx)[0].event_id)
	db.query('UPDATE events SET title = "'+values[0]+'", repetition_rate ='+str(values[1])+", event_type = "+str(values[2])+", value = "+values[3]+', date ="'+values[4]+'" WHERE id = '+idx+";")

# Распределение запросов на создание объектов таблицы
func match_created(obj_type: Global.Pages, values: Array) -> void:
	match obj_type:
		Global.Pages.WALLET: return _create_wallet(values)
		Global.Pages.SECTION: return _create_section(values)
		Global.Pages.SUBSECTION: return _create_subsection(values)
		Global.Pages.CASH_FLOW: return _create_cash_flow(values)
		Global.Pages.TRANSFER: return _create_transfer(values)
		Global.Pages.PAYMENT: return _create_payment(values)
		Global.Pages.PERCENT: return _create_percent(values)
		Global.Pages.LOAN: return _create_loan(values)
		Global.Pages.EVENT: return _create_event(values)

# Запрос на создание кошелька
func _create_wallet(values: Array) -> void:
	db.query("INSERT INTO wallets (title, value) VALUES ("+values[0]+", "+values[1]+");")
	
# Запрос на создание раздела
func _create_section(values: Array) -> void:
	if values[1] == "true": values[2] = "-1.0"
	db.query("INSERT INTO sections (title, income, month_limit) VALUES ("+values[0]+", "+values[1]+", "+values[2]+");")

# Запрос на создание подраздела
func _create_subsection(values: Array) -> void:
	if _select("* FROM sections", "id = "+values[1])[0].income == 1: values[2] = "-1.0"
	if len(_select("* FROM subsections", "parent_id = "+values[1])) == 0:
		db.query('INSERT INTO subsections (title, parent_id, month_limit) VALUES ("__SS4", '+values[1]+", -1);")
	db.query("INSERT INTO subsections (title, parent_id, month_limit) VALUES ("+values[0]+", "+values[1]+", "+values[2]+");")

# Запрос на создание движения средств
func _create_cash_flow(values: Array) -> void:
	db.query("INSERT INTO cash_flows (wallet_id, section_id, value, date) VALUES ("+values[0]+", "+values[1]+", "+values[2]+", "+values[3]+");")
	if not _select("* FROM sections", "id = "+values[1])[0].income: values[2] = str(float(values[2]) * -1)
	db.query("UPDATE wallets SET value = value + "+values[2]+" WHERE id = "+values[0])

# Запрос на создание перевода средств
func _create_transfer(values: Array) -> void:
	db.query("INSERT INTO cash_flows (section_id, wallet_id, wallet_2_id, value, date) VALUES (1, "+values[0]+", "+values[1]+", "+values[2]+", "+values[3]+");")
	db.query("UPDATE wallets SET value = value - "+values[2]+" WHERE id = "+values[0])
	db.query("UPDATE wallets SET value = value + "+values[2]+" WHERE id = "+values[1])

# Запрос на создание платежей по займу
func _create_payment(values: Array) -> void:
	db.query("INSERT INTO cash_flows (section_id, wallet_id, wallet_2_id, value, date) VALUES (3, "+values[0]+", "+values[1]+", "+values[2]+", "+values[3]+");")
	db.query("UPDATE wallets SET value = value - "+values[2]+" WHERE id = "+values[0])
	db.query("UPDATE loans SET total = total - "+values[2]+" WHERE id = "+values[1])

# Запрос на создание процентов по займу
func _create_percent(values: Array) -> void:
	db.query("INSERT INTO cash_flows (section_id, wallet_2_id, value, date) VALUES (4, "+values[0]+", "+values[1]+", "+values[2]+");")
	db.query("UPDATE loans SET total = total + "+values[1]+" WHERE id = "+values[0])

# Запрос на создание займа
func _create_loan(values: Array) -> void:
	db.query('INSERT INTO loans (title, total) VALUES ("'+values[0]+'", '+values[2]+");")
	var loan_id: int = _select("* FROM loans")[-1].id
	db.query("INSERT INTO cash_flows (wallet_id, wallet_2_id, section_id, value, date) VALUES ("+values[1]+", "+str(loan_id)+", 2, "+values[2]+", "+values[3]+");")
	db.query("UPDATE wallets SET value = value + " + values[2] + " WHERE id = " + values[1] + ";")

# Запрос на создание события
func _create_event(values: Array) -> void:
	if int(values[2]) == 0: values[3] = "0.0"
	db.query("INSERT INTO events (title, repetition_rate, event_type, value, date) VALUES ("+values[0]+", "+str(values[1])+", "+str(values[2])+", "+values[3]+", "+values[4]+");")

# Проверка наличия записи с определенным имененем в таблице кошельков
func check_wallet_name(obj_name: String, idx: int) -> bool:
	return len(_select("* FROM wallets", 'title = "' + obj_name + '" AND id != ' + str(idx))) == 0

# Проверка наличия записи с определенным имененем в таблице разделов
func check_section_name(obj_name: String, idx: int) -> bool:
	return len(_select("* FROM sections", 'title = "' + obj_name + '" AND id != ' + str(idx))) == 0

# Проверка наличия подстатьи с определенным имененем в таблице раделов
func check_subsection_name(obj_name: String, idx: int, parent_id: int) -> bool:
	return len(_select("* FROM subsections", 'title = "' + obj_name + '" AND id != ' + str(idx)+" AND parent_id = "+str(parent_id))) == 0

# Получение суммы займа до выбранной даты
func get_loan_total(idx: int, w2idx: int, date: String) -> float:
	if not db: return 0.0
	var value: Variant = _select("SUM(IIF(subsection_id == 2, value * -1, value)) total FROM cash_flows",
		'section_id=2 AND date <= "'+date+'" AND (date != "'+date+'" OR id != '+str(idx)+") AND wallet_2_id = "+str(w2idx))[0].total
	return 0.0 if value == null else value
	
# Проверка минимальной даты от которой можно провести транзакции по займам
func loan_check_first_date(idx: int, date: String) -> bool:
	db.query('SELECT "'+date+'" < (SELECT date FROM cash_flows WHERE subsection_id=1 AND wallet_2_id = '+str(idx)+") res;")
	return bool(db.query_result[0].res)
