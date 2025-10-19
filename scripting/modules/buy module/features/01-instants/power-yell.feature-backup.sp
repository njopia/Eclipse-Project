#if defined _power_yell_feature_
	#endinput
#endif
#define _power_yell_feature_

#include <sdktools>
#include <left4dhooks>	  // Necesario para L4D_StaggerPlayer

///////////////////////////
// INSTANTS: Power Yell  //
///////////////////////////

// --- Defines ---
#define POWER_YELL_RADIUS	  400.0	   // Radio en unidades para repeler a los infectados.
#define POWER_YELL_PUSH_FORCE 700.0	   // Fuerza del empujón.
#define POWER_YELL_COOLDOWN	  5.0	   // Cooldown en segundos.

// Efectos de partículas
#define PARTICLE_ELECTRIC	  "electrical_arc_01_system"
#define PARTICLE_FIRE		  "gas_explosion_ground_fire"
#define PARTICLE_SHOCKWAVE	  "bomb_explosion_huge"

// --- Variables ---
static float g_fNextPowerYell[MAXPLAYERS + 1];

/**
 * Activa la habilidad Power Yell para un jugador.
 * El jugador emite un grito que repele a los infectados comunes y especiales cercanos.
 *
 * @param client  Índice del jugador que activa la habilidad.
 */
stock void	 Activate_PowerYell(int client)
{
	// 1. Verificar que el cliente es válido
	if (!IsValidSurvivor(client))
		return;

	// 2. Verificar Cooldown
	float remainingTime = g_fNextPowerYell[client] - GetGameTime();
	if (remainingTime > 0.0)
	{
		PrintToChat(client, "\x05[Eclipse]\x01 Debes esperar \x04%.1f\x01 segundos para usar el Grito de Poder.", remainingTime);
		return;
	}

	// 3. Efectos audiovisuales
	PlayPowerYellEffects(client);

	// 4. Obtener posición del jugador
	float origin[3];
	GetClientAbsOrigin(client, origin);

	// 5. Repeler infectados
	int commonPushed  = PushCommonInfected(client, origin);
	int specialPushed = PushSpecialInfected(client, origin);
	int totalPushed	  = commonPushed + specialPushed;

	// 6. Feedback al jugador
	if (totalPushed > 0)
	{
		PrintToChat(client, "\x05[Eclipse]\x01 Repeliste a \x04%d\x01 infectados (\x04%d\x01 comunes, \x04%d\x01 especiales).",
					totalPushed, commonPushed, specialPushed);
	}
	else
	{
		PrintToChat(client, "\x05[Eclipse]\x01 No hay infectados cerca para repeler.");
	}

	// 7. Establecer cooldown
	g_fNextPowerYell[client] = GetGameTime() + POWER_YELL_COOLDOWN;
}

/**
 * Reproduce efectos de sonido y visuales para el Power Yell.
 */
static void PlayPowerYellEffects(int client)
{
	// Sonido de grito
	EmitSoundToAll("player/survivor/voice/producer/taunt01.wav", client, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8);

	// Mensaje al jugador
	PrintToChat(client, "\x05[Eclipse]\x01 ¡Has desatado un \x04Grito de Poder\x01!");

	// Efectos visuales
	float origin[3];
	GetClientAbsOrigin(client, origin);

	CreateParticleEffect(origin, PARTICLE_ELECTRIC, 2.0);
	CreateShockwaveEffect(origin);
}

/**
 * Crea una partícula temporal en la posición dada.
 */
static void CreateParticleEffect(const float origin[3], const char[] effectName, float duration)
{
	int particle = CreateEntityByName("info_particle_system");
	if (particle != -1)
	{
		DispatchKeyValue(particle, "effect_name", effectName);
		TeleportEntity(particle, origin, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		// Auto-destruir después de la duración
		char output[64];
		Format(output, sizeof(output), "OnUser1 !self:Kill::%.1f:-1", duration);
		SetVariantString(output);
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
	}
}

/**
 * Crea efecto de onda de choque visual
 */
static void CreateShockwaveEffect(const float origin[3])
{
	// Crear onda expansiva con modelo de sprite
	int sprite = CreateEntityByName("env_sprite");
	if (sprite != -1)
	{
		float adjustedOrigin[3];
		adjustedOrigin[0] = origin[0];
		adjustedOrigin[1] = origin[1];
		adjustedOrigin[2] = origin[2] + 10.0;

		DispatchKeyValue(sprite, "model", "sprites/blueglow1.vmt");
		DispatchKeyValue(sprite, "rendercolor", "100 200 255");
		DispatchKeyValue(sprite, "renderamt", "200");
		DispatchKeyValue(sprite, "scale", "2.0");

		TeleportEntity(sprite, adjustedOrigin, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(sprite);

		// Auto-destruir
		SetVariantString("OnUser1 !self:Kill::0.5:-1");
		AcceptEntityInput(sprite, "AddOutput");
		AcceptEntityInput(sprite, "FireUser1");
	}
}

/**
 * Empuja a los infectados comunes dentro del radio.
 * @param attacker  Cliente que origina el empuje
 * @param origin    Posición de origen del empuje
 * @return          El número de infectados comunes empujados.
 */
static int PushCommonInfected(int attacker, const float origin[3])
{
	int	  entity = -1;
	int	  pushed = 0;
	float entityOrigin[3];
	float radiusSquared = POWER_YELL_RADIUS * POWER_YELL_RADIUS;	// Optimización

	while ((entity = FindEntityByClassname(entity, "infected")) != -1)
	{
		// Validación: Verificar que la entidad existe y está viva
		if (!IsValidEntity(entity))
			continue;

		int health = GetEntProp(entity, Prop_Data, "m_iHealth", 1);
		if (health <= 0)
			continue;

		// Validación: Verificar que puede moverse
		MoveType movetype = GetEntityMoveType(entity);
		if (movetype == MOVETYPE_NONE || movetype == MOVETYPE_NOCLIP)
			continue;

		// Verificar distancia
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityOrigin);
		if (GetVectorDistanceSquared(origin, entityOrigin) > radiusSquared)
			continue;

		// Empujar infectado común
		PushCommonEntity(entity, origin, attacker);
		pushed++;
	}
	return pushed;
}

/**
 * Empuja a los infectados especiales (jugadores) dentro del radio.
 * @param attacker  Cliente que origina el empuje
 * @param origin    Posición de origen del empuje
 * @return          El número de infectados especiales empujados.
 */
static int PushSpecialInfected(int attacker, const float origin[3])
{
	int	  pushed = 0;
	float entityOrigin[3];
	float radiusSquared = POWER_YELL_RADIUS * POWER_YELL_RADIUS;

	for (int i = 1; i <= MaxClients; i++)
	{
		// Validación: Cliente conectado, vivo y en equipo infectado
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
			continue;

		if (GetClientTeam(i) != 3)
			continue;

		// No empujar fantasmas
		if (IsPlayerGhost(i))
			continue;

		// Verificar que es un infectado especial válido
		int zombieClass = GetEntProp(i, Prop_Send, "m_zombieClass");
		if (zombieClass < ZOMBIECLASS_SMOKER || zombieClass > ZOMBIECLASS_CHARGER)
			continue;

		// No empujar Tanks (demasiado pesados)
		if (zombieClass == ZOMBIECLASS_TANK)
			continue;

		// Verificar distancia
		GetClientAbsOrigin(i, entityOrigin);
		if (GetVectorDistanceSquared(origin, entityOrigin) > radiusSquared)
			continue;

		// Empujar infectado especial
		PushSpecialEntity(i, origin, attacker);
		pushed++;
	}
	return pushed;
}

/**
 * Empuja un infectado común con efecto de muerte por fuerza bruta
 */
static void PushCommonEntity(int entity, const float origin[3], int attacker)
{
	// Calcular dirección del empuje
	float targetOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", targetOrigin);

	float pushDir[3];
	SubtractVectors(targetOrigin, origin, pushDir);
	NormalizeVector(pushDir, pushDir);

	// Crear velocidad con componente vertical
	float velocity[3];
	velocity[0] = pushDir[0];
	velocity[1] = pushDir[1];
	velocity[2] = 0.6;	  // Componente vertical para levantarlos

	// Escalar a la fuerza configurada
	ScaleVector(velocity, POWER_YELL_PUSH_FORCE);

	// Aplicar velocidad
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, velocity);

	// Matar el infectado común con daño contundente (más dramático)
	SDKHooks_TakeDamage(entity, attacker, attacker, 100.0, DMG_CLUB);
}

/**
 * Empuja un infectado especial (jugador) usando L4D_StaggerPlayer
 */
static void PushSpecialEntity(int entity, const float origin[3], int attacker)
{
	// Calcular dirección del empuje
	float targetOrigin[3];
	GetClientAbsOrigin(entity, targetOrigin);

	float pushDir[3];
	SubtractVectors(targetOrigin, origin, pushDir);
	NormalizeVector(pushDir, pushDir);

	// Calcular velocidad resultante
	float velocity[3];
	float angles[3];
	GetVectorAngles(pushDir, angles);

	velocity[0] = Cosine(DegToRad(angles[1])) * POWER_YELL_PUSH_FORCE;
	velocity[1] = Sine(DegToRad(angles[1])) * POWER_YELL_PUSH_FORCE;
	velocity[2] = POWER_YELL_PUSH_FORCE * 0.5;	  // Componente vertical

	// Añadir velocidad actual del jugador para efecto más natural
	float currentVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecVelocity", currentVelocity);
	AddVectors(velocity, currentVelocity, velocity);

	// Aplicar velocidad y efecto de tambaleo
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, velocity);
	L4D_StaggerPlayer(entity, attacker, pushDir);

	// Efecto de sonido de impacto
	EmitSoundToAll("player/tank/hit/hulk_punch_1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
}

// ============================================
// FUNCIONES AUXILIARES
// ============================================

/**
 * Verifica si un cliente es un sobreviviente válido
 */
static bool IsValidSurvivor(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	if (!IsClientInGame(client))
		return false;

	if (!IsPlayerAlive(client))
		return false;

	if (GetClientTeam(client) != 2)
		return false;

	return true;
}

/**
 * Verifica si el jugador es un fantasma
 */
static bool IsPlayerGhost(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isGhost") == 1);
}

/**
 * Calcula la distancia al cuadrado entre dos vectores (más rápido que GetVectorDistance)
 * Evita el cálculo de raíz cuadrada para mejor rendimiento.
 *
 * @param vec1  Primer vector
 * @param vec2  Segundo vector
 * @return      Distancia al cuadrado
 */
static float GetVectorDistanceSquared(const float vec1[3], const float vec2[3])
{
	float dx = vec1[0] - vec2[0];
	float dy = vec1[1] - vec2[1];
	float dz = vec1[2] - vec2[2];
	return (dx * dx + dy * dy + dz * dz);
}