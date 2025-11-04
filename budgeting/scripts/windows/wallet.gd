extends CreationWindow
# Подключение пути к объектам в 
@onready var Title = $Title
	
# Проверка введенных данных
func check_object() -> bool:
	super.check_object()
	return _set_error(Request.select(table, "id", 'title="'+Title.get_text()+'"'))
