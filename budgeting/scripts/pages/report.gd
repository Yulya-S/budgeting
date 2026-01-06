extends Control
@onready var Filter = $Menu

# Подключение сигнала
func _ready() -> void: Global.connect_signal_update_page(self)
	
# Запуск обновления данных на странице
func _update_page() -> void:
	ColorScheme.repainting(self)
	File.set_lang(self)
	update_data()
	
# Обновление данных
func update_data() -> void:
	for i in get_children(): Global.run_func(i, "update_data", [])
	_find_objects($ScrollContainer/VBoxContainer)

# Поиск и запуск изменения списков и графиков
func _find_objects(obj: Variant) -> void:
	Global.run_func(obj, "update_data", [] if obj.get_parent().name != "Sections" else [{"where":"s.month_limit>=0", "order": "value DESC"}])
	for i in obj.get_children(): _find_objects(i)

# Изменение данных после смены дня
func new_day() -> void: pass
	#Filter.reset_date_filters()
	#$Head.update_date()
	#update_data()
