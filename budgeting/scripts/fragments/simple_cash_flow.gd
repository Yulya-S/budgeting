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
	wallet_ids = [data.wallet_id, data.wallet_2_id]
	Title.set_object(str(data.title), data.id)
	var wallet_title: String = str(data.title_2)
	var wallet2_title: String = ""
	match data.section_id:
		1:
			Title.next_page = Global.Pages.TRANSFER
			wallet2_title = Request.select(Request.Tables.WALLETS, "title", "id="+str(data.wallet_2_id))[0].title
		2: wallet2_title = Request.select(Request.Tables.LOANS, "title", "id="+str(data.wallet_2_id))[0].title
		3:
			wallet2_title = wallet_title
			wallet_ids = [data.wallet_2_id, data.wallet_id]
			wallet_title = Request.select(Request.Tables.LOANS, "title", "id="+str(data.wallet_2_id))[0].title
	if wallet2_title != "": Wallet2Title.get_child(0).visible = true
	WalletTitle.set_object(wallet_title, wallet_ids[0])
	Wallet2Title.set_object(wallet2_title, wallet_ids[1])
	Value.set_text(str(data.value))
	Date.set_text(str(data.date))
