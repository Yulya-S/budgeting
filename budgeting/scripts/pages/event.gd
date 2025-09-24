extends Control
# Подключение пути к объектам в сцене
@onready var Objects = $ObjArray
@onready var Filter = $Filter

# Запуск фильтрации
func _ready() -> void: Filter.get_filter()

# Обработка нажатия кнопки создания события
func _on_add_event_button_down() -> void: Global.emit_signal("open_window", Global.Pages.EVENT)
