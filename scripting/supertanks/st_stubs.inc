#if defined _st_stubs_included
 #endinput
#endif
#define _st_stubs_included

// ============================================================================
// TEMPORARY STUB FUNCTIONS
// These are placeholder implementations for functions that will be extracted
// to their respective modules in future phases of modularization.
// ============================================================================

// Finale/wave stubs - will be moved to systems/st_finale.inc
public Action:TimerTankWave2(Handle:timer) { return Plugin_Stop; }
public Action:TimerTankWave3(Handle:timer) { return Plugin_Stop; }

// Gamemode stubs - will be moved to nightmare modules
stock ExecGameModes() { }
