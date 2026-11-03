# Godot authoring preference

- The user wants all map content saved as editable nodes in Godot scenes.
- Use saved meshes, collision shapes, lights, materials, cameras, and environment
  nodes. Do not generate or load map geometry from runtime scripts.
- Do not add scripts to the map unless the user explicitly requests behavior
  that requires them. Expose visual adjustments through the Inspector.
- Preserve the user's existing scene and geometry. Keep meshes and their
  collision shapes under the same named parent so edits stay aligned.
