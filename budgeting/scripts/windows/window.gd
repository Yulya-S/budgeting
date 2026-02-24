extends Control
# Экспортируемая переменная
@export var page_type: Request.ObjectVariants = Request.ObjectVariants.WALLET # Тип создаваемого / Изменяемого объкта
# Переменная
var idx: int = 0 # Индекс изменяемого объекта

# Применение цветовой палитры окна
func _ready() -> void:
	ColorScheme.repainting(self)
	File.set_lang(self)

# Обновление данных на странице
func set_page(new_idx: int) -> void:
	var data: Dictionary = Request.match_elem(str(new_idx), page_type)
	if data == {}:
		$Window.on_close_button_down()
		return
	idx = new_idx
	$Window/Delete.visible = true
	for i in get_children():
		if i.get_class() == "TextEdit": i.set_text(str(data[Global.lower(i)]))
		elif i.get_class() == "CheckButton":
			i.button_pressed = data[Global.lower(i)]
			_on_income_toggled(data[Global.lower(i)])

# Обработка переключения переключателя
func _on_income_toggled(toggled_on: bool) -> void:
	File.set_CB($Income)
	$Month_Limit.visible = not toggled_on
