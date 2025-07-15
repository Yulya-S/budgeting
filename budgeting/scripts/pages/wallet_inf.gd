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

# Подключение сигналов
func _ready() -> void: Global.connect("update_page", Callable(self, "_update_values"))

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
	var wallet_value: Array = Request.select(Request.Tables.WALLETS, "*", "id="+str(id))
	if len(wallet_value) == 0:
		_on_back_button_down()
		return
	lines = Request.select_cash_flow_sum(id)
	Title.set_text(wallet_value[0].title)
	Value.set_text(str(wallet_value[0].value))

# Обработка нажатия кнопки возврата к списку счетов
func _on_back_button_down() -> void:
	self.queue_free()
	get_parent().remove_child(self)

# Обработка нажатия кнопки изменения счета
func _on_update_button_down() -> void: Global.emit_signal("open_window", Global.Pages.WALLET, id)
