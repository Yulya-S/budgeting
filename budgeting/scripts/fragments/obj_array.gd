extends ScrollContainer
# Подключение пути к объекту в сцене
@onready var Objects = $Objects
# Экспортируемые переменные
@export var obj: Request.ObjectVariants = Request.ObjectVariants.EVENT # Выбранный объект списка
@export var first_line: bool = true # Будет ли создан заголовок списка
# Переменная
@onready var lines: ArrayLines = ArrayLines.new("res://scenes/fragments/list_elements/"+Global.enum_key(Request.ObjectVariants, obj)+".tscn") # Объект для создания строк списков

# Применение размера VBoxContainer
func _ready() -> void: if not first_line: Objects.alignment = VBoxContainer.ALIGNMENT_END

# Смена объекта списка
func update_obj(new_obj: Request.ObjectVariants) -> void:
	obj = new_obj
	lines = ArrayLines.new("res://scenes/fragments/list_elements/"+Global.enum_key(Request.ObjectVariants, obj)+".tscn")

# Изменение размера контейнера
func set_container_size(new_size: Vector2) -> void:
	size = new_size
	Objects.custom_minimum_size = new_size

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
