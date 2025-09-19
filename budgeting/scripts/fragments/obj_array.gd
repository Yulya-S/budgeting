extends ScrollContainer
# Подключение пути к объектам в сцене
@onready var Objects = $Objects

# Экспортируемая переменная
@export var obj: ListObjects = ListObjects.WALLET # Выбранный объект списка

# Перечисление
enum ListObjects {WALLET, WALLET_TRANSACTION, SECTION, CASH_FLOW, LOAN, EVENT} # Объекты списка

# Переменные
var data: Dictionary = {"where": "", "date": Time.get_date_string_from_system(), "order": ""} # Фрагменты запроса
var obj_path: Resource = null # Подгружаемый объект
var lines: Array = [] # Список объектов для создания на странице

# Создание сцены
func _ready() -> void:
	obj_path = load("res://scenes/fragments/list_elements/"+Global.enum_key(ListObjects, obj)+".tscn")
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
func set_data(where: String = "", date: String = "", order: String = "") -> void:
	if where != "" or data.where != "": data.where = where
	if date != "": data.date = date
	if order != "" or data.order != "": data.order = order
	update_page()

# Получение списка элементов списка
func select() -> Array:
	match obj:
		ListObjects.WALLET: return Request.select_wallets_list(data.where, data.order)
		ListObjects.WALLET_TRANSACTION: return Request.select_general_sections_cash_movement(get_parent().id, data.date)
		ListObjects.LOAN: return Request.select_loan_list(data.where, data.order)
		ListObjects.SECTION: return Request.select_sections(data.where, data.date, data.order)
		ListObjects.CASH_FLOW: return Request.select_cash_flows(data.where, data.date, data.order)
		ListObjects.EVENT: return Request.select_events(data.where, data.date, data.order)
	return []

# Заполнение страницы
func update_page(close_page: String = ""):
	for i in Objects.get_children():
		i.queue_free()
		Objects.remove_child(i)
	Objects.add_child(obj_path.instantiate())
	Objects.get_child(-1).color = Color.html("#dfdfdf")
	lines = select()
	if get_parent().get("update_page"):	get_parent().update_page(close_page)
