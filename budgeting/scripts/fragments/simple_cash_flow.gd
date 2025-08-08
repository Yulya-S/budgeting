extends PageFragment
# Подключение путей к объектам в сцене
@onready var WalletTitle = $WalletTitle
@onready var Value = $Value
@onready var Date = $Date

# Обработка нажатия клавиш мыши
func _input(_event: InputEvent) -> void: pass

# Изменение значений
func set_values(data: Dictionary) -> void:
	Title.set_text(str(data.title))
	WalletTitle.set_text(str(data.wallet_title))
	Value.set_text(str(data.value))
	Date.set_text(str(data.date))
