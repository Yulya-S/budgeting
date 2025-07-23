extends ScrollContainer
# Подключение путей к объектам в сцене
@onready var Objects = $Objects

# Экспортируемые параметры
@export var table: Request.Tables = Request.Tables.WALLETS # Таблица связанная со списком
@export var data: Dictionary = {"columns": "*", "where": "", "order": "", "date": Time.get_date_string_from_system()}

# Параметры
var obj_path: Resource = null # Подгружаемый объект
var lines: Array = [] # Список объектов для создания на странице

# Создание сцены
func _ready() -> void:
	# Подгрузка сцены объекта
	var obj_name: String = Global.enum_key(Request.Tables, table)
	obj_name[-1] = "."
	obj_path = load("res://scenes/fragments/"+obj_name+"tscn")
	# Подключение сигналов
	Global.connect("update_page", Callable(self, "update_page"))
	update_page()
	
# Получение количества объектов
func obj_count() -> int: return len(Objects)

# Существуют ли объекты в списке
func lack_objects() -> bool: return len(Objects) > 1

# Динамическое заполнение страницы
func _process(_delta: float) -> void:
	if len(lines) > 0:
		Objects.add_child(obj_path.instantiate())
		Objects.get_child(-1).set_values(lines.pop_front())

# Изменение параметров запроса
func set_data(columns: String = "", where: String = "", order: String = "", date: String = "") -> void:
	if columns != "": data.columns = columns
	if where != "": data.where = where
	if order != "": data.order = order
	if date != "": data.date = date
	update_page()
	
func _select() -> Array:
	match table:
		Request.Tables.CASH_FLOWS: if data.where: return Request.select_cash_flow_sum(int(data.where.split("=")[1]), data.date)
		Request.Tables.SECTIONS: return Request.select_sections(data.date, data.where)
	return Request.select(table, data.columns, data.where, data.order)

# Заполнение страницы	
func update_page():
	for i in Objects.get_children():
		i.queue_free()
		Objects.remove_child(i)
	Objects.add_child(obj_path.instantiate())
	Objects.get_child(-1).color = Color.html("#dfdfdf")
	lines = _select()
	if get_parent().get("update_page"): get_parent().update_page()
