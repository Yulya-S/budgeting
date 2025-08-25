extends InfPage
# Подключение пути к объектам в сцене
@onready var Objects = $ObjArray

# Смена индекса объекта
func set_object(obj_id: int, parent = null) -> void:
	Objects.data.date = ""
	Objects.set_data("cf.section_id IN (2,3,4) AND cf.wallet_2_id="+str(obj_id))
	super.set_object(obj_id, parent)
