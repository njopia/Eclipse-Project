# SuperTanks Nightmare - Modular Structure

This is a modularized version of the Natan SuperTanks Nightmare plugin for L4D2.

## Structure

```
scripting/
├── natan_supertanks_nightmare.sp     [MAIN PLUGIN]
└── supertanks/
    ├── st_constants.inc               [Constants & Definitions]
    ├── st_variables.inc               [Global Variables]
    ├── st_config.inc                  [ConVars & Configuration]
    │
    ├── tanks/
    │   ├── st_tank_base.inc          [Base Tank System]
    │   ├── st_tank_smasher.inc       [Smasher Tank]
    │   ├── st_tank_warp.inc          [Warp Tank]
    │   ├── st_tank_meteor.inc        [Meteor Tank]
    │   ├── st_tank_spitter.inc       [Spitter Tank]
    │   ├── st_tank_heal.inc          [Heal Tank]
    │   ├── st_tank_fire.inc          [Fire Tank]
    │   ├── st_tank_ice.inc           [Ice Tank]
    │   ├── st_tank_jockey.inc        [Jockey Tank]
    │   ├── st_tank_ghost.inc         [Ghost Tank]
    │   ├── st_tank_shock.inc         [Shock Tank]
    │   ├── st_tank_witch.inc         [Witch Tank & Witch Management]
    │   ├── st_tank_shield.inc        [Shield Tank]
    │   ├── st_tank_cobalt.inc        [Cobalt Tank]
    │   ├── st_tank_jumper.inc        [Jumper Tank]
    │   ├── st_tank_gravity.inc       [Gravity Tank]
    │   └── st_tank_demon.inc         [Demon Tank]
    │
    ├── nightmare/
    │   ├── st_nightmare_core.inc      [Nightmare Mode Core]
    │   ├── st_nightmare_difficulty.inc [Auto-Difficulty System]
    │   ├── st_nightmare_spawning.inc  [Enhanced Spawning]
    │   └── st_nightmare_environment.inc [Environmental Effects]
    │
    ├── systems/
    │   ├── st_damage.inc             [Damage Handling]
    │   ├── st_effects.inc            [Visual/Particle Effects]
    │   ├── st_spawning.inc           [Spawn Management]
    │   ├── st_finale.inc             [Finale Management]
    │   └── st_events.inc             [Event Handlers]
    │
    └── utilities/
        ├── st_sdk.inc                [SDK Calls]
        ├── st_utils.inc              [Utility Functions]
        ├── st_precache.inc           [Precaching]
        └── st_timers.inc             [Timer Management]
```

## Tank Types

0. **Normal/Default Tank** - Standard tank with customizable stats
1. **Smasher Tank** - High damage melee attacks, crushes survivors
2. **Warp Tank** - Teleports to survivors periodically
3. **Meteor Tank** - Spawns falling meteors
4. **Spitter Tank** - Shoots acid projectiles
5. **Heal Tank** - Regenerates health when near survivors
6. **Fire Tank** - Sets survivors on fire
7. **Ice Tank** - Freezes/slows survivors
8. **Jockey Tank** - Throws jockeys at survivors
9. **Ghost Tank** - Can cloak and disarm survivors
10. **Shock Tank** - Stuns survivors with electrical attacks
11. **Witch Tank** - Spawns witches
12. **Shield Tank** - Has protective shields
13. **Cobalt Tank** - Speed-burst tank
14. **Jumper Tank** - Jumps/leaps at survivors
15. **Gravity Tank** - Pulls survivors toward it
16. **Demon Tank** - Progressive difficulty tank (Nightmare Mode)

## Compilation

To compile the plugin, simply compile the main file:
```
spcomp natan_supertanks_nightmare.sp
```

All include files will be automatically included.

## Configuration

The plugin generates `SuperTanks.cfg` in your cfg/sourcemod/ folder.

## Dependencies

- SourceMod 1.7+
- gamedata/supertanks.txt (SDK signatures)

## Credits

Original plugin by Natan
Modularized structure for maintainability
