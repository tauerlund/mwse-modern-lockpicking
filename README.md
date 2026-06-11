# Modern Lockpicking (MWSE Lua)

MWSE Lua mod that introduces a Skyrim-like lockpicking system in The Elder Scrolls III: Morrowind.

## :link: Dependencies:

- [mwse](https://github.com/MWSE/MWSE)

## :white_check_mark: Features:

#### Visuals

- [x] Render lock mesh
- [x] Render knife mesh (tension wrench)
- [x] Render lockpick mesh
- [x] Animate lock, knife, and lockpick on entry
- [x] Animate lock following mouse position
- [x] Animate knife when rotating cylinder
- [x] Animate lockpick following mouse position
- [x] Animate lockpick jitter when cylinder is blocked
- [x] Depth of field effect (requires MGE)
- [x] Sweet spot debug renderer (MCM toggle)
- [ ] Animation upon successful lockpicking

#### Gameplay

- [x] Unlock container/door upon successful lockpicking
- [x] Open container/door upon successful lockpicking
- [x] Sweet spot with configurable gradient zone
- [x] Pick damage when outside sweet spot, scaling with lock difficulty
- [x] Break and remove picks from inventory when condition reaches zero
- [x] Cycle through multiple lockpicks during a session
- [x] Persist last-used pick selection across sessions
- [x] Skeleton key support (configurable damage)
- [x] Lock complexity check (block picks too weak for a lock)
- [x] Disable mod without uninstalling (vanilla lockpicking fallback)

#### Configuration

- [x] Two activation modes: Activate (interact with lock) or Attack (intercept vanilla lockpick swing)
- [x] Configurable keybinds (rotate lock, cycle picks, exit)
- [x] Allow or block equipping picks from inventory
- [x] Difficulty sliders (security factor, lock level factor, quality factor, max sweet spot radius, gradient factor, pick damage rate)
- [x] Skeleton key damage toggle
- [x] Reset difficulty to defaults
- [x] Dynamic lock mesh overrides via JSON config files

## :beetle: Bugs:

- [ ] Cylinder can be rotated while a new pick is spawning
