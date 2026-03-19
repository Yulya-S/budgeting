extends ColorRect
# Подключение путей к объектам в сцене
@onready var Progress = $ProgressBar
@onready var Message = $Message
# Переменные
@onready var last_entry: String = Request.select_last_entry() # Получение даты последнего входа
var create: bool = true # Этап создания событий
var events: Array = [] # Список событий для добавления в уведомления

# Применение цветовой палитры и перевода
func _ready() -> void:
	SF.color_and_lang(self)
	_create_table()

# Отображение процесса загрузки
func _process(_delta: float) -> void:
	if create:
		Progress.value = Progress.max_value - len(Request.events)
		if Request.completion_creation_et:
			events = Request.select_notif_events(last_entry)
			_update(events, 1)
	elif len(events) > 0:
		Progress.value = Progress.max_value - len(events)
		Request.insert_notifications(events.pop_front())
	else:
		last_entry = Global.get_other_month(last_entry, true)
		if Global.date_comparison(Global.date_to_dict(last_entry), Global.get_date(), ">"):
			get_parent().start_update()
			Global.delete_child(get_parent(), self)
			return
		_create_table()

# Запуск обновления событий
func _create_table() -> void:
	Request.start_create_multiplied_events_table(last_entry)
	_update(Request.events, 0)

# Смена значения max_value и текста загрузки
func _update(count: Array, message_idx: int) -> void:
	Progress.max_value = len(count)
	Message.set_text(File.lang["__L"+str(message_idx + 1)])
	create = not bool(message_idx)
