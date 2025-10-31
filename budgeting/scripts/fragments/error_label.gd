extends Label
# Переменные
enum States {NONE, _E01, _E02, _E03, _E04} # Список кодов возможных ошибок
var state: States = States.NONE # Код текущей ошибки

# Очистка ошибки
func clear() -> void:
	visible = false
	state = States.NONE

# Применить новый код ошибки
func set_state(new_state: States) -> void:
	if state != States.NONE: return
	state = new_state
	update_lang()

# Изменение текста ошибки
func update_lang() -> void:
	if state == States.NONE: return
	_set_error_text(File.lang["_Errors"][States.keys()[state]])
	
# Изменение текста ошибки
func _set_error_text(erro_text: String) -> void:
	visible = true
	erro_text[0] = erro_text[0].to_upper()
	set_text(erro_text + "!")
	
# Обработчики ошибок
# Проверка обязательных к заполнению полей
func check_mandatory_fields(field: TextEdit) -> bool:
	if field.get_text() == "":
		set_state(States._E01)
		return true
	return false
