extends ScrollContainer
# Подключение пути к объектам в сцене
@onready var Objects = $Objects

# Экспортируемая переменная
@export var obj: Request.ObjectVariants = Request.ObjectVariants.EVENT # Выбранный объект списка

# Перечисление
enum ListObjects {WALLET, WALLET_TRANSACTION, SECTION, CASH_FLOW, LOAN, EVENT} # Объекты списка

# Переменные
var obj_path: Resource = null # Подгружаемый объект
var lines: Array = [] # Список объектов для создания на странице

# Параметры для смегчения динамического создания объектов
var change_list: Array = []

# Создание сцены
func _ready() -> void: obj_path = load("res://scenes/fragments/list_elements/"+Global.enum_key(Request.ObjectVariants, obj)+".tscn")
	
# Получение количества объектов
func obj_count() -> int: return Objects.get_child_count() - 1

# Существуют ли объекты в списке
func lack_objects() -> bool: return Objects.get_child_count() > 1

# Динамическое заполнение страницы
func _process(_delta: float) -> void:
	# Добавление объекта на экран
	if len(lines) > 0:
		Objects.add_child(obj_path.instantiate())
		Objects.get_child(-1).set_values(lines.pop_front())
	# Обновление списка при необходимости дополнительного изменения данных
	if len(change_list) > 0: lines.append(Request.match_update_list_element(obj, change_list.pop_front(), self))

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

# Получение данных для списка
func data_update(filter: ColorRect) -> void:
	# Очистка списка
	for i in Objects.get_children():
		i.queue_free()
		Objects.remove_child(i)
	# Добавление первого элемента списка
	Objects.add_child(obj_path.instantiate())
	lines = []
	change_list = Request.match_select(obj, filter.get_filter())

# Заполнение страницы - удалить это
func update_page(_close_page: String = ""):
	pass
	#for i in Objects.get_children():
		#i.queue_free()
		#Objects.remove_child(i)
	#Objects.add_child(obj_path.instantiate())
	#Objects.get_child(-1).color = Color.html("#dfdfdf")
	#lines = select()
	#if get_parent().get("update_page"):	get_parent().update_page(close_page)
