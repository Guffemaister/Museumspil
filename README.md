# Seven Doors / Cisternerne

En Godot VR-prototype inspireret af brugerens idé til **Marina Abramović:
Seven Deaths** i Cisternerne. Du starter i en halvcirkelformet lobby med syv døre.
Dør I (**La traviata**) og dør II (**Tosca**) er spilbare. De øvrige fem døre er
pladsholdere til kommende oplevelser.

## Prøv på computeren

1. Hent ændringerne i VS Code: **Source Control → … → Pull**.
2. Åbn projektet i **Godot 4.6 eller nyere**, og tryk **F5**.
   `Cisternerne.tscn` er allerede valgt som hovedscene.
3. Klik i spilvinduet. Brug **WASD** til at gå og musen til at se dig omkring.
4. Vælg **dør I — La traviata** eller **dør II — Tosca**. Begge har en varm,
   gylden ramme. De gyldne gulvpunkter fører til dør I.
5. Peg midt på døren og tryk **E**. Vent på, at den åbner, og gå over tærsklen.
6. Peg på startteksten ved sengen (La traviata) eller på terrassen (Tosca),
   og tryk **E**. Forløbene varer cirka **48** og **42 sekunder**.
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
6. Brug samme trigger til at begynde ved sengen eller på terrassen. **B på højre controller**
   sender dig tilbage til lobbyen; returdøren virker også.

Hvis spillet starter i desktop-tilstand, kontrollér Quest Link og den aktive
OpenXR-runtime, stop spillet, og start igen. Der bruges Godots Mobile-renderer
med Vulkan til PC VR. PC'en skal have en kompatibel GPU og opdaterede drivere.
Hold headsetgrænsen aktiv; fysisk bevægelse kan passere virtuelle vægge.

## Lobbyen og oplevelserne

- Lobbyen er en halvcirkel med stensøjler, hvælvinger, en fugtig gulvflade,
  langsomme ringe i vandet og genereret rumklang/ambient lyd.
- Dør I åbner fysisk. Når du går over tærsklen, toner synsfeltet roligt ud,
  og du ankommer til et separat rum. Der er ingen tvungen kamerabevægelse.
- **Det sidste åndedrag** er en original, atmosfærisk fortolkning inspireret
  af Violettas død af tuberkulose i Verdis *La traviata*.
- Et tomt leje, et stearinlys, syntetiseret åndedræt og korte danske tekster
  danner et forløb, som gradvist ender i stilhed. Du starter selv forløbet.
- Efter fuld gennemspilning markeres dør I som **OPLEVET**. Du kan gå ind igen.
  En tidlig afbrydelse giver ikke en ny gennemførelse.

### Dør II — Tosca / Faldet

Du træder ud på en borgterrasse højt over et stiliseret Rom. Månen, tage og en
fjern kuppel danner baggrunden. Vind og en original, syntetiseret klokke sætter
stemningen, mens en skikkelse i rødt står på en ydre afsats.

Peg på **BEGYND TOSCA** og tryk E / højre trigger for at starte. Korte danske
tekster leder frem mod et koreograferet fald: silhuetten forsvinder under muren,
mens et rødt tørklæde driver langsommere ned. Kameraet bliver på terrassen.
En mur med kollision og særskilte VR-bevægelsesgrænser holder spilfiguren på
platformen. Der er ingen tvungen kamerabevægelse eller krav om at springe.

Efter cirka 42 sekunder markeres **dør II** som OPLEVET. Den har sin egen status,
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
- `cistern/cistern.gd`: lobby, oplevelsens tidsforløb, sceneovergange og fremdrift.
- `cistern/door.gd`: døre, åbning, fokus og status.
- `cistern/interaction.gd`: start- og returinteraktioner.
- `cistern/architecture.gd`: geometri og materialer.
- `cistern/soundscape.gd`: original, genereret lyd og rumklang.
- `cistern/tosca.gd`: borgterrasse, by, silhuet, faldforløb, vind og klokke.
- `museum/player.gd`: fælles desktop-/OpenXR-controller, kollisioner og navigation.
- `openxr_action_map.tres`: Godots standardbindinger inklusive Quest Touch.

Kør fra projektmappen med Godot på PATH:

```sh
godot --headless --xr-mode off --editor --import --quit
godot --headless --xr-mode off --audio-driver Dummy --path . --script tests/cistern_test.gd
godot --headless --xr-mode off --audio-driver Dummy --path . --script tests/tosca_test.gd
godot --headless --xr-mode off --path . --script tests/museum_test.gd
```

Scenetestene kontrollerer lobbyens geometri, begge døres interaktion og fysiske
passage, overgange, oplevelsernes faser, lydtilstand, gennemførelse, gentagelse og
tidlig retur. Tosca-testen kontrollerer også terrassens kant, det animerede fald,
at kameraet står stille under faldet, og at de to døres fremdrift er uafhængig.
De tidligere museumstests kontrollerer fortsat fælles bevægelse og genstandsinteraktion.

Cloudmiljøet kan afprøve desktop-funktionalitet og rendere med software-OpenGL.
Headsetsporing, controllernes faktiske input, Vulkan-rendering og Quest Link skal
afprøves på din PC med headset.

Den tidligere museumsscene `Museum.tscn` og tastaturtesten `Tester.tscn` er
bevaret. Åbn den ønskede scene og tryk **F6** for at køre den særskilt.
