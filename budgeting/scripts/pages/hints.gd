extends PageWindow
# Переменные
var idx: int = 0  # Индекс выбранной подсказки
@onready var count: int = len(File.lang.keys().filter(func(item): return "__H" in item)) # Количество подсказок

# Применение перевода
func _ready() -> void:
	File.set_lang(self)
	$Count.set_text(str(count))
	_set_hint()

# Изменение значения подсказки
func _set_hint() -> void:
	$Idx.set_text(str(idx + 1))
	$Label.set_text(File.lang["__H" + str(idx + 1)])
	_match_marker()

# Изменение размера и расположения маркера подсказки
func _set_marker(x: float, y: float, _w: float, _h: float) -> void:
	$Marker.position = Vector2(x, y)
	$Marker.size = Vector2(x, y)

# Определение расположения и размера маркера
func _match_marker() -> void:
	match idx:
		0: _set_marker(20, 30, 50, 60)
		1: _set_marker(10, 10, 80, 100)

# Смена подсказки
# Следующая
func _on_next_button_down() -> void:
	idx += 1
	if idx >= count: idx = 0
	_set_hint()

# Предыдущая
func _on_last_button_down() -> void:
	idx -= 1
	if idx < 0: idx = count - 1
	_set_hint()
