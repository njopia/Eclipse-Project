#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === DIFFICULTY ORCHESTRATOR MODULE ===
// Orquestador central de modos de dificultad
// Gestiona mutual exclusion, progresión y coordinación
//==================================================

//==================================================
// ENUMS Y CONSTANTES
//==================================================

enum DifficultyMode
{
	MODE_NONE = 0,
	MODE_BLOODMOON = 1,
	MODE_HELL = 2,
	MODE_INFERNO = 3,
	MODE_COWLEVEL = 4
};

// Progression requirements (campaign wins needed to unlock next mode)
#define PROGRESSION_BLOODMOON_TO_HELL		0	// Immediate unlock after 1 win
#define PROGRESSION_HELL_TO_INFERNO			2	// Need 2 wins
#define PROGRESSION_INFERNO_TO_COWLEVEL		2	// Need 2 wins

//==================================================
// VARIABLES GLOBALES
//==================================================

// ConVars
Handle g_cvar_DiffOrch_Enable = INVALID_HANDLE;
Handle g_cvar_DiffOrch_ProgressionEnable = INVALID_HANDLE;
Handle g_cvar_DiffOrch_MutualExclusion = INVALID_HANDLE;
Handle g_cvar_DiffOrch_AutoUnlock = INVALID_HANDLE;

// Estado actual
DifficultyMode g_CurrentMode = MODE_NONE;
int g_iDifficultyWins = 0;
bool g_bFinaleCompleted = false;

// Modo anterior (para tracking)
DifficultyMode g_PreviousMode = MODE_NONE;

// Handles para ConVars de modos (obtenidos dinámicamente)
Handle g_hBloodmoon_Enable = INVALID_HANDLE;
Handle g_hCowLevel_Enable = INVALID_HANDLE;
Handle g_hHell_Enable = INVALID_HANDLE;
Handle g_hInferno_Enable = INVALID_HANDLE;

//==================================================
// FUNCIONES PÚBLICAS
//==================================================

/**
 * Inicializa el orquestador de dificultad
 */
public void DifficultyOrchestrator_OnPluginStart()
{
	// ConVars de configuración
	g_cvar_DiffOrch_Enable = CreateConVar(
		"difficulty_orchestrator_enable",
		"1",
		"Habilita el orquestador de dificultad",
		FCVAR_PLUGIN,
		true, 0.0, true, 1.0
	);

	g_cvar_DiffOrch_ProgressionEnable = CreateConVar(
		"difficulty_progression_enable",
		"1",
		"Habilita progresión automática de dificultad al ganar campañas",
		FCVAR_PLUGIN,
		true, 0.0, true, 1.0
	);

	g_cvar_DiffOrch_MutualExclusion = CreateConVar(
		"difficulty_mutual_exclusion",
		"1",
		"Solo un modo de dificultad activo a la vez",
		FCVAR_PLUGIN,
		true, 0.0, true, 1.0
	);

	g_cvar_DiffOrch_AutoUnlock = CreateConVar(
		"difficulty_auto_unlock",
		"1",
		"Desbloqueo automático al cumplir requisitos",
		FCVAR_PLUGIN,
		true, 0.0, true, 1.0
	);

	// Hooks de eventos
	HookEvent("mission_lost", Event_MissionLost);
	HookEvent("finale_win", Event_FinaleWin);

	// Hook ConVar changes para detectar activaciones manuales
	HookConVarChange(g_cvar_DiffOrch_MutualExclusion, ConVarChanged_MutualExclusion);

	// Obtener handles de ConVars de modos (FindConVar busca ConVars ya registrados)
	CreateTimer(0.5, Timer_FindModeConVars, _, TIMER_FLAG_NO_MAPCHANGE);

	// Comandos admin
	RegAdminCmd("sm_diffmode", Command_DiffMode, ADMFLAG_ROOT, "Gestionar modos de dificultad");
	RegAdminCmd("sm_resetprogression", Command_ResetProgression, ADMFLAG_ROOT, "Resetear progresión de dificultad");

	// Alias cortos para comandos
	RegAdminCmd("sm_bm", Command_Alias_Bloodmoon, ADMFLAG_ROOT, "Alias: Activar Bloodmoon");
	RegAdminCmd("sm_cow", Command_Alias_CowLevel, ADMFLAG_ROOT, "Alias: Activar Cow Level");
	RegAdminCmd("sm_diffstatus", Command_Alias_Status, ADMFLAG_ROOT, "Alias: Ver estado de dificultad");
	RegAdminCmd("sm_diffreset", Command_Alias_Reset, ADMFLAG_ROOT, "Alias: Resetear progresión");
}

/**
 * Timer para encontrar y hookear ConVars de modos
 * Delay necesario porque los módulos se inicializan después del orquestador
 */
public Action Timer_FindModeConVars(Handle timer)
{
	// Buscar ConVars registrados por los módulos
	g_hBloodmoon_Enable = FindConVar("bloodmoon_enable");
	g_hCowLevel_Enable = FindConVar("cowlevel_enable");
	g_hHell_Enable = FindConVar("hell_enable");
	g_hInferno_Enable = FindConVar("inferno_enable");

	// Hook cambios en ConVars de modos individuales para enforcar mutual exclusion
	if (g_hBloodmoon_Enable != INVALID_HANDLE)
		HookConVarChange(g_hBloodmoon_Enable, ConVarChanged_ModeActivation);

	if (g_hCowLevel_Enable != INVALID_HANDLE)
		HookConVarChange(g_hCowLevel_Enable, ConVarChanged_ModeActivation);

	if (g_hHell_Enable != INVALID_HANDLE)
		HookConVarChange(g_hHell_Enable, ConVarChanged_ModeActivation);

	if (g_hInferno_Enable != INVALID_HANDLE)
		HookConVarChange(g_hInferno_Enable, ConVarChanged_ModeActivation);

	LogMessage("[Difficulty Orchestrator] Mode ConVars hooked successfully");
	return Plugin_Stop;
}

/**
 * Llamado al inicio del mapa
 */
public void DifficultyOrchestrator_OnMapStart()
{
	g_bFinaleCompleted = false;

	// Detectar modo activo al inicio
	DifficultyOrchestrator_DetectActiveMode();
}

/**
 * Hook: Finale ganado
 */
public void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(g_cvar_DiffOrch_Enable))
		return;

	if (!GetConVarBool(g_cvar_DiffOrch_ProgressionEnable))
		return;

	g_bFinaleCompleted = true;

	// Procesar progresión en el siguiente mapa
	CreateTimer(5.0, Timer_ProcessProgression, _, TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Hook: Misión perdida
 */
public void Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
	// Reset progression on loss
	g_iDifficultyWins = 0;
}

/**
 * Timer: Procesar progresión de dificultad
 */
public Action Timer_ProcessProgression(Handle timer)
{
	if (!g_bFinaleCompleted)
		return Plugin_Stop;

	DifficultyOrchestrator_ProcessProgression();
	return Plugin_Stop;
}

/**
 * Procesa la progresión de dificultad después de ganar
 */
void DifficultyOrchestrator_ProcessProgression()
{
	if (!GetConVarBool(g_cvar_DiffOrch_AutoUnlock))
		return;

	switch (g_CurrentMode)
	{
		case MODE_NONE:
		{
			// First win → Unlock Bloodmoon
			SetGlobalTransTarget(LANG_SERVER);
			char message[256];
			Format(message, sizeof(message), "%t", "DiffOrch_BloodmoonUnlocked");
			PrintToChatAll("\x05[Eclipse]\x04 %s", message);
			EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");

			DifficultyOrchestrator_SetMode(MODE_BLOODMOON);
			g_iDifficultyWins = 0;
		}
		case MODE_BLOODMOON:
		{
			// Bloodmoon → Hell (immediate)
			if (g_iDifficultyWins >= PROGRESSION_BLOODMOON_TO_HELL)
			{
				SetGlobalTransTarget(LANG_SERVER);
				char message[256];
				Format(message, sizeof(message), "%t", "DiffOrch_HellUnlocked");
				PrintToChatAll("\x05[Eclipse]\x04 %s", message);
				EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");

				DifficultyOrchestrator_SetMode(MODE_HELL);
				g_iDifficultyWins = 0;
			}
			else
			{
				g_iDifficultyWins++;
			}
		}
		case MODE_HELL:
		{
			// Hell → Inferno (2 wins)
			if (g_iDifficultyWins >= PROGRESSION_HELL_TO_INFERNO)
			{
				SetGlobalTransTarget(LANG_SERVER);
				char message[256];
				Format(message, sizeof(message), "%t", "DiffOrch_InfernoUnlocked");
				PrintToChatAll("\x05[Eclipse]\x04 %s", message);
				EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");

				DifficultyOrchestrator_SetMode(MODE_INFERNO);
				g_iDifficultyWins = 0;
			}
			else
			{
				g_iDifficultyWins++;
			}
		}
		case MODE_INFERNO:
		{
			// Inferno → Cow Level (2 wins)
			if (g_iDifficultyWins >= PROGRESSION_INFERNO_TO_COWLEVEL)
			{
				SetGlobalTransTarget(LANG_SERVER);
				char message[256];
				Format(message, sizeof(message), "%t", "DiffOrch_CowLevelUnlocked");
				PrintToChatAll("\x05[Eclipse]\x04 %s", message);
				EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");

				DifficultyOrchestrator_SetMode(MODE_COWLEVEL);
				g_iDifficultyWins = 0;
			}
			else
			{
				g_iDifficultyWins++;
			}
		}
		case MODE_COWLEVEL:
		{
			// Cow Level completed → Congratulations!
			SetGlobalTransTarget(LANG_SERVER);
			char message[256];
			Format(message, sizeof(message), "%t", "DiffOrch_AllCompleted");
			PrintToChatAll("\x05[Eclipse]\x04 %s", message);

			DifficultyOrchestrator_SetMode(MODE_NONE);
			g_iDifficultyWins = 0;
		}
	}
}

/**
 * Establece el modo de dificultad activo
 */
public void DifficultyOrchestrator_SetMode(DifficultyMode mode)
{
	if (!GetConVarBool(g_cvar_DiffOrch_Enable))
		return;

	// Store previous mode
	g_PreviousMode = g_CurrentMode;
	g_CurrentMode = mode;

	// Mutual exclusion: desactivar otros modos
	if (GetConVarBool(g_cvar_DiffOrch_MutualExclusion))
	{
		DifficultyOrchestrator_EnforceMutualExclusion(mode);
	}

	// Activar el modo solicitado
	DifficultyOrchestrator_ActivateMode(mode);

	// Log mode change
	LogMessage("[Difficulty Orchestrator] Mode changed: %d → %d", g_PreviousMode, g_CurrentMode);
}

/**
 * Aplica mutual exclusion - desactiva todos los modos excepto el especificado
 */
void DifficultyOrchestrator_EnforceMutualExclusion(DifficultyMode activeMode)
{
	// Verificar que los handles estén inicializados
	if (g_hCowLevel_Enable == INVALID_HANDLE || g_hBloodmoon_Enable == INVALID_HANDLE)
	{
		LogMessage("[Difficulty Orchestrator] ConVar handles not yet initialized, skipping mutual exclusion");
		return;
	}

	// Desactivar Bloodmoon si no es el modo activo
	if (activeMode != MODE_BLOODMOON && GetConVarBool(g_hBloodmoon_Enable))
	{
		SetConVarBool(g_hBloodmoon_Enable, false);
		LogMessage("[Difficulty Orchestrator] Deactivating Bloodmoon (mutual exclusion)");
	}

	// Desactivar Hell si no es el modo activo
	if (g_hHell_Enable != INVALID_HANDLE && activeMode != MODE_HELL && GetConVarBool(g_hHell_Enable))
	{
		SetConVarBool(g_hHell_Enable, false);
		LogMessage("[Difficulty Orchestrator] Deactivating Hell (mutual exclusion)");
	}

	// Desactivar Inferno si no es el modo activo
	if (g_hInferno_Enable != INVALID_HANDLE && activeMode != MODE_INFERNO && GetConVarBool(g_hInferno_Enable))
	{
		SetConVarBool(g_hInferno_Enable, false);
		LogMessage("[Difficulty Orchestrator] Deactivating Inferno (mutual exclusion)");
	}

	// Desactivar Cow Level si no es el modo activo
	if (activeMode != MODE_COWLEVEL && GetConVarBool(g_hCowLevel_Enable))
	{
		SetConVarBool(g_hCowLevel_Enable, false);
		LogMessage("[Difficulty Orchestrator] Deactivating Cow Level (mutual exclusion)");
	}
}

/**
 * Activa el modo especificado
 */
void DifficultyOrchestrator_ActivateMode(DifficultyMode mode)
{
	// Verificar que los handles estén inicializados
	if (g_hCowLevel_Enable == INVALID_HANDLE || g_hBloodmoon_Enable == INVALID_HANDLE)
	{
		LogMessage("[Difficulty Orchestrator] ConVar handles not yet initialized, cannot activate mode");
		return;
	}

	switch (mode)
	{
		case MODE_NONE:
		{
			// No active mode - ensure all are disabled
			SetConVarBool(g_hBloodmoon_Enable, false);
			SetConVarBool(g_hCowLevel_Enable, false);
			if (g_hHell_Enable != INVALID_HANDLE)
				SetConVarBool(g_hHell_Enable, false);
			if (g_hInferno_Enable != INVALID_HANDLE)
				SetConVarBool(g_hInferno_Enable, false);
		}
		case MODE_BLOODMOON:
		{
			// Forzar toggle para garantizar que el hook se dispare
			if (GetConVarBool(g_hBloodmoon_Enable))
				SetConVarBool(g_hBloodmoon_Enable, false);
			SetConVarBool(g_hBloodmoon_Enable, true);
		}
		case MODE_HELL:
		{
			if (g_hHell_Enable != INVALID_HANDLE)
			{
				// Forzar toggle para garantizar que el hook se dispare
				if (GetConVarBool(g_hHell_Enable))
					SetConVarBool(g_hHell_Enable, false);
				SetConVarBool(g_hHell_Enable, true);
			}
			else
			{
				LogMessage("[Difficulty Orchestrator] Hell mode ConVar not found");
			}
		}
		case MODE_INFERNO:
		{
			if (g_hInferno_Enable != INVALID_HANDLE)
			{
				// Forzar toggle para garantizar que el hook se dispare
				if (GetConVarBool(g_hInferno_Enable))
					SetConVarBool(g_hInferno_Enable, false);
				SetConVarBool(g_hInferno_Enable, true);
			}
			else
			{
				LogMessage("[Difficulty Orchestrator] Inferno mode ConVar not found");
			}
		}
		case MODE_COWLEVEL:
		{
			// Forzar toggle para garantizar que el hook se dispare
			if (GetConVarBool(g_hCowLevel_Enable))
				SetConVarBool(g_hCowLevel_Enable, false);
			SetConVarBool(g_hCowLevel_Enable, true);
		}
	}
}

/**
 * Detecta qué modo está activo actualmente
 */
void DifficultyOrchestrator_DetectActiveMode()
{
	DifficultyMode detectedMode = MODE_NONE;

	// Verificar que los handles estén inicializados
	if (g_hCowLevel_Enable == INVALID_HANDLE || g_hBloodmoon_Enable == INVALID_HANDLE)
	{
		LogMessage("[Difficulty Orchestrator] ConVar handles not yet initialized, skipping detection");
		return;
	}

	// Check en orden de prioridad (de mayor a menor dificultad)
	if (GetConVarBool(g_hCowLevel_Enable))
		detectedMode = MODE_COWLEVEL;
	else if (g_hInferno_Enable != INVALID_HANDLE && GetConVarBool(g_hInferno_Enable))
		detectedMode = MODE_INFERNO;
	else if (g_hHell_Enable != INVALID_HANDLE && GetConVarBool(g_hHell_Enable))
		detectedMode = MODE_HELL;
	else if (GetConVarBool(g_hBloodmoon_Enable))
		detectedMode = MODE_BLOODMOON;

	if (detectedMode != g_CurrentMode)
	{
		g_PreviousMode = g_CurrentMode;
		g_CurrentMode = detectedMode;
		LogMessage("[Difficulty Orchestrator] Detected active mode: %d", g_CurrentMode);
	}
}

/**
 * Hook: Cambio en ConVar de mutual exclusion
 */
public void ConVarChanged_MutualExclusion(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(g_cvar_DiffOrch_MutualExclusion))
	{
		// Si se activa mutual exclusion, aplicar inmediatamente
		DifficultyOrchestrator_DetectActiveMode();
		DifficultyOrchestrator_EnforceMutualExclusion(g_CurrentMode);
	}
}

/**
 * Hook: Cambio en ConVars de activación de modos individuales
 * Detecta cuando un modo es activado manualmente y aplica mutual exclusion
 */
public void ConVarChanged_ModeActivation(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (!GetConVarBool(g_cvar_DiffOrch_Enable))
		return;

	if (!GetConVarBool(g_cvar_DiffOrch_MutualExclusion))
		return;

	// Solo procesar si el modo fue activado (0 → 1)
	int oldVal = StringToInt(oldValue);
	int newVal = StringToInt(newValue);

	if (oldVal == 1 && newVal == 1)
		return; // No hubo cambio real

	if (newVal == 1)
	{
		// Determinar qué modo fue activado
		DifficultyMode activatedMode = MODE_NONE;

		if (convar == g_hBloodmoon_Enable)
			activatedMode = MODE_BLOODMOON;
		else if (convar == g_hHell_Enable)
			activatedMode = MODE_HELL;
		else if (convar == g_hInferno_Enable)
			activatedMode = MODE_INFERNO;
		else if (convar == g_hCowLevel_Enable)
			activatedMode = MODE_COWLEVEL;

		if (activatedMode != MODE_NONE)
		{
			LogMessage("[Difficulty Orchestrator] Manual activation detected: %d", activatedMode);

			// Actualizar modo actual
			g_PreviousMode = g_CurrentMode;
			g_CurrentMode = activatedMode;

			// Enforcar mutual exclusion
			DifficultyOrchestrator_EnforceMutualExclusion(activatedMode);
		}
	}
	else if (newVal == 0)
	{
		// Modo desactivado - si era el modo actual, resetear
		DifficultyMode deactivatedMode = MODE_NONE;

		if (convar == g_hBloodmoon_Enable)
			deactivatedMode = MODE_BLOODMOON;
		else if (convar == g_hHell_Enable)
			deactivatedMode = MODE_HELL;
		else if (convar == g_hInferno_Enable)
			deactivatedMode = MODE_INFERNO;
		else if (convar == g_hCowLevel_Enable)
			deactivatedMode = MODE_COWLEVEL;

		if (deactivatedMode == g_CurrentMode)
		{
			LogMessage("[Difficulty Orchestrator] Current mode deactivated: %d", deactivatedMode);
			g_PreviousMode = g_CurrentMode;
			g_CurrentMode = MODE_NONE;
		}
	}
}

//==================================================
// COMANDOS ADMIN
//==================================================

/**
 * Comando: Gestionar modos de dificultad
 */
public Action Command_DiffMode(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[Difficulty] Usage: sm_diffmode <none|bloodmoon|hell|inferno|cowlevel|status>");
		return Plugin_Handled;
	}

	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));

	if (StrEqual(arg, "status", false))
	{
		// Mostrar estado actual
		char modeName[32];
		DifficultyOrchestrator_GetModeName(g_CurrentMode, modeName, sizeof(modeName));

		ReplyToCommand(client, "[Difficulty] Current Mode: %s", modeName);
		ReplyToCommand(client, "[Difficulty] Progression Wins: %d", g_iDifficultyWins);
		ReplyToCommand(client, "[Difficulty] Mutual Exclusion: %s",
			GetConVarBool(g_cvar_DiffOrch_MutualExclusion) ? "ON" : "OFF");
		ReplyToCommand(client, "[Difficulty] Auto Progression: %s",
			GetConVarBool(g_cvar_DiffOrch_ProgressionEnable) ? "ON" : "OFF");
		return Plugin_Handled;
	}

	// Cambiar modo
	DifficultyMode newMode = MODE_NONE;

	if (StrEqual(arg, "none", false))
		newMode = MODE_NONE;
	else if (StrEqual(arg, "bloodmoon", false))
		newMode = MODE_BLOODMOON;
	else if (StrEqual(arg, "hell", false))
		newMode = MODE_HELL;
	else if (StrEqual(arg, "inferno", false))
		newMode = MODE_INFERNO;
	else if (StrEqual(arg, "cowlevel", false))
		newMode = MODE_COWLEVEL;
	else
	{
		ReplyToCommand(client, "[Difficulty] Invalid mode: %s", arg);
		return Plugin_Handled;
	}

	char modeName[32];
	DifficultyOrchestrator_GetModeName(newMode, modeName, sizeof(modeName));
	ReplyToCommand(client, "[Difficulty] Setting mode to: %s", modeName);

	DifficultyOrchestrator_SetMode(newMode);
	return Plugin_Handled;
}

/**
 * Comando: Resetear progresión
 */
public Action Command_ResetProgression(int client, int args)
{
	g_iDifficultyWins = 0;
	DifficultyOrchestrator_SetMode(MODE_NONE);

	ReplyToCommand(client, "[Difficulty] Progression reset. All modes deactivated.");
	PrintToChatAll("\x05[Eclipse]\x01 Difficulty progression has been reset by admin.");

	return Plugin_Handled;
}

//==================================================
// COMANDOS ALIAS (SHORTCUTS)
//==================================================

/**
 * Alias: sm_bm - Activar Bloodmoon
 */
public Action Command_Alias_Bloodmoon(int client, int args)
{
	DifficultyOrchestrator_SetMode(MODE_BLOODMOON);
	ReplyToCommand(client, "[Difficulty] Bloodmoon activated");
	return Plugin_Handled;
}

/**
 * Alias: sm_cow - Activar Cow Level
 */
public Action Command_Alias_CowLevel(int client, int args)
{
	DifficultyOrchestrator_SetMode(MODE_COWLEVEL);
	ReplyToCommand(client, "[Difficulty] Cow Level activated");
	return Plugin_Handled;
}

/**
 * Alias: sm_diffstatus - Ver estado
 */
public Action Command_Alias_Status(int client, int args)
{
	char modeName[32];
	DifficultyOrchestrator_GetModeName(g_CurrentMode, modeName, sizeof(modeName));

	ReplyToCommand(client, "[Difficulty] Current Mode: %s", modeName);
	ReplyToCommand(client, "[Difficulty] Progression Wins: %d", g_iDifficultyWins);
	ReplyToCommand(client, "[Difficulty] Mutual Exclusion: %s",
		GetConVarBool(g_cvar_DiffOrch_MutualExclusion) ? "ON" : "OFF");
	ReplyToCommand(client, "[Difficulty] Auto Progression: %s",
		GetConVarBool(g_cvar_DiffOrch_ProgressionEnable) ? "ON" : "OFF");

	return Plugin_Handled;
}

/**
 * Alias: sm_diffreset - Resetear progresión
 */
public Action Command_Alias_Reset(int client, int args)
{
	return Command_ResetProgression(client, args);
}

//==================================================
// FUNCIONES DE UTILIDAD
//==================================================

/**
 * Obtiene el nombre del modo
 */
void DifficultyOrchestrator_GetModeName(DifficultyMode mode, char[] buffer, int maxlen)
{
	switch (mode)
	{
		case MODE_NONE: strcopy(buffer, maxlen, "None");
		case MODE_BLOODMOON: strcopy(buffer, maxlen, "Bloodmoon");
		case MODE_HELL: strcopy(buffer, maxlen, "Hell");
		case MODE_INFERNO: strcopy(buffer, maxlen, "Inferno");
		case MODE_COWLEVEL: strcopy(buffer, maxlen, "Cow Level");
		default: strcopy(buffer, maxlen, "Unknown");
	}
}

/**
 * Obtiene el modo actual
 */
public DifficultyMode DifficultyOrchestrator_GetCurrentMode()
{
	return g_CurrentMode;
}

/**
 * Obtiene el contador de victorias
 */
public int DifficultyOrchestrator_GetWinCount()
{
	return g_iDifficultyWins;
}

/**
 * Establece el contador de victorias (para persistencia)
 */
public void DifficultyOrchestrator_SetWinCount(int wins)
{
	g_iDifficultyWins = wins;
}
