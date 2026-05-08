#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === DIFFICULTY ORCHESTRATOR MODULE ===
// Coordina modos de dificultad: mutual exclusion,
// progresion por victorias y comandos admin.
//
// Comunicacion con modos:
//   Cada modo llama DifficultyOrchestrator_Register()
//   al final de su OnPluginStart(). El orquestador
//   guarda el ConVar handle y hookea cambios para
//   detectar activaciones manuales.
//   La flag g_bOrchestratorChanging evita que los
//   hooks propios del orquestador se disparen de
//   forma recursiva cuando el mismo orquestador
//   cambia un ConVar.
//==================================================

// =============================================================================
// ENUMS Y CONSTANTES
// =============================================================================

enum DifficultyMode
{
	MODE_NONE      = 0,
	MODE_BLOODMOON = 1,
	MODE_HELL      = 2,
	MODE_INFERNO   = 3,
	MODE_COWLEVEL  = 4
};

// Victorias acumuladas en el modo actual necesarias para avanzar.
// 0 = avanza despues de la primera victoria en ese modo.
#define PROGRESSION_BLOODMOON_TO_HELL    0
#define PROGRESSION_HELL_TO_INFERNO      2
#define PROGRESSION_INFERNO_TO_COWLEVEL  2

// =============================================================================
// VARIABLES GLOBALES
// =============================================================================

Handle g_cvar_DiffOrch_Enable          = INVALID_HANDLE;
Handle g_cvar_DiffOrch_ProgressionEnable = INVALID_HANDLE;
Handle g_cvar_DiffOrch_MutualExclusion = INVALID_HANDLE;
Handle g_cvar_DiffOrch_AutoUnlock      = INVALID_HANDLE;

// Handles registrados por cada modo (indice = DifficultyMode)
Handle g_hModeConVars[5];

// Estado actual
DifficultyMode g_CurrentMode  = MODE_NONE;
DifficultyMode g_PreviousMode = MODE_NONE;
int  g_iDifficultyWins  = 0;
bool g_bFinaleCompleted = false;

// Evita que el hook del orquestador procese cambios que el mismo genero,
// previniendo el loop recursivo de mutual exclusion.
bool g_bOrchestratorChanging = false;

// =============================================================================
// INICIALIZACION
// =============================================================================

public void DifficultyOrchestrator_OnPluginStart()
{
	g_cvar_DiffOrch_Enable = CreateConVar(
		"difficulty_orchestrator_enable", "1",
		"Habilita el orquestador de dificultad",
		FCVAR_PLUGIN, true, 0.0, true, 1.0);

	g_cvar_DiffOrch_ProgressionEnable = CreateConVar(
		"difficulty_progression_enable", "1",
		"Progresion automatica al ganar campanas",
		FCVAR_PLUGIN, true, 0.0, true, 1.0);

	g_cvar_DiffOrch_MutualExclusion = CreateConVar(
		"difficulty_mutual_exclusion", "1",
		"Solo un modo activo a la vez",
		FCVAR_PLUGIN, true, 0.0, true, 1.0);

	g_cvar_DiffOrch_AutoUnlock = CreateConVar(
		"difficulty_auto_unlock", "1",
		"Desbloqueo automatico al cumplir requisitos",
		FCVAR_PLUGIN, true, 0.0, true, 1.0);

	for (int i = 0; i < 5; i++)
		g_hModeConVars[i] = INVALID_HANDLE;

	HookEvent("finale_win",   Event_FinaleWin);
	HookEvent("mission_lost", Event_MissionLost);

	RegAdminCmd("sm_diffmode",      Command_DiffMode,       ADMFLAG_ROOT, "Gestionar modos de dificultad");
	RegAdminCmd("sm_mode",          Command_DiffMode,       ADMFLAG_ROOT, "Alias: modos de dificultad");
	RegAdminCmd("sm_resetprogression", Command_ResetProgression, ADMFLAG_ROOT, "Resetear progresion");
	RegAdminCmd("sm_bm",            Command_Alias_Bloodmoon, ADMFLAG_ROOT, "Activar Bloodmoon");
	RegAdminCmd("sm_hell",          Command_Alias_Hell,      ADMFLAG_ROOT, "Activar Hell Mode");
	RegAdminCmd("sm_inferno",       Command_Alias_Inferno,   ADMFLAG_ROOT, "Activar Inferno Mode");
	RegAdminCmd("sm_cow",           Command_Alias_CowLevel,  ADMFLAG_ROOT, "Activar Cow Level");
	RegAdminCmd("sm_diffstatus",    Command_Alias_Status,    ADMFLAG_ROOT, "Ver estado de dificultad");
	RegAdminCmd("sm_diffreset",     Command_Alias_Reset,     ADMFLAG_ROOT, "Resetear progresion");
}

public void DifficultyOrchestrator_OnMapStart()
{
	g_bFinaleCompleted = false;
	_DiffOrch_DetectActiveMode();
}

// =============================================================================
// REGISTRO DE MODOS
// Los modos llaman esto al final de su OnPluginStart()
// =============================================================================

void DifficultyOrchestrator_Register(DifficultyMode mode, Handle hEnableConVar)
{
	g_hModeConVars[view_as<int>(mode)] = hEnableConVar;
	HookConVarChange(hEnableConVar, ConVarChanged_ModeActivation);
	LogMessage("[DiffOrch] Registered mode %d", view_as<int>(mode));
}

// =============================================================================
// EVENTOS
// =============================================================================

public void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(g_cvar_DiffOrch_Enable))          return;
	if (!GetConVarBool(g_cvar_DiffOrch_ProgressionEnable)) return;

	g_bFinaleCompleted = true;
	CreateTimer(5.0, Timer_ProcessProgression, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
	g_iDifficultyWins = 0;
}

public Action Timer_ProcessProgression(Handle timer)
{
	if (!g_bFinaleCompleted) return Plugin_Stop;
	g_bFinaleCompleted = false;
	_DiffOrch_ProcessProgression();
	return Plugin_Stop;
}

// =============================================================================
// LOGICA DE PROGRESION
// =============================================================================

static void _DiffOrch_ProcessProgression()
{
	if (!GetConVarBool(g_cvar_DiffOrch_AutoUnlock)) return;

	char msg[256];

	switch (g_CurrentMode)
	{
		case MODE_NONE:
		{
			Format(msg, sizeof(msg), "%t", "DiffOrch_BloodmoonUnlocked");
			PrintToChatAll("\x05[Eclipse]\x04 %s", msg);
			EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");
			DifficultyOrchestrator_SetMode(MODE_BLOODMOON);
			g_iDifficultyWins = 0;
		}
		case MODE_BLOODMOON:
		{
			if (g_iDifficultyWins >= PROGRESSION_BLOODMOON_TO_HELL)
			{
				Format(msg, sizeof(msg), "%t", "DiffOrch_HellUnlocked");
				PrintToChatAll("\x05[Eclipse]\x04 %s", msg);
				EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");
				DifficultyOrchestrator_SetMode(MODE_HELL);
				g_iDifficultyWins = 0;
			}
			else g_iDifficultyWins++;
		}
		case MODE_HELL:
		{
			if (g_iDifficultyWins >= PROGRESSION_HELL_TO_INFERNO)
			{
				Format(msg, sizeof(msg), "%t", "DiffOrch_InfernoUnlocked");
				PrintToChatAll("\x05[Eclipse]\x04 %s", msg);
				EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");
				DifficultyOrchestrator_SetMode(MODE_INFERNO);
				g_iDifficultyWins = 0;
			}
			else g_iDifficultyWins++;
		}
		case MODE_INFERNO:
		{
			if (g_iDifficultyWins >= PROGRESSION_INFERNO_TO_COWLEVEL)
			{
				Format(msg, sizeof(msg), "%t", "DiffOrch_CowLevelUnlocked");
				PrintToChatAll("\x05[Eclipse]\x04 %s", msg);
				EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");
				DifficultyOrchestrator_SetMode(MODE_COWLEVEL);
				g_iDifficultyWins = 0;
			}
			else g_iDifficultyWins++;
		}
		case MODE_COWLEVEL:
		{
			Format(msg, sizeof(msg), "%t", "DiffOrch_AllCompleted");
			PrintToChatAll("\x05[Eclipse]\x04 %s", msg);
			DifficultyOrchestrator_SetMode(MODE_NONE);
			g_iDifficultyWins = 0;
		}
	}
}

// =============================================================================
// API PUBLICA
// =============================================================================

public void DifficultyOrchestrator_SetMode(DifficultyMode mode)
{
	if (!GetConVarBool(g_cvar_DiffOrch_Enable)) return;

	g_PreviousMode = g_CurrentMode;
	g_CurrentMode  = mode;

	if (GetConVarBool(g_cvar_DiffOrch_MutualExclusion))
		_DiffOrch_EnforceMutualExclusion(mode);

	_DiffOrch_ActivateMode(mode);

	LogMessage("[DiffOrch] Mode %d -> %d", view_as<int>(g_PreviousMode), view_as<int>(g_CurrentMode));
}

public DifficultyMode DifficultyOrchestrator_GetCurrentMode()  { return g_CurrentMode; }
public int  DifficultyOrchestrator_GetWinCount()               { return g_iDifficultyWins; }
public void DifficultyOrchestrator_SetWinCount(int wins)       { g_iDifficultyWins = wins; }

// =============================================================================
// MUTUAL EXCLUSION
// Desactiva todos los modos excepto el activo.
// Usa g_bOrchestratorChanging para que el hook del orquestador ignore
// los ConVar changes que el mismo genera, evitando recursion.
// El hook propio de cada modo (Bloodmoon_ConVarChanged, etc.) NO lee
// esta flag, por lo que la activacion/desactivacion real ocurre correctamente.
// =============================================================================

static void _DiffOrch_EnforceMutualExclusion(DifficultyMode activeMode)
{
	g_bOrchestratorChanging = true;

	for (int i = 1; i <= 4; i++)
	{
		if (view_as<DifficultyMode>(i) == activeMode) continue;
		Handle h = g_hModeConVars[i];
		if (h != INVALID_HANDLE && GetConVarBool(h))
			SetConVarBool(h, false);
	}

	g_bOrchestratorChanging = false;
}

// =============================================================================
// ACTIVACION DE MODO
// =============================================================================

static void _DiffOrch_ActivateMode(DifficultyMode mode)
{
	if (mode == MODE_NONE)
	{
		// Desactivar el modo que estaba corriendo
		int prev = view_as<int>(g_PreviousMode);
		Handle h = (prev >= 1 && prev <= 4) ? g_hModeConVars[prev] : INVALID_HANDLE;
		if (h != INVALID_HANDLE && GetConVarBool(h))
		{
			g_bOrchestratorChanging = true;
			SetConVarBool(h, false);
			g_bOrchestratorChanging = false;
		}
		return;
	}

	Handle h = g_hModeConVars[view_as<int>(mode)];
	if (h == INVALID_HANDLE)
	{
		LogMessage("[DiffOrch] Mode %d not registered", view_as<int>(mode));
		return;
	}

	// Establecer el ConVar a true.
	// El hook propio del modo (Bloodmoon_ConVarChanged, etc.) se encarga
	// de llamar a su funcion Activate(). El hook del orquestador se suprime.
	if (!GetConVarBool(h))
	{
		g_bOrchestratorChanging = true;
		SetConVarBool(h, true);
		g_bOrchestratorChanging = false;
	}
}

// =============================================================================
// HOOK: CAMBIO MANUAL DE CONVAR DE MODO
// Solo procesa cambios que NO hizo el orquestador.
// =============================================================================

public void ConVarChanged_ModeActivation(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (g_bOrchestratorChanging) return;
	if (!GetConVarBool(g_cvar_DiffOrch_Enable)) return;

	int newVal = StringToInt(newValue);
	int oldVal = StringToInt(oldValue);
	if (newVal == oldVal) return;

	DifficultyMode changedMode = MODE_NONE;
	for (int i = 1; i <= 4; i++)
	{
		if (g_hModeConVars[i] == convar)
		{
			changedMode = view_as<DifficultyMode>(i);
			break;
		}
	}
	if (changedMode == MODE_NONE) return;

	if (newVal == 1)
	{
		// Activacion manual: actualizar estado y aplicar mutual exclusion
		g_PreviousMode = g_CurrentMode;
		g_CurrentMode  = changedMode;

		if (GetConVarBool(g_cvar_DiffOrch_MutualExclusion))
			_DiffOrch_EnforceMutualExclusion(changedMode);

		LogMessage("[DiffOrch] Manual activation: mode %d", view_as<int>(changedMode));
	}
	else
	{
		// Desactivacion manual: si era el modo activo, pasar a NONE
		if (changedMode == g_CurrentMode)
		{
			g_PreviousMode = g_CurrentMode;
			g_CurrentMode  = MODE_NONE;
		}
	}
}

// =============================================================================
// DETECCION DE MODO ACTIVO (al inicio de mapa)
// =============================================================================

static void _DiffOrch_DetectActiveMode()
{
	DifficultyMode detected = MODE_NONE;

	// Prioridad: modo mas alto
	for (int i = 4; i >= 1; i--)
	{
		Handle h = g_hModeConVars[i];
		if (h != INVALID_HANDLE && GetConVarBool(h))
		{
			detected = view_as<DifficultyMode>(i);
			break;
		}
	}

	if (detected != g_CurrentMode)
	{
		g_PreviousMode = g_CurrentMode;
		g_CurrentMode  = detected;
		LogMessage("[DiffOrch] Detected active mode: %d", view_as<int>(g_CurrentMode));
	}
}

// =============================================================================
// COMANDOS ADMIN
// =============================================================================

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
		char modeName[32];
		_DiffOrch_GetModeName(g_CurrentMode, modeName, sizeof(modeName));
		ReplyToCommand(client, "[Difficulty] Mode: %s | Wins: %d | MutEx: %s | Progression: %s",
			modeName, g_iDifficultyWins,
			GetConVarBool(g_cvar_DiffOrch_MutualExclusion) ? "ON" : "OFF",
			GetConVarBool(g_cvar_DiffOrch_ProgressionEnable) ? "ON" : "OFF");
		return Plugin_Handled;
	}

	DifficultyMode newMode;
	if      (StrEqual(arg, "none",      false)) newMode = MODE_NONE;
	else if (StrEqual(arg, "bloodmoon", false)) newMode = MODE_BLOODMOON;
	else if (StrEqual(arg, "hell",      false)) newMode = MODE_HELL;
	else if (StrEqual(arg, "inferno",   false)) newMode = MODE_INFERNO;
	else if (StrEqual(arg, "cowlevel",  false)) newMode = MODE_COWLEVEL;
	else { ReplyToCommand(client, "[Difficulty] Invalid mode: %s", arg); return Plugin_Handled; }

	char modeName[32];
	_DiffOrch_GetModeName(newMode, modeName, sizeof(modeName));
	ReplyToCommand(client, "[Difficulty] Setting mode: %s", modeName);
	DifficultyOrchestrator_SetMode(newMode);
	return Plugin_Handled;
}

public Action Command_ResetProgression(int client, int args)
{
	g_iDifficultyWins = 0;
	DifficultyOrchestrator_SetMode(MODE_NONE);
	ReplyToCommand(client, "[Difficulty] Progression reset.");
	PrintToChatAll("\x05[Eclipse]\x01 Difficulty progression reset by admin.");
	return Plugin_Handled;
}

public Action Command_Alias_Bloodmoon(int client, int args)
{
	DifficultyOrchestrator_SetMode(MODE_BLOODMOON);
	ReplyToCommand(client, "[Difficulty] Bloodmoon activated");
	return Plugin_Handled;
}

public Action Command_Alias_Hell(int client, int args)
{
	DifficultyOrchestrator_SetMode(MODE_HELL);
	ReplyToCommand(client, "[Difficulty] Hell Mode activated");
	return Plugin_Handled;
}

public Action Command_Alias_Inferno(int client, int args)
{
	DifficultyOrchestrator_SetMode(MODE_INFERNO);
	ReplyToCommand(client, "[Difficulty] Inferno Mode activated");
	return Plugin_Handled;
}

public Action Command_Alias_CowLevel(int client, int args)
{
	DifficultyOrchestrator_SetMode(MODE_COWLEVEL);
	ReplyToCommand(client, "[Difficulty] Cow Level activated");
	return Plugin_Handled;
}

public Action Command_Alias_Status(int client, int args)
{
	char modeName[32];
	_DiffOrch_GetModeName(g_CurrentMode, modeName, sizeof(modeName));
	ReplyToCommand(client, "[Difficulty] Mode: %s | Wins: %d | MutEx: %s | Progression: %s",
		modeName, g_iDifficultyWins,
		GetConVarBool(g_cvar_DiffOrch_MutualExclusion) ? "ON" : "OFF",
		GetConVarBool(g_cvar_DiffOrch_ProgressionEnable) ? "ON" : "OFF");
	return Plugin_Handled;
}

public Action Command_Alias_Reset(int client, int args)
{
	return Command_ResetProgression(client, args);
}

// =============================================================================
// UTILIDAD
// =============================================================================

static void _DiffOrch_GetModeName(DifficultyMode mode, char[] buffer, int maxlen)
{
	switch (mode)
	{
		case MODE_NONE:      strcopy(buffer, maxlen, "None");
		case MODE_BLOODMOON: strcopy(buffer, maxlen, "Bloodmoon");
		case MODE_HELL:      strcopy(buffer, maxlen, "Hell");
		case MODE_INFERNO:   strcopy(buffer, maxlen, "Inferno");
		case MODE_COWLEVEL:  strcopy(buffer, maxlen, "Cow Level");
		default:             strcopy(buffer, maxlen, "Unknown");
	}
}
