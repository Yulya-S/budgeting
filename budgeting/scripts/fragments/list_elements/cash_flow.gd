extends PageFragment
# Подключение путей к объектам в сцене
@onready var Title = $Title
@onready var WalletTitle = $Wallet_Title
@onready var Wallet2Title = $Wallet_2_Title

# Изменение значений
func set_values(data: Dictionary) -> void:
	super.set_values(data)
	match data.section_id:
		1: Title.next_page = Global.Pages.TRANSFER
		2: pass
		3:
			WalletTitle.next_page = Global.Pages.LOAN_INF
			Title.next_page = Global.Pages.LOAN
	if data.get("wallet_2_title"): Wallet2Title.get_child(0).visible = true
