extends PageFragment
# Подключение путей к объектам в сцене
@onready var Value = $Value
@onready var Total = $Total

# Изменение значений
func set_values(data: Dictionary) -> void:
	#Title.set_object(data.title, [data.wallet_id, data.section_id])
	Title.set_object(str(data.title), data.id)
	#Value.set_text(str(data.count))
	Total.set_text(str(data.total))
