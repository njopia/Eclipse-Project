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
Handle g_cvar_Inferno_DebugDamage       = INVALID_HANDLE;

// ConVars del juego
Handle g_zCVAR_CommonLimit_Inf = INVALID_HANDLE;
Handle g_zCVAR_MobMin_Inf      = INVALID_HANDLE;
Handle g_zCVAR_MobMax_Inf      = INVALID_HANDLE;
Handle g_zCVAR_MegaMob_Inf     = INVALID_HANDLE;
Handle g_zCVAR_Difficulty_Inf  = INVALID_HANDLE;

// =============================================================================
// ESTADO
// =============================================================================

bool   g_bInfernoActive      = false;
int    g_iFogRef_Inf         = -1;
Handle g_hFogTimer_Inf       = null;
int    g_iParticleRefs_Inf[16];
int    g_iParticleTotal_Inf  = 0;

int  g_iOrigCommonLimit_Inf = -1;
int  g_iOrigMobMin_Inf      = -1;
int  g_iOrigMobMax_Inf      = -1;
int  g_iOrigMegaMob_Inf     = -1;
char g_sOrigDifficulty_Inf[16];

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
	g_cvar_Inferno_DebugDamage = CreateConVar("inferno_debug_damage",     "0",          "Debug dano",                        FCVAR_PLUGIN);

	g_zCVAR_CommonLimit_Inf = FindConVar("z_common_limit");
	g_zCVAR_MobMin_Inf      = FindConVar("z_mob_spawn_min_size");
	g_zCVAR_MobMax_Inf      = FindConVar("z_mob_spawn_max_size");
	g_zCVAR_MegaMob_Inf     = FindConVar("z_mega_mob_size");
	g_zCVAR_Difficulty_Inf  = FindConVar("z_difficulty");

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, Inferno_OnTakeDamage);

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
	g_iParticleTotal_Inf = 0;
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

	g_bInfernoActive = true;

	char ls[8];
	GetConVarString(g_cvar_Inferno_LightStyle, ls, sizeof(ls));
	DiffBase_ApplyLightStyle(ls);

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

	g_bInfernoActive = false;

	DiffBase_RestoreDirector(
		g_zCVAR_CommonLimit_Inf, g_zCVAR_MobMin_Inf, g_zCVAR_MobMax_Inf,
		g_zCVAR_MegaMob_Inf,     g_zCVAR_Difficulty_Inf,
		g_iOrigCommonLimit_Inf,  g_iOrigMobMin_Inf,      g_iOrigMobMax_Inf,
		g_iOrigMegaMob_Inf,      g_sOrigDifficulty_Inf);

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
// API
// =============================================================================

public bool Inferno_IsActive() { return g_bInfernoActive; }
