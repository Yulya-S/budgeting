extends PageWindow
# Перечисление
enum States {CASH_FLOWS, EVENTS, LOANS} # Виды очисток
# Переменная
var state: States = States.CASH_FLOWS # Выбранный вид очистки

# Применение перевода
func _ready() -> void: File.set_lang(self)

# Обработка нажатий кнопок
func _on_cash_flows_button_down() -> void: _show_CD(States.CASH_FLOWS)

func _on_clear_events_button_down() -> void: _show_CD(States.EVENTS)

func _on_loans_button_down() -> void: _show_CD(States.LOANS)

# Отображение окна подтверждения действия
func _show_CD(new_state: States) -> void:
	$ConfirmationDialog.visible = true
	state = new_state

# Обработка подтверждения очистки данных
func _on_confirmation_dialog_confirmed() -> void:
	match state:
		States.CASH_FLOWS: Request.clear_cash_flows()
		States.EVENTS: Request.clear_events()
		States.LOANS: Request.clear_loans()
