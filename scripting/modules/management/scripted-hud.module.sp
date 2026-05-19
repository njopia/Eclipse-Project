/**
 * ====================================================================================================
 * ECLIPSE MANAGEMENT SYSTEM - SCRIPTED HUD MODULE
 * ====================================================================================================
 * Modulo de HUD para mostrar informacion del servidor y jugadores
 * Adaptado de l4d2_scripted_hud.sp por Mart
 * ====================================================================================================
 */

#if defined _SCRIPTED_HUD_MODULE_
	#endinput
#endif
#define _SCRIPTED_HUD_MODULE_

// ====================================================================================================
// Defines
// ====================================================================================================
#define HUD1 0

#define HUD_FLAG_NONE			  0
#define HUD_FLAG_PRESTR			  1
#define HUD_FLAG_POSTSTR		  2
#define HUD_FLAG_BEEP			  4
#define HUD_FLAG_BLINK			  8
#define HUD_FLAG_AS_TIME		  16
#define HUD_FLAG_COUNTDOWN_WARN	  32
#define HUD_FLAG_NOBG			  64
#define HUD_FLAG_ALLOWNEGTIMER	  128
#define HUD_FLAG_ALIGN_LEFT		  256
#define HUD_FLAG_ALIGN_CENTER	  512
#define HUD_FLAG_ALIGN_RIGHT	  768
#define HUD_FLAG_TEAM_SURVIVORS	  1024
#define HUD_FLAG_TEAM_INFECTED	  2048
#define HUD_FLAG_TEAM_MASK		  3072
#define HUD_FLAG_UNKNOWN1		  4096
#define HUD_FLAG_TEXT			  8192
#define HUD_FLAG_NOTVISIBLE		  16384

#define HUD_TEAM_ALL			  0
#define HUD_TEAM_SURVIVOR		  1
#define HUD_TEAM_INFECTED		  2

#define HUD_TEXT_ALIGN_LEFT		  1
#define HUD_TEXT_ALIGN_CENTER	  2
#define HUD_TEXT_ALIGN_RIGHT	  3

#define HUD_X_LEFT_TO_RIGHT		  0
#define HUD_X_RIGHT_TO_LEFT		  1

#define HUD_Y_TOP_TO_BOTTOM		  0
#define HUD_Y_BOTTOM_TO_TOP		  1

#if !defined TEAM_SURVIVOR
	#define TEAM_SURVIVOR			  2
#endif
#if !defined TEAM_INFECTED
	#define TEAM_INFECTED			  3
#endif

#define MSG_COUNT				  5
#define ROTATE_INTERVAL			  10.0
#define AUTO_RELOAD_INTERVAL	  30.0	// Auto-recarga de mensajes desde BD cada 30 segundos

// ====================================================================================================
// Module Variables
// ====================================================================================================
static Handle g_hDbHUDMessages;		// Handle para la conexion a la BD de mensajes

static ConVar g_hCvar_HUD_Enabled;
static ConVar g_hCvar_HUD_UpdateInterval;
static ConVar g_hCvar_HUD1_Text;
static ConVar g_hCvar_HUD1_TextAlign;
static ConVar g_hCvar_HUD1_BlinkTank;
static ConVar g_hCvar_HUD1_Blink;
static ConVar g_hCvar_HUD1_Beep;
static ConVar g_hCvar_HUD1_Visible;
static ConVar g_hCvar_HUD1_Background;
static ConVar g_hCvar_HUD1_Team;
static ConVar g_hCvar_HUD1_X;
static ConVar g_hCvar_HUD1_Y;
static ConVar g_hCvar_HUD1_Width;
static ConVar g_hCvar_HUD1_Height;

static bool	  g_bHUD_Enabled;
static bool	  g_bAliveTank;
static bool	  g_bCvar_HUD1_BlinkTank;
static bool	  g_bCvar_HUD1_Blink;
static bool	  g_bCvar_HUD1_Beep;
static bool	  g_bCvar_HUD1_Visible;
static bool	  g_bCvar_HUD1_Background;
static bool	  g_bCvar_HUD1_Text;

static int	  g_iCvar_HUD1_TextAlign;
static int	  g_iCvar_HUD1_Team;
static int	  g_iHUD1Flags;

static float  g_fCvar_HUD_UpdateInterval;
static float  g_fCvar_HUD1_X;
static float  g_fCvar_HUD1_Y;
static float  g_fCvar_HUD1_Width;
static float  g_fCvar_HUD1_Height;

static char	  g_sCvar_HUD1_Text[128];
static char	  g_sHUD_Text[512];
static char	  g_sHUD_TextArray[4][128];
static char	  g_sBuffer[128];
static char	  g_sSpaces[128] = "                                                                                                                               ";
static char  g_shortSpaces[64] = "    ☠    ";
static Handle g_tUpdateInterval;
static Handle g_tAutoReload;		// Timer para auto-recarga de mensajes

// Message rotation - Dynamic from database
#define MAX_HUD_MESSAGES 50
static char	  g_Messages[MAX_HUD_MESSAGES][128];
static int	  g_MessageCount = 0;
static char	  g_CurrentMessage[128];
static int	  g_MessageIndex = -1;

// ====================================================================================================
// Database Functions
// ====================================================================================================
bool ScriptedHUD_ConnectDatabase()
{
	char Error[256];
	g_hDbHUDMessages = SQL_Connect(DB_HUD_MESSAGES, true, Error, sizeof(Error));

	if (g_hDbHUDMessages == INVALID_HANDLE)
	{
		LogError("[ScriptedHUD] Error al conectar con la base de datos: %s", Error);
		return false;
	}

	LogMessage("[ScriptedHUD] Conexion a base de datos exitosa");
	return true;
}

void ScriptedHUD_LoadMessagesFromDB()
{
	if (g_hDbHUDMessages == INVALID_HANDLE)
	{
		LogError("[ScriptedHUD] No hay conexion a la base de datos");
		return;
	}

	// No resetear g_MessageCount aquí: los mensajes actuales siguen mostrándose
	// mientras la query asíncrona está en vuelo. El reset ocurre en el callback.

	char query[256];
	Format(query, sizeof(query), "SELECT message FROM server_hud_messages WHERE is_active = 1 ORDER BY id ASC");

	SQL_TQuery(g_hDbHUDMessages, ScriptedHUD_OnMessagesLoaded, query);
}

void ScriptedHUD_OnMessagesLoaded(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("[ScriptedHUD] Error al cargar mensajes: %s", error);
		// Cargar mensajes por defecto
		ScriptedHUD_LoadDefaultMessages();
		return;
	}

	g_MessageCount = 0;

	while (SQL_FetchRow(hndl) && g_MessageCount < MAX_HUD_MESSAGES)
	{
		SQL_FetchString(hndl, 0, g_Messages[g_MessageCount], sizeof(g_Messages[]));
		g_MessageCount++;
	}

	if (g_MessageCount == 0)
	{
		LogMessage("[ScriptedHUD] No se encontraron mensajes activos en la BD, usando mensajes por defecto");
		ScriptedHUD_LoadDefaultMessages();
	}
	else
	{
		LogMessage("[ScriptedHUD] %d mensajes cargados desde la base de datos", g_MessageCount);
	}

	// Actualizar g_CurrentMessage inmediatamente con los nuevos mensajes
	// para no esperar al próximo tick del timer de rotación (10 s).
	ScriptedHUD_AdvanceMessage();
}

void ScriptedHUD_LoadDefaultMessages()
{
	g_MessageCount = 5;
	strcopy(g_Messages[0], sizeof(g_Messages[]), "Welcome to Eclipse Server!");
	strcopy(g_Messages[1], sizeof(g_Messages[]), "Type !buy to access the shop");
	strcopy(g_Messages[2], sizeof(g_Messages[]), "Earn XP by killing zombies");
	strcopy(g_Messages[3], sizeof(g_Messages[]), "Level up to unlock bonuses");
	strcopy(g_Messages[4], sizeof(g_Messages[]), "Have fun playing!");

	LogMessage("[ScriptedHUD] Mensajes por defecto cargados");
}

// ====================================================================================================
// Module Initialization
// ====================================================================================================
void ScriptedHUD_OnPluginStart()
{
	// Conectar a la base de datos y cargar mensajes
	if (ScriptedHUD_ConnectDatabase())
	{
		ScriptedHUD_LoadMessagesFromDB();
	}
	else
	{
		ScriptedHUD_LoadDefaultMessages();
	}

	// Create ConVars
	g_hCvar_HUD_Enabled			= CreateConVar("ems_hud_enable", "1", "Enable/Disable the HUD module", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvar_HUD_UpdateInterval	= CreateConVar("ems_hud_update_interval", "0.1", "HUD update interval in seconds", FCVAR_NOTIFY, true, 0.1);
	g_hCvar_HUD1_Text			= CreateConVar("ems_hud1_text", "", "Custom text for HUD slot 1 (empty = auto)", FCVAR_NOTIFY);
	g_hCvar_HUD1_TextAlign		= CreateConVar("ems_hud1_text_align", "1", "Text alignment (1=LEFT, 2=CENTER, 3=RIGHT)", FCVAR_NOTIFY, true, 1.0, true, 3.0);
	g_hCvar_HUD1_BlinkTank		= CreateConVar("ems_hud1_blink_tank", "1", "Blink when tank is alive", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvar_HUD1_Blink			= CreateConVar("ems_hud1_blink", "0", "Always blink text", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvar_HUD1_Beep			= CreateConVar("ems_hud1_beep", "0", "Beep sound when blinking", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvar_HUD1_Visible		= CreateConVar("ems_hud1_visible", "1", "HUD visibility", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvar_HUD1_Background		= CreateConVar("ems_hud1_background", "0", "Show background", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvar_HUD1_Team			= CreateConVar("ems_hud1_team", "0", "Team filter (0=ALL, 1=SURVIVOR, 2=INFECTED)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_hCvar_HUD1_X				= CreateConVar("ems_hud1_x", "0.02", "X position", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_hCvar_HUD1_Y				= CreateConVar("ems_hud1_y", "0.015", "Y position", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_hCvar_HUD1_Width			= CreateConVar("ems_hud1_width", "1.5", "Text area width", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_hCvar_HUD1_Height			= CreateConVar("ems_hud1_height", "0.026", "Text area height", FCVAR_NOTIFY, true, 0.0, true, 2.0);

	// Hook ConVar changes
	g_hCvar_HUD_Enabled.AddChangeHook(ScriptedHUD_OnCvarChanged);
	g_hCvar_HUD_UpdateInterval.AddChangeHook(ScriptedHUD_OnCvarChanged);
	g_hCvar_HUD1_Text.AddChangeHook(ScriptedHUD_OnCvarChanged);
	g_hCvar_HUD1_TextAlign.AddChangeHook(ScriptedHUD_OnCvarChanged);
	g_hCvar_HUD1_BlinkTank.AddChangeHook(ScriptedHUD_OnCvarChanged);
	g_hCvar_HUD1_Blink.AddChangeHook(ScriptedHUD_OnCvarChanged);
	g_hCvar_HUD1_Beep.AddChangeHook(ScriptedHUD_OnCvarChanged);
	g_hCvar_HUD1_Visible.AddChangeHook(ScriptedHUD_OnCvarChanged);
	g_hCvar_HUD1_Background.AddChangeHook(ScriptedHUD_OnCvarChanged);
	g_hCvar_HUD1_Team.AddChangeHook(ScriptedHUD_OnCvarChanged);
	g_hCvar_HUD1_X.AddChangeHook(ScriptedHUD_OnCvarChanged);
	g_hCvar_HUD1_Y.AddChangeHook(ScriptedHUD_OnCvarChanged);
	g_hCvar_HUD1_Width.AddChangeHook(ScriptedHUD_OnCvarChanged);
	g_hCvar_HUD1_Height.AddChangeHook(ScriptedHUD_OnCvarChanged);

	// Initialize message rotation (TIMER_FLAG_NO_MAPCHANGE: persiste entre mapas)
	ScriptedHUD_AdvanceMessage();
	CreateTimer(ROTATE_INTERVAL, ScriptedHUD_Timer_RotateMessage, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, ScriptedHUD_Timer_CheckTank, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	// Initialize auto-reload timer
	g_tAutoReload = CreateTimer(AUTO_RELOAD_INTERVAL, ScriptedHUD_Timer_AutoReload, _, TIMER_REPEAT);
	LogMessage("[ScriptedHUD] Auto-reload timer iniciado (cada %.1f segundos)", AUTO_RELOAD_INTERVAL);
}

void ScriptedHUD_OnConfigsExecuted()
{
	ScriptedHUD_GetCvars();

	delete g_tUpdateInterval;
	g_tUpdateInterval = CreateTimer(g_fCvar_HUD_UpdateInterval, ScriptedHUD_Timer_UpdateHUD, _, TIMER_REPEAT);

	// g_tAutoReload muere en cada cambio de mapa (sin TIMER_FLAG_NO_MAPCHANGE): recrear
	if (g_tAutoReload == INVALID_HANDLE)
	{
		g_tAutoReload = CreateTimer(AUTO_RELOAD_INTERVAL, ScriptedHUD_Timer_AutoReload, _, TIMER_REPEAT);
		ScriptedHUD_LoadMessagesFromDB();
	}

	// Re-habilitar challenge mode DESPUÉS de que los timers estén creados y haya mapa cargado.
	// GameRules_SetProp falla si no hay mapa activo → verificar antes de llamar.
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (sMap[0] != '\0')
		GameRules_SetProp("m_bChallengeModeActive", 1);
}

void ScriptedHUD_OnMapStart()
{
	// Enable HUD drawing
	GameRules_SetProp("m_bChallengeModeActive", 1);
}

void ScriptedHUD_OnMapEnd()
{
	// Limpiar timers que no tienen TIMER_FLAG_NO_MAPCHANGE
	delete g_tUpdateInterval;
	g_tUpdateInterval = INVALID_HANDLE;

	delete g_tAutoReload;
	g_tAutoReload = INVALID_HANDLE;
}

// ====================================================================================================
// ConVar Change Handler
// ====================================================================================================
void ScriptedHUD_OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hCvar_HUD1_Background)
		RequestFrame(ScriptedHUD_OnNextFrame_RefreshBackground, HUD1);

	ScriptedHUD_GetCvars();

	delete g_tUpdateInterval;
	g_tUpdateInterval = CreateTimer(g_fCvar_HUD_UpdateInterval, ScriptedHUD_Timer_UpdateHUD, _, TIMER_REPEAT);
}

void ScriptedHUD_OnNextFrame_RefreshBackground(int hudid)
{
	if (!g_bHUD_Enabled)
		return;

	GameRules_SetProp("m_iScriptedHUDFlags", HUD_FLAG_NOTVISIBLE, _, hudid);
}

// ====================================================================================================
// Get ConVar Values
// ====================================================================================================
void ScriptedHUD_GetCvars()
{
	g_bHUD_Enabled				= g_hCvar_HUD_Enabled.BoolValue;
	g_fCvar_HUD_UpdateInterval	= g_hCvar_HUD_UpdateInterval.FloatValue;

	g_hCvar_HUD1_Text.GetString(g_sCvar_HUD1_Text, sizeof(g_sCvar_HUD1_Text));
	g_bCvar_HUD1_Text			= (g_sCvar_HUD1_Text[0] != 0);
	g_iCvar_HUD1_TextAlign		= g_hCvar_HUD1_TextAlign.IntValue;
	g_bCvar_HUD1_BlinkTank		= g_hCvar_HUD1_BlinkTank.BoolValue;
	g_bCvar_HUD1_Blink			= g_hCvar_HUD1_Blink.BoolValue;
	g_bCvar_HUD1_Beep			= g_hCvar_HUD1_Beep.BoolValue;
	g_bCvar_HUD1_Visible		= g_hCvar_HUD1_Visible.BoolValue;
	g_bCvar_HUD1_Background		= g_hCvar_HUD1_Background.BoolValue;
	g_iCvar_HUD1_Team			= g_hCvar_HUD1_Team.IntValue;
	g_fCvar_HUD1_X				= g_hCvar_HUD1_X.FloatValue;
	g_fCvar_HUD1_Y				= g_hCvar_HUD1_Y.FloatValue;
	g_fCvar_HUD1_Width			= g_hCvar_HUD1_Width.FloatValue;
	g_fCvar_HUD1_Height			= g_hCvar_HUD1_Height.FloatValue;

	ScriptedHUD_GetHUDFlags();
}

// ====================================================================================================
// Calculate HUD Flags
// ====================================================================================================
void ScriptedHUD_GetHUDFlags()
{
	g_iHUD1Flags = HUD_FLAG_TEXT;

	switch (g_iCvar_HUD1_TextAlign)
	{
		case 1: g_iHUD1Flags |= HUD_FLAG_ALIGN_LEFT;
		case 2: g_iHUD1Flags |= HUD_FLAG_ALIGN_CENTER;
		case 3: g_iHUD1Flags |= HUD_FLAG_ALIGN_RIGHT;
	}

	switch (g_iCvar_HUD1_Team)
	{
		case 1: g_iHUD1Flags |= HUD_FLAG_TEAM_SURVIVORS;
		case 2: g_iHUD1Flags |= HUD_FLAG_TEAM_INFECTED;
	}

	if (!g_bCvar_HUD1_Visible)
		g_iHUD1Flags |= HUD_FLAG_NOTVISIBLE;

	if (!g_bCvar_HUD1_Background)
		g_iHUD1Flags |= HUD_FLAG_NOBG;

	if (g_bCvar_HUD1_Blink)
		g_iHUD1Flags |= HUD_FLAG_BLINK;

	if (g_bCvar_HUD1_Beep)
		g_iHUD1Flags |= HUD_FLAG_BEEP;
}

// ====================================================================================================
// Timers
// ====================================================================================================
Action ScriptedHUD_Timer_CheckTank(Handle timer)
{
	if (g_bAliveTank)
		g_bAliveTank = ScriptedHUD_HasAnyTankAlive();

	return Plugin_Continue;
}

Action ScriptedHUD_Timer_UpdateHUD(Handle timer)
{
	if (g_bHUD_Enabled)
		ScriptedHUD_UpdateHUD();

	return Plugin_Continue;
}

Action ScriptedHUD_Timer_RotateMessage(Handle timer)
{
	ScriptedHUD_AdvanceMessage();
	return Plugin_Continue;
}

Action ScriptedHUD_Timer_AutoReload(Handle timer)
{
	ScriptedHUD_LoadMessagesFromDB();
	return Plugin_Continue;
}

// ====================================================================================================
// Update HUD
// ====================================================================================================
void ScriptedHUD_UpdateHUD()
{
	ScriptedHUD_GetHUDText();

	if (g_bCvar_HUD1_BlinkTank && g_bAliveTank)
		GameRules_SetProp("m_iScriptedHUDFlags", g_iHUD1Flags | HUD_FLAG_BLINK, _, HUD1);
	else
		GameRules_SetProp("m_iScriptedHUDFlags", g_iHUD1Flags, _, HUD1);

	GameRules_SetPropFloat("m_fScriptedHUDPosX", g_fCvar_HUD1_X, HUD1);
	GameRules_SetPropFloat("m_fScriptedHUDPosY", g_fCvar_HUD1_Y, HUD1);
	GameRules_SetPropFloat("m_fScriptedHUDWidth", g_fCvar_HUD1_Width, HUD1);
	GameRules_SetPropFloat("m_fScriptedHUDHeight", g_fCvar_HUD1_Height * (ScriptedHUD_CountChar(g_sHUD_TextArray[HUD1], '\n') + 1), HUD1);

	ImplodeStrings(g_sHUD_TextArray, sizeof(g_sHUD_TextArray), " ", g_sHUD_Text, sizeof(g_sHUD_Text));
	GameRules_SetPropString("m_szScriptedHUDStringSet", g_sHUD_Text);
}

// ====================================================================================================
// Get HUD Text
// ====================================================================================================
void ScriptedHUD_GetHUDText()
{
	g_sBuffer = "\0";

	if (g_bCvar_HUD1_Text)
	{
		FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s%s", g_sCvar_HUD1_Text, g_sSpaces);
	}
	else
	{
		char hostName[128];
		FindConVar("hostname").GetString(hostName, sizeof(hostName));
		FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s %s %s %s", hostName,g_shortSpaces, g_CurrentMessage, g_sSpaces);
	}

	g_sHUD_TextArray[HUD1] = g_sBuffer;
}

// ====================================================================================================
// Message Rotation
// ====================================================================================================
void ScriptedHUD_AdvanceMessage()
{
	if (g_MessageCount == 0)
	{
		strcopy(g_CurrentMessage, sizeof(g_CurrentMessage), "Eclipse Server");
		return;
	}

	g_MessageIndex = (g_MessageIndex + 1) % g_MessageCount;
	strcopy(g_CurrentMessage, sizeof(g_CurrentMessage), g_Messages[g_MessageIndex]);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action ScriptedHUD_Cmd_ReloadMessages(int client, int args)
{
	ScriptedHUD_LoadMessagesFromDB();

	if (client > 0)
	{
		PrintToChat(client, "\x04[HUD]\x01 Mensajes recargados desde la base de datos. Total: \x05%d\x01 mensajes", g_MessageCount);
	}

	PrintToServer("[ScriptedHUD] Mensajes recargados por %N. Total: %d mensajes", client > 0 ? client : 0, g_MessageCount);

	return Plugin_Handled;
}

// ====================================================================================================
// Helper Functions
// ====================================================================================================
bool ScriptedHUD_HasAnyTankAlive()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		if (GetClientTeam(client) != TEAM_INFECTED)
			continue;

		if (!IsPlayerAlive(client))
			continue;

		if (GetEntProp(client, Prop_Send, "m_zombieClass") != 8) // 8 = Tank
			continue;

		if (GetEntProp(client, Prop_Send, "m_isGhost") == 1)
			continue;

		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1)
			continue;

		return true;
	}

	return false;
}

int ScriptedHUD_CountChar(const char[] str, char c)
{
	int i;
	int count;

	while (str[i] != 0)
	{
		if (str[i++] == c)
			count++;
	}

	return count;
}
