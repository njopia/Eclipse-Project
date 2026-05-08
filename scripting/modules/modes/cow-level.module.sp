#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === COW LEVEL MODE MODULE ===
// Secret easter egg difficulty unlocked after beating Inferno twice
// Spawns decorative cow props, removes special infected, panic mode only
//==================================================

// Paths
#define CONFIG_COW_SPAWNS "data/cow_level.cfg"
#define MODEL_COWPILE "models/props_debris/dead_cow_smallpile.mdl"
#define MODEL_COW "models/props_debris/dead_cow.mdl"

// ConVars
Handle g_cvar_CowLevel_Enable = INVALID_HANDLE;
Handle g_cvar_CowLevel_PanicInterval = INVALID_HANDLE;
Handle g_cvar_CowLevel_ColorCorrection = INVALID_HANDLE;
Handle g_cvar_CowLevel_ColorFile = INVALID_HANDLE;
Handle g_cvar_CowLevel_ColorWeight = INVALID_HANDLE;
Handle g_cvar_CowLevel_MegaMobSound = INVALID_HANDLE;
Handle g_cvar_CowLevel_MegaMobSoundChance = INVALID_HANDLE;
Handle g_cvar_CowLevel_RemoveSpecials = INVALID_HANDLE;

// ConVars del juego
Handle z_common_limit_cowlevel = INVALID_HANDLE;
Handle z_mob_spawn_min_size_cowlevel = INVALID_HANDLE;
Handle z_mob_spawn_max_size_cowlevel = INVALID_HANDLE;
Handle z_mega_mob_size_cowlevel = INVALID_HANDLE;
Handle z_difficulty_cowlevel = INVALID_HANDLE;

// Backups
int	   g_iOrigCommonLimit_CowLevel = -1;
int	   g_iOrigMobMin_CowLevel = -1;
int	   g_iOrigMobMax_CowLevel = -1;
int	   g_iOrigMegaMob_CowLevel = -1;
char   g_sOrigDifficulty_CowLevel[16];

// Estado
bool   g_bCowLevelActive = false;
int    g_iCowLevel_ColorCorrectionRef = -1;
int    g_iCowLevel_FogVolumeRef = -1;
int    g_iCowLevelSpawns = 0;
float  g_fCowLevel_LastPanicEvent = 0.0;
float  g_fCowLevel_MapStartTime = 0.0;
Handle g_hCowLevel_EventTimer = null;

// Array para almacenar referencias de cows spawneadas
ArrayList g_aCowEntities = null;

/**
 * Inicializa el módulo de Cow Level
 */
public void CowLevel_OnPluginStart()
{
	// ConVars principales
	g_cvar_CowLevel_Enable = CreateConVar("cowlevel_enable", "0", "Habilita el Secret Cow Level", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_CowLevel_PanicInterval = CreateConVar("cowlevel_panic_interval", "45.0", "Intervalo en segundos para panic events (0=disable)", FCVAR_PLUGIN, true, 0.0);

	// Color Correction
	g_cvar_CowLevel_ColorCorrection = CreateConVar("cowlevel_color_correction", "1", "Usar color correction (post-processing)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_CowLevel_ColorFile = CreateConVar("cowlevel_color_file", "materials/correction/thirdstrike.raw", "Archivo de color correction", FCVAR_PLUGIN);
	g_cvar_CowLevel_ColorWeight = CreateConVar("cowlevel_color_weight", "0.5", "Intensidad del color correction (0.0-1.0)", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Mega Mob Sound
	g_cvar_CowLevel_MegaMobSound = CreateConVar("cowlevel_megamob_sound", "1", "Reproducir sonido de mega mob aleatorio", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvar_CowLevel_MegaMobSoundChance = CreateConVar("cowlevel_megamob_sound_chance", "15", "Probabilidad 1/N de sonido por tick (15=~6.7%)", FCVAR_PLUGIN, true, 1.0);

	// Special Infected Removal
	g_cvar_CowLevel_RemoveSpecials = CreateConVar("cowlevel_remove_specials", "1", "Remover infected especiales (solo zombies comunes)", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Obtener ConVars del juego
	z_common_limit_cowlevel = FindConVar("z_common_limit");
	z_mob_spawn_min_size_cowlevel = FindConVar("z_mob_spawn_min_size");
	z_mob_spawn_max_size_cowlevel = FindConVar("z_mob_spawn_max_size");
	z_mega_mob_size_cowlevel = FindConVar("z_mega_mob_size");
	z_difficulty_cowlevel = FindConVar("z_difficulty");

	// Inicializar array de entidades
	g_aCowEntities = new ArrayList();

	// Hook cambios de ConVar
	HookConVarChange(g_cvar_CowLevel_Enable, CowLevel_ConVarChanged);

	// Registrar comando admin
	RegAdminCmd("sm_cowlevel", Command_ToggleCowLevel, ADMFLAG_ROOT, "Toggle Secret Cow Level");

	g_sOrigDifficulty_CowLevel[0] = '\0';
}

/**
 * Callback cuando cambia el ConVar de enable
 */
public void CowLevel_ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_cvar_CowLevel_Enable)
	{
		bool bNewState = GetConVarBool(g_cvar_CowLevel_Enable);

		if (bNewState && !g_bCowLevelActive)
		{
			CowLevel_Activate();
		}
		else if (!bNewState && g_bCowLevelActive)
		{
			CowLevel_Deactivate();
		}
	}
}

/**
 * Llamado al inicio del mapa
 */
public void CowLevel_OnMapStart()
{
	g_fCowLevel_MapStartTime = GetGameTime();

	// Reset backups
	g_iOrigCommonLimit_CowLevel = g_iOrigMobMin_CowLevel = g_iOrigMobMax_CowLevel = g_iOrigMegaMob_CowLevel = -1;

	// Precache models
	PrecacheModel(MODEL_COW, true);
	PrecacheModel(MODEL_COWPILE, true);

	// Precache mega mob sound
	PrecacheSound("npc/mega_mob/mega_mob_incoming.wav", true);

	// Reset estado
	g_iCowLevelSpawns = 0;
	g_iCowLevel_ColorCorrectionRef = -1;
	g_iCowLevel_FogVolumeRef = -1;

	// Limpiar array de cows
	if (g_aCowEntities != null)
	{
		g_aCowEntities.Clear();
	}

	// Si está habilitado, activar
	if (GetConVarBool(g_cvar_CowLevel_Enable))
	{
		// Delay para que el mapa cargue completamente
		CreateTimer(3.0, Timer_DelayedActivation, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * Timer para activación con delay
 */
public Action Timer_DelayedActivation(Handle timer)
{
	if (GetConVarBool(g_cvar_CowLevel_Enable))
	{
		CowLevel_Activate();
	}
	return Plugin_Stop;
}

/**
 * Llamado al final del mapa
 */
public void CowLevel_OnMapEnd()
{
	CowLevel_Deactivate();
}

/**
 * Llamado cuando un cliente se conecta
 */
public void CowLevel_OnClientPutInServer(int client)
{
	// Si Cow Level está activo, aplicar efectos al cliente
	if (g_bCowLevelActive && !IsFakeClient(client))
	{
		CreateTimer(2.0, Timer_WelcomeToCowLevel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * Mensaje de bienvenida al Cow Level
 */
public Action Timer_WelcomeToCowLevel(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client))
	{
		SetGlobalTransTarget(client);
		char message[256];
		Format(message, sizeof(message), "%t", "CowLevel_Welcome");
		PrintToChat(client, "\x05[Eclipse]\x01 %s", message);
	}
	return Plugin_Stop;
}

/**
 * Comando admin para toggle Cow Level
 */
public Action Command_ToggleCowLevel(int client, int args)
{
	bool bCurrentState = GetConVarBool(g_cvar_CowLevel_Enable);
	SetConVarBool(g_cvar_CowLevel_Enable, !bCurrentState);

	char message[128];
	if (!bCurrentState)
	{
		SetGlobalTransTarget(client);
		Format(message, sizeof(message), "%t", "CowLevel_Activated");
		PrintToChat(client, "\x05[Admin]\x01 %s", message);
	}
	else
	{
		SetGlobalTransTarget(client);
		Format(message, sizeof(message), "%t", "CowLevel_Deactivated");
		PrintToChat(client, "\x05[Admin]\x01 %s", message);
	}

	return Plugin_Handled;
}

/**
 * Activa el Cow Level
 */
void CowLevel_Activate()
{
	if (g_bCowLevelActive)
	{
		LogMessage("[Cow Level] Already active, skipping activation");
		return;
	}

	LogMessage("[Cow Level] ============ ACTIVATION START ============");

	// Cachear y aplicar Configuracion del director
	CowLevel_CacheOriginalDirector();
	// Cow Level no modifica el director, pero guardamos los valores por si acaso

	// Preparar timestamp (NO activar aún)
	g_fCowLevel_LastPanicEvent = GetGameTime();

	// Anunciar activación
	SetGlobalTransTarget(LANG_SERVER);
	char message[256];
	Format(message, sizeof(message), "%t", "CowLevel_Unlocked");
	PrintToChatAll("\x05[Eclipse]\x04 %s", message);

	// Reproducir sonido
	LogMessage("[Cow Level] Playing activation sound...");
	EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");

	// Cargar cow spawns
	LogMessage("[Cow Level] Loading cow spawns...");
	CowLevel_LoadCowSpawns();

	// Crear color correction
	if (GetConVarBool(g_cvar_CowLevel_ColorCorrection))
	{
		char colorFile[PLATFORM_MAX_PATH];
		GetConVarString(g_cvar_CowLevel_ColorFile, colorFile, sizeof(colorFile));
		float weight = GetConVarFloat(g_cvar_CowLevel_ColorWeight);
		LogMessage("[Cow Level] Creating color correction: file=%s, weight=%.2f", colorFile, weight);
		CowLevel_CreateColorCorrection(colorFile, weight);
	}
	else
	{
		LogMessage("[Cow Level] Color correction disabled");
	}

	// Iniciar timer de eventos
	if (g_hCowLevel_EventTimer == null)
	{
		LogMessage("[Cow Level] Starting event timer...");
		g_hCowLevel_EventTimer = CreateTimer(5.0, Timer_CowLevelEvents, _, TIMER_REPEAT);
	}

	// SOLO activar después de que todos los recursos estén creados
	g_bCowLevelActive = true;

	LogMessage("[Cow Level] ============ ACTIVATION COMPLETE ============");
}

/**
 * Desactiva el Cow Level
 */
void CowLevel_Deactivate()
{
	if (!g_bCowLevelActive) return;

	g_bCowLevelActive = false;

	// Restaurar Configuracion del director
	CowLevel_RestoreDirector();

	// Detener timer de eventos
	if (g_hCowLevel_EventTimer != null)
	{
		KillTimer(g_hCowLevel_EventTimer);
		g_hCowLevel_EventTimer = null;
	}

	// Remover cows
	CowLevel_RemoveCowSpawns();

	// Remover color correction
	CowLevel_RemoveColorCorrection();

	// Anunciar desactivación
	SetGlobalTransTarget(LANG_SERVER);
	char message[128];
	Format(message, sizeof(message), "%t", "CowLevel_Ended");
	PrintToChatAll("\x05[Eclipse]\x01 %s", message);
}

/**
 * Timer de eventos periódicos del Cow Level
 */
public Action Timer_CowLevelEvents(Handle timer)
{
	if (!g_bCowLevelActive)
	{
		g_hCowLevel_EventTimer = null;
		return Plugin_Stop;
	}

	float currentTime = GetGameTime();
	float mapElapsed = currentTime - g_fCowLevel_MapStartTime;

	// No ejecutar eventos inmediatamente al inicio del mapa
	if (mapElapsed < 10.0)
		return Plugin_Continue;

	float panicInterval = GetConVarFloat(g_cvar_CowLevel_PanicInterval);

	// Panic Events
	if (panicInterval > 0.0 && (currentTime - g_fCowLevel_LastPanicEvent) >= panicInterval)
	{
		CowLevel_ForcePanicEvent();
		g_fCowLevel_LastPanicEvent = currentTime;
	}

	// Mega Mob Sound (probabilidad)
	if (GetConVarBool(g_cvar_CowLevel_MegaMobSound))
	{
		int chance = GetConVarInt(g_cvar_CowLevel_MegaMobSoundChance);
		if (GetRandomInt(1, chance) == 1)
		{
			EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");
		}
	}

	// Remover special infected si está habilitado
	if (GetConVarBool(g_cvar_CowLevel_RemoveSpecials))
	{
		CowLevel_RemoveNonZombies();
	}

	return Plugin_Continue;
}

/**
 * Fuerza un panic event
 */
void CowLevel_ForcePanicEvent()
{
	// Encontrar un cliente real para ejecutar el comando
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
 * Remueve infected especiales, dejando solo zombies comunes
 */
void CowLevel_RemoveNonZombies()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
		{
			// Si es special infected
			int class = GetEntProp(i, Prop_Send, "m_zombieClass");
			if (class >= 1 && class <= 6) // Smoker, Boomer, Hunter, Spitter, Jockey, Charger
			{
				if (IsFakeClient(i))
				{
					ForcePlayerSuicide(i);
				}
				else
				{
					// Si es jugador humano, respawnear como survivor
					ChangeClientTeam(i, 2);
				}
			}
			// Tanks (class 8) también se remueven
			else if (class == 8)
			{
				ForcePlayerSuicide(i);
			}
		}
	}
}

/**
 * Carga los cow spawns desde el archivo de Configuracion
 */
void CowLevel_LoadCowSpawns()
{
	if (g_iCowLevelSpawns > 0)
		return; // Ya fueron cargados

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_COW_SPAWNS);

	if (!FileExists(sPath))
	{
		LogMessage("[Cow Level] Config file not found: %s", sPath);
		LogMessage("[Cow Level] Creating default spawns...");
		CowLevel_CreateDefaultSpawns();
		return;
	}

	// Cargar config
	KeyValues hFile = new KeyValues("spawns");
	if (!hFile.ImportFromFile(sPath))
	{
		LogError("[Cow Level] Cannot read config: %s", sPath);
		delete hFile;
		return;
	}

	// Obtener nombre del mapa actual
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if (!hFile.JumpToKey(sMap))
	{
		LogMessage("[Cow Level] No spawns defined for map: %s", sMap);
		delete hFile;
		CowLevel_CreateDefaultSpawns();
		return;
	}

	// Obtener cantidad
	int iCount = hFile.GetNum("num", 0);
	if (iCount == 0)
	{
		LogMessage("[Cow Level] No spawn count for map: %s", sMap);
		delete hFile;
		return;
	}

	// Cargar posiciones y crear cows
	char sTemp[10];
	float vPos[3], vAng[3];

	for (int i = 1; i <= iCount; i++)
	{
		IntToString(i, sTemp, sizeof(sTemp));

		if (hFile.JumpToKey(sTemp))
		{
			hFile.GetVector("pos", vPos);
			hFile.GetVector("ang", vAng);

			if (vPos[0] != 0.0 || vPos[1] != 0.0 || vPos[2] != 0.0)
			{
				CowLevel_CreateCow(vPos, vAng);
			}

			hFile.GoBack();
		}
	}

	delete hFile;
	g_iCowLevelSpawns = 1;

	LogMessage("[Cow Level] Loaded %d cow spawns for map: %s", iCount, sMap);
}

/**
 * Crea spawns por defecto cuando no hay config
 */
void CowLevel_CreateDefaultSpawns()
{
	// Crear algunas cows en posiciones aleatorias cerca de los jugadores
	int spawned = 0;

	for (int i = 1; i <= MaxClients && spawned < 10; i++)
	{
		if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i))
		{
			float vPos[3], vAng[3];
			GetClientAbsOrigin(i, vPos);
			GetClientAbsAngles(i, vAng);

			// Crear 2-3 cows cerca de este jugador
			for (int j = 0; j < GetRandomInt(2, 3); j++)
			{
				float vOffset[3];
				vOffset[0] = GetRandomFloat(-300.0, 300.0);
				vOffset[1] = GetRandomFloat(-300.0, 300.0);
				vOffset[2] = 0.0;

				AddVectors(vPos, vOffset, vPos);
				CowLevel_CreateCow(vPos, vAng);
				spawned++;
			}
		}
	}

	if (spawned > 0)
	{
		LogMessage("[Cow Level] Created %d default cow spawns", spawned);
		g_iCowLevelSpawns = 1;
	}
}

/**
 * Crea una entidad de cow
 */
void CowLevel_CreateCow(float vOrigin[3], float vAngles[3])
{
	// Elegir modelo aleatorio
	char Model[PLATFORM_MAX_PATH];
	if (GetRandomInt(1, 2) == 1)
	{
		strcopy(Model, sizeof(Model), MODEL_COWPILE);
	}
	else
	{
		strcopy(Model, sizeof(Model), MODEL_COW);
	}

	int entity = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(entity))
	{
		vOrigin[2] -= 10.0; // Ajustar altura

		DispatchKeyValue(entity, "model", Model);
		DispatchKeyValue(entity, "solid", "6");
		DispatchSpawn(entity);
		TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);

		// Guardar referencia (con null check)
		if (g_aCowEntities != null)
		{
			g_aCowEntities.Push(EntIndexToEntRef(entity));
		}
	}
}

/**
 * Remueve todos los cow spawns
 */
void CowLevel_RemoveCowSpawns()
{
	// Null check para seguridad
	if (g_aCowEntities == null)
		return;

	// Usar el array de referencias
	for (int i = 0; i < g_aCowEntities.Length; i++)
	{
		int entity = EntRefToEntIndex(g_aCowEntities.Get(i));
		if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}

	g_aCowEntities.Clear();
	g_iCowLevelSpawns = 0;
}

/**
 * Crea el sistema de color correction
 */
void CowLevel_CreateColorCorrection(const char[] fileName, float weight)
{
	// Limpiar anteriores
	CowLevel_RemoveColorCorrection();

	LogMessage("[Cow Level] Creating color_correction entity...");

	// Crear color_correction entity
	int colorEnt = CreateEntityByName("color_correction");
	if (colorEnt == -1)
	{
		LogMessage("[Cow Level] ERROR: Failed to create color_correction entity!");
		return;
	}

	LogMessage("[Cow Level] color_correction entity created: %d", colorEnt);

	DispatchKeyValue(colorEnt, "targetname", "cowlevel_colorcorrection");
	DispatchKeyValue(colorEnt, "filename", fileName);

	char sWeight[16];
	FloatToString(weight, sWeight, sizeof(sWeight));
	DispatchKeyValue(colorEnt, "maxweight", sWeight);
	DispatchKeyValue(colorEnt, "maxfalloff", "-1");
	DispatchKeyValue(colorEnt, "minfalloff", "0");

	DispatchSpawn(colorEnt);
	ActivateEntity(colorEnt);
	AcceptEntityInput(colorEnt, "Enable");

	// Validate entity index is in valid range and entity is valid
	if (colorEnt > 0 && IsValidEntity(colorEnt))
	{
		g_iCowLevel_ColorCorrectionRef = EntIndexToEntRef(colorEnt);
		LogMessage("[Cow Level] color_correction spawned and enabled (ref: %d)", g_iCowLevel_ColorCorrectionRef);
	}
	else
	{
		LogMessage("[Cow Level] ERROR: color_correction entity became invalid after spawn (index: %d)!", colorEnt);
		g_iCowLevel_ColorCorrectionRef = -1;
	}

	// Crear fog_volume para que el color correction funcione
	LogMessage("[Cow Level] Creating fog_volume entity...");
	int fogVolEnt = CreateEntityByName("fog_volume");
	if (fogVolEnt == -1)
	{
		LogMessage("[Cow Level] ERROR: Failed to create fog_volume entity!");
		// Limpiar color_correction huérfano
		CowLevel_RemoveColorCorrection();
		return;
	}

	LogMessage("[Cow Level] fog_volume entity created: %d", fogVolEnt);

	DispatchKeyValue(fogVolEnt, "targetname", "cowlevel_fogvolume");
	DispatchKeyValue(fogVolEnt, "PostProcessName", "cowlevel_colorcorrection");

	// Cubrir todo el mapa - DEBE hacerse ANTES de DispatchSpawn
	DispatchKeyValue(fogVolEnt, "mins", "-10000 -10000 -10000");
	DispatchKeyValue(fogVolEnt, "maxs", "10000 10000 10000");

	DispatchSpawn(fogVolEnt);
	ActivateEntity(fogVolEnt);

	// Validate entity index is in valid range and entity is valid
	if (fogVolEnt > 0 && IsValidEntity(fogVolEnt))
	{
		g_iCowLevel_FogVolumeRef = EntIndexToEntRef(fogVolEnt);
		LogMessage("[Cow Level] fog_volume spawned (ref: %d)", g_iCowLevel_FogVolumeRef);
	}
	else
	{
		LogMessage("[Cow Level] ERROR: fog_volume entity became invalid after spawn (index: %d)!", fogVolEnt);
		g_iCowLevel_FogVolumeRef = -1;
	}
}

/**
 * Remueve el color correction
 */
void CowLevel_RemoveColorCorrection()
{
	// Remover color_correction
	if (g_iCowLevel_ColorCorrectionRef != -1)
	{
		int entity = EntRefToEntIndex(g_iCowLevel_ColorCorrectionRef);
		if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
		g_iCowLevel_ColorCorrectionRef = -1;
	}

	// Remover fog_volume
	if (g_iCowLevel_FogVolumeRef != -1)
	{
		int entity = EntRefToEntIndex(g_iCowLevel_FogVolumeRef);
		if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
		g_iCowLevel_FogVolumeRef = -1;
	}
}

//==================================================
// FUNCIONES DE BACKUP Y RESTAURACIÓN
//==================================================

/**
 * Cachea los valores originales del director
 */
void CowLevel_CacheOriginalDirector()
{
	if (g_iOrigCommonLimit_CowLevel == -1 && z_common_limit_cowlevel != null)
		g_iOrigCommonLimit_CowLevel = GetConVarInt(z_common_limit_cowlevel);
	if (g_iOrigMobMin_CowLevel == -1 && z_mob_spawn_min_size_cowlevel != null)
		g_iOrigMobMin_CowLevel = GetConVarInt(z_mob_spawn_min_size_cowlevel);
	if (g_iOrigMobMax_CowLevel == -1 && z_mob_spawn_max_size_cowlevel != null)
		g_iOrigMobMax_CowLevel = GetConVarInt(z_mob_spawn_max_size_cowlevel);
	if (g_iOrigMegaMob_CowLevel == -1 && z_mega_mob_size_cowlevel != null)
		g_iOrigMegaMob_CowLevel = GetConVarInt(z_mega_mob_size_cowlevel);
	if (g_sOrigDifficulty_CowLevel[0] == '\0' && z_difficulty_cowlevel != null)
		GetConVarString(z_difficulty_cowlevel, g_sOrigDifficulty_CowLevel, sizeof(g_sOrigDifficulty_CowLevel));
}

/**
 * Restaura los valores originales del director
 */
void CowLevel_RestoreDirector()
{
	if (z_common_limit_cowlevel && g_iOrigCommonLimit_CowLevel != -1)
		SetConVarInt(z_common_limit_cowlevel, g_iOrigCommonLimit_CowLevel);
	if (z_mob_spawn_min_size_cowlevel && g_iOrigMobMin_CowLevel != -1)
		SetConVarInt(z_mob_spawn_min_size_cowlevel, g_iOrigMobMin_CowLevel);
	if (z_mob_spawn_max_size_cowlevel && g_iOrigMobMax_CowLevel != -1)
		SetConVarInt(z_mob_spawn_max_size_cowlevel, g_iOrigMobMax_CowLevel);
	if (z_mega_mob_size_cowlevel && g_iOrigMegaMob_CowLevel != -1)
		SetConVarInt(z_mega_mob_size_cowlevel, g_iOrigMegaMob_CowLevel);
	if (z_difficulty_cowlevel && g_sOrigDifficulty_CowLevel[0] != '\0')
		ServerCommand("z_difficulty %s", g_sOrigDifficulty_CowLevel);
}
