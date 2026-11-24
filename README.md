# Lost Island: Survival Quest

An offline, low-poly 3D survival adventure built with Godot 4.4+. The project uses original procedural geometry and does not require paid assets or online services.

## Run the game
1. Install Godot 4.4 or newer.
2. Open `project.godot` in Godot Project Manager.
3. Press **F6** to run the main scene or **F5** to run the project.

### Controls
- **WASD** move, **mouse** look, **Shift** sprint, **Space** jump.
- **E** interact / collect, **F** attack, **Escape** release mouse capture.
- HUD buttons provide touch movement, sprint, jump, interaction, combat, inventory, crafting and save.
- Mobile camera look: drag on the right half of the screen.

## Current playable systems
- Procedural tropical island scene, ocean, forest, spring, cave marker, abandoned camp and ancient ruins.
- Third-person character, keyboard and touch movement, camera look, sprint and jump.
- Hunger, thirst, health, pickups and basic enemy pursuit/combat.
- Inventory display, craftable axe/spear/shelter/campfire, a 10-step mission sequence and discovered landmark state.
- Local JSON save/load at `user://lost_island_save.json`.

## Android export
The repository contains an Android export preset (`export_presets.cfg`) configured for `com.lostisland.survivalquest`, landscape orientation and arm64. Install the Android SDK, JDK and matching Godot export templates. Configure SDK/JDK paths in **Editor > Editor Settings > Export > Android**, then use **Project > Export > Android** to produce a debug APK. Configure a signing keystore in the preset before making a release build.

## Notes
The repository contains source project files only; no APK has been generated or tested in this environment. This is an early playable foundation and has not been validated with the Godot editor/Android toolchain. Further work is needed for complete mission content, balanced encounters, audio, polished art, map/menu screens, robust mobile testing and production release QA.
