extends Node
class_name Calendar
# Подключение путей к объектам в сцене
@onready var Cells = $Cells

# Переменные
@export var cell_path: Resource = load("res://scenes/pages/events/cell.tscn") # Путь к сцене ячеек календаря
var date: Dictionary = {} # Сохранение выбранной даты
var day_count: int = 30 # Количество дней в выбранном месяце

# Постепенное создание элементов страницы
func _process(_delta: float) -> void:
	if _end_create():
		Cells.add_child(cell_path.instantiate())
		Cells.get_child(-1).set_values(Cells.get_child_count() - date.weekday, Global.date_comparison(Global.date, date, "==", false),
			Global.date_comparison(Global.date, date, "=<", false), day_count)

# Проверка завершено ли создание ячеек календаря
func _end_create() -> bool: return Cells.get_child_count() < day_count + date.weekday - 1 or Cells.get_child_count() % 7 != 0

# Обновление данных
func update_data(new_filter: ColorRect) -> void:
	# Очистка календаря
	for i in Cells.get_children():
		i.queue_free()
		Cells.remove_child(i)
	# Получение новых данных для создания на странице
	date = Global.date_to_dict(new_filter.get_filter().date)
	if date.weekday == 0: date.weekday = 7 # Смена индекса дня недели
	day_count = Request.select_day_count(Global.date_to_str(date))	
