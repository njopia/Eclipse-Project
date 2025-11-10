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

// Referencias externas a ConVars de modos (definidos en sus respectivos módulos)
// NOTA: Estos handles son accesibles porque todos los módulos se compilan juntos
extern Handle g_cvar_Bloodmoon_Enable;
extern Handle g_cvar_CowLevel_Enable;
// TODO: Agregar cuando Hell e Inferno estén implementados
// extern Handle g_cvar_Hell_Enable;
// extern Handle g_cvar_Inferno_Enable;

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

	// Comandos admin
	RegAdminCmd("sm_diffmode", Command_DiffMode, ADMFLAG_ROOT, "Gestionar modos de dificultad");
	RegAdminCmd("sm_resetprogression", Command_ResetProgression, ADMFLAG_ROOT, "Resetear progresión de dificultad");
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
	// Desactivar Bloodmoon si no es el modo activo
	if (activeMode != MODE_BLOODMOON && GetConVarBool(g_cvar_Bloodmoon_Enable))
	{
		SetConVarBool(g_cvar_Bloodmoon_Enable, false);
		LogMessage("[Difficulty Orchestrator] Deactivating Bloodmoon (mutual exclusion)");
	}

	// Desactivar Hell si no es el modo activo
	// TODO: Implementar cuando Hell module esté disponible
	/*
	if (activeMode != MODE_HELL && GetConVarBool(g_cvar_Hell_Enable))
	{
		SetConVarBool(g_cvar_Hell_Enable, false);
		LogMessage("[Difficulty Orchestrator] Deactivating Hell (mutual exclusion)");
	}
	*/

	// Desactivar Inferno si no es el modo activo
	// TODO: Implementar cuando Inferno module esté disponible
	/*
	if (activeMode != MODE_INFERNO && GetConVarBool(g_cvar_Inferno_Enable))
	{
		SetConVarBool(g_cvar_Inferno_Enable, false);
		LogMessage("[Difficulty Orchestrator] Deactivating Inferno (mutual exclusion)");
	}
	*/

	// Desactivar Cow Level si no es el modo activo
	if (activeMode != MODE_COWLEVEL && GetConVarBool(g_cvar_CowLevel_Enable))
	{
		SetConVarBool(g_cvar_CowLevel_Enable, false);
		LogMessage("[Difficulty Orchestrator] Deactivating Cow Level (mutual exclusion)");
	}
}

/**
 * Activa el modo especificado
 */
void DifficultyOrchestrator_ActivateMode(DifficultyMode mode)
{
	switch (mode)
	{
		case MODE_NONE:
		{
			// No active mode - ensure all are disabled
			SetConVarBool(g_cvar_Bloodmoon_Enable, false);
			SetConVarBool(g_cvar_CowLevel_Enable, false);
			// TODO: Hell, Inferno
		}
		case MODE_BLOODMOON:
		{
			if (!GetConVarBool(g_cvar_Bloodmoon_Enable))
				SetConVarBool(g_cvar_Bloodmoon_Enable, true);
		}
		case MODE_HELL:
		{
			// TODO: Activar Hell cuando esté implementado
			LogMessage("[Difficulty Orchestrator] Hell mode not yet implemented");
		}
		case MODE_INFERNO:
		{
			// TODO: Activar Inferno cuando esté implementado
			LogMessage("[Difficulty Orchestrator] Inferno mode not yet implemented");
		}
		case MODE_COWLEVEL:
		{
			if (!GetConVarBool(g_cvar_CowLevel_Enable))
				SetConVarBool(g_cvar_CowLevel_Enable, true);
		}
	}
}

/**
 * Detecta qué modo está activo actualmente
 */
void DifficultyOrchestrator_DetectActiveMode()
{
	DifficultyMode detectedMode = MODE_NONE;

	// Check en orden de prioridad
	if (GetConVarBool(g_cvar_CowLevel_Enable))
		detectedMode = MODE_COWLEVEL;
	// TODO: else if (GetConVarBool(g_cvar_Inferno_Enable))
	//	detectedMode = MODE_INFERNO;
	// TODO: else if (GetConVarBool(g_cvar_Hell_Enable))
	//	detectedMode = MODE_HELL;
	else if (GetConVarBool(g_cvar_Bloodmoon_Enable))
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
