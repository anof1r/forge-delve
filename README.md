# Forge-Delve

Self-hosted Godot 4 visualizer for grid-based D&D dungeons. The current demo loads `scenes/levels/tavern.tscn`, places editable modular tiles, props, and tokens, and supports turn-based movement without combat.

## Requirements

- Godot 4.7.2 Mono with Forward+ and Jolt Physics.
- Node.js/npm only when a Meshy GLB must be dequantized.
- The external model packs listed below. Large source assets are intentionally excluded from Git.

## Asset setup

Keep filenames unchanged because the catalogs load models by name.

- `assets/props/`: glTF release of **Quaternius Fantasy Props MegaKit** (CC0), including its textures and binary files.
- `assets/walls/`: selected files from the `glTF` directory of **Medieval Village MegaKit [Standard]**, including `.gltf`, `.bin`, textures, and `License_Standard.txt`.
- `assets/models/dal_dayneris.glb` and `assets/models/maximir.glb`: project-specific Meshy token models.

Godot cannot import Meshy files that still use `KHR_mesh_quantization`. Convert each affected file before importing:

```powershell
npx.cmd --yes @gltf-transform/cli dequantize input.glb output.glb
```

Copies of the third-party license texts are stored in `licenses/`. Do not commit model files unless their license permits redistribution.

## Run and verify

From the repository root:

```powershell
& 'D:\Projects\godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe' --headless --path . --import --quit
& 'D:\Projects\godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe' --path .
```

The first command imports scripts and local assets. Missing required files are reported as `Tile model not found`, `Prop model not found`, or failed token resource loads.

## Project layout

- `scenes/levels/`: editable levels and their initial token placement.
- `scripts/core/`: grid authority, dungeon orchestration, and asset catalogs.
- `scripts/entities/`: tiles, props, and movable tokens.
- `scripts/ui/`: input, camera, highlights, and HUD.
- `tools/`: one-time scene generation utilities; do not run `build_tavern.gd` over a manually edited tavern scene.
