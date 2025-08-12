extends Node
# Перечисление
enum Tables {WALLETS, SECTIONS, CASH_FLOWS, LOANS, PAYMENTS, SQLITE_SEQUENCE} # Таблицы в базе данных

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
	_create_table("loans", "title VARCHAR(255), date DATE, total FLOAT")
	_create_table("events", "title VARCHAR(255), date DATE, note VARCHAR(255)")
	if len(select(Tables.SECTIONS)) != 0: return
	for i in ["Переводы", "Платежи", "Заём"]: insert_record(Tables.SECTIONS, ['"'+i+'"', -1, false])
	
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
	update(Tables.WALLETS, "id=id-1", "id>"+str(id))

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
	return len(Request.select(Request.Tables.WALLETS)) != 0 and len(Request.select(Request.Tables.SECTIONS)) > 3

# Получение текущего суммарного бюджета
func select_budget() -> float:
	var wallets_sum: float = select(Tables.WALLETS, "COALESCE(SUM(value), 0) value")[0].value
	return wallets_sum + (select(Tables.LOANS, "COALESCE(SUM(total), 0) value")[0].value * 2.)

# Запрос на получение суммы и количества транзакций сгруппированных по разделам
func select_sections_cash_movement(id, date: String = Time.get_datetime_string_from_system()) -> Array:
	db.query("SELECT cf.wallet_id, cf.section_id, sum(cf.value) value, count(cf.id) count, s.title, s.income FROM cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id "+\
		"WHERE cf.wallet_id="+str(id)+" AND s.month_limit>=0 AND "+where_date(date, "cf.date")+" GROUP BY s.id;")
	var result: Array = db.query_result
	for i in result: if not i.income: i.value *= -1
	return result

# Запрос на получение суммы и количества транзакций сгруппированных по специальным разделам
func select_special_sections_cash_movement(id, date: String = Time.get_datetime_string_from_system()) -> Array:
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
	return select_special_sections_cash_movement(id, date) + select_sections_cash_movement(id, date)
	
# Получение суммы движений средств на счете
func select_wallets_movement(id: int, date: String = Time.get_datetime_string_from_system()) -> Array:
	var result: Array = [0.0, 0]
	for i in select_general_sections_cash_movement(id, date):
		result[0] += i.value 
		result[1] += i.count
	return result
	
# Получение движенения средств суммарно для всех кошельков
func select_general_wallets_movement() -> float:
	var sum: float = 0.0
	for i in select(Tables.WALLETS, "id"): sum += select_wallets_movement(i.id)[0]
	return sum
	
# Получение списка разделов
func select_sections(where: String = "", date: String = Time.get_datetime_string_from_system()) -> Array:
	return select("`sections` s", "s.*, (SELECT COALESCE(SUM(cf.value), 0.0) FROM `cash_flows` cf WHERE cf.section_id = s.id AND "+where_date(date)+") value", where)

# Получение списка движений средств
func select_cash_flows(where: String = "", date: String = Time.get_datetime_string_from_system()) -> Array:
	if where != "": where += " AND " + where_date(date)
	else: where = where_date(date)
	return select("`cash_flows` cf", "cf.*, s.title, w.title wallet_title", where, "cf.date DESC", "sections s ON cf.section_id=s.id LEFT JOIN wallets w ON cf.wallet_id=w.id")

# Получение суммы движений средств распределенных по дням
func select_daily_transactions(where: String, date: String = Time.get_datetime_string_from_system()) -> Array:
	if where != "": where = " WHERE " + where
	db.query("""SELECT COALESCE(SUM(value), 0) value, strftime('%d', date) day FROM (SELECT cf.date, CASE WHEN cf.section_id = 1 THEN 0
		WHEN cf.section_id = 2 THEN cf.value * -1 WHEN s.income = 0 THEN cf.value * -1 ELSE cf.value END value FROM cash_flows cf
		LEFT JOIN sections s ON cf.section_id=s.id"""+where+") WHERE "+where_date(date)+" GROUP BY date")
	return db.query_result
	
