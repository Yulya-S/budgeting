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
	idx = new_idx
	var data: Dictionary = Request.match_elem(str(idx), page_type)
	$Window/Delete.visible = true
	for i in get_children():
		if i.get_class() == "TextEdit": i.set_text(str(data[Global.lower(i)]))
