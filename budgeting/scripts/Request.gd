extends Node
# Перечисление
enum Tables {WALLETS, SECTIONS, CASH_FLOWS, LOANS, EVENTS, SETTINGS, NOTIFICATIONS, SQLITE_SEQUENCE, USERS} # Таблицы в базе данных
enum ObjectVariants {WALLET, SECTION, CASH_FLOW, LOAN, EVENT, REPORT, NOTIFICATION, WALLET_TRANSACTION} # Варианты списков объектов по которым могут быть запросы

# Переменная
var db: SQLite = null # Подключенная база данных
# Для заполнения таблицы событий
var events: Array = [] # Список событий для постепенного увеличения их количества
var completion_creation_et: bool = false # Маркер завершения заполнения таблицы событий
@onready var selected_date: NewDate = NewDate.new(Time.get_datetime_string_from_system()) # Выбранная дата
var next_month: Dictionary = {} # Следующий месяц
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
	_create_table("cash_flows", "wallet_id INT, wallet_2_id INT, section_id INT, value FLOAT, date DATE, note VARCHAR(255)", ["(`wallet_id`) REFERENCES `wallets`(`id`)", "(`section_id`) REFERENCES `sections`(`id`)"])
	_create_table("loans", "title VARCHAR(255), total FLOAT, date DATE")
	_create_table("events", "title VARCHAR(255), event_type INT, value FLOAT, repetition_rate INT, date DATE, note VARCHAR(255)")
	_create_table("multiplied_events", "title VARCHAR(255), event_type INT, value FLOAT, date DATE, note VARCHAR(255), completed BOOLEAN, event_id INT")
	# Создание таблиц для персонализации приложения
	_create_table("settings", "color_preset BOOLEAN, color_scheme INT, color_1 VARCHAR(255), color_2 VARCHAR(255), color_3 VARCHAR(255), color_4 VARCHAR(255), dark_theme BOOLEAN, event_page_calendar BOOLEAN, last_entry DATE")
	_create_table("notifications", "event_id INT, new BOOL, date DATE", ["(`event_id`) REFERENCES `events`(`id`)"])
	if len(select(Tables.SECTIONS)) != 0: return
	for i in ["__ST1", "__ST2", "__ST3", "__ST4"]: insert_record(Tables.SECTIONS, ['"'+i+'"', -1, false])

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
	value["value"] = select(Tables.CASH_FLOWS, "*", "section_id=2 AND wallet_2_id="+str(id))[0].value
	value["percents"] = str(select_loan_percent(id)) + "%"
	return value

# Получение кошелька по индексу
func select_wallet(id: int) -> Array: return select(Tables.WALLETS, "*", "id="+str(id))

# Получение раздела по индексу
func select_section(id: int) -> Array: return select(Tables.SECTIONS, "*", "id="+str(id))

# Получение займа по индексу
func select_loan(id: int) -> Array: return select("cash_flows cf", "cf.*, l.title", "section_id=2 AND wallet_2_id="+str(id), "", "loans l ON l.id=wallet_2_id")

# Получение события по индексу
func select_event(id: int) -> Array:
	var results: Array = select(Tables.EVENTS, "*", "id="+str(id))
	for i in range(len(results)): results[i].repetition_rate += 1
	return results

# Получение среднего процента по займу при учете процесса погашения займа
func select_loan_percent(id: int) -> int:
	var summ: float = 0.0
	var percents: Array = []
	for i in _select("* FROM cash_flows", "section_id IN (2, 3, 4) AND wallet_2_id="+str(id), "date"):
		match i.section_id:
			2: summ = i.value
			3: summ -= i.value
			4:
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
				if selected_date.date.day != 1 and Global.date_comparison(next_month, new_date, "==", false): _insert_event(value, new_date)
			3, 4:
				_insert_events_to_repetition_rate_3_4(value, new_date, selected_date.date)
				if selected_date.date.day != 1: _insert_events_to_repetition_rate_3_4(value, new_date, next_month)

# Получение данных из таблиц
func _select(req_text: String, where: String = "", order: String = "", group: String = "") -> Array:
	if where: where = " WHERE " + where
	if order: order = " ORDER BY " + order
	if group: group = " GROUP BY " + group
	db.query("SELECT " + req_text + where + order + group + ";")
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
	return "COALESCE(SUM(CASE WHEN cf.section_id IN (1, 4) THEN 0 WHEN cf.section_id = 3 OR (s.income = 0 AND s.month_limit<>-1) THEN cf.value * -1 ELSE cf.value END),0.0) value
		FROM cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id"

# Получить сумму движений средств за время до выбранной даты
func select_past_funds_movements(date: String = Global.date_to_str()) -> float:
	return _select(_funds_movements_text(), where_date(date, "date", "<"))[0].value

# Получение движения средств
func select_funds_movements() -> float: return _select(_funds_movements_text(), where_date())[0].value

# Запрос на получение списка кошельков
func _select_wallets_list(where: String, order: String) -> Array:
	return _select("*, (SELECT cf.date FROM cash_flows cf WHERE (cf.section_id NOT IN (2, 3, 4)
		AND cf.wallet_2_id=w.id) OR cf.wallet_id=w.id ORDER BY cf.date DESC) last_date FROM wallets w",where,order)

# Запрос на изменение списка кошельков
func _update_wallets_list(line: Dictionary, date: String = Global.date_to_str()) -> Dictionary:
	var value: Array = _select("SUM(IIF((cf.section_id=1 and cf.wallet_id="+str(line.id)+")OR cf.section_id=3 OR (s.income=0 and cf.section_id>4 and cf.wallet_id="+str(line.id)+"), cf.value*-1, cf.value)) value
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

# Запрос на получение списка движений средств
func _select_cash_flows_list(where: String = "", date: String = Global.date_to_str(), order: String = "") -> Array:
	if where: where = " AND "+where
	return _select("cf.*, s.title, w.title wallet_title FROM `cash_flows` cf LEFT JOIN sections s ON cf.section_id=s.id
		LEFT JOIN wallets w ON cf.wallet_id=w.id", where_date(date)+where, order)

# Запрос на изменение списка разделов
func _update_cash_flows_list(line: Dictionary) -> Dictionary:
	match line.section_id:
		1: line["wallet_2_title"] = _select_title(Tables.WALLETS, line.wallet_2_id)
		3: line["wallet_2_title"] = _select_title(Tables.LOANS, line.wallet_2_id)
		4: line["wallet_title"] = _select_title(Tables.LOANS, line.wallet_2_id)
		2:
			line["wallet_2_title"] = line.wallet_title
			line.wallet_title = _select_title(Tables.LOANS, line.wallet_2_id)
			var save_id: int = line.wallet_id
			line.wallet_id = line.wallet_2_id
			line.wallet_2_id = save_id
	return line
	
# Получение суммы движений средств распределенных по дням
func select_cash_flow_graphics(where: String, date: String = Global.date_to_str()) -> Array:
	if where: where = " AND " + where
	return _select("SUM(CASE WHEN cf.section_id IN (1, 4) THEN 0 WHEN cf.section_id = 3 OR (s.income = 0 AND s.month_limit<>-1)  THEN cf.value * -1 ELSE cf.value END) value,
		strftime('%d', cf.date) day FROM cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id ", where_date(date)+where, "", "cf.date")

# Получение списка займов
func _select_loans_list(where: String = "", order: String = "") -> Array:
	return _select("l.*, cf.wallet_id, w.title wallet_title, cf.value FROM loans l LEFT JOIN cash_flows cf ON cf.section_id=2 AND cf.wallet_2_id=l.id LEFT JOIN wallets w ON cf.wallet_id=w.id", where, order)

# Добавление событий во временную таблицу
func _insert_event(value: Dictionary, date: Dictionary) -> void:
	var text_date: String = Global.date_to_str(date).split(" ")[0]
	insert_record("multiplied_events", ["'"+value.title+"'", value.event_type, value.value, "'"+text_date+"'", "'"+value.note+"'", Global.date_comparison(Global.get_date(), date, ">"), value.id])

# Добавление событий во временную таблицу с выбранным шагом
func _insert_events_with_step(value: Dictionary, new_date: Dictionary, day_count: int, step: int) -> void:
	var two_week: int = 0
	if selected_date.date.day != 1 and new_date.month != next_month.month: two_week = 14
	while new_date.day <= day_count + two_week:
		var date_dup: Dictionary = new_date.duplicate()
		if new_date.day > day_count:
			date_dup = next_month.duplicate()
			date_dup.day = new_date.day - day_count
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
	next_month = Global.get_other_month(selected_date.date, true)
	last_month_day_count = select_day_count(Global.get_other_month(date))
	events = _select_events_list(date, date if selected_date.date.day < selected_date.day_count - 14 else Global.date_to_str(next_month))
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
		COALESCE((SELECT SUM(cf.value) FROM cash_flows cf LEFT JOIN sections s on cf.section_id=s.id WHERE ((cf.wallet_id=w.id AND (s.income=1 OR cf.section_id=2)) OR (cf.section_id=1 AND cf.wallet_2_id=w.id)) AND "+where_date(date, "cf.date")+"), 0.0) income,
		COALESCE((SELECT SUM(cf.value) FROM cash_flows cf LEFT JOIN sections s on cf.section_id=s.id WHERE ((cf.wallet_id=w.id AND s.income=0 AND cf.section_id>4) OR (cf.section_id=1 AND cf.wallet_id=w.id) OR cf.section_id=3) AND "+where_date(date, "cf.date")+"), 0.0) expenditure,
		COALESCE((SELECT SUM(IIF((cf.section_id=1 and cf.wallet_id=w.id)OR cf.section_id=3 OR (s.income=0 and cf.section_id>4 and cf.wallet_id=w.id), cf.value*-1, cf.value)) FROM cash_flows cf LEFT JOIN sections s on cf.section_id=s.id WHERE (cf.wallet_id=w.id or (cf.wallet_2_id=w.id and cf.section_id=1)) AND "+where_date(date, "cf.date", "<")+"), 0.0) cash_flow
		FROM wallets w")

# Запрос на получение списка отчета по разделам
func _select_sections_report(date: String = Global.date_to_str()) -> Array:
	return _select("t.id, t.title,
		COALESCE((SELECT SUM(cf.value) FROM cash_flows cf LEFT JOIN sections s on cf.section_id=s.id WHERE (s.income=1 OR cf.section_id=2) AND cf.section_id=t.id AND "+where_date(date, "cf.date")+"), 0.0) income,
		COALESCE((SELECT SUM(cf.value) FROM cash_flows cf LEFT JOIN sections s on cf.section_id=s.id WHERE s.income=0 AND (cf.section_id>4 OR cf.section_id=3) AND cf.section_id=t.id AND "+where_date(date, "cf.date")+"), 0.0) expenditure,
		COALESCE((SELECT SUM(IIF((s.income=0 AND (cf.section_id>4 OR cf.section_id=3)), cf.value*-1, cf.value)) FROM cash_flows cf LEFT JOIN sections s on cf.section_id=s.id WHERE cf.section_id=t.id AND "+where_date(date, "cf.date", "<")+"), 0.0) cash_flow
		FROM sections t WHERE t.id NOT IN (1, 4)")

# Запрос на получение списка отчета
func _select_reports_list(table: String = "wallets", date: String = Global.date_to_str()):
	if table == "wallets": return _select_wallets_report(date)
	return _select_sections_report(date)
	
# Запрос на изменение списка отчета
func _update_reports_list(line: Dictionary) -> Dictionary:
	line["value"] = line.cash_flow + line.income - line.expenditure
	return line

# Распределение запросов для заполнения списков на страницах
func match_select(list_element: ObjectVariants, filter_data: Dictionary) -> Array:
	match list_element:
		ObjectVariants.WALLET: return _select_wallets_list(filter_data.where, filter_data.order)
		ObjectVariants.SECTION: return select_sections_list(filter_data.where, filter_data.date, filter_data.order)
		ObjectVariants.CASH_FLOW: return _select_cash_flows_list(filter_data.where, filter_data.date, filter_data.order)
		ObjectVariants.LOAN: return _select_loans_list(filter_data.where, filter_data.order)
		ObjectVariants.EVENT: return select_multiplied_events_list()
		ObjectVariants.REPORT: return _select_reports_list(filter_data.where, filter_data.date)
		ObjectVariants.NOTIFICATION: return _select_notifications_list()
	return []

# Распределение запросов на обновление элементов списков на страницах
func match_update_list_element(list_element: ObjectVariants, line: Dictionary, parent = null) -> Dictionary:
	match list_element:
		ObjectVariants.WALLET: return _update_wallets_list(line)
		ObjectVariants.SECTION:	return _update_sections_list(line, parent)
		ObjectVariants.CASH_FLOW: return _update_cash_flows_list(line)
		ObjectVariants.EVENT: return _update_events_list(line)
		ObjectVariants.REPORT: return _update_reports_list(line)
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
	var values: Array = _select("wallet_2_id AS id FROM cash_flows WHERE wallet_2_id IN (SELECT id FROM loans WHERE total = 0) AND section_id = 3 AND" + _month_difference())
	for i in values:
		db.query("DELETE FROM cash_flows WHERE section_id IN (2, 3, 4) AND wallet_2_id="+str(i.id)+";")
		db.query("DELETE FROM loans WHERE id = " + str(i.id) + ";")
		db.query("UPDATE loans SET id = id - 1 WHERE id > " + str(i.id) + ";")
		db.query('UPDATE sqlite_sequence SET seq = seq - 1 WHERE name = "loans";')
		db.query("UPDATE cash_flows SET wallet_2_id = wallet_2_id - 1 WHERE wallet_2_id > "+str(i.id)+" AND section_id IN (2, 3, 4);")
	_table_ids_update()
	
# Работа с уведомлениями
# Запрос на поиск непрочитанных уведомлений
func presence_unread_notifications() -> bool: return _select("COUNT(id) count FROM notifications", "new")[0].count != 0

# Проверка наличия уведомлений за текущую дату
func checking_notifications() -> bool: return len(_select("* FROM notifications", ' date == "'+Global.date_to_str()+'"')) > 0

# Получение списка событий для создания уведомлений
func select_notif_events() -> Array: return _select("* FROM multiplied_events", ' date == "'+Global.date_to_str()+'"')

# Создание уведомления из события
func insert_notifications(line: Dictionary) -> void: insert_record(Tables.NOTIFICATIONS, [line.id, true, '"'+line.date+'"'])

# Запрос на получение списка уведомлений
func _select_notifications_list() -> Array: return _select("e.title, n.* FROM notifications n LEFT JOIN events e ON n.event_id=e.id", "", "n.date DESC")

# Удаление пометки о нивизне уведомления
func update_notifications_new() -> void: db.query("UPDATE notifications SET new = 0;")

# Очистка таблицы уведомлений
func clear_notifications() -> void:
	db.query("DELETE FROM notifications")
	db.query('UPDATE sqlite_sequence SET seq = 0 WHERE name = "notifications";')
