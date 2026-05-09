#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === HELL MODE MODULE ===
// Segundo nivel de dificultad. Overlay naranja-rojo,
// fog de fuego, dano x1.5 y hordas mas agresivas.
//==================================================

// =============================================================================
// CONVARS
// =============================================================================

Handle g_cvar_Hell_Enable            = INVALID_HANDLE;
Handle g_cvar_Hell_DmgMult           = INVALID_HANDLE;
Handle g_cvar_Hell_Fade              = INVALID_HANDLE;
Handle g_cvar_Hell_ChangeDiff        = INVALID_HANDLE;
Handle g_cvar_Hell_CommonLimit       = INVALID_HANDLE;
Handle g_cvar_Hell_MobMin            = INVALID_HANDLE;
Handle g_cvar_Hell_MobMax            = INVALID_HANDLE;
Handle g_cvar_Hell_MegaMob           = INVALID_HANDLE;
Handle g_cvar_Hell_LightStyle        = INVALID_HANDLE;
Handle g_cvar_Hell_LightStyleRestore = INVALID_HANDLE;
Handle g_cvar_Hell_FogEnable         = INVALID_HANDLE;
Handle g_cvar_Hell_FogColor          = INVALID_HANDLE;
Handle g_cvar_Hell_FogStart          = INVALID_HANDLE;
Handle g_cvar_Hell_FogEnd            = INVALID_HANDLE;
Handle g_cvar_Hell_FogDensity        = INVALID_HANDLE;
Handle g_cvar_Hell_FogTick           = INVALID_HANDLE;
Handle g_cvar_Hell_ParticleName      = INVALID_HANDLE;
Handle g_cvar_Hell_ParticleCount     = INVALID_HANDLE;
Handle g_cvar_Hell_SoundStart        = INVALID_HANDLE;
Handle g_cvar_Hell_SoundLoop         = INVALID_HANDLE;
Handle g_cvar_Hell_FadeAlpha         = INVALID_HANDLE;
Handle g_cvar_Hell_FadeDuration      = INVALID_HANDLE;
Handle g_cvar_Hell_DebugDamage           = INVALID_HANDLE;
Handle g_cvar_Hell_TankSpawn             = INVALID_HANDLE;
Handle g_cvar_Hell_TankInterval          = INVALID_HANDLE;
Handle g_cvar_Hell_PanicEvents           = INVALID_HANDLE;
Handle g_cvar_Hell_PanicInterval         = INVALID_HANDLE;
Handle g_cvar_Hell_WitchEnable           = INVALID_HANDLE;
Handle g_cvar_Hell_WitchMax              = INVALID_HANDLE;
Handle g_cvar_Hell_WitchRecycleDist      = INVALID_HANDLE;
Handle g_cvar_Hell_MegaMobSound          = INVALID_HANDLE;
Handle g_cvar_Hell_MegaMobSoundChance    = INVALID_HANDLE;
Handle g_cvar_Hell_TonemapEnable         = INVALID_HANDLE;
Handle g_cvar_Hell_BloomScale            = INVALID_HANDLE;
Handle g_cvar_Hell_ExposureMin           = INVALID_HANDLE;
Handle g_cvar_Hell_ExposureMax           = INVALID_HANDLE;
Handle g_cvar_Hell_ColorCorrection       = INVALID_HANDLE;
Handle g_cvar_Hell_ColorFile             = INVALID_HANDLE;
Handle g_cvar_Hell_ColorWeight           = INVALID_HANDLE;

// ConVars del juego
Handle g_zCVAR_CommonLimit_Hell = INVALID_HANDLE;
Handle g_zCVAR_MobMin_Hell      = INVALID_HANDLE;
Handle g_zCVAR_MobMax_Hell      = INVALID_HANDLE;
Handle g_zCVAR_MegaMob_Hell     = INVALID_HANDLE;
Handle g_zCVAR_Difficulty_Hell  = INVALID_HANDLE;

// =============================================================================
// ESTADO
// =============================================================================

bool   g_bHellActive      = false;
int    g_iFogRef_Hell     = -1;
int    g_iCCRef_Hell      = INVALID_ENT_REFERENCE;
Handle g_hFogTimer_Hell   = null;
int    g_iParticleRefs_Hell[16];
int    g_iParticleTotal_Hell = 0;

int  g_iOrigCommonLimit_Hell = -1;
int  g_iOrigMobMin_Hell      = -1;
int  g_iOrigMobMax_Hell      = -1;
int  g_iOrigMegaMob_Hell     = -1;
char g_sOrigDifficulty_Hell[16];

Handle g_hEventTimer_Hell    = null;
int    g_iTankCount_Hell     = 0;
float  g_fLastTankSpawn_Hell = 0.0;
float  g_fLastPanic_Hell     = 0.0;
float  g_fMapStart_Hell      = 0.0;
int    g_iTonemapRef_Hell    = -1;

// =============================================================================
// INICIALIZACION
// =============================================================================

public void Hell_OnPluginStart()
{
	g_cvar_Hell_Enable      = CreateConVar("hell_enable",           "0",          "Habilita Hell Mode",               FCVAR_PLUGIN);
	g_cvar_Hell_DmgMult     = CreateConVar("hell_damage_mult",      "1.5",        "Multiplicador de dano a Survivors", FCVAR_PLUGIN);
	g_cvar_Hell_Fade        = CreateConVar("hell_fade",             "1",          "Overlay naranja-rojo persistente", FCVAR_PLUGIN);
	g_cvar_Hell_ChangeDiff  = CreateConVar("hell_change_difficulty","1",          "Cambiar dificultad a Imposible",   FCVAR_PLUGIN);
	g_cvar_Hell_CommonLimit = CreateConVar("hell_common_limit",     "50",         "z_common_limit",                   FCVAR_PLUGIN);
	g_cvar_Hell_MobMin      = CreateConVar("hell_mob_min",          "30",         "z_mob_spawn_min_size",             FCVAR_PLUGIN);
	g_cvar_Hell_MobMax      = CreateConVar("hell_mob_max",          "40",         "z_mob_spawn_max_size",             FCVAR_PLUGIN);
	g_cvar_Hell_MegaMob     = CreateConVar("hell_mega_mob",         "70",         "z_mega_mob_size",                  FCVAR_PLUGIN);
	g_cvar_Hell_LightStyle  = CreateConVar("hell_lightstyle",       "a",          "LightStyle activo",                FCVAR_PLUGIN);
	g_cvar_Hell_LightStyleRestore = CreateConVar("hell_lightstyle_restore","m",   "LightStyle a restaurar",           FCVAR_PLUGIN);
	g_cvar_Hell_FogEnable   = CreateConVar("hell_fog_enable",       "1",          "Crear fog",                        FCVAR_PLUGIN);
	g_cvar_Hell_FogColor    = CreateConVar("hell_fog_color",        "255 80 20",  "Color fog 'r g b'",                FCVAR_PLUGIN);
	g_cvar_Hell_FogStart    = CreateConVar("hell_fog_start",        "40",         "Fog start distance",               FCVAR_PLUGIN);
	g_cvar_Hell_FogEnd      = CreateConVar("hell_fog_end",          "1000",       "Fog end distance",                 FCVAR_PLUGIN);
	g_cvar_Hell_FogDensity  = CreateConVar("hell_fog_density",      "0.75",       "Fog max density",                  FCVAR_PLUGIN);
	g_cvar_Hell_FogTick     = CreateConVar("hell_fog_tick",         "3.0",        "Intervalo re-aplicar fog",         FCVAR_PLUGIN);
	g_cvar_Hell_ParticleName  = CreateConVar("hell_particle",       "env_fire_small_smoke", "Particula ambiental",   FCVAR_PLUGIN);
	g_cvar_Hell_ParticleCount = CreateConVar("hell_particle_count", "4",          "Cantidad de emisores",             FCVAR_PLUGIN);
	g_cvar_Hell_SoundStart  = CreateConVar("hell_sound_start",      "",           "Sonido al activar",                FCVAR_PLUGIN);
	g_cvar_Hell_SoundLoop   = CreateConVar("hell_sound_loop",       "",           "Sonido loop",                      FCVAR_PLUGIN);
	g_cvar_Hell_FadeAlpha   = CreateConVar("hell_fade_alpha",       "100",        "Alpha overlay 0-255",              FCVAR_PLUGIN);
	g_cvar_Hell_FadeDuration = CreateConVar("hell_fade_duration",   "1500",       "Duracion transicion ms",           FCVAR_PLUGIN);
	g_cvar_Hell_DebugDamage           = CreateConVar("hell_debug_damage",           "0",    "Debug dano",                       FCVAR_PLUGIN);
	g_cvar_Hell_TankSpawn             = CreateConVar("hell_tank_spawn",             "1",    "Spawn automatico de tanks",          FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Hell_TankInterval          = CreateConVar("hell_tank_interval",          "60.0", "Intervalo spawn de tanks (s)",       FCVAR_PLUGIN, true, 0.0);
	g_cvar_Hell_PanicEvents           = CreateConVar("hell_panic_events",           "1",    "Panic events periodicos",            FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Hell_PanicInterval         = CreateConVar("hell_panic_interval",         "45.0", "Intervalo panic events (s)",         FCVAR_PLUGIN, true, 0.0);
	g_cvar_Hell_WitchEnable           = CreateConVar("hell_witch_enable",           "1",    "Sistema de witches activo",          FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Hell_WitchMax              = CreateConVar("hell_witch_max",              "33",   "Max witches simultaneas",            FCVAR_PLUGIN, true, 1.0);
	g_cvar_Hell_WitchRecycleDist      = CreateConVar("hell_witch_recycle_dist",     "1000", "Distancia (u) para reciclar witches",FCVAR_PLUGIN, true, 0.0);
	g_cvar_Hell_MegaMobSound          = CreateConVar("hell_megamob_sound",          "1",    "Sonido aleatorio mega mob",          FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Hell_MegaMobSoundChance    = CreateConVar("hell_megamob_sound_chance",   "20",   "Probabilidad 1/N sonido mega mob",   FCVAR_PLUGIN, true, 1.0);
	g_cvar_Hell_TonemapEnable         = CreateConVar("hell_tonemap_enable",         "1",    "Tonemap (bloom/exposicion)",          FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Hell_BloomScale            = CreateConVar("hell_bloom_scale",            "4.0",  "Intensidad bloom",                   FCVAR_PLUGIN, true, 0.0);
	g_cvar_Hell_ExposureMin           = CreateConVar("hell_exposure_min",           "0.3",  "Exposicion minima",                  FCVAR_PLUGIN, true, 0.0);
	g_cvar_Hell_ExposureMax           = CreateConVar("hell_exposure_max",           "0.7",  "Exposicion maxima",                  FCVAR_PLUGIN, true, 0.0);
	g_cvar_Hell_ColorCorrection = CreateConVar("hell_color_correction", "1",                                           "Color correction activa",        FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Hell_ColorFile       = CreateConVar("hell_color_file",       "materials/correction/urban_night_red.pwl.raw","Archivo .pwl.raw de correccion", FCVAR_PLUGIN);
	g_cvar_Hell_ColorWeight     = CreateConVar("hell_color_weight",     "0.65",                                        "Intensidad 0.0-1.0",             FCVAR_PLUGIN, true, 0.0, true, 1.0);

	g_zCVAR_CommonLimit_Hell = FindConVar("z_common_limit");
	g_zCVAR_MobMin_Hell      = FindConVar("z_mob_spawn_min_size");
	g_zCVAR_MobMax_Hell      = FindConVar("z_mob_spawn_max_size");
	g_zCVAR_MegaMob_Hell     = FindConVar("z_mega_mob_size");
	g_zCVAR_Difficulty_Hell  = FindConVar("z_difficulty");

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, Hell_OnTakeDamage);

	HookEvent("player_death", Hell_Event_PlayerDeath);
	HookEvent("tank_killed",  Hell_Event_TankKilled);

	RegAdminCmd("sm_hell_on",     Cmd_HellOn,     ADMFLAG_GENERIC, "Activa Hell Mode");
	RegAdminCmd("sm_hell_off",    Cmd_HellOff,    ADMFLAG_GENERIC, "Desactiva Hell Mode");
	RegAdminCmd("sm_hell_toggle", Cmd_HellToggle, ADMFLAG_GENERIC, "Alterna Hell Mode");
	RegAdminCmd("sm_hell_status", Cmd_HellStatus, ADMFLAG_GENERIC, "Estado Hell Mode");

	HookConVarChange(g_cvar_Hell_Enable, Hell_ConVarChanged);

	DifficultyOrchestrator_Register(MODE_HELL, g_cvar_Hell_Enable);
}

public void Hell_OnMapStart()
{
	g_iOrigCommonLimit_Hell = g_iOrigMobMin_Hell = g_iOrigMobMax_Hell = g_iOrigMegaMob_Hell = -1;
	g_sOrigDifficulty_Hell[0] = '\0';
	g_iFogRef_Hell = -1;
	g_iCCRef_Hell  = INVALID_ENT_REFERENCE;
	for (int i = 0; i < 16; i++) g_iParticleRefs_Hell[i] = -1;
	g_iParticleTotal_Hell = 0;
	g_fMapStart_Hell      = GetGameTime();
	g_iTankCount_Hell     = 0;
	g_fLastTankSpawn_Hell = g_fLastPanic_Hell = 0.0;
	g_iTonemapRef_Hell    = -1;
	PrecacheSound("npc/mega_mob/mega_mob_incoming.wav", true);
}

public void Hell_OnMapEnd()
{
	if (g_bHellActive) Hell_Deactivate("map_end");
}

public void Hell_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hell_OnTakeDamage);

	if (g_bHellActive && GetConVarBool(g_cvar_Hell_Fade))
		CreateTimer(2.0, Hell_Timer_FadeNewPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void Hell_OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Hell_OnTakeDamage);
}

// =============================================================================
// CONVAR HOOK
// =============================================================================

public void Hell_ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	bool bNew = view_as<bool>(StringToInt(newValue));
	bool bOld = view_as<bool>(StringToInt(oldValue));
	if (bNew == bOld) return;

	DiffBase_Debug("Hell", "ConVarChanged: %s -> %s", oldValue, newValue);

	if (bNew && !g_bHellActive)
		Hell_Activate("convar");
	else if (!bNew && g_bHellActive)
		Hell_Deactivate("convar");
}

// =============================================================================
// DAMAGE HOOK
// =============================================================================

public Action Hell_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	return DiffBase_ApplyDamageMult(victim, attacker, inflictor, damage,
		g_bHellActive,
		GetConVarFloat(g_cvar_Hell_DmgMult),
		GetConVarBool(g_cvar_Hell_DebugDamage),
		"Hell");
}

// =============================================================================
// ACTIVACION
// =============================================================================

void Hell_Activate(const char[] reason = "manual")
{
	if (g_bHellActive) return;
	#pragma unused reason

	DiffBase_Debug("Hell", "Activate (razon: %s)", reason);
	DiffBase_BackupDirector(
		g_zCVAR_CommonLimit_Hell, g_zCVAR_MobMin_Hell, g_zCVAR_MobMax_Hell,
		g_zCVAR_MegaMob_Hell,     g_zCVAR_Difficulty_Hell,
		g_iOrigCommonLimit_Hell,  g_iOrigMobMin_Hell,      g_iOrigMobMax_Hell,
		g_iOrigMegaMob_Hell,      g_sOrigDifficulty_Hell,  sizeof(g_sOrigDifficulty_Hell));

	DiffBase_ApplyDirector(
		g_zCVAR_CommonLimit_Hell, g_zCVAR_MobMin_Hell, g_zCVAR_MobMax_Hell, g_zCVAR_MegaMob_Hell,
		GetConVarInt(g_cvar_Hell_CommonLimit),
		GetConVarInt(g_cvar_Hell_MobMin),
		GetConVarInt(g_cvar_Hell_MobMax),
		GetConVarInt(g_cvar_Hell_MegaMob));

	g_bHellActive         = true;
	g_iTankCount_Hell     = 0;
	g_fLastTankSpawn_Hell = g_fLastPanic_Hell = GetGameTime();
	Hell_StartEventTimer();

	char ls[8];
	GetConVarString(g_cvar_Hell_LightStyle, ls, sizeof(ls));
	DiffBase_ApplyLightStyle(ls);

	if (GetConVarBool(g_cvar_Hell_TonemapEnable))
		DiffBase_CreateTonemapController(
			GetConVarFloat(g_cvar_Hell_BloomScale),
			GetConVarFloat(g_cvar_Hell_ExposureMin),
			GetConVarFloat(g_cvar_Hell_ExposureMax),
			g_iTonemapRef_Hell);

	if (GetConVarBool(g_cvar_Hell_FogEnable))
	{
		char color[32];
		GetConVarString(g_cvar_Hell_FogColor, color, sizeof(color));
		int ent = DiffBase_SpawnFogController(color,
			GetConVarInt(g_cvar_Hell_FogStart),
			GetConVarInt(g_cvar_Hell_FogEnd),
			GetConVarFloat(g_cvar_Hell_FogDensity),
			g_iFogRef_Hell);
		g_iFogRef_Hell = (ent != -1) ? EntIndexToEntRef(ent) : -1;
		Hell_StartFogTimer();
	}

	char pname[64];
	GetConVarString(g_cvar_Hell_ParticleName, pname, sizeof(pname));
	DiffBase_CreateAmbientParticles(pname,
		GetConVarInt(g_cvar_Hell_ParticleCount),
		g_iParticleRefs_Hell, g_iParticleTotal_Hell);

	char sStart[128], sLoop[128];
	GetConVarString(g_cvar_Hell_SoundStart, sStart, sizeof(sStart));
	GetConVarString(g_cvar_Hell_SoundLoop,  sLoop,  sizeof(sLoop));
	DiffBase_PlaySoundToAll(sStart);
	DiffBase_PlaySoundToAll(sLoop);

	DiffBase_DoScreenFadeAll(true, 255, 80, 20,
		GetConVarInt(g_cvar_Hell_FadeAlpha),
		GetConVarInt(g_cvar_Hell_FadeDuration));

	if (GetConVarBool(g_cvar_Hell_ChangeDiff))
		ServerCommand("z_difficulty Impossible");

	if (GetConVarBool(g_cvar_Hell_ColorCorrection))
	{
		char ccFile[PLATFORM_MAX_PATH];
		GetConVarString(g_cvar_Hell_ColorFile, ccFile, sizeof(ccFile));
		int fogVol = -1;
		DiffBase_CreateColorCorrection(ccFile, GetConVarFloat(g_cvar_Hell_ColorWeight), g_iCCRef_Hell, fogVol, "hell_cc");
	}

	PrintToChatAll("\x04[Hell]\x01 Modo Infierno ACTIVADO! Las llamas te consumiran (x%.2f dano)",
		GetConVarFloat(g_cvar_Hell_DmgMult));
}

// =============================================================================
// DESACTIVACION
// =============================================================================

void Hell_Deactivate(const char[] reason = "manual")
{
	if (!g_bHellActive) return;
	#pragma unused reason

	DiffBase_Debug("Hell", "Deactivate (razon: %s)", reason);
	g_bHellActive     = false;
	g_iTankCount_Hell = 0;
	Hell_StopEventTimer();

	DiffBase_RestoreDirector(
		g_zCVAR_CommonLimit_Hell, g_zCVAR_MobMin_Hell, g_zCVAR_MobMax_Hell,
		g_zCVAR_MegaMob_Hell,     g_zCVAR_Difficulty_Hell,
		g_iOrigCommonLimit_Hell,  g_iOrigMobMin_Hell,      g_iOrigMobMax_Hell,
		g_iOrigMegaMob_Hell,      g_sOrigDifficulty_Hell);

	DiffBase_RemoveTonemapController(g_iTonemapRef_Hell);
	DiffBase_RemoveAmbientParticles(g_iParticleRefs_Hell, g_iParticleTotal_Hell);
	int fogVolHell = -1;
	DiffBase_RemoveColorCorrection(g_iCCRef_Hell, fogVolHell);
	Hell_StopFogTimer();
	DiffBase_RemoveFogController(g_iFogRef_Hell);

	char ls[8];
	GetConVarString(g_cvar_Hell_LightStyleRestore, ls, sizeof(ls));
	DiffBase_ApplyLightStyle(ls);

	char sLoop[128];
	GetConVarString(g_cvar_Hell_SoundLoop, sLoop, sizeof(sLoop));
	DiffBase_StopSoundToAll(sLoop);

	if (GetConVarBool(g_cvar_Hell_ChangeDiff) && g_sOrigDifficulty_Hell[0] != '\0')
		ServerCommand("z_difficulty %s", g_sOrigDifficulty_Hell);

	DiffBase_DoScreenFadeAll(false, 255, 80, 20,
		GetConVarInt(g_cvar_Hell_FadeAlpha),
		GetConVarInt(g_cvar_Hell_FadeDuration));

	PrintToChatAll("\x04[Hell]\x01 Modo Infierno DESACTIVADO.");
}

// =============================================================================
// FOG TIMER
// =============================================================================

void Hell_StartFogTimer()
{
	if (g_hFogTimer_Hell != null) return;
	float tick = GetConVarFloat(g_cvar_Hell_FogTick);
	if (tick < 1.0) tick = 1.0;
	g_hFogTimer_Hell = CreateTimer(tick, Hell_Timer_FogEnforcer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void Hell_StopFogTimer()
{
	if (g_hFogTimer_Hell != null) { KillTimer(g_hFogTimer_Hell); g_hFogTimer_Hell = null; }
}

public Action Hell_Timer_FogEnforcer(Handle timer)
{
	if (!g_bHellActive || !GetConVarBool(g_cvar_Hell_FogEnable))
		return Plugin_Continue;

	char color[32];
	GetConVarString(g_cvar_Hell_FogColor, color, sizeof(color));
	DiffBase_EnsureFogController(g_iFogRef_Hell, color,
		GetConVarInt(g_cvar_Hell_FogStart),
		GetConVarInt(g_cvar_Hell_FogEnd),
		GetConVarFloat(g_cvar_Hell_FogDensity));

	if (GetConVarBool(g_cvar_Hell_ColorCorrection))
	{
		char ccFile[PLATFORM_MAX_PATH];
		GetConVarString(g_cvar_Hell_ColorFile, ccFile, sizeof(ccFile));
		DiffBase_EnsureColorCorrection(g_iCCRef_Hell, ccFile, GetConVarFloat(g_cvar_Hell_ColorWeight), "hell_cc");
	}

	return Plugin_Continue;
}

// =============================================================================
// FADE PARA NUEVOS JUGADORES
// =============================================================================

public Action Hell_Timer_FadeNewPlayer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client)) return Plugin_Stop;
	if (!g_bHellActive || !GetConVarBool(g_cvar_Hell_Fade)) return Plugin_Stop;

	DiffBase_ApplyFadeToClient(client, 255, 80, 20,
		GetConVarInt(g_cvar_Hell_FadeAlpha),
		GetConVarInt(g_cvar_Hell_FadeDuration));

	return Plugin_Stop;
}

// =============================================================================
// COMANDOS ADMIN
// =============================================================================

public Action Cmd_HellOn(int client, int args)
{
	if (!GetConVarBool(g_cvar_Hell_Enable))
		{ ReplyToCommand(client, "[Hell] Sistema deshabilitado"); return Plugin_Handled; }
	Hell_Activate("admin");
	ReplyToCommand(client, "[Hell] ACTIVADO");
	return Plugin_Handled;
}

public Action Cmd_HellOff(int client, int args)
{
	Hell_Deactivate("admin");
	ReplyToCommand(client, "[Hell] DESACTIVADO");
	return Plugin_Handled;
}

public Action Cmd_HellToggle(int client, int args)
{
	return g_bHellActive ? Cmd_HellOff(client, args) : Cmd_HellOn(client, args);
}

public Action Cmd_HellStatus(int client, int args)
{
	char diff[16];
	if (g_zCVAR_Difficulty_Hell) GetConVarString(g_zCVAR_Difficulty_Hell, diff, sizeof(diff));
	ReplyToCommand(client, "[Hell] Activo: %s | Mult: %.2f | Dif: %s",
		g_bHellActive ? "SI" : "NO",
		GetConVarFloat(g_cvar_Hell_DmgMult),
		diff[0] ? diff : "n/a");
	return Plugin_Handled;
}

// =============================================================================
// EVENT TIMER (tanks, panic, witches, mega mob sound)
// =============================================================================

void Hell_StartEventTimer()
{
	if (g_hEventTimer_Hell != null) return;
	g_hEventTimer_Hell = CreateTimer(5.0, Hell_Timer_Events, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void Hell_StopEventTimer()
{
	if (g_hEventTimer_Hell != null) { KillTimer(g_hEventTimer_Hell); g_hEventTimer_Hell = null; }
}

public Action Hell_Timer_Events(Handle timer)
{
	if (!g_bHellActive) return Plugin_Continue;
	float now = GetGameTime();
	if (now - g_fMapStart_Hell < 10.0) return Plugin_Continue;

	// 1. Tank (max 1)
	if (GetConVarBool(g_cvar_Hell_TankSpawn))
	{
		float interval = GetConVarFloat(g_cvar_Hell_TankInterval);
		if (interval > 0.0 && (now - g_fLastTankSpawn_Hell) >= interval
			&& g_iTankCount_Hell < 1 && !DiffBase_IsFinaleActive())
		{
			int target = DiffBase_FindSurvivorTarget();
			if (target != -1)
			{
				float pos[3], ang[3];
				if (L4D_GetRandomPZSpawnPosition(target, view_as<int>(L4D2ZombieClass_Tank), 10, pos))
				{
					GetClientAbsAngles(target, ang);
					int tank = L4D2_SpawnTank(pos, ang);
					if (tank > 0) g_iTankCount_Hell++;
				}
			}
			g_fLastTankSpawn_Hell = now;
		}
	}

	// 2. Panic
	if (GetConVarBool(g_cvar_Hell_PanicEvents))
	{
		float interval = GetConVarFloat(g_cvar_Hell_PanicInterval);
		if (interval > 0.0 && (now - g_fLastPanic_Hell) >= interval)
		{
			L4D_ForcePanicEvent();
			g_fLastPanic_Hell = now;
		}
	}

	// 3. Witches
	if (GetConVarBool(g_cvar_Hell_WitchEnable))
	{
		int witchMax   = GetConVarInt(g_cvar_Hell_WitchMax);
		int witchCount = L4D2_GetWitchCount();
		if (witchCount < witchMax)
		{
			DiffBase_SpawnWitch();
			if (witchCount < witchMax / 2)
				DiffBase_SpawnWitch();
		}
		DiffBase_RecycleWitches(float(GetConVarInt(g_cvar_Hell_WitchRecycleDist)));
		DiffBase_EnrageWitches(GetRandomInt(2, 6));
	}

	// 4. Mega mob sound
	if (GetConVarBool(g_cvar_Hell_MegaMobSound))
	{
		int chance = GetConVarInt(g_cvar_Hell_MegaMobSoundChance);
		if (chance > 0 && GetRandomInt(1, chance) == 1)
			EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN);
	}

	return Plugin_Continue;
}

public void Hell_Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bHellActive) return;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (victim > 0 && IsClientInGame(victim)
		&& GetClientTeam(victim) == 3
		&& GetEntProp(victim, Prop_Send, "m_zombieClass") == 8
		&& g_iTankCount_Hell > 0)
		g_iTankCount_Hell--;
}

public void Hell_Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bHellActive) return;
	if (g_iTankCount_Hell > 0) g_iTankCount_Hell--;
}

// =============================================================================
// API
// =============================================================================

public bool Hell_IsActive() { return g_bHellActive; }
