extends Control
## In-match HUD: health/shield bars, active weapon + ammo, storm phase
## timer, and (in Tech Battle) a running feed of every Tech rule that has
## activated so far. Built entirely from code.

var player: Player
var storm: StormManager
var mode: GameModeBase

var health_label: Label
var shield_label: Label
var weapon_label: Label
var storm_label: Label
var rules_box: VBoxContainer
var alive_label: Label
var evolve_toast: Label
var _toast_timer: float = 0.0

func setup(p: Player, storm_manager: StormManager, game_mode: GameModeBase) -> void:
	player = p
	storm = storm_manager
	mode = game_mode
	if player:
		player.weapon_evolved.connect(_on_weapon_evolved)
	if mode is TechBattleMode:
		(mode as TechBattleMode).rule_activated.connect(_on_rule_activated)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bottom_left := VBoxContainer.new()
	bottom_left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bottom_left.position = Vector2(20, -110)
	add_child(bottom_left)
	health_label = _label(bottom_left, "HP: 100 / 100")
	shield_label = _label(bottom_left, "Shield: 100 / 100")
	weapon_label = _label(bottom_left, "Weapon: none")

	var top_center := VBoxContainer.new()
	top_center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_center.position = Vector2(0, 16)
	top_center.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(top_center)
	storm_label = _label(top_center, "Calm phase...")
	storm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alive_label = _label(top_center, "")
	alive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	evolve_toast = _label(top_center, "")
	evolve_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	evolve_toast.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))

	var top_right := VBoxContainer.new()
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.position = Vector2(-260, 16)
	top_right.custom_minimum_size = Vector2(240, 0)
	add_child(top_right)
	var rules_title := _label(top_right, "Active Tech Rules:")
	rules_box = VBoxContainer.new()
	top_right.add_child(rules_box)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.add_theme_font_size_override("font_size", 24)
	add_child(crosshair)

func _label(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	parent.add_child(l)
	return l

func _process(delta: float) -> void:
	if player == null:
		return
	health_label.text = "HP: %d / %d" % [ceil(player.health), int(player.max_health)]
	shield_label.text = "Shield: %d / %d" % [ceil(player.shield), int(player.max_shield)]
	if player.slots.has(player.active_slot):
		var w = player.slots[player.active_slot]
		var ammo_txt := " [%d]" % w.ammo_in_mag if w.def.has("mag_size") else ""
		weapon_label.text = "Weapon: %s%s" % [w.def.get("name", "?"), ammo_txt]
	else:
		weapon_label.text = "Weapon: none"

	if storm:
		if storm.is_calm():
			storm_label.text = "Calm phase: storm in %ds" % int(storm.time_remaining_in_state())
		else:
			storm_label.text = "Storm phase %d" % (storm.current_phase() + 1)
	if mode:
		alive_label.text = "Alive: %d" % GameManager.players_alive_count()

	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			evolve_toast.text = ""

func _on_weapon_evolved(new_name: String) -> void:
	evolve_toast.text = "Weapon evolved: %s!" % new_name
	_toast_timer = 3.0

func _on_rule_activated(rule: Dictionary) -> void:
	var l := Label.new()
	l.text = "[%s] %s" % [TechRuleDatabase.rarity_name(rule.rarity), rule.name]
	l.add_theme_color_override("font_color", _rarity_color(rule.rarity))
	rules_box.add_child(l)

func _rarity_color(rarity: int) -> Color:
	match rarity:
		TechRuleDatabase.Rarity.COMMON: return Color(0.8, 0.8, 0.8)
		TechRuleDatabase.Rarity.UNCOMMON: return Color(0.5, 0.85, 0.5)
		TechRuleDatabase.Rarity.RARE: return Color(0.4, 0.6, 1.0)
		TechRuleDatabase.Rarity.EPIC: return Color(0.75, 0.35, 0.95)
		TechRuleDatabase.Rarity.LEGENDARY: return Color(1.0, 0.75, 0.2)
		_: return Color.WHITE
