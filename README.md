# Seven Doors / Cisternerne

En Godot VR-prototype inspireret af brugerens idé til **Marina Abramović:
Seven Deaths** i Cisternerne. Du starter i en halvcirkelformet lobby med syv døre.
Dør I (**La traviata**) og dør II (**Tosca**) er spilbare. De øvrige fem døre er
pladsholdere til kommende oplevelser.

## Redigér hele spillet i Godot

Alle eksisterende rum, genstande, lys, kollisioner, kameraer, controllere,
lydafspillere og brugerflader er nu gemt som almindelige noder i `.tscn`-scener.
Scripts styrer interaktion, animation og spilforløb. De opbygger ikke rummene ved start.

1. Hent ændringerne i VS Code med **Pull**.
2. Dobbeltklik på den ønskede scene i Godots **FileSystem**-panel.
3. Vælg **3D** øverst (eller **2D** til brugerfladen). Fold noderne ud i **Scene**.
4. Vælg en node, og tryk **F** for at fokusere på den. Flyt, drej og redigér
   dens egenskaber i **Inspector**.
5. Gem med **Ctrl+S**, og tryk **F5** for at teste hele spillet.

| Scene | Hvad du kan redigere |
| --- | --- |
| `Cisternerne.tscn` | Hele spillets opstilling og placeringen af de tre rum. Underliggende noder er allerede gjort redigerbare. |
| `Lobby.tscn` | Architecture: vægge, gulv, loft, søjler og gangbro. Doors: alle syv døre. Lighting, Signage, WaterRipples og PlayerSpawn. |
| `LaTraviata.tscn` | Architecture, Bed, CandleTable, Window, Curtains, Signage, Interactions og Lighting. Vælg roden for Duration, Narrative og Movement Bounds. |
| `Tosca.tscn` | Tower: terrasse, rækværk, brystværn og lanterne. City: 44 bygninger, kuppel og måne. PlayerScarf, Signage, Interactions, Lighting og Audio. Vælg roden for tider, faldlængder, fortælling og bevægelsesgrænser. |
| `Player.tscn` | Desktop-krop, kollisionskapsel, kamera, OpenXR-kamera, controllermodeller og pegestråle. Hastighed og interaktionsrækkevidde findes på roden. |
| `DesktopHUD.tscn` | Panel, stednavn, kontroltekst, interaktionsprompt og sigtepunkt. Redigér i 2D; ankre følger vinduets størrelse. |
| `Soundscape.tscn` | Baggrundslyd og åndedræt: lydressourcer, lydniveau og bus. Rumklang redigeres i Godots Audio-panel via `default_bus_layout.tres`. |
| `Museum.tscn` | Det tidligere museum: Architecture, Lighting, Signage, tre genstande under Exhibits og dets egen DesktopHUD. |
| `Tester.tscn` | Den tidligere tastaturtest med gemte tekstnoder. |

**Startpositioner og oplevelser:** Lobbyens `PlayerSpawn` og rummenes
`Markers/PlayerSpawn` bestemmer, hvor du ankommer, og hvilken retning du ser.
I La traviata flytter du `Bed/FirstPersonView` for at ændre synspunktets position
på lejet; flytter du hele Bed, følger markøren med. I Tosca bestemmer
`Markers/FallTarget`, hvor du bevæger dig ud over kanten før faldet. Faldlængden
ændres med Full Fall Distance / Short Fall Distance på Tosca-roden.
Startpositioner, faldmarkør og VR-grænser følger også flyttede og drejede rum.
Movement Bounds er et lokalt X/Z-rektangel; justér det, hvis du ændrer rummets størrelse.

Flyt en genstands **forældrenode** for at holde grafik og kollision sammen.
Ændrer du størrelsen på et mesh, skal du også tilpasse dets CollisionShape3D.
Hold døre og vægåbninger på linje. Bevar eksisterende nodenavne og stier,
som scripts bruger. Lyde er originale, på forhånd genererede AudioStreamWAV-
ressourcer i `audio/`; de kan erstattes via de gemte AudioStreamPlayer-noder.

En dørs Title og Theme og en interaktions Prompt redigeres på selve dør-/
Area3D-noden i Inspector. Statiske skilte redigeres på deres Label3D.
Oplevelsernes skiftende fortællinger redigeres på rummenes rod; status- og
prompttekster opdateres under spillet. Kameraets Fade-mesh bruges til mørke
og rumskift. Start- og faldskilte samt stoffet skifter synlighed under forløbet.

Du kan også åbne `Cisternerne.tscn` og redigere komponenterne dér. Ændringer
lavet i hovedscenen gælder dens instans; åbn komponentens egen scene, når du
vil ændre grundudgaven. Rummene alene har ingen spiller, så brug **F5** til at
spille dem. `Museum.tscn` og `Tester.tscn` kan køres særskilt med **F6**.

## Prøv på computeren

1. Hent ændringerne i VS Code: **Source Control → … → Pull**.
2. Åbn projektet i **Godot 4.6 eller nyere**, og tryk **F5**.
   `Cisternerne.tscn` er allerede valgt som hovedscene.
3. Klik i spilvinduet. Brug **WASD** til at gå og musen til at se dig omkring.
4. Vælg **dør I — La traviata** eller **dør II — Tosca**. Begge har en varm,
   gylden ramme. De gyldne gulvpunkter fører til dør I.
5. Peg midt på døren og tryk **E**. Vent på, at den åbner, og gå over tærsklen.
6. Peg på startteksten ved sengen (La traviata) eller på terrassen (Tosca),
   og tryk **E**. La traviata varer cirka **48 sekunder**. I Tosca følger en kort
   indledning; gå derefter tæt på kanten og vælg **BEGYND FALDET** med E.
7. Tryk **R** for at vende tilbage til lobbyen når som helst. Du kan også
   vælge returdøren bag dig med **E**. **Esc** slipper musen.

Vil du teste uden at starte OpenXR, kan du køre:

```sh
godot --xr-mode off --path .
```

## Prøv med Meta Quest tilsluttet en PC

Spillet kører på din Windows-PC og vises i headsettet gennem **Quest Link**
eller **Air Link**. Prototypen er ikke en selvstændig Android-app til Quest.

1. Installer Meta Quest Link på din PC, og vælg den som aktiv **OpenXR-runtime**
   i appens indstillinger.
2. Forbind Quest via USB eller Air Link, og gå ind i PC Link-miljøet.
   Headset og begge controllere skal være vågne.
3. Slå **Embed Game on Play** fra i Godots Game-menu, og tryk **F5**.
   Output-panelet viser `Museum mode: OpenXR`, hvis VR er startet.
4. **Venstre stick** flytter dig. **Højre stick** drejer i trin på 30 grader.
5. Peg med højre controllers stråle, og tryk **højre trigger** for at åbne
   dør I eller II. Gå derefter over tærsklen med venstre stick.
6. Brug samme trigger til at begynde ved sengen eller på terrassen. I Tosca
   bekræfter du igen ved kanten for at falde. **B på højre controller**
   sender dig tilbage til lobbyen; returdøren virker også.

Hvis spillet starter i desktop-tilstand, kontrollér Quest Link og den aktive
OpenXR-runtime, stop spillet, og start igen. Der bruges Godots Mobile-renderer.
Den valgte grafikdriver skal fungere med PC'ens GPU og OpenXR-runtime.
Hold headsetgrænsen aktiv; fysisk bevægelse kan passere virtuelle vægge.

## Lobbyen og oplevelserne

- Lobbyen er en halvcirkel med stensøjler, hvælvinger, en fugtig gulvflade,
  langsomme ringe i vandet og genereret rumklang/ambient lyd.
- Dørene åbner fysisk. Når du går over tærsklen, toner synsfeltet roligt ud,
  og du ankommer til et separat rum. Begge scener opleves nu i første person.
- **Det sidste åndedrag** er en original, atmosfærisk fortolkning inspireret
  af Violettas død af tuberkulose i Verdis *La traviata*.
- Når du begynder La traviata, glider dit perspektiv roligt ind på lejet.
  Du hører åndedrættet blive svagere, mens stearinlyset slukkes, og dit syn
  toner helt ud. Efter et kort mørke bliver rummet synligt igen, og du kan vende
  tilbage til lobbyen eller opleve scenen igen. Du kan stadig se dig omkring.
- Efter fuld gennemspilning markeres dør I som **OPLEVET**. Du kan gå ind igen.
  En tidlig afbrydelse giver ikke en ny gennemførelse.

### Dør II — Tosca / Faldet

Du træder ud på en borgterrasse højt over et stiliseret Rom. Månen, tage og en
fjern kuppel danner baggrunden. Vind og en original, syntetiseret klokke sætter
stemningen. Du indtager selv Toscas plads på terrassen.

1. Peg på **BEGYND TOSCA** og tryk E / højre trigger.
2. Efter en indledning på cirka 10 sekunder viser teksten, at du kan gå til kanten.
3. Brug WASD / venstre stick til at nærme dig det midterste rækværk.
4. Peg på **BEGYND FALDET**, og bekræft med E / højre trigger.
5. Dit synspunkt bevæger sig ud over kanten og accelererer ned langs tårnet.
   Byen bevæger sig op gennem dit synsfelt, og et rødt stykke stof følger dig.
   Du kan fortsat se dig omkring med musen eller headsettet; scenen tvinger
   ingen rotation eller rulning af dit hoved.
6. Synet toner ud før afslutningen. Efter et kort mørke vender du tilbage til
   terrassen med afslutningsteksten og mulighed for at gentage eller gå til lobbyen.

Du behøver kun at bruge spillets kontroller, også i VR. Faldet starter først,
når du bekræfter det ved kanten. Før start kan du vælge **FALD: FULDT / KORT**
på skiltet til venstre. Fuldt fald flytter dit synspunkt cirka 25 virtuelle meter
ned over cirka fem sekunder. Kort fald begrænser bevægelsen til fire meter og
toner tidligere ud. Begge varianter opleves fra spillerens perspektiv.

Efter hele forløbet markeres **dør II** som OPLEVET. Den har sin egen status,
så en Tosca-gennemspilning ikke gennemfører La traviata. Du kan afbryde med R / B,
bruge returdøren bag dig og genbesøge scenen. Ved retur stopper vind og klokke,
og lobbyens lydniveau gendannes. Du kan spille de to scener i valgfri rækkefølge.

Alle syv døre er navngivet efter den liste, du har angivet:

| Dør | Opera | Dødstema |
| --- | --- | --- |
| I | La traviata — Giuseppe Verdi | Tæring / tuberkulose |
| II | Tosca — Giacomo Puccini | Fald fra et tårn |
| III | Otello — Giuseppe Verdi | Kvælning |
| IV | Madame Butterfly — Giacomo Puccini | Rituelt selvmord (hara-kiri) |
| V | Carmen — Georges Bizet | Knivstik |
| VI | Lucia di Lammermoor — Gaetano Donizetti | Vanvid / sindssyge |
| VII | Norma — Vincenzo Bellini | Brændt på bålet |

Konceptets kildehenvisninger: [Cisternerne](https://frederiksbergmuseerne.dk/da/udstillinger/marina-abramovic/)
og [Factum Arte](https://www.factum-arte.com/pag/1760/seven-deaths).

Scenerne gengiver ikke konkrete filmklip eller udstillingens rum. Grafik,
tekster og lyd er lavet til projektet; der indgår ingen optagelser fra udstillingen
eller operaforestillinger. De fem øvrige oplevelser er endnu ikke implementeret.

## Udvikling og tests

Hovedfiler:

- `Cisternerne.tscn`: ny hovedscene.
- `Lobby.tscn`: redigerbar lobby med geometri, døre, lys, skilte og startmarkør.
- `cistern/cistern.gd`: lobby, oplevelsens tidsforløb, sceneovergange og fremdrift.
- `cistern/door.gd`: døre, åbning, fokus og status.
- `cistern/interaction.gd`: start- og returinteraktioner.
- `LaTraviata.tscn` og `Tosca.tscn`: gemte rum med redigerbar geometri og markører.
- `cistern/room_settings.gd`: varighed, fortælling og bevægelsesgrænser for La traviata.
- `Soundscape.tscn`, `audio/` og `default_bus_layout.tres`: lyd og rumklang.
- `cistern/soundscape.gd`: afspilning og ændring af lydniveau under oplevelserne.
- `cistern/tosca.gd`: førstepersonsfald, fortælling, bevægelsesvalg og afspilning af vind og klokke.
- `museum/player.gd`: fælles desktop-/OpenXR-controller, kollisioner, navigation og sekvensbevægelse.
- `openxr_action_map.tres`: Godots standardbindinger inklusive Quest Touch.

Kør fra projektmappen med Godot på PATH:

```sh
godot --headless --xr-mode off --editor --import --quit
godot --headless --xr-mode off --audio-driver Dummy --path . --script tests/cistern_test.gd
godot --headless --xr-mode off --audio-driver Dummy --path . --script tests/tosca_test.gd
godot --headless --xr-mode off --audio-driver Dummy --path . --script tests/editable_lobby_test.gd
godot --headless --xr-mode off --audio-driver Dummy --path . --script tests/editable_scenes_test.gd
godot --headless --xr-mode off --audio-driver Dummy --path . --script tests/museum_test.gd
```

Scenetestene kontrollerer lobbyens geometri, begge døres interaktion og fysiske
passage, overgange, oplevelsernes faser, lydtilstand, gennemførelse, gentagelse og
tidlig retur. Tosca-testen kontrollerer også kantens bekræftelse, at spillerens
faktiske kamera og XR-rig falder, at lokale headsetposer bevares, kort fald,
sort overgang, gendannelse af kontroller og uafhængig fremdrift for de to døre.
La traviata-testen kontrollerer førstepersonsperspektivet på lejet og mørket ved afslutningen.
De tidligere museumstests kontrollerer fortsat fælles bevægelse og genstandsinteraktion.
Lobbytesten kontrollerer, at geometri er til stede før spilstart, at døre ikke
genereres dobbelt, og at ændringer af vægge og døre kan gemmes, indlæses og bruges i spillet.
Scenetesten kontrollerer desuden alle komponenter før spilstart, at der ikke oprettes
ekstra noder, og at redigerede rum, kameraer, tekst, lyd, senge- og faldmarkører
bevares gennem gemning/genindlæsning og bruges under gameplay.

Cloudmiljøet kan afprøve desktop-funktionalitet og rendere med software-OpenGL.
Headsetsporing, controllernes faktiske input, Vulkan-rendering og Quest Link skal
afprøves på din PC med headset.

Den tidligere museumsscene `Museum.tscn` og tastaturtesten `Tester.tscn` er
bevaret. Åbn den ønskede scene og tryk **F6** for at køre den særskilt.
