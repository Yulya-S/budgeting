extends ColorRect
# Подключение путей к объектам в сцене
@onready var Border = $Border
@onready var Value = $Value
@onready var Max = $Max
@onready var ConsumptionIncome = $ConsumptionIncome
@onready var Title = $Title

# Переменные
var id: int = 0
var state: Global.MouseOver = Global.MouseOver.NORMAL # Текущее состояние объекта

# Смена размера цветовой линии под размер родителя
func _ready() -> void:
	custom_minimum_size[0] = get_parent().get_parent().size[0]
	update_minimum_size()

# Изменение значений
func set_values(data: Dictionary) -> void:
	id = data.id
	if data.income: ConsumptionIncome.set_text("Доход")
	elif data.month_limit > 0: ConsumptionIncome.set_text("Расход")
	Border.visible = ConsumptionIncome.get_text() == "Расход"
	if Border.visible:
		Border.get_child(0).size.x = (Border.size.x * data.value) / data.month_limit
		if Border.size.x < Border.get_child(0).size.x:
			Border.get_child(0).size.x = Border.size.x
			Border.get_child(0).color = Color.html("#990027")
		elif Border.size.x / 2. <  Border.get_child(0).size.x: Border.get_child(0).color = Color.html("#978800")
	Value.set_text(str(data.value))
	if data.month_limit > 0: Max.set_text(str(data.month_limit))
	else: Max.set_text("")
	Title.set_text(data.title)
	
# Обработка нажатия клавиш мыши
func _input(event: InputEvent) -> void:
	if state == Global.MouseOver.NORMAL or not id or not ConsumptionIncome.get_text(): return
	if event.is_action("click") and event.is_pressed():
		Global.emit_signal("open_window", Global.Pages.SECTION, id)

# Обработка наведения мыши на контейнер
func _on_title_mouse_entered() -> void: state = Global.MouseOver.HOVER

func _on_title_mouse_exited() -> void: state = Global.MouseOver.NORMAL
