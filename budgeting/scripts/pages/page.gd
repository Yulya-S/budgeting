extends Control
class_name Page
# Подключение пути к объектам в сцене
@onready var Objects = $ObjArray

# Подключение сигнала
func _ready() -> void:
	Global.connect("update_page", Callable(self, "_update_page"))
	_update_page()
	
# Запуск обновления данных на странице
func _update_page() -> void:
	ColorScheme.repainting(self)
	File.set_lang(self)
	update_data()
	
# Обновление данных
func update_data() -> void: Objects.update_data($Filter)

# Изменение данных после смены дня
func new_day() -> void:
	$Filter.reset_date_filters()
	$Head.update_date()
	update_data()
