extends ScrollContainer
# Подключение пути к объекту в сцене
@onready var Objects = $Objects
# Экспортируемая переменная
@export var obj: Request.ObjectVariants = Request.ObjectVariants.EVENT # Выбранный объект списка
# Переменная
@onready var lines: ArrayLines = ArrayLines.new("res://scenes/fragments/list_elements/"+Global.enum_key(Request.ObjectVariants, obj)+".tscn") # Объект для создания строк списков

# Получение количества объектов
func obj_count() -> int: return Objects.get_child_count() - 1

# Существуют ли объекты в списке
func lack_objects() -> bool: return Objects.get_child_count() > 1

# Динамическое заполнение страницы
func _process(_delta: float) -> void: lines.add_obj(Objects, obj, self)

# Получение данных для списка
func update_data(filter: Variant = {}) -> void: lines.clear(Request.match_select(obj, Global.get_filter(filter)), Objects)

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
