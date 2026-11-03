# Cisterne-kortet

![Kortet vist i Godot](docs/cisterne-preview.png)

Kortet i `cistern/CisternMap.tscn` bruger din baseplate fra `Floor.tscn` med
udgangspunkt i referencebilledernes søjler, let spidse buer, krydshvælvinger,
kalkpletter og fugtige gulve.

Baseplaten er `Floor mesh` i din `Floor.tscn` med samme BoxMesh,
placering og tykkelse. Den er gjort **15 % større vandret: 60 × 30 → 69 × 34,5**.
Dens aflange form og forholdet 2:1 er bevaret. Kortets længderetning følger
den roterede gulvinstans, og bygningen holder sig inden for dens kanter.

## Åbn og redigér

1. Hent ændringerne med **Pull** i VS Code.
2. Åbn **`cistern/CisternMap.tscn`** i Godot, og vælg **3D**.
3. Fold **Architecture**, **Floor** eller **Player** ud i scenetræet. Noderne er redigerbare.
4. Vælg en søjle eller bue og tryk **F** for at fokusere på den.
5. Hold højre museknap nede i 3D-visningen og brug **WASD** for at udforske kortet.
6. Gem med **Ctrl+S**, og tryk **F5** for at gå rundt med din spiller.

## Gå rundt

F5 starter kortet med din `Player.tscn` og dit gulv. Klik i spilvinduet, hvis
musen ikke allerede er fanget.

| Kontrol | Handling |
| --- | --- |
| WASD | Gå i den retning, du ser |
| Mus | Se dig omkring |
| Esc | Slip musen og stands bevægelsen |
| Venstreklik | Fang musen igen |
| R | Tilbage til `FuturePlayerSpawn` |

`Player.tscn` bruger din eksisterende CharacterBody3D som rod. Den har en
CollisionShape3D med kapsel, en BodyMesh og Head/Camera3D. `player.gd` styrer
bevægelse, tyngdekraft, museblik og retur til start. Det erstatter forsøget i
`mesh_instance_3d.gd`, som brugte CharacterBody-metoder på en MeshInstance3D.

Åbn Player.tscn for at redigere kroppen og kameraet. **Speed**, **Fall Acceleration**
og **Mouse Sensitivity** findes på roden i Inspector. Head bestemmer kamerahøjden.
Kroppens mesh bruger lag 3 og er synligt i editoren, men skjult for spillerens
kamera, så du ikke ser indersiden af kroppen. Vandets eksisterende lag 2 er bevaret.

Kortet indeholder en instans af Floor.tscn, drejet så gulvet passer til bygningen,
og en instans af Player.tscn. Markøren FuturePlayerSpawn bestemmer startposition
og synsretning. De gamle kameranoder er bevaret til forhåndsvisning; spillerens
kamera er aktivt under spillet. F6 på Player.tscn alene har intet gulv; brug F5
eller F6 på hele kortet.

| Node | Hvad den indeholder |
| --- | --- |
| Floor/Floor mesh | Din baseplate med gulvmateriale og kollision |
| Player | Spillerens krop, kapsel, hoved og kamera |
| Architecture/Pillars | 104 søjler i 13 rækker; syv gennemgående gange |
| Architecture/Arches | 187 tværgående og langsgående buer |
| Architecture/Vaults | 84 krydshvælvinger med gemte kollisionsformer |
| Architecture/Walls | Ydervægge og mørke, fugtige sokler |
| Puddles | Uregelmæssige, bløde vandpytter med almindelige Godot-materialer |
| Lighting | WorldEnvironment, refleksionsprober, pendellamper og lyspunkter |
| Details | Ophængswirer og små vægarmaturer |
| PreviewCameras | Kamera langs midtergangen og et kamera på skrå gennem hvælvingerne |
| FuturePlayerSpawn | Spillerens startposition og synsretning |

Flyt en genstands forældrenode for at holde grafik og kollision sammen.
Hvis du ændrer en BoxMesh-størrelse, skal den tilsvarende CollisionShape3D
også tilpasses. Bevar kortets placering i forhold til baseplaten, hvis du
flytter dem hver for sig.

## Materialer og byggeklodser

Grundscenerne ligger i `cistern/`: `Pillar.tscn`, `CrossArch.tscn`,
`SideArch.tscn`, `GroinVault.tscn` og `HangingLamp.tscn`. Hele kortet ligger i
`cistern/CisternMap.tscn`. Åbn en grundscene for at ændre alle dens instanser,
eller redigér en enkelt instans fra hovedscenen.

Materialerne i `cistern/materials/` er almindelige **StandardMaterial3D**-
ressourcer. Farve, ruhed, normaler, gennemsigtighed og teksturskala kan ændres
i Inspector. Brug **Make Unique**, hvis en materialeændring kun skal gælde
én genstand. Teksturerne og de gemte buede mesh er lavet til dette kort.

Kortets indhold er stadig **gemte, redigerbare noder og ressourcer**. Spillerens
script styrer adfærd og opbygger ingen noder ved start. Præferencen om gemte
noder er skrevet i `AGENTS.md`, så den følger fremtidigt arbejde i projektet.

Spillerens test kan køres fra projektmappen:

```sh
godot --headless --editor --import --quit
godot --headless --path . --script tests/player_test.gd
```

Testen afprøver rigtigt WASD-input, museblik, kameras valg, gulv- og vægkollision,
retur til start, vinduesfokus samt gemning og genindlæsning af spillerindstillinger.

Projektets eksisterende Godot 4.7-/Forward+- og Windows-driverindstillinger
er bevaret. Skærmrefleksioner og SSAO bruger Forward+; forhåndsvisning i
Compatibility ser derfor anderledes ud. Kortet er kontrolleret i Godot 4.6.3
med headless validering og software-OpenGL. Kontrollér den endelige Forward+-
belysning på din egen PC.
