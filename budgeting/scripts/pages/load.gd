extends ColorRect
@onready var Progress = $ProgressBar
# Переменные
@onready var last_entry: String = Request.select_last_entry()
var create: bool = true # Этап создания событий
var events: Array = [] # Список событий для добавления в уведомления

# Применение цветовой палитры и перевода
func _ready() -> void:
	ColorScheme.repainting(self)
	File.set_lang(self)
	Request.start_create_multiplied_events_table(Global.date_to_str())
	Progress.max_value = len(Request.events)

# Отображение процесса загрузки
func _process(delta: float) -> void:
	if create:
		_set_value(Request.events)
		if Request.checking_notifications():
			Global.delete_child(get_parent(), self)
			return
		elif Request.completion_creation_et:
			events = Request.select_notif_events()
			Progress.max_value = len(events)
			$Message.set_text(File.lang["__L2"])
			create = false
	elif len(events) > 0:
		_set_value(events)
		Request.insert_notifications(events.pop_front())
	else:
		get_parent().start_update()
		Global.delete_child(get_parent(), self)

# Изменение текущего значения загрузки
func _set_value(count: Array) -> void: Progress.value = Progress.max_value - len(count)
