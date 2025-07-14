extends Control
# Подключение путей к объектам в сцене
@onready var Title = $Wallet/Title
@onready var Value = $Wallet/Value
@onready var Objects = $ScrollContainer/VBoxContainer
@onready var TotalCount = $Total/Count
@onready var TotalValue = $Total/Value

# Путь к подгружаемой сцене транзакции
var cash_flow_path = load("res://scenes/fragments/cash_flow.tscn")

# Переменные
var id = null # Индекс счета
var lines: Array = [] # Список объектов для создания на странице

# Динамическое заполнение страницы
func _process(delta: float) -> void:
	if len(lines) > 0:
		Objects.add_child(cash_flow_path.instantiate())
		var obj: Dictionary = lines.pop_front()
		Objects.get_child(-1).set_values(obj)
		TotalValue.set_text(str(float(TotalValue.get_text()) + obj.value))
		TotalCount.set_text(str(int(TotalCount.get_text()) + 1))	

# Смена индекса объекта
func set_object(obj_id: int) -> void:
	id = obj_id
	_update_values()

# Заполнение данных на странице
func _update_values() -> void:
	var wallet_value: Dictionary = Request.select(Request.Tables.WALLETS, "*", "id="+str(id))[0]
	lines = Request.select_cash_flow_sum(id)
	Title.set_text(wallet_value.title)
	Value.set_text(str(wallet_value.value))
