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

# Запрос на получение суммы и количества транзакций сгруппированных по разделам
func select_sections_cash_movement(id, date: String = Time.get_datetime_string_from_system()) -> Array:
	db.query("SELECT sum(cf.value) value, count(cf.id) count, s.title, s.income FROM cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id "+\
		"WHERE cf.wallet_id="+str(id)+" AND s.month_limit>=0 AND "+where_date(date, "cf.date")+" GROUP BY s.id;")
	var result: Array = db.query_result
	for i in result: if not i.income: i.value *= -1
	return result

# Запрос на получение суммы и количества транзакций сгруппированных по специальным разделам
func select_special_sections_cash_movment(id, date: String = Time.get_datetime_string_from_system()) -> Array:
	db.query("SELECT cf.*, s.title, SUM(cf.value) value, COUNT(cf.id) count FROM cash_flows cf LEFT JOIN sections s ON cf.section_id = s.id "+\
		"WHERE (cf.wallet_id="+str(id)+" OR (cf.wallet_2_id="+str(id)+" AND s.id=1)) AND s.month_limit=-1 AND "+where_date(date, "cf.date")+" GROUP BY section_id, wallet_id, wallet_2_id;")
	var sections: Array = []
	var values: Array = []
	for i in db.query_result:
		if i.section_id not in sections:
			sections.append(i.section_id)
			values.append({"title": i.title, "value": 0.0, "count": 0})
		if (i.section_id == 1 and i.wallet_id == id) or i.section_id == 2:
			i.value *= -1.
		values[sections.find(i.section_id)].value += i.value
		values[sections.find(i.section_id)].count += i.count
	return values

# Объединение результатов двух запросов на сумму и количество транзакций сгруппированных по разделам
func select_general_sections_cash_movment(id, date: String = Time.get_datetime_string_from_system()) -> Array:
	return select_special_sections_cash_movment(id, date) + select_sections_cash_movement(id, date)
	
# Получение суммы движений средств на счете
func select_wallets_movement(id: int, date: String = Time.get_datetime_string_from_system()) -> Array:
	var result: Array = [0.0, 0]
	for i in select_general_sections_cash_movment(id, date):
		result[0] += i.value 
		result[1] += i.count
	return result

# Получение числового значения из базы
func select_value(table: Tables, columns: String = "*", where: String = "", order: String = "", left: String = "") -> float:
	var value: Array = select(table, columns, where, order, left)
	if len(value) == 0 or not value[0].value: return 0.0
	return value[0].value

# Получение списка разделов
func select_sections(date: String = Time.get_datetime_string_from_system(), where: String = "") -> Array:
	return select("`sections` s", "s.*, (SELECT COALESCE(SUM(cf.value), 0.0) FROM `cash_flows` cf WHERE cf.section_id = s.id AND "+where_date(date)+") value", where)

# Получение суммы затрат / доходов по статьям расходов / доходов
func select_cash_flow_sum(wallet_id: int, date: String = Time.get_datetime_string_from_system()) -> Array:
	return select("`cash_flows` as cf", "s.title, COUNT(cf.id) count, SUM(cf.value) value",
		"wallet_id="+str(wallet_id)+" AND "+where_date(date)+" AND s.title IS NOT NULL", "cf.section_id", "`sections` AS s ON cf.section_id = s.id")
	
# Получение суммы и количества записей по движениям средств
func select_total_cash_flow(id: int, date: String = Time.get_datetime_string_from_system()) -> Dictionary:
	var value: Array = select(Tables.CASH_FLOWS, "COALESCE(SUM(value), 0) value, COALESCE(COUNT(value), 0) count", "wallet_id="+str(id)+" AND "+where_date(date))
	if len(value) == 0: return {"value": 0.0, "count": 0}
	return value[0]
	
# Получение суммы доходов и расходов за месяц
func select_total_v(id: int, date: String = Time.get_datetime_string_from_system()) -> float:
	db.query("SELECT SUM(cf.value) value, s.income FROM cash_flows cf LEFT JOIN sections AS s ON cf.section_id = s.id WHERE cf.wallet_id ="+str(id)+" AND s.month_limit >= 0 AND "+where_date(date)+" GROUP BY income")
	var value: float = 0
	for i in db.query_result:
		if not i.income: i.value*=-1
		value += i.value
	return value
