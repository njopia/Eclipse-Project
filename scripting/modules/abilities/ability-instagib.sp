//==================================================
// === INSTAGIB ABILITY (Level 46) ===
// Anti-virus coated ammunition - extremely deadly
// Massive damage multiplier against infected
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

#define INSTAGIB_DAMAGE_MULTIPLIER 10.0  // 10x daño contra infectados
#define INSTAGIB_CRIT_CHANCE 50  // 50% de probabilidad de instakill

/**
 * Activa Instagib
 */
bool Ability_Instagib_Activate(int client)
{
	// Efecto visual blanco brillante
	int clients[1];
	clients[0] = client;
	int color[4] = {255, 255, 255, 120};
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

	// Activar night vision para efecto dramático
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);

	PrintToChat(client, "\x04[Instagib]\x01 ¡Munición anti-virus! Daño 10x + 50%% instakill.");
	return true;
}

/**
 * Desactiva Instagib
 */
void Ability_Instagib_Deactivate(int client)
{
	if (!IsClientInGame(client))
		return;

	// Desactivar night vision
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);

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
 * Hook de daño para Instagib
 */
public Action Instagib_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Si el atacante tiene Instagib activo
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
	{
		if (!Abilities_IsActive(attacker, Ability_Instagib))
			return Plugin_Continue;

		// Solo contra infectados
		if (victim <= 0 || victim > MaxClients)
		{
			// También funciona contra entidades infectadas (witch, etc)
			char className[64];
			if (IsValidEntity(victim))
			{
				GetEdictClassname(victim, className, sizeof(className));
				if (StrContains(className, "infected") != -1 || StrContains(className, "witch") != -1)
				{
					// Multiplicar daño
					damage *= INSTAGIB_DAMAGE_MULTIPLIER;

					// Probabilidad de instakill
					int roll = GetRandomInt(1, 100);
					if (roll <= INSTAGIB_CRIT_CHANCE)
					{
						damage = 999999.0;  // Instakill
						PrintHintText(attacker, "INSTAGIB!");

						// Efecto visual en el target
						float victimPos[3];
						GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
						TE_SetupBeamRingPoint(victimPos, 10.0, 200.0, PrecacheModel("materials/sprites/laserbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.3, 10.0, 0.0, {255, 255, 255, 255}, 10, 0);
						TE_SendToAll();
					}

					return Plugin_Changed;
				}
			}
			return Plugin_Continue;
		}

		// Victim es un cliente infectado
		if (GetClientTeam(victim) == 3)
		{
			// Multiplicar daño
			damage *= INSTAGIB_DAMAGE_MULTIPLIER;

			// Probabilidad de instakill
			int roll = GetRandomInt(1, 100);
			if (roll <= INSTAGIB_CRIT_CHANCE)
			{
				damage = 999999.0;  // Instakill
				PrintHintText(attacker, "INSTAGIB!");

				// Efecto visual
				float victimPos[3];
				GetClientAbsOrigin(victim, victimPos);
				TE_SetupBeamRingPoint(victimPos, 10.0, 200.0, PrecacheModel("materials/sprites/laserbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.3, 10.0, 0.0, {255, 255, 255, 255}, 10, 0);
				TE_SendToAll();

				// Efecto de sonido
				EmitSoundToAll("weapons/hegrenade/explode5.wav", victim);
			}

			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}
