# Godot workflow

- Build Godot content and UI as saved, editable nodes in `.tscn` scenes.
- Save geometry, collision shapes, lights, cameras, controllers, audio players,
  and interaction areas in scenes rather than creating them at runtime.
- Use scripts for behavior, signals, animation, and game state. Preserve edits
  made in Godot and expose relevant settings in the Inspector.
- Keep meshes and collision shapes together under named parent nodes.
- Validate relevant changes in Godot. Do not reintroduce the removed prototypes
  unless the user asks for them.
- Each cloud task is already isolated; use this checkout unless asked otherwise.
