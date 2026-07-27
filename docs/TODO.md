# BONK — Todo & Roadmap

> Kryds af efterhånden som vi kommer igennem. Hvert fase er et naturligt delmål der kan testes og føles komplet.

---

## FASE 0 — Godot Setup
*Mål: Et tomt men korrekt struktureret Godot-projekt klar til kode*

- [ ] Opret Godot projekt i `/game/`
- [ ] Opret mappestruktur (autoloads, resources, data, scenes, assets)
- [ ] Skriv Resource-klasser
  - [ ] ItemData.gd
  - [ ] GearData.gd
  - [ ] FragmentData.gd
  - [ ] CraftingIngredient.gd
  - [ ] CraftingRecipe.gd
  - [ ] DropEntry.gd
  - [ ] MonsterData.gd
  - [ ] PetData.gd
  - [ ] PetInstance.gd
  - [ ] ResearchData.gd
  - [ ] BuildingData.gd
- [ ] Opret EventBus.gd med alle signals
- [ ] Opret tomme Manager autoloads
  - [ ] GameManager.gd
  - [ ] SaveManager.gd
  - [ ] CharacterManager.gd
  - [ ] InventoryManager.gd
  - [ ] ExpeditionManager.gd
  - [ ] CityManager.gd
  - [ ] ResearchManager.gd
  - [ ] CollectionLogManager.gd
  - [ ] PetManager.gd
- [ ] Registrer alle autoloads i Project Settings

---

## FASE 1 — Kerneloop (MVP)
*Mål: Send karakter ud, kæmp, få drops, se inventory. Intet mere.*

- [ ] CharacterManager — stats og XP-beregning
- [ ] InventoryManager — tilføj/fjern items
- [ ] MonsterData — opret ét testmonster som .tres fil
- [ ] ExpeditionManager — start og afslut expedition
- [ ] Kamp-simulation — tick-system, hit/miss/block, skadeberegning
- [ ] Drop-system — rul drops fra monster drop table
- [ ] Stat XP — optjen XP fra kamp baseret på gear
- [ ] Basic combat view — portræt, HP bars, floating damage tal
- [ ] Basic expedition UI — vælg zone, send ud, recall
- [ ] Basic inventory UI — vis items og mængder
- [ ] Basic character UI — vis stats og levels
- [ ] SaveManager — gem og load JSON
- [ ] **Test: komplet kerneloop virker ende-til-ende**

---

## FASE 2 — By og crafting
*Mål: Brug dine drops til at bygge og crafte noget meningsfuldt*

- [ ] CityManager — bygninger og levels
- [ ] Forge UI — vis opskrifter, craft items
- [ ] Crafting-system — direkte crafting virker
- [ ] Gear equip-system — equip og udskift gear
- [ ] Stat-formel komplet — gear_bonus + building_bonus indregnet
- [ ] Damage types — weapon damage type påvirker kamp
- [ ] Monster weakness/resistance — damage matrix virker
- [ ] Basic Research Center — start research, vent, få unlock
- [ ] Building upgrade-system — brug ressourcer + tid
- [ ] **Test: craft bedre gear, mærk forskellen i kamp**

---

## FASE 3 — Progression og opdagelse
*Mål: Spillet føles som en reel progression med formål*

- [ ] Target Hunt mode
- [ ] Boss Run mode
- [ ] Scouting system (Watchtower)
- [ ] Research Center — kategorier og progressiv afsløring
- [ ] Forsker-NPC i Camp
- [ ] Offline progress — beregning og summary-skærm
- [ ] Offline cap — starter på 0, unlockes via Research
- [ ] Inventory sorting
- [ ] **Test: progression føles meningsfuld over flere sessioner**

---

## FASE 4 — Collection log og opdagelse
*Mål: Spilleren jager sjældne ting og kan se hvad der mangler*

- [ ] Museum/Collection Log — grundstruktur
- [ ] Drop table tracking — registrer hvad der er fundet
- [ ] Monster research — afslør drop table i Museum
- [ ] Fragment system — saml og kombiner fragmenter
- [ ] Schematic drops fra monstre
- [ ] Challenge entries — registrer kampbetingelser automatisk
- [ ] **Test: collection log føles som et langsigtet mål**

---

## FASE 5 — Pets
*Mål: Pets er en meningsfuld og sjov del af spillet*

- [ ] PetManager
- [ ] Aktivt pet kæmper på sin egen tick
- [ ] Pet XP per skade gjort
- [ ] Pet level-progression
- [ ] Beast Den bygning
- [ ] Passive bonusser fra inaktive pets stakker
- [ ] Pets som rare drops fra monstre
- [ ] **Test: pets føles værd at jagte**

---

## FASE 6 — Dybde og systemer
*Mål: Alle kernebygninger og systemer er funktionelle*

- [ ] Ancestor's Altar — burn-mekanik
- [ ] Fragment schematic kombinering
- [ ] Crafting kæder (mellemprodukter)
- [ ] Legendarisk crafting (kræver drops fra flere zoner)
- [ ] Gear kæde-opgradering
- [ ] Trading Post (sælg til NPC)
- [ ] Camp/Hub quests
- [ ] NPC storyline (basis)
- [ ] Push notifikationer (research færdig, building færdig)
- [ ] **Test: et helt spil-loop fra ny spiller til midspil**

---

## FASE 7 — Indhold
*Mål: Spillet har nok indhold til at føles komplet*

- [ ] Alle planlagte zoner oprettet med monstre
- [ ] Boss for hver zone
- [ ] Alle bygninger implementeret og upgradeable
- [ ] Research tree med tilstrækkeligt indhold
- [ ] Balancering af ressourcer, XP-kurver, drop-rates
- [ ] Collection log entries for alle monstre og items

---

## FASE 8 — Polish og mobil
*Mål: Spillet er klar til en testflight/beta*

- [ ] Visuel stil besluttet og implementeret
- [ ] Alle UI screens polish
- [ ] Lyd og musik (basis)
- [ ] iOS export setup og test
- [ ] Android export setup og test
- [ ] Touch UI optimering
- [ ] Performance test på mobil
- [ ] **Testflight / beta release**

---

## FASE 9 — Server (fremtid)
*Mål: Multiplayer og sociale features*

- [ ] Nakama server setup
- [ ] Account system
- [ ] Cloud save sync
- [ ] Leaderboards
- [ ] Claner
- [ ] PvP (design og implementering)
- [ ] Trading Post — spiller-til-spiller handel

---

*Sidst opdateret: 2026-07-27 — Fase 0 starter nu*
