extends Node
# Перечисления
enum Tables {WALLETS, SECTIONS, CASH_FLOWS, LOANS, PAYMENTS, SQLITE_SEQUENCE} # Таблицы в базе данных

# Параметр
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
	
func _create_table(title: String, columns: String, other: String = "") -> void:
	if other: other = ", " + other
	db.query("CREATE TABLE IF NOT EXISTS "+title+" (id INTEGER PRIMARY KEY AUTOINCREMENT, "+columns+other+");")

# Создание таблиц в базе
func create_tables() -> void:
	_create_table("wallets", "title VARCHAR(255), value FLOAT")
	_create_table("sections", "title VARCHAR(255), month_limit FLOAT, income BOOLEAN")
	_create_table("cash_flows", "wallet_id INT, section_id INT, value FLOAT, date DATE, note VARCHAR(255)",	"FOREIGN KEY (`wallet_id`) REFERENCES `wallets`(`id`), FOREIGN KEY (`section_id`) REFERENCES `sections`(`id`)")
	_create_table("loans", "title VARCHAR(255), date DATE, total FLOAT")
	_create_table("payments", "cash_flow_id INT, loan_id INT", "FOREIGN KEY (`cash_flow_id`) REFERENCES `cash_flows`(`id`), FOREIGN KEY (`loan_id`) REFERENCES `loans`(`id`)")
	_create_table("events", "title VARCHAR(255), date DATE, note VARCHAR(255)")
	if len(select(Tables.SECTIONS)) != 0: return
	for i in ["Переводы", "Платежи"]: insert_record(Tables.SECTIONS, ['"'+i+'"', -1, false])
	
# Получить название таблицы из enum Tables
func _get_table_name(table: Tables) -> String: return Global.enum_key(Tables, table)

# Получить названия колонок
func _get_columns(table: Tables) -> Array:
	db.query("PRAGMA table_info(`"+_get_table_name(table)+"`)")
	var result: Array = []
	for i in db.query_result: result.append(i.name)
	result.pop_front()
	return result
	
# Добавление фрагмента текста в запрос
func add_part_request(text: String, column: String, value, operator: String = "=", sep: String = " AND ") -> String:
	if not value: return text
	if text: text += sep 
	if operator == "LIKE": value = '"%' + str(value) + '%"'
	text += column + " " + operator + " " + str(value)
	return text

# Отправка запроса на создание записи таблице
func insert(table: Tables, columns: Array, values: Array) -> void:
	db.query("INSERT INTO `"+_get_table_name(table)+"` ("+",".join(columns)+") VALUES ("+",".join(values)+");")

# Добавление записи
func insert_record(table: Tables, values: Array) -> void:
	insert(table, _get_columns(table), values)

# Отправка запроса на изменение записей в таблице
func update(table: Tables, values: String, where: String) -> void:
	db.query("UPDATE `"+_get_table_name(table)+"` SET "+values+" WHERE "+where + ";")

# Изменение записи
func update_record(table: Tables, id: int, values: Array) -> void:
	var request_text: String = ""
	var columns: Array = _get_columns(table)
	for i in len(values): request_text = add_part_request(request_text, columns[i], values[i], "=", ", ")
	update(table, request_text, "id=" + str(id))

# Отправка запроса на удаление записи в таблице
func delete(table: Tables, id: int) -> void:
	db.query("DELETE FROM `"+_get_table_name(table)+"` WHERE id="+str(id)+";")
	update(Tables.SQLITE_SEQUENCE, "seq=seq-1", 'name="'+_get_table_name(table)+'"')
	update(Tables.WALLETS, "id=id-1", "id>"+str(id))

# Получение данных из таблиц
func select(table: Tables, columns: String = "*", where: String = "", order: String = "") -> Array:
	if where: where = " WHERE "+where
	if order: order = " ORDER BY "+order
	db.query("SELECT "+columns+" FROM "+_get_table_name(table)+where+order+";")
	return db.query_result

# Получение числового значения из базы
func select_value(table: Tables, columns: String = "*") -> float:
	var value: Array = select(table, columns)
	if len(value) == 0 or not value[0].value: return 0.0
	return value[0].value

# Получение списка разделов (нужно доделать)
func select_sections(date: String = Time.get_datetime_string_from_system()) -> Array:
	db.query("SELECT s.*, COALESCE(SUM(cf.value), 0) value FROM `sections` s LEFT JOIN `cash_flows` cf ON cf.section_id = s.id WHERE strftime('%Y-%m', cf.date) = strftime('%Y-%m', '"+date+"') GROUP BY s.id;")
	return db.query_result

# Получение суммы затрат / доходов по статьям расходов / доходов
func select_cash_flow_sum(wallet_id: int, date: String = Time.get_datetime_string_from_system()) -> Array:
	db.query("""SELECT s.title, COUNT(cf.id) count, SUM(cf.value) value FROM `cash_flows` as cf
		LEFT JOIN `sections` AS s ON cf.section_id = s.id WHERE wallet_id="""+str(wallet_id)+" AND strftime('%Y-%m', date) = strftime('%Y-%m', '"+date+"') GROUP BY section_id;")
	return db.query_result
	
# Получение суммы затрат / доходов по статьям расходов / доходов
func select_total_cash_flow(id: int, date: String = Time.get_datetime_string_from_system()) -> Dictionary:
	db.query("SELECT COALESCE(SUM(value), 0) value, COALESCE(COUNT(value), 0) count FROM `cash_flows` WHERE wallet_id="+str(id)+" AND strftime('%Y-%m', date) = strftime('%Y-%m', '"+date+"');")
	var value: Array = db.query_result 
	if len(value) == 0: return {"value": 0.0, "count": 0}
	return value[0]
