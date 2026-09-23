extends Control
## Entry point (project's main scene). Lets the player jump into either
## game mode, or open the Item Shop / Skin Customizer first. Built entirely
## from code so no hand-authored UI scene is required.

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.custom_minimum_size = Vector2(320, 0)
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var title := Label.new()
	title.text = "ROYALE OFFLINE"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var wallet := Label.new()
	wallet.text = "Battle Tokens: %d    Gems: %d" % [EconomyManager.battle_tokens, EconomyManager.gems]
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(wallet)

	root.add_child(_make_button("Play: Battle Royale", func(): _start_match(GameManager.GameMode.BATTLE_ROYALE)))
	root.add_child(_make_button("Play: Tech Battle", func(): _start_match(GameManager.GameMode.TECH_BATTLE)))
	root.add_child(_make_button("Item Shop", func(): get_tree().change_scene_to_file("res://scenes/ui/ItemShop.tscn")))
	root.add_child(_make_button("Customize Skin", func(): get_tree().change_scene_to_file("res://scenes/ui/SkinCustomizer.tscn")))
	root.add_child(_make_button("Quit", func(): get_tree().quit()))

func _make_button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(on_pressed)
	return b

func _start_match(mode: int) -> void:
	Main.pending_mode = mode
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
