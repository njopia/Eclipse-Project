#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === BLOODMOON MODE MODULE ===
// Primer nivel de dificultad. Overlay rojo, fog,
// dano aumentado, hordas mas grandes y eventos
// periodicos (tanks, panics, breeders).
//==================================================

// =============================================================================
// CONVARS
// =============================================================================

Handle g_cvar_Bloodmoon_Enable            = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_DmgMult           = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_Fade              = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ChangeDiff        = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_CommonLimit       = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_MobMin            = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_MobMax            = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_MegaMob           = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_LightStyle        = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_LightStyleRestore = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FogEnable         = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FogColor          = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FogStart          = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FogEnd            = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FogDensity        = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FogTick           = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ParticleName      = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ParticleCount     = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_SoundStart        = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_SoundLoop         = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FadeAlpha         = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FadeDuration      = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_DebugDamage       = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_TankSpawn         = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_TankInterval      = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_PanicEvents       = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_PanicInterval     = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_TonemapEnable     = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_BloomScale        = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ExposureMin       = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ExposureMax       = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_UsePrecipitation  = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_PrecipType        = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_BreederEvents     = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_BreederChance     = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_MegaMobSound      = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_MegaMobSoundChance = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ColorCorrection          = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ColorFile         = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ColorWeight       = INVALID_HANDLE;

// ConVars del juego
Handle g_zCVAR_CommonLimit_BM = INVALID_HANDLE;
Handle g_zCVAR_MobMin_BM      = INVALID_HANDLE;
Handle g_zCVAR_MobMax_BM      = INVALID_HANDLE;
Handle g_zCVAR_MegaMob_BM     = INVALID_HANDLE;
Handle g_zCVAR_Difficulty_BM  = INVALID_HANDLE;

// =============================================================================
// ESTADO
// =============================================================================

bool   g_bBloodmoonActive = false;
int    g_iFogRef_BM       = -1;
int    g_iCCRef_BM        = INVALID_ENT_REFERENCE;
Handle g_hFogTimer_BM     = null;
Handle g_hEventTimer_BM   = null;
int    g_iParticleRefs_BM[16];
int    g_iParticleTotal_BM  = 0;
int    g_iTonemapRef_BM         = -1;
int    g_iPrecipitationRef_BM   = -1;
int    g_iTankCount_BM      = 0;
float  g_fLastTankSpawn_BM  = 0.0;
float  g_fLastPanicEvent_BM = 0.0;
float  g_fMapStartTime_BM   = 0.0;

// Backup del director
int  g_iOrigCommonLimit_BM = -1;
int  g_iOrigMobMin_BM      = -1;
int  g_iOrigMobMax_BM      = -1;
int  g_iOrigMegaMob_BM     = -1;
char g_sOrigDifficulty_BM[16];

// =============================================================================
// INICIALIZACION
// =============================================================================

public void Bloodmoon_OnPluginStart()
{
	g_cvar_Bloodmoon_Enable      = CreateConVar("bloodmoon_enable",           "0",            "Habilita Bloodmoon",               FCVAR_PLUGIN);
	g_cvar_Bloodmoon_DmgMult     = CreateConVar("bloodmoon_damage_mult",      "1.35",         "Multiplicador de dano a Survivors", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_Fade        = CreateConVar("bloodmoon_fade",             "1",            "Overlay rojo persistente",         FCVAR_PLUGIN);
	g_cvar_Bloodmoon_ChangeDiff  = CreateConVar("bloodmoon_change_difficulty","1",            "Cambiar dificultad a Imposible",   FCVAR_PLUGIN);
	g_cvar_Bloodmoon_CommonLimit = CreateConVar("bloodmoon_common_limit",     "45",           "z_common_limit",                   FCVAR_PLUGIN);
	g_cvar_Bloodmoon_MobMin      = CreateConVar("bloodmoon_mob_min",          "25",           "z_mob_spawn_min_size",             FCVAR_PLUGIN);
	g_cvar_Bloodmoon_MobMax      = CreateConVar("bloodmoon_mob_max",          "35",           "z_mob_spawn_max_size",             FCVAR_PLUGIN);
	g_cvar_Bloodmoon_MegaMob     = CreateConVar("bloodmoon_mega_mob",         "60",           "z_mega_mob_size",                  FCVAR_PLUGIN);
	g_cvar_Bloodmoon_LightStyle  = CreateConVar("bloodmoon_lightstyle",       "b",            "LightStyle activo",                FCVAR_PLUGIN);
	g_cvar_Bloodmoon_LightStyleRestore = CreateConVar("bloodmoon_lightstyle_restore", "m",   "LightStyle a restaurar",           FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FogEnable   = CreateConVar("bloodmoon_fog_enable",       "1",            "Crear fog",                        FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FogColor    = CreateConVar("bloodmoon_fog_color",        "200 40 40",    "Color fog 'r g b'",                FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FogStart    = CreateConVar("bloodmoon_fog_start",        "50",           "Fog start distance",               FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FogEnd      = CreateConVar("bloodmoon_fog_end",          "1200",         "Fog end distance",                 FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FogDensity  = CreateConVar("bloodmoon_fog_density",      "0.7",          "Fog max density",                  FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FogTick     = CreateConVar("bloodmoon_fog_tick",         "3.0",          "Intervalo re-aplicar fog",         FCVAR_PLUGIN);
	g_cvar_Bloodmoon_ParticleName  = CreateConVar("bloodmoon_particle",       "env_snow_128", "Particula ambiental",              FCVAR_PLUGIN);
	g_cvar_Bloodmoon_ParticleCount = CreateConVar("bloodmoon_particle_count", "3",            "Cantidad de emisores",             FCVAR_PLUGIN);
	g_cvar_Bloodmoon_SoundStart  = CreateConVar("bloodmoon_sound_start",      "",             "Sonido al activar",                FCVAR_PLUGIN);
	g_cvar_Bloodmoon_SoundLoop   = CreateConVar("bloodmoon_sound_loop",       "",             "Sonido loop",                      FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FadeAlpha   = CreateConVar("bloodmoon_fade_alpha",       "120",          "Alpha overlay 0-255",              FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FadeDuration = CreateConVar("bloodmoon_fade_duration",   "1500",         "Duracion transicion ms",           FCVAR_PLUGIN);
	g_cvar_Bloodmoon_DebugDamage = CreateConVar("bloodmoon_debug_damage",     "0",            "Debug dano",                       FCVAR_PLUGIN);
	g_cvar_Bloodmoon_TankSpawn   = CreateConVar("bloodmoon_tank_spawn",       "1",            "Spawn automatico de tanks",        FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Bloodmoon_TankInterval = CreateConVar("bloodmoon_tank_interval",   "60.0",         "Intervalo spawn de tanks (s)",     FCVAR_PLUGIN, true, 0.0);
	g_cvar_Bloodmoon_PanicEvents = CreateConVar("bloodmoon_panic_events",     "1",            "Panic events periodicos",          FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Bloodmoon_PanicInterval = CreateConVar("bloodmoon_panic_interval", "45.0",         "Intervalo panic events (s)",       FCVAR_PLUGIN, true, 0.0);
	g_cvar_Bloodmoon_TonemapEnable = CreateConVar("bloodmoon_tonemap_enable",  "1",            "Tonemap (bloom/exposicion)",        FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Bloodmoon_BloomScale  = CreateConVar("bloodmoon_bloom_scale",      "2.5",          "Intensidad bloom",                 FCVAR_PLUGIN, true, 0.0);
	g_cvar_Bloodmoon_ExposureMin = CreateConVar("bloodmoon_exposure_min",     "0.7",          "Exposicion minima",                FCVAR_PLUGIN, true, 0.0);
	g_cvar_Bloodmoon_ExposureMax = CreateConVar("bloodmoon_exposure_max",     "1.8",          "Exposicion maxima",                FCVAR_PLUGIN, true, 0.0);
	g_cvar_Bloodmoon_UsePrecipitation = CreateConVar("bloodmoon_use_precipitation","1",       "Usar precipitacion en vez de particulas", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Bloodmoon_PrecipType  = CreateConVar("bloodmoon_precip_type",      "3",            "Tipo: 1=lluvia 2=ceniza 3=nieve 4=lluvia_l4d", FCVAR_PLUGIN, true, 1.0, true, 4.0);
	g_cvar_Bloodmoon_BreederEvents = CreateConVar("bloodmoon_breeder_events", "1",            "Spawn aleatorio de especiales extra", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Bloodmoon_BreederChance = CreateConVar("bloodmoon_breeder_chance", "25",           "Probabilidad 1/N breeder event",   FCVAR_PLUGIN, true, 1.0);
	g_cvar_Bloodmoon_MegaMobSound = CreateConVar("bloodmoon_megamob_sound",   "1",            "Sonido aleatorio mega mob",        FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Bloodmoon_MegaMobSoundChance = CreateConVar("bloodmoon_megamob_sound_chance","20", "Probabilidad 1/N sonido mega mob", FCVAR_PLUGIN, true, 1.0);
	g_cvar_Bloodmoon_ColorCorrection = CreateConVar("bloodmoon_color_correction", "1",                                           "Color correction activa",        FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Bloodmoon_ColorFile       = CreateConVar("bloodmoon_color_file",       "materials/correction/urban_night_red.pwl.raw","Archivo .pwl.raw de correccion", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_ColorWeight     = CreateConVar("bloodmoon_color_weight",     "0.45",                                        "Intensidad 0.0-1.0",             FCVAR_PLUGIN, true, 0.0, true, 1.0);

	g_zCVAR_CommonLimit_BM = FindConVar("z_common_limit");
	g_zCVAR_MobMin_BM      = FindConVar("z_mob_spawn_min_size");
	g_zCVAR_MobMax_BM      = FindConVar("z_mob_spawn_max_size");
	g_zCVAR_MegaMob_BM     = FindConVar("z_mega_mob_size");
	g_zCVAR_Difficulty_BM  = FindConVar("z_difficulty");

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, Bloodmoon_OnTakeDamage);

	HookEvent("player_death", BM_Event_PlayerDeath);
	HookEvent("tank_killed",  BM_Event_TankKilled);

	RegAdminCmd("sm_bloodmoon_on",     Cmd_BloodmoonOn,     ADMFLAG_GENERIC, "Activa Bloodmoon");
	RegAdminCmd("sm_bloodmoon_off",    Cmd_BloodmoonOff,    ADMFLAG_GENERIC, "Desactiva Bloodmoon");
	RegAdminCmd("sm_bloodmoon_toggle", Cmd_BloodmoonToggle, ADMFLAG_GENERIC, "Alterna Bloodmoon");
	RegAdminCmd("sm_bloodmoon_status", Cmd_BloodmoonStatus, ADMFLAG_GENERIC, "Estado Bloodmoon");
	RegAdminCmd("sm_bloodmoon_testmob",Cmd_BloodmoonTestMob,ADMFLAG_GENERIC, "Fuerza una horda");

	HookConVarChange(g_cvar_Bloodmoon_Enable, Bloodmoon_ConVarChanged);

	// Registrar con el orquestador (disponible porque se inicializo primero)
	DifficultyOrchestrator_Register(MODE_BLOODMOON, g_cvar_Bloodmoon_Enable);
}

public void Bloodmoon_OnMapStart()
{
	g_fMapStartTime_BM     = GetGameTime();
	g_iOrigCommonLimit_BM  = g_iOrigMobMin_BM = g_iOrigMobMax_BM = g_iOrigMegaMob_BM = -1;
	g_sOrigDifficulty_BM[0] = '\0';
	g_fLastTankSpawn_BM    = 0.0;
	g_fLastPanicEvent_BM   = 0.0;
	g_iTankCount_BM        = 0;
	g_iFogRef_BM           = -1;
	g_iCCRef_BM            = INVALID_ENT_REFERENCE;
	g_iTonemapRef_BM = g_iPrecipitationRef_BM = -1;
	for (int i = 0; i < 16; i++) g_iParticleRefs_BM[i] = -1;
	g_iParticleTotal_BM    = 0;

	PrecacheSound("npc/mega_mob/mega_mob_incoming.wav", true);

}

public void Bloodmoon_OnMapEnd()
{
	if (g_bBloodmoonActive)
		Bloodmoon_Deactivate("map_end");
}

public void Bloodmoon_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Bloodmoon_OnTakeDamage);
}

public void Bloodmoon_OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Bloodmoon_OnTakeDamage);
}

// =============================================================================
// CONVAR HOOK (activacion/desactivacion reactiva)
// =============================================================================

public void Bloodmoon_ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	bool bNew = view_as<bool>(StringToInt(newValue));
	bool bOld = view_as<bool>(StringToInt(oldValue));
	if (bNew == bOld) return;

	DiffBase_Debug("Bloodmoon", "ConVarChanged: %s -> %s", oldValue, newValue);

	if (bNew && !g_bBloodmoonActive)
		Bloodmoon_Activate("convar");
	else if (!bNew && g_bBloodmoonActive)
		Bloodmoon_Deactivate("convar");
}

// =============================================================================
// DAMAGE HOOK
// =============================================================================

public Action Bloodmoon_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	return DiffBase_ApplyDamageMult(victim, attacker, inflictor, damage,
		g_bBloodmoonActive,
		GetConVarFloat(g_cvar_Bloodmoon_DmgMult),
		GetConVarBool(g_cvar_Bloodmoon_DebugDamage),
		"Bloodmoon");
}

// =============================================================================
// EVENTOS
// =============================================================================

public void BM_Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bBloodmoonActive) return;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (victim > 0 && IsClientInGame(victim)
		&& GetClientTeam(victim) == 3
		&& GetEntProp(victim, Prop_Send, "m_zombieClass") == 8
		&& g_iTankCount_BM > 0)
		g_iTankCount_BM--;
}

public void BM_Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bBloodmoonActive) return;
	if (g_iTankCount_BM > 0) g_iTankCount_BM--;
}

// =============================================================================
// ACTIVACION
// =============================================================================

void Bloodmoon_Activate(const char[] reason = "manual")
{
	if (g_bBloodmoonActive) return;
	#pragma unused reason

	LogMessage("[Bloodmoon] Activating...");
	DiffBase_Debug("Bloodmoon", "Activate (razon: %s)", reason);

	DiffBase_BackupDirector(
		g_zCVAR_CommonLimit_BM, g_zCVAR_MobMin_BM, g_zCVAR_MobMax_BM,
		g_zCVAR_MegaMob_BM,     g_zCVAR_Difficulty_BM,
		g_iOrigCommonLimit_BM,  g_iOrigMobMin_BM,      g_iOrigMobMax_BM,
		g_iOrigMegaMob_BM,      g_sOrigDifficulty_BM,  sizeof(g_sOrigDifficulty_BM));

	DiffBase_ApplyDirector(
		g_zCVAR_CommonLimit_BM, g_zCVAR_MobMin_BM, g_zCVAR_MobMax_BM, g_zCVAR_MegaMob_BM,
		GetConVarInt(g_cvar_Bloodmoon_CommonLimit),
		GetConVarInt(g_cvar_Bloodmoon_MobMin),
		GetConVarInt(g_cvar_Bloodmoon_MobMax),
		GetConVarInt(g_cvar_Bloodmoon_MegaMob));

	g_bBloodmoonActive   = true;
	g_fLastTankSpawn_BM  = GetGameTime();
	g_fLastPanicEvent_BM = GetGameTime();
	g_iTankCount_BM      = 0;

	char ls[8];
	GetConVarString(g_cvar_Bloodmoon_LightStyle, ls, sizeof(ls));
	DiffBase_ApplyLightStyle(ls);

	if (GetConVarBool(g_cvar_Bloodmoon_TonemapEnable))
		DiffBase_CreateTonemapController(
			GetConVarFloat(g_cvar_Bloodmoon_BloomScale),
			GetConVarFloat(g_cvar_Bloodmoon_ExposureMin),
			GetConVarFloat(g_cvar_Bloodmoon_ExposureMax),
			g_iTonemapRef_BM);

	if (GetConVarBool(g_cvar_Bloodmoon_UsePrecipitation))
	{
		BM_CreatePrecipitation(GetConVarInt(g_cvar_Bloodmoon_PrecipType));
	}
	else
	{
		char pname[64];
		GetConVarString(g_cvar_Bloodmoon_ParticleName, pname, sizeof(pname));
		DiffBase_CreateAmbientParticles(pname,
			GetConVarInt(g_cvar_Bloodmoon_ParticleCount),
			g_iParticleRefs_BM, g_iParticleTotal_BM);
	}

	if (GetConVarBool(g_cvar_Bloodmoon_FogEnable))
	{
		char color[32];
		GetConVarString(g_cvar_Bloodmoon_FogColor, color, sizeof(color));
		int ent = DiffBase_SpawnFogController(color,
			GetConVarInt(g_cvar_Bloodmoon_FogStart),
			GetConVarInt(g_cvar_Bloodmoon_FogEnd),
			GetConVarFloat(g_cvar_Bloodmoon_FogDensity),
			g_iFogRef_BM);
		g_iFogRef_BM = (ent != -1) ? EntIndexToEntRef(ent) : -1;
		BM_StartFogTimer();
	}

	BM_StartEventTimer();

	char sStart[128], sLoop[128];
	GetConVarString(g_cvar_Bloodmoon_SoundStart, sStart, sizeof(sStart));
	GetConVarString(g_cvar_Bloodmoon_SoundLoop,  sLoop,  sizeof(sLoop));
	DiffBase_PlaySoundToAll(sStart);
	DiffBase_PlaySoundToAll(sLoop);

	if (GetConVarBool(g_cvar_Bloodmoon_Fade))
		DiffBase_DoScreenFadeAll(true, 120, 0, 0,
			GetConVarInt(g_cvar_Bloodmoon_FadeAlpha),
			GetConVarInt(g_cvar_Bloodmoon_FadeDuration));

	if (GetConVarBool(g_cvar_Bloodmoon_ChangeDiff))
		ServerCommand("z_difficulty Impossible");

	if (GetConVarBool(g_cvar_Bloodmoon_ColorCorrection))
	{
		char ccFile[PLATFORM_MAX_PATH];
		GetConVarString(g_cvar_Bloodmoon_ColorFile, ccFile, sizeof(ccFile));
		int fogVol = -1;
		DiffBase_CreateColorCorrection(ccFile, GetConVarFloat(g_cvar_Bloodmoon_ColorWeight), g_iCCRef_BM, fogVol, "bm_cc");
	}

	PrintToChatAll("\x04[Bloodmoon]\x01 Luna de Sangre ACTIVADA! (x%.2f dano)",
		GetConVarFloat(g_cvar_Bloodmoon_DmgMult));
}

// =============================================================================
// DESACTIVACION
// =============================================================================

void Bloodmoon_Deactivate(const char[] reason = "manual")
{
	if (!g_bBloodmoonActive) return;
	#pragma unused reason

	DiffBase_Debug("Bloodmoon", "Deactivate (razon: %s)", reason);
	g_bBloodmoonActive  = false;
	g_iTankCount_BM     = 0;
	g_fLastTankSpawn_BM = g_fLastPanicEvent_BM = 0.0;

	DiffBase_RestoreDirector(
		g_zCVAR_CommonLimit_BM, g_zCVAR_MobMin_BM, g_zCVAR_MobMax_BM,
		g_zCVAR_MegaMob_BM,     g_zCVAR_Difficulty_BM,
		g_iOrigCommonLimit_BM,  g_iOrigMobMin_BM,      g_iOrigMobMax_BM,
		g_iOrigMegaMob_BM,      g_sOrigDifficulty_BM);

	BM_StopEventTimer();

	DiffBase_RemoveTonemapController(g_iTonemapRef_BM);
	BM_RemovePrecipitation();
	DiffBase_RemoveAmbientParticles(g_iParticleRefs_BM, g_iParticleTotal_BM);
	int fogVolBM = -1;
	DiffBase_RemoveColorCorrection(g_iCCRef_BM, fogVolBM);

	BM_StopFogTimer();
	DiffBase_RemoveFogController(g_iFogRef_BM);

	char ls[8];
	GetConVarString(g_cvar_Bloodmoon_LightStyleRestore, ls, sizeof(ls));
	DiffBase_ApplyLightStyle(ls);

	char sLoop[128];
	GetConVarString(g_cvar_Bloodmoon_SoundLoop, sLoop, sizeof(sLoop));
	DiffBase_StopSoundToAll(sLoop);

	if (GetConVarBool(g_cvar_Bloodmoon_ChangeDiff) && g_sOrigDifficulty_BM[0] != '\0')
		ServerCommand("z_difficulty %s", g_sOrigDifficulty_BM);

	if (GetConVarBool(g_cvar_Bloodmoon_Fade))
		DiffBase_DoScreenFadeAll(false, 120, 0, 0,
			GetConVarInt(g_cvar_Bloodmoon_FadeAlpha),
			GetConVarInt(g_cvar_Bloodmoon_FadeDuration));

	PrintToChatAll("\x04[Bloodmoon]\x01 Luna de Sangre DESACTIVADA.");
}

// =============================================================================
// FOG TIMER
// =============================================================================

void BM_StartFogTimer()
{
	if (g_hFogTimer_BM != null) return;
	float tick = GetConVarFloat(g_cvar_Bloodmoon_FogTick);
	if (tick < 1.0) tick = 1.0;
	g_hFogTimer_BM = CreateTimer(tick, BM_Timer_FogEnforcer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void BM_StopFogTimer()
{
	if (g_hFogTimer_BM != null) { KillTimer(g_hFogTimer_BM); g_hFogTimer_BM = null; }
}

public Action BM_Timer_FogEnforcer(Handle timer)
{
	if (!g_bBloodmoonActive || !GetConVarBool(g_cvar_Bloodmoon_FogEnable))
		return Plugin_Continue;

	char color[32];
	GetConVarString(g_cvar_Bloodmoon_FogColor, color, sizeof(color));
	DiffBase_EnsureFogController(g_iFogRef_BM, color,
		GetConVarInt(g_cvar_Bloodmoon_FogStart),
		GetConVarInt(g_cvar_Bloodmoon_FogEnd),
		GetConVarFloat(g_cvar_Bloodmoon_FogDensity));

	if (GetConVarBool(g_cvar_Bloodmoon_ColorCorrection))
	{
		char ccFile[PLATFORM_MAX_PATH];
		GetConVarString(g_cvar_Bloodmoon_ColorFile, ccFile, sizeof(ccFile));
		DiffBase_EnsureColorCorrection(g_iCCRef_BM, ccFile, GetConVarFloat(g_cvar_Bloodmoon_ColorWeight), "bm_cc");
	}

	return Plugin_Continue;
}

// =============================================================================
// EVENT TIMER (tanks, panics, breeders, mega mob sound)
// =============================================================================

void BM_StartEventTimer()
{
	if (g_hEventTimer_BM != null) return;
	g_hEventTimer_BM = CreateTimer(5.0, BM_Timer_Events, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void BM_StopEventTimer()
{
	if (g_hEventTimer_BM != null) { KillTimer(g_hEventTimer_BM); g_hEventTimer_BM = null; }
}

public Action BM_Timer_Events(Handle timer)
{
	if (!g_bBloodmoonActive) return Plugin_Continue;

	float now = GetGameTime();
	if (now - g_fMapStartTime_BM < 10.0) return Plugin_Continue;

	// 1. Tank spawn
	if (GetConVarBool(g_cvar_Bloodmoon_TankSpawn))
	{
		float interval = GetConVarFloat(g_cvar_Bloodmoon_TankInterval);
		if (interval > 0.0 && (now - g_fLastTankSpawn_BM) >= interval)
		{
			if (g_iTankCount_BM < 1 && !DiffBase_IsFinaleActive())
			{
				BM_SpawnTank();
				g_fLastTankSpawn_BM = now;
			}
		}
	}

	// 2. Panic event
	if (GetConVarBool(g_cvar_Bloodmoon_PanicEvents))
	{
		float interval = GetConVarFloat(g_cvar_Bloodmoon_PanicInterval);
		if (interval > 0.0 && (now - g_fLastPanicEvent_BM) >= interval)
		{
			BM_ForcePanicEvent();
			g_fLastPanicEvent_BM = now;
		}
	}

	// 3. Breeder event
	if (GetConVarBool(g_cvar_Bloodmoon_BreederEvents))
	{
		int chance = GetConVarInt(g_cvar_Bloodmoon_BreederChance);
		if (chance > 0 && GetRandomInt(1, chance) == 1)
			BM_CreateBreederEvent();
	}

	// 4. Mega mob sound
	if (GetConVarBool(g_cvar_Bloodmoon_MegaMobSound))
	{
		int chance = GetConVarInt(g_cvar_Bloodmoon_MegaMobSoundChance);
		if (chance > 0 && GetRandomInt(1, chance) == 1)
			EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN);
	}

	return Plugin_Continue;
}

// =============================================================================
// SPAWNING DE TANKS Y ESPECIALES
// =============================================================================

void BM_SpawnTank()
{
	int target = DiffBase_FindSurvivorTarget();
	if (target == -1) return;

	float pos[3], ang[3];
	if (!L4D_GetRandomPZSpawnPosition(target, view_as<int>(L4D2ZombieClass_Tank), 10, pos))
		return;

	GetClientAbsAngles(target, ang);
	int tank = L4D2_SpawnTank(pos, ang);
	if (tank > 0) g_iTankCount_BM++;
}

void BM_ForcePanicEvent()
{
	L4D_ForcePanicEvent();
}

void BM_CreateBreederEvent()
{
	int target = DiffBase_FindSurvivorTarget();
	if (target == -1) return;

	float ang[3];
	GetClientAbsAngles(target, ang);
	for (int n = 0; n < 2; n++)
	{
		int zombieClass = GetRandomInt(1, 6);
		float pos[3];
		if (!L4D_GetRandomPZSpawnPosition(target, zombieClass, 10, pos))
			continue;
		L4D2_SpawnSpecial(zombieClass, pos, ang);
	}
}

// =============================================================================
// PRECIPITACION
// =============================================================================

void BM_CreatePrecipitation(int precipType)
{
	int entity = CreateEntityByName("func_precipitation");
	if (entity == -1) return;

	char mapName[PLATFORM_MAX_PATH], mapPath[PLATFORM_MAX_PATH];
	GetCurrentMap(mapName, sizeof(mapName));
	Format(mapPath, sizeof(mapPath), "maps/%s.bsp", mapName);
	PrecacheModel(mapPath, true);

	DispatchKeyValue(entity, "model", mapPath);

	char sType[4];
	IntToString(precipType, sType, sizeof(sType));
	DispatchKeyValue(entity, "preciptype", sType);

	float vMins[3], vMaxs[3], vOrigin[3];
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
	GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);
	SetEntPropVector(entity, Prop_Send, "m_vecMins", vMins);
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vMaxs);
	vOrigin[0] = (vMins[0] + vMaxs[0]) / 2.0;
	vOrigin[1] = (vMins[1] + vMaxs[1]) / 2.0;
	vOrigin[2] = (vMins[2] + vMaxs[2]) / 2.0;

	DispatchSpawn(entity);
	ActivateEntity(entity);
	TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);

	g_iPrecipitationRef_BM = EntIndexToEntRef(entity);
}

void BM_RemovePrecipitation()
{
	int ent = EntRefToEntIndex(g_iPrecipitationRef_BM);
	if (ent != -1 && IsValidEntity(ent)) RemoveEntity(ent);
	g_iPrecipitationRef_BM = -1;
}

// =============================================================================
// COMANDOS ADMIN
// =============================================================================

public Action Cmd_BloodmoonOn(int client, int args)
{
	if (!GetConVarBool(g_cvar_Bloodmoon_Enable))
		{ ReplyToCommand(client, "[Bloodmoon] Sistema deshabilitado"); return Plugin_Handled; }
	Bloodmoon_Activate("admin");
	ReplyToCommand(client, "[Bloodmoon] ACTIVADO");
	return Plugin_Handled;
}

public Action Cmd_BloodmoonOff(int client, int args)
{
	Bloodmoon_Deactivate("admin");
	ReplyToCommand(client, "[Bloodmoon] DESACTIVADO");
	return Plugin_Handled;
}

public Action Cmd_BloodmoonToggle(int client, int args)
{
	return g_bBloodmoonActive ? Cmd_BloodmoonOff(client, args) : Cmd_BloodmoonOn(client, args);
}

public Action Cmd_BloodmoonStatus(int client, int args)
{
	char diff[16];
	if (g_zCVAR_Difficulty_BM) GetConVarString(g_zCVAR_Difficulty_BM, diff, sizeof(diff));
	ReplyToCommand(client, "[Bloodmoon] Activo: %s | Mult: %.2f | Dif: %s | Tanks: %d",
		g_bBloodmoonActive ? "SI" : "NO",
		GetConVarFloat(g_cvar_Bloodmoon_DmgMult),
		diff[0] ? diff : "n/a",
		g_iTankCount_BM);
	return Plugin_Handled;
}

public Action Cmd_BloodmoonTestMob(int client, int args)
{
	ServerCommand("z_spawn mob");
	ReplyToCommand(client, "[Bloodmoon] Horda forzada");
	return Plugin_Handled;
}

// =============================================================================
// API
// =============================================================================

public bool Bloodmoon_IsActive() { return g_bBloodmoonActive; }
