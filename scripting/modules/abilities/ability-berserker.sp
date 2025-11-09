//==================================================
// === BERSERKER ABILITY (Level 5) ===
// Speeds up attacks and gives double damage with melee weapons
// Duration: 60 seconds
// Cooldown: 5 minutes
// Requirements: Must have melee weapon
//==================================================

// Estado del jugador
bool g_bBerserker_HasMelee[MAXPLAYERS + 1];
float g_fBerserker_OriginalAttackSpeed[MAXPLAYERS + 1];

/**
 * Activa Berserker
 */
bool Ability_Berserker_Activate(int client)
{
	// Verificar que tenga melee weapon
	int weapon = GetPlayerWeaponSlot(client, 1); // Slot 1 = melee
	if (weapon == -1)
	{
		PrintToChat(client, "\x04[Berserker]\x01 Necesitas un arma melee para usar esta ability.");
		return false;
	}

	// Activar night vision (efecto visual)
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);

	// Guardar velocidad de ataque original
	g_fBerserker_OriginalAttackSpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flNextAttack");
	g_bBerserker_HasMelee[client] = true;

	// Efecto de pantalla roja
	int clients[1];
	clients[0] = client;
	int color[4] = {255, 0, 0, 128};
	int duration = 60000; // 60 segundos en milisegundos
	int flags = 0x0001; // FFADE_IN

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, 1000);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
		EndMessage();
	}

	PrintToChat(client, "\x04[Berserker]\x01 ¡Fuerza melee duplicada! ¡Ataque acelerado!");
	return true;
}

/**
 * Desactiva Berserker
 */
void Ability_Berserker_Deactivate(int client)
{
	if (!IsClientInGame(client))
		return;

	// Desactivar night vision
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);

	// Restaurar velocidad de ataque
	g_bBerserker_HasMelee[client] = false;

	// Limpiar efecto de pantalla
	int clients[1];
	clients[0] = client;
	int color[4] = {0, 0, 0, 0};

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, 500);
		BfWriteShort(message, 500);
		BfWriteShort(message, 0x0002); // FFADE_OUT
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
		EndMessage();
	}
}

/**
 * Hook de daño para Berserker
 */
public Action Berserker_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Si el atacante tiene Berserker activo y usa melee
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
	{
		if (Abilities_IsActive(attacker, Ability_Berserker))
		{
			// Verificar si el arma es melee
			char weapon[64];
			GetClientWeapon(attacker, weapon, sizeof(weapon));

			if (StrContains(weapon, "melee") != -1 ||
				StrContains(weapon, "chainsaw") != -1 ||
				StrContains(weapon, "pistol") == -1) // No es pistola
			{
				// Duplicar daño melee
				damage *= 2.0;
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}

/**
 * Hook de swing de arma para acelerar ataques
 */
public void Berserker_OnWeaponSwing(int client)
{
	if (!Abilities_IsActive(client, Ability_Berserker))
		return;

	// Acelerar la siguiente acción
	float nextAttack = GetEntPropFloat(client, Prop_Send, "m_flNextAttack");
	if (nextAttack > GetGameTime())
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 0.2);
	}
}
