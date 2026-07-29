# Devlog

## 2026-07-29 — Session 5: Gear slots, resistances, refinement og Crude-tier våben

### Gear slots
- GearData.Slot enum opdateret: MAIN_HAND/OFF_HAND → WEAPON, SHIELD, HEAD, BODY, LEGS, BOOTS, GLOVES, AMULET, CHARM, CAPE, QUIVER
- CharacterManager refaktoreret til `equipped: Dictionary` (slot int → GearData) i stedet for individuelle vars
- Tilføjet `get_equipped(slot)`, `get_total_drop_bonus()`, `get_resistance(damage_type)`
- CharacterScreen opdateret til at vise alle 11 slots dynamisk

### Attack types og armor resistances
- MonsterData: fjernede duplikeret DamageType enum — bruger nu GearData.DamageType
- Monstre har `attack_damage_type` (Blunt/Slash/Pierce/Fire/Poison/Spirit)
- GearData fik 6 resistance-felter (resistance_blunt osv.) — 0.0 = neutral, 0.5 = halvt skade, negativ = sårbar
- ExpeditionManager anvender nu `get_resistance()` på indgående skade

### Refinement-system
- `RefinementRecipe` resource: inputs (Array[CraftingIngredient]), tool_item (reusable), output, duration, required_unlock
- `RefineryManager` autoload: kø-baseret, items forbruges ved queue, 1 batch ad gangen med timer, serialize/deserialize
- Refinement-kø vises og styres i BonkeryScreen med SpinBox til antal batches
- ResourceRegistry loader nu refinement recipes fra res://data/refinement/
- SaveManager gemmer/gendanner refinery-kø

### Nye items og recipes
- Items: Carved Bone, Leather, Silk
- Refinement recipes:
  - 5 Bones → 1 Carved Bone (5s)
  - 3 Hide + 1 Thread + Needle (tool) → 1 Leather (5s)
  - 1 Silk Gland → 3 Silk (5s)
- Raw Bones bruges stadig til bygninger; Carved Bone bruges til weapons/armor

### Crude-tier våben (tidl. Bone-tier)
- Tier omdøbt til "Crude" — dækker alle primitive materialer, ikke kun knogle
- Crude Club (Blunt 1H): +2 STR +1 SPD — 1 Carved Bone + 1 Hide
- Crude Axe (Slash 1H): +3 STR +1 ACC — 2 Carved Bone + 1 Leather
- Crude Spear (Pierce 2H): +3 STR +1 SPD +2 ACC — 3 Carved Bone + 2 Thread
- Spiked Club (Blunt 1H): +4 STR +1 SPD — 1 Carved Bone + 3 Spikes

### Bugfix
- InventoryManager: `get_quantity`, `has_item` og `remove_item` håndterede ikke non-stackable items korrekt (brugte item.id som slot key, men non-stackable items gemmes med unik slot key). Alle tre funktioner itererer nu alle slots.

## 2026-07-26 — Session 1: Projektstart
- Koncept defineret: primitiv idle RPG, Runescape-inspireret, fokus på rare drops og collection logs
- GDD oprettet, CLAUDE.md oprettet
- Godot 4, iOS + Android

## 2026-07-27 — Session 2: Design og arkitektur
GDD færdiggjort med alle arkitektur-kritiske systemer besluttet:
- 5 stats, gear-baseret træning, damage types (6), weapon/shield system
- Zone modes (Roam, Target Hunt, Boss Run, Bounded), tick-baseret kamp
- Data-strukturer: ItemData, GearData, FragmentData, CraftingRecipe, MonsterData, PetData, PetInstance
- Fragment/schematic system (notes, riddles, maps der kombineres)
- Save system (lokal JSON, server-klar arkitektur med Nakama som mål)
- Offline progress (starter på 0, unlockes via Research)
- Inventory (bank-model, høj cap, drops tabt ved fuld)
- Research Center (ressourcer + tid, progressiv afsløring, forsker-NPC)
- City layout (faste pladser, alle bygninger besluttet)
- Pets (aktivt pet kæmper + XP, inaktive giver passive bonusser)
- EventBus arkitektur besluttet

## 2026-07-28 — Session 4: Navigation, zoner og drops

### Navigation
- Main.gd omskrevet til multi-screen navigation: Expedition, Character, Tribe, Bonkery, Thinkery
- Expedition-skærm har tre views: world (zoneliste), zone (aktiviteter), combat
- CharacterManager.deserialize rettede bug: gear blev ikke gendannet ved load

### Zone-system
- ZoneData resource: id, name, description, roam_monsters (Array[ZoneMonsterEntry]), boss, required_unlock
- ZoneMonsterEntry resource: monster + weight (til vægtbaseret tilfældig spawning)
- ResourceRegistry loader nu zoner fra res://data/zones/
- ExpeditionManager tager nu ZoneData i stedet for enkelt monster, picker tilfældig monster via vægte
- EventBus: monster_spawned signal tilføjet
- Første zone: The Outskirts med fire monstre

### Drop-system
- MonsterData fik tre separate drop tables: drops_guaranteed, drops_common, drops_rare, drops_ultra_rare
- drops_guaranteed: altid drop, ingen roll
- drops_common: pick one per kill via vægte
- drops_rare: aktiveres med rare_table_chance, hvert entry rulles uafhængigt
- drops_ultra_rare: aktiveres med ultra_rare_table_chance, hvert entry rulles uafhængigt
- GameManager offline progress opdateret til nye tabeller
- Planlagt: set drop protection (bad luck mitigation for item-sæt)

### Monstre — The Outskirts
- Spikeback (pindsvin): Bones/Meat common, Spikes rare, Needle ultra rare
- Skitternut (egern): Meat/Bones/Hide common, Golden Acorn rare
- Bluedart (roller-fugl): Feathers/Meat common
- Tangler (edderkop): Thread guaranteed, Silk Gland common, Venom Sac rare

### Items oprettet
Meat, Feathers, Spikes, Needle, Golden Acorn, Thread, Silk Gland, Venom Sac

### Gear tiers besluttet
Bone → Flint → Copper → ... → Crystal → Spirit → Ancient → Astral
GearData fik tier: int felt

### Næste skridt
- Opret Godot-projekt
- Sæt mappestruktur op
- Skriv alle Resource-klasser
- Sæt EventBus og tomme Managers op som autoloads

## 2026-07-27 — Session 3: Godot setup, kerneloop og by-systemer

### Fase 0 — Godot Setup
- Godot 4.5.1 projekt oprettet i `/bonk/` med Mobile renderer
- Mappestruktur oprettet: autoloads, resources, data, scenes, assets
- Alle 11 Resource-klasser skrevet (ItemData, GearData, FragmentData, CraftingIngredient, CraftingRecipe, DropEntry, MonsterData, PetData, PetInstance, ResearchData, BuildingData)
- EventBus oprettet med alle signals
- 10 Manager autoloads registreret (EventBus først, derefter ResourceRegistry, GameManager osv.)
- GitHub repo oprettet og offentliggjort: github.com/NicDoh/BONK

### Fase 1 — Kerneloop
- CharacterManager: 5 stats med XP og level-up, gear-bonusser, HP-beregning, serialize/deserialize
- InventoryManager: tilføj/fjern items, stackable/non-stackable, inventory cap
- ExpeditionManager: separate tick-timers for spiller og monster baseret på Speed-stat, hit/miss/block, skadeberegning med damage matrix, drop-rolling
- SaveManager: lokal JSON gem/load, auto-save ved luk/pause
- Basic combat UI: HP bars, kamplog, stats i realtid, inventory
- Testmonster oprettet som .tres fil med Bones og Hide som drops

### Fase 2 — By og crafting
- CityManager: bygnings-levels og upgrade-timer med ressource-cost
- CraftingManager: opskrifter, ingredient-check, craft og fjern materialer
- ResourceRegistry: central lookup for alle items/gear/research — erstatter disk-scan ved save-load
- Bonkery: crafting UI med ingrediens-visning, craft-knap, equip/unequip gear
- Thinkery (Research Center): ResearchManager med prerequisites, visible conditions, unlock-system
- Offline progress: beregnes ved opstart hvis unlocked — kills, XP og drops simuleret
- Test-items: Bones, Hide (stackable drops), Bone Club (main hand gear, +2 str +1 speed)
- Test-research: Offline Progress (10s, unlocker offline_progress)
- Test-bygning: Bonkery (3 levels, 10/30/60s upgrade-tider)

### Navne besluttet
Tribe (base), Bonkery (Forge), Thinkery (Research Center), Ogg's Hearth (Camp + Ancestor's Altar), Oddities (Museum), Tamery (Beast Den), Scoutery (Watchtower)

### Tekniske beslutninger
- Separate attack timers (ikke fælles tick) — Speed-stat giver reel forskel for monstre
- ResourceRegistry som autoload #2 — loader alle .tres ved start, ingen disk-scan bagefter
- Offline summary gemmes i GameManager.pending_offline_summary og vises når scenen er klar
- ExpeditionManager gemmer monster_path i save så offline progress kan beregnes
