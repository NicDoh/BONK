# BONK — Decisions Log

> Hvorfor vi besluttede hvad vi besluttede. Ikke hvad, men hvorfor.

---

## Engine & Platform

**Godot 4, Mobile renderer**
Mobile renderer frem for Compatibility fordi vi målretter moderne enheder og ikke ønsker at gå på kompromis for gammel hardware.

---

## Arkitektur

**EventBus-pattern**
Al kommunikation mellem systemer går via en global EventBus autoload. Managers refererer aldrig direkte til hinanden. Gør det muligt at ændre ét system uden at røre de andre.

**Resource-baseret data**
Alt spilindhold (monstre, items, gear, opskrifter) ligger i .tres Resource-filer, ikke hardkodet. En ny monstertype = én ny fil. Ingen eksisterende kode røres.

**SaveManager som eneste data-touchpoint**
Kun SaveManager må læse og skrive til disk. Gør det nemt at skifte save-backend (lokal JSON nu, Nakama server senere) uden at røre resten af koden.

---

## Karakter & Stats

**5 stats: HP, Strength, Defense, Speed, Accuracy**
Luck blev fravalgt — for komplekst og svært at gøre meningsfuldt. Drop-bonusser kommer fra gear og bygninger i stedet.

**Gear bestemmer hvilke stats der trænes**
Main hand våben træner Strength/Speed/Accuracy. Off-hand shield træner Defense. HP trænes passivt fra hits modtaget. Besluttet fremfor zone-valg, Research-valg eller shared XP — fordi det giver spilleren et meningsfuldt valg om hvad der skal prioriteres via gear-loadout.

**Separate attack timers for spiller og monster**
Spiller og monster har hver sin tick-timer baseret på deres respektive Speed-stat. Besluttet efter det viste sig at fælles tick gjorde Speed meningsløs for monstre.

---

## Kamp

**6 damage types: Blunt, Slash, Pierce, Fire, Poison, Spirit**
Tre fysiske fra start, tre elementære der unlockes med nye zoner. Giver monstre meningsfulde weaknesses og gør gear-valg strategisk.

**Damage matrix: Weak(×1.5) / Neutral(×1.0) / Resistant(×0.5) / Immune(×0.0)**
Simpel og forudsigelig. Giver collection log-entries mening (dræb en boss med et dårligt våben = ekstra udfordring).

---

## Progression

**Tattoos som prestigesystem**
Permanente mærker på karakteren som bevis for præstationer. Adskiller sig fra gear (ikke udstyr, ikke statistisk) og understøtter tribal-identiteten. Trigger-mekanik ikke besluttet endnu — diskuteres til fase 3/8.

---

## Tribe & Bygninger

**Base kaldes "the Tribe"**
Ikke "city" eller "village". Tribe har en identitet og en historie.

**Bygningsnavne**
- Bonkery (Forge) — passer til spilnavnet
- Thinkery (Research Center) — primitiv hjemmelavet tone
- Ogg's Hearth (Camp/Hub + Ancestor's Altar) — socialt centrum og burn-mekanik flettet sammen
- Oddities (Museum/Collection Log) — kuriositets-kabinet-vibe
- Tamery (Beast Den) — stedet hvor man tæmmer
- Scoutery (Watchtower) — scouting og zone-afsløring

**Ancestor's Altar flettet ind i Ogg's Hearth**
En separat burn-bygning ville føles isoleret. Bålet er naturligt stedet for ofringer og ritualer — og det giver Ogg's Hearth mere dybde end bare et socialt sted.

**Trading Post og Warehouse droppet**
Trading Post: ikke kritisk for kerneloopet, kan tilføjes senere. Warehouse: inventory er en del af player-profilen, ikke en bygning.

---

## Offline Progress

**Starter på 0, unlockes via Thinkery**
Tidlig spil kræver aktiv deltagelse. Første offline-unlock er en milestone. Skalerer til 24 timer i late game via Research.

---

## Save System

**Lokal JSON nu, Nakama server senere**
Arkitekturen er server-klar (SaveManager som eneste touchpoint), men vi bruger lokal JSON indtil spillet er færdigt. Undgår kompleksitet tidligt i projektet.
