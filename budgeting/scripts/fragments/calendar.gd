extends Node
class_name Calendar
# Подключение пути к объекту в сцене
@onready var Cells = $Cells
# Экспортируемая переменная
@export var cell_path: Resource = load("res://scenes/pages/events/cell.tscn") # Сцена ячейки календаря
# Переменная
@onready var date: NewDate = NewDate.new(Global.get_date()) # Выбранная дата

# Постепенное создание элементов страницы
func _process(_delta: float) -> void: if _end_create(): Global.add_new_child(Cells, cell_path, [Cells.get_child_count() - date.weekday(), _date_comparison(), _date_comparison( ">"), date.day_count])
		
# Сравнение дат
func _date_comparison(operator: String = "==") -> bool: return date.date_comparison(Global.get_date(), operator)

# Проверка завершено ли создание ячеек календаря
func _end_create() -> bool: return Cells.get_child_count() != date.calendar_cells()

# Обновление данных
func update_data(new_filter: ColorRect) -> void:
	Global.clear_scene(Cells)
	date.set_value(new_filter.get_filter().date)
