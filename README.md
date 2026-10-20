# Seven Doors / Cisternerne

En Godot VR-prototype inspireret af brugerens idé til **Marina Abramović:
Seven Deaths** i Cisternerne. Du starter i en halvcirkelformet lobby med syv døre.
Den første dør er spilbar; de øvrige seks er pladsholdere til kommende oplevelser.

## Prøv på computeren

1. Hent ændringerne i VS Code: **Source Control → … → Pull**.
2. Åbn projektet i **Godot 4.6 eller nyere**, og tryk **F5**.
   `Cisternerne.tscn` er allerede valgt som hovedscene.
3. Klik i spilvinduet. Brug **WASD** til at gå og musen til at se dig omkring.
4. Følg de gyldne punkter til **dør I**, som har en varm, gylden ramme.
5. Peg midt på døren og tryk **E**. Vent på, at den åbner, og gå over tærsklen.
6. I det næste rum: peg på teksten ved sengens fodende og tryk **E** for at
   begynde oplevelsen. Den varer cirka **48 sekunder**.
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
   dør I. Gå derefter over tærsklen med venstre stick.
6. Brug samme trigger til at begynde ved sengen. **B på højre controller**
   sender dig tilbage til lobbyen; returdøren virker også.

Hvis spillet starter i desktop-tilstand, kontrollér Quest Link og den aktive
OpenXR-runtime, stop spillet, og start igen. Der bruges Godots Mobile-renderer
med Vulkan til PC VR. PC'en skal have en kompatibel GPU og opdaterede drivere.
Hold headsetgrænsen aktiv; fysisk bevægelse kan passere virtuelle vægge.

## Lobbyen og den første dør

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

Dør I er vores valg til denne prototype. Scenen gengiver ikke et konkret filmklip
eller udstillingens rum og fastlægger ikke de øvrige døres rækkefølge. Grafik,
tekster og lyd er lavet til projektet; der indgår ingen optagelser fra udstillingen
eller operaforestillinger. De seks øvrige oplevelser er endnu ikke implementeret.

## Udvikling og tests

Hovedfiler:

- `Cisternerne.tscn`: ny hovedscene.
- `cistern/cistern.gd`: lobby, oplevelsens tidsforløb, sceneovergange og fremdrift.
- `cistern/door.gd`: døre, åbning, fokus og status.
- `cistern/interaction.gd`: start- og returinteraktioner.
- `cistern/architecture.gd`: geometri og materialer.
- `cistern/soundscape.gd`: original, genereret lyd og rumklang.
- `museum/player.gd`: fælles desktop-/OpenXR-controller, kollisioner og navigation.
- `openxr_action_map.tres`: Godots standardbindinger inklusive Quest Touch.

Kør fra projektmappen med Godot på PATH:

```sh
godot --headless --xr-mode off --editor --import --quit
godot --headless --xr-mode off --audio-driver Dummy --path . --script tests/cistern_test.gd
godot --headless --xr-mode off --path . --script tests/museum_test.gd
```

De nye tests kontrollerer lobbyens geometri, dørinteraktion, fysisk passage,
overgange, oplevelsens faser, lydtilstand, gennemførelse, gentagelse og tidlig retur.
De tidligere museumstests kontrollerer fortsat fælles bevægelse og genstandsinteraktion.

Cloudmiljøet kan afprøve desktop-funktionalitet og rendere med software-OpenGL.
Headsetsporing, controllernes faktiske input, Vulkan-rendering og Quest Link skal
afprøves på din PC med headset.

Den tidligere museumsscene `Museum.tscn` og tastaturtesten `Tester.tscn` er
bevaret. Åbn den ønskede scene og tryk **F6** for at køre den særskilt.
