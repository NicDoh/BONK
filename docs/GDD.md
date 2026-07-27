# Game Design Document — [ARBEJDSTITEL: BONK?]

> Primitiv idle RPG til iOS og Android. Runescape-inspireret fokus på rare drops, collection logs og opdagelse frem for ren tal-progression.

---

## 0. Designprincipper (urokkelige)

- **Ingen lukkede døre** — spilleren kan altid skifte fokus og nå alt indhold på én karakter. Valg handler om hvad man prioriterer nu, ikke hvad man ofrer for altid. Alt kan maxes.
- **Opdagelse som drivkraft** — spilleren skal ikke altid vide hvad der venter. Drop tables, monstre og indhold afsløres gradvist.
- **Sjældne drops er kernen** — progression handler om jakten, ikke om at se tal stige hurtigt.
- **Systemer er uafhængige** — hvert system kan ændres og udvides uden at røre ved de andre.

---

## 1. Kernekoncept

Du er en hulemand eller stammemedlem i en primitiv verden. Du sender din karakter på idle-ekspeditioner i forskellige zoner. Dine drops bruges til at bygge og opgradere din by, som igen gør din karakter stærkere og åbner nyt indhold.

Spillet handler **ikke** om at se tal stige hurtigt. Det handler om jagten på sjældne drops, at complete collection logs og opdage hemmeligheder — ligesom Runescape's grind-kultur.

### Kerneloop
```
Equip gear (bestemmer hvilke stats der trænes + damage type)
        ↓
Vælg zone og mode
        ↓
Karakter kæmper automatisk i realtid (tick-baseret)
        ↓
Drops samles + stat XP optjenes fra gear-loadout
        ↓
Karakter dør eller ekspedition afsluttes → rewards hjem
        ↓
Brug ressourcer i byen (Forge, Research, osv.)
        ↓
Karakter bliver stærkere / nyt indhold unlocket
        ↓
[Gentag med nye zoner, modes og sværere monstre]
```

---

## 2. Tema & Æstetik

- **Setting:** Stenalderen / primitiv stamme-verden
- **Tone:** Sjov og charmerende — ikke seriøs dark fantasy. Hulemænd, klippetegninger, bål, mammutter.
- **Visuel stil:** [DISKUTERES — 2D pixel art? Tegnefilm? Minimalistisk?]
- **Navn:** [DISKUTERES]

---

## 3. Karakter

### Stats (besluttet)

Fem stats med egne levels. Alle kan maxes på samme karakter — ingen permanente valg.

| Stat | Funktion i kamp |
|------|----------------|
| **HP** | Overlevelses-tid — total sundhed |
| **Strength** | Skade per hit |
| **Defense** | Reducerer indgående skade |
| **Speed** | Angrebshastighed |
| **Accuracy** | Chance for at ramme |

### Stat-formel
```
Total Strength = base_from_level + gear_bonus + building_bonus + research_bonus
```
Stats gemmes aldrig direkte — beregnes altid live fra alle kilder. Ny kilde kan tilføjes uden at ændre eksisterende kode.

### Stat levels (Runescape-inspireret)
- Hver stat har sit eget level der stiger uafhængigt af de andre
- XP optjenes fra gear-loadout under kamp
- Levelcap: [DISKUTERES — 99 som Runescape?]
- Alle fem stats kan maxes på samme karakter

### Hvordan stats trænes (besluttet)

**Alt stat-træning bestemmes af dit gear — ingen separate systemer.**

#### Main hand våben → bestemmer offensiv stat XP

| Våbentype | Træner | Eksempler |
|-----------|--------|-----------|
| Tunge slag-våben | Strength | Bone Club, Stone Maul, War Axe, Cave Hammer |
| Lette hurtige våben | Speed | Bone Whip, Flint Dagger, Obsidian Knife, Claw Gauntlets |
| Præcisionsvåben (two-handed) | Accuracy | Spear, Crude Bow, Sling, Javelin |

#### Off-hand slot → bestemmer defensiv XP eller dobler offensiv

| Off-hand | Effekt |
|----------|--------|
| Skjold | + Defense XP (skalerer med monsters angrebsstyrke) |
| Andet våben (dual wield) | Dobler primær weapons XP — ingen Defense XP |
| Intet (two-handed main hand) | Ingen off-hand slot tilgængeligt |

#### HP → passiv, ingen beslutning nødvendig
- Træner fra hits modtaget i kamp
- Skalerer med monsters styrke — svage monstre giver minimal HP XP

#### XP skalerer med monster styrke
- Svage monstre = lav XP uanset gear
- Stærke monstre = høj XP
- Aldrig optimalt at farme svage monstre for stats

#### Eksempler på gear-kombinationer

| Loadout | Træner |
|---------|--------|
| Club + Shield | Strength + Defense |
| Club + Club | Strength × 2 |
| Dagger + Shield | Speed + Defense |
| Dagger + Club | Speed + Strength |
| Spear (two-handed) | Accuracy |
| Bow (two-handed) | Accuracy |

### Drop-chance bonusser
- Drop-rates er faste tal i monster-data (ingen Luck-stat)
- Gear, bygninger og research kan give % bonus til drop-chance
- Eksempel: "Ancient Totem — +15% rare drop chance fra skov-monstre"

### Damage types (besluttet)

Seks typer i alt. Fysiske typer er tilgængelige fra starten. Elementære typer introduceres med nye zoner.

| Type | Kategori | Våben | Introduceres |
|------|----------|-------|-------------|
| Blunt | Fysisk | Clubs, Mauls, Hammers | Fra start |
| Slash | Fysisk | Axes, Daggers, Claws, Whips | Fra start |
| Pierce | Fysisk | Spears, Bows, Javelins | Fra start |
| Fire | Elementær | Fire-tipped weapons, torches | Volcano zone |
| Poison | Elementær | Venomous blades, toxic darts | Swamp zone |
| Spirit | Elementær | Shamanic weapons, bone totems | Deep Cave / Ancient Ruins |

### Damage matrix per monster (besluttet)

Hvert monster har en multiplier per damage type:

| Kategori | Multiplikator |
|----------|--------------|
| Weak | ×1.5 |
| Neutral | ×1.0 |
| Resistant | ×0.5 |
| Immune | ×0.0 |

```
Stone Golem Boss:    Pierce Weak,  Blunt Immune,   Fire Resistant
Swamp Hydra Boss:   Fire Weak,    Poison Immune,  Slash Resistant
Ancient Spirit Boss: Spirit Weak, alle fysiske Immune
Fire Elemental Boss: Poison Weak, Fire Immune
```

- Weakness og resistance skjult i Museum indtil monsteret er researched
- Forkert weapon type mod en boss = nærmest umuligt
- Bosser kan have Challenge collection log entry: "Dræb med immune weapon type"

---

## 4. Ekspeditioner

### Grundprincip
- 100% idle — karakteren agerer automatisk
- Foregår i **realtid** mens appen er åben
- Ingen timer — varer indtil karakteren dør eller spilleren henter den hjem
- [DISKUTERES — Hvad sker der når appen lukkes?]

### Zoner
Overordnede områder med temaer. Nye zoner unlockes via Research Center og introducerer nye damage types, monstre og ressourcer.

```
Forest      → Blunt, Slash, Pierce  (startzone)
Cave        → Blunt, Pierce
Swamp       → Poison introduceres
Volcano     → Fire introduceres
Deep Cave   → Spirit introduceres  (sent i spillet)
```

### Expedition modes (besluttet)

UI'et vokser med spillerens progression — tidlig spil ser kun Roam.

| Mode | Tilgængelighed | Beskrivelse |
|------|---------------|-------------|
| **Roam** | Altid | Åben, random encounters, kæmper til død/recall |
| **Target Hunt** | Research unlock | Åben, ét specifikt monster, kæmper til død/recall |
| **Boss Run** | Research unlock | Bounded, ét forsøg mod zone-boss, høj risiko/reward |
| **Bounded activities** | Research unlock | Specifik run med defineret slutmål (Gather, Scout, osv.) |

**Scout** afslører hvilke monstre der findes i en zone → disse dukker op i Research Center → research afslører drop table og damage matrix i Museum → Target Hunt muligt.

### Kamp — tick-baseret (besluttet)

Kamp kører i ticks. Speed-stat bestemmer tick-hastighed.

**Hvert tick:**
```
1. Spiller angriber monster
   → Accuracy check: rammer du?
   → Hvis hit: skade = Strength × damage_type_multiplier
   → Stat XP optjenes (baseret på gear)

2. Monster angriber spiller
   → Hit check: rammer monsteret?
   → Hvis hit → Block check (shield equipped?)
       → Block: 0 skade + Defense XP
       → Ingen block: skade lander + HP XP

3. Monster død? → drops rulles, næste monster spawner
4. Spiller død? → ekspedition slutter, drops hjem
```

### Combat view — Shakes & Fidget-inspireret (besluttet)

Karakter og monster portræt side om side. Simpelt og læseligt på mobil.

```
┌─────────────────────────────────┐
│  [KARAKTER]        [GOBLIN]     │
│                                 │
│  ████████░░ HP     ████░░░░ HP  │
│                                 │
│  STR: 24   DEF: 12      -14 💥  │
│  SPD: 18   ACC: 20   MISS!      │
│                                 │
│  ⚔ Bone Club  🛡 Hide Shield    │
│                                 │
│  [      RECALL      ]           │
└─────────────────────────────────┘
```

- Damage-tal spawner, tweener opad og fader ud
- Lille shake på portræt ved hit
- Hvert monster har et portræt i sin Resource-fil
- Kamp-logik og UI er fuldstændigt adskilte via EventBus

---

## 5. Drops & Ressourcer

### Common ressourcer
- **Bones** — basismateriale fra de fleste monstre
- **Hide** — skind fra dyr-monstre
- Flere per zone: minerals, plantemateriale, lava-sten, osv.

### Rare drops
- Fast lav drop-chance i monster Resource-fil
- Kræves til bygningsopgraderinger, crafting og collection logs
- **Er kernen i spillet**

### Drop table-system
- Hvert monster har drops som `Array[DropEntry]` i sin Resource-fil
- Hver DropEntry: item, min/max quantity, chance (0.0–1.0)
- Drop table skjult indtil monsteret er researched

---

## 6. Data-strukturer (besluttet)

Alle spildata lever i Godot Resource-filer (`.tres`). Intet er hardkodet.

### ItemData
Basis for alt der kan ligge i inventory.
```
id, name, description, icon, rarity, stackable, max_stack
Rarity: COMMON / UNCOMMON / RARE / LEGENDARY
```

### GearData (extends ItemData)
Items med kamp-egenskaber.
```
slot: MAIN_HAND / OFF_HAND / HEAD / BODY / LEGS / FEET / AMULET / RING
two_handed: bool
damage_type: DamageType
bonus_hp, bonus_strength, bonus_defense, bonus_speed, bonus_accuracy: int
bonus_drop_chance: float
stackable: altid false
```

### FragmentData (extends ItemData)
Brudstykker af viden der kan kombineres til schematics eller andre rewards.
```
set_id: String          → hvilken samling tilhører fragmentet
fragment_index: int     → fragment nr. X i sættet
flavor_text: String     → selve indholdet: note, riddle, kort-tekst, gåde
```

Når alle fragmenter i et set er collected → "Combine" vises → produces schematic eller andet reward.

Fragment-typer (alle bruger samme struktur, flavor_text varierer):
- **Pages/Notes** — tekstfragmenter der tilsammen udgør instruktioner
- **Map pieces** — kombiner til et kort der afslører zone eller location
- **Riddle tablets** — giver hints om hvor næste fragment eller item findes
- **Puzzle pieces** — visuelle fragmenter der samles til et billede

### CraftingRecipe
Hvad Forge bruger og producerer.
```
id, result: ItemData, result_quantity
ingredients: Array[CraftingIngredient]  → { item: ItemData, quantity }
required_research: String               → research id (boolean unlock)
required_schematic_drop: ItemData       → sjælden schematic-drop (valgfrit)
is_chain_upgrade: bool                  → opgraderer eksisterende gear
```

### MonsterData
```
id, name, description, portrait, is_boss
Stats: hp, strength, defense, speed, accuracy
attack_damage_type: DamageType
Damage matrix: multiplier_blunt/slash/pierce/fire/poison/spirit (float)
drops: Array[DropEntry]  → { item: ItemData, min, max, chance }
```

### PetData
Basis-data for et pet. Pets er sjældne drops fra monstre og bosser.
```
id, name, description, portrait
rarity: COMMON / UNCOMMON / RARE / LEGENDARY

# Combat stats (skalerer med level når aktivt)
base_strength: int
base_speed: int
damage_type: DamageType

# Passiv bonus når pet er inaktivt
passive_bonus_type: String   # "drop_chance", "construction_speed", "xp_gain" osv.
passive_bonus_value: float
```

### PetInstance
En specifik ejet pet med progression.
```
pet_data: PetData
current_xp: float
level: int
```

Character har:
```
active_pet: PetInstance          # kæmper med, gainer XP fra skade
owned_pets: Array[PetInstance]   # alle inaktive pets — passive bonusser stakker
```

Pet-regler:
- Ét aktivt pet slot
- Aktivt pet angriber på sin egen tick (baseret på pet's Speed)
- Gains XP per skade gjort — skalerer naturligt med monster styrke
- Bidrager ~10-20% af spillerens kraft afhængig af sjældenhed
- Kan ikke dø — stopper kun når spilleren dør
- Alle inaktive pets giver passive bonusser simultant
- Pet collection log lever i Beast Den og/eller Museum

---

## 7. Tribe-bygninger

Spillerens base kaldes **the Tribe**. Kortet viser tribe'en oppefra med alle bygninger. Klikker man på en bygning går man ind i den.

### Bonkery (tidl. Forge)
Crafting-hub for våben, rustning og items. Selve Bonkery-bygningen har egne levels og ser visuelt anderledes ud på hvert level (fra primitivt bålsted til ordentlig smedje).

#### Crafting-typer

**Direkte (instant)** — tidlig spil, simple materialer:
```
Bones + Hide → Bone Club
```

**Kæde (instant per trin)** — mellemspil, kræver mellemprodukter:
```
Iron Ore → Iron Bar → Iron Club
```

**Legendarisk (instant men svær at samle materialer)** — kræver rare drops fra flere zoner:
```
Iron Bar + Dragon Scale (Volcano) + Ancient Marrow (Deep Cave) + Spirit Ember (boss drop)
  → Legendary Fire Blade
```

**Kæde-opgradering** — avanceret gear kan opgraderes frem for at erstattes:
```
Legendary Fire Blade + Volcanic Core (boss) + Ash Crystal × 5
  → Sacred Fire Blade  (ny collection log entry)
```
Standard gear erstattes altid. Kun legendarisk/avanceret gear kan opgrades.

#### Unlock-system
- **Research Center boolean unlock** — de fleste opskrifter unlockes via research
- **Schematic drops** — sjældne fysiske items fra monstre der unlocker specielle opskrifter
- **Fragment schematics** — saml fragmenter (notes, maps, riddles) og kombiner dem til et schematic

#### Bygnings-upgrades
Koster ressourcer + tid. Visse levels kræver desuden et schematic-drop som item:
```
Forge Level 1: basis (fra start)
Forge Level 2: Stone + tid
Forge Level 3: Iron Bars + tid + "Advanced Forge Plans" (research unlock)
Forge Level 4: Rare materials + tid + "Ancient Forge Manual" (fragment schematic)
```

### Thinkery (tidl. Research Center)
Spillets **opdagelses- og unlock-motor**. Alt nyt indhold går igennem Thinkery.

#### Pris og tid (besluttet)
Koster **både ressourcer og tid**. Ressourcer betales med det samme, derefter venter man.
```
Tidlig research:  billige ressourcer + minutter
Sen research:     sjældne drops + dage
```

#### Én ad gangen (besluttet)
Én aktiv research ad gangen. Giver mening til valget. Muligvis flere slots sent via Research Center bygnings-opgradering.

#### Forsker-mekanik (besluttet)
**Tidlig spil:** Kun spillerens karakter kan researche — valget er expedition eller research, ikke begge.

**Sent unlock: NPC Forsker** via Ogg's Hearth. Research kører i baggrunden mens karakteren expediter — men langsommere eller dyrere:
```
Forsker alene:    Langsomt, karakter expediter frit
Selv researcher:  Hurtigere, expedition stopper
```
Forskeren er sandsynligvis første NPC der unlockes og en kæmpe milestone.

#### Progressiv afsløring (besluttet)
Spilleren ser **aldrig mere end hvad der er relevant nu.** Early game: 3-4 valg. Late game: 8-10 valg. Research afslører sin dybde gradvist.

#### Interne kategorier
Character · City · Expedition · Crafting · Knowledge
Kategorier og indhold vises gradvist — Knowledge vises f.eks. først efter første Scout.

#### Interface
[DISKUTERES — præsentation designes når vi bygger det]

#### Data-struktur (ResearchData)
```gdscript
id, title, description, category
cost_resources: Array[CraftingIngredient]
duration_seconds: float
prerequisites: Array[String]       # andre research ids
visible_conditions: Array[String]  # hvad trigger synlighed
unlocks: Array[String]             # hvad giver det
```

Kan unlock: zoner, expedition modes, monster-viden, by-bygninger, Forge-schematics, % bonusser, quest-indhold og meget mere.

### Ogg's Hearth (tidl. Camp/Hub + Ancestor's Altar)
Tribe'ens sociale centrum og ildsted. To formål flettet sammen:

**Socialt/narrativt:**
- NPC'er sidder rundt om bålet — nye karakterer dukker op efterhånden som spillet skrider frem
- Rygter, gåder og hints om monstre og zoner
- Storyline og quest-indhold
- Første NPC er sandsynligvis Ogg selv

**Burn-mekanik (tidl. Ancestor's Altar):**
- Offer/brænd store mængder common ressourcer mod større mål
- Sjældne research unlocks, permanente bonusser, special items, collection log entries
- Giver common ressourcer mening i endgame

### Oddities (tidl. Museum / Collection Log)
**En af spillets største features.**

#### Kategorier
```
MUSEUM
├── Monsters       → entries per monster og boss
├── Items          → alle unikke items fundet
├── Lore           → fragmenter, schematics, riddles
├── Achievements   → challenge entries og særlige bedrifter
└── World          → zoner, aktiviteter, bosser besejret
```

#### Entry-typer per monster
```
STONE GOLEM BOSS
├── First kill
├── Rare drop: Ancient Core
├── Challenge: Kill with Blunt weapon  (immune type)
├── Challenge: Kill without damage
└── Speed kill: Under 60 sekunder
```

#### Lore-sektionen — fragment tracking
```
LORE
├── Ancient Forge Manual    [3/3 pages] ✓  → Forge Level 4 unlocked
├── Volcano Weapons Plans   [2/4 pieces]   ← mangler stadig
├── Cave Shaman Riddle      [løst] ✓
└── Torn Expedition Map     [1/3]          ← mystisk, peger mod ny zone
```

- Entries skjulte indtil opdaget
- Challenge-entries registreres automatisk fra kampbetingelser
- Lore-entries tracker fragment-progress og viser flavor text
- Complete en log → rewards og achievements
- Endgame-driver langt efter stats og gear er maxet

Drop-rates vist i loggen: [DISKUTERES]

### Tamery (tidl. Beast Den)
Ejer alt pet-relateret. Administrer aktivt pet, se alle ejede pets og passive bonusser.
Bonusser per level: [DISKUTERES]

### Scoutery (tidl. Watchtower)
Ejer exploration-domænet. Scout runs og zone-afsløring hører hjemme her fremfor Thinkery.
Bonusser per level: [DISKUTERES]

### Øvrige bygninger
Kan altid tilføjes — en ny bygning = en ny BuildingData Resource-fil. Ingen eksisterende kode røres.
Alle bygningers level-bonusser designes grundigt når de er relevante — intet placeholders.

---

## 8. Progression & Endgame

### Tidlig spil
- Forest zone, Roam mode, byg Forge og Camp
- Lær kerneloopen: gear → expedition → drops → craft → stærkere

### Midspil
- Scout → Research → Target Hunt
- Nye zoner med nye damage types og monstre
- Collection logs begynder at fyldes

### Endgame
- Bedste gear (sjældne drops + elementære damage types)
- Sværeste bosser med komplekse damage matrices
- Complete alle collection logs inkl. challenge entries
- Max alle fem stat levels
- Prestige/rebirth: [DISKUTERES]

---

## 9. Monetisering [DISKUTERES]
- **Vigtigt:** Sjældne drops må ikke købes for penge
- Cosmetics? Reklamer? Tidsbegrænsede events?

---

## 10. Platform
- **iOS og Android** via Godot 4
- Touch-first UI
- Portrait eller landscape: [DISKUTERES]

---

## 11. Save System (besluttet)

### Tilgang
Lokal save først. Server (Nakama eller lignende) tilføjes når spillet er færdigt og bevist. PvP og clans er en fremtidig ambition — intet i arkitekturen må lukke den dør.

### Format
JSON via Godot's `FileAccess`. Simpelt, menneskeligt læseligt, ingen afhængigheder.

### Arkitekturprincip
**SaveManager er det eneste sted der rører data-storage.** Game logic ved aldrig om den taler med en fil eller en server. Når server tilføjes, udskiftes kun SaveManager's implementation — intet andet ændres.

```
Game logic → SaveManager → [JSON fil nu]
                         → [Nakama server senere]
```

### Hvad gemmes
```
character      → stat levels, XP, equipped gear
inventory      → alle items og mængder
city           → bygninger og levels
research       → completed research + aktiv research + timer
expedition     → aktiv? zone? mode? tidspunkt sendt af sted?
collection_log → hvad er fundet og completed
fragments      → hvilke fragments er collected
settings       → spilindstillinger
```

### Hvert Manager serialiserer sit eget data
```gdscript
func save_game():
    var data = {
        "inventory":      InventoryManager.serialize(),
        "city":           CityManager.serialize(),
        "character":      CharacterManager.serialize(),
        "research":       ResearchManager.serialize(),
        "collection_log": CollectionLogManager.serialize(),
        "expedition":     ExpeditionManager.serialize()
    }
    # skriv til fil
```

### Hvornår gemmes der
- På vigtige events (expedition slutter, item craftes, building opgraderes)
- Når appen pauses/lukkes (safety net)

### Korruptions-sikring
To backup-filer (`save_a.json` og `save_b.json`) der alternerer. Hvis én er korrupt loades den anden.

### Fremtidig server-migration
- Alle events har timestamps — nødvendigt for offline progress og server sync
- Spilleren har en UUID fra dag ét — bliver account identifier på server
- Nakama er det primære kandidat (open source, native Godot support, clans + matchmaking built-in)

---

## 12. Offline Progress (besluttet)

### Hvad fortsætter offline
| System | Offline? |
|--------|----------|
| Roam expedition | Ja |
| Target Hunt | Ja |
| Boss Run | Nej — kræver aktiv beslutning |
| Bounded activities | Nej — kræver aktiv beslutning |
| Research timer | Ja |
| Building upgrade timer | Ja |

### Offline cap
Starter på **0** — ingen offline progress før det er researched. Det første unlock er en ægte milestone.

Progression via Research Center:
```
Start:                  0 timer   (skal holde appen åben)
"First Rest":           2 timer   ← første store milestone
"Rested Wanderer I":    4 timer
"Rested Wanderer II":   6 timer
"Rested Wanderer III":  8 timer
"Rested Wanderer IV":   12 timer
"Ancient Endurance":    24 timer  (late game)
```

Præcise timetal og antal trin justeres under balancering — værdien hentes altid fra ResearchManager, aldrig hardkodet.

### Karakterdød offline
Karakteren kæmper til den dør — drops og XP fra det tidspunkt gemmes. Karakteren er hjemme når spilleren åbner appen. Ingen tab.

### Beregning
```
elapsed      = current_time - save_timestamp
simulated    = min(elapsed, offline_cap)
simulated    = min(simulated, time_until_death)
drops + xp   = simulate(simulated, zone, mode, character_stats)
```

### "Åbn presenter"-skærm
Når spilleren vender tilbage vises et summary:
```
Du var væk i 4 timer.
Monstre dræbt: 142
Bones ×284  Hide ×96
⚡ Rare drop: [item]!
Strength XP: +450  HP XP: +230
```

---

## 13. Inventory (besluttet)

### Koncept
Inventory fungerer som en **bank** — ét samlet sted for alle items. Kan blive rodet med mange items, men spilleren kan organisere den pænt via sortering.

### Ressource-cap
Høj cap per ressource-type. Præcis tal bestemmes under balancering — gemt i config-fil, aldrig hardkodet. Let at justere.

### Sortering
Ingen faste tabs. Spilleren sorterer efter behov:
```
[ Type ]  [ Sjældenhed ]  [ Zone ]  [ Nylig fundet ]
```

### Fuld inventory under expedition
Drops går tabt. Spillerens ansvar at holde inventory ryddeligt. Skaber reel grund til at bruge burn-mekanikken og tjekke inventory inden lange expeditioner.

### Gear
Ikke stackable, men man kan have flere af samme item. Fremtidig markedsværdi i multiplayer-version.

**Salvage i Forge** — gear kan nedbrydes til et par ressourcer direkte i Forge UI. Ingen separat system.

### Burn-mekanik (Ogg's Hearth)
Offer store mængder common ressourcer mod større mål:
- Sjældne research unlocks
- Permanente bonusser
- Special items der ikke kan fås andre steder
- Collection log entries

Giver common ressourcer mening i endgame og er en naturlig måde at tømme overskud på inden expedition.

---

## 14. EventBus (besluttet)

Global Godot autoload. Alle systemer kommunikerer udelukkende via EventBus — ingen direkte referencer mellem managers.

```gdscript
# autoload/EventBus.gd
extends Node

# Kamp
signal player_hit_monster(damage: float, damage_type: DamageType, multiplier: float)
signal player_missed()
signal monster_hit_player(damage: float)
signal player_blocked(damage: float)
signal monster_missed()
signal pet_hit_monster(damage: float, damage_type: DamageType)
signal monster_died(monster_data: MonsterData)
signal player_died()

# XP og levels
signal stat_xp_gained(stat_name: String, amount: float)
signal stat_leveled_up(stat_name: String, new_level: int)
signal pet_xp_gained(pet_instance: PetInstance, amount: float)
signal pet_leveled_up(pet_instance: PetInstance, new_level: int)

# Items og drops
signal item_obtained(item_data: ItemData, quantity: int)
signal item_removed(item_data: ItemData, quantity: int)
signal fragment_obtained(fragment_data: FragmentData)
signal pet_obtained(pet_data: PetData)
signal inventory_full()

# Ekspedition
signal expedition_started(zone_id: String, mode: String)
signal expedition_ended(result: Dictionary)
signal offline_progress_applied(duration: float, summary: Dictionary)

# Research og unlocks
signal research_started(research_data: ResearchData)
signal research_completed(research_data: ResearchData)
signal content_unlocked(unlock_id: String)

# By og bygninger
signal building_upgrade_started(building_id: String, new_level: int)
signal building_upgrade_completed(building_id: String, new_level: int)
signal item_crafted(recipe_id: String, result: ItemData)
signal item_salvaged(gear_data: GearData)
signal resources_burned(resource_id: String, quantity: int)

# Collection log
signal collection_entry_completed(entry_id: String)
signal fragment_set_completed(set_id: String)
```

Signals tilføjes løbende når nye systemer bygges. EventBus starter med kamp- og drop-signals (kernen i game loopet).

---

## ÅBNE DISKUSSIONSPUNKTER
- [ ] Stat levelcap (99?)
- [ ] Ogg's Hearth og NPC-system
- [ ] Questtyper
- [ ] Vises drop-rates i Oddities?
- [ ] Monetisering
- [ ] Visuel stil
- [ ] Spiltitel
- [ ] Tattoos som prestigesystem — trigger ukendt (stat milestones, collection log, zone completion eller kombination). Vises visuelt på karakteren. Diskuteres til phase 3/8.
- [ ] Portrait vs. landscape
- [ ] Bygnings-level bonusser (alle bygninger — diskuteres når relevant)
- [ ] Inventory-skærm navn (spillerens stash/loot)
