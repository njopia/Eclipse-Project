#if defined _st_constants_included
 #endinput
#endif
#define _st_constants_included

// ============================================================================
// CONSTANTS - Using #define for cross-file visibility
// ============================================================================

// Fade flags
#define FFADE_IN 0x0001
#define FFADE_OUT 0x0002
#define FFADE_MODULATE 0x0004
#define FFADE_STAYOUT 0x0008
#define FFADE_PURGE 0x0010

// Survivor models
#define MODEL_NICK "models/survivors/survivor_gambler.mdl"
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl"
#define MODEL_COACH "models/survivors/survivor_coach.mdl"
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl"
#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"

// Tank models
#define MODEL_TANK_DLC3 "models/infected/hulk_dlc3.mdl"

// Weapon view models
#define MODEL_V_FIREAXE "models/weapons/melee/v_fireaxe.mdl"
#define MODEL_V_FRYING_PAN "models/weapons/melee/v_frying_pan.mdl"
#define MODEL_V_MACHETE "models/weapons/melee/v_machete.mdl"
#define MODEL_V_BAT "models/weapons/melee/v_bat.mdl"
#define MODEL_V_CROWBAR "models/weapons/melee/v_crowbar.mdl"
#define MODEL_V_CRICKET_BAT "models/weapons/melee/v_cricket_bat.mdl"
#define MODEL_V_TONFA "models/weapons/melee/v_tonfa.mdl"
#define MODEL_V_KATANA "models/weapons/melee/v_katana.mdl"
#define MODEL_V_ELECTRIC_GUITAR "models/weapons/melee/v_electric_guitar.mdl"
#define MODEL_V_KNIFE "models/v_models/v_knife_t.mdl"
#define MODEL_V_GOLFCLUB "models/weapons/melee/v_golfclub.mdl"

// Prop models
#define MODEL_GASCAN "models/props_junk/gascan001a.mdl"
#define MODEL_PROPANE "models/props_junk/propanecanister001a.mdl"

// Particle effects
#define PARTICLE_LS_BOLT "storm_lightning_01_thin"
#define PARTICLE_SMOKE "apc_wheel_smoke1"
#define PARTICLE_FIRE "aircraft_destroy_fastFireTrail"
#define PARTICLE_WARP "electrical_arc_01_system"
#define PARTICLE_SPIT "spitter_areaofdenial_glow2"
#define PARTICLE_SPITPROJ "spitter_projectile"
#define PARTICLE_ELEC "electrical_arc_01_parent"
#define PARTICLE_BLOOD_EXPLODE "boomer_explode_D"
#define PARTICLE_EXPLODE "boomer_explode"
#define PARTICLE_METEOR "smoke_medium_01"
#define PARTICLE_FLARE "flare_burning"
#define PARTICLE_DEMON_SMOKE "smoke_campfire"

// Weapon classnames array - Must be declared in main file or variables file
// as arrays cannot be #defined
