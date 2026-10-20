# Cisternen

Et miljø til at gå på opdagelse i, inspireret af referencebillederne:
mørke murstenshvælvinger, søjler, lavt vand, gangbroer med gyldne lyskanter
og fire blå vandinstallationer. Der er en midtergang og to sidegange med
forbindelser på tværs.

## Start og styring

1. Hent ændringerne med **Pull** i VS Code.
2. Åbn `project.godot` i Godot. **F5** starter `Cisterne.tscn`.
3. Klik i spilvinduet for at aktivere musen.

| Kontrol | Handling |
| --- | --- |
| WASD | Gå |
| Mus | Se dig omkring |
| Esc | Slip musen og stands bevægelsen |
| R | Tilbage til start |

Spilleren har kollision mod søjler, ydervægge og gulv og kan træde op på
gangbroerne fra det lave bassin. Dette miljø bruger desktop-styring.

## Redigér i Godot

Åbn **`Cisterne.tscn`**, vælg **3D**, og fold noderne ud i Scene-panelet.
Vælg en node og tryk **F** for at fokusere på den. Gem med **Ctrl+S** og
brug **F5** for at prøve ændringerne. Underliggende scener er gjort redigerbare.

| Node i hovedscenen | Indhold |
| --- | --- |
| Architecture/Structure | Bassinets bund og rummets fire ydervægge |
| Architecture/Pillars | 28 søjler med samlet grafik og kollision |
| Architecture/Arches | Tværbuer og langsgående buer |
| Architecture/Vaults | 18 gemte krydshvælvinger |
| Architecture/FarRecess | Den belyste niche for enden |
| Walkways | Tre gangbroer og forbindelser på tværs |
| Walkways/LightBorders | Lysstriber, der følger gangbroernes omrids |
| Water | Vandoverfladen og dens animerede materiale |
| WaterInstallations | Fire flytbare installationer med armatur, vand, ringe og lys |
| Lighting | WorldEnvironment, refleksionsprobe og varmt lys ved hvælvingerne |
| PlayerSpawn | Spillerens startposition og synsretning |
| Player | Krop, kollisionsform og kamera; hastighed og musefølsomhed i Inspector |
| Controls | Brugerfladen, som redigeres i 2D |

Byggeklodserne findes også som selvstændige scener i `environment/`:
`Pillar.tscn`, `CrossArch.tscn`, `SideArch.tscn`, `VaultBay.tscn`,
`Walkway.tscn` og `WaterInstallation.tscn`. Ændringer i en grundscene gælder
dens instanser; ændringer i hovedscenen gælder den valgte instans.
Spilleren findes i `player/FirstPersonPlayer.tscn`, og brugerfladen i `ui/Controls.tscn`.

Flyt forældrenoden for at holde grafik, lys og kollision sammen. Ændrer du
et meshs størrelse, skal kollisionsformen også tilpasses. Flytter eller ændrer
du gangbroerne, skal lyskanterne under LightBorders følge med. Bevar eksisterende
nodenavne under Player og Controls, som styringen bruger.

Materialer ligger i `environment/materials/`. Shader-parametre for vand,
lysfarve, ringe og faldhastighed kan ændres i Inspector. Materialerne deles
mellem instanser; vælg **Make Unique**, hvis du vil ændre én genstand alene.
Teksturer og geometri er lavet til dette projekt.

Alt indhold er gemt som **redigerbare noder**. Rummet, kameraet, kollisioner,
lys og brugerfladen bygges ikke op af kode ved spilstart. Scriptet styrer kun
spillerens bevægelse; shaders giver vandet bevægelse.

## Grafik og kontrol

Projektets **Forward+**-renderer er bevaret. Vandet bruger en refleksionsprobe,
skærmrefleksioner (SSR) og animerede normaler. WorldEnvironment styrer også
ambient lys, tåge, glow og SSAO. Refleksioner og glow ser anderledes ud i
Compatibility-rendereren, som ikke understøtter SSR.

```sh
godot --headless --editor --import --quit
godot --headless --audio-driver Dummy --path . --script tests/environment_test.gd
```

Testen kontrollerer bevægelse, museblik, kollisioner, opstigning på gangbroer,
retur til start og at redigerede søjler, lys og kameraindstillinger overlever
gemning og genindlæsning. Miljøet er også visuelt kontrolleret med software-OpenGL;
Forward+ med den faktiske GPU skal afprøves lokalt.
