# BONK — Todo & Roadmap

> Kryds af efterhånden som vi kommer igennem. Hvert fase er et naturligt delmål der kan testes og føles komplet.

---

## FASE 0 — Godot Setup ✅
*Mål: Et tomt men korrekt struktureret Godot-projekt klar til kode*

- [x] Opret Godot projekt i `/bonk/`
- [x] Opret mappestruktur (autoloads, resources, data, scenes, assets)
- [x] Skriv Resource-klasser (ItemData, GearData, FragmentData, CraftingIngredient, CraftingRecipe, DropEntry, MonsterData, PetData, PetInstance, ResearchData, BuildingData)
- [x] Opret EventBus.gd med alle signals
- [x] Opret Manager autoloads (GameManager, SaveManager, CharacterManager, InventoryManager, ExpeditionManager, CityManager, ResearchManager, CollectionLogManager, PetManager, CraftingManager, ResourceRegistry)
- [x] Registrer alle autoloads i Project Settings

---

## FASE 1 — Kerneloop (MVP) ✅
*Mål: Send karakter ud, kæmp, få drops, se inventory. Intet mere.*

- [x] CharacterManager — stats og XP-beregning
- [x] InventoryManager — tilføj/fjern items
- [x] MonsterData — testmonster som .tres fil
- [x] ExpeditionManager — start og afslut expedition
- [x] Kamp-simulation — separate tick-timers per spiller/monster, hit/miss/block, skadeberegning
- [x] Drop-system — rul drops fra monster drop table
- [x] Stat XP — optjen XP fra kamp baseret på gear
- [x] Basic combat UI — HP bars, kamplog, stats, inventory
- [x] SaveManager — gem og load JSON
- [x] **Test: komplet kerneloop virker ende-til-ende** ✅

---

## FASE 2 — By og crafting ✅
*Mål: Brug dine drops til at bygge og crafte noget meningsfuldt*

- [x] CityManager — bygninger og levels
- [x] Bonkery UI — vis opskrifter, craft items
- [x] Crafting-system — direkte crafting virker
- [x] Gear equip/unequip-system
- [x] Stat-formel komplet — gear_bonus indregnet
- [x] Damage types — weapon damage type påvirker kamp
- [x] Monster weakness/resistance — damage matrix virker
- [x] Thinkery (Research Center) — start research, vent, få unlock
- [x] Building upgrade-system — ressourcer + tid
- [x] ResourceRegistry — central itemlookup, ingen disk-scan ved load
- [x] Offline progress — beregnes ved load hvis unlocked via Thinkery
- [x] **Test: craft bedre gear, mærk forskellen i kamp** ✅

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
