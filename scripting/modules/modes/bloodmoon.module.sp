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

// === NUEVAS CONVARS - Características Avanzadas ===
Handle g_cvar_Bloodmoon_TankSpawn = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_TankInterval = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_PanicEvents = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_PanicInterval = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ColorCorrection = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ColorFile = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_ColorWeight = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_UsePrecipitation = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_PrecipType = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_BreederEvents = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_BreederChance = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_MegaMobSound = INVALID_HANDLE;
Handle g_cvar_Bloodmoon_MegaMobSoundChance = INVALID_HANDLE;

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

// === NUEVAS VARIABLES - Sistemas Avanzados ===
Handle g_hEventTimer = null;						// Timer para eventos periódicos (tanks, panic, etc)
int	   g_iColorCorrectionRef = -1;					// Reference para color correction entity
int	   g_iFogVolumeRef = -1;						// Reference para fog_volume entity
int	   g_iPrecipitationRef = -1;					// Reference para func_precipitation entity
int	   g_iTankCount = 0;							// Contador de tanks vivos
float  g_fLastTankSpawn = 0.0;						// Timestamp del último spawn de tank
float  g_fLastPanicEvent = 0.0;						// Timestamp del último panic event
float  g_fMapStartTime = 0.0;						// Timestamp del inicio del mapa

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

	// === NUEVAS CONVARS - Características Avanzadas ===
	// Tank Spawning
	g_cvar_Bloodmoon_TankSpawn = CreateConVar("bloodmoon_tank_spawn", "1", "Spawn automático de tanks durante Bloodmoon", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Bloodmoon_TankInterval = CreateConVar("bloodmoon_tank_interval", "60.0", "Intervalo en segundos para spawn de tanks (0=disable)", FCVAR_PLUGIN, true, 0.0);

	// Panic Events
	g_cvar_Bloodmoon_PanicEvents = CreateConVar("bloodmoon_panic_events", "1", "Forzar panic events periódicos", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Bloodmoon_PanicInterval = CreateConVar("bloodmoon_panic_interval", "45.0", "Intervalo en segundos para panic events (0=disable)", FCVAR_PLUGIN, true, 0.0);

	// Color Correction
	g_cvar_Bloodmoon_ColorCorrection = CreateConVar("bloodmoon_color_correction", "1", "Usar color correction (post-processing)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Bloodmoon_ColorFile = CreateConVar("bloodmoon_color_file", "materials/correction/ghost.raw", "Archivo de color correction", FCVAR_PLUGIN);
	g_cvar_Bloodmoon_ColorWeight = CreateConVar("bloodmoon_color_weight", "0.4", "Intensidad del color correction (0.0-1.0)", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Precipitation
	g_cvar_Bloodmoon_UsePrecipitation = CreateConVar("bloodmoon_use_precipitation", "1", "Usar func_precipitation en vez de partículas", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Bloodmoon_PrecipType = CreateConVar("bloodmoon_precip_type", "3", "Tipo precipitación: 1=lluvia 2=ceniza 3=nieve 4=lluvia_l4d", FCVAR_PLUGIN, true, 1.0, true, 4.0);

	// Breeder Events
	g_cvar_Bloodmoon_BreederEvents = CreateConVar("bloodmoon_breeder_events", "1", "Spawn aleatorio de infectados especiales extra", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Bloodmoon_BreederChance = CreateConVar("bloodmoon_breeder_chance", "25", "Probabilidad 1/N de breeder event por tick (25=4%)", FCVAR_PLUGIN, true, 1.0);

	// Mega Mob Sound
	g_cvar_Bloodmoon_MegaMobSound = CreateConVar("bloodmoon_megamob_sound", "1", "Reproducir sonido de mega mob aleatorio", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_Bloodmoon_MegaMobSoundChance = CreateConVar("bloodmoon_megamob_sound_chance", "20", "Probabilidad 1/N de sonido por tick (20=5%)", FCVAR_PLUGIN, true, 1.0);

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

	// Hook de eventos
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("tank_killed", Event_TankKilled);

	// Comandos admin
	RegAdminCmd("sm_bloodmoon_on", Cmd_BloodmoonOn, ADMFLAG_GENERIC, "Activa Bloodmoon");
	RegAdminCmd("sm_bloodmoon_off", Cmd_BloodmoonOff, ADMFLAG_GENERIC, "Desactiva Bloodmoon");
	RegAdminCmd("sm_bloodmoon_toggle", Cmd_BloodmoonToggle, ADMFLAG_GENERIC, "Alterna Bloodmoon");
	RegAdminCmd("sm_bloodmoon_status", Cmd_BloodmoonStatus, ADMFLAG_GENERIC, "Estado Bloodmoon");
	RegAdminCmd("sm_bloodmoon_testmob", Cmd_BloodmoonTestMob, ADMFLAG_GENERIC, "Fuerza una horda");

	// Hook ConVar para detectar activación/desactivación
	HookConVarChange(g_cvar_Bloodmoon_Enable, Bloodmoon_ConVarChanged);

	g_sOrigDifficulty[0] = '\0';
	g_iFogRef = -1;
	g_iColorCorrectionRef = -1;
	g_iFogVolumeRef = -1;
	g_iPrecipitationRef = -1;

	// Inicializar array de referencias de partículas
	for (int i = 0; i < 16; i++)
		g_iParticleRefs[i] = -1;
}

/**
 * Hook cuando un mapa inicia
 */
public void Bloodmoon_OnMapStart()
{
	g_iOrigCommonLimit = g_iOrigMobMin = g_iOrigMobMax = g_iOrigMegaMob = -1;
	g_fMapStartTime = GetGameTime();
	g_iTankCount = 0;

	// Reset comprehensivo de estado para nuevo mapa
	g_fLastTankSpawn = 0.0;
	g_fLastPanicEvent = 0.0;
	g_iParticleTotal = 0;

	// Reset de referencias de entidades
	g_iFogRef = -1;
	g_iColorCorrectionRef = -1;
	g_iFogVolumeRef = -1;
	g_iPrecipitationRef = -1;

	// Reset array de partículas
	for (int i = 0; i < 16; i++)
		g_iParticleRefs[i] = -1;

	// Precache del sonido mega mob
	PrecacheSound("npc/mega_mob/mega_mob_incoming.wav", true);
}

/**
 * Callback cuando cambia el ConVar de enable
 */
public void Bloodmoon_ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_cvar_Bloodmoon_Enable)
	{
		bool bNewState = GetConVarBool(g_cvar_Bloodmoon_Enable);

		LogMessage("[Bloodmoon] ConVar changed from '%s' to '%s' (state: %d)", oldValue, newValue, bNewState);

		if (bNewState && !g_bBloodmoonActive)
		{
			LogMessage("[Bloodmoon] Activating Bloodmoon mode...");
			Bloodmoon_Activate("convar");
		}
		else if (!bNewState && g_bBloodmoonActive)
		{
			LogMessage("[Bloodmoon] Deactivating Bloodmoon mode...");
			Bloodmoon_Deactivate("convar");
		}
	}
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
 * Hook de daño - Multiplicador de Bloodmoon
 */
public Action Bloodmoon_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_bBloodmoonActive) return Plugin_Continue;
	if (!bloodmoon_IsValidClient(victim) || GetClientTeam(victim) != 2) return Plugin_Continue;

	float mult = GetConVarFloat(g_cvar_Bloodmoon_DmgMult);
	if (mult <= 1.0) return Plugin_Continue;

	bool fromSpecial = (bloodmoon_IsValidClient(attacker) && GetClientTeam(attacker) == 3);
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
 * Event: player_death - Detecta muerte de jugadores infectados
 */
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bBloodmoonActive) return;

	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (victim <= 0 || !IsClientInGame(victim)) return;

	// Si es un tank, decrementar contador
	if (GetClientTeam(victim) == 3 && GetEntProp(victim, Prop_Send, "m_zombieClass") == 8)
	{
		if (g_iTankCount > 0) g_iTankCount--;
	}
}

/**
 * Event: tank_killed - Detecta muerte de tanks (backup)
 */
public void Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bBloodmoonActive) return;
	if (g_iTankCount > 0) g_iTankCount--;
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
	if (g_bBloodmoonActive)
	{
		LogMessage("[Bloodmoon] Already active, skipping activation");
		return;
	}

	LogMessage("[Bloodmoon] ============ ACTIVATION START ============");
	LogMessage("[Bloodmoon] Reason: %s", reason);

	#pragma unused reason

	Bloodmoon_CacheOriginalDirector();
	Bloodmoon_ApplyDirector();

	g_bBloodmoonActive = true;
	g_fLastTankSpawn = GetGameTime();
	g_fLastPanicEvent = GetGameTime();
	g_iTankCount = 0;

	// Ambientación
	LogMessage("[Bloodmoon] Applying light style...");
	Bloodmoon_ApplyLightStyle();

	// === NUEVOS SISTEMAS ===

	// Color Correction (post-processing visual)
	if (GetConVarBool(g_cvar_Bloodmoon_ColorCorrection))
	{
		char colorFile[PLATFORM_MAX_PATH];
		GetConVarString(g_cvar_Bloodmoon_ColorFile, colorFile, sizeof(colorFile));
		float weight = GetConVarFloat(g_cvar_Bloodmoon_ColorWeight);
		LogMessage("[Bloodmoon] Creating color correction: file=%s, weight=%.2f", colorFile, weight);
		Bloodmoon_CreateColorCorrection(colorFile, weight);
	}
	else
	{
		LogMessage("[Bloodmoon] Color correction disabled");
	}

	// Precipitation system (nieve/lluvia en todo el mapa)
	if (GetConVarBool(g_cvar_Bloodmoon_UsePrecipitation))
	{
		int precipType = GetConVarInt(g_cvar_Bloodmoon_PrecipType);
		LogMessage("[Bloodmoon] Creating precipitation: type=%d", precipType);
		Bloodmoon_CreatePrecipitation(precipType);
	}
	else
	{
		LogMessage("[Bloodmoon] Creating ambient particles...");
		// Usar el sistema de partículas antiguo
		Bloodmoon_CreateAmbientParticles();
	}

	// Fog controller
	if (GetConVarBool(g_cvar_Bloodmoon_FogEnable))
	{
		LogMessage("[Bloodmoon] Creating fog controller...");
		int ent = Bloodmoon_SpawnFogController();
		g_iFogRef = (ent != -1) ? EntIndexToEntRef(ent) : -1;
		LogMessage("[Bloodmoon] Fog entity: %d (ref: %d)", ent, g_iFogRef);
		Bloodmoon_StartFogEnforcerTimer();
	}
	else
	{
		LogMessage("[Bloodmoon] Fog disabled");
	}

	// Iniciar timer de eventos periódicos (tanks, panic, breeder, sonidos)
	LogMessage("[Bloodmoon] Starting event timer...");
	Bloodmoon_StartEventTimer();

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
		LogMessage("[Bloodmoon] Changing difficulty to Impossible...");
		ServerCommand("z_difficulty Impossible");

		// Verify the change
		char currentDiff[32];
		GetConVarString(z_difficulty, currentDiff, sizeof(currentDiff));
		LogMessage("[Bloodmoon] Current z_difficulty after command: %s", currentDiff);
	}
	else
	{
		LogMessage("[Bloodmoon] Difficulty change disabled");
	}

	LogMessage("[Bloodmoon] ============ ACTIVATION COMPLETE ============");
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

	// Resetear variables de estado para reactivación limpia
	g_iTankCount = 0;
	g_fLastTankSpawn = 0.0;
	g_fLastPanicEvent = 0.0;

	// === LIMPIAR NUEVOS SISTEMAS ===
	Bloodmoon_StopEventTimer();
	Bloodmoon_RemoveColorCorrection();
	Bloodmoon_RemovePrecipitation();

	// Limpiar sistemas antiguos
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
	LogMessage("[Bloodmoon] Creating env_fog_controller entity...");

	int ent = CreateEntityByName("env_fog_controller");
	if (ent == -1)
	{
		LogMessage("[Bloodmoon] ERROR: Failed to create env_fog_controller entity!");
		return -1;
	}

	LogMessage("[Bloodmoon] env_fog_controller entity created: %d", ent);

	char color[32];
	GetConVarString(g_cvar_Bloodmoon_FogColor, color, sizeof(color));
	char density[16];
	FloatToString(GetConVarFloat(g_cvar_Bloodmoon_FogDensity), density, sizeof(density));
	char sStart[16];
	IntToString(GetConVarInt(g_cvar_Bloodmoon_FogStart), sStart, sizeof(sStart));
	char sEnd[16];
	IntToString(GetConVarInt(g_cvar_Bloodmoon_FogEnd), sEnd, sizeof(sEnd));

	LogMessage("[Bloodmoon] Fog settings: color=%s, density=%s, start=%s, end=%s", color, density, sStart, sEnd);

	DispatchKeyValue(ent, "fogcolor", color);
	DispatchKeyValue(ent, "fogstart", sStart);
	DispatchKeyValue(ent, "fogend", sEnd);
	DispatchKeyValue(ent, "fogmaxdensity", density);
	DispatchKeyValue(ent, "fogenable", "1");
	DispatchSpawn(ent);
	AcceptEntityInput(ent, "TurnOn");

	LogMessage("[Bloodmoon] env_fog_controller spawned and activated");

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
		// Invalidar la referencia después de remover
		g_iParticleRefs[i] = -1;
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
bool bloodmoon_IsValidClient(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client));
}

//==================================================
// === NUEVAS FUNCIONES - SISTEMAS AVANZADOS ===
//==================================================

/**
 * Inicia el timer de eventos periódicos
 * Maneja: Tank spawning, Panic events, Breeder events, Mega mob sounds
 */
void Bloodmoon_StartEventTimer()
{
	if (g_hEventTimer == null)
	{
		// Timer cada 5 segundos para verificar eventos
		g_hEventTimer = CreateTimer(5.0, Bloodmoon_Timer_Events, _, TIMER_REPEAT);
	}
}

/**
 * Detiene el timer de eventos periódicos
 */
void Bloodmoon_StopEventTimer()
{
	if (g_hEventTimer != null)
	{
		KillTimer(g_hEventTimer);
		g_hEventTimer = null;
	}
}

/**
 * Timer principal de eventos periódicos
 */
public Action Bloodmoon_Timer_Events(Handle timer)
{
	if (!g_bBloodmoonActive)
		return Plugin_Continue;

	float currentTime = GetGameTime();
	float mapElapsed = currentTime - g_fMapStartTime;

	// No ejecutar eventos inmediatamente al inicio del mapa
	if (mapElapsed < 10.0)
		return Plugin_Continue;

	// 1. Tank Spawning
	if (GetConVarBool(g_cvar_Bloodmoon_TankSpawn))
	{
		float tankInterval = GetConVarFloat(g_cvar_Bloodmoon_TankInterval);
		if (tankInterval > 0.0 && (currentTime - g_fLastTankSpawn) >= tankInterval)
		{
			// Solo spawnear si no hay tanks vivos y no estamos en finale
			if (g_iTankCount < 1 && !Bloodmoon_IsFinaleActive())
			{
				Bloodmoon_SpawnTank();
				g_fLastTankSpawn = currentTime;
			}
		}
	}

	// 2. Panic Events
	if (GetConVarBool(g_cvar_Bloodmoon_PanicEvents))
	{
		float panicInterval = GetConVarFloat(g_cvar_Bloodmoon_PanicInterval);
		if (panicInterval > 0.0 && (currentTime - g_fLastPanicEvent) >= panicInterval)
		{
			Bloodmoon_ForcePanicEvent();
			g_fLastPanicEvent = currentTime;
		}
	}

	// 3. Breeder Events (aleatorio)
	if (GetConVarBool(g_cvar_Bloodmoon_BreederEvents))
	{
		int chance = GetConVarInt(g_cvar_Bloodmoon_BreederChance);
		if (chance > 0 && GetRandomInt(1, chance) == 1)
		{
			Bloodmoon_CreateBreederEvent();
		}
	}

	// 4. Mega Mob Sound (aleatorio)
	if (GetConVarBool(g_cvar_Bloodmoon_MegaMobSound))
	{
		int chance = GetConVarInt(g_cvar_Bloodmoon_MegaMobSoundChance);
		if (chance > 0 && GetRandomInt(1, chance) == 1)
		{
			EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN);
		}
	}

	return Plugin_Continue;
}

/**
 * Spawnea un Tank usando fake client
 * TODO: Agregar soporte para left4dhooks cuando esté disponible
 */
void Bloodmoon_SpawnTank()
{
	int bot = CreateFakeClient("Tank");
	if (bot > 0)
	{
		ChangeClientTeam(bot, 3);
		CreateTimer(0.1, Timer_SpawnTank, GetClientUserId(bot), TIMER_FLAG_NO_MAPCHANGE);
		g_iTankCount++;
	}
}

public Action Timer_SpawnTank(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client))
	{
		// Usar cheat para spawn de tank
		int flags = GetCommandFlags("z_spawn_old");
		SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "z_spawn_old tank auto");
		SetCommandFlags("z_spawn_old", flags);

		// Kickear el bot después de spawn
		CreateTimer(0.5, Timer_KickBot, userid);
	}
	return Plugin_Stop;
}

public Action Timer_KickBot(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client) && IsFakeClient(client))
	{
		KickClient(client);
	}
	return Plugin_Stop;
}

/**
 * Fuerza un panic event usando comando director
 * TODO: Agregar soporte para left4dhooks cuando esté disponible
 */
void Bloodmoon_ForcePanicEvent()
{
	// Usar comando director
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			int flags = GetCommandFlags("director_force_panic_event");
			SetCommandFlags("director_force_panic_event", flags & ~FCVAR_CHEAT);
			FakeClientCommand(i, "director_force_panic_event");
			SetCommandFlags("director_force_panic_event", flags);
			break;
		}
	}
}

/**
 * Crea un Breeder Event - spawnea 2 infectados especiales extra
 */
void Bloodmoon_CreateBreederEvent()
{
	for (int count = 0; count < 2; count++)
	{
		int bot = CreateFakeClient("Breeder");
		if (bot > 0)
		{
			ChangeClientTeam(bot, 3);
			CreateTimer(0.1, Timer_SpawnSpecial, GetClientUserId(bot), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_SpawnSpecial(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client))
	{
		// Spawn infectado aleatorio (smoker, hunter, boomer, spitter, jockey, charger)
		int zombieClass = GetRandomInt(1, 6);

		int flags = GetCommandFlags("z_spawn_old");
		SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);

		char cmd[64];
		char className[32];
		switch (zombieClass)
		{
			case 1: className = "smoker";
			case 2: className = "boomer";
			case 3: className = "hunter";
			case 4: className = "spitter";
			case 5: className = "jockey";
			case 6: className = "charger";
		}
		Format(cmd, sizeof(cmd), "z_spawn_old %s auto", className);
		FakeClientCommand(client, cmd);

		SetCommandFlags("z_spawn_old", flags);
		CreateTimer(0.5, Timer_KickBot, userid);
	}
	return Plugin_Stop;
}

/**
 * Verifica si el finale está activo
 */
bool Bloodmoon_IsFinaleActive()
{
	int ent = -1;
	ent = FindEntityByClassname(ent, "trigger_finale");
	return (ent != -1);
}

/**
 * Crea el sistema de Color Correction con fog_volume
 * Proporciona post-processing visual profesional
 */
void Bloodmoon_CreateColorCorrection(const char[] fileName, float weight)
{
	LogMessage("[Bloodmoon] Creating color_correction entity...");

	// 1. Crear color_correction entity
	int colorEnt = CreateEntityByName("color_correction");
	if (colorEnt == -1)
	{
		LogMessage("[Bloodmoon] ERROR: Failed to create color_correction entity!");
		return;
	}

	LogMessage("[Bloodmoon] color_correction entity created: %d", colorEnt);

	DispatchKeyValue(colorEnt, "spawnflags", "2");

	char sWeight[16];
	FloatToString(weight, sWeight, sizeof(sWeight));
	DispatchKeyValue(colorEnt, "maxweight", sWeight);
	DispatchKeyValue(colorEnt, "fadeInDuration", "4");
	DispatchKeyValue(colorEnt, "fadeOutDuration", "4");
	DispatchKeyValue(colorEnt, "maxfalloff", "-1");
	DispatchKeyValue(colorEnt, "minfalloff", "-1");
	DispatchKeyValue(colorEnt, "filename", fileName);

	char tName[16];
	Format(tName, sizeof(tName), "CC%d", colorEnt);
	DispatchKeyValue(colorEnt, "targetname", tName);

	DispatchSpawn(colorEnt);
	ActivateEntity(colorEnt);
	AcceptEntityInput(colorEnt, "Enable");

	float origin[3] = {0.0, 0.0, 0.0};
	TeleportEntity(colorEnt, origin, NULL_VECTOR, NULL_VECTOR);

	// Validate entity index is in valid range and entity is valid
	if (colorEnt > 0 && IsValidEntity(colorEnt))
	{
		g_iColorCorrectionRef = EntIndexToEntRef(colorEnt);
		LogMessage("[Bloodmoon] color_correction spawned and enabled (ref: %d)", g_iColorCorrectionRef);
	}
	else
	{
		LogMessage("[Bloodmoon] ERROR: color_correction entity became invalid after spawn (index: %d)!", colorEnt);
		g_iColorCorrectionRef = -1;
	}

	// 2. Crear fog_volume para aplicar color correction globalmente
	LogMessage("[Bloodmoon] Creating fog_volume entity for color correction...");
	int fogVolEnt = CreateEntityByName("fog_volume");
	if (fogVolEnt == -1)
	{
		LogMessage("[Bloodmoon] ERROR: Failed to create fog_volume entity!");
		return;
	}

	LogMessage("[Bloodmoon] fog_volume entity created: %d", fogVolEnt);

	DispatchKeyValue(fogVolEnt, "targetname", "bloodmoon_fogvolume");
	DispatchKeyValue(fogVolEnt, "ColorCorrectionName", tName);

	// Usar DispatchKeyValue en vez de SetEntPropVector (más seguro)
	DispatchKeyValue(fogVolEnt, "mins", "-10000 -10000 -10000");
	DispatchKeyValue(fogVolEnt, "maxs", "10000 10000 10000");

	DispatchSpawn(fogVolEnt);
	ActivateEntity(fogVolEnt);

	// Validate entity index is in valid range and entity is valid
	if (fogVolEnt > 0 && IsValidEntity(fogVolEnt))
	{
		g_iFogVolumeRef = EntIndexToEntRef(fogVolEnt);
		LogMessage("[Bloodmoon] fog_volume spawned (ref: %d)", g_iFogVolumeRef);
	}
	else
	{
		LogMessage("[Bloodmoon] ERROR: fog_volume entity became invalid after spawn (index: %d)!", fogVolEnt);
		g_iFogVolumeRef = -1;
	}

	// Desactivar otros fog_volume entities
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "fog_volume")) != -1)
	{
		if (entity != fogVolEnt)
		{
			AcceptEntityInput(entity, "Disable");
		}
	}
}

/**
 * Remueve el sistema de Color Correction
 */
void Bloodmoon_RemoveColorCorrection()
{
	int ent = EntRefToEntIndex(g_iColorCorrectionRef);
	if (ent != -1 && IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "Disable");
		RemoveEntity(ent);
	}
	g_iColorCorrectionRef = -1;

	ent = EntRefToEntIndex(g_iFogVolumeRef);
	if (ent != -1 && IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "Disable");
		RemoveEntity(ent);
	}
	g_iFogVolumeRef = -1;
}

/**
 * Crea func_precipitation (nieve/lluvia en TODO el mapa)
 * Mucho más eficiente que partículas localizadas
 */
void Bloodmoon_CreatePrecipitation(int precipType)
{
	int entity = CreateEntityByName("func_precipitation");
	if (entity == -1) return;

	// Obtener el modelo BSP del mapa actual
	char mapName[PLATFORM_MAX_PATH];
	char mapPath[PLATFORM_MAX_PATH];
	GetCurrentMap(mapName, sizeof(mapName));
	Format(mapPath, sizeof(mapPath), "maps/%s.bsp", mapName);
	PrecacheModel(mapPath, true);

	DispatchKeyValue(entity, "model", mapPath);

	// Tipo de precipitación: 1=lluvia, 2=ceniza, 3=nieve, 4=lluvia L4D
	char sType[4];
	IntToString(precipType, sType, sizeof(sType));
	DispatchKeyValue(entity, "preciptype", sType);

	// Obtener boundaries del mundo para cubrir TODO el mapa
	float vMins[3], vMaxs[3], vOrigin[3];
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
	GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);

	SetEntPropVector(entity, Prop_Send, "m_vecMins", vMins);
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vMaxs);

	// Posicionar en el centro del mapa
	vOrigin[0] = (vMins[0] + vMaxs[0]) / 2.0;
	vOrigin[1] = (vMins[1] + vMaxs[1]) / 2.0;
	vOrigin[2] = (vMins[2] + vMaxs[2]) / 2.0;

	DispatchSpawn(entity);
	ActivateEntity(entity);
	TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);

	g_iPrecipitationRef = EntIndexToEntRef(entity);
}

/**
 * Remueve func_precipitation
 */
void Bloodmoon_RemovePrecipitation()
{
	int ent = EntRefToEntIndex(g_iPrecipitationRef);
	if (ent != -1 && IsValidEntity(ent))
	{
		RemoveEntity(ent);
	}
	g_iPrecipitationRef = -1;
}
