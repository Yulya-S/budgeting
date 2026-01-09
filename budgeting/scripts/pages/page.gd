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
func update_data() -> void:
	Objects.update_data(Filter)
	for i in get_children(): Global.run_func(i, "update_data", [Filter])

# Изменение данных после смены дня
func new_day() -> void:
	Filter.reset_date_filters()
	$Head.update_date()
	update_data()
