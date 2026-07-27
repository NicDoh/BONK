extends Node

enum Mode { ROAM }

var active: bool = false
var current_zone_id: String = ""
var current_mode: Mode = Mode.ROAM
var current_monster: MonsterData = null

var _player_tick_timer: float = 0.0
var _monster_tick_timer: float = 0.0
var _monster_hp: int = 0

func _process(delta: float) -> void:
	if not active:
		return

	_player_tick_timer += delta
	if _player_tick_timer >= _get_player_tick_interval():
		_player_tick_timer = 0.0
		_player_attack()
		if _monster_hp <= 0:
			_on_monster_died()
			return

	_monster_tick_timer += delta
	if _monster_tick_timer >= _get_monster_tick_interval():
		_monster_tick_timer = 0.0
		_monster_attack()
		if not CharacterManager.is_alive():
			_on_player_died()

func start(zone_id: String, monster: MonsterData, mode: Mode = Mode.ROAM) -> void:
	if active:
		return
	current_zone_id = zone_id
	current_mode = mode
	current_monster = monster
	_monster_hp = monster.hp
	_player_tick_timer = 0.0
	_monster_tick_timer = 0.0
	active = true
	CharacterManager.heal_to_full()
	EventBus.expedition_started.emit(zone_id, Mode.keys()[mode])

func recall() -> void:
	if not active:
		return
	active = false
	current_monster = null
	EventBus.expedition_ended.emit({"reason": "recalled"})

func _player_attack() -> void:
	var accuracy := CharacterManager.get_effective_stat("accuracy")
	var hit_chance := clampf(accuracy / float(accuracy + current_monster.defense) , 0.05, 0.95)

	if randf() > hit_chance:
		EventBus.player_missed.emit()
		return

	var strength := CharacterManager.get_effective_stat("strength")
	var damage := maxi(1, strength - current_monster.defense / 2)
	var multiplier := _get_damage_multiplier()
	var final_damage := int(damage * multiplier)

	var damage_type := GearData.DamageType.BLUNT
	if CharacterManager.equipped_main_hand:
		damage_type = CharacterManager.equipped_main_hand.damage_type

	_monster_hp -= final_damage
	EventBus.player_hit_monster.emit(final_damage, damage_type, multiplier)

	_grant_weapon_xp(final_damage)

func _monster_attack() -> void:
	var monster_acc := current_monster.accuracy
	var player_def := CharacterManager.get_effective_stat("defense")
	var hit_chance := clampf(monster_acc / float(monster_acc + player_def), 0.05, 0.95)

	if randf() > hit_chance:
		EventBus.monster_missed.emit()
		CharacterManager.gain_xp("defense", 1.0)
		return

	var damage := maxi(1, current_monster.strength - player_def / 2)

	# Block check (off-hand shield)
	if CharacterManager.equipped_off_hand and CharacterManager.equipped_off_hand.slot == GearData.Slot.OFF_HAND:
		var block_chance := clampf(player_def / float(player_def + current_monster.strength), 0.0, 0.6)
		if randf() < block_chance:
			EventBus.player_blocked.emit(damage)
			CharacterManager.gain_xp("defense", 2.0)
			return

	CharacterManager.take_damage(damage)
	EventBus.monster_hit_player.emit(damage)
	CharacterManager.gain_xp("hp", float(damage) * 0.5)

func _on_monster_died() -> void:
	EventBus.monster_died.emit(current_monster)
	_roll_drops()
	_spawn_next_monster()

func _on_player_died() -> void:
	active = false
	EventBus.player_died.emit()
	EventBus.expedition_ended.emit({"reason": "died"})

func _roll_drops() -> void:
	for entry in current_monster.drops:
		var drop_bonus := 0.0
		if CharacterManager.equipped_main_hand:
			drop_bonus = CharacterManager.equipped_main_hand.bonus_drop_chance
		if CharacterManager.equipped_off_hand:
			drop_bonus += CharacterManager.equipped_off_hand.bonus_drop_chance

		var roll := randf()
		var adjusted_weight := entry.weight * (1.0 + drop_bonus)
		if roll < adjusted_weight:
			var qty := randi_range(entry.quantity_min, entry.quantity_max)
			InventoryManager.add_item(entry.item, qty)

func _spawn_next_monster() -> void:
	_monster_hp = current_monster.hp
	_player_tick_timer = 0.0
	_monster_tick_timer = 0.0

func _grant_weapon_xp(damage: int) -> void:
	if not CharacterManager.equipped_main_hand:
		CharacterManager.gain_xp("strength", float(damage) * 0.5)
		return

	var weapon := CharacterManager.equipped_main_hand
	var xp := float(damage)

	if weapon.two_handed:
		CharacterManager.gain_xp("strength", xp * 0.5)
		CharacterManager.gain_xp("speed", xp * 0.25)
		CharacterManager.gain_xp("accuracy", xp * 0.25)
	else:
		match weapon.slot:
			GearData.Slot.MAIN_HAND:
				CharacterManager.gain_xp("strength", xp * 0.5)
				CharacterManager.gain_xp("speed", xp * 0.25)
				CharacterManager.gain_xp("accuracy", xp * 0.25)

func _get_damage_multiplier() -> float:
	if not CharacterManager.equipped_main_hand:
		return 1.0
	match CharacterManager.equipped_main_hand.damage_type:
		GearData.DamageType.BLUNT:   return current_monster.multiplier_blunt
		GearData.DamageType.SLASH:   return current_monster.multiplier_slash
		GearData.DamageType.PIERCE:  return current_monster.multiplier_pierce
		GearData.DamageType.FIRE:    return current_monster.multiplier_fire
		GearData.DamageType.POISON:  return current_monster.multiplier_poison
		GearData.DamageType.SPIRIT:  return current_monster.multiplier_spirit
	return 1.0

func _get_player_tick_interval() -> float:
	var speed := CharacterManager.get_effective_stat("speed")
	return clampf(3.0 - (speed * 0.05), 0.5, 3.0)

func _get_monster_tick_interval() -> float:
	if not current_monster:
		return 3.0
	return clampf(3.0 - (current_monster.speed * 0.05), 0.5, 3.0)

func serialize() -> Dictionary:
	return {
		"active": active,
		"zone_id": current_zone_id,
	}
