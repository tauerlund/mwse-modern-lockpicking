![Model](https://github.com/tauerlund/mwse-modern-lockpicking/blob/main/header.png)

An MWSE Lua mod that replaces Morrowind's chance-based lockpicking with a Skyrim-style minigame. Instead of rolling against your Security skill, you pick locks by hand: move the pick with the mouse to find the sweet spot, then rotate the cylinder using a knife as tension wrench. Security, Agility, Luck and pick quality decide how big the sweet spot is and how quickly your picks wear down.

## :link: Dependencies

- [mwse](https://github.com/MWSE/MWSE)

## :white_check_mark: Features

#### Gameplay

- Find the sweet spot with the pick, hold it there, and turn the cylinder all the way to open the lock.
- Turning the cylinder outside the sweet spot damages the pick: the harder the lock, the faster it wears down. At zero condition the pick snaps and is removed from your inventory.
- Cycle through all the lockpicks in your inventory mid-session. The last pick you used is remembered for the next lock.
- Optional lock complexity check: locks your best pick has no chance against (by the vanilla formula) can't be attempted at all.
- The skeleton key works like any other pick and is unbreakable by default (damage can be enabled).
- Picking a lock unlocks and opens the container or door, and exercises your Security skill.
- The mod can be disabled at any time in the MCM, falling back to vanilla lockpicking.

#### Visuals & audio

- A full 3D scene with lock, knife and pick meshes that animate on entry and follow your mouse.
- Lit rendering mode that lights the lock like the world around you (torches, light spells, etc.), with a simpler unlit mode as an alternative.
- The pick jiggles when the cylinder is blocked, getting worse as it takes damage.
- Broken picks visibly snap, with the tip flying off.
- Depth of field effect that blurs the background while picking (requires MGE).
- Sound effects for moving the pick, turning the cylinder, jiggling, cycling, breaking picks, and unlocking.
- In-game HUD with the lock level, a controls overview, and a list of your picks.
- Lockpick tooltips show remaining health instead of uses.
- Sweet spot debug renderer (MCM toggle).

#### Configuration

- Two activation modes: Activate (interact with a locked object) or Attack (swing your equipped pick like in vanilla).
- Rebindable keys for rotating the lock, cycling picks, and exiting.
- Difficulty sliders for the sweet spot size, gradient zone, and pick damage rate.
- Allow or block equipping lockpicks from the inventory.
- Custom lock meshes per activator via JSON config files.

#### Planned

- Animation upon successful lockpicking

## :beetle: Bugs

See [issues](https://github.com/tauerlund/mwse-modern-lockpicking/issues).
