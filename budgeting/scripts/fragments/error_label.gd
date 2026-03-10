extends Label
# Переменные
enum States {NONE, _E1, _E2, _E3, _E4, _E5, _E6, _E7, _E8} # Список возможных ошибок
var state: States = States.NONE # Код текущей ошибки

# Изменение текста ошибки
func _process(_delta: float) -> void:
	if state == States.NONE: return
	visible = true
	var error_text: String = File.lang["_Errors"][States.keys()[state]]
	error_text[0] = error_text[0].to_upper()
	set_text(error_text + "!")

# Очистка
func clear() -> void:
	visible = false
	state = States.NONE

# Применить новый код
func set_state(new_state: States) -> bool:
	if state != States.NONE: return false
	state = new_state
	return false

# Проверка заполнено ли текстовое поле
func check(field: Variant) -> bool:
	if field is TextEdit and SF.L_is_empty(field):
		set_state(States._E1)
		return true
	return false

# Проверка обязательных к заполнению полей
func check_mandatory_fields(fields: Array) -> bool:
	for i in fields: if check(i): return true
	return false
