extends Node

# Получение родителя определенного уровня
func g_p(obj: Variant, level: int = 2, save_level: int = 1) -> Variant:
	return obj.get_parent() if level == save_level else g_p(obj.get_parent(), level, save_level + 1)

# Получение int значения из текстового поля
func L_to_int(obj: Variant) -> int: return int(obj.get_text())

# Получение float значения из текстового поля
func L_to_float(obj: Variant) -> float: return float(obj.get_text())

# Проверка что текстовое поле пусто
func L_is_empty(obj: Variant) -> bool: return obj.get_text() == ""

# Применение цветовой палитры и перевода объекта
func color_and_lang(obj: Variant) -> void:
	ColorScheme.repainting(obj)
	File.set_lang(obj)

# Изменение текста на нижний регистр
func l(obj: Variant) -> String: return obj.name.to_lower()

# Отправка сигнала открытия окна
func op_w(next_page: Global.Pages, id: Variant = null,
		next_page_dir: Global.Dirs = Global.Dirs.WINDOWS, parent: Variant = null) -> void:
	Global.emit_signal("open_window", next_page, id, next_page_dir, parent)

# Отправка сигнала открытия нового окна
func op_np(page: Global.Pages, id: Variant = null, parent: Variant = null) -> void:
	Global.emit_signal("open_new_page", page, id, parent)
