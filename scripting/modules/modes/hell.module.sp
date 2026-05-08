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
Handle g_cvar_Hell_DebugDamage       = INVALID_HANDLE;

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
Handle g_hFogTimer_Hell   = null;
int    g_iParticleRefs_Hell[16];
int    g_iParticleTotal_Hell = 0;

int  g_iOrigCommonLimit_Hell = -1;
int  g_iOrigMobMin_Hell      = -1;
int  g_iOrigMobMax_Hell      = -1;
int  g_iOrigMegaMob_Hell     = -1;
char g_sOrigDifficulty_Hell[16];

// =============================================================================
// INICIALIZACION
// =============================================================================

public void Hell_OnPluginStart()
{
	g_cvar_Hell_Enable      = CreateConVar("hell_enable",           "1",          "Habilita Hell Mode",               FCVAR_PLUGIN);
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
	g_cvar_Hell_DebugDamage = CreateConVar("hell_debug_damage",     "0",          "Debug dano",                       FCVAR_PLUGIN);

	g_zCVAR_CommonLimit_Hell = FindConVar("z_common_limit");
	g_zCVAR_MobMin_Hell      = FindConVar("z_mob_spawn_min_size");
	g_zCVAR_MobMax_Hell      = FindConVar("z_mob_spawn_max_size");
	g_zCVAR_MegaMob_Hell     = FindConVar("z_mega_mob_size");
	g_zCVAR_Difficulty_Hell  = FindConVar("z_difficulty");

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, Hell_OnTakeDamage);

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
	for (int i = 0; i < 16; i++) g_iParticleRefs_Hell[i] = -1;
	g_iParticleTotal_Hell = 0;
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

	g_bHellActive = true;

	char ls[8];
	GetConVarString(g_cvar_Hell_LightStyle, ls, sizeof(ls));
	DiffBase_ApplyLightStyle(ls);

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

	g_bHellActive = false;

	DiffBase_RestoreDirector(
		g_zCVAR_CommonLimit_Hell, g_zCVAR_MobMin_Hell, g_zCVAR_MobMax_Hell,
		g_zCVAR_MegaMob_Hell,     g_zCVAR_Difficulty_Hell,
		g_iOrigCommonLimit_Hell,  g_iOrigMobMin_Hell,      g_iOrigMobMax_Hell,
		g_iOrigMegaMob_Hell,      g_sOrigDifficulty_Hell);

	DiffBase_RemoveAmbientParticles(g_iParticleRefs_Hell, g_iParticleTotal_Hell);
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
// API
// =============================================================================

public bool Hell_IsActive() { return g_bHellActive; }
