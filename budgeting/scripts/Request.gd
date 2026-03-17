extends Node
# Перечисления
enum Tables {WALLETS, SECTIONS, SUBSECTIONS, CASH_FLOWS, LOANS,
	EVENTS, SETTINGS, NOTIFICATIONS, SQLITE_SEQUENCE, USERS,
	MULTIPLIED_EVENTS, FAST_CREATIONS, TEMP_TABLE} # Таблицы в базе данных
enum ObjectVariants {WALLET, SECTION, CASH_FLOW, LOAN, EVENT, REPORT_W, REPORT_S,
	NOTIFICATION, FAST_CREATION, WALLET_TRANSACTION, SUBSECTION} # Варианты списков объектов, по которым могут быть запросы
enum ActionTypes {INSERT, UPDATE, DELETE} # Виды действий с объектами

# Переменные
var db: SQLite = null # Подключенная база данных
# Данные для заполнения таблицы событий
var events: Array = [] # Список событий для постепенного увеличения их количества
var completion_creation_et: bool = false # Маркер завершения заполнения таблицы событий
@onready var selected_date: NewDate = NewDate.new() # Выбранная дата
@onready var next_month: NewDate = NewDate.new()  # Следующий месяц
var last_month_day_count: int = 30 # Количество дней в предыдущем месяце

# Постепенное создание событий в таблице "Размноженных" событий
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
			3, 4:
				_insert_events_to_repetition_rate_3_4(value, new_date, selected_date.date)
				if selected_date.date.day != 1:
					_insert_events_to_repetition_rate_3_4(value, new_date, next_month.date)
			0:
				if selected_date.date_comparison(new_date, "=="):
					_insert_multiplied_event(value, new_date)
				if next_month.date_comparison(new_date, "==", false) and selected_date.date.day != 1:
					_insert_multiplied_event(value, new_date)

# Начало создания таблицы событий
func start_create_multiplied_events_table(date: String) -> void:
	selected_date.set_value(date)
	next_month.set_value(Global.get_other_month(selected_date.date, true))
	last_month_day_count = select_day_count(Global.get_other_month(date))
	var new_date: String = date
	if selected_date.date.day < selected_date.day_count - 14:
		new_date = Global.date_to_str(next_month.date)
	events = select("*, Date(julianday(date)+juli+CASE WHEN juli<0 THEN juli*-1
		WHEN repetition_rate=1 THEN juli%2 WHEN repetition_rate=2 THEN 7-juli%7
		ELSE juli*-1 END) new_date FROM (SELECT *, (julianday(Date('" + date +
		"'))-julianday(date)) juli FROM events) AS event",
		where_date(new_date, "date", "<="), "new_date")
	_delete(Tables.MULTIPLIED_EVENTS)
	_update(Tables.SQLITE_SEQUENCE, ["seq"], ["0"], 'name="multiplied_events"')
	completion_creation_et = false

# Подключение базы данных и создание таблиц в ней
# Открытие базы данных
func _open_db(db_name: String = "users") -> void:
	db = SQLite.new()
	db.path = File.BasesPath + db_name + ".db"
	db.open_db()

# Подключение базы данных пользователей
func connection_user_db() -> void:
	_open_db()
	_create_table(Tables.USERS, ["login VARCHAR(255)", "password VARCHAR(255)", "base VARCHAR(255)"])

# Создание стандартных объектов в таблице
func _insert_standart(table: Tables, values: Array, substitution_data: Array = [0]) -> void:
	if len(select_all(table)) == 0:
		for i in substitution_data: _insert_witn_columns(table, [i] + values)

# Подключение базы данных
func connection_db(db_name: String) -> void:
	_open_db(db_name)
	# Создание таблиц в базе
	_create_table(Tables.WALLETS, ["value FLOAT"], true)
	_create_table(Tables.SECTIONS, ["income BOOLEAN", "month_limit FLOAT"], true)
	_create_table(Tables.SUBSECTIONS, ["section_id INT", "month_limit FLOAT"], true)
	_create_table(Tables.CASH_FLOWS, ["wallet_id INT", "wallet_2_id INT",
		"section_id INT", "subsection_id INT", "value FLOAT", "date DATE"])
	_create_table(Tables.LOANS, ["total FLOAT"], true)
	_create_table(Tables.EVENTS, ["repetition_rate INT",
		"event_type INT", "value FLOAT", "date DATE"], true)
	_create_table(Tables.MULTIPLIED_EVENTS, ["event_type INT", "value FLOAT",
		"date DATE", "completed BOOLEAN", "event_id INT"], true)
	# Создание таблиц для персонализации приложения
	_create_table(Tables.SETTINGS, ["color_preset BOOLEAN", "color_scheme INT",
		"color_1 VARCHAR(255)", "color_2 VARCHAR(255)", "color_3 VARCHAR(255)",
		"color_4 VARCHAR(255)", "dark_theme BOOLEAN",
		"event_page_calendar BOOLEAN", "last_entry DATE"])
	_create_table(Tables.NOTIFICATIONS, ["event_id INT", "new BOOL", "date DATE"])
	_create_table(Tables.FAST_CREATIONS, ["wallet_id INT", "section_id INT", "subsection_id INT"])
	# Создание стандартных данных
	_insert_standart(Tables.SECTIONS, [false, -1], ['"__ST1"', '"__ST2"'])
	_insert_standart(Tables.SUBSECTIONS, [2, -1], ['"__SS1"', '"__SS2"', '"__SS3"'])
	_insert_standart(Tables.SETTINGS, [0, '"3a9891ff"', '"c8c8c8ff"', "null",
		"null", 0, 0, '"'+Global.date_to_str()+'"'])

# Запрос на создание таблицы
func _create_table(title: Tables, t_columns: Array, title_c: bool = false) -> void:
	if title_c: t_columns = ["title VARCHAR(255)"] + t_columns
	var foreign: Array = []
	for i in t_columns: if "id" in i:
		foreign.append("(`"+i.split(" ")[0]+"`) REFERENCES `"+i.split("_id")[0]+"s`(`id`)")
	if len(foreign) != 0: foreign = [""] + foreign
	db.query("CREATE TABLE IF NOT EXISTS " + Global.enum_key(Tables, title) +
		" (id INTEGER PRIMARY KEY AUTOINCREMENT, " + ", ".join(t_columns) +
		", FOREIGN KEY ".join(foreign) + ");")

# Фрагменты запросов
# Название таблицы
func _get_table_name(table: Variant) -> String:
	if table is String: return table
	return Global.enum_key(Tables, table)

# Названия колонок в таблице
func _get_columns(table: Variant) -> Array:
	db.query("PRAGMA table_info(`"+_get_table_name(table)+"`)")
	var result: Array = []
	for i in db.query_result: result.append(i.name)
	result.pop_front()
	return result

# Сборка даты поиска по дате
func where_date(date: String = Global.date_to_str(),
		column: String = "date", operator: String = "=") -> String:
	return "STRFTIME('%Y-%m', " + column + ")" + operator + 'STRFTIME("%Y-%m", "' + date + '")'

# Текст для запроса движений средств
func _funds_movements_text() -> String:
	return "COALESCE(SUM(CASE WHEN cf.section_id=1 OR cf.subsection_id=3 THEN 0
		WHEN cf.subsection_id=2 OR (s.income = 0 AND s.month_limit<>-1)
		THEN cf.value * -1 ELSE cf.value END), 0.0)
		value FROM cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id"

# Получение суммы значений по таблице
func _table_sum(table: Variant) -> String:
	return "COALESCE(SUM(value), 0.0) value FROM " + _get_table_name(table)

# Получение списка отчета по счетам
func _coalesce_select_fr() -> String:
	return "COALESCE((SELECT SUM(cf.value) FROM cash_flows cf
		LEFT JOIN sections s on cf.section_id=s.id "

# Получение числового значения фрагмента даты
func _strftime(format: String, date: String) -> String:
	return 'CAST(strftime("%'+format+'", '+date+') AS INTAGER)'

# Получения количества месяцев от выбранной даты
func _month_count(date: String = '"'+Global.date_to_str()+'"') -> String:
	return "("+_strftime("Y", date)+" * 12 + "+_strftime("m", date)+")"

# Проверки прошло ли два месяца от выбранной даты
func _month_difference() -> String:
	return _month_count()+" - "+_month_count("date")+" > 2"

# Создание записей
# Основной запрос
func _insert(table: Variant, columns: String, values: Array) -> void:
	db.query("INSERT INTO `" + _get_table_name(table) + "` (" + columns +
		") VALUES (" + ", ".join(values) + ");")

# Со всеми колонками таблицы
func _insert_witn_columns(table: Variant, values: Array) -> void:
	_insert(table, ", ".join(_get_columns(table)), values)

# Добавление событий во временную таблицу
func _insert_multiplied_event(value: Dictionary, date: Dictionary) -> void:
	var text_date: String = Global.date_to_str(date).split(" ")[0]
	_insert_witn_columns(Tables.MULTIPLIED_EVENTS, ["'" + value.title + "'",
		value.event_type, value.value, "'" + text_date + "'",
		Global.date_comparison(Global.get_date(), date, ">"), value.id])

# Добавление событий с выбранным шагом
func _insert_events_with_step(value: Dictionary,
		new_date: Dictionary, day_count: int, step: int) -> void:
	var two_week: int = 0
	if selected_date.date.day != 1 and new_date.month != next_month.date.month: two_week = 14
	while new_date.day <= day_count + two_week:
		var date_dup: Dictionary = new_date.duplicate()
		if new_date.day > day_count:
			date_dup = next_month.date.duplicate()
			date_dup.day = new_date.day - day_count
		elif date_dup.day > next_month.day_count: break
		_insert_multiplied_event(value, date_dup)
		new_date.day += step

# Создание событий для частоты раз в месяц и раз в год
func _insert_events_to_repetition_rate_3_4(value: Dictionary,
		new_date: Dictionary, date: Dictionary) -> void:
	new_date.year = date.year
	if value.repetition_rate == 3:
		new_date.month = date.month
		if last_month_day_count < new_date.day: _insert_multiplied_event(value, new_date)
		if selected_date.day_count >= new_date.day: _insert_multiplied_event(value, new_date)
	elif (new_date.month == date.month and selected_date.day_count >= new_date.day) or \
			(new_date.month == Global.get_other_month(date).month and last_month_day_count < new_date.day):
		_insert_multiplied_event(value, new_date)

# Уведомления из события
func insert_notifications(line: Dictionary) -> void:
	_insert_witn_columns(Tables.NOTIFICATIONS, [line.event_id, true, '"'+line.date+'"'])

# Объект быстрого создания записей
func insert_fast_creation() -> void:
	var subsections: Array = select_all(Tables.SUBSECTIONS, "section_id = 3")
	var subs_id = "null" if len(subsections) == 0 else subsections[0].id
	_insert_witn_columns(Tables.FAST_CREATIONS, [1, 3, subs_id])

# Кошелёк
func _insert_wallet(values: Array) -> void: _insert("wallets", "title, value", values)

# Раздел
func _insert_section(values: Array) -> void:
	if values[1] == "true": values[2] = "-1.0"
	_insert_witn_columns(Tables.SECTIONS, values)

# Подраздел
func _insert_subsection(values: Array) -> void:
	if select_all_id(Tables.SECTIONS, int(values[1]))[0].income == 1: values[2] = "-1.0"
	if len(select_all(Tables.SUBSECTIONS, "section_id="+values[1])) == 0:
		_insert_witn_columns(Tables.SUBSECTIONS, ['"__SS4"', values[1], -1])
		var other_sub_id: int = select_all(Tables.SUBSECTIONS)[-1].id
		_update(Tables.CASH_FLOWS, ["subsection_id"], [other_sub_id], "section_id="+values[1])
		_update(Tables.FAST_CREATIONS, ["subsection_id"], [other_sub_id], "section_id="+values[1])
	_insert_witn_columns(Tables.SUBSECTIONS, values)

# Движение средств
func _insert_cash_flow(values: Array) -> void:
	_insert(Tables.CASH_FLOWS, "wallet_id, section_id, subsection_id, value, date", values)
	if not select_all_id(Tables.SECTIONS, int(values[1]))[0].income: values[3] = str(float(values[3]) * -1)
	_update_record(Tables.WALLETS, ["value"], ["value+" + values[3]], int(values[0]))

# Перевод средств
func _insert_transfer(values: Array) -> void:
	_insert(Tables.CASH_FLOWS, "section_id, wallet_id, wallet_2_id, value, date", [1] + values)
	_update_value(Tables.WALLETS, "value", values[2], values[2], values[1], values[0])

# Платеж по займу
func _insert_payment(values: Array) -> void:
	_insert_witn_columns(Tables.CASH_FLOWS, values.slice(0, 2) + [2, 2] + values.slice(2))
	_update_record(Tables.WALLETS, ["value"], ["value-" + values[2]], int(values[0]))
	_update_record(Tables.LOANS, ["total"], ["total-" + values[2]], int(values[1]))

# Процент по займу
func _insert_percent(values: Array) -> void:
	_insert(Tables.CASH_FLOWS, "section_id, subsection_id, wallet_2_id, value, date", [2, 3] + values)
	_update_record(Tables.LOANS, ["total"], ["total+" + values[1]], int(values[0]))

# Заём
func _insert_loan(values: Array) -> void:
	_insert_witn_columns(Tables.LOANS, [values[0], values[2]])
	var loan_id: int = select_all(Tables.LOANS)[-1].id
	_insert(Tables.CASH_FLOWS, "wallet_2_id, section_id, subsection_id, wallet_id, value, date", [loan_id, 2, 1] + values.slice(1))
	_update_record(Tables.WALLETS, ["value"], ["value+" + values[2]], int(values[1]))

# Событие
func _insert_event(values: Array) -> void:
	if int(values[2]) == 0: values[3] = "0.0"
	_insert_witn_columns(Tables.EVENTS, values)

# Обновление записей
# Основной запрос
func _update(table: Variant, columns: Array, values: Array, where: String = "") -> void:
	var v: Array = []
	if where: where = " WHERE " + where
	for i in range([len(columns), len(values)].min()):
		v.append(columns[i] + " = " + str(values[i]))
	db.query("UPDATE `" + _get_table_name(table) + "` SET " + ",".join(v) + where + ";")

# По индексу
func _update_record(table: Variant, columns: Array, values: Array,
			idx: Variant, other: String = "") -> void:
	if other: other = "AND " + other
	_update(table, columns, values, "id = " + str(idx) + other)

# Все колонки у записи
func update_with_columns(table: Variant, idx: Variant, values: Array, other: String = "") -> void:
	_update_record(table, _get_columns(table), values, idx, other)

# Значения объекта с прибавлением одного значения и отнятием другого
func _update_value(table: Tables, value_name: String, value_1: Variant,
		value_2: Variant, idx_1: Variant, idx_2: Variant) -> void:
	_update_record(table, [value_name], [value_name + "+" + value_1], int(idx_1))
	_update_record(table, [value_name], [value_name + "-" + value_2], int(idx_2))

# Удаление пометки о новизне уведомления
func update_notifications_new() -> void: _update(Tables.NOTIFICATIONS, ["new"], [0])

# Дата последнего входа в программу
func update_last_entry() -> void:
	_update(Tables.SETTINGS, ["last_entry"], ['"'+Global.date_to_str()+'"'])

# Кошелёк для объекта быстрого создания записей
func update_fc_wallet(idx: int, wallet_id: int) -> void:
	_update_record(Tables.FAST_CREATIONS, ["wallet_id"], [wallet_id], idx)

# Раздел для объекта быстрого создания записей
func update_fc_section(idx: int, section_id: int) -> int:
	_update_record(Tables.FAST_CREATIONS, ["section_id"], [section_id], idx)
	if len(select_all(Tables.SUBSECTIONS, "section_id="+str(section_id))) == 0:
		update_fc_subsection(idx, "null")
	else:
		update_fc_subsection(idx, select_all(Tables.SUBSECTIONS,
			'title == "__SS4" AND section_id='+str(section_id))[0].id)
	return int(select("* FROM fast_creations fc LEFT JOIN sections s ON
		fc.section_id=s.id", "fc.id=" + str(idx))[0].income)

# Подраздел для быстрого создания записей
func update_fc_subsection(idx: int, subsection_id: Variant) -> void:
	_update_record(Tables.FAST_CREATIONS, ["subsection_id"], [subsection_id], idx)

# Кошелёк
func _update_wallet(idx: String, values: Array) -> void:
	_update_record(Tables.WALLETS, ["title", "value"], values, int(idx))

# Раздел
func _update_section(idx: String, values: Array) -> void:
	if values[1] == "true": values[2] = "-1.0"
	update_with_columns(Tables.SECTIONS, idx, values)

# Подраздел
func _update_subsection(idx, values) -> void:
	if select_all_id(Tables.SECTIONS, int(values[1]))[0].income == 1: values[2] = "-1.0"
	update_with_columns(Tables.SUBSECTIONS, idx, values)

# Движение средств
func _update_cash_flow(idx: String, values: Array) -> void:
	var data: Dictionary = select("cf.*, s.income FROM cash_flows cf LEFT
		JOIN sections s ON s.id=cf.section_id", "cf.id="+idx)[0]
	if not data.income: data.value *= -1
	_update_record(Tables.CASH_FLOWS, ["wallet_id", "section_id", "subsection_id", "value", "date"], values, int(idx))
	if not select_all_id(Tables.SECTIONS, int(values[1]))[0].income:
		values[3] = str(float(values[3]) * -1)
	_update_value(Tables.WALLETS, "value", values[3], data.value, values[0], data.wallet_id)

# Перевод средств
func _update_transfer(idx: String, values: Array) -> void:
	var data: Dictionary = _select_first_cash_flow(idx)
	_update_value(Tables.WALLETS, "value", data.value, data.value, data.wallet_id, data.wallet_2_id)
	_update_record(Tables.CASH_FLOWS, ["wallet_id", "wallet_2_id", "value", "date"], values, int(idx))
	_update_value(Tables.WALLETS, "value", values[2], values[2], values[1], values[0])

# Погашение займа
func _update_payment(idx: String, values: Array) -> void:
	var data: Dictionary = _select_first_cash_flow(idx)
	_update_value(Tables.WALLETS, "value", data.value, values[2], data.wallet_id, values[0])
	_update_record(Tables.CASH_FLOWS, ["wallet_id", "wallet_2_id", "value", "date"], values, int(idx))
	_update_value(Tables.LOANS, "total", values[2], data.value, values[1], data.wallet_2_id)

# Процент по займу
func _update_percent(idx: String, values: Array) -> void:
	var data: Dictionary = _select_first_cash_flow(idx)
	_update_record(Tables.CASH_FLOWS, ["wallet_2_id", "value", "date"], values, int(idx))
	_update_value(Tables.LOANS, "total", values[1], data.value, values[0], data.wallet_2_id)

# Заём
func _update_loan(idx: String, values: Array) -> void:
	update_with_columns(Tables.LOANS, idx, values)
	var last_value: Dictionary = select_all(Tables.CASH_FLOWS,
		"subsection_id=1 AND wallet_2_id="+idx)[0]
	_update_value(Tables.WALLETS, "value", values[2], last_value.value, values[1], last_value.wallet_id)
	_update(Tables.CASH_FLOWS, ["wallet_id", "value", "date"], values,
		"subsection_id=1 AND wallet_2_id=" + idx)

# Событие
func _update_event(idx: String, values: Array) -> void:
	if int(values[2]) == 0: values[3] = "0.0"
	idx = str(select_all_id(Tables.MULTIPLIED_EVENTS, int(idx))[0].event_id)
	update_with_columns(Tables.EVENTS, idx, values)

# Удаление записей
# Основной запрос
func _delete(table: Variant, where: String = "") -> void:
	if where: where = " WHERE " + where
	db.query("DELETE FROM `"+_get_table_name(table)+"`"+where+";")

# По индексу
func _delete_record(table: Variant, idx: int, other: String = "") -> void:
	if other: other = "AND " + other
	var where_idx: String = "id = " + str(idx)
	_delete(table, where_idx + other)
	_update(table, ["id"], ["id - 1"], "id > " + str(idx))
	_update(Tables.SQLITE_SEQUENCE, ["seq"], ["seq - 1"], 'name = "' + _get_table_name(table) + '"')

# Изменение индексов в таблице
func _delete_and_update_ids(table: Variant, where: String = "") -> void:
	_delete(table, where)
	_create_table(Tables.TEMP_TABLE, ["old_id INTEGER"])
	db.query("INSERT INTO temp_table (old_id) SELECT ROWID FROM " + _get_table_name(table) + ";")
	var sel: String = "(SELECT id FROM temp_table WHERE old_id = " + _get_table_name(table) + ".id)"
	_update(table, ["id"], [sel], "EXISTS " + sel)
	_update(Tables.SQLITE_SEQUENCE, ["seq"], ["(SELECT COUNT(*) FROM "+_get_table_name(table)+")"],
		'name = "' + _get_table_name(table) + '"')
	db.query("DROP TABLE temp_table;")

# Удаление и обновление данных таблицы со сдвигом индексации
func _del_upd_idx_and_values(table: Variant, idx: Variant, name_fr: String = "", other: String = "") -> void:
	_delete_and_update_ids(table, name_fr + "id = " + str(idx) + other)
	_update(table, [name_fr + "id"], [name_fr + "id - 1"], name_fr + "id > " + idx)

# Пользователь
func delete_user() -> void:
	connection_user_db()
	var data: Dictionary = select_all(Tables.USERS, 'login="'+File.config.login+'"')[0]
	DirAccess.remove_absolute(File.BasesPath + File.show_data(data.base) + ".db")
	_delete_record(Tables.USERS, data.id)
	File.clear_config()

# Быстрое создание записей
func delete_fast_creation(idx: int) -> void: _delete_record(Tables.FAST_CREATIONS, idx)

# Кошелёк
func _delete_wallet(idx: String) -> void:
	_delete_record(Tables.WALLETS, int(idx))
	_del_upd_idx_and_values(Tables.FAST_CREATIONS, idx, "wallet_")
	_del_upd_idx_and_values(Tables.CASH_FLOWS, idx, "wallet_",
		" OR (wallet_2_id=" +idx+" AND section_id=1)")
	_update(Tables.CASH_FLOWS, ["wallet_id"], ["null"],
		"wallet_id="+idx+" AND subsection_id IN (1, 2)")
	_update(Tables.CASH_FLOWS, ["wallet_2_id"], ["wallet_2_id - 1"],
		"section_id=1 AND wallet_2_id>" + idx)

# Раздел
func _delete_section(idx: String) -> void:
	_delete_record(Tables.SECTIONS, int(idx))
	_del_upd_idx_and_values(Tables.CASH_FLOWS, idx, "section_")
	_del_upd_idx_and_values(Tables.FAST_CREATIONS, idx, "section_")
	# Удаление подразделов
	_del_upd_idx_and_values(Tables.SUBSECTIONS, idx, "section_")
	_update(Tables.CASH_FLOWS, ["subsection_id"], ["subsection_id-(SELECT COUNT(s.id)
		FROM subsections s, cash_flows cf WHERE s.section_id=" + idx + " AND
		cf.subsection_id>s.id AND s.id!=cf.subsection_id)"], "section_id!=" + idx)

# Подраздел
func _delete_subsection(idx: String) -> void:
	var value: Dictionary = select_all_id(Tables.SUBSECTIONS, int(idx))[0]
	_delete_record(Tables.SUBSECTIONS, int(idx))
	_del_upd_idx_and_values(Tables.CASH_FLOWS, idx, "subsection_")
	_del_upd_idx_and_values(Tables.FAST_CREATIONS, idx, "subsection_")
	# Удаление подраздела "Другое"
	if len(select_all(Tables.SUBSECTIONS, "section_id="+str(value.section_id))) == 1:
		_delete_subsection(str(select_all(Tables.SUBSECTIONS,
			"section_id="+str(value.section_id)+' AND title = "__SS4"')[0].id))

# Движение средств
func _delete_cash_flow(idx: String) -> void:
	var data: Dictionary = select("cf.*, s.income FROM cash_flows cf LEFT JOIN
		sections s ON cf.section_id=s.id", "cf.id="+idx)[0]
	if not data.income: data.value *= -1
	_update_record(Tables.WALLETS, ["value"], ["value-" + str(data.value)], data.wallet_id)
	_delete_record(Tables.CASH_FLOWS, int(idx))

# Перевод средств
func _delete_transfer(idx: String) -> void:
	var data: Dictionary = _select_first_cash_flow(idx)
	_update_value(Tables.WALLETS, "value", data.value, data.value, data.wallet_id, data.wallet_2_id)
	_delete(Tables.CASH_FLOWS, "id=" + idx)

# Платеж по займу
func _delete_payment(idx: String) -> void:
	var data: Dictionary = _select_first_cash_flow(idx)
	_update_record(Tables.WALLETS, ["value"], ["value+" + str(data.value)], data.wallet_id)
	_update_record(Tables.LOANS, ["total"], ["total+" + str(data.value)], data.wallet_2_id)
	_delete(Tables.CASH_FLOWS, "id = " + idx)

# Процент по займу
func _delete_percent(idx: String) -> void:
	var data: Dictionary = _select_first_cash_flow(idx)
	_update_record(Tables.LOANS, ["total"], ["total-" + str(data.value)], data.wallet_2_id)
	_delete(Tables.CASH_FLOWS, "id = " + idx)

# Заём
func _delete_loan(idx: String) -> void:
	_delete_record(Tables.LOANS, int(idx))
	var values: Dictionary = select_all(Tables.CASH_FLOWS,
		"subsection_id=1 AND wallet_2_id="+idx)[0]
	if values.wallet_id != null:
		_update_record(Tables.WALLETS, ["value"], ["value-" + str(values.value)], values.wallet_id)
	_del_upd_idx_and_values(Tables.CASH_FLOWS, idx, "wallet_2_") # Удаление движений средств

# Событие
func _delete_event(idx: String) -> void:
	idx = str(select_all_id(Tables.MULTIPLIED_EVENTS, int(idx))[0].event_id)
	_delete_record(Tables.EVENTS, int(idx))
	_delete_and_update_ids(Tables.MULTIPLIED_EVENTS, "event_id = " + idx)
	_del_upd_idx_and_values(Tables.NOTIFICATIONS, idx, "event_")

# Запросы на получение данных
# Основная функция
func select(req_text: String, where: String = "", order: String = "", group: String = "") -> Array:
	if where: where = " WHERE " + where
	if group: group = " GROUP BY " + group
	if order: order = " ORDER BY " + order
	db.query("SELECT " + req_text + where + group + order + ";")
	return db.query_result

# Все записи из таблицы
func select_all(table: Variant, where: String = "", order: String = "") -> Array:
	return select("* FROM "+_get_table_name(table), where, order)

# Все записи из таблицы по индексу
func select_all_id(table: Variant, idx: int, other: String = "") -> Array:
	if other: other = "AND " + other
	return select_all(table, "id = " + str(idx) + other)

# Названия объекта под определенным индексом
func _select_title(table: Tables, idx: int) -> String:
	return select("title FROM " + _get_table_name(table), "id = "+str(idx))[0].title

# Количество дней в текущем месяце
func select_day_count(date: String) -> int:
	if not db: return 30
	return int(select("STRFTIME('%d', DATE('"+date+"', 'start of month',
		'+1 month', '-1 day')) day_count")[0].day_count)

# Получение даты последнего входа в программу
func select_last_entry() -> String: return select("last_entry FROM settings")[0].last_entry

# Пользователь, в аккаунт которого совершается вход
func select_user() -> Dictionary:
	var user_data: Array = []
	for i in File.config.keys(): if i in _get_columns(Tables.USERS):
		user_data.append(i + '="' + File.config[i] + '"')
	return select_all(Tables.USERS, "AND ".join(user_data))[0]

# Настройки
func select_settings() -> Dictionary: return select_all(Tables.SETTINGS)[0]

# Текущий суммарный бюджет
func select_wallets_sum() -> float:
	return select("COALESCE((SELECT COALESCE(SUM(value), 0.0) FROM wallets)-
		(SELECT COALESCE(SUM(total), 0.0) FROM loans), 0.0) value")[0].value

# Сумма движений средств за время до выбранной даты
func select_past_funds_movements(date: String = Global.date_to_str()) -> float:
	return select(_funds_movements_text(), where_date(date, "date", "<"))[0].value

# Значение движения средств
func select_funds_movements() -> float:
	return select(_funds_movements_text(), where_date())[0].value

# Движение средств по индексу
func _select_first_cash_flow(idx: Variant) -> Dictionary:
	return select_all_id(Tables.CASH_FLOWS, int(idx))[0]

# Сумма движений средств распределенных по дням
func select_cash_flow_graphics(where: String, date: String = Global.date_to_str()) -> Array:
	if where: where = " AND " + where
	return select("SUM(CASE WHEN cf.section_id=1 OR cf.subsection_id=3 THEN 0
		WHEN cf.subsection_id=2 OR (s.income=0 AND s.month_limit<>-1) THEN
		cf.value * -1 ELSE cf.value END) value, strftime('%d', cf.date) day FROM
		cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id ",
		where_date(date) + where, "", "cf.date")

# Размноженные события
func select_multiplied_events_list(where: String = "") -> Array:
	if where: where = "CAST(strftime('%d', date) AS INTEGER) = "+where
	return select_all(Tables.MULTIPLIED_EVENTS, where, "date")

# Дни с по крайней мере одним событием
func select_event_days(where: String = "") -> Array:
	return select("date FROM multiplied_events", where, "", "date")

# Поиск непрочитанных уведомлений
func presence_unread_notifications() -> bool:
	return select("COUNT(id) count FROM notifications", "new")[0].count != 0

# События для создания уведомлений
func select_notif_events(date: String) -> Array:
	return select_all(Tables.MULTIPLIED_EVENTS, 'date <= "'+Global.date_to_str()+
		'" AND date > "'+date+'" AND strftime("%m", date) = strftime("%m", "'+date+'")')

# Быстрые создания записей
func select_fast_creations_list() -> Array:
	return select("fc.*, w.title, s.title, s.income FROM fast_creations fc LEFT
		JOIN sections s ON fc.section_id=s.id LEFT JOIN wallets w ON fc.wallet_id=w.id")

# Общая информация об объекте
func select_inf_data(where: String, idx: int, type: Global.Pages) -> Dictionary:
	if where == "": return {}
	var value: Dictionary = {}
	match type:
		Global.Pages.WALLET:
			value = select("*, value as total FROM wallets", "id="+str(idx))[0]
			value.merge(select("coalesce(COUNT(cf.id), 0) count FROM cash_flows cf", where)[0])
			return _update_wallets_list(value)
		Global.Pages.LOAN:
			value = select("l.*, (SELECT value FROM cash_flows WHERE subsection_id=1
				AND wallet_2_id=l.id) value FROM loans l", "l.id=" + str(idx))[0]
			value["percent"] = _select_loan_percent(idx)
			return value
	return select_sections_list("s.id = "+str(idx))[0]

# Средний процент займа
func _select_loan_percent(idx: int) -> String:
	var summ: float = 0.0
	var result: float = 0.0
	var count: int = 0
	for i in select_all(Tables.CASH_FLOWS, "section_id=2 AND wallet_2_id=" + str(idx)):
		match i.subsection_id:
			1: summ = i.value
			2: summ -= i.value
			3:
				result += (i.value * 100) / summ
				summ += i.value
				count += 1
	if count == 0: return str(0) + " %"
	return str(int(round(result / count))) + " %"

# Значения для построения графика займов
func select_loan_graphics(idx: int) -> Array:
	if idx == 0: return []
	return select("SUM(IIF(subsection_id=2, value*-1, value)) value, date as day
		FROM cash_flows", "wallet_2_id=" + str(idx) + " AND section_id=2", "", "day")

# Сумма займа до выбранной даты
func get_loan_total(idx: int, w2idx: int, date: String) -> float:
	if not db: return 0.0
	var value: Variant = select("SUM(IIF(subsection_id == 2, value * -1,
		value)) total FROM cash_flows", 'section_id=2 AND date<="' + date +'
		" AND (date!="' + date + '" OR id!=' + str(idx) + ") AND
		wallet_2_id=" + str(w2idx))[0].total
	return 0.0 if value == null else value

# Проверки данных из таблицы для создания / изменения объектов
# Распределение
func match_check(page_type: Global.Pages) -> void:
	match page_type:
		Global.Pages.TRANSFER: if not check_wallet_count(1): return
		Global.Pages.PERCENT: if not check_loan_count(): return
		Global.Pages.PAYMENT:
			if not (check_wallet_count() and check_loan_count()): return
		Global.Pages.CASH_FLOW:
			if not (check_wallet_count() and check_values_count(Tables.SECTIONS, 2)): return
	SF.op_w(page_type)

# Количество объектов
func check_values_count(table: Variant, count: int = 0, where: String = "") -> bool:
	return len(select_all(table, where)) > count

# Количество кошельков
func check_wallet_count(count: int = 0) -> bool:
	return check_values_count(Tables.WALLETS, count)

# Наличие достаточного количества кошельков и разделов для создания движений средств
func check_sections_and_wallets() -> bool:
	return select("COUNT(id) c FROM wallets")[0].c >= 1 and select("COUNT(id) c FROM sections")[0].c > 2

# Количество займов
func check_loan_count(where: String = "") -> bool:
	if where: where = " AND " + where
	return check_values_count(Tables.LOANS, 0, "total > 0" + where)

# Существование выбранного пользователя
func select_existence_user(login: bool) -> bool:
	var req: String = 'login="' + File.config["login"] + '"'
	if login: req += ' AND password="' + File.config["password"] + '"'
	var res: Array = select("COUNT(id)==" + str(int(login)) + " res FROM users", req)
	if len(res) == 0: return false
	return res[0].res

# Минимальная дата, от которой можно провести транзакции по займам
func loan_check_first_date(idx: int, date: String) -> bool:
	return bool(select('"' + date + '"<(SELECT date FROM cash_flows WHERE
		subsection_id=1 AND wallet_2_id=' + str(idx) + ") res")[0].res)

# Наличие записи с определенным именем
func _check_name_in_table(obj_name: String, table_idx: int, idx: int, section_id: int = 0) -> bool:
	return len(select_all(Tables.find_key(table_idx), 'title="' + obj_name +
		'" AND id!=' + str(idx) + (" AND section_id=" + str(section_id) if section_id > 0 else ""))) == 0

# Наличие записи с определенным именем в таблице кошельков
func check_wallet_name(obj_name: String, idx: int) -> bool:
	return _check_name_in_table(obj_name, 0, idx)

# Наличие записи с определенным именем в таблице разделов
func check_section_name(obj_name: String, idx: int) -> bool:
	return _check_name_in_table(obj_name, 1, idx)

# Наличие подстатьи с определенным именем в таблице подразделов
func check_subsection_name(obj_name: String, idx: int, section_id: int) -> bool:
	return _check_name_in_table(obj_name, 2, idx, section_id)

# Получение данных для списка на странице
# Распределитель
func match_select(list_element: ObjectVariants, filter_data: Dictionary) -> Array:
	match list_element:
		ObjectVariants.WALLET:
			return select("*, (SELECT cf.date FROM cash_flows cf WHERE
				(cf.section_id!=2 AND cf.wallet_2_id=w.id) OR cf.wallet_id=w.id
				ORDER BY cf.date DESC) last_date FROM wallets w",
				filter_data.where, filter_data.order)
		ObjectVariants.SECTION:
			return select_sections_list(filter_data.where, filter_data.date, filter_data.order)
		ObjectVariants.SUBSECTION:
			return select("ss.*, s.income, COALESCE(j.v, 0.0) value, j.last_date,
				j.last_id FROM subsections ss LEFT JOIN sections s ON
				ss.section_id=s.id LEFT JOIN (SELECT SUM(value) v, date
				last_date, id last_id, subsection_id FROM cash_flows cf GROUP
				BY section_id, subsection_id) j ON j.subsection_id = ss.id",
				"ss.section_id=" + filter_data.where.split(" = ")[-1],
				"last_date DESC, id DESC")
		ObjectVariants.CASH_FLOW:
			var where: String = filter_data.where
			if filter_data.date != "":
				if where != "": where = " AND " + where
				where = where_date(filter_data.date) + where
			return select("cf.*, s.title, COALESCE(ss.title, '') sub_title,
				s.income, w.title wallet_title FROM `cash_flows` cf LEFT JOIN
				sections s ON cf.section_id=s.id LEFT JOIN wallets w ON
				cf.wallet_id=w.id LEFT JOIN subsections ss ON
				cf.subsection_id=ss.id", where, filter_data.order)
		ObjectVariants.LOAN:
			return select("l.*, cf.wallet_id, w.title wallet_title, cf.value
				FROM loans l LEFT JOIN cash_flows cf ON cf.subsection_id=1 AND
				cf.wallet_2_id=l.id LEFT JOIN wallets w ON cf.wallet_id=w.id",
				filter_data.where, filter_data.order)
		ObjectVariants.EVENT: return select_multiplied_events_list()
		ObjectVariants.REPORT_W:
			var wd: String = where_date(filter_data.date, "cf.date")
			return select("w.id, w.title, " + _coalesce_select_fr() +
				"WHERE ((cf.wallet_id=w.id AND (s.income=1 OR cf.subsection_id=1))
				OR (cf.section_id=1 AND cf.wallet_2_id=w.id)) AND " +
				wd + "), 0.0) income, " + _coalesce_select_fr() + "WHERE
				((cf.wallet_id=w.id AND ((s.income=0 AND cf.section_id>2) OR
				cf.subsection_id = 2)) OR (cf.section_id=1 AND cf.wallet_id=w.id))
				AND " + wd + "), 0.0) expenditure, COALESCE((SELECT
				SUM(IIF((cf.section_id=1 and cf.wallet_id=w.id) OR cf.subsection_id=2
				OR (s.income=0 and cf.section_id>2 AND cf.wallet_id=w.id),
				cf.value*-1, cf.value)) FROM cash_flows cf LEFT JOIN sections s
				ON cf.section_id=s.id WHERE (cf.wallet_id=w.id OR (cf.wallet_2_id=w.id
				and cf.section_id=1)) AND " + where_date(filter_data.date, "cf.date", "<") +
				"), 0.0) cash_flow FROM wallets w")
		ObjectVariants.REPORT_S:
			var wd: String = where_date(filter_data.date, "cf.date")
			return select("* FROM (SELECT t.id, t.title," + _coalesce_select_fr() +
				"WHERE (s.income=1 OR cf.subsection_id=1) AND cf.section_id=t.id
				AND " + wd + "), 0.0) income, " + _coalesce_select_fr() +
				"WHERE s.income=0 AND (cf.section_id>2 OR cf.subsection_id=2)
				AND cf.section_id=t.id AND " + wd + "), 0.0) expenditure FROM
				sections t WHERE t.id != 1) WHERE (income != 0 OR expenditure != 0)")
		ObjectVariants.NOTIFICATION:
			return select("e.title, n.* FROM notifications n LEFT JOIN
				events e ON n.event_id=e.id", "", "n.date DESC")
		ObjectVariants.FAST_CREATION: return select_fast_creations_list()
		ObjectVariants.WALLET_TRANSACTION:
			var idx: String = filter_data.where.split(")")[0].split("_id = ")[-1]
			return select("s.id, s.title, COUNT(cf.id) count, SUM(IIF((NOT
				s.income AND cf.section_id!= 1 AND cf.subsection_id!=1)
				OR cf.subsection_id = 2 OR (cf.section_id = 1 AND cf.wallet_id = " +
				idx + "), cf.value * -1, cf.value)) value FROM cash_flows cf
				LEFT JOIN sections s ON s.id = cf.section_id ",
				filter_data.where, "", "cf.section_id")
	return []

# Запрос на получение списка разделов
func select_sections_list(where: String = "",
		date: String = Global.date_to_str(), order: String = "") -> Array:
	if 'LIKE "%%"' not in where: where += " AND s.id > 2"
	return select("s.*, COALESCE(j.v, 0.0) value, j.last_date, j.last_id FROM
		sections s LEFT JOIN (SELECT cf.section_id, SUM(cf.value) v, cf.date
		last_date, cf.id last_id FROM cash_flows cf WHERE " + where_date(date) +
		" GROUP BY cf.section_id) j ON s.id=j.section_id", where, order)

# Изменение строк данных для списков на странице
# Распределитель
func match_update_list_element(list_element: ObjectVariants, line: Dictionary, parent = null) -> Dictionary:
	match list_element:
		ObjectVariants.WALLET: return _update_wallets_list(line)
		ObjectVariants.SECTION, ObjectVariants.SUBSECTION:
			line["marker"] = ColorScheme.get_color(parent.obj_count(), len(parent.lines.change_list) + parent.obj_count())
			line["progress"] = (100. * line.value) / line.month_limit
		ObjectVariants.CASH_FLOW:
			match line.section_id:
				1: line["wallet_2_title"] = _select_title(Tables.WALLETS, line.wallet_2_id)
				2:
					if line.subsection_id == 1:
						line["wallet_2_title"] = _select_title(Tables.LOANS, line.wallet_2_id)
					else:
						line["wallet_2_title"] = line.wallet_title
						line.wallet_title = _select_title(Tables.LOANS, line.wallet_2_id)
						var save_id: int = line.wallet_id if line.wallet_id else 0
						line.wallet_id = line.wallet_2_id
						line.wallet_2_id = save_id
				_: if line.income:
					line["wallet_2_title"] = line.wallet_title
					line.wallet_2_id = line.wallet_id
		ObjectVariants.LOAN: line["percent"] = _select_loan_percent(line.id)
		ObjectVariants.EVENT:
			if line.event_type == 1:
				line["profit_accounting"] = select(_table_sum(Tables.WALLETS))[0].value + \
					select(_table_sum(Tables.MULTIPLIED_EVENTS), 'event_type=2 AND date<"'+line.date+'"')[0].value - line.value
		ObjectVariants.REPORT_W: line["value"] = line.cash_flow + line.income - line.expenditure
	return line

# Запрос на изменение списка кошельков
func _update_wallets_list(line: Dictionary, date: String = Global.date_to_str()) -> Dictionary:
	var value: Array = select("SUM(IIF((cf.section_id=1 and cf.wallet_id=" +
		str(line.id) + ")OR cf.subsection_id=2 OR (s.income=0 and cf.section_id>2
		and cf.wallet_id=" + str(line.id) + "), cf.value*-1, cf.value)) value
		FROM cash_flows cf LEFT JOIN sections s ON cf.section_id=s.id",
		"(cf.wallet_id=" + str(line.id) + " or (cf.wallet_2_id=" + str(line.id) +
		" and cf.section_id=1)) AND " + where_date(date, "cf.date"))
	line["cash_flow"] = value[0].value if value[0].value else 0.
	return line

# Распределение запросов для получения объектов таблиц на странице информации
func match_elem(idx: String, obj_type: Global.Pages) -> Dictionary:
	match obj_type:
		Global.Pages.WALLET: return select_all_id(Tables.WALLETS, int(idx))[0]
		Global.Pages.SECTION: if int(idx) > 2:
			var value: Dictionary = select_all_id(Tables.SECTIONS, int(idx))[0]
			if value.month_limit == -1.0: value.month_limit = 0.0
			return value
		Global.Pages.SUBSECTION: if int(idx) > 3:
			var value: Dictionary = select_all_id(Tables.SUBSECTIONS, int(idx))[0]
			if value.title == "__SS4": return {}
			if value.month_limit == -1.0: value.month_limit = 0.0
			return value
		Global.Pages.LOAN:
			if select("COUNT(id) count FROM cash_flows", "subsection_id IN
				(2, 3) AND wallet_2_id=" + idx)[0].count > 0: return {}
			return select("cf.*, l.title FROM cash_flows cf LEFT JOIN loans l
				ON cf.wallet_2_id=l.id", "subsection_id=1 AND wallet_2_id=" + idx)[0]
		Global.Pages.EVENT:
			idx = str(select_all_id(Tables.MULTIPLIED_EVENTS, int(idx))[0].event_id)
			return select_all_id(Tables.EVENTS, int(idx))[0]
		_: return _select_first_cash_flow(idx)
	return {}

# Распределение обработки действий с объектами
func match_actions(action_type: ActionTypes, obj_type: Global.Pages, idx: String, values: Array = []) -> void:
	match action_type:
		ActionTypes.INSERT: call("_insert_"+Global.enum_key(Global.Pages, obj_type), values)
		ActionTypes.UPDATE: call("_update_"+Global.enum_key(Global.Pages, obj_type), idx, values)
		ActionTypes.DELETE: call("_delete_"+Global.enum_key(Global.Pages, obj_type), idx)

# Очистка данных
# Движения средств
func clear_cash_flows() -> void:
	_delete_and_update_ids(Tables.CASH_FLOWS, 'CAST(strftime("%Y", "'+Global.date_to_str()+\
		'") AS INTAGER) - CAST(strftime("%Y", date) AS INTAGER) > 2')

# События
func clear_events() -> void:
	var lines: Array = select("id FROM events", _month_difference() + " AND repetition_rate = 0")
	for i in lines: _delete_and_update_ids(Tables.NOTIFICATIONS, "event_id = " + str(i.id))
	_delete_and_update_ids(Tables.EVENTS, _month_difference() + " AND repetition_rate = 0")

# Займы
func clear_loans() -> void:
	var fragment: String = "FROM cash_flows WHERE wallet_2_id IN (SELECT id FROM
		loans WHERE total=0) AND subsection_id=2 AND" + _month_difference() + ")"
	_delete_and_update_ids(Tables.CASH_FLOWS, "section_id=2 AND wallet_2_id IN (SELECT wallet_2_id AS id " + fragment)
	_delete(Tables.LOANS, "id IN (SELECT wallet_2_id AS id " + fragment)
	_update(Tables.CASH_FLOWS, ["wallet_2_id"], ["wallet_2_id-(SELECT COUNT(id)" + fragment])

# Уведомления
func clear_notifications() -> void:
	_delete(Tables.NOTIFICATIONS)
	_update(Tables.SQLITE_SEQUENCE, ["seq"], [0], 'name = "notifications"')
