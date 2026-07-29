extends Node

# Combat
signal player_hit_monster(damage: int, damage_type: int, multiplier: float)
signal player_missed()
signal monster_hit_player(damage: int)
signal player_blocked(damage: int)
signal monster_missed()
signal pet_hit_monster(damage: int, damage_type: int)
signal monster_died(monster_data: MonsterData)
signal player_died()

# XP
signal stat_xp_gained(stat_name: String, amount: float)
signal stat_leveled_up(stat_name: String, new_level: int)
signal training_focus_changed(stat_name: String)
signal pet_xp_gained(pet_instance: PetInstance, amount: float)
signal pet_leveled_up(pet_instance: PetInstance, new_level: int)

# Items
signal item_obtained(item_data: ItemData, quantity: int)
signal item_removed(item_data: ItemData, quantity: int)
signal fragment_obtained(fragment_data: FragmentData)
signal pet_obtained(pet_data: PetData)
signal inventory_full()

# Expedition
signal expedition_started(zone_id: String, mode: String)
signal expedition_ended(result: Dictionary)
signal monster_spawned(monster: MonsterData)
signal offline_progress_applied(duration: float, summary: Dictionary)

# Research
signal research_started(research_data: ResearchData)
signal research_completed(research_data: ResearchData)
signal content_unlocked(unlock_id: String)

# City
signal building_upgrade_started(building_id: String, new_level: int)
signal building_upgrade_completed(building_id: String, new_level: int)
signal item_crafted(recipe_id: String, result: ItemData)
signal item_salvaged(gear_data: GearData)
signal resources_burned(resource_id: String, quantity: int)

# Refinement
signal refinement_queued(recipe: RefinementRecipe, batches: int)
signal refinement_completed(recipe: RefinementRecipe)

# Collection log
signal collection_entry_completed(entry_id: String)
signal fragment_set_completed(set_id: String)
