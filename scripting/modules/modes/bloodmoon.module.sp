#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === BLOODMOON MODE MODULE ===
// Luna de sangre manual con efectos ambientales
// Dificultad aumentada, multiplicador de daño, efectos visuales
//==================================================

// Fade flags
#define FFADE_OUT	   0x0001
#define FFADE_IN	   0x0002
#define FFADE_STAYOUT  0x0008
#define FFADE_PURGE	   0x0010

// ConVars del módulo
Handle g_cvar_Bloodmoon_Enable = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_DmgMult = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_Fade = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ChangeDiff = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_CommonLimit = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_MobMin = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_MobMax = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_MegaMob = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_LightStyle = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_LightStyleRestore = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FogEnable = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FogColor = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FogStart = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FogEnd = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FogDensity = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ParticleName = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ParticleCount = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_SoundStart = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_SoundLoop = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_DebugDamage = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FadeAlpha = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FadeDuration = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_FogTick = INVALID_HANDLE;

// ConVars del juego
Handle z_common_limit = INVALID_HANDLE;
Handle z_mob_spawn_min_size = INVALID_HANDLE;
Handle z_mob_spawn_max_size = INVALID_HANDLE;
Handle z_mega_mob_size = INVALID_HANDLE;
Handle z_difficulty = INVALID_HANDLE;

// Backups
int	   g_iOrigCommonLimit = -1;
int	   g_iOrigMobMin = -1;
int	   g_iOrigMobMax = -1;
int	   g_iOrigMegaMob = -1;
char   g_sOrigDifficulty[16];

// Estado
bool   g_bBloodmoonActive = false;
int	   g_iParticleRefs[16];
int	   g_iParticleTotal = 0;
int	   g_iFogRef = -1;
Handle g_hFogTimer = null;

/**
 * Inicializa el módulo de Bloodmoon
 */
public void Bloodmoon_OnPluginStart()
{
	// ConVars principales
	g_cvar_Bloodmoon_Enable = CreateConVar("bloodmoon_enable", "1", "Habilita el sistema de Bloodmoon", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_DmgMult = CreateConVar("bloodmoon_damage_mult", "1.35", "Multiplicador de daño a Survivors", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_Fade = CreateConVar("bloodmoon_fade", "1", "Fade rojo persistente", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_ChangeDiff = CreateConVar("bloodmoon_change_difficulty", "1", "Cambiar a Experto", FCVAR_PLUGIN);

	// Director
	g_cvar_Bloodmoon_CommonLimit = CreateConVar("bloodmoon_common_limit", "45", "z_common_limit durante Bloodmoon", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_MobMin = CreateConVar("bloodmoon_mob_min", "25", "z_mob_spawn_min_size", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_MobMax = CreateConVar("bloodmoon_mob_max", "35", "z_mob_spawn_max_size", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_MegaMob = CreateConVar("bloodmoon_mega_mob", "60", "z_mega_mob_size", FCVAR_PLUGIN);

	// Ambientación
	g_cvar_Bloodmoon_LightStyle = CreateConVar("bloodmoon_lightstyle", "b", "LightStyle a aplicar", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_LightStyleRestore = CreateConVar("bloodmoon_lightstyle_restore", "m", "LightStyle a restaurar", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FogEnable = CreateConVar("bloodmoon_fog_enable", "1", "Crear Fog", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FogColor = CreateConVar("bloodmoon_fog_color", "200 40 40", "Color Fog 'r g b'", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FogStart = CreateConVar("bloodmoon_fog_start", "50", "Fog start distance", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FogEnd = CreateConVar("bloodmoon_fog_end", "1200", "Fog end distance", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FogDensity = CreateConVar("bloodmoon_fog_density", "0.7", "Fog max density 0..1", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_ParticleName = CreateConVar("bloodmoon_particle", "env_snow_128", "Partícula ambiental", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_ParticleCount = CreateConVar("bloodmoon_particle_count", "3", "Cantidad de emisores", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_SoundStart = CreateConVar("bloodmoon_sound_start", "", "Sonido al activar", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_SoundLoop = CreateConVar("bloodmoon_sound_loop", "", "Sonido loop", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FadeAlpha = CreateConVar("bloodmoon_fade_alpha", "120", "Alpha del overlay rojo 0..255", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FadeDuration = CreateConVar("bloodmoon_fade_duration", "1500", "Duración ms de transición", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_FogTick = CreateConVar("bloodmoon_fog_tick", "3.0", "Intervalo para re-aplicar fog", FCVAR_PLUGIN);

	// Debug
	g_cvar_Bloodmoon_DebugDamage = CreateConVar("bloodmoon_debug_damage", "0", "Debug de daño", FCVAR_PLUGIN);

	// Obtener ConVars del juego
	z_common_limit = FindConVar("z_common_limit");
	z_mob_spawn_min_size = FindConVar("z_mob_spawn_min_size");
	z_mob_spawn_max_size = FindConVar("z_mob_spawn_max_size");
	z_mega_mob_size = FindConVar("z_mega_mob_size");
	z_difficulty = FindConVar("z_difficulty");

	// Hooks de daño
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, Bloodmoon_OnTakeDamage);

	// Comandos admin
	RegAdminCmd("sm_bloodmoon_on", Cmd_BloodmoonOn, ADMFLAG_GENERIC, "Activa Bloodmoon");
	RegAdminCmd("sm_bloodmoon_off", Cmd_BloodmoonOff, ADMFLAG_GENERIC, "Desactiva Bloodmoon");
	RegAdminCmd("sm_bloodmoon_toggle", Cmd_BloodmoonToggle, ADMFLAG_GENERIC, "Alterna Bloodmoon");
	RegAdminCmd("sm_bloodmoon_status", Cmd_BloodmoonStatus, ADMFLAG_GENERIC, "Estado Bloodmoon");
	RegAdminCmd("sm_bloodmoon_testmob", Cmd_BloodmoonTestMob, ADMFLAG_GENERIC, "Fuerza una horda");

	g_sOrigDifficulty[0] = '\0';
	g_iFogRef = -1;
}

/**
 * Hook cuando un cliente se conecta
 */
public void Bloodmoon_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Bloodmoon_OnTakeDamage);
}

/**
 * Hook cuando un cliente se desconecta
 */
public void Bloodmoon_OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Bloodmoon_OnTakeDamage);
}

/**
 * Al inicio del mapa
 */
public void Bloodmoon_OnMapStart()
{
	g_iOrigCommonLimit = g_iOrigMobMin = g_iOrigMobMax = g_iOrigMegaMob = -1;
}

/**
 * Hook de daño - Multiplicador de Bloodmoon
 */
public Action Bloodmoon_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_bBloodmoonActive) return Plugin_Continue;
	if (!IsValidClient(victim) || GetClientTeam(victim) != 2) return Plugin_Continue;

	float mult = GetConVarFloat(g_cvar_Bloodmoon_DmgMult);
	if (mult <= 1.0) return Plugin_Continue;

	bool fromSpecial = (IsValidClient(attacker) && GetClientTeam(attacker) == 3);
	bool fromCommon = false;

	if (!fromSpecial)
	{
		char cls[32];
		if (IsValidEdict(attacker) && attacker > MaxClients)
		{
			GetEdictClassname(attacker, cls, sizeof(cls));
			if (StrEqual(cls, "infected", false)) fromCommon = true;
		}
		else if (IsValidEdict(inflictor) && inflictor > MaxClients)
		{
			GetEdictClassname(inflictor, cls, sizeof(cls));
			if (StrEqual(cls, "infected", false)) fromCommon = true;
		}
	}

	if (fromSpecial || fromCommon)
	{
		damage *= mult;
		if (GetConVarBool(g_cvar_Bloodmoon_DebugDamage))
		{
			char vName[64];
			GetClientName(victim, vName, sizeof(vName));
			PrintToChatAll("\x05[Bloodmoon:DMG]\x01 %s recibió %.1f daño (mult=%.2f)", vName, damage, mult);
		}
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

/**
 * Comandos admin
 */
public Action Cmd_BloodmoonOn(int client, int args)
{
	if (!GetConVarBool(g_cvar_Bloodmoon_Enable))
	{
		ReplyToCommand(client, "[Bloodmoon] Sistema deshabilitado");
		return Plugin_Handled;
	}
	Bloodmoon_Activate("comando admin");
	ReplyToCommand(client, "[Bloodmoon] ACTIVADO");
	return Plugin_Handled;
}

public Action Cmd_BloodmoonOff(int client, int args)
{
	Bloodmoon_Deactivate("comando admin");
	ReplyToCommand(client, "[Bloodmoon] DESACTIVADO");
	return Plugin_Handled;
}

public Action Cmd_BloodmoonToggle(int client, int args)
{
	if (g_bBloodmoonActive)
		return Cmd_BloodmoonOff(client, args);
	return Cmd_BloodmoonOn(client, args);
}

public Action Cmd_BloodmoonStatus(int client, int args)
{
	char diff[16];
	if (z_difficulty) GetConVarString(z_difficulty, diff, sizeof(diff));

	ReplyToCommand(client, "[Bloodmoon] Activo: %s | Mult: %.2f | Dificultad: %s",
		g_bBloodmoonActive ? "SI" : "NO",
		GetConVarFloat(g_cvar_Bloodmoon_DmgMult),
		diff[0] ? diff : "n/a");
	return Plugin_Handled;
}

public Action Cmd_BloodmoonTestMob(int client, int args)
{
	ServerCommand("z_spawn mob");
	ReplyToCommand(client, "[Bloodmoon] Horda forzada");
	return Plugin_Handled;
}

/**
 * Activa el modo Bloodmoon
 */
void Bloodmoon_Activate(const char[] reason = "manual")
{
	if (g_bBloodmoonActive) return;

	#pragma unused reason

	Bloodmoon_CacheOriginalDirector();
	Bloodmoon_ApplyDirector();

	g_bBloodmoonActive = true;

	// Ambientación
	Bloodmoon_ApplyLightStyle();

	if (GetConVarBool(g_cvar_Bloodmoon_FogEnable))
	{
		int ent = Bloodmoon_SpawnFogController();
		g_iFogRef = (ent != -1) ? EntIndexToEntRef(ent) : -1;
		Bloodmoon_StartFogEnforcerTimer();
	}

	Bloodmoon_CreateAmbientParticles();

	char sStart[128], sLoop[128];
	GetConVarString(g_cvar_Bloodmoon_SoundStart, sStart, sizeof(sStart));
	GetConVarString(g_cvar_Bloodmoon_SoundLoop, sLoop, sizeof(sLoop));
	if (sStart[0]) Bloodmoon_PlaySoundToAll(sStart);
	if (sLoop[0]) Bloodmoon_PlaySoundToAll(sLoop);

	Bloodmoon_DoScreenFadeAll(true);

	PrintToChatAll("\x04[Bloodmoon]\x01 ¡Luna de Sangre ACTIVADA! Hordas y daño incrementados (mult=%.2f)",
		GetConVarFloat(g_cvar_Bloodmoon_DmgMult));

	if (GetConVarBool(g_cvar_Bloodmoon_ChangeDiff))
	{
		ServerCommand("z_difficulty Impossible");
	}
}

/**
 * Desactiva el modo Bloodmoon
 */
void Bloodmoon_Deactivate(const char[] reason = "manual")
{
	if (!g_bBloodmoonActive) return;

	#pragma unused reason

	Bloodmoon_RestoreDirector();
	g_bBloodmoonActive = false;

	Bloodmoon_RemoveAmbientParticles();
	Bloodmoon_StopFogEnforcerTimer();
	Bloodmoon_RemoveFogController();
	Bloodmoon_RestoreLightStyle();

	char sLoop[128];
	GetConVarString(g_cvar_Bloodmoon_SoundLoop, sLoop, sizeof(sLoop));
	if (sLoop[0]) Bloodmoon_StopSoundToAll(sLoop);

	if (GetConVarBool(g_cvar_Bloodmoon_ChangeDiff) && g_sOrigDifficulty[0] != '\0')
	{
		ServerCommand("z_difficulty %s", g_sOrigDifficulty);
	}

	Bloodmoon_DoScreenFadeAll(false);
	PrintToChatAll("\x04[Bloodmoon]\x01 Luna de Sangre DESACTIVADA. Director restaurado");
}

// ==================== FUNCIONES DE SOPORTE ====================

void Bloodmoon_CacheOriginalDirector()
{
	if (g_iOrigCommonLimit == -1 && z_common_limit != null)
		g_iOrigCommonLimit = GetConVarInt(z_common_limit);
	if (g_iOrigMobMin == -1 && z_mob_spawn_min_size != null)
		g_iOrigMobMin = GetConVarInt(z_mob_spawn_min_size);
	if (g_iOrigMobMax == -1 && z_mob_spawn_max_size != null)
		g_iOrigMobMax = GetConVarInt(z_mob_spawn_max_size);
	if (g_iOrigMegaMob == -1 && z_mega_mob_size != null)
		g_iOrigMegaMob = GetConVarInt(z_mega_mob_size);
	if (g_sOrigDifficulty[0] == '\0' && z_difficulty != null)
		GetConVarString(z_difficulty, g_sOrigDifficulty, sizeof(g_sOrigDifficulty));
}

void Bloodmoon_ApplyDirector()
{
	if (z_common_limit) SetConVarInt(z_common_limit, GetConVarInt(g_cvar_Bloodmoon_CommonLimit));
	if (z_mob_spawn_min_size) SetConVarInt(z_mob_spawn_min_size, GetConVarInt(g_cvar_Bloodmoon_MobMin));
	if (z_mob_spawn_max_size) SetConVarInt(z_mob_spawn_max_size, GetConVarInt(g_cvar_Bloodmoon_MobMax));
	if (z_mega_mob_size) SetConVarInt(z_mega_mob_size, GetConVarInt(g_cvar_Bloodmoon_MegaMob));
}

void Bloodmoon_RestoreDirector()
{
	if (z_common_limit && g_iOrigCommonLimit != -1) SetConVarInt(z_common_limit, g_iOrigCommonLimit);
	if (z_mob_spawn_min_size && g_iOrigMobMin != -1) SetConVarInt(z_mob_spawn_min_size, g_iOrigMobMin);
	if (z_mob_spawn_max_size && g_iOrigMobMax != -1) SetConVarInt(z_mob_spawn_max_size, g_iOrigMobMax);
	if (z_mega_mob_size && g_iOrigMegaMob != -1) SetConVarInt(z_mega_mob_size, g_iOrigMegaMob);
}

void Bloodmoon_ApplyLightStyle()
{
	char ls[8];
	GetConVarString(g_cvar_Bloodmoon_LightStyle, ls, sizeof(ls));
	if (ls[0]) SetLightStyle(0, ls);
}

void Bloodmoon_RestoreLightStyle()
{
	char ls[8];
	GetConVarString(g_cvar_Bloodmoon_LightStyleRestore, ls, sizeof(ls));
	if (ls[0]) SetLightStyle(0, ls);
}

int Bloodmoon_SpawnFogController()
{
	int ent = CreateEntityByName("env_fog_controller");
	if (ent == -1) return -1;

	char color[32];
	GetConVarString(g_cvar_Bloodmoon_FogColor, color, sizeof(color));
	char density[16];
	FloatToString(GetConVarFloat(g_cvar_Bloodmoon_FogDensity), density, sizeof(density));
	char sStart[16];
	IntToString(GetConVarInt(g_cvar_Bloodmoon_FogStart), sStart, sizeof(sStart));
	char sEnd[16];
	IntToString(GetConVarInt(g_cvar_Bloodmoon_FogEnd), sEnd, sizeof(sEnd));

	DispatchKeyValue(ent, "fogcolor", color);
	DispatchKeyValue(ent, "fogstart", sStart);
	DispatchKeyValue(ent, "fogend", sEnd);
	DispatchKeyValue(ent, "fogmaxdensity", density);
	DispatchKeyValue(ent, "fogenable", "1");
	DispatchSpawn(ent);
	AcceptEntityInput(ent, "TurnOn");

	return ent;
}

void Bloodmoon_RemoveFogController()
{
	int ent = EntRefToEntIndex(g_iFogRef);
	if (ent != -1 && IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "TurnOff");
		RemoveEntity(ent);
	}
	g_iFogRef = -1;
}

void Bloodmoon_CreateAmbientParticles()
{
	g_iParticleTotal = 0;
	char pname[64];
	GetConVarString(g_cvar_Bloodmoon_ParticleName, pname, sizeof(pname));
	if (!pname[0]) return;

	int count = GetConVarInt(g_cvar_Bloodmoon_ParticleCount);
	if (count < 1) return;
	if (count > 16) count = 16;

	PrecacheGeneric(pname, true);

	for (int i = 0; i < count; i++)
	{
		int ent = CreateEntityByName("info_particle_system");
		if (ent == -1) continue;

		DispatchKeyValue(ent, "effect_name", pname);
		DispatchKeyValue(ent, "start_active", "1");

		float pos[3];
		pos[0] = float(i * 64);
		pos[1] = float((i % 3) * 96);
		pos[2] = 72.0;
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "Start");

		g_iParticleRefs[g_iParticleTotal++] = EntIndexToEntRef(ent);
	}
}

void Bloodmoon_RemoveAmbientParticles()
{
	for (int i = 0; i < g_iParticleTotal; i++)
	{
		int ent = EntRefToEntIndex(g_iParticleRefs[i]);
		if (ent != -1 && IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "Stop");
			RemoveEntity(ent);
		}
	}
	g_iParticleTotal = 0;
}

void Bloodmoon_PlaySoundToAll(const char[] sample)
{
	if (!sample[0]) return;
	PrecacheSound(sample, true);
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			EmitSoundToClient(i, sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN, _, 1.0);
}

void Bloodmoon_StopSoundToAll(const char[] sample)
{
	if (!sample[0]) return;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			StopSound(i, SNDCHAN_STATIC, sample);
}

void Bloodmoon_DoScreenFadeAll(bool activate)
{
	if (!GetConVarBool(g_cvar_Bloodmoon_Fade)) return;

	int r = 120, g = 0, b = 0;
	int alpha = GetConVarInt(g_cvar_Bloodmoon_FadeAlpha);
	int duration = GetConVarInt(g_cvar_Bloodmoon_FadeDuration);
	int hold = 0;

	// Purge previo
	Handle hPurge = StartMessageAll("Fade");
	if (hPurge != null)
	{
		BfWriteShort(hPurge, 0);
		BfWriteShort(hPurge, 0);
		BfWriteShort(hPurge, FFADE_PURGE);
		BfWriteByte(hPurge, 0);
		BfWriteByte(hPurge, 0);
		BfWriteByte(hPurge, 0);
		BfWriteByte(hPurge, 0);
		EndMessage();
	}

	int flags = activate ? (FFADE_IN | FFADE_STAYOUT) : FFADE_OUT;

	Handle hFade = StartMessageAll("Fade");
	if (hFade != null)
	{
		BfWriteShort(hFade, duration);
		BfWriteShort(hFade, hold);
		BfWriteShort(hFade, flags);
		BfWriteByte(hFade, r);
		BfWriteByte(hFade, g);
		BfWriteByte(hFade, b);
		BfWriteByte(hFade, alpha);
		EndMessage();
	}

	if (!activate)
	{
		CreateTimer(float(duration) / 1000.0 + 0.05, Bloodmoon_Timer_PurgeFadeOnce);
	}
}

public Action Bloodmoon_Timer_PurgeFadeOnce(Handle t, any data)
{
	Handle h = StartMessageAll("Fade");
	if (h != null)
	{
		BfWriteShort(h, 0);
		BfWriteShort(h, 0);
		BfWriteShort(h, FFADE_PURGE);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		EndMessage();
	}
	return Plugin_Stop;
}

void Bloodmoon_ApplyFogSettingsToEnt(int ent)
{
	if (ent == -1 || !IsValidEntity(ent)) return;

	char color[32];
	GetConVarString(g_cvar_Bloodmoon_FogColor, color, sizeof(color));
	SetVariantString(color);
	AcceptEntityInput(ent, "SetColor");

	int s = GetConVarInt(g_cvar_Bloodmoon_FogStart);
	int e = GetConVarInt(g_cvar_Bloodmoon_FogEnd);
	float d = GetConVarFloat(g_cvar_Bloodmoon_FogDensity);

	SetVariantInt(s);
	AcceptEntityInput(ent, "SetStartDist");
	SetVariantInt(e);
	AcceptEntityInput(ent, "SetEndDist");
	SetVariantFloat(d);
	AcceptEntityInput(ent, "SetMaxDensity");
	AcceptEntityInput(ent, "TurnOn");
}

int Bloodmoon_EnsureFogController()
{
	int ent = EntRefToEntIndex(g_iFogRef);
	if (ent == -1 || !IsValidEntity(ent))
	{
		ent = Bloodmoon_SpawnFogController();
		g_iFogRef = (ent != -1) ? EntIndexToEntRef(ent) : -1;
	}
	if (ent != -1 && IsValidEntity(ent))
	{
		Bloodmoon_ApplyFogSettingsToEnt(ent);
	}
	return ent;
}

public Action Bloodmoon_Timer_FogEnforcer(Handle timer, any data)
{
	if (!g_bBloodmoonActive || !GetConVarBool(g_cvar_Bloodmoon_FogEnable))
		return Plugin_Continue;

	Bloodmoon_EnsureFogController();
	return Plugin_Continue;
}

void Bloodmoon_StartFogEnforcerTimer()
{
	if (g_hFogTimer == null)
	{
		float tick = GetConVarFloat(g_cvar_Bloodmoon_FogTick);
		if (tick < 1.0) tick = 1.0;
		g_hFogTimer = CreateTimer(tick, Bloodmoon_Timer_FogEnforcer, _, TIMER_REPEAT);
	}
}

void Bloodmoon_StopFogEnforcerTimer()
{
	if (g_hFogTimer != null)
	{
		KillTimer(g_hFogTimer);
		g_hFogTimer = null;
	}
}

/**
 * Obtiene si Bloodmoon está activo
 */
public bool Bloodmoon_IsActive()
{
	return g_bBloodmoonActive;
}

/**
 * Utilidad para validar clientes
 */
bool IsValidClient(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client));
}
