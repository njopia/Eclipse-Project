#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === CURRENCY STATS MODULE ===
// Rastrea y registra estadisticas de currency ganada
//==================================================

// --- Arrays para estadisticas de currency ---
int g_iCurrencyEarned[MAXPLAYERS + 1];	  // Total de currency ganada por sesion
int g_iCommonKills[MAXPLAYERS + 1];		  // Total de infectados comunes matados
int g_iSpecialKills[MAXPLAYERS + 1];	  // Total de especiales matados
int g_iHeadshots[MAXPLAYERS + 1];		  // Total de headshots
int g_iTotalRevivals[MAXPLAYERS + 1];	  // Total de revives dados
int g_iTotalHeals[MAXPLAYERS + 1];		  // Total de curaciones dadas

/**
 * Inicializa el modulo de estadisticas de currency
 */
public void CurrencyStats_OnPluginStart()
{
	// No hay ConVars, solo inicializacion de arrays
	// Los arrays se resetean en ResetPlayerCurrencyStats()
	for (int i = 1; i <= MaxClients; i++)
	{
		ResetPlayerCurrencyStats(i);
	}
}

/**
 * Resetea todas las estadisticas de un jugador
 * Debe ser llamada en OnClientDisconnect
 */
public void ResetPlayerCurrencyStats(int client)
{
	g_iCurrencyEarned[client] = 0;
	g_iCommonKills[client]	  = 0;
	g_iSpecialKills[client]	  = 0;
	g_iHeadshots[client]	  = 0;
	g_iTotalRevivals[client]  = 0;
	g_iTotalHeals[client]	  = 0;
}

/**
 * Reporta estadisticas de currency del jugador
 * Util para debugging y auditoria
 */
stock void CurrencyStats_PrintPlayerStats(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return;

	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));

	int balance = GetPlayerCurrency(client);

	PrintToChat(client, "\x05[Currency Stats]\x01 ==================");
	PrintToChat(client, "\x05Jugador: \x04%s", clientName);
	PrintToChat(client, "\x05Balance: \x04%d", balance);
	PrintToChat(client, "\x05Total Ganado: \x04%d", g_iCurrencyEarned[client]);
	PrintToChat(client, "\x05Infectados Comunes Matados: \x04%d", g_iCommonKills[client]);
	PrintToChat(client, "\x05Especiales Matados: \x04%d", g_iSpecialKills[client]);
	PrintToChat(client, "\x05Headshots: \x04%d", g_iHeadshots[client]);
	PrintToChat(client, "\x05Revives Dados: \x04%d", g_iTotalRevivals[client]);
	PrintToChat(client, "\x05Curaciones Dadas: \x04%d", g_iTotalHeals[client]);
	PrintToChat(client, "\x05[Currency Stats]\x01 ==================");
}

/**
 * Incrementa contador de infectados comunes matados
 */
stock void CurrencyStats_AddCommonKill(int client)
{
	if (client <= 0 || client > MaxClients)
		return;
	g_iCommonKills[client]++;
}

/**
 * Incrementa contador de especiales matados
 */
stock void CurrencyStats_AddSpecialKill(int client)
{
	if (client <= 0 || client > MaxClients)
		return;
	g_iSpecialKills[client]++;
}

/**
 * Incrementa contador de headshots
 */
stock void CurrencyStats_AddHeadshot(int client)
{
	if (client <= 0 || client > MaxClients)
		return;
	g_iHeadshots[client]++;
}

/**
 * Incrementa contador de revives
 */
stock void CurrencyStats_AddRevival(int client)
{
	if (client <= 0 || client > MaxClients)
		return;
	g_iTotalRevivals[client]++;
}

/**
 * Incrementa contador de curaciones
 */
stock void CurrencyStats_AddHeal(int client)
{
	if (client <= 0 || client > MaxClients)
		return;
	g_iTotalHeals[client]++;
}

/**
 * Registra currency ganada en estadisticas
 * Debe ser llamada desde AwardCurrency
 */
stock void CurrencyStats_AddEarnings(int client, int amount)
{
	if (client <= 0 || client > MaxClients)
		return;
	g_iCurrencyEarned[client] += amount;
}

/**
 * Obtiene el total de currency ganada por sesion
 */
stock int CurrencyStats_GetTotalEarned(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;
	return g_iCurrencyEarned[client];
}

/**
 * Obtiene el total de infectados comunes matados
 */
stock int CurrencyStats_GetCommonKills(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;
	return g_iCommonKills[client];
}

/**
 * Obtiene el total de especiales matados
 */
stock int CurrencyStats_GetSpecialKills(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;
	return g_iSpecialKills[client];
}

/**
 * Obtiene el total de headshots
 */
stock int CurrencyStats_GetHeadshots(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;
	return g_iHeadshots[client];
}
