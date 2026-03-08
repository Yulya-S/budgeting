extends Node

# Получение родителя определенного уровня
func g_p(obj: Variant, level: int = 2, save_level: int = 1) -> Variant:
	return obj.get_parent() if level == save_level else g_p(obj.get_parent(), level, save_level + 1)

# Получение int значения из текстового поля
func L_to_int(obj: Variant) -> int: return int(obj.get_text())

# Проверка что текстовое поле пусто
func L_is_empty(obj: Variant) -> bool: return obj.get_text() == ""
