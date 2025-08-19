extends ScrollContainer
# Подключение пути к объектам в сцене
@onready var Objects = $Objects

# Экспортируемые переменные
@export var table: Request.Tables = Request.Tables.WALLETS # Таблица связанная со списком
@export var data: Dictionary = {"columns": "*", "where": "", "order": "",
	"date": Time.get_date_string_from_system()} # Фрагменты запроса
@export var obj_name: String = "wallet"

# Переменные
var obj_path: Resource = null # Подгружаемый объект
var lines: Array = [] # Список объектов для создания на странице

# Создание сцены
func _ready() -> void:
	# Создание сцены объекта
	obj_path = load("res://scenes/fragments/"+obj_name+".tscn")
	# Подключение сигнала
	Global.connect("update_page", Callable(self, "update_page"))
	
# Получение количества объектов
func obj_count() -> int: return Objects.get_child_count()

# Существуют ли объекты в списке
func lack_objects() -> bool: return Objects.get_child_count() > 1

# Динамическое заполнение страницы
func _process(_delta: float) -> void:
	if len(lines) > 0:
		Objects.add_child(obj_path.instantiate())
		Objects.get_child(-1).set_values(lines.pop_front())
	
# Изменение параметров запроса
func set_data(columns: String = "", where: String = "", order: String = "", date: String = "") -> void:
	if columns != "": data.columns = columns
	if where != "" or data.where != "": data.where = where
	if order != "" or data.order != "": data.order = order
	if date != "": data.date = date
	update_page()

# Получение списка элементов списка
func select() -> Array:
	match table:
		Request.Tables.CASH_FLOWS:
			if get_parent().get("id"): return Request.select_general_sections_cash_movement(get_parent().id, data.date)
			return Request.select_cash_flows(data.where, data.date)
		Request.Tables.SECTIONS: return Request.select_sections(data.where, data.date)
		Request.Tables.LOANS: if get_parent().get("id"): return Request.select_loan_progress(get_parent().id)
	return Request.select(table, data.columns, data.where, data.order)

# Заполнение страницы
func update_page():
	for i in Objects.get_children():
		i.queue_free()
		Objects.remove_child(i)
	Objects.add_child(obj_path.instantiate())
	Objects.get_child(-1).color = Color.html("#dfdfdf")
	lines = select()
	if len(lines) > 0 and null in lines[0].values(): lines = []
	if get_parent().get("update_page"): get_parent().update_page()
