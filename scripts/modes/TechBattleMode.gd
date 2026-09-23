class_name TechBattleMode
extends GameModeBase
## Tech Battle: identical to Battle Royale until the calm phase ends. From
## then on, every time the storm finishes closing in (StormManager's
## `phase_advanced`), one legal Tech rule is rolled in and stays active for
## the rest of the match -- so a match can end with 8-10+ rules stacked,
## chosen so the combination never becomes unwinnable (see
## TechRuleDatabase.can_activate).

signal rule_activated(rule: Dictionary)

var active_rules: Array[Dictionary] = []
var effects: TechEffectApplier
var _rng := RandomNumberGenerator.new()

func mode_id() -> int:
	return GameManager.GameMode.TECH_BATTLE

func start() -> void:
	super.start()
	_rng.randomize()
	effects = TechEffectApplier.new()
	effects.setup(world, loot_spawner, storm, players)
	add_child(effects)
	storm.phase_advanced.connect(_on_phase_advanced)

func _process(delta: float) -> void:
	if effects:
		effects.process_periodics(delta)

func _on_phase_advanced(_phase_index: int) -> void:
	var next := TechRuleDatabase.roll_next_rule(active_rules, _rng)
	if next.is_empty():
		return
	active_rules.append(next)
	effects.apply(next)
	emit_signal("rule_activated", next)

func active_rule_names() -> Array[String]:
	var out: Array[String] = []
	for r in active_rules:
		out.append(r.name)
	return out
