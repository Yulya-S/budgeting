extends PageFragment
# Подключение путей к объектам в сцене
@onready var WalletTitle = $WalletTitle
@onready var Wallet2Title = $Wallet2Title
@onready var Value = $Value
@onready var Date = $Date

var wallet_ids: Array = [0, 0]
var section_id: int = 0

# Изменение значений
func set_values(data: Dictionary) -> void:
	id = data.id
	wallet_ids = [data.wallet_id, data.wallet_2_id]
	section_id = section_id
	Title.set_text(str(data.title))
	var wallet_title: String = str(data.wallet_title)
	var wallet2_title: String = ""
	match data.section_id:
		1: wallet2_title = Request.select(Request.Tables.WALLETS, "title", "id="+str(data.wallet_2_id))[0].title
		2: wallet2_title = Request.select(Request.Tables.LOANS, "title", "id="+str(data.wallet_2_id))[0].title
		3:
			wallet2_title = wallet_title
			wallet_title = Request.select(Request.Tables.LOANS, "title", "id="+str(data.wallet_2_id))[0].title
	if wallet2_title != "": Wallet2Title.get_child(0).visible = true
	WalletTitle.set_text(wallet_title)
	Wallet2Title.set_text(wallet2_title)
	Value.set_text(str(data.value))
	Date.set_text(str(data.date))
