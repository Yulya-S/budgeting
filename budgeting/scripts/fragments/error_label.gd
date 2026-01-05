extends Label
# Переменные
enum States {NONE, _E01, _E02, _E03, _E04, _E05, _E06, _E07} # Список возможных ошибок
var state: States = States.NONE # Код текущей ошибки

# Очистка
func clear() -> void:
	visible = false
	state = States.NONE

# Применить новый код
func set_state(new_state: States) -> void:
	if state != States.NONE: return
	state = new_state
	update_lang()

# Изменение текста
func update_lang() -> void:
	visible = true
	var error_text: String = File.lang["_Errors"][States.keys()[state]]
	error_text[0] = error_text[0].to_upper()
	set_text(error_text + "!")
	
# Проверка обязательных к заполнению полей
func check_mandatory_fields(field: Array) -> bool:
	for i in field: if i is TextEdit and i.get_text() == "":
		set_state(States._E01)
		return true
	return false
