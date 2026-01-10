extends Fragment
# Подключение пути к объекту в сцене
@onready var Wallet2Title = $Wallet_2_Title

# Изменение значений
func set_values(data: Dictionary) -> void:
	super.set_values(data)
	match data.section_id:
		1: Title.next_page = Global.Pages.TRANSFER
		2, 4:
			$Wallet_Title.next_page = Global.Pages.LOAN_INF
			Title.next_page = Global.Pages.LOAN if data.section_id == 2 else Global.Pages.PERCENT
		3:
			Wallet2Title.next_page = Global.Pages.LOAN_INF
			Title.next_page = Global.Pages.PAYMENT
		_: Wallet2Title.visible = false
