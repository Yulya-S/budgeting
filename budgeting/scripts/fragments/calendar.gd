extends Node
class_name Calendar
# Подключение пути к объекту в сцене
@onready var Cells = $Cells
# Экспортируемая переменная
@export var cell_path: Resource = load("res://scenes/pages/events/cell.tscn") # Сцена ячейки календаря
# Переменные
var date: Dictionary = Global.date # Выбранная дата
var day_count: int = 30 # Количество дней в выбранном месяце

# Постепенное создание элементов страницы
func _process(_delta: float) -> void: if date != {} and _end_create(): Global.add_new_child(Cells, cell_path, [Cells.get_child_count() - date.weekday + 1, _date_comparison(), _date_comparison( "<"), day_count])
		
# Сравнение дат
func _date_comparison(operator: String = "==") -> bool: return Global.date_comparison(Global.date, date, operator, false)

# Проверка завершено ли создание ячеек календаря
func _end_create() -> bool: return Cells.get_child_count() < day_count + date.weekday - 1 or Cells.get_child_count() % 7 != 0

# Обновление данных
func update_data(new_filter: ColorRect) -> void:
	Global.clear_scene(Cells)
	# Обновление данных для заполнения страницы
	day_count = Request.select_day_count(new_filter.get_filter().date)
	date = Global.date_to_dict(new_filter.filter.date)
	if date.weekday == 0: date.weekday = 7 # Смена индекса дня недели
