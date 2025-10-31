#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === KNIFE PASSIVE REWARD ===
// Allows backstabbing special infected when captured using the [USE] key
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
float g_fKnife_LastUse[MAXPLAYERS + 1]; // Last use time for cooldown
int g_iKnife_Target[MAXPLAYERS + 1];
int g_iKnife_ProgressButton[MAXPLAYERS + 1]; // func_button_timed entity for progress bar

/**
 * Initialize Knife module
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
		"Knife attack duration in seconds",
		FCVAR_PLUGIN
	);

	cvar_Knife_DamageMultiplier = CreateConVar(
		"reward_knife_damage_multiplier",
		"2",
		"Base damage multiplier (level * multiplier * 4)",
		FCVAR_PLUGIN
	);

	cvar_Knife_SuccessChance = CreateConVar(
		"reward_knife_min_chance",
		"10",
		"Minimum success chance (compared with random(1, level*4))",
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
	g_fKnife_LastUse[client] = 0.0;
	g_iKnife_Target[client] = -1;
	g_iKnife_ProgressButton[client] = -1;
}

/**
 * Limpia recursos al desconectar
 */
public void Knife_OnClientDisconnect(int client)
{
	Knife_DestroyProgressButton(client);

	g_bKnife_Enabled[client] = false;
	g_bKnife_InProgress[client] = false;
	g_fKnife_StartTime[client] = 0.0;
	g_fKnife_LastUse[client] = 0.0;
	g_iKnife_Target[client] = -1;
	g_iKnife_ProgressButton[client] = -1;
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
	g_fKnife_LastUse[client] = 0.0;
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
		PrintToChat(client, "\x04[REWARD]\x01 Unlocked \x05Knife\x01! (Backstab infected when captured - Hold USE for %.1fs)", duration);
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

	// Check if being held by an infected
	int zombie = Knife_CheckZombieHold(client);
	if (zombie <= 0)
	{
		if (g_bKnife_InProgress[client])
		{
			g_bKnife_InProgress[client] = false;
			g_fKnife_StartTime[client] = 0.0;
			g_iKnife_Target[client] = -1;

			// Feedback de cancelación
			PrintHintText(client, "");
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
		// Verificar cooldown de 0.5s después del último uso
		float timeSinceLastUse = currentTime - g_fKnife_LastUse[client];
		if (timeSinceLastUse < 0.5)
		{
			return false; // Cooldown activo, no hacer nada
		}

		if (!g_bKnife_InProgress[client] && useActionOwner <= 0)
		{
			g_bKnife_InProgress[client] = true;
			g_fKnife_StartTime[client] = currentTime;
			g_iKnife_Target[client] = zombie;

			// Crear botón de progreso nativo
			Knife_CreateProgressButton(client, duration);

			// Feedback inicial mejorado
			PrintToChat(client, "\x04[KNIFE]\x01 Preparing to strike...");
			PrintCenterText(client, ">> KNIFE ATTACK INITIATED <<");
		}
		else if (g_bKnife_InProgress[client])
		{
			// Verificar si completó el tiempo
			float elapsed = currentTime - g_fKnife_StartTime[client];

			if (elapsed >= duration)
			{
				// Completar knife
				Knife_Complete(client, zombie, level);

				// IMPORTANTE: Resetear TODOS los estados para permitir un nuevo uso
				g_bKnife_InProgress[client] = false;
				g_fKnife_StartTime[client] = 0.0;
				g_fKnife_LastUse[client] = currentTime; // Marcar tiempo del último uso
				g_iKnife_Target[client] = -1;

				// Destruir el botón de progreso
				Knife_DestroyProgressButton(client);
			}
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

			// Destruir el botón de progreso
			Knife_DestroyProgressButton(client);

			// Feedback de cancelación
			PrintCenterText(client, ">> KNIFE ATTACK CANCELLED <<");
		}
	}

	return false;
}

/**
 * Crea un botón de progreso invisible que muestra la barra nativa de L4D2
 */
stock void Knife_CreateProgressButton(int client, float duration)
{
	// Destruir botón anterior si existe
	Knife_DestroyProgressButton(client);

	// Obtener posición del jugador
	float clientPos[3];
	GetClientAbsOrigin(client, clientPos);

	// Crear func_button_timed (igual que healing station)
	int button = CreateEntityByName("func_button_timed");
	if (!IsValidEntity(button))
		return;

	// Configurar el botón
	char durationStr[16];
	FloatToString(duration, durationStr, sizeof(durationStr));

	DispatchKeyValue(button, "use_string", "Knifing..."); // Texto que se muestra
	DispatchKeyValue(button, "use_time", durationStr); // Duración
	DispatchKeyValue(button, "auto_disable", "1"); // Auto-desactivar al completar

	// Hacer el botón invisible y sin colisión
	DispatchKeyValue(button, "rendermode", "10"); // No renderizar
	DispatchKeyValue(button, "solid", "0"); // Sin colisión

	DispatchSpawn(button);
	ActivateEntity(button);

	// Teleportar al jugador
	TeleportEntity(button, clientPos, NULL_VECTOR, NULL_VECTOR);

	// Hacer invisible
	int effects = GetEntProp(button, Prop_Send, "m_fEffects");
	effects |= 32; // EF_NODRAW
	SetEntProp(button, Prop_Send, "m_fEffects", effects);

	// Auto-activar el botón para el cliente
	SetEntPropEnt(button, Prop_Data, "m_hActivator", client);
	AcceptEntityInput(button, "Press", client, client);

	// Guardar referencia
	g_iKnife_ProgressButton[client] = button;
}

/**
 * Destruye el botón de progreso
 */
stock void Knife_DestroyProgressButton(int client)
{
	int button = g_iKnife_ProgressButton[client];
	if (button > 0 && IsValidEntity(button))
	{
		AcceptEntityInput(button, "Disable");
		AcceptEntityInput(button, "Kill");
	}
	g_iKnife_ProgressButton[client] = -1;
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
				PrintHintText(client, "");
				PrintToChat(client, "\x04[KNIFE]\x01 \x05CUT SMOKER'S TONGUE!\x01");
				PrintCenterText(client, ">> SMOKER TONGUE CUT! <<");

				// Efecto de pantalla
				Knife_ScreenEffect(client, {0, 255, 0, 30}); // Verde

				Knife_BreakInfectedHold(zombie);
				return;
			}
		}

		// Daño normal - Feedback mejorado
		char zombieName[32];
		Knife_GetInfectedName(zombie, zombieName, sizeof(zombieName));

		PrintHintText(client, "");
		PrintToChat(client, "\x04[KNIFE]\x01 \x05CRITICAL HIT!\x01 [\x03%d\x01 damage to %s]", damage, zombieName);
		PrintCenterText(client, ">> STABBING SUCCESSFUL! <<\n%d DAMAGE", damage);

		// Efecto de pantalla (rojo intenso para daño alto, naranja para daño bajo)
		if (damage >= 100)
			Knife_ScreenEffect(client, {255, 0, 0, 40}); // Rojo
		else
			Knife_ScreenEffect(client, {255, 165, 0, 30}); // Naranja

		Knife_DealDamage(zombie, damage);
	}
	else
	{
		// Falló - Feedback mejorado
		PrintHintText(client, "");
		PrintToChat(client, "\x04[KNIFE]\x01 \x07You missed!\x01 (Rolled: %d, Needed: %d+)", random, minChance);
		PrintCenterText(client, ">> KNIFE ATTACK FAILED! <<");

		// Efecto de pantalla gris para fallo
		Knife_ScreenEffect(client, {128, 128, 128, 20});
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

/**
 * Aplica un efecto de pantalla al jugador
 */
stock void Knife_ScreenEffect(int client, int color[4])
{
	int targets[2];
	targets[0] = client;

	int duration = 500; // 0.5 segundos
	int holdtime = 100;
	int flags = 0x0001; // FFADE_IN

	Handle message = StartMessageEx(GetUserMessageId("Fade"), targets, 1);
	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]); // R
		BfWriteByte(message, color[1]); // G
		BfWriteByte(message, color[2]); // B
		BfWriteByte(message, color[3]); // A
		EndMessage();
	}
}

/**
 * Obtiene el nombre del infectado
 */
stock void Knife_GetInfectedName(int client, char[] buffer, int maxlength)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != 3)
	{
		strcopy(buffer, maxlength, "Infected");
		return;
	}

	int zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");

	switch (zombieClass)
	{
		case 1: strcopy(buffer, maxlength, "Smoker");
		case 2: strcopy(buffer, maxlength, "Boomer");
		case 3: strcopy(buffer, maxlength, "Hunter");
		case 4: strcopy(buffer, maxlength, "Spitter");
		case 5: strcopy(buffer, maxlength, "Jockey");
		case 6: strcopy(buffer, maxlength, "Charger");
		case 8: strcopy(buffer, maxlength, "Tank");
		default: strcopy(buffer, maxlength, "Infected");
	}
}
