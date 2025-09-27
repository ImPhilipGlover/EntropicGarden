# Archived TelOS Demos and Diagnostics

This directory houses non-canonical demonstration and diagnostic scripts that were previously stored at the repository root. The canonical runtime surface is defined under `libs/Telos/source`, `libs/Telos/io`, `libs/Telos/python`, and the active regression suites in `demos/tests/`. Legacy assets are preserved here for historical reference while keeping the root workspace focused on the maintained code paths.

- `cognitive_legacy/` – retired cognitive walkthroughs and full-path demos.
- `morphic_legacy/` – early Morphic UI chat experiments and visualization harnesses.
- `diagnostics/` – ad-hoc Morphic or SDL2 probes used during initial bring-up.

Scripts in these folders should not be treated as part of the supported build or test surface. Prefer the maintained suites in `demos/tests/` when validating behavior.
