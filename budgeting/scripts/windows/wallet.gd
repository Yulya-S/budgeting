extends CreationWindow
# Подключение пути к объектам в 
@onready var Title = $Title
	
# Проверка введенных данных
func check_object(_new_circle: bool = true) -> bool:
	super.check_object(true)
	return _set_error(Request.select(table, "id", 'title="'+Title.get_text()+'"'))
