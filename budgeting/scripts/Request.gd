extends Node
# Перечисления
enum Tables {WALLETS, SECTIONS, CASH_FLOWS, LOANS, PAYMENTS, SQLITE_SEQUENCE} # Таблицы в базе данных

# Параметр
var db: SQLite = null # Подключенная база данных

# Создание и подключение базы данных
func _ready() -> void:
	connection_db()
	create_tables()
	create_datas()

# Подключение базы данных
func connection_db() -> void:
	db = SQLite.new()
	db.path = "res://bases/base.db"
	db.open_db()
	
func _create_table(title: String, columns: String, other: String = "") -> void:
	db.query("CREATE TABLE IF NOT EXISTS "+title+" (id INTEGER PRIMARY KEY AUTOINCREMENT, "+columns+other+");")

# Создание таблиц в базе
func create_tables() -> void:
	_create_table("wallets", "title VARCHAR(255), value FLOAT")
	_create_table("sections", "title VARCHAR(255), month_limit FLOAT, income BOOLEAN")
	_create_table("cash_flows", "wallet_id INT, section_id INT, value FLOAT, date DATE, note VARCHAR(255)",	"FOREIGN KEY (`wallet_id`) REFERENCES `wallets`(`id`), FOREIGN KEY (`section_id`) REFERENCES `sections`(`id`)")
	_create_table("loans", "title VARCHAR(255), date DATE, total FLOAT, percent FLOAT")
	_create_table("payments", "wallet_id INT, loan_id INT, value FLOAT, date DATE, note VARCHAR(255)", "FOREIGN KEY (`wallet_id`) REFERENCES `wallets`(`id`), FOREIGN KEY (`loan_id`) REFERENCES `loans`(`id`)")
	_create_table("events", "title VARCHAR(255), date DATE, note VARCHAR(255)")
	
# Создание данных для проверки работы программы
func create_datas() -> void:
	if len(select(Tables.CASH_FLOWS)) != 0: return
	db.query('INSERT INTO `wallets` (title, value) VALUES ("Кошелек1", '+str(randi()%10000)+'), ("Кошелек2", '+str(randi()%10000)+');')
	db.query('INSERT INTO `sections` (title, month_limit, income) VALUES ("Перевод", -1, false), ("Развлечения", '+str(randi()%5000)+', false), ("Продукты", '+str(randi()%5000)+', false), ("Другое", '+str(randi()%5000)+', false);')
	db.query('INSERT INTO `cash_flows` (wallet_id, section_id, value) VALUES ('+str((randi()%2)+1)+','+str((randi()%3)+1)+','+str(randi()%1000)+'), ('+str((randi()%2)+1)+','+str((randi()%3)+1)+','+str(randi()%1000)+'), ('+str((randi()%2)+1)+','+str((randi()%3)+1)+','+str(randi()%1000)+');')
	db.query('INSERT INTO `loans` (title, total, percent) VALUES ("Кредит", '+str(randi()%1000000)+', '+str(randi()%50)+');')
	db.query('INSERT INTO `payments` (wallet_id, loan_id, value) VALUES ('+str((randi()%2)+1)+', 1, '+str(randi()%5000)+'), ('+str((randi()%2)+1)+', 1, '+str(randi()%5000)+'), ('+str((randi()%2)+1)+', 1, '+str(randi()%5000)+');')
	db.query('INSERT INTO `events` (title) VALUES ("событие1"), ("событие3"), ("событие4"), ("событие5");')

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

# Получение суммы затрат / доходов по статьям расходов / доходов
func select_cash_flow_sum(wallet_id: int) -> Array:
	db.query("""SELECT s.title, COUNT(cf.id) count, SUM(cf.value) value FROM `cash_flows` as cf
		LEFT JOIN `sections` AS s ON cf.section_id = s.id WHERE wallet_id="""+str(wallet_id)+" GROUP BY section_id;")
	return db.query_result
