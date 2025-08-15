extends PageFragment
# Подключение путей к объектам в сцене
@onready var Count = $Count
@onready var Total = $Total

# Изменение значений
func set_values(data: Dictionary) -> void:
	Title.set_object(data.title, [data.wallet_id, data.section_id])
	Count.set_text(str(data.count))
	Total.set_text(str(data.value))
