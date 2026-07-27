# Devlog

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
