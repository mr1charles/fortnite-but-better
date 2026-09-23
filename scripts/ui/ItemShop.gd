extends Control
## Item Shop: buy skins with Battle Tokens (earned free from playing) or
## Gems (the paid currency, topped up via purchase_gem_pack). Prices come
## straight from SkinDatabase / ShopManager so balancing them only means
## editing those two files.

var wallet_label: Label
var grid: GridContainer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	add_child(margin)

	var col := VBoxContainer.new()
	margin.add_child(col)

	var header := HBoxContainer.new()
	col.add_child(header)
	var title := Label.new()
	title.text = "ITEM SHOP"
	title.add_theme_font_size_override("font_size", 28)
	header.add_child(title)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	header.add_child(back)

	wallet_label = Label.new()
	col.add_child(wallet_label)
	_refresh_wallet()

	var gem_row := HBoxContainer.new()
	col.add_child(gem_row)
	for pack in ShopManager.gem_packs:
		var b := Button.new()
		b.text = "%d Gems - $%.2f" % [pack.gems, pack.price_usd]
		b.pressed.connect(func(): _buy_gems(pack.id))
		gem_row.add_child(b)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 460)
	col.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)
	_populate_skins()

func _refresh_wallet() -> void:
	wallet_label.text = "Battle Tokens: %d    Gems: %d    (%s)" % [
		EconomyManager.battle_tokens, EconomyManager.gems, ShopManager.PAYOUT_OWNER_NOTE
	]

func _populate_skins() -> void:
	for child in grid.get_children():
		child.queue_free()
	for skin in SkinDatabase.all_skins():
		grid.add_child(_build_skin_card(skin))

func _build_skin_card(skin: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 150)
	var box := VBoxContainer.new()
	panel.add_child(box)

	var name_label := Label.new()
	name_label.text = skin.name
	box.add_child(name_label)

	var rarity_label := Label.new()
	rarity_label.text = SkinDatabase.rarity_name(skin.rarity)
	rarity_label.add_theme_color_override("font_color", SkinDatabase.rarity_color(skin.rarity))
	box.add_child(rarity_label)

	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(0, 40)
	swatch.color = skin.palette.get("body", Color.GRAY)
	box.add_child(swatch)

	var owned: bool = EconomyManager.owns_skin(skin.id)
	var action := Button.new()
	if owned:
		action.text = "Equip" if EconomyManager.equipped_skin_id != skin.id else "Equipped"
		action.disabled = EconomyManager.equipped_skin_id == skin.id
		action.pressed.connect(func():
			EconomyManager.equip_skin(skin.id)
			_populate_skins())
	else:
		var currency_name := "Tokens" if skin.currency == SkinDatabase.Currency.TOKENS else "Gems"
		action.text = "Buy - %d %s" % [skin.price, currency_name]
		action.pressed.connect(func(): _buy_skin(skin.id))
	box.add_child(action)
	return panel

func _buy_skin(skin_id: String) -> void:
	ShopManager.purchase_skin(skin_id)
	_refresh_wallet()
	_populate_skins()

func _buy_gems(pack_id: String) -> void:
	ShopManager.purchase_gem_pack(pack_id)
	_refresh_wallet()
