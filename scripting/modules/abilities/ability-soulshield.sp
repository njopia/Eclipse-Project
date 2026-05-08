//==================================================
// === SOULSHIELD ABILITY (Level 37) ===
// Complete invulnerability - no damage taken
// Visual effect shows damage absorbed
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

int g_iSoulshield_DamageBlocked[MAXPLAYERS + 1];

/**
 * Activa Soulshield
 */
bool Ability_Soulshield_Activate(int client)
{
	g_iSoulshield_DamageBlocked[client] = 0;

	// Dar godmode temporal
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);

	// Efecto visual dorado/blanco brillante
	int clients[1];
	clients[0] = client;
	int color[4] = {255, 255, 200, 100};
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

	// Hook de dano para trackear bloques
	SDKHook(client, SDKHook_OnTakeDamage, Soulshield_OnTakeDamage);

	PrintToChat(client, "\x04[Soulshield]\x01 Invulnerabilidad total! No recibes dano.");
	return true;
}

/**
 * Desactiva Soulshield
 */
void Ability_Soulshield_Deactivate(int client)
{
	if (!IsClientInGame(client))
		return;

	// Remover godmode
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);

	// Unhook
	SDKUnhook(client, SDKHook_OnTakeDamage, Soulshield_OnTakeDamage);

	// Mostrar estadisticas
	if (g_iSoulshield_DamageBlocked[client] > 0)
	{
		PrintToChat(client, "\x04[Soulshield]\x01 Dano bloqueado: \x03%d", g_iSoulshield_DamageBlocked[client]);
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

	g_iSoulshield_DamageBlocked[client] = 0;
}

/**
 * Hook: Bloquear todo el dano y mostrar efecto visual
 */
public Action Soulshield_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!Abilities_IsActive(victim, Ability_Soulshield))
		return Plugin_Continue;

	// Trackear dano bloqueado
	g_iSoulshield_DamageBlocked[victim] += RoundToFloor(damage);

	// Efecto visual en cada bloqueo
	float victimPos[3];
	GetClientAbsOrigin(victim, victimPos);
	victimPos[2] += 50.0; // Elevar el efecto

	// Anillo dorado expandiendose
	TE_SetupBeamRingPoint(victimPos, 10.0, 120.0, PrecacheModel("materials/sprites/laserbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.3, 8.0, 0.0, {255, 255, 200, 255}, 10, 0);
	TE_SendToAll();

	// Feedback cada 100 de dano bloqueado
	if (g_iSoulshield_DamageBlocked[victim] % 100 <= RoundToFloor(damage))
	{
		PrintHintText(victim, "Soulshield: %d dano bloqueado", g_iSoulshield_DamageBlocked[victim]);
	}

	// Bloquear todo el dano
	damage = 0.0;
	return Plugin_Changed;
}
