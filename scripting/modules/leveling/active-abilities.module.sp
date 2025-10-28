#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === ACTIVE ABILITIES MANAGER MODULE ===
// Gestor central de todas las habilidades activas
//==================================================

// Incluir todas las habilidades activas
#include "rewards/active/berserker.ability.sp"
#include "rewards/active/acid-bath.ability.sp"
#include "rewards/active/lifestealer.ability.sp"
#include "rewards/active/speed-freak.ability.sp"
#include "rewards/active/shoulder-cannon.ability.sp"

/**
 * Inicializa el módulo de habilidades activas
 */
public void ActiveAbilities_OnPluginStart()
{
	// Inicializar cada habilidad
	Berserker_OnPluginStart();
	AcidBath_OnPluginStart();
	LifeStealer_OnPluginStart();
	SpeedFreak_OnPluginStart();
	ShoulderCannon_OnPluginStart();

	// Crear timer para actualizar habilidades cada segundo
	CreateTimer(1.0, Timer_ActiveAbilities_SecondTick, _, TIMER_REPEAT);

	// Hook de eventos
	HookEvent("player_death", Event_ActiveAbilities_PlayerDeath, EventHookMode_Post);

	// Hook para daño
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, Hook_ActiveAbilities_OnTakeDamage);
		}
	}
}

/**
 * Hook cuando un cliente se conecta
 */
public void ActiveAbilities_OnClientConnect(int client)
{
	Berserker_OnClientConnect(client);
	AcidBath_OnClientConnect(client);
	LifeStealer_OnClientConnect(client);
	SpeedFreak_OnClientConnect(client);
	ShoulderCannon_OnClientConnect(client);
}

/**
 * Hook cuando un cliente se conecta al juego
 */
public void ActiveAbilities_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hook_ActiveAbilities_OnTakeDamage);
}

/**
 * Hook cuando un cliente se desconecta
 */
public void ActiveAbilities_OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Hook_ActiveAbilities_OnTakeDamage);

	Berserker_OnClientDisconnect(client);
	AcidBath_OnClientDisconnect(client);
	LifeStealer_OnClientDisconnect(client);
	SpeedFreak_OnClientDisconnect(client);
	ShoulderCannon_OnClientDisconnect(client);
}

/**
 * Hook cuando un jugador muere
 */
public Action Event_ActiveAbilities_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && client <= MaxClients)
	{
		ShoulderCannon_OnPlayerDeath(client);
	}
	return Plugin_Continue;
}

/**
 * Timer que se ejecuta cada segundo para actualizar habilidades
 */
public Action Timer_ActiveAbilities_SecondTick(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		Berserker_OnSecondTick(i);
		AcidBath_OnSecondTick(i);
		LifeStealer_OnSecondTick(i);
		SpeedFreak_OnSecondTick(i);
	}

	return Plugin_Continue;
}

/**
 * Hook para manejar daño (para todas las habilidades)
 */
public Action Hook_ActiveAbilities_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	Action result = Plugin_Continue;

	// Berserker - aumenta daño de melee del atacante
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
	{
		Action berserkerResult = Berserker_OnTakeDamage(victim, attacker, inflictor, damage, damagetype);
		if (berserkerResult > result)
			result = berserkerResult;
	}

	// Acid Bath - convierte daño de ácido en curación para la víctima
	if (victim > 0 && victim <= MaxClients && IsClientInGame(victim))
	{
		Action acidBathResult = AcidBath_OnTakeDamage(victim, attacker, inflictor, damage, damagetype);
		if (acidBathResult > result)
			result = acidBathResult;
	}

	// LifeStealer - roba vida al atacante cuando hace daño
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && result != Plugin_Handled)
	{
		if (LifeStealer_IsActive(attacker))
		{
			// Llamar después de que se aplique el daño
			DataPack pack = new DataPack();
			pack.WriteCell(GetClientUserId(attacker));
			pack.WriteCell(GetClientUserId(victim));
			pack.WriteFloat(damage);
			CreateTimer(0.0, Timer_LifeStealer_DamageDealt, pack, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return result;
}

/**
 * Timer para aplicar robo de vida (después del daño)
 */
public Action Timer_LifeStealer_DamageDealt(Handle timer, DataPack pack)
{
	pack.Reset();
	int attackerUserId = pack.ReadCell();
	int victimUserId = pack.ReadCell();
	float damage = pack.ReadFloat();
	delete pack;

	int attacker = GetClientOfUserId(attackerUserId);
	int victim = GetClientOfUserId(victimUserId);

	if (attacker > 0 && victim > 0)
	{
		LifeStealer_OnDamageDealt(attacker, victim, damage);
	}

	return Plugin_Stop;
}

/**
 * Hook para modificar velocidad del jugador (Speed Freak)
 */
public void ActiveAbilities_ModifySpeed(int client, float &speed)
{
	SpeedFreak_ModifySpeed(client, speed);
}

/**
 * Hook para cuando el jugador usa un arma (Berserker swing speed, Speed Freak healing speed)
 */
public void ActiveAbilities_OnWeaponFire(int client)
{
	Berserker_OnWeaponSwing(client);
	SpeedFreak_ModifyHealingSpeed(client);
}

/**
 * Obtiene información de habilidad para el menú de compra
 */
public void ActiveAbilities_GetAbilityInfo(int client, int level, char[] buffer, int maxlen, const char[] abilityName)
{
	if (StrEqual(abilityName, "Berserker", false))
	{
		int cooldown = Berserker_GetCooldown(client);
		if (cooldown > 0)
		{
			Format(buffer, maxlen, "Berserker [%is]", cooldown);
		}
		else if (Berserker_IsActive(client))
		{
			int remaining = Berserker_GetTimeRemaining(client);
			Format(buffer, maxlen, "Berserker [ACTIVE: %is]", remaining);
		}
		else
		{
			Format(buffer, maxlen, "Berserker [Ready]");
		}
	}
	else if (StrEqual(abilityName, "Acid Bath", false))
	{
		int cooldown = AcidBath_GetCooldown(client);
		if (cooldown > 0)
		{
			Format(buffer, maxlen, "Acid Bath [%is]", cooldown);
		}
		else if (AcidBath_IsActive(client))
		{
			int remaining = AcidBath_GetTimeRemaining(client);
			Format(buffer, maxlen, "Acid Bath [ACTIVE: %is]", remaining);
		}
		else
		{
			Format(buffer, maxlen, "Acid Bath [Ready]");
		}
	}
	else if (StrEqual(abilityName, "LifeStealer", false))
	{
		int cooldown = LifeStealer_GetCooldown(client);
		if (cooldown > 0)
		{
			Format(buffer, maxlen, "LifeStealer [%is]", cooldown);
		}
		else if (LifeStealer_IsActive(client))
		{
			int remaining = LifeStealer_GetTimeRemaining(client);
			Format(buffer, maxlen, "LifeStealer [ACTIVE: %is]", remaining);
		}
		else
		{
			Format(buffer, maxlen, "LifeStealer [Ready]");
		}
	}
	else if (StrEqual(abilityName, "Speed Freak", false))
	{
		int cooldown = SpeedFreak_GetCooldown(client);
		if (cooldown > 0)
		{
			Format(buffer, maxlen, "Speed Freak [%is]", cooldown);
		}
		else if (SpeedFreak_IsActive(client))
		{
			int remaining = SpeedFreak_GetTimeRemaining(client);
			Format(buffer, maxlen, "Speed Freak [ACTIVE: %is]", remaining);
		}
		else
		{
			Format(buffer, maxlen, "Speed Freak [Ready]");
		}
	}
	else if (StrEqual(abilityName, "Shoulder Cannon", false))
	{
		if (ShoulderCannon_IsActive(client))
		{
			int ammo = ShoulderCannon_GetAmmo(client);
			Format(buffer, maxlen, "Shoulder Cannon [Ammo: %i]", ammo);
		}
		else
		{
			Format(buffer, maxlen, "Shoulder Cannon [Equip]");
		}
	}
}

/**
 * Activa una habilidad por nombre
 */
public bool ActiveAbilities_ActivateAbility(int client, int level, const char[] abilityName)
{
	if (StrEqual(abilityName, "Berserker", false))
	{
		if (!Berserker_CanUse(client, level))
		{
			if (!Berserker_HasMeleeEquipped(client))
			{
				PrintToChat(client, "\x05[Ability]\x01 You need a melee weapon to use Berserker!");
			}
			else if (Berserker_GetCooldown(client) > 0)
			{
				PrintToChat(client, "\x05[Ability]\x01 You have to wait %i seconds to use this again.", Berserker_GetCooldown(client));
			}
			return false;
		}
		Berserker_Activate(client);
		return true;
	}
	else if (StrEqual(abilityName, "Acid Bath", false))
	{
		if (!AcidBath_CanUse(client, level))
		{
			if (AcidBath_GetCooldown(client) > 0)
			{
				PrintToChat(client, "\x05[Ability]\x01 You have to wait %i seconds to use this again.", AcidBath_GetCooldown(client));
			}
			return false;
		}
		AcidBath_Activate(client);
		return true;
	}
	else if (StrEqual(abilityName, "LifeStealer", false))
	{
		if (!LifeStealer_CanUse(client, level))
		{
			if (LifeStealer_GetCooldown(client) > 0)
			{
				PrintToChat(client, "\x05[Ability]\x01 You have to wait %i seconds to use this again.", LifeStealer_GetCooldown(client));
			}
			return false;
		}
		LifeStealer_Activate(client);
		return true;
	}
	else if (StrEqual(abilityName, "Speed Freak", false))
	{
		if (!SpeedFreak_CanUse(client, level))
		{
			if (SpeedFreak_GetCooldown(client) > 0)
			{
				PrintToChat(client, "\x05[Ability]\x01 You have to wait %i seconds to use this again.", SpeedFreak_GetCooldown(client));
			}
			return false;
		}
		SpeedFreak_Activate(client);
		return true;
	}
	else if (StrEqual(abilityName, "Shoulder Cannon", false))
	{
		if (!ShoulderCannon_CanUse(client, level))
		{
			return false;
		}

		// Toggle: equipar o desequipar
		if (ShoulderCannon_IsActive(client))
		{
			ShoulderCannon_Remove(client);
			PrintToChat(client, "\x05[Ability]\x01 Shoulder Cannon unequipped.");
		}
		else
		{
			ShoulderCannon_Activate(client);
		}
		return true;
	}

	return false;
}

/**
 * Verifica si el jugador puede usar una habilidad
 */
public bool ActiveAbilities_CanUseAbility(int client, int level, const char[] abilityName)
{
	if (StrEqual(abilityName, "Berserker", false))
	{
		return Berserker_CanUse(client, level);
	}
	else if (StrEqual(abilityName, "Acid Bath", false))
	{
		return AcidBath_CanUse(client, level);
	}
	else if (StrEqual(abilityName, "LifeStealer", false))
	{
		return LifeStealer_CanUse(client, level);
	}
	else if (StrEqual(abilityName, "Speed Freak", false))
	{
		return SpeedFreak_CanUse(client, level);
	}
	else if (StrEqual(abilityName, "Shoulder Cannon", false))
	{
		return ShoulderCannon_CanUse(client, level);
	}

	return false;
}
