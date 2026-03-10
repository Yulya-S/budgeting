extends ScrollContainer
# Подключение пути к объекту в сцене
@onready var Objects = $Objects
# Экспортируемые переменные
@export var obj: Request.ObjectVariants = Request.ObjectVariants.EVENT # Выбранный объект списка
@export var first_line: bool = true # Будет ли создан заголовок списка
# Переменная объекта для создания строк списка
@onready var lines: ArrayLines = ArrayLines.new(Global.enum_key(Request.ObjectVariants, obj))

# Применение размера VBoxContainer
func _ready() -> void: if not first_line: Objects.alignment = VBoxContainer.ALIGNMENT_END

# Смена объекта списка
func update_section_inf_obj(subsection: bool) -> void:
	obj = Request.ObjectVariants.SUBSECTION if subsection else Request.ObjectVariants.CASH_FLOW
	lines = ArrayLines.new("section" if subsection else "cash_flow")

# Изменение размера контейнера
func set_container_size(new_size: Vector2) -> void:
	Objects.custom_minimum_size = new_size
	size = new_size

# Получение количества объектов
func obj_count() -> int: return Objects.get_child_count() - 1

# Существуют ли объекты в списке
func lack_objects() -> bool: return Objects.get_child_count() > 1

# Динамическое заполнение страницы
func _process(_delta: float) -> void: lines.add_obj(Objects, obj, self)

# Получение данных для списка
func update_data(filter: Variant = {}) -> void: lines.clear(Request.match_select(obj, Global.get_filter(filter)), Objects)
