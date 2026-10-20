# Godot scene workflow

- All visible content and UI must be saved as editable nodes in `.tscn` scenes.
- Save players, cameras, controllers, collision shapes, lights, audio players,
  interaction areas, and room markers in scenes too. Do not rebuild these nodes
  from GDScript at startup or replace edits made in Godot's editor.
- Use GDScript for behavior, animation, signals, and game state. Expose relevant
  settings, narrative text, durations, and movement bounds in the Inspector.
- Use editable markers for player spawns, first-person viewpoints, and fall targets.
  Room-relative behavior must continue working when a room is moved or rotated.
- Keep mesh and collision geometry together under named parents. Preserve node
  references when changing scene structure, and update the editing guide.
- Validate changes using the relevant existing scene tests and a meaningful
  editor save/reload check when scene authoring behavior changes.
- Each cloud task is already isolated. Work in this checkout; do not create
  another worktree unless the user asks for one.
