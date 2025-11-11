#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === HELL MODE MODULE ===
// Modo infernal con efectos de fuego y dificultad extrema
// Mayor multiplicador de daño que Bloodmoon, efectos visuales de fuego
//==================================================

// ConVars del módulo
Handle g_cvar_Hell_Enable = INVALID_HANDLE;
Handle g_cvar_Hell_DmgMult = INVALID_HANDLE;
Handle g_cvar_Hell_Fade = INVALID_HANDLE;
Handle g_cvar_Hell_ChangeDiff = INVALID_HANDLE;
Handle g_cvar_Hell_CommonLimit = INVALID_HANDLE;
Handle g_cvar_Hell_MobMin = INVALID_HANDLE;
Handle g_cvar_Hell_MobMax = INVALID_HANDLE;
Handle g_cvar_Hell_MegaMob = INVALID_HANDLE;
Handle g_cvar_Hell_LightStyle = INVALID_HANDLE;
Handle g_cvar_Hell_LightStyleRestore = INVALID_HANDLE;
Handle g_cvar_Hell_FogEnable = INVALID_HANDLE;
Handle g_cvar_Hell_FogColor = INVALID_HANDLE;
Handle g_cvar_Hell_FogStart = INVALID_HANDLE;
Handle g_cvar_Hell_FogEnd = INVALID_HANDLE;
Handle g_cvar_Hell_FogDensity = INVALID_HANDLE;
Handle g_cvar_Hell_ParticleName = INVALID_HANDLE;
Handle g_cvar_Hell_ParticleCount = INVALID_HANDLE;
Handle g_cvar_Hell_SoundStart = INVALID_HANDLE;
Handle g_cvar_Hell_SoundLoop = INVALID_HANDLE;
Handle g_cvar_Hell_DebugDamage = INVALID_HANDLE;
Handle g_cvar_Hell_FadeAlpha = INVALID_HANDLE;
Handle g_cvar_Hell_FadeDuration = INVALID_HANDLE;
Handle g_cvar_Hell_FogTick = INVALID_HANDLE;

// ConVars del juego (compartidas con Bloodmoon)
Handle z_common_limit_hell = INVALID_HANDLE;
Handle z_mob_spawn_min_size_hell = INVALID_HANDLE;
Handle z_mob_spawn_max_size_hell = INVALID_HANDLE;
Handle z_mega_mob_size_hell = INVALID_HANDLE;
Handle z_difficulty_hell = INVALID_HANDLE;

// Backups
int	   g_iOrigCommonLimit_Hell = -1;
int	   g_iOrigMobMin_Hell = -1;
int	   g_iOrigMobMax_Hell = -1;
int	   g_iOrigMegaMob_Hell = -1;
char   g_sOrigDifficulty_Hell[16];

// Estado
bool   g_bHellActive = false;
int	   g_iParticleRefs_Hell[16];
int	   g_iParticleTotal_Hell = 0;
int	   g_iFogRef_Hell = -1;
Handle g_hFogTimer_Hell = null;

/**
 * Inicializa el módulo de Hell
 */
public void Hell_OnPluginStart()
{
	// ConVars principales
	g_cvar_Hell_Enable = CreateConVar("hell_enable", "1", "Habilita el sistema de Hell Mode", FCVAR_PLUGIN);
	g_cvar_Hell_DmgMult = CreateConVar("hell_damage_mult", "1.5", "Multiplicador de daño a Survivors", FCVAR_PLUGIN);
	g_cvar_Hell_Fade = CreateConVar("hell_fade", "1", "Fade rojo-naranja persistente", FCVAR_PLUGIN);
	g_cvar_Hell_ChangeDiff = CreateConVar("hell_change_difficulty", "1", "Cambiar a Experto", FCVAR_PLUGIN);

	// Director
	g_cvar_Hell_CommonLimit = CreateConVar("hell_common_limit", "50", "z_common_limit durante Hell Mode", FCVAR_PLUGIN);
	g_cvar_Hell_MobMin = CreateConVar("hell_mob_min", "30", "z_mob_spawn_min_size", FCVAR_PLUGIN);
	g_cvar_Hell_MobMax = CreateConVar("hell_mob_max", "40", "z_mob_spawn_max_size", FCVAR_PLUGIN);
	g_cvar_Hell_MegaMob = CreateConVar("hell_mega_mob", "70", "z_mega_mob_size", FCVAR_PLUGIN);

	// Ambientación
	g_cvar_Hell_LightStyle = CreateConVar("hell_lightstyle", "a", "LightStyle a aplicar", FCVAR_PLUGIN);
	g_cvar_Hell_LightStyleRestore = CreateConVar("hell_lightstyle_restore", "m", "LightStyle a restaurar", FCVAR_PLUGIN);
	g_cvar_Hell_FogEnable = CreateConVar("hell_fog_enable", "1", "Crear Fog", FCVAR_PLUGIN);
	g_cvar_Hell_FogColor = CreateConVar("hell_fog_color", "255 80 20", "Color Fog 'r g b'", FCVAR_PLUGIN);
	g_cvar_Hell_FogStart = CreateConVar("hell_fog_start", "40", "Fog start distance", FCVAR_PLUGIN);
	g_cvar_Hell_FogEnd = CreateConVar("hell_fog_end", "1000", "Fog end distance", FCVAR_PLUGIN);
	g_cvar_Hell_FogDensity = CreateConVar("hell_fog_density", "0.75", "Fog max density 0..1", FCVAR_PLUGIN);
	g_cvar_Hell_ParticleName = CreateConVar("hell_particle", "env_fire_small_smoke", "Partícula ambiental", FCVAR_PLUGIN);
	g_cvar_Hell_ParticleCount = CreateConVar("hell_particle_count", "4", "Cantidad de emisores", FCVAR_PLUGIN);
	g_cvar_Hell_SoundStart = CreateConVar("hell_sound_start", "", "Sonido al activar", FCVAR_PLUGIN);
	g_cvar_Hell_SoundLoop = CreateConVar("hell_sound_loop", "", "Sonido loop", FCVAR_PLUGIN);
	g_cvar_Hell_FadeAlpha = CreateConVar("hell_fade_alpha", "100", "Alpha del overlay rojo-naranja 0..255", FCVAR_PLUGIN);
	g_cvar_Hell_FadeDuration = CreateConVar("hell_fade_duration", "1500", "Duración ms de transición", FCVAR_PLUGIN);
	g_cvar_Hell_FogTick = CreateConVar("hell_fog_tick", "3.0", "Intervalo para re-aplicar fog", FCVAR_PLUGIN);

	// Debug
	g_cvar_Hell_DebugDamage = CreateConVar("hell_debug_damage", "0", "Debug de daño", FCVAR_PLUGIN);

	// Obtener ConVars del juego
	z_common_limit_hell = FindConVar("z_common_limit");
	z_mob_spawn_min_size_hell = FindConVar("z_mob_spawn_min_size");
	z_mob_spawn_max_size_hell = FindConVar("z_mob_spawn_max_size");
	z_mega_mob_size_hell = FindConVar("z_mega_mob_size");
	z_difficulty_hell = FindConVar("z_difficulty");

	// Hooks de daño
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, Hell_OnTakeDamage);

	// Comandos admin
	RegAdminCmd("sm_hell_on", Cmd_HellOn, ADMFLAG_GENERIC, "Activa Hell Mode");
	RegAdminCmd("sm_hell_off", Cmd_HellOff, ADMFLAG_GENERIC, "Desactiva Hell Mode");
	RegAdminCmd("sm_hell_toggle", Cmd_HellToggle, ADMFLAG_GENERIC, "Alterna Hell Mode");
	RegAdminCmd("sm_hell_status", Cmd_HellStatus, ADMFLAG_GENERIC, "Estado Hell Mode");

	// Hook ConVar para detectar activación/desactivación
	HookConVarChange(g_cvar_Hell_Enable, Hell_ConVarChanged);

	g_sOrigDifficulty_Hell[0] = '\0';
	g_iFogRef_Hell = -1;
}

/**
 * Callback cuando cambia el ConVar de enable
 */
public void Hell_ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_cvar_Hell_Enable)
	{
		bool bNewState = GetConVarBool(g_cvar_Hell_Enable);

		LogMessage("[Hell] ConVar changed from '%s' to '%s' (state: %d)", oldValue, newValue, bNewState);

		if (bNewState && !g_bHellActive)
		{
			LogMessage("[Hell] Activating Hell mode...");
			Hell_Activate("convar");
		}
		else if (!bNewState && g_bHellActive)
		{
			LogMessage("[Hell] Deactivating Hell mode...");
			Hell_Deactivate("convar");
		}
	}
}

/**
 * Hook cuando un cliente se conecta
 */
public void Hell_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hell_OnTakeDamage);
}

/**
 * Hook cuando un cliente se desconecta
 */
public void Hell_OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Hell_OnTakeDamage);
}

/**
 * Al inicio del mapa
 */
public void Hell_OnMapStart()
{
	g_iOrigCommonLimit_Hell = g_iOrigMobMin_Hell = g_iOrigMobMax_Hell = g_iOrigMegaMob_Hell = -1;
}

/**
 * Hook cuando un mapa termina
 */
public void Hell_OnMapEnd()
{
	// Desactivar Hell si está activo al cambiar de mapa
	if (g_bHellActive)
	{
		LogMessage("[Hell] Map ending, deactivating Hell");
		Hell_Deactivate("map_end");
	}
}

/**
 * Hook de daño - Multiplicador de Hell
 */
public Action Hell_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_bHellActive) return Plugin_Continue;
	if (!hell_IsValidClient(victim) || GetClientTeam(victim) != 2) return Plugin_Continue;

	float mult = GetConVarFloat(g_cvar_Hell_DmgMult);
	if (mult <= 1.0) return Plugin_Continue;

	bool fromSpecial = (hell_IsValidClient(attacker) && GetClientTeam(attacker) == 3);
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
		if (GetConVarBool(g_cvar_Hell_DebugDamage))
		{
			char vName[64];
			GetClientName(victim, vName, sizeof(vName));
			PrintToChatAll("\x05[Hell:DMG]\x01 %s recibió %.1f daño (mult=%.2f)", vName, damage, mult);
		}
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

/**
 * Comandos admin
 */
public Action Cmd_HellOn(int client, int args)
{
	if (!GetConVarBool(g_cvar_Hell_Enable))
	{
		ReplyToCommand(client, "[Hell] Sistema deshabilitado");
		return Plugin_Handled;
	}
	Hell_Activate("comando admin");
	ReplyToCommand(client, "[Hell] ACTIVADO");
	return Plugin_Handled;
}

public Action Cmd_HellOff(int client, int args)
{
	Hell_Deactivate("comando admin");
	ReplyToCommand(client, "[Hell] DESACTIVADO");
	return Plugin_Handled;
}

public Action Cmd_HellToggle(int client, int args)
{
	if (g_bHellActive)
		return Cmd_HellOff(client, args);
	return Cmd_HellOn(client, args);
}

public Action Cmd_HellStatus(int client, int args)
{
	char diff[16];
	if (z_difficulty_hell) GetConVarString(z_difficulty_hell, diff, sizeof(diff));

	ReplyToCommand(client, "[Hell] Activo: %s | Mult: %.2f | Dificultad: %s",
		g_bHellActive ? "SI" : "NO",
		GetConVarFloat(g_cvar_Hell_DmgMult),
		diff[0] ? diff : "n/a");
	return Plugin_Handled;
}

/**
 * Activa el modo Hell
 */
void Hell_Activate(const char[] reason = "manual")
{
	if (g_bHellActive) return;

	#pragma unused reason

	Hell_CacheOriginalDirector();
	Hell_ApplyDirector();

	g_bHellActive = true;

	// Ambientación
	Hell_ApplyLightStyle();

	if (GetConVarBool(g_cvar_Hell_FogEnable))
	{
		int ent = Hell_SpawnFogController();
		g_iFogRef_Hell = (ent != -1) ? EntIndexToEntRef(ent) : -1;
		Hell_StartFogEnforcerTimer();
	}

	Hell_CreateAmbientParticles();

	char sStart[128], sLoop[128];
	GetConVarString(g_cvar_Hell_SoundStart, sStart, sizeof(sStart));
	GetConVarString(g_cvar_Hell_SoundLoop, sLoop, sizeof(sLoop));
	if (sStart[0]) Hell_PlaySoundToAll(sStart);
	if (sLoop[0]) Hell_PlaySoundToAll(sLoop);

	Hell_DoScreenFadeAll(true);

	PrintToChatAll("\x04[Hell]\x01 ¡Modo Infierno ACTIVADO! Las llamas del infierno te consumirán (mult=%.2f)",
		GetConVarFloat(g_cvar_Hell_DmgMult));

	if (GetConVarBool(g_cvar_Hell_ChangeDiff))
	{
		ServerCommand("z_difficulty Impossible");
	}
}

/**
 * Desactiva el modo Hell
 */
void Hell_Deactivate(const char[] reason = "manual")
{
	if (!g_bHellActive) return;

	#pragma unused reason

	Hell_RestoreDirector();
	g_bHellActive = false;

	Hell_RemoveAmbientParticles();
	Hell_StopFogEnforcerTimer();
	Hell_RemoveFogController();
	Hell_RestoreLightStyle();

	char sLoop[128];
	GetConVarString(g_cvar_Hell_SoundLoop, sLoop, sizeof(sLoop));
	if (sLoop[0]) Hell_StopSoundToAll(sLoop);

	if (GetConVarBool(g_cvar_Hell_ChangeDiff) && g_sOrigDifficulty_Hell[0] != '\0')
	{
		ServerCommand("z_difficulty %s", g_sOrigDifficulty_Hell);
	}

	Hell_DoScreenFadeAll(false);
	PrintToChatAll("\x04[Hell]\x01 Modo Infierno DESACTIVADO. Has escapado del infierno.");
}

// ==================== FUNCIONES DE SOPORTE ====================

void Hell_CacheOriginalDirector()
{
	if (g_iOrigCommonLimit_Hell == -1 && z_common_limit_hell != null)
		g_iOrigCommonLimit_Hell = GetConVarInt(z_common_limit_hell);
	if (g_iOrigMobMin_Hell == -1 && z_mob_spawn_min_size_hell != null)
		g_iOrigMobMin_Hell = GetConVarInt(z_mob_spawn_min_size_hell);
	if (g_iOrigMobMax_Hell == -1 && z_mob_spawn_max_size_hell != null)
		g_iOrigMobMax_Hell = GetConVarInt(z_mob_spawn_max_size_hell);
	if (g_iOrigMegaMob_Hell == -1 && z_mega_mob_size_hell != null)
		g_iOrigMegaMob_Hell = GetConVarInt(z_mega_mob_size_hell);
	if (g_sOrigDifficulty_Hell[0] == '\0' && z_difficulty_hell != null)
		GetConVarString(z_difficulty_hell, g_sOrigDifficulty_Hell, sizeof(g_sOrigDifficulty_Hell));
}

void Hell_ApplyDirector()
{
	if (z_common_limit_hell) SetConVarInt(z_common_limit_hell, GetConVarInt(g_cvar_Hell_CommonLimit));
	if (z_mob_spawn_min_size_hell) SetConVarInt(z_mob_spawn_min_size_hell, GetConVarInt(g_cvar_Hell_MobMin));
	if (z_mob_spawn_max_size_hell) SetConVarInt(z_mob_spawn_max_size_hell, GetConVarInt(g_cvar_Hell_MobMax));
	if (z_mega_mob_size_hell) SetConVarInt(z_mega_mob_size_hell, GetConVarInt(g_cvar_Hell_MegaMob));
}

void Hell_RestoreDirector()
{
	if (z_common_limit_hell && g_iOrigCommonLimit_Hell != -1) SetConVarInt(z_common_limit_hell, g_iOrigCommonLimit_Hell);
	if (z_mob_spawn_min_size_hell && g_iOrigMobMin_Hell != -1) SetConVarInt(z_mob_spawn_min_size_hell, g_iOrigMobMin_Hell);
	if (z_mob_spawn_max_size_hell && g_iOrigMobMax_Hell != -1) SetConVarInt(z_mob_spawn_max_size_hell, g_iOrigMobMax_Hell);
	if (z_mega_mob_size_hell && g_iOrigMegaMob_Hell != -1) SetConVarInt(z_mega_mob_size_hell, g_iOrigMegaMob_Hell);
}

void Hell_ApplyLightStyle()
{
	char ls[8];
	GetConVarString(g_cvar_Hell_LightStyle, ls, sizeof(ls));
	if (ls[0]) SetLightStyle(0, ls);
}

void Hell_RestoreLightStyle()
{
	char ls[8];
	GetConVarString(g_cvar_Hell_LightStyleRestore, ls, sizeof(ls));
	if (ls[0]) SetLightStyle(0, ls);
}

int Hell_SpawnFogController()
{
	// Desactivar fog controllers nativos del mapa primero
	Hell_DisableMapFogControllers();

	int ent = CreateEntityByName("env_fog_controller");
	if (ent == -1) return -1;

	char color[32];
	GetConVarString(g_cvar_Hell_FogColor, color, sizeof(color));
	char density[16];
	FloatToString(GetConVarFloat(g_cvar_Hell_FogDensity), density, sizeof(density));
	char sStart[16];
	IntToString(GetConVarInt(g_cvar_Hell_FogStart), sStart, sizeof(sStart));
	char sEnd[16];
	IntToString(GetConVarInt(g_cvar_Hell_FogEnd), sEnd, sizeof(sEnd));

	DispatchKeyValue(ent, "fogcolor", color);
	DispatchKeyValue(ent, "fogstart", sStart);
	DispatchKeyValue(ent, "fogend", sEnd);
	DispatchKeyValue(ent, "fogmaxdensity", density);
	DispatchKeyValue(ent, "fogenable", "1");
	DispatchSpawn(ent);
	AcceptEntityInput(ent, "TurnOn");

	return ent;
}

/**
 * Desactiva fog controllers nativos del mapa que pueden interferir
 */
void Hell_DisableMapFogControllers()
{
	int entity = -1;
	int disabledCount = 0;
	while ((entity = FindEntityByClassname(entity, "env_fog_controller")) != -1)
	{
		// No tocar nuestro propio fog controller
		if (entity == EntRefToEntIndex(g_iFogRef_Hell))
			continue;

		// Desactivar fog controllers del mapa
		AcceptEntityInput(entity, "TurnOff");
		disabledCount++;
	}

	if (disabledCount > 0)
		LogMessage("[Hell] Disabled %d map fog controller(s)", disabledCount);
}

void Hell_RemoveFogController()
{
	int ent = EntRefToEntIndex(g_iFogRef_Hell);
	if (ent != -1 && IsValidEntity(ent))
	{
		// Solo eliminar la entidad sin TurnOff para evitar desvanecimiento
		RemoveEntity(ent);
	}
	g_iFogRef_Hell = -1;
}

void Hell_CreateAmbientParticles()
{
	g_iParticleTotal_Hell = 0;
	char pname[64];
	GetConVarString(g_cvar_Hell_ParticleName, pname, sizeof(pname));
	if (!pname[0]) return;

	int count = GetConVarInt(g_cvar_Hell_ParticleCount);
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

		g_iParticleRefs_Hell[g_iParticleTotal_Hell++] = EntIndexToEntRef(ent);
	}
}

void Hell_RemoveAmbientParticles()
{
	for (int i = 0; i < g_iParticleTotal_Hell; i++)
	{
		int ent = EntRefToEntIndex(g_iParticleRefs_Hell[i]);
		if (ent != -1 && IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "Stop");
			RemoveEntity(ent);
		}
	}
	g_iParticleTotal_Hell = 0;
}

void Hell_PlaySoundToAll(const char[] sample)
{
	if (!sample[0]) return;
	PrecacheSound(sample, true);
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			EmitSoundToClient(i, sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN, _, 1.0);
}

void Hell_StopSoundToAll(const char[] sample)
{
	if (!sample[0]) return;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			StopSound(i, SNDCHAN_STATIC, sample);
}

void Hell_DoScreenFadeAll(bool activate)
{
	if (!GetConVarBool(g_cvar_Hell_Fade)) return;

	int r = 255, g = 80, b = 20;  // Color naranja-rojo (fuego)
	int alpha = GetConVarInt(g_cvar_Hell_FadeAlpha);
	int duration = GetConVarInt(g_cvar_Hell_FadeDuration);
	int hold = activate ? 999999 : 0;  // Hold infinito cuando se activa, 0 cuando se desactiva

	// Purge previo
	Handle hPurge = StartMessageAll("Fade");
	if (hPurge != null)
	{
		BfWriteShort(hPurge, 0);
		BfWriteShort(hPurge, 0);
		BfWriteByte(hPurge, 0);
		BfWriteByte(hPurge, 0);
		BfWriteByte(hPurge, 0);
		BfWriteByte(hPurge, 0);
		BfWriteShort(hPurge, FFADE_PURGE);
		EndMessage();
	}

	int flags = activate ? (FFADE_IN | FFADE_STAYOUT) : FFADE_OUT;

	Handle hFade = StartMessageAll("Fade");
	if (hFade != null)
	{
		BfWriteShort(hFade, duration);
		BfWriteShort(hFade, hold);
		BfWriteByte(hFade, r);
		BfWriteByte(hFade, g);
		BfWriteByte(hFade, b);
		BfWriteByte(hFade, alpha);
		BfWriteShort(hFade, flags);
		EndMessage();
	}

	if (!activate)
	{
		CreateTimer(float(duration) / 1000.0 + 0.05, Hell_Timer_PurgeFadeOnce);
	}
}

public Action Hell_Timer_PurgeFadeOnce(Handle t, any data)
{
	Handle h = StartMessageAll("Fade");
	if (h != null)
	{
		BfWriteShort(h, 0);
		BfWriteShort(h, 0);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		BfWriteShort(h, FFADE_PURGE);
		EndMessage();
	}
	return Plugin_Stop;
}

void Hell_ApplyFogSettingsToEnt(int ent)
{
	if (ent == -1 || !IsValidEntity(ent)) return;

	char color[32];
	GetConVarString(g_cvar_Hell_FogColor, color, sizeof(color));
	SetVariantString(color);
	AcceptEntityInput(ent, "SetColor");

	int s = GetConVarInt(g_cvar_Hell_FogStart);
	int e = GetConVarInt(g_cvar_Hell_FogEnd);
	float d = GetConVarFloat(g_cvar_Hell_FogDensity);

	SetVariantInt(s);
	AcceptEntityInput(ent, "SetStartDist");
	SetVariantInt(e);
	AcceptEntityInput(ent, "SetEndDist");
	SetVariantFloat(d);
	AcceptEntityInput(ent, "SetMaxDensity");
	AcceptEntityInput(ent, "TurnOn");
}

int Hell_EnsureFogController()
{
	int ent = EntRefToEntIndex(g_iFogRef_Hell);
	if (ent == -1 || !IsValidEntity(ent))
	{
		ent = Hell_SpawnFogController();
		g_iFogRef_Hell = (ent != -1) ? EntIndexToEntRef(ent) : -1;
	}
	if (ent != -1 && IsValidEntity(ent))
	{
		Hell_ApplyFogSettingsToEnt(ent);
	}
	return ent;
}

public Action Hell_Timer_FogEnforcer(Handle timer, any data)
{
	if (!g_bHellActive || !GetConVarBool(g_cvar_Hell_FogEnable))
		return Plugin_Continue;

	Hell_EnsureFogController();
	return Plugin_Continue;
}

void Hell_StartFogEnforcerTimer()
{
	if (g_hFogTimer_Hell == null)
	{
		float tick = GetConVarFloat(g_cvar_Hell_FogTick);
		if (tick < 1.0) tick = 1.0;
		g_hFogTimer_Hell = CreateTimer(tick, Hell_Timer_FogEnforcer, _, TIMER_REPEAT);
	}
}

void Hell_StopFogEnforcerTimer()
{
	if (g_hFogTimer_Hell != null)
	{
		KillTimer(g_hFogTimer_Hell);
		g_hFogTimer_Hell = null;
	}
}

/**
 * Obtiene si Hell está activo
 */
public bool Hell_IsActive()
{
	return g_bHellActive;
}

/**
 * Utilidad para validar clientes
 */
bool hell_IsValidClient(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client));
}
