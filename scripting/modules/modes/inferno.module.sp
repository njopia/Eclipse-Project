#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === INFERNO MODE MODULE ===
// Modo infernal supremo con fuego devastador
// El modo más difícil - multiplicador máximo de daño, hordas masivas
//==================================================

// ConVars del módulo
Handle g_cvar_Inferno_Enable = INVALID_HANDLE;
Handle g_cvar_Inferno_DmgMult = INVALID_HANDLE;
Handle g_cvar_Inferno_Fade = INVALID_HANDLE;
Handle g_cvar_Inferno_ChangeDiff = INVALID_HANDLE;
Handle g_cvar_Inferno_CommonLimit = INVALID_HANDLE;
Handle g_cvar_Inferno_MobMin = INVALID_HANDLE;
Handle g_cvar_Inferno_MobMax = INVALID_HANDLE;
Handle g_cvar_Inferno_MegaMob = INVALID_HANDLE;
Handle g_cvar_Inferno_LightStyle = INVALID_HANDLE;
Handle g_cvar_Inferno_LightStyleRestore = INVALID_HANDLE;
Handle g_cvar_Inferno_FogEnable = INVALID_HANDLE;
Handle g_cvar_Inferno_FogColor = INVALID_HANDLE;
Handle g_cvar_Inferno_FogStart = INVALID_HANDLE;
Handle g_cvar_Inferno_FogEnd = INVALID_HANDLE;
Handle g_cvar_Inferno_FogDensity = INVALID_HANDLE;
Handle g_cvar_Inferno_ParticleName = INVALID_HANDLE;
Handle g_cvar_Inferno_ParticleCount = INVALID_HANDLE;
Handle g_cvar_Inferno_SoundStart = INVALID_HANDLE;
Handle g_cvar_Inferno_SoundLoop = INVALID_HANDLE;
Handle g_cvar_Inferno_DebugDamage = INVALID_HANDLE;
Handle g_cvar_Inferno_FadeAlpha = INVALID_HANDLE;
Handle g_cvar_Inferno_FadeDuration = INVALID_HANDLE;
Handle g_cvar_Inferno_FogTick = INVALID_HANDLE;

// ConVars del juego (compartidas con Bloodmoon/Hell)
Handle z_common_limit_inferno = INVALID_HANDLE;
Handle z_mob_spawn_min_size_inferno = INVALID_HANDLE;
Handle z_mob_spawn_max_size_inferno = INVALID_HANDLE;
Handle z_mega_mob_size_inferno = INVALID_HANDLE;
Handle z_difficulty_inferno = INVALID_HANDLE;

// Backups
int	   g_iOrigCommonLimit_Inferno = -1;
int	   g_iOrigMobMin_Inferno = -1;
int	   g_iOrigMobMax_Inferno = -1;
int	   g_iOrigMegaMob_Inferno = -1;
char   g_sOrigDifficulty_Inferno[16];

// Estado
bool   g_bInfernoActive = false;
int	   g_iParticleRefs_Inferno[16];
int	   g_iParticleTotal_Inferno = 0;
int	   g_iFogRef_Inferno = -1;
Handle g_hFogTimer_Inferno = null;

/**
 * Inicializa el módulo de Inferno
 */
public void Inferno_OnPluginStart()
{
	// ConVars principales
	g_cvar_Inferno_Enable = CreateConVar("inferno_enable", "1", "Habilita el sistema de Inferno Mode", FCVAR_PLUGIN);
	g_cvar_Inferno_DmgMult = CreateConVar("inferno_damage_mult", "2.0", "Multiplicador de daño a Survivors", FCVAR_PLUGIN);
	g_cvar_Inferno_Fade = CreateConVar("inferno_fade", "1", "Fade amarillo-naranja persistente", FCVAR_PLUGIN);
	g_cvar_Inferno_ChangeDiff = CreateConVar("inferno_change_difficulty", "1", "Cambiar a Experto", FCVAR_PLUGIN);

	// Director
	g_cvar_Inferno_CommonLimit = CreateConVar("inferno_common_limit", "60", "z_common_limit durante Inferno Mode", FCVAR_PLUGIN);
	g_cvar_Inferno_MobMin = CreateConVar("inferno_mob_min", "35", "z_mob_spawn_min_size", FCVAR_PLUGIN);
	g_cvar_Inferno_MobMax = CreateConVar("inferno_mob_max", "50", "z_mob_spawn_max_size", FCVAR_PLUGIN);
	g_cvar_Inferno_MegaMob = CreateConVar("inferno_mega_mob", "80", "z_mega_mob_size", FCVAR_PLUGIN);

	// Ambientación
	g_cvar_Inferno_LightStyle = CreateConVar("inferno_lightstyle", "c", "LightStyle a aplicar", FCVAR_PLUGIN);
	g_cvar_Inferno_LightStyleRestore = CreateConVar("inferno_lightstyle_restore", "m", "LightStyle a restaurar", FCVAR_PLUGIN);
	g_cvar_Inferno_FogEnable = CreateConVar("inferno_fog_enable", "1", "Crear Fog", FCVAR_PLUGIN);
	g_cvar_Inferno_FogColor = CreateConVar("inferno_fog_color", "255 150 0", "Color Fog 'r g b'", FCVAR_PLUGIN);
	g_cvar_Inferno_FogStart = CreateConVar("inferno_fog_start", "30", "Fog start distance", FCVAR_PLUGIN);
	g_cvar_Inferno_FogEnd = CreateConVar("inferno_fog_end", "800", "Fog end distance", FCVAR_PLUGIN);
	g_cvar_Inferno_FogDensity = CreateConVar("inferno_fog_density", "0.85", "Fog max density 0..1", FCVAR_PLUGIN);
	g_cvar_Inferno_ParticleName = CreateConVar("inferno_particle", "env_fire_medium_smoke", "Partícula ambiental", FCVAR_PLUGIN);
	g_cvar_Inferno_ParticleCount = CreateConVar("inferno_particle_count", "6", "Cantidad de emisores", FCVAR_PLUGIN);
	g_cvar_Inferno_SoundStart = CreateConVar("inferno_sound_start", "", "Sonido al activar", FCVAR_PLUGIN);
	g_cvar_Inferno_SoundLoop = CreateConVar("inferno_sound_loop", "", "Sonido loop", FCVAR_PLUGIN);
	g_cvar_Inferno_FadeAlpha = CreateConVar("inferno_fade_alpha", "130", "Alpha del overlay naranja-amarillo 0..255", FCVAR_PLUGIN);
	g_cvar_Inferno_FadeDuration = CreateConVar("inferno_fade_duration", "1500", "Duración ms de transición", FCVAR_PLUGIN);
	g_cvar_Inferno_FogTick = CreateConVar("inferno_fog_tick", "3.0", "Intervalo para re-aplicar fog", FCVAR_PLUGIN);

	// Debug
	g_cvar_Inferno_DebugDamage = CreateConVar("inferno_debug_damage", "0", "Debug de daño", FCVAR_PLUGIN);

	// Obtener ConVars del juego
	z_common_limit_inferno = FindConVar("z_common_limit");
	z_mob_spawn_min_size_inferno = FindConVar("z_mob_spawn_min_size");
	z_mob_spawn_max_size_inferno = FindConVar("z_mob_spawn_max_size");
	z_mega_mob_size_inferno = FindConVar("z_mega_mob_size");
	z_difficulty_inferno = FindConVar("z_difficulty");

	// Hooks de daño
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, Inferno_OnTakeDamage);

	// Comandos admin
	RegAdminCmd("sm_inferno_on", Cmd_InfernoOn, ADMFLAG_GENERIC, "Activa Inferno Mode");
	RegAdminCmd("sm_inferno_off", Cmd_InfernoOff, ADMFLAG_GENERIC, "Desactiva Inferno Mode");
	RegAdminCmd("sm_inferno_toggle", Cmd_InfernoToggle, ADMFLAG_GENERIC, "Alterna Inferno Mode");
	RegAdminCmd("sm_inferno_status", Cmd_InfernoStatus, ADMFLAG_GENERIC, "Estado Inferno Mode");

	// Hook ConVar para detectar activación/desactivación
	HookConVarChange(g_cvar_Inferno_Enable, Inferno_ConVarChanged);

	g_sOrigDifficulty_Inferno[0] = '\0';
	g_iFogRef_Inferno = -1;
}

/**
 * Callback cuando cambia el ConVar de enable
 */
public void Inferno_ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_cvar_Inferno_Enable)
	{
		bool bNewState = GetConVarBool(g_cvar_Inferno_Enable);

		LogMessage("[Inferno] ConVar changed from '%s' to '%s' (state: %d)", oldValue, newValue, bNewState);

		if (bNewState && !g_bInfernoActive)
		{
			LogMessage("[Inferno] Activating Inferno mode...");
			Inferno_Activate("convar");
		}
		else if (!bNewState && g_bInfernoActive)
		{
			LogMessage("[Inferno] Deactivating Inferno mode...");
			Inferno_Deactivate("convar");
		}
	}
}

/**
 * Hook cuando un cliente se conecta
 */
public void Inferno_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Inferno_OnTakeDamage);
}

/**
 * Hook cuando un cliente se desconecta
 */
public void Inferno_OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Inferno_OnTakeDamage);
}

/**
 * Al inicio del mapa
 */
public void Inferno_OnMapStart()
{
	g_iOrigCommonLimit_Inferno = g_iOrigMobMin_Inferno = g_iOrigMobMax_Inferno = g_iOrigMegaMob_Inferno = -1;
}

/**
 * Hook cuando un mapa termina
 */
public void Inferno_OnMapEnd()
{
	// Desactivar Inferno si está activo al cambiar de mapa
	if (g_bInfernoActive)
	{
		LogMessage("[Inferno] Map ending, deactivating Inferno");
		Inferno_Deactivate("map_end");
	}
}

/**
 * Hook de daño - Multiplicador de Inferno
 */
public Action Inferno_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_bInfernoActive) return Plugin_Continue;
	if (!inferno_IsValidClient(victim) || GetClientTeam(victim) != 2) return Plugin_Continue;

	float mult = GetConVarFloat(g_cvar_Inferno_DmgMult);
	if (mult <= 1.0) return Plugin_Continue;

	bool fromSpecial = (inferno_IsValidClient(attacker) && GetClientTeam(attacker) == 3);
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
		if (GetConVarBool(g_cvar_Inferno_DebugDamage))
		{
			char vName[64];
			GetClientName(victim, vName, sizeof(vName));
			PrintToChatAll("\x05[Inferno:DMG]\x01 %s recibió %.1f daño (mult=%.2f)", vName, damage, mult);
		}
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

/**
 * Comandos admin
 */
public Action Cmd_InfernoOn(int client, int args)
{
	if (!GetConVarBool(g_cvar_Inferno_Enable))
	{
		ReplyToCommand(client, "[Inferno] Sistema deshabilitado");
		return Plugin_Handled;
	}
	Inferno_Activate("comando admin");
	ReplyToCommand(client, "[Inferno] ACTIVADO");
	return Plugin_Handled;
}

public Action Cmd_InfernoOff(int client, int args)
{
	Inferno_Deactivate("comando admin");
	ReplyToCommand(client, "[Inferno] DESACTIVADO");
	return Plugin_Handled;
}

public Action Cmd_InfernoToggle(int client, int args)
{
	if (g_bInfernoActive)
		return Cmd_InfernoOff(client, args);
	return Cmd_InfernoOn(client, args);
}

public Action Cmd_InfernoStatus(int client, int args)
{
	char diff[16];
	if (z_difficulty_inferno) GetConVarString(z_difficulty_inferno, diff, sizeof(diff));

	ReplyToCommand(client, "[Inferno] Activo: %s | Mult: %.2f | Dificultad: %s",
		g_bInfernoActive ? "SI" : "NO",
		GetConVarFloat(g_cvar_Inferno_DmgMult),
		diff[0] ? diff : "n/a");
	return Plugin_Handled;
}

/**
 * Activa el modo Inferno
 */
void Inferno_Activate(const char[] reason = "manual")
{
	if (g_bInfernoActive) return;

	#pragma unused reason

	Inferno_CacheOriginalDirector();
	Inferno_ApplyDirector();

	g_bInfernoActive = true;

	// Ambientación
	Inferno_ApplyLightStyle();

	if (GetConVarBool(g_cvar_Inferno_FogEnable))
	{
		int ent = Inferno_SpawnFogController();
		g_iFogRef_Inferno = (ent != -1) ? EntIndexToEntRef(ent) : -1;
		Inferno_StartFogEnforcerTimer();
	}

	Inferno_CreateAmbientParticles();

	char sStart[128], sLoop[128];
	GetConVarString(g_cvar_Inferno_SoundStart, sStart, sizeof(sStart));
	GetConVarString(g_cvar_Inferno_SoundLoop, sLoop, sizeof(sLoop));
	if (sStart[0]) Inferno_PlaySoundToAll(sStart);
	if (sLoop[0]) Inferno_PlaySoundToAll(sLoop);

	Inferno_DoScreenFadeAll(true);

	PrintToChatAll("\x04[Inferno]\x01 ¡INFERNO SUPREMO ACTIVADO! El fuego eterno te aguarda (mult=%.2f)",
		GetConVarFloat(g_cvar_Inferno_DmgMult));

	if (GetConVarBool(g_cvar_Inferno_ChangeDiff))
	{
		ServerCommand("z_difficulty Impossible");
	}
}

/**
 * Desactiva el modo Inferno
 */
void Inferno_Deactivate(const char[] reason = "manual")
{
	if (!g_bInfernoActive) return;

	#pragma unused reason

	Inferno_RestoreDirector();
	g_bInfernoActive = false;

	Inferno_RemoveAmbientParticles();
	Inferno_StopFogEnforcerTimer();
	Inferno_RemoveFogController();
	Inferno_RestoreLightStyle();

	char sLoop[128];
	GetConVarString(g_cvar_Inferno_SoundLoop, sLoop, sizeof(sLoop));
	if (sLoop[0]) Inferno_StopSoundToAll(sLoop);

	if (GetConVarBool(g_cvar_Inferno_ChangeDiff) && g_sOrigDifficulty_Inferno[0] != '\0')
	{
		ServerCommand("z_difficulty %s", g_sOrigDifficulty_Inferno);
	}

	Inferno_DoScreenFadeAll(false);
	PrintToChatAll("\x04[Inferno]\x01 Inferno DESACTIVADO. Has sobrevivido al fuego eterno.");
}

// ==================== FUNCIONES DE SOPORTE ====================

void Inferno_CacheOriginalDirector()
{
	if (g_iOrigCommonLimit_Inferno == -1 && z_common_limit_inferno != null)
		g_iOrigCommonLimit_Inferno = GetConVarInt(z_common_limit_inferno);
	if (g_iOrigMobMin_Inferno == -1 && z_mob_spawn_min_size_inferno != null)
		g_iOrigMobMin_Inferno = GetConVarInt(z_mob_spawn_min_size_inferno);
	if (g_iOrigMobMax_Inferno == -1 && z_mob_spawn_max_size_inferno != null)
		g_iOrigMobMax_Inferno = GetConVarInt(z_mob_spawn_max_size_inferno);
	if (g_iOrigMegaMob_Inferno == -1 && z_mega_mob_size_inferno != null)
		g_iOrigMegaMob_Inferno = GetConVarInt(z_mega_mob_size_inferno);
	if (g_sOrigDifficulty_Inferno[0] == '\0' && z_difficulty_inferno != null)
		GetConVarString(z_difficulty_inferno, g_sOrigDifficulty_Inferno, sizeof(g_sOrigDifficulty_Inferno));
}

void Inferno_ApplyDirector()
{
	if (z_common_limit_inferno) SetConVarInt(z_common_limit_inferno, GetConVarInt(g_cvar_Inferno_CommonLimit));
	if (z_mob_spawn_min_size_inferno) SetConVarInt(z_mob_spawn_min_size_inferno, GetConVarInt(g_cvar_Inferno_MobMin));
	if (z_mob_spawn_max_size_inferno) SetConVarInt(z_mob_spawn_max_size_inferno, GetConVarInt(g_cvar_Inferno_MobMax));
	if (z_mega_mob_size_inferno) SetConVarInt(z_mega_mob_size_inferno, GetConVarInt(g_cvar_Inferno_MegaMob));
}

void Inferno_RestoreDirector()
{
	if (z_common_limit_inferno && g_iOrigCommonLimit_Inferno != -1) SetConVarInt(z_common_limit_inferno, g_iOrigCommonLimit_Inferno);
	if (z_mob_spawn_min_size_inferno && g_iOrigMobMin_Inferno != -1) SetConVarInt(z_mob_spawn_min_size_inferno, g_iOrigMobMin_Inferno);
	if (z_mob_spawn_max_size_inferno && g_iOrigMobMax_Inferno != -1) SetConVarInt(z_mob_spawn_max_size_inferno, g_iOrigMobMax_Inferno);
	if (z_mega_mob_size_inferno && g_iOrigMegaMob_Inferno != -1) SetConVarInt(z_mega_mob_size_inferno, g_iOrigMegaMob_Inferno);
}

void Inferno_ApplyLightStyle()
{
	char ls[8];
	GetConVarString(g_cvar_Inferno_LightStyle, ls, sizeof(ls));
	if (ls[0]) SetLightStyle(0, ls);
}

void Inferno_RestoreLightStyle()
{
	char ls[8];
	GetConVarString(g_cvar_Inferno_LightStyleRestore, ls, sizeof(ls));
	if (ls[0]) SetLightStyle(0, ls);
}

int Inferno_SpawnFogController()
{
	// Desactivar fog controllers nativos del mapa primero
	Inferno_DisableMapFogControllers();

	int ent = CreateEntityByName("env_fog_controller");
	if (ent == -1) return -1;

	char color[32];
	GetConVarString(g_cvar_Inferno_FogColor, color, sizeof(color));
	char density[16];
	FloatToString(GetConVarFloat(g_cvar_Inferno_FogDensity), density, sizeof(density));
	char sStart[16];
	IntToString(GetConVarInt(g_cvar_Inferno_FogStart), sStart, sizeof(sStart));
	char sEnd[16];
	IntToString(GetConVarInt(g_cvar_Inferno_FogEnd), sEnd, sizeof(sEnd));

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
void Inferno_DisableMapFogControllers()
{
	int entity = -1;
	int disabledCount = 0;
	while ((entity = FindEntityByClassname(entity, "env_fog_controller")) != -1)
	{
		// No tocar nuestro propio fog controller
		if (entity == EntRefToEntIndex(g_iFogRef_Inferno))
			continue;

		// Desactivar fog controllers del mapa
		AcceptEntityInput(entity, "TurnOff");
		disabledCount++;
	}

	if (disabledCount > 0)
		LogMessage("[Inferno] Disabled %d map fog controller(s)", disabledCount);
}

void Inferno_RemoveFogController()
{
	int ent = EntRefToEntIndex(g_iFogRef_Inferno);
	if (ent != -1 && IsValidEntity(ent))
	{
		// Solo eliminar la entidad sin TurnOff para evitar desvanecimiento
		RemoveEntity(ent);
	}
	g_iFogRef_Inferno = -1;
}

void Inferno_CreateAmbientParticles()
{
	g_iParticleTotal_Inferno = 0;
	char pname[64];
	GetConVarString(g_cvar_Inferno_ParticleName, pname, sizeof(pname));
	if (!pname[0]) return;

	int count = GetConVarInt(g_cvar_Inferno_ParticleCount);
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

		g_iParticleRefs_Inferno[g_iParticleTotal_Inferno++] = EntIndexToEntRef(ent);
	}
}

void Inferno_RemoveAmbientParticles()
{
	for (int i = 0; i < g_iParticleTotal_Inferno; i++)
	{
		int ent = EntRefToEntIndex(g_iParticleRefs_Inferno[i]);
		if (ent != -1 && IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "Stop");
			RemoveEntity(ent);
		}
	}
	g_iParticleTotal_Inferno = 0;
}

void Inferno_PlaySoundToAll(const char[] sample)
{
	if (!sample[0]) return;
	PrecacheSound(sample, true);
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			EmitSoundToClient(i, sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN, _, 1.0);
}

void Inferno_StopSoundToAll(const char[] sample)
{
	if (!sample[0]) return;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			StopSound(i, SNDCHAN_STATIC, sample);
}

void Inferno_DoScreenFadeAll(bool activate)
{
	if (!GetConVarBool(g_cvar_Inferno_Fade)) return;

	int r = 255, g = 150, b = 0;  // Color amarillo-naranja (fuego intenso)
	int alpha = GetConVarInt(g_cvar_Inferno_FadeAlpha);
	int duration = GetConVarInt(g_cvar_Inferno_FadeDuration);
	int hold = 0;

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
		CreateTimer(float(duration) / 1000.0 + 0.05, Inferno_Timer_PurgeFadeOnce);
	}
}

public Action Inferno_Timer_PurgeFadeOnce(Handle t, any data)
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

void Inferno_ApplyFogSettingsToEnt(int ent)
{
	if (ent == -1 || !IsValidEntity(ent)) return;

	char color[32];
	GetConVarString(g_cvar_Inferno_FogColor, color, sizeof(color));
	SetVariantString(color);
	AcceptEntityInput(ent, "SetColor");

	int s = GetConVarInt(g_cvar_Inferno_FogStart);
	int e = GetConVarInt(g_cvar_Inferno_FogEnd);
	float d = GetConVarFloat(g_cvar_Inferno_FogDensity);

	SetVariantInt(s);
	AcceptEntityInput(ent, "SetStartDist");
	SetVariantInt(e);
	AcceptEntityInput(ent, "SetEndDist");
	SetVariantFloat(d);
	AcceptEntityInput(ent, "SetMaxDensity");
	AcceptEntityInput(ent, "TurnOn");
}

int Inferno_EnsureFogController()
{
	int ent = EntRefToEntIndex(g_iFogRef_Inferno);
	if (ent == -1 || !IsValidEntity(ent))
	{
		ent = Inferno_SpawnFogController();
		g_iFogRef_Inferno = (ent != -1) ? EntIndexToEntRef(ent) : -1;
	}
	if (ent != -1 && IsValidEntity(ent))
	{
		Inferno_ApplyFogSettingsToEnt(ent);
	}
	return ent;
}

public Action Inferno_Timer_FogEnforcer(Handle timer, any data)
{
	if (!g_bInfernoActive || !GetConVarBool(g_cvar_Inferno_FogEnable))
		return Plugin_Continue;

	Inferno_EnsureFogController();
	return Plugin_Continue;
}

void Inferno_StartFogEnforcerTimer()
{
	if (g_hFogTimer_Inferno == null)
	{
		float tick = GetConVarFloat(g_cvar_Inferno_FogTick);
		if (tick < 1.0) tick = 1.0;
		g_hFogTimer_Inferno = CreateTimer(tick, Inferno_Timer_FogEnforcer, _, TIMER_REPEAT);
	}
}

void Inferno_StopFogEnforcerTimer()
{
	if (g_hFogTimer_Inferno != null)
	{
		KillTimer(g_hFogTimer_Inferno);
		g_hFogTimer_Inferno = null;
	}
}

/**
 * Obtiene si Inferno está activo
 */
public bool Inferno_IsActive()
{
	return g_bInfernoActive;
}

/**
 * Utilidad para validar clientes
 */
bool inferno_IsValidClient(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client));
}
