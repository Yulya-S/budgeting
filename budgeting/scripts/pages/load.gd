extends ColorRect
@onready var Progress = $ProgressBar
@onready var Message = $Message
# Переменные
@onready var last_entry: String = Request.select_last_entry()
var create: bool = true # Этап создания событий
var events: Array = [] # Список событий для добавления в уведомления

# Применение цветовой палитры и перевода
func _ready() -> void:
	ColorScheme.repainting(self)
	File.set_lang(self)
	_create_table()

func _create_table() -> void:
	Request.start_create_multiplied_events_table(last_entry)
	Progress.max_value = len(Request.events)
	create = true
	Message.set_text(File.lang["__L1"])

# Отображение процесса загрузки
func _process(_delta: float) -> void:
	if create:
		_set_value(Request.events)
		if Request.completion_creation_et:
			events = Request.select_notif_events(last_entry)
			Progress.max_value = len(events)
			Message.set_text(File.lang["__L2"])
			create = false
	elif len(events) > 0:
		_set_value(events)
		Request.insert_notifications(events.pop_front())
	else:
		last_entry = Global.get_other_month(last_entry, true, true)
		if Global.date_comparison(Global.date_to_dict(last_entry), Global.get_date(), ">"):
			get_parent().start_update()
			Global.delete_child(get_parent(), self)
			return
		_create_table()

# Изменение текущего значения загрузки
func _set_value(count: Array) -> void: Progress.value = Progress.max_value - len(count)
