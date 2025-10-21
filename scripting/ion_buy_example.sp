/**
 * Ejemplo de integración del Ion Cannon con un sistema de compras
 * Este es un ejemplo funcional de cómo usar la API de ion_cannon.inc
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <ion_cannon>

public Plugin myinfo =
{
	name		= "Ion Cannon - Buy System Example",
	author		= "Socius",
	description = "Ejemplo de integración con sistema de compras",
	version		= "1.0.0",
	url			= ""
};

// Simulación de puntos (en tu sistema real, esto vendría de tu plugin de puntos)
int g_PlayerPoints[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_buyion", Cmd_BuyIon, "Comprar Ion Cannon");
	RegConsoleCmd("sm_points", Cmd_ShowPoints, "Ver tus puntos");

	// Simular puntos para testing
	RegAdminCmd("sm_givepoints", Cmd_GivePoints, ADMFLAG_CHEATS, "Dar puntos a jugador");
}

public void OnClientPutInServer(int client)
{
	// Dar puntos iniciales para testing
	g_PlayerPoints[client] = 10000;
}

// ===================== COMANDO DE COMPRA =====================
public Action Cmd_BuyIon(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	int cost = 5000;  // Costo del Ion Cannon

	// Verificar si puede usar Ion Cannon
	if (!Ion_CanUse(client))
	{
		float cooldown = Ion_GetCooldown(client);
		if (cooldown > 0.0)
		{
			PrintToChat(client, "\x04[Buy]\x01 Ion Cannon en cooldown: \x03%.0f\x01 segundos", cooldown);
		}
		else
		{
			PrintToChat(client, "\x04[Buy]\x01 No puedes usar Ion Cannon ahora");
		}
		return Plugin_Handled;
	}

	// Verificar puntos
	if (g_PlayerPoints[client] < cost)
	{
		PrintToChat(client, "\x04[Buy]\x01 Puntos insuficientes! Necesitas: \x05%d\x01 (Tienes: \x03%d\x01)",
			cost, g_PlayerPoints[client]);
		return Plugin_Handled;
	}

	// Cobrar puntos
	g_PlayerPoints[client] -= cost;

	// Activar Ion Cannon
	if (Ion_Activate(client))
	{
		PrintToChat(client, "\x04[Buy]\x01 Ion Cannon activado! (-\x03%d\x01 puntos)", cost);
		PrintToChat(client, "\x04[Buy]\x01 Puntos restantes: \x05%d", g_PlayerPoints[client]);
	}
	else
	{
		// Reembolsar si falla
		g_PlayerPoints[client] += cost;
		PrintToChat(client, "\x04[Buy]\x01 Error al activar Ion Cannon (reembolsado)");
	}

	return Plugin_Handled;
}

// ===================== FORWARDS DEL ION CANNON =====================

/**
 * Llamado cuando el Ion Cannon se activa
 */
public void Ion_OnActivate(int client)
{
	PrintToChatAll("\x04[Ion]\x01 \x05%N\x01 ha activado el \x03Ion Cannon\x01!", client);

	// Aquí puedes agregar lógica adicional cuando se activa:
	// - Efectos de sonido globales
	// - Mensajes especiales
	// - Buffs temporales
	// - etc.
}

/**
 * Llamado cuando el Ion Cannon termina
 * Aquí es donde recompensas al jugador por los kills
 */
public void Ion_OnComplete(int client, int kills)
{
	if (!IsValidClient(client))
		return;

	if (kills > 0)
	{
		// Fórmula de recompensa: 10 puntos por kill
		int bonus = kills * 10;
		g_PlayerPoints[client] += bonus;

		PrintToChat(client, "\x04[Ion]\x01 Bonus: \x05+%d\x01 puntos (\x03%d\x01 kills)", bonus, kills);
		PrintToChat(client, "\x04[Ion]\x01 Puntos totales: \x05%d", g_PlayerPoints[client]);

		// Anunciar si fue especialmente efectivo
		if (kills >= 30)
		{
			PrintToChatAll("\x04[Ion]\x01 \x05%N\x01 eliminó \x03%d\x01 infectados! (+\x05%d\x01 pts)",
				client, kills, bonus);
		}
	}
	else
	{
		PrintToChat(client, "\x04[Ion]\x01 Completado - Sin kills esta vez");
	}
}

// ===================== COMANDOS DE UTILIDAD =====================

public Action Cmd_ShowPoints(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	int charges = Ion_GetCharges(client);
	float cooldown = Ion_GetCooldown(client);

	PrintToChat(client, "\x04[Buy]\x01 === Tu Información ===");
	PrintToChat(client, "\x04[Buy]\x01 Puntos: \x05%d", g_PlayerPoints[client]);
	PrintToChat(client, "\x04[Buy]\x01 Ion Cannon:");

	if (cooldown > 0.0)
	{
		PrintToChat(client, "  - Cooldown: \x03%.0f\x01 segundos", cooldown);
	}
	else
	{
		PrintToChat(client, "  - Estado: \x05DISPONIBLE");
	}

	PrintToChat(client, "  - Cargas: \x05%d", charges);

	return Plugin_Handled;
}

public Action Cmd_GivePoints(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[Buy] Uso: sm_givepoints <jugador> <cantidad>");
		return Plugin_Handled;
	}

	char targetName[MAX_NAME_LENGTH], pointsStr[16];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, pointsStr, sizeof(pointsStr));

	int target = FindTarget(client, targetName, true, false);
	if (target == -1)
		return Plugin_Handled;

	int points = StringToInt(pointsStr);
	g_PlayerPoints[target] += points;

	ReplyToCommand(client, "[Buy] Otorgados %d puntos a %N (Total: %d)",
		points, target, g_PlayerPoints[target]);
	PrintToChat(target, "\x04[Buy]\x01 Has recibido \x05%d\x01 puntos", points);

	return Plugin_Handled;
}

// ===================== HELPERS =====================

bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}
