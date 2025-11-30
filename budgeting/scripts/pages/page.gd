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
	update_date()
	
# Обновление данных
func update_date() -> void: Objects.data_update($Filter)
