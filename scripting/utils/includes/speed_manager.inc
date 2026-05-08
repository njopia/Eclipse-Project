#if defined _speed_manager_included
	#endinput
#endif
#define _speed_manager_included

// =============================================================================
// SPEED MANAGER — EMS
// Gestiona velocidades de sobrevivientes mediante un sistema de capas (layers).
// La velocidad más alta activa se aplica mediante los forwards de L4D:
//   L4D_OnGetRunTopSpeed / WalkTopSpeed / CrouchTopSpeed
// Esto garantiza que el boost persiste ante cualquier reset del engine
// (adrenalina, incap, agarrón de SI, etc.).
// =============================================================================

// --- Capas disponibles (prioridad por valor, mayor = más prioritario) ---
enum SpeedLayer
{
	SpeedLayer_Base        = 0,  // Velocidad base del juego (1.0)
	SpeedLayer_TeamBoost   = 1,  // Team Speed Boost (compra de equipo)
	SpeedLayer_SurvBoost   = 2,  // Surge individual (compra individual)
	SpeedLayer_SpeedFreak  = 3,  // Ability Speed Freak (nivel 31)
}

#define SPEED_LAYER_COUNT   4
#define SPEED_BASE          1.0
#define SPEED_MAX           3.0  // Techo absoluto anti-abuso

// --- Estado interno ---
static float  g_fSpeedLayers[MAXPLAYERS + 1][SPEED_LAYER_COUNT];
static Handle g_hSpeedTimers[MAXPLAYERS + 1][SPEED_LAYER_COUNT];

// =============================================================================
// API PÚBLICA
// =============================================================================

/**
 * Aplica una capa de velocidad a un cliente con duración opcional.
 * Si ya hay una capa activa del mismo tipo, la reemplaza.
 *
 * @param client    Índice del cliente.
 * @param layer     Capa de velocidad a aplicar.
 * @param speed     Multiplicador de velocidad (ej: 1.4 = 40% más rápido).
 * @param duration  Duración en segundos. 0.0 = permanente hasta remover manualmente.
 */
stock void SPD_Apply(int client, SpeedLayer layer, float speed, float duration = 0.0)
{
	if (!_SPD_IsValidClient(client)) return;

	speed = _SPD_Clamp(speed, SPEED_BASE, SPEED_MAX);

	_SPD_KillLayerTimer(client, layer);
	g_fSpeedLayers[client][layer] = speed;

	if (duration > 0.0)
	{
		DataPack pack = new DataPack();
		pack.WriteCell(client);
		pack.WriteCell(view_as<int>(layer));
		g_hSpeedTimers[client][layer] = CreateTimer(duration, _SPD_TimerExpire, pack, TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * Remueve una capa de velocidad específica de un cliente.
 *
 * @param client    Índice del cliente.
 * @param layer     Capa a remover.
 */
stock void SPD_Remove(int client, SpeedLayer layer)
{
	if (client < 1 || client > MaxClients) return;

	_SPD_KillLayerTimer(client, layer);
	g_fSpeedLayers[client][layer] = 0.0;
}

/**
 * Remueve todas las capas de un cliente.
 *
 * @param client    Índice del cliente.
 */
stock void SPD_RemoveAll(int client)
{
	if (client < 1 || client > MaxClients) return;

	for (int i = 0; i < SPEED_LAYER_COUNT; i++)
	{
		_SPD_KillLayerTimer(client, view_as<SpeedLayer>(i));
		g_fSpeedLayers[client][i] = 0.0;
	}
}

/**
 * Aplica la capa a todos los sobrevivientes en juego.
 *
 * @param layer     Capa a aplicar.
 * @param speed     Multiplicador de velocidad.
 * @param duration  Duración en segundos. 0.0 = permanente.
 */
stock void SPD_ApplyToTeam(SpeedLayer layer, float speed, float duration = 0.0)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (_SPD_IsValidSurvivor(i))
			SPD_Apply(i, layer, speed, duration);
	}
}

/**
 * Remueve una capa de todos los sobrevivientes en juego.
 *
 * @param layer     Capa a remover.
 */
stock void SPD_RemoveFromTeam(SpeedLayer layer)
{
	for (int i = 1; i <= MaxClients; i++)
		SPD_Remove(i, layer);
}

/**
 * Retorna la velocidad efectiva actual de un cliente (capa más alta activa).
 *
 * @param client    Índice del cliente.
 * @return          Multiplicador activo, o SPEED_BASE si no hay capas.
 */
stock float SPD_GetEffective(int client)
{
	return _SPD_GetHighest(client);
}

/**
 * Retorna true si el cliente tiene una capa específica activa.
 *
 * @param client    Índice del cliente.
 * @param layer     Capa a verificar.
 */
stock bool SPD_HasLayer(int client, SpeedLayer layer)
{
	if (client < 1 || client > MaxClients) return false;
	return g_fSpeedLayers[client][layer] > 0.0;
}

// --- Llamar en OnClientDisconnect ---
stock void SPD_OnClientDisconnect(int client)
{
	SPD_RemoveAll(client);
}

// --- Llamar en OnMapEnd o CleanupTimers ---
stock void SPD_OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
		SPD_RemoveAll(i);
}

// =============================================================================
// L4D FORWARDS — enforcement por frame via engine
// El engine llama estos forwards cada vez que consulta la velocidad máxima
// del jugador. Retornar Plugin_Handled con retVal modificado es la forma
// canónica y más robusta de aplicar velocidad persistente en L4D2.
// =============================================================================

public Action L4D_OnGetRunTopSpeed(int target, float &retVal)
{
	return _SPD_ForwardApply(target, retVal);
}

public Action L4D_OnGetWalkTopSpeed(int target, float &retVal)
{
	return _SPD_ForwardApply(target, retVal);
}

public Action L4D_OnGetCrouchTopSpeed(int target, float &retVal)
{
	return _SPD_ForwardApply(target, retVal);
}

// =============================================================================
// INTERNAL
// =============================================================================

static Action _SPD_ForwardApply(int client, float &retVal)
{
	if (client < 1 || client > MaxClients) return Plugin_Continue;

	float mult = _SPD_GetHighest(client);
	if (mult <= SPEED_BASE) return Plugin_Continue;

	retVal *= mult;
	return Plugin_Handled;
}

static bool _SPD_IsValidClient(int client)
{
	return client >= 1
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& IsPlayerAlive(client)
		&& GetClientTeam(client) == 2;
}

static bool _SPD_IsValidSurvivor(int client)
{
	return _SPD_IsValidClient(client);
}

static float _SPD_Clamp(float val, float min, float max)
{
	if (val < min) return min;
	if (val > max) return max;
	return val;
}

static float _SPD_GetHighest(int client)
{
	float highest = 0.0;
	for (int i = 0; i < SPEED_LAYER_COUNT; i++)
	{
		if (g_fSpeedLayers[client][i] > highest)
			highest = g_fSpeedLayers[client][i];
	}
	return (highest > 0.0) ? highest : SPEED_BASE;
}

static void _SPD_KillLayerTimer(int client, SpeedLayer layer)
{
	if (g_hSpeedTimers[client][layer] != INVALID_HANDLE)
	{
		KillTimer(g_hSpeedTimers[client][layer]);
		g_hSpeedTimers[client][layer] = INVALID_HANDLE;
	}
}

public Action _SPD_TimerExpire(Handle timer, DataPack pack)
{
	pack.Reset();
	int client       = pack.ReadCell();
	SpeedLayer layer = view_as<SpeedLayer>(pack.ReadCell());
	delete pack;

	g_hSpeedTimers[client][layer] = INVALID_HANDLE;
	g_fSpeedLayers[client][layer] = 0.0;

	return Plugin_Stop;
}
