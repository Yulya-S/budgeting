extends PageFragment
# Подключение путей к объектам в сцене
@onready var Count = $Count
@onready var Total = $Total

# Изменение значений
func set_values(data: Dictionary) -> void:
	id = [data.wallet_id, data.section_id]
	Title.set_text(str(data.title))
	Count.set_text(str(data.count))
	Total.set_text(str(data.value))
