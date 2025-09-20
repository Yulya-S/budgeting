extends ColorRect
# Параметр
var values: Array = [] # Данные для отображения

# Отрисовка графика
func _draw() -> void:
	if len(values) == 0: return # Отмена отрисовки при недостаточном количестве данных
	# Подготовка данных для отображения
	var data_to_draw: Array = [0.0]
	var date: String = values[0].date
	for i in values:
		if date != i.date:
			date = i.date
			data_to_draw.append(data_to_draw[-1])
		match i.section_id:
			2: data_to_draw[-1] = i.value
			3: data_to_draw[-1] -= i.value
			4: data_to_draw[-1] += i.value
	if len(data_to_draw) < 2: return # Отмена отрисовки при недостаточном количестве данных
	# Отображение линий графика
	for i in range(0, len(data_to_draw)-1):
		draw_line(Vector2((i*1132./(len(data_to_draw)-1))+10., 114.-(114.*data_to_draw[i]/data_to_draw.max())+5.),
			Vector2(((i+1)*1132./(len(data_to_draw)-1))+10., 114.-(114.*data_to_draw[i+1]/data_to_draw.max())+5.), Color.FIREBRICK, 2)
	# Добавление точек для обозначения дат
	for i in range(len(data_to_draw)):
		draw_circle(Vector2((i*1132./(len(data_to_draw)-1))+10., 114.-(114.*data_to_draw[i]/data_to_draw.max())+5.), 3, Color.DARK_BLUE)

# Перезапуск отрисовки графика
func update_schedule() -> void:
	if not get_parent().id: return
	values = Request.select(Request.Tables.CASH_FLOWS, "*", "section_id IN (2,3,4) AND wallet_2_id="+str(get_parent().id), "date")
	queue_redraw()
