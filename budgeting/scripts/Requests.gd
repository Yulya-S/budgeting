extends Node

var db: SQLite = null

func _ready() -> void:
	connection_db()
	create_tables()

func connection_db():
	db = SQLite.new()
	db.path = "res://bases/base.db"
	db.open_db()
	
func create_tables():
	db.query("CREATE TABLE IF NOT EXISTS wallets (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR(255), value INT);")
	db.query("CREATE TABLE IF NOT EXISTS sections (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR(255), monts_limit INT, income BOOLEAN);")
	db.query("""CREATE TABLE IF NOT EXISTS cash_flows (id INTEGER PRIMARY KEY AUTOINCREMENT, wallet_id INT, section_id INT, value INT, date DATE, note VARCHAR(255),
		FOREIGN KEY (`wallet_id`) REFERENCES `wallets`(`id`), FOREIGN KEY (`section_id`) REFERENCES `sections`(`id`));""")
	db.query("CREATE TABLE IF NOT EXISTS loans (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR(255), date DATE, total INT, percent INT);")
	db.query("""CREATE TABLE IF NOT EXISTS payments (id INTEGER PRIMARY KEY AUTOINCREMENT, wallet_id INT, loan_id INT, value INT, date DATE, note VARCHAR(255),
		FOREIGN KEY (`wallet_id`) REFERENCES `wallets`(`id`), FOREIGN KEY (`loan_id`) REFERENCES `loans`(`id`));""")
	db.query("CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR(255), date DATE, note VARCHAR(255));")
	
