#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

#include <sdktools>

///////////////////////////
// INSTANTS: Fire Yell   //
///////////////////////////

// --- Defines ---
#define FIRE_YELL_RADIUS		350.0
#define FIRE_YELL_COOLDOWN		5.0
#define FIRE_YELL_BURN_DURATION	5.0
#define MAX_INFECTED_TO_BURN	50

// Partícula usando macro del include
#define PARTICLE_FIREYELL_FIRE		PARTICLE_MOLOTOV_FIRE

// --- Variables ---
static float g_fNextFireYell[MAXPLAYERS + 1];

/**
 * Activa la habilidad Fire Yell para un jugador.
 * El jugador emite un grito que quema a los infectados comunes y especiales cercanos.
 *
 * @param client  Índice del jugador que activa la habilidad.
 */
stock void Activate_FireYell(int client)
{
	float remainingTime = g_fNextFireYell[client] - GetGameTime();
	if (remainingTime > 0.0)
	{
		PrintToChat(client, "\x05[Eclipse]\x01 Debes esperar \x04%.1f\x01 segundos.", remainingTime);
		return;
	}

	PlayFireYellEffects(client);

	float origin[3];
	GetClientAbsOrigin(client, origin);

	int commonBurned  = BurnCommonInfected(origin);
	int specialBurned = BurnSpecialInfected(origin);
	int totalBurned   = commonBurned + specialBurned;

	if (totalBurned > 0)
		PrintToChat(client, "\x05[Eclipse]\x01 Quemaste \x04%d\x01 infectados (\x04%d\x01 comunes, \x04%d\x01 especiales).",
					totalBurned, commonBurned, specialBurned);
	else
		PrintToChat(client, "\x05[Eclipse]\x01 No hay infectados en el área.");

	g_fNextFireYell[client] = GetGameTime() + FIRE_YELL_COOLDOWN;
}

/**
 * Reproduce efectos de sonido y visuales.
 */
static void PlayFireYellEffects(int client)
{
	EmitSoundToAll("player/survivor/voice/mechanic/taunt02.wav", client, SNDCHAN_VOICE);
	PrintToChat(client, "\x05[Eclipse]\x01 ¡Has desatado un \x04Grito de Fuego\x01!");

	float origin[3];
	GetClientAbsOrigin(client, origin);

	// Partícula en posición del jugador usando FX include
	FX_CreateParticleAtPos(origin, PARTICLE_FIREYELL_FIRE, 2.0);
}

/**
 * Quema infectados comunes en el radio.
 * @return Número de infectados quemados.
 */
static int BurnCommonInfected(const float origin[3])
{
	int   entity = -1;
	int   burned = 0;
	float entityOrigin[3];
	float radiusSquared = FIRE_YELL_RADIUS * FIRE_YELL_RADIUS;

	while ((entity = FindEntityByClassname(entity, "infected")) != -1 && burned < MAX_INFECTED_TO_BURN)
	{
		if (!IsValidEntity(entity))
			continue;

		if (GetEntProp(entity, Prop_Data, "m_iHealth") <= 0)
			continue;

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityOrigin);

		if (GetVectorDistanceSquared(origin, entityOrigin) > radiusSquared)
			continue;

		IgniteEntity(entity, FIRE_YELL_BURN_DURATION);

		// Partícula adjunta al infectado quemado
		FX_AttachParticle(entity, PARTICLE_FIREYELL_FIRE, FIRE_YELL_BURN_DURATION);

		burned++;
	}

	return burned;
}

/**
 * Quema infectados especiales (jugadores) en el radio.
 * @return Número de especiales quemados.
 */
static int BurnSpecialInfected(const float origin[3])
{
	int   burned = 0;
	float entityOrigin[3];
	float radiusSquared = FIRE_YELL_RADIUS * FIRE_YELL_RADIUS;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidSpecialInfected(i))
			continue;

		GetClientAbsOrigin(i, entityOrigin);

		if (GetVectorDistanceSquared(origin, entityOrigin) > radiusSquared)
			continue;

		int zombieClass = GetEntProp(i, Prop_Send, "m_zombieClass");

		// Solo quemar Smoker, Boomer, Hunter, Spitter, Jockey, Charger — no Tank ni Witch
		if (zombieClass >= ZOMBIECLASS_SMOKER && zombieClass <= ZOMBIECLASS_CHARGER)
		{
			IgniteEntity(i, FIRE_YELL_BURN_DURATION);

			// Partícula adjunta al especial quemado
			FX_AttachParticle(i, PARTICLE_FIREYELL_FIRE, FIRE_YELL_BURN_DURATION);

			burned++;
		}
	}

	return burned;
}

/**
 * Verifica si un cliente es un infectado especial válido.
 */
static bool IsValidSpecialInfected(int client)
{
	return IsClientInGame(client)
		&& IsPlayerAlive(client)
		&& GetClientTeam(client) == 3;
}

/**
 * Reinicia el cooldown de un jugador.
 */
stock void ResetFireYellCooldown(int client)
{
	g_fNextFireYell[client] = 0.0;
}

/**
 * Obtiene el tiempo restante de cooldown.
 */
stock float GetFireYellCooldown(int client)
{
	float remaining = g_fNextFireYell[client] - GetGameTime();
	return (remaining > 0.0) ? remaining : 0.0;
}

static float GetVectorDistanceSquared(const float vec1[3], const float vec2[3])
{
	float dx = vec1[0] - vec2[0];
	float dy = vec1[1] - vec2[1];
	float dz = vec1[2] - vec2[2];
	return (dx * dx + dy * dy + dz * dz);
}
