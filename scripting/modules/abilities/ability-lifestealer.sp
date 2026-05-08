//==================================================
// === LIFESTEALER ABILITY (Level 12) ===
// Heal the user a small portion of damage delivered
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

#define LIFESTEAL_PERCENTAGE 0.15  // 15% del dano se convierte en curacion

/**
 * Activa Lifestealer
 */
bool Ability_Lifestealer_Activate(int client)
{
	// Efecto visual rojo oscuro
	int clients[1];
	clients[0] = client;
	int color[4] = {150, 0, 0, 80};
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

	PrintToChat(client, "\x04[Lifestealer]\x01 Robas vida con cada golpe!");
	return true;
}

/**
 * Desactiva Lifestealer
 */
void Ability_Lifestealer_Deactivate(int client)
{
	if (!IsClientInGame(client))
		return;

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

/**
 * Hook de dano para Lifestealer
 */
public Action Lifestealer_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Si el atacante tiene Lifestealer activo
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
	{
		if (Abilities_IsActive(attacker, Ability_Lifestealer))
		{
			// Calcular curacion (15% del dano)
			int healAmount = RoundToFloor(damage * LIFESTEAL_PERCENTAGE);

			if (healAmount > 0)
			{
				int health = GetClientHealth(attacker);
				int maxHealth = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");

				if (health < maxHealth)
				{
					int newHealth = health + healAmount;
					if (newHealth > maxHealth)
						newHealth = maxHealth;

					SetEntityHealth(attacker, newHealth);
					PrintHintText(attacker, "Lifesteal: +%d HP", healAmount);
				}
			}
		}
	}

	return Plugin_Continue;
}
