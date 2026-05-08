#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === INFERNO MODE MODULE ===
// Tercer nivel de dificultad. Overlay amarillo-naranja,
// fog denso, dano x2.0 y hordas masivas.
//==================================================

// =============================================================================
// CONVARS
// =============================================================================

Handle g_cvar_Inferno_Enable            = INVALID_HANDLE;
Handle g_cvar_Inferno_DmgMult           = INVALID_HANDLE;
Handle g_cvar_Inferno_Fade              = INVALID_HANDLE;
Handle g_cvar_Inferno_ChangeDiff        = INVALID_HANDLE;
Handle g_cvar_Inferno_CommonLimit       = INVALID_HANDLE;
Handle g_cvar_Inferno_MobMin            = INVALID_HANDLE;
Handle g_cvar_Inferno_MobMax            = INVALID_HANDLE;
Handle g_cvar_Inferno_MegaMob           = INVALID_HANDLE;
Handle g_cvar_Inferno_LightStyle        = INVALID_HANDLE;
Handle g_cvar_Inferno_LightStyleRestore = INVALID_HANDLE;
Handle g_cvar_Inferno_FogEnable         = INVALID_HANDLE;
Handle g_cvar_Inferno_FogColor          = INVALID_HANDLE;
Handle g_cvar_Inferno_FogStart          = INVALID_HANDLE;
Handle g_cvar_Inferno_FogEnd            = INVALID_HANDLE;
Handle g_cvar_Inferno_FogDensity        = INVALID_HANDLE;
Handle g_cvar_Inferno_FogTick           = INVALID_HANDLE;
Handle g_cvar_Inferno_ParticleName      = INVALID_HANDLE;
Handle g_cvar_Inferno_ParticleCount     = INVALID_HANDLE;
Handle g_cvar_Inferno_SoundStart        = INVALID_HANDLE;
Handle g_cvar_Inferno_SoundLoop         = INVALID_HANDLE;
Handle g_cvar_Inferno_FadeAlpha         = INVALID_HANDLE;
Handle g_cvar_Inferno_FadeDuration      = INVALID_HANDLE;
Handle g_cvar_Inferno_DebugDamage            = INVALID_HANDLE;
Handle g_cvar_Inferno_TankSpawn              = INVALID_HANDLE;
Handle g_cvar_Inferno_TankInterval           = INVALID_HANDLE;
Handle g_cvar_Inferno_TankMax                = INVALID_HANDLE;
Handle g_cvar_Inferno_PanicEvents            = INVALID_HANDLE;
Handle g_cvar_Inferno_PanicInterval          = INVALID_HANDLE;
Handle g_cvar_Inferno_WitchEnable            = INVALID_HANDLE;
Handle g_cvar_Inferno_WitchMax               = INVALID_HANDLE;
Handle g_cvar_Inferno_WitchRecycleDist       = INVALID_HANDLE;
Handle g_cvar_Inferno_RemoveCommons          = INVALID_HANDLE;
Handle g_cvar_Inferno_MegaMobSound           = INVALID_HANDLE;
Handle g_cvar_Inferno_MegaMobSoundChance     = INVALID_HANDLE;
Handle g_cvar_Inferno_MeteorEnable           = INVALID_HANDLE;
Handle g_cvar_Inferno_MeteorChance           = INVALID_HANDLE;
Handle g_cvar_Inferno_InstaCapEnable         = INVALID_HANDLE;
Handle g_cvar_Inferno_InstaCapChance         = INVALID_HANDLE;
Handle g_cvar_Inferno_TonemapEnable          = INVALID_HANDLE;
Handle g_cvar_Inferno_BloomScale             = INVALID_HANDLE;
Handle g_cvar_Inferno_ExposureMin            = INVALID_HANDLE;
Handle g_cvar_Inferno_ExposureMax            = INVALID_HANDLE;

// ConVars del juego
Handle g_zCVAR_CommonLimit_Inf = INVALID_HANDLE;
Handle g_zCVAR_MobMin_Inf      = INVALID_HANDLE;
Handle g_zCVAR_MobMax_Inf      = INVALID_HANDLE;
Handle g_zCVAR_MegaMob_Inf     = INVALID_HANDLE;
Handle g_zCVAR_Difficulty_Inf  = INVALID_HANDLE;

// =============================================================================
// ESTADO
// =============================================================================

bool   g_bInfernoActive              = false;
bool   g_bIsInstaCapper_Inf[MAXPLAYERS + 1];
int    g_iFogRef_Inf         = -1;
Handle g_hFogTimer_Inf       = null;
int    g_iParticleRefs_Inf[16];
int    g_iParticleTotal_Inf  = 0;

int  g_iOrigCommonLimit_Inf = -1;
int  g_iOrigMobMin_Inf      = -1;
int  g_iOrigMobMax_Inf      = -1;
int  g_iOrigMegaMob_Inf     = -1;
char g_sOrigDifficulty_Inf[16];

Handle g_hEventTimer_Inf    = null;
int    g_iTankCount_Inf     = 0;
float  g_fLastTankSpawn_Inf = 0.0;
float  g_fLastPanic_Inf     = 0.0;
float  g_fMapStart_Inf      = 0.0;
int    g_iTonemapRef_Inf    = -1;

// =============================================================================
// INICIALIZACION
// =============================================================================

public void Inferno_OnPluginStart()
{
	g_cvar_Inferno_Enable      = CreateConVar("inferno_enable",           "1",          "Habilita Inferno Mode",             FCVAR_PLUGIN);
	g_cvar_Inferno_DmgMult     = CreateConVar("inferno_damage_mult",      "2.0",        "Multiplicador de dano a Survivors", FCVAR_PLUGIN);
	g_cvar_Inferno_Fade        = CreateConVar("inferno_fade",             "1",          "Overlay amarillo-naranja",          FCVAR_PLUGIN);
	g_cvar_Inferno_ChangeDiff  = CreateConVar("inferno_change_difficulty","1",          "Cambiar dificultad a Imposible",    FCVAR_PLUGIN);
	g_cvar_Inferno_CommonLimit = CreateConVar("inferno_common_limit",     "60",         "z_common_limit",                    FCVAR_PLUGIN);
	g_cvar_Inferno_MobMin      = CreateConVar("inferno_mob_min",          "35",         "z_mob_spawn_min_size",              FCVAR_PLUGIN);
	g_cvar_Inferno_MobMax      = CreateConVar("inferno_mob_max",          "50",         "z_mob_spawn_max_size",              FCVAR_PLUGIN);
	g_cvar_Inferno_MegaMob     = CreateConVar("inferno_mega_mob",         "80",         "z_mega_mob_size",                   FCVAR_PLUGIN);
	g_cvar_Inferno_LightStyle  = CreateConVar("inferno_lightstyle",       "c",          "LightStyle activo",                 FCVAR_PLUGIN);
	g_cvar_Inferno_LightStyleRestore = CreateConVar("inferno_lightstyle_restore","m",   "LightStyle a restaurar",            FCVAR_PLUGIN);
	g_cvar_Inferno_FogEnable   = CreateConVar("inferno_fog_enable",       "1",          "Crear fog",                         FCVAR_PLUGIN);
	g_cvar_Inferno_FogColor    = CreateConVar("inferno_fog_color",        "255 150 0",  "Color fog 'r g b'",                 FCVAR_PLUGIN);
	g_cvar_Inferno_FogStart    = CreateConVar("inferno_fog_start",        "30",         "Fog start distance",                FCVAR_PLUGIN);
	g_cvar_Inferno_FogEnd      = CreateConVar("inferno_fog_end",          "800",        "Fog end distance",                  FCVAR_PLUGIN);
	g_cvar_Inferno_FogDensity  = CreateConVar("inferno_fog_density",      "0.85",       "Fog max density",                   FCVAR_PLUGIN);
	g_cvar_Inferno_FogTick     = CreateConVar("inferno_fog_tick",         "3.0",        "Intervalo re-aplicar fog",          FCVAR_PLUGIN);
	g_cvar_Inferno_ParticleName  = CreateConVar("inferno_particle",       "env_fire_medium_smoke","Particula ambiental",    FCVAR_PLUGIN);
	g_cvar_Inferno_ParticleCount = CreateConVar("inferno_particle_count", "6",          "Cantidad de emisores",              FCVAR_PLUGIN);
	g_cvar_Inferno_SoundStart  = CreateConVar("inferno_sound_start",      "",           "Sonido al activar",                 FCVAR_PLUGIN);
	g_cvar_Inferno_SoundLoop   = CreateConVar("inferno_sound_loop",       "",           "Sonido loop",                       FCVAR_PLUGIN);
	g_cvar_Inferno_FadeAlpha   = CreateConVar("inferno_fade_alpha",       "130",        "Alpha overlay 0-255",               FCVAR_PLUGIN);
	g_cvar_Inferno_FadeDuration = CreateConVar("inferno_fade_duration",   "1500",       "Duracion transicion ms",            FCVAR_PLUGIN);
	g_cvar_Inferno_DebugDamage         = CreateConVar("inferno_debug_damage",          "0",    "Debug dano",                        FCVAR_PLUGIN);
	g_cvar_Inferno_TankSpawn           = CreateConVar("inferno_tank_spawn",            "1",    "Spawn automatico de tanks",          FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Inferno_TankInterval        = CreateConVar("inferno_tank_interval",         "60.0", "Intervalo spawn de tanks (s)",       FCVAR_PLUGIN, true, 0.0);
	g_cvar_Inferno_TankMax             = CreateConVar("inferno_tank_max",              "3",    "Max tanks simultaneos",              FCVAR_PLUGIN, true, 1.0);
	g_cvar_Inferno_PanicEvents         = CreateConVar("inferno_panic_events",          "1",    "Panic events periodicos",            FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Inferno_PanicInterval       = CreateConVar("inferno_panic_interval",        "30.0", "Intervalo panic events (s)",         FCVAR_PLUGIN, true, 0.0);
	g_cvar_Inferno_WitchEnable         = CreateConVar("inferno_witch_enable",          "1",    "Sistema de witches activo",          FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Inferno_WitchMax            = CreateConVar("inferno_witch_max",             "66",   "Max witches simultaneas",            FCVAR_PLUGIN, true, 1.0);
	g_cvar_Inferno_WitchRecycleDist    = CreateConVar("inferno_witch_recycle_dist",    "1000", "Distancia (u) para reciclar witches",FCVAR_PLUGIN, true, 0.0);
	g_cvar_Inferno_RemoveCommons       = CreateConVar("inferno_remove_commons",        "1",    "Eliminar comunes periodicamente",    FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Inferno_MegaMobSound        = CreateConVar("inferno_megamob_sound",         "1",    "Sonido aleatorio mega mob",          FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Inferno_MegaMobSoundChance  = CreateConVar("inferno_megamob_sound_chance",  "15",   "Probabilidad 1/N sonido mega mob",   FCVAR_PLUGIN, true, 1.0);
	g_cvar_Inferno_MeteorEnable        = CreateConVar("inferno_meteor_enable",          "1",    "Lluvia de meteoritos",               FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Inferno_MeteorChance        = CreateConVar("inferno_meteor_chance",          "2",    "Probabilidad 1/N de lanzar meteoro", FCVAR_PLUGIN, true, 1.0);
	g_cvar_Inferno_InstaCapEnable      = CreateConVar("inferno_instacap_enable",        "1",    "Infectados que incapacitan al instante", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Inferno_InstaCapChance      = CreateConVar("inferno_instacap_chance",        "60",   "Probabilidad 1/N de crear insta-cappers", FCVAR_PLUGIN, true, 1.0);
	g_cvar_Inferno_TonemapEnable       = CreateConVar("inferno_tonemap_enable",         "1",    "Tonemap (bloom/exposicion)",              FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Inferno_BloomScale          = CreateConVar("inferno_bloom_scale",            "5.0",  "Intensidad bloom",                       FCVAR_PLUGIN, true, 0.0);
	g_cvar_Inferno_ExposureMin         = CreateConVar("inferno_exposure_min",           "0.4",  "Exposicion minima",                      FCVAR_PLUGIN, true, 0.0);
	g_cvar_Inferno_ExposureMax         = CreateConVar("inferno_exposure_max",           "0.9",  "Exposicion maxima",                      FCVAR_PLUGIN, true, 0.0);

	g_zCVAR_CommonLimit_Inf = FindConVar("z_common_limit");
	g_zCVAR_MobMin_Inf      = FindConVar("z_mob_spawn_min_size");
	g_zCVAR_MobMax_Inf      = FindConVar("z_mob_spawn_max_size");
	g_zCVAR_MegaMob_Inf     = FindConVar("z_mega_mob_size");
	g_zCVAR_Difficulty_Inf  = FindConVar("z_difficulty");

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, Inferno_OnTakeDamage);

	HookEvent("player_death",          Inferno_Event_PlayerDeath);
	HookEvent("tank_killed",           Inferno_Event_TankKilled);
	HookEvent("tongue_grab",           Inferno_Event_TongueGrab);
	HookEvent("lunge_pounce",          Inferno_Event_LungePounce);
	HookEvent("jockey_ride",           Inferno_Event_JockeyRide);
	HookEvent("charger_pummel_start",  Inferno_Event_ChargerPummel);
	HookEvent("player_now_it",         Inferno_Event_PlayerNowIt);

	RegAdminCmd("sm_inferno_on",     Cmd_InfernoOn,     ADMFLAG_GENERIC, "Activa Inferno Mode");
	RegAdminCmd("sm_inferno_off",    Cmd_InfernoOff,    ADMFLAG_GENERIC, "Desactiva Inferno Mode");
	RegAdminCmd("sm_inferno_toggle", Cmd_InfernoToggle, ADMFLAG_GENERIC, "Alterna Inferno Mode");
	RegAdminCmd("sm_inferno_status", Cmd_InfernoStatus, ADMFLAG_GENERIC, "Estado Inferno Mode");

	HookConVarChange(g_cvar_Inferno_Enable, Inferno_ConVarChanged);

	DifficultyOrchestrator_Register(MODE_INFERNO, g_cvar_Inferno_Enable);
}

public void Inferno_OnMapStart()
{
	g_iOrigCommonLimit_Inf = g_iOrigMobMin_Inf = g_iOrigMobMax_Inf = g_iOrigMegaMob_Inf = -1;
	g_sOrigDifficulty_Inf[0] = '\0';
	g_iFogRef_Inf = -1;
	for (int i = 0; i < 16; i++) g_iParticleRefs_Inf[i] = -1;
	g_iParticleTotal_Inf  = 0;
	g_fMapStart_Inf       = GetGameTime();
	g_iTankCount_Inf      = 0;
	g_fLastTankSpawn_Inf  = g_fLastPanic_Inf = 0.0;
	g_iTonemapRef_Inf     = -1;
	for (int i = 0; i <= MaxClients; i++) g_bIsInstaCapper_Inf[i] = false;
	PrecacheSound("npc/mega_mob/mega_mob_incoming.wav", true);
	PrecacheModel("models/props_debris/concrete_chunk01a.mdl", true);
}

public void Inferno_OnMapEnd()
{
	if (g_bInfernoActive) Inferno_Deactivate("map_end");
}

public void Inferno_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Inferno_OnTakeDamage);
}

public void Inferno_OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Inferno_OnTakeDamage);
	g_bIsInstaCapper_Inf[client] = false;
}

// =============================================================================
// CONVAR HOOK
// =============================================================================

public void Inferno_ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	bool bNew = view_as<bool>(StringToInt(newValue));
	bool bOld = view_as<bool>(StringToInt(oldValue));
	if (bNew == bOld) return;

	if (bNew && !g_bInfernoActive)
		Inferno_Activate("convar");
	else if (!bNew && g_bInfernoActive)
		Inferno_Deactivate("convar");
}

// =============================================================================
// DAMAGE HOOK
// =============================================================================

public Action Inferno_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	return DiffBase_ApplyDamageMult(victim, attacker, inflictor, damage,
		g_bInfernoActive,
		GetConVarFloat(g_cvar_Inferno_DmgMult),
		GetConVarBool(g_cvar_Inferno_DebugDamage),
		"Inferno");
}

// =============================================================================
// ACTIVACION
// =============================================================================

void Inferno_Activate(const char[] reason = "manual")
{
	if (g_bInfernoActive) return;
	#pragma unused reason

	DiffBase_BackupDirector(
		g_zCVAR_CommonLimit_Inf, g_zCVAR_MobMin_Inf, g_zCVAR_MobMax_Inf,
		g_zCVAR_MegaMob_Inf,     g_zCVAR_Difficulty_Inf,
		g_iOrigCommonLimit_Inf,  g_iOrigMobMin_Inf,      g_iOrigMobMax_Inf,
		g_iOrigMegaMob_Inf,      g_sOrigDifficulty_Inf,  sizeof(g_sOrigDifficulty_Inf));

	DiffBase_ApplyDirector(
		g_zCVAR_CommonLimit_Inf, g_zCVAR_MobMin_Inf, g_zCVAR_MobMax_Inf, g_zCVAR_MegaMob_Inf,
		GetConVarInt(g_cvar_Inferno_CommonLimit),
		GetConVarInt(g_cvar_Inferno_MobMin),
		GetConVarInt(g_cvar_Inferno_MobMax),
		GetConVarInt(g_cvar_Inferno_MegaMob));

	g_bInfernoActive      = true;
	g_iTankCount_Inf      = 0;
	g_fLastTankSpawn_Inf  = g_fLastPanic_Inf = GetGameTime();
	Inferno_StartEventTimer();

	char ls[8];
	GetConVarString(g_cvar_Inferno_LightStyle, ls, sizeof(ls));
	DiffBase_ApplyLightStyle(ls);

	if (GetConVarBool(g_cvar_Inferno_TonemapEnable))
		DiffBase_CreateTonemapController(
			GetConVarFloat(g_cvar_Inferno_BloomScale),
			GetConVarFloat(g_cvar_Inferno_ExposureMin),
			GetConVarFloat(g_cvar_Inferno_ExposureMax),
			g_iTonemapRef_Inf);

	if (GetConVarBool(g_cvar_Inferno_FogEnable))
	{
		char color[32];
		GetConVarString(g_cvar_Inferno_FogColor, color, sizeof(color));
		int ent = DiffBase_SpawnFogController(color,
			GetConVarInt(g_cvar_Inferno_FogStart),
			GetConVarInt(g_cvar_Inferno_FogEnd),
			GetConVarFloat(g_cvar_Inferno_FogDensity),
			g_iFogRef_Inf);
		g_iFogRef_Inf = (ent != -1) ? EntIndexToEntRef(ent) : -1;
		Inferno_StartFogTimer();
	}

	char pname[64];
	GetConVarString(g_cvar_Inferno_ParticleName, pname, sizeof(pname));
	DiffBase_CreateAmbientParticles(pname,
		GetConVarInt(g_cvar_Inferno_ParticleCount),
		g_iParticleRefs_Inf, g_iParticleTotal_Inf);

	char sStart[128], sLoop[128];
	GetConVarString(g_cvar_Inferno_SoundStart, sStart, sizeof(sStart));
	GetConVarString(g_cvar_Inferno_SoundLoop,  sLoop,  sizeof(sLoop));
	DiffBase_PlaySoundToAll(sStart);
	DiffBase_PlaySoundToAll(sLoop);

	if (GetConVarBool(g_cvar_Inferno_Fade))
		DiffBase_DoScreenFadeAll(true, 255, 150, 0,
			GetConVarInt(g_cvar_Inferno_FadeAlpha),
			GetConVarInt(g_cvar_Inferno_FadeDuration));

	if (GetConVarBool(g_cvar_Inferno_ChangeDiff))
		ServerCommand("z_difficulty Impossible");

	PrintToChatAll("\x04[Inferno]\x01 INFERNO SUPREMO ACTIVADO! El fuego eterno te aguarda (x%.2f dano)",
		GetConVarFloat(g_cvar_Inferno_DmgMult));
}

// =============================================================================
// DESACTIVACION
// =============================================================================

void Inferno_Deactivate(const char[] reason = "manual")
{
	if (!g_bInfernoActive) return;
	#pragma unused reason

	g_bInfernoActive  = false;
	g_iTankCount_Inf  = 0;
	Inferno_StopEventTimer();

	DiffBase_RestoreDirector(
		g_zCVAR_CommonLimit_Inf, g_zCVAR_MobMin_Inf, g_zCVAR_MobMax_Inf,
		g_zCVAR_MegaMob_Inf,     g_zCVAR_Difficulty_Inf,
		g_iOrigCommonLimit_Inf,  g_iOrigMobMin_Inf,      g_iOrigMobMax_Inf,
		g_iOrigMegaMob_Inf,      g_sOrigDifficulty_Inf);

	DiffBase_RemoveTonemapController(g_iTonemapRef_Inf);
	DiffBase_RemoveAmbientParticles(g_iParticleRefs_Inf, g_iParticleTotal_Inf);
	Inferno_StopFogTimer();
	DiffBase_RemoveFogController(g_iFogRef_Inf);

	char ls[8];
	GetConVarString(g_cvar_Inferno_LightStyleRestore, ls, sizeof(ls));
	DiffBase_ApplyLightStyle(ls);

	char sLoop[128];
	GetConVarString(g_cvar_Inferno_SoundLoop, sLoop, sizeof(sLoop));
	DiffBase_StopSoundToAll(sLoop);

	if (GetConVarBool(g_cvar_Inferno_ChangeDiff) && g_sOrigDifficulty_Inf[0] != '\0')
		ServerCommand("z_difficulty %s", g_sOrigDifficulty_Inf);

	if (GetConVarBool(g_cvar_Inferno_Fade))
		DiffBase_DoScreenFadeAll(false, 255, 150, 0,
			GetConVarInt(g_cvar_Inferno_FadeAlpha),
			GetConVarInt(g_cvar_Inferno_FadeDuration));

	PrintToChatAll("\x04[Inferno]\x01 Inferno DESACTIVADO. Has sobrevivido al fuego eterno.");
}

// =============================================================================
// FOG TIMER
// =============================================================================

void Inferno_StartFogTimer()
{
	if (g_hFogTimer_Inf != null) return;
	float tick = GetConVarFloat(g_cvar_Inferno_FogTick);
	if (tick < 1.0) tick = 1.0;
	g_hFogTimer_Inf = CreateTimer(tick, Inferno_Timer_FogEnforcer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void Inferno_StopFogTimer()
{
	if (g_hFogTimer_Inf != null) { KillTimer(g_hFogTimer_Inf); g_hFogTimer_Inf = null; }
}

public Action Inferno_Timer_FogEnforcer(Handle timer)
{
	if (!g_bInfernoActive || !GetConVarBool(g_cvar_Inferno_FogEnable))
		return Plugin_Continue;

	char color[32];
	GetConVarString(g_cvar_Inferno_FogColor, color, sizeof(color));
	DiffBase_EnsureFogController(g_iFogRef_Inf, color,
		GetConVarInt(g_cvar_Inferno_FogStart),
		GetConVarInt(g_cvar_Inferno_FogEnd),
		GetConVarFloat(g_cvar_Inferno_FogDensity));

	return Plugin_Continue;
}

// =============================================================================
// COMANDOS ADMIN
// =============================================================================

public Action Cmd_InfernoOn(int client, int args)
{
	if (!GetConVarBool(g_cvar_Inferno_Enable))
		{ ReplyToCommand(client, "[Inferno] Sistema deshabilitado"); return Plugin_Handled; }
	Inferno_Activate("admin");
	ReplyToCommand(client, "[Inferno] ACTIVADO");
	return Plugin_Handled;
}

public Action Cmd_InfernoOff(int client, int args)
{
	Inferno_Deactivate("admin");
	ReplyToCommand(client, "[Inferno] DESACTIVADO");
	return Plugin_Handled;
}

public Action Cmd_InfernoToggle(int client, int args)
{
	return g_bInfernoActive ? Cmd_InfernoOff(client, args) : Cmd_InfernoOn(client, args);
}

public Action Cmd_InfernoStatus(int client, int args)
{
	char diff[16];
	if (g_zCVAR_Difficulty_Inf) GetConVarString(g_zCVAR_Difficulty_Inf, diff, sizeof(diff));
	ReplyToCommand(client, "[Inferno] Activo: %s | Mult: %.2f | Dif: %s",
		g_bInfernoActive ? "SI" : "NO",
		GetConVarFloat(g_cvar_Inferno_DmgMult),
		diff[0] ? diff : "n/a");
	return Plugin_Handled;
}

// =============================================================================
// EVENT TIMER (tanks, panic, witches, remove commons, mega mob sound)
// =============================================================================

void Inferno_StartEventTimer()
{
	if (g_hEventTimer_Inf != null) return;
	g_hEventTimer_Inf = CreateTimer(5.0, Inferno_Timer_Events, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void Inferno_StopEventTimer()
{
	if (g_hEventTimer_Inf != null) { KillTimer(g_hEventTimer_Inf); g_hEventTimer_Inf = null; }
}

public Action Inferno_Timer_Events(Handle timer)
{
	if (!g_bInfernoActive) return Plugin_Continue;
	float now = GetGameTime();
	if (now - g_fMapStart_Inf < 10.0) return Plugin_Continue;

	// 1. Tanks (max configurable, defecto 3)
	if (GetConVarBool(g_cvar_Inferno_TankSpawn))
	{
		float interval = GetConVarFloat(g_cvar_Inferno_TankInterval);
		int   tankMax  = GetConVarInt(g_cvar_Inferno_TankMax);
		if (interval > 0.0 && (now - g_fLastTankSpawn_Inf) >= interval
			&& g_iTankCount_Inf < tankMax && !DiffBase_IsFinaleActive())
		{
			int target = DiffBase_FindSurvivorTarget();
			if (target != -1)
			{
				float pos[3], ang[3];
				if (L4D_GetRandomPZSpawnPosition(target, view_as<int>(L4D2ZombieClass_Tank), 10, pos))
				{
					GetClientAbsAngles(target, ang);
					int tank = L4D2_SpawnTank(pos, ang);
					if (tank > 0) g_iTankCount_Inf++;
				}
			}
			g_fLastTankSpawn_Inf = now;
		}
	}

	// 2. Panic
	if (GetConVarBool(g_cvar_Inferno_PanicEvents))
	{
		float interval = GetConVarFloat(g_cvar_Inferno_PanicInterval);
		if (interval > 0.0 && (now - g_fLastPanic_Inf) >= interval)
		{
			L4D_ForcePanicEvent();
			g_fLastPanic_Inf = now;
		}
	}

	// 3. Witches (cascada agresiva: hasta 5 spawns por tick, enrage x6)
	if (GetConVarBool(g_cvar_Inferno_WitchEnable))
	{
		int witchMax   = GetConVarInt(g_cvar_Inferno_WitchMax);
		int witchCount = L4D2_GetWitchCount();
		// Cascada: cuantas menos witches hay, mas spawna por tick
		if (witchCount < witchMax)         DiffBase_SpawnWitch();
		if (witchCount < witchMax * 4 / 5) DiffBase_SpawnWitch();
		if (witchCount < witchMax * 3 / 5) DiffBase_SpawnWitch();
		if (witchCount < witchMax * 2 / 5) DiffBase_SpawnWitch();
		if (witchCount < witchMax / 5)     DiffBase_SpawnWitch();

		DiffBase_RecycleWitches(float(GetConVarInt(g_cvar_Inferno_WitchRecycleDist)));
		// Enrage masivo: 6 pasadas
		for (int j = 0; j < 6; j++)
			DiffBase_EnrageWitches(GetRandomInt(2, 6));
	}

	// 4. Eliminar comunes (para dejar paso a las witches)
	if (GetConVarBool(g_cvar_Inferno_RemoveCommons))
		DiffBase_RemoveCommonInfected();

	// 5. Meteoros: siempre revisar rocks cerca del suelo; lanzar nuevo segun chance
	if (GetConVarBool(g_cvar_Inferno_MeteorEnable))
	{
		int chance = GetConVarInt(g_cvar_Inferno_MeteorChance);
		bool launchNew = (chance > 0 && GetRandomInt(1, chance) == 1);
		Inferno_MeteorFall(launchNew);
	}

	// 6. Mega mob sound
	if (GetConVarBool(g_cvar_Inferno_MegaMobSound))
	{
		int chance = GetConVarInt(g_cvar_Inferno_MegaMobSoundChance);
		if (chance > 0 && GetRandomInt(1, chance) == 1)
			EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN);
	}

	// 7. Insta-cappers
	if (GetConVarBool(g_cvar_Inferno_InstaCapEnable))
	{
		int chance = GetConVarInt(g_cvar_Inferno_InstaCapChance);
		if (chance > 0 && GetRandomInt(1, chance) == 1)
			Inferno_CreateInstaCappers();
	}

	return Plugin_Continue;
}

public void Inferno_Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bInfernoActive) return;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (victim > 0 && IsClientInGame(victim)
		&& GetClientTeam(victim) == 3
		&& GetEntProp(victim, Prop_Send, "m_zombieClass") == 8
		&& g_iTankCount_Inf > 0)
		g_iTankCount_Inf--;
}

public void Inferno_Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bInfernoActive) return;
	if (g_iTankCount_Inf > 0) g_iTankCount_Inf--;
}

// =============================================================================
// INSTA-CAPPERS
// =============================================================================

// Spawna 2 especiales con 1666 HP, velocidad 1.3x y glow verde
void Inferno_CreateInstaCappers()
{
	int target = DiffBase_FindSurvivorTarget();
	if (target == -1) return;

	float ang[3];
	GetClientAbsAngles(target, ang);

	for (int n = 0; n < 2; n++)
	{
		int zombieClass = GetRandomInt(1, 6);
		float pos[3];
		if (!L4D_GetRandomPZSpawnPosition(target, zombieClass, 10, pos)) continue;

		int bot = L4D2_SpawnSpecial(zombieClass, pos, ang);
		if (bot < 1) continue;

		g_bIsInstaCapper_Inf[bot] = true;
		CreateTimer(0.2, Inferno_Timer_SetupInstaCapper, GetClientUserId(bot), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Inferno_Timer_SetupInstaCapper(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client < 1 || !IsClientInGame(client) || !IsFakeClient(client)) return Plugin_Stop;

	SetEntProp(client, Prop_Send, "m_iMaxHealth", 1666);
	SetEntProp(client, Prop_Send, "m_iHealth", 1666);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.3);
	SetEntProp(client, Prop_Send, "m_iGlowType", 2);
	SetEntProp(client, Prop_Send, "m_glowColorOverride", (70 | (120 << 8))); // RGB 70,120,0

	int zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
	char name[32];
	switch (zombieClass)
	{
		case 1: name = "Insta-Cap Smoker";
		case 2: name = "Insta-Cap Boomer";
		case 3: name = "Insta-Cap Hunter";
		case 4: name = "Insta-Cap Spitter";
		case 5: name = "Insta-Cap Jockey";
		case 6: name = "Insta-Cap Charger";
		default: name = "Insta-Capper";
	}
	SetClientInfo(client, "name", name);

	return Plugin_Stop;
}

// Aplica 600 de dano de fuego via point_hurt si el atacante es instacapper
void Inferno_InstaCapDamage(int attacker, int victim)
{
	if (attacker < 1 || attacker > MaxClients) return;
	if (!g_bIsInstaCapper_Inf[attacker]) return;
	if (victim < 1 || victim > MaxClients || !IsClientInGame(victim)) return;
	if (GetClientTeam(victim) != 2) return;
	if (GetEntProp(victim, Prop_Send, "m_isIncapacitated")) return;

	float pos[3];
	GetClientAbsOrigin(victim, pos);

	int hurt = CreateEntityByName("point_hurt");
	if (hurt < 1) return;

	DispatchKeyValue(hurt, "Damage", "600");
	DispatchKeyValue(hurt, "DamageType", "128"); // DMG_BURN
	DispatchKeyValue(hurt, "DamageDelay", "0.0");
	DispatchSpawn(hurt);
	TeleportEntity(hurt, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(hurt, "Hurt", victim);
	SetVariantString("OnUser1 !self:Kill::0.1:-1");
	AcceptEntityInput(hurt, "AddOutput");
	AcceptEntityInput(hurt, "FireUser1");
}

public void Inferno_Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bInfernoActive) return;
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim   = GetClientOfUserId(event.GetInt("victim"));
	Inferno_InstaCapDamage(attacker, victim);
}

public void Inferno_Event_LungePounce(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bInfernoActive) return;
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim   = GetClientOfUserId(event.GetInt("victim"));
	Inferno_InstaCapDamage(attacker, victim);
}

public void Inferno_Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bInfernoActive) return;
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim   = GetClientOfUserId(event.GetInt("victim"));
	Inferno_InstaCapDamage(attacker, victim);
}

public void Inferno_Event_ChargerPummel(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bInfernoActive) return;
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim   = GetClientOfUserId(event.GetInt("victim"));
	Inferno_InstaCapDamage(attacker, victim);
}

public void Inferno_Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bInfernoActive) return;
	int victim   = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	Inferno_InstaCapDamage(attacker, victim);
}

// =============================================================================
// METEOROS
// =============================================================================

// Distancia de una entidad al suelo (traza hacia abajo)
float Inferno_GetGroundDist(int entity)
{
	float pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	float endPos[3];
	endPos[0] = pos[0]; endPos[1] = pos[1]; endPos[2] = pos[2] - 600.0;
	TR_TraceRay(pos, endPos, MASK_SOLID_BRUSHONLY, RayType_EndPoint);
	if (!TR_DidHit()) return 600.0;
	float groundPos[3];
	TR_GetEndPosition(groundPos);
	return pos[2] - groundPos[2];
}

// Explosion de impacto: visual + dano AOE + push
void Inferno_ExplodeMeteor(int entity)
{
	if (entity < 1 || !IsValidEntity(entity)) return;
	float pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	pos[2] += 50.0;
	AcceptEntityInput(entity, "Kill");

	// Visual
	int expl = CreateEntityByName("env_explosion");
	if (expl > 0)
	{
		DispatchKeyValue(expl, "iMagnitude", "100");
		DispatchSpawn(expl);
		TeleportEntity(expl, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(expl, "Explode");
		SetVariantString("OnUser1 !self:Kill::0.1:-1");
		AcceptEntityInput(expl, "AddOutput");
		AcceptEntityInput(expl, "FireUser1");
	}

	// Dano AOE (tipo fuego)
	int hurt = CreateEntityByName("point_hurt");
	if (hurt > 0)
	{
		DispatchKeyValue(hurt, "Damage", "40");
		DispatchKeyValue(hurt, "DamageType", "128"); // DMG_BURN
		DispatchKeyValue(hurt, "DamageDelay", "0.0");
		DispatchKeyValueFloat(hurt, "DamageRadius", 200.0);
		DispatchSpawn(hurt);
		TeleportEntity(hurt, pos, NULL_VECTOR, NULL_VECTOR);
		int target = DiffBase_FindSurvivorTarget();
		if (target > 0) AcceptEntityInput(hurt, "Hurt", target);
		SetVariantString("OnUser1 !self:Kill::0.1:-1");
		AcceptEntityInput(hurt, "AddOutput");
		AcceptEntityInput(hurt, "FireUser1");
	}

	// Push fisico
	int push = CreateEntityByName("point_push");
	if (push > 0)
	{
		DispatchKeyValueFloat(push, "magnitude", 600.0);
		DispatchKeyValueFloat(push, "radius", 200.0);
		SetVariantString("spawnflags 24");
		AcceptEntityInput(push, "AddOutput");
		DispatchSpawn(push);
		TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(push, "Enable", -1, -1);
		SetVariantString("OnUser1 !self:Kill::0.5:-1");
		AcceptEntityInput(push, "AddOutput");
		AcceptEntityInput(push, "FireUser1");
	}
}

// Revisa rocks en el suelo y opcionalmente lanza uno nuevo
void Inferno_MeteorFall(bool launchNew)
{
	// Explotar tank_rocks que ya aterrizaron
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != INVALID_ENT_REFERENCE)
	{
		if (Inferno_GetGroundDist(entity) < 200.0)
			Inferno_ExplodeMeteor(entity);
	}

	if (!launchNew) return;

	int target = DiffBase_FindSurvivorTarget();
	if (target == -1) return;

	float eyePos[3];
	GetClientEyePosition(target, eyePos);

	// Posicion de spawn: encima del survivor con desvio horizontal aleatorio
	float spawnPos[3];
	spawnPos[0] = eyePos[0] + GetRandomFloat(-400.0, 400.0);
	spawnPos[1] = eyePos[1] + GetRandomFloat(-400.0, 400.0);
	spawnPos[2] = eyePos[2] + 800.0;

	int rock = CreateEntityByName("tank_rock");
	if (rock < 1) return;

	DispatchKeyValue(rock, "model", "models/props_debris/concrete_chunk01a.mdl");
	DispatchSpawn(rock);

	float ang[3];
	ang[0] = GetRandomFloat(-180.0, 180.0);
	ang[1] = GetRandomFloat(-180.0, 180.0);
	ang[2] = GetRandomFloat(-180.0, 180.0);

	float vel[3];
	vel[0] = GetRandomFloat(-100.0, 100.0);
	vel[1] = GetRandomFloat(-100.0, 100.0);
	vel[2] = -50.0;

	TeleportEntity(rock, spawnPos, ang, vel);
	ActivateEntity(rock);
	AcceptEntityInput(rock, "Ignite");

	// Kill de seguridad si no explota solo
	SetVariantString("OnUser1 !self:Kill::10.0:-1");
	AcceptEntityInput(rock, "AddOutput");
	AcceptEntityInput(rock, "FireUser1");
}

// =============================================================================
// API
// =============================================================================

public bool Inferno_IsActive() { return g_bInfernoActive; }
