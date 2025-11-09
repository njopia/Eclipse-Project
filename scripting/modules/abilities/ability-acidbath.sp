//==================================================
// === ACID BATH ABILITY (Level 9) ===
// Makes spitter goo heal you instead of hurt you
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

/**
 * Activa Acid Bath
 */
bool Ability_AcidBath_Activate(int client)
{
	// Efecto visual verde
	int clients[1];
	clients[0] = client;
	int color[4] = {0, 255, 0, 100};
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

	PrintToChat(client, "\x04[Acid Bath]\x01 ¡El ácido de Spitter ahora te cura!");
	return true;
}

/**
 * Desactiva Acid Bath
 */
void Ability_AcidBath_Deactivate(int client)
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
 * Hook de daño para Acid Bath
 */
public Action AcidBath_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
		return Plugin_Continue;

	// Si el jugador tiene Acid Bath activo
	if (!Abilities_IsActive(victim, Ability_AcidBath))
		return Plugin_Continue;

	// Verificar si el daño es de Spitter (ácido)
	// damagetype 1056 es ácido de spitter
	if (damagetype & DMG_RADIATION || damagetype & DMG_ACID)
	{
		// Convertir daño en curación
		int health = GetClientHealth(victim);
		int maxHealth = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
		int healAmount = RoundToFloor(damage);

		if (health + healAmount > maxHealth)
		{
			healAmount = maxHealth - health;
		}

		if (healAmount > 0)
		{
			SetEntityHealth(victim, health + healAmount);
			PrintHintText(victim, "Acid Bath: +%d HP", healAmount);
		}

		// Bloquear el daño original
		damage = 0.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}
