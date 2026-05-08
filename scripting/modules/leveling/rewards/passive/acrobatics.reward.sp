#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === ACROBATICS PASSIVE REWARD ===
// Aumenta la altura del salto y reduce el dano por caida
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_Acrobatics_RequiredLevel = INVALID_HANDLE;
Handle cvar_Acrobatics_JumpGravity = INVALID_HANDLE;
Handle cvar_Acrobatics_FallDamageReduction = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bAcrobatics_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el modulo de Acrobatics
 */
public void Acrobatics_OnPluginStart()
{
	cvar_Acrobatics_RequiredLevel = CreateConVar(
		"reward_acrobatics_level",
		"2",
		"Nivel requerido para desbloquear Acrobatics (aumento de salto y reduccion de dano por caida)",
		FCVAR_PLUGIN
	);

	cvar_Acrobatics_JumpGravity = CreateConVar(
		"reward_acrobatics_jump_gravity",
		"0.7",
		"Multiplicador de gravedad al saltar (0.7 = salto mas alto, 1.0 = normal)",
		FCVAR_PLUGIN
	);

	cvar_Acrobatics_FallDamageReduction = CreateConVar(
		"reward_acrobatics_fall_reduction",
		"0.5",
		"Multiplicador de dano por caida (0.5 = mitad de dano, 1.0 = normal)",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void Acrobatics_OnClientConnect(int client)
{
	g_bAcrobatics_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void Acrobatics_OnClientDisconnect(int client)
{
	g_bAcrobatics_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void Acrobatics_OnPlayerSpawn(int client, int level)
{
	if (Acrobatics_IsUnlocked(client, level))
	{
		g_bAcrobatics_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void Acrobatics_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_Acrobatics_RequiredLevel);

	// Solo mostrar mensaje si justo alcanzo el nivel requerido
	if (level == requiredLevel)
	{
		g_bAcrobatics_Enabled[client] = true;
		PrintToChat(client, "\x04[REWARD]\x01 Desbloqueaste \x05Acrobatics\x01! (Mayor altura de salto y menos dano por caida)");
	}
	else if (level > requiredLevel)
	{
		g_bAcrobatics_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool Acrobatics_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_Acrobatics_RequiredLevel);
}

/**
 * Procesa el input del jugador cada tick para aplicar la gravedad reducida al saltar
 */
public Action Acrobatics_OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
		return Plugin_Continue;

	// Solo survivors
	if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	// Verificar si tiene Acrobatics habilitado
	if (!g_bAcrobatics_Enabled[client])
		return Plugin_Continue;

	float gravityValue;

	// Si esta saltando (en el aire), reducir la gravedad
	if (buttons & IN_JUMP)
	{
		gravityValue = GetConVarFloat(cvar_Acrobatics_JumpGravity);
	}
	else
	{
		gravityValue = 1.0; // Gravedad normal
	}

	SetEntityGravity(client, gravityValue);

	return Plugin_Continue;
}

/**
 * Maneja la reduccion de dano por caida
 * Esta funcion debe ser llamada desde OnTakeDamage
 * @param victim - ID del cliente que recibe dano
 * @param attacker - ID del atacante (0 = mundo)
 * @param damage - Dano original
 * @param damagetype - Tipo de dano
 * @return Dano modificado
 */
public float Acrobatics_OnTakeDamage(int victim, int attacker, float damage, int damagetype)
{
	// Solo procesar si:
	// 1. El atacante es el mundo (attacker == 0)
	// 2. El tipo de dano es por caida (damagetype == 32)
	// 3. El jugador tiene Acrobatics habilitado
	if (attacker == 0 && damagetype == 32 && g_bAcrobatics_Enabled[victim])
	{
		if (damage > 2.0) // Solo reducir si el dano es significativo
		{
			float reductionMultiplier = GetConVarFloat(cvar_Acrobatics_FallDamageReduction);
			float reducedDamage = damage * reductionMultiplier;
			float damageReduced = damage - reducedDamage;

			PrintToChat(victim, "\x04[Acrobatics]\x01 Dano por caida reducido en \x03%i\x01 puntos de vida.", RoundFloat(damageReduced));

			return reducedDamage;
		}
	}

	return damage; // Devolver dano sin modificar
}

/**
 * Obtiene si Acrobatics esta habilitado para un jugador
 */
public bool Acrobatics_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bAcrobatics_Enabled[client];
}
