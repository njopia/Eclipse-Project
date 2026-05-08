//==================================================
// === HEALING AURA ABILITY (Level 33) ===
// Heals all nearby survivors continuously
// Healing scales with distance (closer = more healing)
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

#define HEALING_AURA_RADIUS 500.0
#define HEALING_AURA_TICK_INTERVAL 1.0

Handle g_hHealingAura_Timer[MAXPLAYERS + 1];
int g_iHealingAura_TotalHealed[MAXPLAYERS + 1];

/**
 * Activa Healing Aura
 */
bool Ability_HealingAura_Activate(int client)
{
	g_iHealingAura_TotalHealed[client] = 0;

	// Iniciar timer de curacion
	g_hHealingAura_Timer[client] = CreateTimer(HEALING_AURA_TICK_INTERVAL, Timer_HealingAura, GetClientUserId(client), TIMER_REPEAT);

	// Efecto visual verde
	int clients[1];
	clients[0] = client;
	int color[4] = {0, 255, 100, 80};
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

	PrintToChat(client, "\x04[Healing Aura]\x01 Aura de curacion activada! Curas a aliados cercanos.");
	return true;
}

/**
 * Desactiva Healing Aura
 */
void Ability_HealingAura_Deactivate(int client)
{
	if (g_hHealingAura_Timer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hHealingAura_Timer[client]);
		g_hHealingAura_Timer[client] = INVALID_HANDLE;
	}

	if (!IsClientInGame(client))
		return;

	// Mostrar estadisticas
	if (g_iHealingAura_TotalHealed[client] > 0)
	{
		PrintToChat(client, "\x04[Healing Aura]\x01 HP total curado: \x03%d", g_iHealingAura_TotalHealed[client]);
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

	g_iHealingAura_TotalHealed[client] = 0;
}

/**
 * Timer: Curar aliados cercanos cada segundo
 */
public Action Timer_HealingAura(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	if (!Abilities_IsActive(client, Ability_HealingAura))
		return Plugin_Stop;

	// Obtener posicion del jugador
	float clientPos[3];
	GetClientAbsOrigin(client, clientPos);

	int healedThisTick = 0;

	// Curar a survivors cercanos
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client || !IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;

		float targetPos[3];
		GetClientAbsOrigin(i, targetPos);

		float distance = GetVectorDistance(clientPos, targetPos);
		if (distance <= HEALING_AURA_RADIUS)
		{
			// Curar mas mientras mas cerca este (10 HP max a distancia 0, 1 HP min en el borde)
			int healAmount = RoundToFloor(10.0 * (1.0 - (distance / HEALING_AURA_RADIUS)));

			if (healAmount > 0)
			{
				int health = GetClientHealth(i);
				int maxHealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");

				if (health < maxHealth)
				{
					int newHealth = health + healAmount;
					if (newHealth > maxHealth)
						newHealth = maxHealth;

					SetEntityHealth(i, newHealth);
					healedThisTick += healAmount;

					// Efecto visual de curacion
					TE_SetupBeamRingPoint(targetPos, 10.0, 100.0, PrecacheModel("materials/sprites/laserbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.5, 5.0, 0.0, {0, 255, 100, 255}, 10, 0);
					TE_SendToAll();
				}
			}
		}
	}

	// Tambien curar al jugador mismo
	int health = GetClientHealth(client);
	int maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	if (health < maxHealth)
	{
		int selfHeal = 5; // Auto-curacion moderada
		int newHealth = health + selfHeal;
		if (newHealth > maxHealth)
			newHealth = maxHealth;

		SetEntityHealth(client, newHealth);
		healedThisTick += selfHeal;
	}

	g_iHealingAura_TotalHealed[client] += healedThisTick;

	// Feedback cada 10 segundos
	static int tickCount[MAXPLAYERS + 1];
	tickCount[client]++;
	if (tickCount[client] % 10 == 0)
	{
		PrintHintText(client, "Healing Aura: %d HP curados", g_iHealingAura_TotalHealed[client]);
	}

	return Plugin_Continue;
}
