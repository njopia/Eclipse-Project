#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

#define _EMPTY_SERVER_RESTART_MODULE_

//==================================================
// === EMPTY SERVER RESTART MODULE ===
// Si no hay jugadores humanos en el servidor durante
// el intervalo configurado, lo reinicia automáticamente.
//==================================================

#define EMPTY_RESTART_INTERVAL 120.0   // 2 minutos entre cada chequeo

static ConVar g_hEmptyRestartEnabled;

/**
 * Inicializa el módulo
 */
public void EmptyServerRestart_OnPluginStart()
{
	g_hEmptyRestartEnabled = CreateConVar(
		"empty_restart_enable",
		"1",
		"Reinicia el servidor si no hay jugadores humanos (0 = desactivado)",
		FCVAR_PLUGIN
	);

	CreateTimer(EMPTY_RESTART_INTERVAL, Timer_EmptyServerCheck, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Timer: cada 2 minutos verifica si el servidor está vacío
 */
public Action Timer_EmptyServerCheck(Handle timer)
{
	if (!g_hEmptyRestartEnabled.BoolValue)
		return Plugin_Continue;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			return Plugin_Continue;   // Hay al menos un humano, no hacer nada
	}

	// Servidor vacío
	LogMessage("[Eclipse] Servidor vacío detectado — reiniciando servidor.");
	PrintToServer("[Eclipse] Servidor vacío — ejecutando _restart.");
	ServerCommand("_restart");

	return Plugin_Continue;
}
