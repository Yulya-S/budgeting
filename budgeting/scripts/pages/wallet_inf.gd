extends Node2D
# Подключение путей к объектам в сцене
@onready var Title = $Background/Wallet/Title
@onready var Value = $Background/Wallet/Value
@onready var Objects = $Background/ScrollContainer/VBoxContainer
@onready var TotalCount = $Background/Total/Count
@onready var TotalValue = $Background/Total/Value

# Путь к подгружаемой сцене транзакции
var cash_flow_path = load("res://scenes/fragments/cash_flow.tscn")

var id = 1 # Индекс счета

# Заполнение данных
func _ready() -> void:
	var wallet_value: Dictionary = Request.select(Request.Tables.WALLETS, "*", "id="+str(id))[0]
	var cash_flow_value: Array = Request.select_cash_flow_sum(id)
	Title.set_text(wallet_value.title)
	Value.set_text(str(wallet_value.value))
	var sum: float = 0.0
	var count: int = 0
	for i in cash_flow_value:
		Objects.add_child(cash_flow_path.instantiate())
		Objects.get_child(-1).set_values(i)
		sum += i.value
	TotalCount.set_text(str(len(cash_flow_value)))
	TotalValue.set_text(str(sum))
	
	
	
	
