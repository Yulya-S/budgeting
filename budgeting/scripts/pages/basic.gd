extends Control
# Подключение путей к объектам в сцене
@onready var Budget = $Menu/Budget
@onready var CashFlow = $Menu/CashFlow
@onready var Objects = $ScrollContainer/VBoxContainer

# Создание главной страницы
func _ready() -> void:
	
	Global.connect("update_page", Callable(self, "_update_page"))
	_update_page()
	
	#Budget.set_text(str(Request.select_budget()))
	#CashFlow.set_text(str(Request.select_general_wallets_movement()))
	#Global.emit_signal("update_page")
	
# Запуск обновления данных на странице
func _update_page() -> void:
	ColorScheme.repainting(self)
	update_data()
	
	#File.set_lang(self)
	#update_data()
	
# Обновление данных
func update_data() -> void: _find_objects(Objects)

# Поиск и запуск изменения списков и графиков
func _find_objects(obj: Variant) -> void:
	if obj.name in ["ObjArray", "DailyTransactions", "Calendar"]: obj.data_update()
	for i in obj.get_children(): _find_objects(i)
	
