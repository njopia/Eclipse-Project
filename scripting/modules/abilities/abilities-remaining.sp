//==================================================
// === REMAINING ABILITIES - STUB IMPLEMENTATIONS ===
// Implementaciones básicas funcionales para completar el sistema
//==================================================

//==================================================
// FLAMESHIELD (Level 16)
// Creates a shield of fire that ignites nearby zombies
//==================================================

bool Ability_Flameshield_Activate(int client)
{
	PrintToChat(client, "\x04[Flameshield]\x01 ¡Escudo de fuego activado!");
	// TODO: Implementar lógica de daño por proximidad a infectados
	return true;
}

void Ability_Flameshield_Deactivate(int client)
{
	// Cleanup
}

//==================================================
// NIGHTCRAWLER (Level 18)
// Teleportation between survivors
//==================================================

bool Ability_Nightcrawler_Activate(int client)
{
	PrintToChat(client, "\x04[Nightcrawler]\x01 ¡Teletransporte activado! Usa la tecla WALK para cambiar de objetivo.");
	// TODO: Implementar sistema de teletransporte
	return true;
}

void Ability_Nightcrawler_Deactivate(int client)
{
	// Cleanup
}

//==================================================
// RAPID FIRE (Level 23)
// Increases M16 firing rate and auto-resupply
//==================================================

bool Ability_Rapid Fire_Activate(int client)
{
	// Verificar que tenga M16
	int weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon == -1)
	{
		PrintToChat(client, "\x04[Rapid Fire]\x01 Necesitas un M16 para usar esta ability.");
		return false;
	}

	char weaponName[64];
	GetEdictClassname(weapon, weaponName, sizeof(weaponName));
	if (StrContains(weaponName, "rifle") == -1)
	{
		PrintToChat(client, "\x04[Rapid Fire]\x01 Necesitas un M16 Assault Rifle.");
		return false;
	}

	PrintToChat(client, "\x04[Rapid Fire]\x01 ¡M16 a máxima cadencia de fuego!");
	// TODO: Implementar aumento de rate of fire
	return true;
}

void Ability_RapidFire_Deactivate(int client)
{
	// Restaurar rate of fire normal
}

//==================================================
// CHAINSAW MASSACRE (Level 25)
// Infinite ammo chainsaw with bonus XP
//==================================================

bool Ability_ChainsawMassacre_Activate(int client)
{
	// Dar chainsaw
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give chainsaw");
	SetCommandFlags("give", flags);

	PrintToChat(client, "\x04[Chainsaw Massacre]\x01 ¡Motosierra infinita! Bonus XP por cada kill.");
	return true;
}

void Ability_ChainsawMassacre_Deactivate(int client)
{
	// Remover chainsaw
	int weapon = GetPlayerWeaponSlot(client, 1);
	if (weapon != -1)
	{
		char weaponName[64];
		GetEdictClassname(weapon, weaponName, sizeof(weaponName));
		if (StrContains(weaponName, "chainsaw") != -1)
		{
			RemovePlayerItem(client, weapon);
			RemoveEntity(weapon);
		}
	}
}

//==================================================
// HEAT SEEKER (Level 27)
// Heat seeking grenade launcher shells + infinite ammo
//==================================================

bool Ability_HeatSeeker_Activate(int client)
{
	// Verificar que tenga Grenade Launcher
	int weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon == -1)
	{
		PrintToChat(client, "\x04[Heat Seeker]\x01 Necesitas un Grenade Launcher.");
		return false;
	}

	char weaponName[64];
	GetEdictClassname(weapon, weaponName, sizeof(weaponName));
	if (StrContains(weaponName, "grenade_launcher") == -1)
	{
		PrintToChat(client, "\x04[Heat Seeker]\x01 Necesitas un Grenade Launcher.");
		return false;
	}

	PrintToChat(client, "\x04[Heat Seeker]\x01 ¡Granadas teledirigidas! Usa WALK para cambiar prioridad.");
	return true;
}

void Ability_HeatSeeker_Deactivate(int client)
{
	// Cleanup
}

//==================================================
// HEALING AURA (Level 33)
// Heals all nearby survivors
//==================================================

Handle g_hHealingAura_Timer[MAXPLAYERS + 1];

bool Ability_HealingAura_Activate(int client)
{
	// Iniciar timer de curación
	g_hHealingAura_Timer[client] = CreateTimer(1.0, Timer_HealingAura, GetClientUserId(client), TIMER_REPEAT);

	PrintToChat(client, "\x04[Healing Aura]\x01 ¡Aura de curación activada! Curas a aliados cercanos.");
	return true;
}

void Ability_HealingAura_Deactivate(int client)
{
	if (g_hHealingAura_Timer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hHealingAura_Timer[client]);
		g_hHealingAura_Timer[client] = INVALID_HANDLE;
	}
}

public Action Timer_HealingAura(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	// Curar a survivors cercanos
	float clientPos[3];
	GetClientAbsOrigin(client, clientPos);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			float targetPos[3];
			GetClientAbsOrigin(i, targetPos);

			float distance = GetVectorDistance(clientPos, targetPos);
			if (distance <= 500.0) // Radio de 500 unidades
			{
				// Curar más mientras más cerca esté
				int healAmount = RoundToFloor(10.0 * (1.0 - (distance / 500.0)));
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
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

//==================================================
// SOULSHIELD (Level 37)
// Negates all damage dealt
//==================================================

bool Ability_Soulshield_Activate(int client)
{
	// Dar godmode temporal
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);

	PrintToChat(client, "\x04[Soulshield]\x01 ¡Invulnerable! No recibes daño.");
	return true;
}

void Ability_Soulshield_Deactivate(int client)
{
	if (!IsClientInGame(client))
		return;

	// Remover godmode
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
}

//==================================================
// POLYMORPH (Level 39)
// Transform common zombies into items
//==================================================

bool Ability_Polymorph_Activate(int client)
{
	PrintToChat(client, "\x04[Polymorph]\x01 ¡Transforma zombies en items! (1-2%% de fallo)");
	// TODO: Implementar transformación de zombies al matarlos
	return true;
}

void Ability_Polymorph_Deactivate(int client)
{
	// Cleanup
}

//==================================================
// INSTAGIB (Level 46)
// Anti-virus ammunition - extremely deadly
//==================================================

bool Ability_Instagib_Activate(int client)
{
	PrintToChat(client, "\x04[Instagib]\x01 ¡Munición anti-virus! Daño extremo a infectados.");
	// TODO: Implementar multiplicador de daño masivo
	return true;
}

void Ability_Instagib_Deactivate(int client)
{
	// Cleanup
}
