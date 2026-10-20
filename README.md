# Museum / After Hours

A small Godot 4.6+ museum game built for **Meta Quest connected to a Windows PC**
with Quest Link or Air Link. Explore a gallery and discover all three artifacts.
Models are stylized, fictional exhibits made with built-in Godot meshes; no asset
downloads or plugins are required. Desktop mode works without a VR headset.

## Play without a headset

1. Pull the latest `main` branch in VS Code.
2. Open `project.godot` in Godot 4.6 or newer.
3. Press **F5**. `Museum.tscn` is already the main scene.
4. Click the game window, then use **WASD** and the mouse to explore.
5. Aim the center crosshair at an artifact and press **E** to pick it up.
6. Press **E** again to return it to its pedestal. Discover all three to finish.
7. **Esc** releases the mouse.

If Godot starts an XR session when you want desktop mode, run with
`godot --xr-mode off --path .`, or disable OpenXR in Project Settings temporarily.

## Play on Meta Quest through a PC

This workflow runs the game **on your PC**, streaming it to the headset.
It does not install an Android application on the Quest.

1. Install the Meta Quest Link desktop app on a compatible Windows PC.
2. In that app's settings, set Meta Quest Link as the active OpenXR runtime.
   The exact setting location depends on the app version.
3. Connect your headset using Quest Link (USB) or Air Link (Wi-Fi), and enter
   the PC Link environment. Have the headset and both controllers awake.
4. In Godot's Game menu, turn off **Embed Game on Play** for VR testing,
   then press **F5**. The project enables OpenXR automatically when its
   runtime initializes. Godot's Output panel reports `Museum mode: OpenXR`.
5. Use the **left thumbstick** to move and **right thumbstick** for 30-degree
   snap turns. Point the right controller's beam at an artifact and press
   the **right trigger** to pick it up; press again to return it.
6. Read each artifact's story on the rear wall. Progress appears above it.

Clear your real play space and keep the headset's boundary enabled. Physical
headset movement is not constrained by virtual walls. Artificial movement may
be uncomfortable; stop if you feel unwell. Teleportation is not implemented.

If desktop mode appears instead, check that Quest Link is running and its
OpenXR runtime is selected, then stop and restart the game. For PC VR rendering,
the project uses Godot's Mobile renderer with Vulkan (not the Android platform).
Make sure the PC has a supported GPU and current drivers.

## Project files

- `Museum.tscn`: main game scene.
- `museum/museum.gd`: procedural gallery, lighting, exhibits, and tour progress.
- `museum/player.gd`: desktop movement and OpenXR camera/controller interaction.
- `museum/exhibit.gd`: artifact models, pickup, and return behavior.
- `openxr_action_map.tres`: Godot's default controller bindings, including Quest Touch.
- `Tester.tscn`: the earlier simple keyboard test; open it and press F6 to run it.

## Automated checks

From this folder, with Godot on your PATH:

```sh
godot --headless --xr-mode off --editor --import --quit
godot --headless --xr-mode off --path . --script tests/museum_test.gd
```

The test exercises scene startup, desktop movement and collision, ray selection,
pickup/return, and completion. Automated checks do not establish headset rendering,
controller tracking, comfort, or Quest Link connectivity. Those need an actual
headset and compatible PC; this cloud workspace has neither.
