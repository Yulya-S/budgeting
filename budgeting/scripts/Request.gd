extends Node
# Перечисление
enum Tables {WALLETS, SECTIONS, CASH_FLOWS, LOANS, EVENTS, SETTINGS, SQLITE_SEQUENCE, USERS} # Таблицы в базе данных
enum ObjectVariants {WALLET, SECTION, CASH_FLOW, LOAN, EVENT, WALLET_TRANSACTION} # Варианты списков объектов по которым могут быть запросы

# Переменная
var db: SQLite = null # Подключенная база данных

# Создание и подключение базы данных
func _ready() -> void: connection_user_db()

# Подключение базы данных пользователей
func connection_user_db() -> void:
	db = SQLite.new()
	db.path = File.BasesPath + "users.db"
	db.open_db()
	# Создание таблицы в базе данных пользователей
	_create_table("users", "login VARCHAR(255), password VARCHAR(255), base VARCHAR(255)")

# Подключение базы данных
func connection_db(db_name: String) -> void:
	db = SQLite.new()
	db.path =  File.BasesPath + db_name + ".db"
	db.open_db()
	create_tables()

# Запрос на создание таблицы
func _create_table(title: String, columns: String, other: String = "") -> void:
	if other: other = ", " + other
	db.query("CREATE TABLE IF NOT EXISTS "+title+" (id INTEGER PRIMARY KEY AUTOINCREMENT, "+columns+other+");")

# Создание таблиц в базе
func create_tables() -> void:
	# Создание основных таблиц
	_create_table("wallets", "title VARCHAR(255), value FLOAT")
	_create_table("sections", "title VARCHAR(255), month_limit FLOAT, income BOOLEAN")
	_create_table("cash_flows", "wallet_id INT, wallet_2_id INT, section_id INT, value FLOAT, date DATE, note VARCHAR(255)", "FOREIGN KEY (`wallet_id`) REFERENCES `wallets`(`id`), FOREIGN KEY (`section_id`) REFERENCES `sections`(`id`)")
	_create_table("loans", "title VARCHAR(255), total FLOAT, date DATE")
	_create_table("events", "title VARCHAR(255), event_type INT, value FLOAT, repetition_rate INT, date DATE, note VARCHAR(255)")
	_create_table("multiplied_events", "title VARCHAR(255), event_type INT, value FLOAT, date DATE, note VARCHAR(255), completed BOOLEAN, event_id INT")
	# Создание таблиц для персонализации приложения
	_create_table("settings", "color_preset BOOLEAN, color_scheme INT, color_1 VARCHAR(255), color_2 VARCHAR(255), color_3 VARCHAR(255), color_4 VARCHAR(255), dark_theme BOOLEAN, event_page_calendar BOOLEAN, last_entry DATE")
	_create_table("notifications", "title INT, event_id INT, new BOOL", "FOREIGN KEY (`event_id`) REFERENCES `events`(`id`)")
	if len(select(Tables.SECTIONS)) != 0: return
	for i in ["Переводы", "Заём", "Платежи по займам", "Проценты по займу"]: insert_record(Tables.SECTIONS, ['"'+i+'"', -1, false])
	
# Получить название таблицы из enum Tables
func _get_table_name(table) -> String:
	if table is String: return table
	return Global.enum_key(Tables, table)

# Получить названия колонок
func _get_columns(table) -> Array:
	db.query("PRAGMA table_info(`"+_get_table_name(table)+"`)")
	var result: Array = []
	for i in db.query_result: result.append(i.name)
	result.pop_front()
	return result
	
# Добавление фрагмента текста в запрос
func add_part_request(text: String, column: String, value, operator: String = "=", sep: String = " AND ") -> String:
	if text: text += sep 
	if operator == "LIKE": value = '"%' + str(value) + '%"'
	text += column + " " + operator + " " + str(value)
	return text
	
# Добавление фрагмента текста в запрос с проверкой что значение не null
func add_part_request_with_check(text: String, column: String, value, operator: String = "=", sep: String = " AND ") -> String:
	if not value: return text
	return add_part_request(text, column, value, operator, sep)

# Отправка запроса на создание записи таблице
func insert(table, columns: Array, values: Array) -> void:
	if table is Tables: table = _get_table_name(table)
	db.query("INSERT INTO `"+_get_table_name(table)+"` ("+",".join(columns)+") VALUES ("+",".join(values)+");")

# Добавление записи
func insert_record(table, values: Array) -> void:
	insert(table, _get_columns(table), values)

# Отправка запроса на изменение записей в таблице
func update(table, values: String, where: String) -> void:
	db.query("UPDATE `"+_get_table_name(table)+"` SET "+values+" WHERE "+where + ";")

# Изменение записи
func update_record(table, id: int, values: Array) -> void:
	var request_text: String = ""
	var columns: Array = _get_columns(table)
	for i in len(values): request_text = add_part_request(request_text, columns[i], values[i], "=", ", ")
	update(table, request_text, "id=" + str(id))

# Отправка запроса на удаление записи в таблице
func delete(table, id: int) -> void:
	db.query("DELETE FROM `"+_get_table_name(table)+"` WHERE id="+str(id)+";")
	update(Tables.SQLITE_SEQUENCE, "seq=seq-1", 'name="'+_get_table_name(table)+'"')
	update(table, "id=id-1", "id>"+str(id))

# Сборка даты
func where_date(date: String = Global.date_to_str(), column: String = "date") -> String:
	return "strftime('%Y-%m', "+column+") = strftime('%Y-%m', '"+date+"')"

# Получение данных из таблиц
func select(table, columns: String = "*", where: String = "", order: String = "", left: String = "") -> Array:
	if where: where = " WHERE "+where
	if order: order = " ORDER BY "+order
	if left: left = " LEFT JOIN "+left
	db.query("SELECT "+columns+" FROM "+_get_table_name(table)+left+where+order+";")
	return db.query_result

# Проверка достаточно ли данных в базе для создания движения средств
func select_possibility_opening_cashFlow() -> bool:
	return len(select(Tables.WALLETS)) != 0 and len(select(Tables.SECTIONS)) > 4

# Проверка достаточно ли данных в базе для создания платежа и добавления процентов по займу
func select_possibility_opening_payment() -> bool:
	return len(select(Tables.WALLETS)) != 0 and len(select(Tables.LOANS, "*", "total>0")) != 0

# Получение текущего суммарного бюджета
func select_budget() -> float:
	var wallets_sum: float = select(Tables.WALLETS, "COALESCE(SUM(value), 0) value")[0].value
	return wallets_sum - (select(Tables.LOANS, "COALESCE(SUM(total), 0) value")[0].value)
	
# Получение движенения средств суммарно для всех кошельков
func select_general_wallets_movement() -> float:
	var sum: float = 0.0
	for i in select(Tables.WALLETS, "id"): sum += select_wallets_movement(i.id)[0]
	return sum
	
# Получение названия объекта под определенным индексом
func _select_title(table: Tables, id: int) -> String: return select(table, "title", "id="+str(id))[0].title

# Получение списка движений средств
func select_cash_flows(where: String = "", date: String = Global.date_to_str(), order: String = "") -> Array:
	if date != "":
		if where != "": where += " AND " + where_date(date)
		else: where = where_date(date)
	var values: Array = select("`cash_flows` cf", "cf.*, s.title, w.title wallet_title", where, order, "sections s ON cf.section_id=s.id LEFT JOIN wallets w ON cf.wallet_id=w.id")
	for i in range(len(values)):
		match values[i].section_id:
			1: values[i]["wallet_2_title"] = _select_title(Tables.WALLETS, values[i].wallet_2_id)
			2:
				values[i]["wallet_2_title"] = values[i].wallet_title
				values[i].wallet_title = _select_title(Tables.LOANS, values[i].wallet_2_id)
				var save_id: int = values[i].wallet_id
				values[i].wallet_id = values[i].wallet_2_id
				values[i].wallet_2_id = save_id
			3, 4: values[i]["wallet_2_title"] = _select_title(Tables.LOANS, values[i].wallet_2_id)
	return values

# Получение суммы движений средств распределенных по дням
func select_daily_transactions(where: String, date: String = Global.date_to_str()) -> Array:
	if where != "": where = " WHERE " + where
	db.query("""SELECT COALESCE(SUM(value), 0) value, strftime('%d', date) day FROM (SELECT cf.date, CASE WHEN cf.section_id IN (1, 4) THEN 0
		WHEN cf.section_id = 3 THEN cf.value * -1 WHEN s.income = 0 AND s.month_limit<>-1 THEN cf.value * -1 ELSE cf.value END value FROM cash_flows cf
		LEFT JOIN sections s ON cf.section_id=s.id"""+where+") WHERE "+where_date(date)+" GROUP BY date")
	return db.query_result
	
# Получение списка займов
func select_loan_list(where: String = "", order: String = "") -> Array:
	if where != "": where = " WHERE " + where
	if order != "": order = " ORDER BY " + order
	db.query("SELECT l.*, cf.wallet_id, w.title wallet_title, cf.value FROM loans l LEFT JOIN cash_flows cf ON cf.section_id=2 AND cf.wallet_2_id=l.id LEFT JOIN wallets w ON cf.wallet_id=w.id"+where+order+";")
	return db.query_result

# Получение количества дней в текущем месяце
func select_day_count(date: String) -> int:
	if not db: return 30
	db.query("SELECT STRFTIME('%d', DATE('"+date+"', 'start of month', '+1 month', '-1 day')) day_count")
	return int(db.query_result[0].day_count)

# Получение событий в текущем месяце с датой первого появления
func select_monthly_events(date: String) -> Array:
	var query_fragment: String = "(julianday(Date('"+date+"'))-julianday(date))"
	db.query("SELECT *, Date(julianday(date)+CASE "+\
		"WHEN "+query_fragment+"<0 THEN 0 "+\
		"WHEN repetition_rate=1 THEN IIF("+query_fragment+"%2==0, "+query_fragment+", "+query_fragment+"+1) "+\
		"WHEN repetition_rate=2 THEN IIF("+query_fragment+"%7==0, "+query_fragment+", "+query_fragment+"+(7-"+query_fragment+"%7)) "+\
		"ELSE 0 END) new_date FROM events WHERE strftime('%Y-%m', date)<=strftime('%Y-%m', Date('"+date+"'));")
	return db.query_result

# Добавление событий во временную таблицу
func insert_event(value: Dictionary, date, completed: bool) -> void:
	if date is Dictionary: date = Global.date_to_str(date).split(" ")[0]
	insert_record("temporary", ["'"+value.title+"'", "'"+date+"'", "'"+value.note+"'", completed, value.id])

# Добавление событий во временную таблицу с выбранным шагом
func insert_events_with_step(value: Dictionary, new_date: Dictionary, current_date: Dictionary, day_count: int, step: int) -> void:
	while new_date.day <= day_count:
		insert_event(value, new_date, Global.date_comparison(current_date, new_date, ">"))
		new_date.day += step

# Получение списка событий
func select_events(date: String) -> Array:
	# подготовка данных о месяце для формирования событий
	var current_date: Dictionary = Global.date
	var selected_date: Dictionary = Global.date_to_dict(date)
	var current_month_day_count: int = select_day_count(date)
	var last_month_day_count: int = select_day_count(Global.date_to_str(Global.get_other_month(selected_date, false)))
	var values: Array = select_monthly_events(date) # Получение первоначальных данных для временной таблицы
	# Заполнение временной таблицы
	_create_table("temporary", "title VARCHAR(255), date DATE, note VARCHAR(255), completed BOOLEAN, event_id INT")
	for i in values:
		var new_date: Dictionary = Global.date_to_dict(i.new_date)
		match i.repetition_rate:
			0: if Global.date_comparison(selected_date, new_date, "==", false): insert_event(i, i.new_date, Global.date_comparison(current_date, new_date, ">"))
			1: insert_events_with_step(i, new_date, current_date, current_month_day_count, 2)
			2: insert_events_with_step(i, new_date, current_date, current_month_day_count, 7)
			3, 4:
				new_date.year = selected_date.year
				if i.repetition_rate == 3: new_date.month = selected_date.month
				if last_month_day_count < new_date.day:
					insert_event(i, selected_date, Global.date_comparison(current_date, selected_date, ">"))
				if new_date.month == selected_date.month and new_date.day <= current_month_day_count:
					insert_event(i, new_date, Global.date_comparison(current_date, new_date, ">"))
	values = select("temporary", "*", "date>='"+date.split(" ")[0]+"'", "date") # Получение результата расчета
	db.query("DROP TABLE IF EXISTS temporary;") # Удаление временной таблицы
	return values

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
	
# Получение информации о счёте
func select_wallet_inf(id: int) -> Dictionary:
	var value: Dictionary = select_inf_value(Tables.WALLETS, id)
	if value == {}: return value
	var total: Array = select_wallets_movement(id)
	value["total_value"] = total[0]
	value["total_count"] = total[1]
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
	db.query("SELECT * FROM cash_flows WHERE section_id IN (2, 3, 4) AND wallet_2_id="+str(id)+" ORDER BY date")
	var summ: float = 0.0
	var percents: Array = []
	for i in db.query_result:
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
	
func select_existence_user(login: bool) -> bool:
	var req: String = 'login="'+File.config["login"]+'"'
	if login: req += ' AND password="'+File.config["password"]+'"'
	var res: Array = Request.select(Tables.USERS, "COUNT(id)=="+str(int(login))+" res", req)
	if len(res) == 0: return false
	return res[0].res

func select_user() -> Dictionary:
	var user_data: Array = []
	for i in File.config.keys(): if i in _get_columns(Tables.USERS): user_data.append(i+'="'+File.config[i]+'"')
	return Request.select(Tables.USERS, "*", " AND ".join(user_data))[0]

# Удаление при знании условия
func delete_user():
	Request.connection_user_db()
	var data: Dictionary = select(Tables.USERS, "*", 'login="'+File.config.login+'"')[0]
	DirAccess.remove_absolute("res://bases/"+File.show_data(data.base)+".db")
	delete(Tables.USERS, data.id)
	File.clear_config()


# Обновление функций
# Запрос на получение суммы и количества транзакций сгруппированных по разделам
func select_sections_cash_movement(id: int, date: String = Global.date_to_str()) -> Array:
	db.query("SELECT cf.wallet_id, cf.section_id, sum(cf.value) value, count(cf.id) count, s.title, s.income FROM cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id "+\
		"WHERE cf.wallet_id="+str(id)+" AND s.month_limit>=0 AND "+where_date(date, "cf.date")+" GROUP BY s.id;")
	var result: Array = db.query_result
	for i in result: if not i.income: i.value *= -1
	return result

# Запрос на получение суммы и количества транзакций сгруппированных по специальным разделам
func select_special_sections_cash_movement(id: int, date: String = Global.date_to_str()) -> Array:
	db.query("SELECT cf.*, s.title, SUM(cf.value) value, COUNT(cf.id) count FROM cash_flows cf LEFT JOIN sections s ON cf.section_id = s.id "+\
		"WHERE (cf.wallet_id="+str(id)+" OR (cf.wallet_2_id="+str(id)+" AND s.id=1)) AND s.month_limit=-1 AND "+where_date(date, "cf.date")+" GROUP BY section_id, wallet_id, wallet_2_id;")
	var sections: Array = []
	var values: Array = []
	for i in db.query_result:
		if i.section_id not in sections:
			sections.append(i.section_id)
			values.append({"wallet_id": id, "section_id": i.section_id, "title": i.title, "value": 0.0, "count": 0})
		if (i.section_id == 1 and i.wallet_id == id) or i.section_id == 2:
			i.value *= -1.
		values[sections.find(i.section_id)].value += i.value
		values[sections.find(i.section_id)].count += i.count
	return values

# Объединение результатов двух запросов на сумму и количество транзакций сгруппированных по разделам
func select_general_sections_cash_movement(id, date: String = Global.date_to_str()) -> Array:
	if not id: return []
	return select_special_sections_cash_movement(id, date) + select_sections_cash_movement(id, date)
	
# Получение суммы движений средств на счете
func select_wallets_movement(id: int, date: String = Global.date_to_str()) -> Array:
	var result: Array = [0.0, 0]
	for i in select_general_sections_cash_movement(id, date):
		result[0] += i.value 
		result[1] += i.count
	return result


# Годится
# Запрос на получение списка кошельков
func _select_wallets_list(where: String, order: String) -> Array:
	if where: where = " WHERE "+where
	if order: order = " ORDER BY "+order
	db.query("""SELECT *, (SELECT cf.date FROM cash_flows cf WHERE (cf.section_id NOT IN (2, 3, 4)
		AND cf.wallet_2_id=w.id) OR cf.wallet_id=w.id ORDER BY cf.date DESC) last_date FROM wallets w"""+where+order+";")
	return db.query_result

# Запрос на изменение списка кошельков
func _update_wallets_list(line: Dictionary, date: String = Global.date_to_str()) -> Dictionary:
	db.query("SELECT SUM(IIF((cf.section_id=1 and cf.wallet_id="+str(line.id)+""")OR cf.section_id=3 OR (s.income=0 and cf.section_id>4), cf.value*-1, cf.value)) value
		FROM cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id WHERE (cf.wallet_id="""+str(line.id)+" or (cf.wallet_2_id="+str(line.id)+" and cf.section_id=1)) AND "+where_date(date, "cf.date")+";")
	line["cash_flow"] = db.query_result[0].value if db.query_result[0].value else 0.
	return line
	
# Запрос на получение списка разделов
func select_sections_list(where: String = "", date: String = Global.date_to_str(), order: String = "") -> Array:
	if where: where = " WHERE "+where
	if order: order = " ORDER BY "+order
	db.query("""SELECT s.*, COALESCE(j.v, 0.0) value, j.last_date, j.last_id FROM `sections` s LEFT JOIN
		(SELECT cf.section_id, SUM(cf.value) v, cf.date last_date, cf.id last_id FROM `cash_flows` cf WHERE """+where_date(date)+" GROUP BY cf.section_id) j ON s.id=j.section_id"+where+order+";")
	return db.query_result
	
# Запрос на изменение списка разделов
func _update_sections_list(line: Dictionary, parent) -> Dictionary:
	line["marker"] = ColorScheme.get_color(parent.obj_count(), len(parent.change_list) + parent.obj_count())
	line["progress"] = (100. * line.value) / line.month_limit
	return line

# Запрос на получение списка движений средств
func _select_cash_flows_list(where: String = "", date: String = Global.date_to_str(), order: String = "") -> Array:
	if where: where = " AND "+where
	if order: order = " ORDER BY "+order
	db.query("""SELECT cf.*, s.title, w.title wallet_title FROM `cash_flows` cf LEFT JOIN sections s ON cf.section_id=s.id
		LEFT JOIN wallets w ON cf.wallet_id=w.id WHERE """+where_date(date)+where+order+";")
	return db.query_result

# Запрос на изменение списка разделов
func _update_cash_flows_list(line: Dictionary) -> Dictionary:
	match line.section_id:
		1: line["wallet_2_title"] = _select_title(Tables.WALLETS, line.wallet_2_id)
		3, 4: line["wallet_2_title"] = _select_title(Tables.LOANS, line.wallet_2_id)
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
	db.query("""SELECT SUM(CASE WHEN cf.section_id IN (1, 4) THEN 0 WHEN cf.section_id = 3 OR (s.income = 0 AND s.month_limit<>-1)  THEN cf.value * -1 ELSE cf.value END) value,
		strftime('%d', cf.date) day FROM cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id WHERE """+where_date(date)+where+" GROUP BY cf.date")
	return db.query_result
	
# Получение списка займов
func _select_loans_list(where: String = "", order: String = "") -> Array:
	if where != "": where = " WHERE " + where
	if order != "": order = " ORDER BY " + order
	db.query("SELECT l.*, cf.wallet_id, w.title wallet_title, cf.value FROM loans l LEFT JOIN cash_flows cf ON cf.section_id=2 AND cf.wallet_2_id=l.id LEFT JOIN wallets w ON cf.wallet_id=w.id"+where+order+";")
	return db.query_result

# Добавление событий во временную таблицу
func _insert_event(value: Dictionary, date: Dictionary) -> void:
	var text_date: String = Global.date_to_str(date).split(" ")[0]
	insert_record("multiplied_events", ["'"+value.title+"'", value.event_type, value.value, "'"+text_date+"'", "'"+value.note+"'", Global.date_comparison(Global.date, date, ">"), value.id])

# Добавление событий во временную таблицу с выбранным шагом
func _insert_events_with_step(value: Dictionary, new_date: Dictionary, day_count: int, step: int) -> void:
	while new_date.day <= day_count:
		_insert_event(value, new_date)
		new_date.day += step
		
# Получение событий в текущем месяце с датой первого появления
func _select_events_list(date: String) -> Array:
	db.query("""SELECT *, Date(julianday(date) + juli + CASE WHEN juli<0 THEN juli*-1 WHEN repetition_rate=1 THEN juli%2
		WHEN repetition_rate=2 THEN 7-juli%7 ELSE juli*-1 END) new_date FROM (SELECT *, (julianday(Date('"""+date+\
		"'))-julianday(date)) juli FROM events) AS event WHERE strftime('%Y-%m', date)<=strftime('%Y-%m', Date('"+date+"')) ORDER BY new_date;")
	return db.query_result

# Заполнение таблицы размноженных событий
func create_multiplied_events_table(date: String) -> void:
	# Подготовка данных о месяце для формирования событий
	var selected_date: Dictionary = Global.date_to_dict(date)
	var current_month_day_count: int = select_day_count(date)
	var last_month_day_count: int = select_day_count(Global.get_last_month(date))
	var values: Array = _select_events_list(date) # Получение первоначальных данных для таблицы
	db.query("DELETE FROM multiplied_events")
	update(Tables.SQLITE_SEQUENCE, "seq=0", 'name="multiplied_events"')
	# Заполнение таблицы
	for i in values:
		var new_date: Dictionary = Global.date_to_dict(i.new_date)
		match i.repetition_rate:
			0: if Global.date_comparison(selected_date, new_date, "==", false): _insert_event(i, new_date)
			1: _insert_events_with_step(i, new_date, current_month_day_count, 2)
			2: _insert_events_with_step(i, new_date, current_month_day_count, 7)
			3, 4:
				new_date.year = selected_date.year
				if i.repetition_rate == 3:
					new_date.month = selected_date.month
					if last_month_day_count < new_date.day: _insert_event(i, new_date)
					if current_month_day_count >= new_date.day: _insert_event(i, new_date)
				elif new_date.month == selected_date.month and current_month_day_count >= new_date.day:
					_insert_event(i, new_date)
				elif new_date.month == Global.get_last_month(selected_date).month and last_month_day_count < new_date.day:
					_insert_event(i, new_date)
	
func select_multiplied_events_list(where: String = "") -> Array:
	if where: where = "CAST(strftime('%d', date) AS INTEGER) = "+where
	return select("multiplied_events", "*", where, "date")

# Запрос на изменение списка разделов
func _update_events_list(line: Dictionary) -> Dictionary:
	if line.event_type == 1: line["profit_accounting"] = select("wallets", "COALESCE(SUM(value), 0.0) value")[0].value + select("multiplied_events", "COALESCE(SUM(value), 0.0) value", 'event_type=2 AND date<"'+line.date+'"')[0].value - line.value
	return line
	
# Запрос на получение списка событий юуз дубликации записей
func _select_unique_events() -> Array:
	db.query("SELECT title, event_id FROM multiplied_events GROUP BY event_id;")
	return db.query_result

# Получение списка дней с покрайней мере одним событием
func select_event_days(where: String = "") -> Array:
	if where: where = " WHERE " + where
	db.query("SELECT date FROM multiplied_events"+where+" GROUP BY date;")
	return db.query_result

# Распределение запросов для заполнения списков на страницах
func match_select(list_element: ObjectVariants, filter_data: Dictionary) -> Array:
	match list_element:
		ObjectVariants.WALLET: return _select_wallets_list(filter_data.where, filter_data.order)
		ObjectVariants.SECTION: return select_sections_list(filter_data.where, filter_data.date, filter_data.order)
		ObjectVariants.CASH_FLOW: return _select_cash_flows_list(filter_data.where, filter_data.date, filter_data.order)
		ObjectVariants.LOAN: return _select_loans_list(filter_data.where, filter_data.order)
		ObjectVariants.EVENT: return select_multiplied_events_list()
	return []

# Распределение запросов на обновление элементов списков на страницах
func match_update_list_element(list_element: ObjectVariants, line: Dictionary, parent = null) -> Dictionary:
	match list_element:
		ObjectVariants.WALLET: return _update_wallets_list(line)
		ObjectVariants.SECTION:	return _update_sections_list(line, parent)
		ObjectVariants.CASH_FLOW: return _update_cash_flows_list(line)
		ObjectVariants.EVENT: return _update_events_list(line)
	return line
	
	
