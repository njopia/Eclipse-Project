#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === DOUBLE JUMP PASSIVE REWARD ===
// Permite al jugador realizar un segundo salto en el aire
//==================================================

// --- ConVars ---
Handle cvar_DoubleJump_RequiredLevel = INVALID_HANDLE;
Handle cvar_DoubleJump_JumpForce = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bDoubleJump_Enabled[MAXPLAYERS + 1];
int g_iDoubleJump_JumpsUsed[MAXPLAYERS + 1];
bool g_bDoubleJump_LastButtonState[MAXPLAYERS + 1];

/**
 * Inicializa el modulo de Double Jump
 */
public void DoubleJump_OnPluginStart()
{
	cvar_DoubleJump_RequiredLevel = CreateConVar(
		"reward_double_jump_level",
		"999",
		"Nivel requerido para desbloquear doble salto",
		FCVAR_PLUGIN
	);

	cvar_DoubleJump_JumpForce = CreateConVar(
		"reward_double_jump_force",
		"300.0",
		"Fuerza del impulso vertical del segundo salto",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void DoubleJump_OnClientConnect(int client)
{
	g_bDoubleJump_Enabled[client] = false;
	g_iDoubleJump_JumpsUsed[client] = 0;
	g_bDoubleJump_LastButtonState[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void DoubleJump_OnClientDisconnect(int client)
{
	g_bDoubleJump_Enabled[client] = false;
	g_iDoubleJump_JumpsUsed[client] = 0;
	g_bDoubleJump_LastButtonState[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void DoubleJump_OnPlayerSpawn(int client, int level)
{
	g_iDoubleJump_JumpsUsed[client] = 0;
	g_bDoubleJump_LastButtonState[client] = false;

	if (DoubleJump_IsUnlocked(client, level))
	{
		g_bDoubleJump_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void DoubleJump_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_DoubleJump_RequiredLevel);

	// Solo mostrar mensaje si justo alcanzo el nivel requerido
	if (level == requiredLevel)
	{
		g_bDoubleJump_Enabled[client] = true;
		PrintToChat(client, "\x04[REWARD]\x01 Desbloqueaste el \x05Doble Salto\x01!");
	}
	else if (level > requiredLevel)
	{
		g_bDoubleJump_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool DoubleJump_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_DoubleJump_RequiredLevel);
}

/**
 * Procesa el input del jugador cada tick
 */
public Action DoubleJump_OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
		return Plugin_Continue;

	// Solo survivors
	if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	// Verificar si tiene el doble salto habilitado
	if (!g_bDoubleJump_Enabled[client])
		return Plugin_Continue;

	int flags = GetEntityFlags(client);

	// Si esta en el suelo, resetear contador de saltos
	if (flags & FL_ONGROUND)
	{
		g_iDoubleJump_JumpsUsed[client] = 0;
		g_bDoubleJump_LastButtonState[client] = false;
	}
	else  // Esta en el aire
	{
		// Detectar cuando se presiona el boton de salto (rising edge)
		bool isPressingJump = (buttons & IN_JUMP) != 0;

		if (isPressingJump && !g_bDoubleJump_LastButtonState[client])
		{
			// El jugador acaba de presionar salto
			g_iDoubleJump_JumpsUsed[client]++;

			// Si es el segundo salto, aplicar impulso
			if (g_iDoubleJump_JumpsUsed[client] == 2)
			{
				float velocity[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
				velocity[2] = GetConVarFloat(cvar_DoubleJump_JumpForce);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

				// Incrementar para evitar multiples saltos
				g_iDoubleJump_JumpsUsed[client]++;
			}
		}

		g_bDoubleJump_LastButtonState[client] = isPressingJump;
	}

	return Plugin_Continue;
}

/**
 * Obtiene si el doble salto esta habilitado para un jugador
 */
public bool DoubleJump_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bDoubleJump_Enabled[client];
}
