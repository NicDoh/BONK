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
