#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === KNIFE PASSIVE REWARD ===
// Permite apuñalar a infectados especiales cuando está capturado usando la tecla [USE]
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_Knife_RequiredLevel = INVALID_HANDLE;
Handle cvar_Knife_Duration = INVALID_HANDLE;
Handle cvar_Knife_DamageMultiplier = INVALID_HANDLE;
Handle cvar_Knife_SuccessChance = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bKnife_Enabled[MAXPLAYERS + 1];
bool g_bKnife_InProgress[MAXPLAYERS + 1];
float g_fKnife_StartTime[MAXPLAYERS + 1];
int g_iKnife_Target[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de Knife
 */
public void Knife_OnPluginStart()
{
	cvar_Knife_RequiredLevel = CreateConVar(
		"reward_knife_level",
		"15",
		"Nivel requerido para desbloquear Knife",
		FCVAR_PLUGIN
	);

	cvar_Knife_Duration = CreateConVar(
		"reward_knife_duration",
		"1.5",
		"Duración del apuñalamiento en segundos",
		FCVAR_PLUGIN
	);

	cvar_Knife_DamageMultiplier = CreateConVar(
		"reward_knife_damage_multiplier",
		"2",
		"Multiplicador de daño base (level * multiplicador * 4)",
		FCVAR_PLUGIN
	);

	cvar_Knife_SuccessChance = CreateConVar(
		"reward_knife_min_chance",
		"10",
		"Probabilidad mínima de éxito (comparado con random(1, level*4))",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void Knife_OnClientConnect(int client)
{
	g_bKnife_Enabled[client] = false;
	g_bKnife_InProgress[client] = false;
	g_fKnife_StartTime[client] = 0.0;
	g_iKnife_Target[client] = -1;
}

/**
 * Limpia recursos al desconectar
 */
public void Knife_OnClientDisconnect(int client)
{
	g_bKnife_Enabled[client] = false;
	g_bKnife_InProgress[client] = false;
	g_fKnife_StartTime[client] = 0.0;
	g_iKnife_Target[client] = -1;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void Knife_OnPlayerSpawn(int client, int level)
{
	if (Knife_IsUnlocked(client, level))
	{
		g_bKnife_Enabled[client] = true;
	}

	// Resetear estado de progreso
	g_bKnife_InProgress[client] = false;
	g_fKnife_StartTime[client] = 0.0;
	g_iKnife_Target[client] = -1;
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void Knife_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_Knife_RequiredLevel);

	if (level == requiredLevel)
	{
		g_bKnife_Enabled[client] = true;
		float duration = GetConVarFloat(cvar_Knife_Duration);
		PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste \x05Knife\x01! (Apuñala infectados cuando te capturen - %.1fs con tecla USE)", duration);
	}
	else if (level > requiredLevel)
	{
		g_bKnife_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool Knife_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_Knife_RequiredLevel);
}

/**
 * Proceso de knife - debe ser llamado en OnPlayerRunCmd o similar
 * Requiere el nivel del jugador para calcular daño
 * Retorna true si está en proceso de knife
 */
public bool Knife_Process(int client, int buttons, int level)
{
	if (!g_bKnife_Enabled[client])
		return false;

	if (!IsPlayerAlive(client))
		return false;

	// Verificar si está siendo sostenido por un infectado
	int zombie = Knife_CheckZombieHold(client);
	if (zombie <= 0)
	{
		if (g_bKnife_InProgress[client])
		{
			g_bKnife_InProgress[client] = false;
			g_fKnife_StartTime[client] = 0.0;
			g_iKnife_Target[client] = -1;
		}
		return false;
	}

	// Verificar si alguien lo está usando
	int useActionOwner = GetEntPropEnt(client, Prop_Send, "m_useActionOwner");

	float currentTime = GetEngineTime();
	float duration = GetConVarFloat(cvar_Knife_Duration);

	// Iniciar proceso si presiona USE
	if (buttons & IN_USE)
	{
		if (!g_bKnife_InProgress[client] && useActionOwner <= 0)
		{
			g_bKnife_InProgress[client] = true;
			g_fKnife_StartTime[client] = currentTime;
			g_iKnife_Target[client] = zombie;
			SetEntPropEnt(client, Prop_Send, "m_useActionOwner", client);
			PrintToChat(client, "\x04[Knife]\x01 Attempting to Knife your assailant...");
		}
		else if (g_bKnife_InProgress[client] && (currentTime - g_fKnife_StartTime[client]) >= duration && useActionOwner == client)
		{
			// Completar knife
			Knife_Complete(client, zombie, level);
			g_bKnife_InProgress[client] = false;
			g_fKnife_StartTime[client] = 0.0;
			g_iKnife_Target[client] = -1;
		}
		return true;
	}
	else
	{
		// Cancelar si suelta USE
		if (g_bKnife_InProgress[client])
		{
			g_bKnife_InProgress[client] = false;
			g_fKnife_StartTime[client] = 0.0;
			g_iKnife_Target[client] = -1;
			SetEntPropEnt(client, Prop_Send, "m_useActionOwner", -1);
		}
	}

	return false;
}

/**
 * Completa el knife attack
 */
stock void Knife_Complete(int client, int zombie, int level)
{
	int minChance = GetConVarInt(cvar_Knife_SuccessChance);
	int random = GetRandomInt(1, level * 4);

	if (random >= minChance)
	{
		// Éxito!
		int damageMultiplier = GetConVarInt(cvar_Knife_DamageMultiplier);
		int damage = random * damageMultiplier;

		// Caso especial: Smoker con lengua extendida
		if (Knife_IsSmoker(zombie))
		{
			float clientPos[3], zombiePos[3];
			GetClientAbsOrigin(client, clientPos);
			GetClientAbsOrigin(zombie, zombiePos);
			float distance = GetVectorDistance(clientPos, zombiePos);

			if (distance > 125.0)
			{
				// Cortar lengua del Smoker
				PrintToChat(client, "\x04[Knife]\x01 Cut Smokers Tongue!");
				Knife_BreakInfectedHold(zombie);
				return;
			}
		}

		// Daño normal
		PrintToChat(client, "\x04[Knife]\x01 Stabbing Successful! [\x04%d\x01 Damage]", damage);
		Knife_DealDamage(zombie, damage);
	}
	else
	{
		// Falló
		PrintToChat(client, "\x04[Knife]\x01 You missed.");
	}
}

/**
 * Verifica qué infectado está sosteniendo al jugador
 */
stock int Knife_CheckZombieHold(int client)
{
	// Smoker
	int attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
		return attacker;

	// Hunter
	attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
		return attacker;

	// Jockey
	attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
		return attacker;

	// Charger
	attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
		return attacker;

	return -1;
}

/**
 * Verifica si un cliente es Smoker
 */
stock bool Knife_IsSmoker(int client)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != 3)
		return false;

	int zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
	return zombieClass == 1; // 1 = Smoker
}

/**
 * Rompe el agarre del infectado
 */
stock void Knife_BreakInfectedHold(int zombie)
{
	// Resetear habilidad del infectado
	SetEntPropFloat(zombie, Prop_Send, "m_flNextAttack", GetGameTime() + 6.0);
}

/**
 * Aplica daño al infectado
 */
stock void Knife_DealDamage(int victim, int damage)
{
	int currentHP = GetClientHealth(victim);
	int newHP = currentHP - damage;

	if (newHP <= 0)
	{
		// Matar al infectado
		ForcePlayerSuicide(victim);
	}
	else
	{
		SetEntityHealth(victim, newHP);
	}
}

/**
 * Obtiene si Knife está habilitado para un jugador
 */
public bool Knife_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bKnife_Enabled[client];
}

/**
 * Obtiene si el jugador está en proceso de knife
 */
public bool Knife_IsInProgress(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bKnife_InProgress[client];
}
