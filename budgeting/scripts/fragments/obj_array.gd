extends ScrollContainer
# Подключение пути к объекту в сцене
@onready var Objects = $Objects

# Перечисление
enum ListObjects {WALLET, SECTION, CASH_FLOW, LOAN, EVENT, WALLET_TRANSACTION} # Объекты списка

# Экспортируемая переменная
@export var obj: Request.ObjectVariants = Request.ObjectVariants.EVENT # Выбранный объект списка
# Переменные
var obj_path: Resource = null # Подгружаемый объект
var lines: Array = [] # Список объектов
var change_list: Array = [] # Список для изменения

# Создание сцены
func _ready() -> void: obj_path = load("res://scenes/fragments/list_elements/"+Global.enum_key(Request.ObjectVariants, obj)+".tscn")
	
# Получение количества объектов
func obj_count() -> int: return Objects.get_child_count() - 1

# Существуют ли объекты в списке
func lack_objects() -> bool: return Objects.get_child_count() > 1

# Динамическое заполнение страницы
func _process(_delta: float) -> void:
	if len(lines) > 0: Global.add_new_child(Objects, obj_path, [lines.pop_front()])
	if len(change_list) > 0: lines.append(Request.match_update_list_element(obj, change_list.pop_front(), self))

# Получение данных для списка
func update_data(filter: Variant = {}) -> void:
	Global.clear_scene(Objects)
	Objects.add_child(obj_path.instantiate()) # Добавление первого элемента списка
	change_list = Request.match_select(obj, Global.get_filter(filter))
	lines = []

# Перенести в Requests
# Получение списка элементов списка
#func select() -> Array:
	#match obj:
		#ListObjects.WALLET: return Request.select_wallets_list(data.where, data.order)
		#ListObjects.WALLET_TRANSACTION: return Request.select_general_sections_cash_movement(get_parent().id, data.date)
		#ListObjects.LOAN: return Request.select_loan_list(data.where, data.order)
		#ListObjects.SECTION: return Request.select_sections(data.where, data.date, data.order)
		#ListObjects.CASH_FLOW: return Request.select_cash_flows(data.where, data.date, data.order)
		#ListObjects.EVENT: return Request.select_events(data.date)
	#return []
