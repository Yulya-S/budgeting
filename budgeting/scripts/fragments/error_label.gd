extends Label

enum States {NONE, _E01, _E02, _E03}
var state: States = States.NONE

func set_state(new_state: States) -> void:
	state = new_state
	update_lang()

func update_lang() -> void:
	if state == States.NONE: return
	text = File.lang["_Errors"][States.keys()[state]]
