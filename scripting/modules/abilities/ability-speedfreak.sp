//==================================================
// === SPEED FREAK ABILITY (Level 31) ===
// Insanely fast movement speed + faster healing
// Sets health to 50 HP during effect
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

int g_iSpeedFreak_OriginalHealth[MAXPLAYERS + 1];

/**
 * Activa Speed Freak
 */
bool Ability_SpeedFreak_Activate(int client)
{
	// Guardar HP original
	g_iSpeedFreak_OriginalHealth[client] = GetClientHealth(client);

	// Establecer HP a 50
	SetEntityHealth(client, 50);

	// Aumentar velocidad drasticamente
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 2.5); // 250% velocidad

	// Efecto visual azul
	int clients[1];
	clients[0] = client;
	int color[4] = {0, 100, 255, 60};
	int duration = 60000;
	int flags = 0x0001;

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, 500);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
		EndMessage();
	}

	PrintToChat(client, "\x04[Speed Freak]\x01 ¡Velocidad máxima! HP reducido a 50.");
	return true;
}

/**
 * Desactiva Speed Freak
 */
void Ability_SpeedFreak_Deactivate(int client)
{
	if (!IsClientInGame(client))
		return;

	// Restaurar velocidad normal
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);

	// Restaurar HP (o dar 100 como mínimo)
	int currentHP = GetClientHealth(client);
	if (currentHP < 100 && g_iSpeedFreak_OriginalHealth[client] >= 100)
	{
		SetEntityHealth(client, 100);
	}

	// Limpiar efecto visual
	int clients[1];
	clients[0] = client;
	int color[4] = {0, 0, 0, 0};

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, 500);
		BfWriteShort(message, 500);
		BfWriteShort(message, 0x0002);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
		EndMessage();
	}
}
