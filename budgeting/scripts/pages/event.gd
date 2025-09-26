extends Control
# Подключение пути к объектам в сцене
@onready var Objects = null
@onready var Filter = $Filter

var objArray = load("res://scenes/fragments/obj_array.tscn")
var calendar = load("res://scenes/pages/events/calendar.tscn")

# Запуск фильтрации
func _ready() -> void:
	#add_child(objArray.instantiate())
	#Objects = get_child(-1)
	#get_child(-1).set_obj(get_child(-1).ListObjects.EVENT)
	#get_child(-1).size = Vector2(1152, 473)
	#get_child(-1).position = Vector2(0, 170)
	
	add_child(calendar.instantiate())
	Objects = get_child(-1)
	#get_child(-1).set_obj(get_child(-1).ListObjects.EVENT)
	#get_child(-1).size = Vector2(456, 473)
	get_child(-1).position = Vector2(0, 170)
	Filter.get_filter()

# Обработка нажатия кнопки создания события
func _on_add_event_button_down() -> void: Global.emit_signal("open_window", Global.Pages.EVENT)
