extends Node
# Перечисление
enum Tables {WALLETS, SECTIONS, CASH_FLOWS, LOANS, EVENTS, SQLITE_SEQUENCE} # Таблицы в базе данных

# Переменная
var db: SQLite = null # Подключенная база данных

# Создание и подключение базы данных
func _ready() -> void:
	connection_db()
	create_tables()

# Подключение базы данных
func connection_db() -> void:
	db = SQLite.new()
	db.path = "res://bases/base.db"
	db.open_db()

# Запрос на создание таблицы
func _create_table(title: String, columns: String, other: String = "") -> void:
	if other: other = ", " + other
	db.query("CREATE TABLE IF NOT EXISTS "+title+" (id INTEGER PRIMARY KEY AUTOINCREMENT, "+columns+other+");")

# Создание таблиц в базе
func create_tables() -> void:
	_create_table("wallets", "title VARCHAR(255), value FLOAT")
	_create_table("sections", "title VARCHAR(255), month_limit FLOAT, income BOOLEAN")
	_create_table("cash_flows", "wallet_id INT, wallet_2_id INT, section_id INT, value FLOAT, date DATE, note VARCHAR(255)",	"FOREIGN KEY (`wallet_id`) REFERENCES `wallets`(`id`), FOREIGN KEY (`section_id`) REFERENCES `sections`(`id`)")
	_create_table("loans", "title VARCHAR(255), total FLOAT, date DATE")
	_create_table("events", "title VARCHAR(255), repetition_rate INT, date DATE, note VARCHAR(255)")
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
func where_date(date: String = Time.get_datetime_string_from_system(), column: String = "date") -> String:
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

# Запрос на получение суммы и количества транзакций сгруппированных по разделам
func select_sections_cash_movement(id: int, date: String = Time.get_datetime_string_from_system()) -> Array:
	db.query("SELECT cf.wallet_id, cf.section_id, sum(cf.value) value, count(cf.id) count, s.title, s.income FROM cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id "+\
		"WHERE cf.wallet_id="+str(id)+" AND s.month_limit>=0 AND "+where_date(date, "cf.date")+" GROUP BY s.id;")
	var result: Array = db.query_result
	for i in result: if not i.income: i.value *= -1
	return result

# Запрос на получение суммы и количества транзакций сгруппированных по специальным разделам
func select_special_sections_cash_movement(id: int, date: String = Time.get_datetime_string_from_system()) -> Array:
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
func select_general_sections_cash_movement(id, date: String = Time.get_datetime_string_from_system()) -> Array:
	if not id: return []
	return select_special_sections_cash_movement(id, date) + select_sections_cash_movement(id, date)
	
# Получение суммы движений средств на счете
func select_wallets_movement(id: int, date: String = Time.get_datetime_string_from_system()) -> Array:
	var result: Array = [0.0, 0]
	for i in select_general_sections_cash_movement(id, date):
		result[0] += i.value 
		result[1] += i.count
	return result

# Получение списка счетов
func select_wallets_list(where: String, order: String) -> Array:
	if where: where = " WHERE "+where
	if order: order = " ORDER BY "+order
	db.query("""SELECT *, (SELECT cf.date FROM cash_flows cf WHERE (cf.section_id NOT IN (2, 3, 4)
		AND cf.wallet_2_id=w.id) OR cf.wallet_id=w.id ORDER BY cf.date DESC) last_date FROM wallets w"""+where+order+";")
	var wallets: Array = db.query_result
	for i in range(len(wallets)): wallets[i]["cash_flow"] = select_wallets_movement(wallets[i].id)[0]
	return wallets
	
# Получение движенения средств суммарно для всех кошельков
func select_general_wallets_movement() -> float:
	var sum: float = 0.0
	for i in select(Tables.WALLETS, "id"): sum += select_wallets_movement(i.id)[0]
	return sum
	
# Получение списка разделов
func select_sections(where: String = "", date: String = Time.get_datetime_string_from_system(), order: String = "") -> Array:
	return select("`sections` s", "*, (SELECT COALESCE(SUM(cf.value), 0.0) FROM `cash_flows` cf WHERE cf.section_id = s.id AND "+where_date(date)+""") value,
		(SELECT cf.date FROM cash_flows cf WHERE cf.section_id = s.id AND """+where_date(date)+""" ORDER BY cf.date DESC) last_date,
		(SELECT cf.id FROM cash_flows cf WHERE cf.section_id = s.id AND """+where_date(date)+" ORDER BY cf.date DESC) last_id", where, order)

# Получение названия объекта под определенным индексом
func _select_title(table: Tables, id: int) -> String: return select(table, "title", "id="+str(id))[0].title

# Получение списка движений средств
func select_cash_flows(where: String = "", date: String = Time.get_datetime_string_from_system(), order: String = "") -> Array:
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
func select_daily_transactions(where: String, date: String = Time.get_datetime_string_from_system()) -> Array:
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
	db.query("SELECT STRFTIME('%d', DATE('"+date+"', 'start of month', '+1 month', '-1 day')) day_count")
	return int(db.query_result[0].day_count)

# Получение событий в текущем месяце с датой первого появления
func select_monthly_events(date: String) -> Array:
	var query_fragment: String = "(julianday(Date('"+date+"'))-julianday(date))"
	db.query("SELECT *, Date(julianday(date)+CASE "+\
		"WHEN "+query_fragment+"<0 THEN 0 "+\
		"WHEN repetition_rate=1 THEN IIF("+query_fragment+"%2==0, "+query_fragment+", "+query_fragment+"+1) "+\
		"WHEN repetition_rate=2 THEN IIF("+query_fragment+"%7==0, "+query_fragment+", "+query_fragment+"+("+query_fragment+"%7)-1) "+\
		"ELSE 0 END) new_date FROM events WHERE strftime('%Y-%m', date)<=strftime('%Y-%m', Date('"+date+"'));")
	return db.query_result

# Добавление событий во временную таблицу
func insert_event(value: Dictionary, date, completed: bool) -> void:
	if date is Dictionary: date = Time.get_datetime_string_from_datetime_dict(date, true).split(" ")[0]
	insert_record("temporary", ["'"+value.title+"'", "'"+date+"'", "'"+value.note+"'", completed])

# Добавление событий во временную таблицу с выбранным шагом
func insert_events_with_step(value: Dictionary, new_date: Dictionary, current_date: Dictionary, day_count: int, step: int) -> void:
	while new_date.day <= day_count:
		insert_event(value, new_date, Global.date_comparison(current_date, new_date, ">"))
		new_date.day += step

# Получение списка событий
func select_events(date: String) -> Array:
	# подготовка данных о месяце для формирования событий
	var current_date: Dictionary = Time.get_datetime_dict_from_system()
	var selected_date: Dictionary = Time.get_datetime_dict_from_datetime_string(date, false)
	var current_month_day_count: int = select_day_count(date)
	var last_month_day_count: int = select_day_count(Time.get_datetime_string_from_datetime_dict(Global.get_other_month(selected_date, false), false))
	var values: Array = select_monthly_events(date) # Получение первоначальных данных для временной таблицы
	# Заполнение временной таблицы
	_create_table("temporary", "title VARCHAR(255), date DATE, note VARCHAR(255), completed BOOLEAN")
	for i in values:
		var new_date: Dictionary = Time.get_datetime_dict_from_datetime_string(i.new_date, false)
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
	values = select("temporary", "*", "", "date") # Получение результата расчета
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
func select_event(id: int) -> Array: return select(Tables.EVENTS, "*", "id="+str(id))

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
