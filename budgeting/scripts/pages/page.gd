extends Control
class_name Page
# Подключение пути к объектам в сцене
@onready var Objects = get_node_or_null("ObjArray")
@onready var Filter = get_node_or_null("Filter")

# Подключение сигнала
func _ready() -> void: Global.connect_signal_update_page(self)
	
# Запуск обновления данных на странице
func _update_page() -> void:
	ColorScheme.repainting(self)
	File.set_lang(self)
	update_data()
	
# Обновление данных
func update_data() -> void: _run_update(Objects)
	
# Запуск функции изменения данных
func _run_update(obj: Variant) -> void:
	Global.run_func(obj, "update_data", _get_filter(obj))
	for i in obj.get_children(): _run_update(i)
	
# Получение данных фильтра
func _get_filter(_obj: Variant) -> Array: return [Filter]

# Изменение данных после смены дня
func new_day() -> void:
	Filter.reset_date_filters()
	$Head.update_date()
	update_data()
