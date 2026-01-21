extends ColorRect
# Переменные
var state_idx: int = 0 # Номер текущего этапа
@onready var states_count: int = len(File.lang.keys().filter(func(item): return "__L" in item)) # Количество этапов загрузки

func _process(delta: float) -> void:
	$ProgressBar.value += 1

#func _new_state
