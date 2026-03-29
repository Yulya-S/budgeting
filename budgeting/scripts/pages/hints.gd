extends PageWindow
# Переменные
var idx: int = 0  # Индекс выбранной подсказки
@onready var count: int = len(File.lang._Hints) # Количество подсказок

# Применение перевода
func _ready() -> void:
	File.set_lang(self)
	$Idx/Count.set_text(str(count))
	_set_hint()

# Изменение значения подсказки
func _set_hint() -> void:
	$Idx.set_text(str(idx + 1))
	$Label.set_text(File.lang._Hints[idx])
	_match_marker()

# Изменение размера и расположения маркера подсказки
func _set_marker(x: float, y: float, w: float, h: float, img_idx: int = 1) -> void:
	$AnimatedSprite2D.frame = img_idx
	$Marker.position = Vector2(x, y)
	$Marker.size = Vector2(w, h)

# Определение расположения и размера маркера
func _match_marker() -> void:
	match idx:
		0: _set_marker(808, 64, 107, 31, 0)
		1: _set_marker(391, 177, 309, 82, 0)
		2: _set_marker(338, 298, 462, 39, 0)
		3: _set_marker(697, 231, 114, 24, 0)
		4: _set_marker(606, 263, 100, 21, 0)
		5: _set_marker(297, 59, 41, 38)
		6: _set_marker(252, 97, 612, 29)
		7: _set_marker(231, 310, 671, 84, 2)
		8: _set_marker(881, 422, 40, 38)
		9: _set_marker(213, 395, 708, 38)
		10: _set_marker(213, 395, 41, 38)
		11: _set_marker(880, 395, 41, 38)
		12: _set_marker(243, 59, 41, 38)
		13: _set_marker(0, 0, 0, 0, 3)
		14: _set_marker(275, 152, 402, 38, 3)
		15: _set_marker(368, 123, 161, 26, 3)
		16: _set_marker(275, 152, 402, 38, 4)
		17: _set_marker(251, 223, 639, 173, 4)
		18: _set_marker(397, 92, 135, 26, 3)
		19: _set_marker(311, 403, 202, 40, 3)
		20: _set_marker(624, 403, 202, 40, 3)
		21: _set_marker(325, 59, 41, 38, 13)
		22: _set_marker(228, 91, 90, 38, 13)
		23: _set_marker(216, 180, 122, 25, 13)
		24: _set_marker(217, 154, 702, 87, 14)
		25: _set_marker(228, 91, 116, 38, 14)
		26: _set_marker(352, 59, 41, 38, 15)
		27: _set_marker(227, 119, 93, 84, 15)
		28: _set_marker(216, 226, 708, 29, 15)
		29: _set_marker(307, 262, 185, 29, 15)
		30: _set_marker(761, 248, 157, 22, 15)
		31: _set_marker(216, 153, 708, 70, 16)
		32: _set_marker(278, 91, 41, 38, 16)
		33: _set_marker(216, 153, 708, 70, 17)
		34: _set_marker(377, 59, 41, 38, 18)
		35: _set_marker(215, 190, 706, 83, 18)
		36: _set_marker(214, 284, 137, 22, 18)
		37: _set_marker(405, 59, 41, 38, 6)
		38: _set_marker(212, 159, 711, 57, 6)
		39: _set_marker(216, 180, 140, 24, 6)
		40: _set_marker(215, 232, 705, 97, 8)
		41: _set_marker(215, 154, 705, 84, 8)
		42: _set_marker(431, 59, 41, 38, 9)
		43: _set_marker(240, 393, 69, 62, 9)
		44: _set_marker(215, 158, 708, 85, 10)
		45: _set_marker(852, 59, 41, 38, 10)
		46: _set_marker(603, 98, 300, 50, 10)
		47: _set_marker(867, 244, 41, 38, 10)
		48: _set_marker(808, 181, 108, 23, 9)
		49: _set_marker(329, 225, 314, 27, 7)
		50: _set_marker(329, 252, 314, 56, 7)
		51: _set_marker(458, 59, 41, 38, 11)
		52: _set_marker(224, 330, 688, 80, 12)
		53: _set_marker(880, 59, 41, 38, 12)

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
