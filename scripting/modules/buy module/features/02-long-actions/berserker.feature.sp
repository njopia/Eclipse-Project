#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === BERSERKER ACTIVE ABILITY ===
// Aumenta velocidad de ataque y da doble daño con melee
// Nivel: 1
// Duración: 60 segundos
// Cooldown: 5 minutos (300 segundos)
//==================================================

// --- ConVars ---
Handle cvar_Berserker_RequiredLevel = INVALID_HANDLE;
Handle cvar_Berserker_Duration = INVALID_HANDLE;
Handle cvar_Berserker_Cooldown = INVALID_HANDLE;
Handle cvar_Berserker_DamageMultiplier = INVALID_HANDLE;

// --- Estado del jugador ---
bool  g_bBerserker_Active[MAXPLAYERS + 1];
int   g_iBerserker_TimeRemaining[MAXPLAYERS + 1];
int   g_iBerserker_Cooldown[MAXPLAYERS + 1];

// --- Partículas ---
#define PARTICLE_BERSERKER "sparks_generic_random"

/**
 * Inicializa el módulo de Berserker
 */
public void Berserker_OnPluginStart()
{
	cvar_Berserker_RequiredLevel = CreateConVar(
		"ability_berserker_level",
		"1",
		"Nivel requerido para desbloquear Berserker",
		FCVAR_PLUGIN
	);

	cvar_Berserker_Duration = CreateConVar(
		"ability_berserker_duration",
		"60",
		"Duración de Berserker en segundos",
		FCVAR_PLUGIN
	);

	cvar_Berserker_Cooldown = CreateConVar(
		"ability_berserker_cooldown",
		"300",
		"Cooldown de Berserker en segundos",
		FCVAR_PLUGIN
	);

	cvar_Berserker_DamageMultiplier = CreateConVar(
		"ability_berserker_damage",
		"2.0",
		"Multiplicador de daño para Berserker",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void Berserker_OnClientConnect(int client)
{
	g_bBerserker_Active[client] = false;
	g_iBerserker_TimeRemaining[client] = 0;
	g_iBerserker_Cooldown[client] = 0;
}

/**
 * Limpia recursos al desconectar
 */
public void Berserker_OnClientDisconnect(int client)
{
	Berserker_Deactivate(client);
	g_iBerserker_Cooldown[client] = 0;
}

/**
 * Actualiza timers cada segundo
 */
public void Berserker_OnSecondTick(int client)
{
	// Reducir cooldown
	if (g_iBerserker_Cooldown[client] > 0)
	{
		g_iBerserker_Cooldown[client]--;
	}

	// Actualizar habilidad activa
	if (g_bBerserker_Active[client])
	{
		g_iBerserker_TimeRemaining[client]--;

		// Mantener night vision
		if (g_iBerserker_TimeRemaining[client] > 0 && g_iBerserker_TimeRemaining[client] <= 50)
		{
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
		}

		// Desactivar si se acabó el tiempo
		if (g_iBerserker_TimeRemaining[client] <= 0)
		{
			Berserker_Deactivate(client);
		}
	}
}

/**
 * Verifica si el jugador puede usar Berserker
 */
public bool Berserker_CanUse(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_Berserker_RequiredLevel);

	if (level < requiredLevel)
	{
		return false;
	}

	if (g_iBerserker_Cooldown[client] > 0)
	{
		return false;
	}

	if (g_bBerserker_Active[client])
	{
		return false;
	}

	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return false;
	}

	// Verificar que tenga un melee equipado
	if (!Berserker_HasMeleeEquipped(client))
	{
		return false;
	}

	return true;
}

/**
 * Activa Berserker
 */
public void Berserker_Activate(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	int duration = GetConVarInt(cvar_Berserker_Duration);
	int cooldown = GetConVarInt(cvar_Berserker_Cooldown);

	g_bBerserker_Active[client] = true;
	g_iBerserker_TimeRemaining[client] = duration;
	g_iBerserker_Cooldown[client] = cooldown;

	// Activar night vision
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);

	PrintToChat(client, "\x04[ABILITY ACTIVATED]\x01 Berserker - Duration: %ds, Damage: 2x", duration);
}

/**
 * Desactiva Berserker
 */
public void Berserker_Deactivate(int client)
{
	if (!g_bBerserker_Active[client])
		return;

	g_bBerserker_Active[client] = false;
	g_iBerserker_TimeRemaining[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
		PrintToChat(client, "\x04[Ability]\x01 Berserker Deactivated");
	}
}

/**
 * Hook para modificar velocidad de swing de melee
 */
public void Berserker_OnWeaponSwing(int client)
{
	if (!g_bBerserker_Active[client])
		return;

	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	int weapon = GetPlayerWeaponSlot(client, 1); // Slot de melee
	if (weapon <= 0 || !IsValidEntity(weapon))
		return;

	// Aumentar velocidad de animación
	SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", 1.6);

	// Reducir delay entre ataques
	float nextPrimaryAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
	float nextSecondaryAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack");
	float cycle = GetEntPropFloat(weapon, Prop_Send, "m_flCycle");

	if (cycle == 0.0)
	{
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", nextPrimaryAttack - 0.30);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", nextSecondaryAttack - 0.30);
	}
}

/**
 * Hook para modificar daño de melee
 */
public Action Berserker_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_bBerserker_Active[attacker])
		return Plugin_Continue;

	if (attacker <= 0 || attacker > MaxClients)
		return Plugin_Continue;

	if (!IsClientInGame(attacker))
		return Plugin_Continue;

	// Verificar que sea daño de melee
	int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if (weapon <= 0 || !IsValidEntity(weapon))
		return Plugin_Continue;

	char weaponName[64];
	GetEntityClassname(weapon, weaponName, sizeof(weaponName));

	if (StrEqual(weaponName, "weapon_melee", false))
	{
		// Aplicar multiplicador de daño
		float multiplier = GetConVarFloat(cvar_Berserker_DamageMultiplier);
		damage *= multiplier;

		// Crear efecto de partículas
		float origin[3], angles[3];
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", origin);
		GetEntPropVector(victim, Prop_Send, "m_angRotation", angles);
		Berserker_CreateEffect(origin, angles);

		return Plugin_Changed;
	}

	return Plugin_Continue;
}

/**
 * Crea el efecto de partículas de Berserker
 */
stock void Berserker_CreateEffect(float origin[3], float angles[3])
{
	origin[2] += 35.0;

	int particle = CreateEntityByName("info_particle_system");
	if (particle > 0 && IsValidEntity(particle))
	{
		DispatchKeyValue(particle, "effect_name", PARTICLE_BERSERKER);
		DispatchKeyValueVector(particle, "origin", origin);
		DispatchKeyValueVector(particle, "angles", angles);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		// Auto-destruir después de 0.1 segundos
		CreateTimer(0.1, Timer_KillParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * Timer para destruir partículas
 */
public Action Timer_KillParticle(Handle timer, int entityRef)
{
	int entity = EntRefToEntIndex(entityRef);
	if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
	return Plugin_Stop;
}

/**
 * Verifica si el jugador tiene un melee equipado
 */
stock bool Berserker_HasMeleeEquipped(int client)
{
	int weapon = GetPlayerWeaponSlot(client, 1);
	if (weapon <= 0 || !IsValidEntity(weapon))
		return false;

	char weaponName[64];
	GetEntityClassname(weapon, weaponName, sizeof(weaponName));

	return StrEqual(weaponName, "weapon_melee", false);
}

/**
 * Obtiene si Berserker está activo
 */
public bool Berserker_IsActive(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bBerserker_Active[client];
}

/**
 * Obtiene el cooldown restante
 */
public int Berserker_GetCooldown(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	return g_iBerserker_Cooldown[client];
}

/**
 * Obtiene el tiempo restante de la habilidad
 */
public int Berserker_GetTimeRemaining(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	return g_iBerserker_TimeRemaining[client];
}