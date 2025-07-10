extends Node
enum Tables {WALLETS, SECTIONS, CASH_FLOWS, LOANS, PAYMENTS, SQLITE_SEQUENCE} # Таблицы в базе данных
var db: SQLite = null # Подключенная база данных

func _ready() -> void:
	connection_db()
	create_tables()
	create_datas()

func connection_db() -> void:
	db = SQLite.new()
	db.path = "res://bases/base.db"
	db.open_db()
	
func create_tables() -> void:
	db.query("CREATE TABLE IF NOT EXISTS wallets (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR(255), value FLOAT);")
	db.query("CREATE TABLE IF NOT EXISTS sections (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR(255), month_limit FLOAT, income BOOLEAN);")
	db.query("""CREATE TABLE IF NOT EXISTS cash_flows (id INTEGER PRIMARY KEY AUTOINCREMENT, wallet_id INT, section_id INT, value FLOAT, date DATE, note VARCHAR(255),
		FOREIGN KEY (`wallet_id`) REFERENCES `wallets`(`id`), FOREIGN KEY (`section_id`) REFERENCES `sections`(`id`));""")
	db.query("CREATE TABLE IF NOT EXISTS loans (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR(255), date DATE, total FLOAT, percent FLOAT);")
	db.query("""CREATE TABLE IF NOT EXISTS payments (id INTEGER PRIMARY KEY AUTOINCREMENT, wallet_id INT, loan_id INT, value FLOAT, date DATE, note VARCHAR(255),
		FOREIGN KEY (`wallet_id`) REFERENCES `wallets`(`id`), FOREIGN KEY (`loan_id`) REFERENCES `loans`(`id`));""")
	db.query("CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR(255), date DATE, note VARCHAR(255));")
	
func create_datas() -> void:
	db.query("SELECT * FROM `cash_flows`;")
	if len(db.query_result) != 0: return
	db.query('INSERT INTO `wallets` (title, value) VALUES ("Кошелек1", '+str(randi()%10000)+'), ("Кошелек2", '+str(randi()%10000)+');')
	db.query('INSERT INTO `sections` (title, month_limit, income) VALUES ("Развлечения", '+str(randi()%5000)+', false), ("Продукты", '+str(randi()%5000)+', false), ("Другое", '+str(randi()%5000)+', false);')
	db.query('INSERT INTO `cash_flows` (wallet_id, section_id, value) VALUES ('+str((randi()%2)+1)+','+str((randi()%3)+1)+','+str(randi()%1000)+'), ('+str((randi()%2)+1)+','+str((randi()%3)+1)+','+str(randi()%1000)+'), ('+str((randi()%2)+1)+','+str((randi()%3)+1)+','+str(randi()%1000)+');')
	db.query('INSERT INTO `loans` (title, total, percent) VALUES ("Кредит", '+str(randi()%1000000)+', '+str(randi()%50)+');')
	db.query('INSERT INTO `payments` (wallet_id, loan_id, value) VALUES ('+str((randi()%2)+1)+', 1, '+str(randi()%5000)+'), ('+str((randi()%2)+1)+', 1, '+str(randi()%5000)+'), ('+str((randi()%2)+1)+', 1, '+str(randi()%5000)+');')
	db.query('INSERT INTO `events` (title) VALUES ("событие1"), ("событие3"), ("событие4"), ("событие5");')

# Получить название таблицы из enum Tables
func _get_table_name(table: Tables) -> String: return Global.enum_key(Tables, table)

# Получение данных из таблиц
func select(table: Tables, columns: String = "*", where: String = "", order: String = "") -> Array:
	if where: where = " WHERE "+where
	if order: order = " ORDER BY "+order
	db.query("SELECT "+columns+" FROM "+_get_table_name(table)+where+order+";")
	return db.query_result

# Получение списка счетов
func get_wallets() -> Array:
	db.query("SELECT * FROM `wallets`;")
	return db.query_result
