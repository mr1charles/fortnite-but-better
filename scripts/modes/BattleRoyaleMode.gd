class_name BattleRoyaleMode
extends GameModeBase
## Standard Battle Royale: find chests and floor loot, use special items,
## survive the storm. No Tech rules -- this is the "normal" mode.

func mode_id() -> int:
	return GameManager.GameMode.BATTLE_ROYALE
