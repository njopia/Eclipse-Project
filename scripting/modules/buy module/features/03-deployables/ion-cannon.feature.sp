//////////////////////////////
// DEPLOYABLES: Ion Cannon  //
//////////////////////////////

#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

// Include Ion Cannon API
#include <ion_cannon>

float g_LastIonPurchase[MAXPLAYERS + 1];

/**
 * Comprar y activar Ion Cannon desde el menú
 *
 * @param client    Cliente que compra
 * @return          true si se activó exitosamente
 */
stock bool BuyIonCannon(int client)
{
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		if (client > 0)
			PrintToChat(client, "\x04[Eclipse]\x01 Debes estar vivo para usar Ion Cannon.");
		return false;
	}

	// Verificar team (solo sobrevivientes)
	if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Solo sobrevivientes pueden usar Ion Cannon.");
		return false;
	}

	// Verificar cooldown de compra
	float now = GetGameTime();
	float timeSinceLastPurchase = now - g_LastIonPurchase[client];

	if (timeSinceLastPurchase < CONFIG_IONCANNON_BUY_COOLDOWN)
	{
		float remaining = CONFIG_IONCANNON_BUY_COOLDOWN - timeSinceLastPurchase;
		PrintToChat(client, "\x04[Eclipse]\x01 Espera \x05%.1f\x01 segundos antes de comprar Ion Cannon nuevamente.", remaining);
		return false;
	}

	// Verificar si puede usar Ion Cannon (cooldown interno + cargas)
	if (!Ion_CanUse(client))
	{
		float cooldown = Ion_GetCooldown(client);
		int charges = Ion_GetCharges(client);

		if (cooldown > 0.0)
		{
			PrintToChat(client, "\x04[Eclipse]\x01 Ion Cannon en cooldown: \x05%.0f\x01 segundos.", cooldown);
		}
		else if (charges <= 0)
		{
			PrintToChat(client, "\x04[Eclipse]\x01 Sin cargas de Ion Cannon disponibles.");
		}

		return false;
	}

	// Activar Ion Cannon
	if (Ion_Activate(client))
	{
		g_LastIonPurchase[client] = now;
		PrintToChat(client, "\x04[Eclipse]\x01 ⚡ \x05Ion Cannon\x01 activado! Cargas restantes: \x05%d", Ion_GetCharges(client));
		return true;
	}
	else
	{
		PrintToChat(client, "\x04[Eclipse]\x01 No se pudo activar Ion Cannon. Intenta nuevamente.");
		return false;
	}
}

/**
 * Obtener información del Ion Cannon para mostrar en el menú
 *
 * @param client    Cliente
 * @param buffer    Buffer para el texto
 * @param maxlen    Tamaño del buffer
 */
stock void GetIonCannonInfo(int client, char[] buffer, int maxlen)
{
	int charges = Ion_GetCharges(client);
	float cooldown = Ion_GetCooldown(client);

	if (cooldown > 0.0)
	{
		Format(buffer, maxlen, "Ion Cannon [CD: %.0fs]", cooldown);
	}
	else if (charges > 0)
	{
		Format(buffer, maxlen, "Ion Cannon [%d cargas]", charges);
	}
	else
	{
		Format(buffer, maxlen, "Ion Cannon [Sin cargas]");
	}
}

/**
 * Verificar si el cliente puede comprar Ion Cannon
 *
 * @param client    Cliente
 * @return          true si puede comprar
 */
stock bool CanBuyIonCannon(int client)
{
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return false;

	if (GetClientTeam(client) != 2)
		return false;

	// Verificar cooldown de compra
	float now = GetGameTime();
	float timeSinceLastPurchase = now - g_LastIonPurchase[client];

	if (timeSinceLastPurchase < CONFIG_IONCANNON_BUY_COOLDOWN)
		return false;

	// Verificar si tiene cargas y no está en cooldown
	return Ion_CanUse(client);
}

/**
 * Reset del sistema cuando el cliente se desconecta
 */
public void IonCannon_OnClientDisconnect(int client)
{
	g_LastIonPurchase[client] = 0.0;
}

// Forward del Ion Cannon cuando se completa
public void Ion_OnComplete(int client, int kills)
{
	if (client > 0 && IsClientInGame(client))
	{
		if (kills > 0)
		{
			PrintToChat(client, "\x04[Eclipse]\x01 Ion Cannon completado: \x05%d\x01 kills", kills);
		}
		else
		{
			PrintToChat(client, "\x04[Eclipse]\x01 Ion Cannon completado (sin kills).");
		}
	}
}
