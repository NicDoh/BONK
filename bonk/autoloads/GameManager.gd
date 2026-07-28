extends Node

const MAX_OFFLINE_SECONDS := 3600.0

var pending_offline_summary: Dictionary = {}

func _ready() -> void:
	SaveManager.load_save()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save()

func apply_offline_progress(saved_timestamp: float) -> void:
	if not ResearchManager.is_unlocked("offline_progress"):
		return
	if not ExpeditionManager.current_monster:
		return

	var elapsed := Time.get_unix_time_from_system() - saved_timestamp
	elapsed = minf(elapsed, MAX_OFFLINE_SECONDS)
	if elapsed < 1.0:
		return

	var kills := ExpeditionManager.calculate_offline_kills(elapsed)
	if kills <= 0:
		return

	var drops_summary: Dictionary = {}
	var monster := ExpeditionManager.current_monster
	var drop_bonus := 0.0
	if CharacterManager.equipped_main_hand:
		drop_bonus = CharacterManager.equipped_main_hand.bonus_drop_chance
	if CharacterManager.equipped_off_hand:
		drop_bonus += CharacterManager.equipped_off_hand.bonus_drop_chance

	for i in kills:
		for entry in monster.drops_guaranteed:
			var qty := randi_range(entry.quantity_min, entry.quantity_max)
			InventoryManager.add_item(entry.item, qty)
			drops_summary[entry.item.name] = drops_summary.get(entry.item.name, 0) + qty
		if not monster.drops_common.is_empty():
			var entry := _weighted_pick(monster.drops_common)
			var qty := randi_range(entry.quantity_min, entry.quantity_max)
			InventoryManager.add_item(entry.item, qty)
			drops_summary[entry.item.name] = drops_summary.get(entry.item.name, 0) + qty
		if monster.rare_table_chance > 0.0 and not monster.drops_rare.is_empty():
			if randf() < monster.rare_table_chance * (1.0 + drop_bonus):
				for entry in monster.drops_rare:
					if randf() < entry.weight:
						var qty := randi_range(entry.quantity_min, entry.quantity_max)
						InventoryManager.add_item(entry.item, qty)
						drops_summary[entry.item.name] = drops_summary.get(entry.item.name, 0) + qty
		if monster.ultra_rare_table_chance > 0.0 and not monster.drops_ultra_rare.is_empty():
			if randf() < monster.ultra_rare_table_chance:
				for entry in monster.drops_ultra_rare:
					if randf() < entry.weight:
						var qty := randi_range(entry.quantity_min, entry.quantity_max)
						InventoryManager.add_item(entry.item, qty)
						drops_summary[entry.item.name] = drops_summary.get(entry.item.name, 0) + qty

	var avg_damage := maxi(1, CharacterManager.get_effective_stat("strength") - monster.defense / 2)
	var xp_per_kill := float(avg_damage * ceili(float(monster.hp) / float(avg_damage)))
	CharacterManager.gain_xp("strength", xp_per_kill * kills * 0.5)
	CharacterManager.gain_xp("speed", xp_per_kill * kills * 0.25)
	CharacterManager.gain_xp("accuracy", xp_per_kill * kills * 0.25)

	pending_offline_summary = {
		"kills": kills,
		"elapsed": elapsed,
		"drops": drops_summary,
	}

func _weighted_pick(entries: Array[DropEntry]) -> DropEntry:
	var total := 0.0
	for e in entries:
		total += e.weight
	var roll := randf() * total
	var cumulative := 0.0
	for e in entries:
		cumulative += e.weight
		if roll <= cumulative:
			return e
	return entries[-1]
