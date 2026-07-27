# BONK — Projekt-kontekst for Claude

## Hvad er dette projekt?
Primitiv idle RPG til iOS og Android bygget i Godot 4. Runescape-inspireret fokus på rare drops, collection logs og opdagelse. Ikke et typisk idle-spil med bare tal der stiger — spillet handler om jagten på sjældne ting og at complete alt.

## Vigtige regler
- **GDD-eksempler er kun illustrationer** — brugeren beslutter selv alle items, monstre, zoner og indhold. Aldrig foreslå eller hardkod specifikt indhold.
- **Bygnings-level bonusser diskuteres grundigt** når de er relevante — ingen placeholders.
- **Systemer er uafhængige** — kommunikation kun via EventBus, aldrig direkte referencer.
- **Ingen lukkede døre** — alt kan maxes, ingen permanente valg der lukker indhold.

## Kerneloop
```
Equip gear → vælg zone og mode → kamp i realtid (tick-baseret)
→ drops + stat XP → brug drops i byen → stærkere karakter → nye zoner
```

## Karakter & Stats
5 stats med egne levels: HP, Strength, Defense, Speed, Accuracy
- Main hand våben → Strength / Speed / Accuracy XP
- Off-hand shield → Defense XP | Dual wield → dobbelt primær XP
- HP → passiv fra hits modtaget, skalerer med monster styrke
- 6 damage types: Blunt, Slash, Pierce, Fire, Poison, Spirit
- Monster damage matrix: Weak(×1.5) / Neutral(×1.0) / Resistant(×0.5) / Immune(×0.0)

## Ekspedition modes
Roam (altid) → Target Hunt → Boss Run → Bounded activities (alle via Research unlock)
- Ingen timer — varer til karakteren dør eller spilleren henter den hjem
- Offline progress starter på 0, unlockes og udvides via Research

## Pets
- Ét aktivt pet slot — kæmper med, gainer XP per skade
- Alle inaktive pets giver passive bonusser simultant
- Sjælde drops fra monstre — stor collection log-kategori

## By-bygninger
Forge · Research Center · Camp/Hub · Museum · Beast Den
Watchtower · Trading Post · Warehouse · Ancestor's Altar
- Faste pladser, visuel progression
- Kan altid udvides med ny bygning (ny BuildingData Resource-fil)
- Alle bygnings-level bonusser designes grundigt når relevant

## Research Center
- Koster ressourcer + tid
- Én aktiv research ad gangen
- Tidlig spil: karakter researcher (blokkerer expedition)
- Sent unlock: NPC forsker der kører i baggrunden
- Progressiv afsløring — aldrig overvældende

## Data-strukturer (alle i res://resources/)
ItemData · GearData · FragmentData · CraftingRecipe · CraftingIngredient
DropEntry · MonsterData · PetData · PetInstance · ResearchData · BuildingData

## Arkitektur
- **EventBus** (autoload) — al kommunikation mellem systemer
- **Managers** (autoloads): GameManager, SaveManager, InventoryManager,
  ExpeditionManager, CharacterManager, CityManager, ResearchManager,
  CollectionLogManager, PetManager
- **SaveManager** er eneste sted der rører data-storage
- Lokal JSON nu, Nakama server når spillet er færdigt
- Alt spildata i .tres Resource-filer — intet hardkodet

## Mappestruktur (Godot projekt)
```
res://
├── autoloads/     → EventBus + alle Managers
├── resources/     → alle Resource-klasser (.gd)
├── data/          → alle .tres datafiler (items, monstre, osv.)
├── scenes/        → UI og gameplay scenes
└── assets/        → teksturer, lyd
```

## Dokumenter
- `docs/GDD.md` — fuldt game design document
- `docs/DEVLOG.md` — løbende log
