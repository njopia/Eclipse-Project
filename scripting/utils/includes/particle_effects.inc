#if defined _particle_effects_included
	#endinput
#endif
#define _particle_effects_included

// =============================================================================
// PARTÍCULAS COMUNES DE L4D2
// =============================================================================

// Fuego
#define PARTICLE_FIRE_SMALL		   "fire_small_01"
#define PARTICLE_FIRE_MEDIUM	   "fire_medium_01"
#define PARTICLE_FIRE_LARGE		   "fire_large_01"
#define PARTICLE_MOLOTOV_FIRE	   "fire_molotov_explosion"
#define PARTICLE_MOLOTOV_SPREAD	   "fire_molotov_spread"

// Explosiones
#define PARTICLE_EXPLOSION		   "explosioncore_wall"
#define PARTICLE_EXPLOSION_GRENADE "explosion_grenade_gg"
#define PARTICLE_EXPLOSION_LARGE   "explosion_huge_b"

// Sangre
#define PARTICLE_BLOOD_MIST		   "blood_impact_red_01"
#define PARTICLE_BLOOD_SPLATTER	   "blood_impact_bullet_01"
#define PARTICLE_BLOOD_EXPLOSION   "boomer_explode_D"

// Especiales de infectados
#define PARTICLE_BOOMER_BILE	   "boomer_explode_D"
#define PARTICLE_SMOKER_TONGUE	   "smoker_tongue_smoke"
#define PARTICLE_SMOKER_COUGH	   "smoker_smokecloud"
#define PARTICLE_HUNTER_POUNCE	   "hunter_projected_trail"
#define PARTICLE_SPITTER_SPIT	   "spitter_projectile_trail"
#define PARTICLE_SPITTER_ACID	   "spitter_acid_puddle_green"
#define PARTICLE_CHARGER_IMPACT	   "charger_impact_01"
#define PARTICLE_JOCKEY_RIDE	   "jockey_smoke_trail"
#define PARTICLE_WITCH_ALERT	   "witch_alert_01"
#define PARTICLE_TANK_ROCK		   "tank_rock_trail"

// Efectos ambientales
#define PARTICLE_SMOKE_SMALL	   "smoke_small_01"
#define PARTICLE_SMOKE_LARGE	   "smoke_medium_01"
#define PARTICLE_ELECTRIC_SPARK	   "electric_spark_01b"
#define PARTICLE_FLASHLIGHT		   "flashlight_switchon"
#define PARTICLE_PIPE_BOMB		   "pipebomb_trail"
#define PARTICLE_ADRENALINE		   "adrenaline_use_1st"

// Curación / Soporte
#define PARTICLE_MEDKIT_USE		   "firstaid_use_1st"
#define PARTICLE_DEFIBRILLATOR	   "defibrillator_use_1stP"

// =============================================================================
// LÍMITE DE PARTÍCULAS (anti-crash)
// =============================================================================

#define FX_MAX_PARTICLES		   64

static int g_iFXParticleCount = 0;

// =============================================================================
// FUNCIONES PÚBLICAS
// =============================================================================

/**
 * Precachea una partícula creándola brevemente.
 * Llamar en OnMapStart() para cada partícula que vayas a usar.
 *
 * @param particlename  Nombre del efecto.
 */
stock void FX_PrecacheParticle(const char[] particlename)
{
	int particle = CreateEntityByName("info_particle_system");
	if (!IsValidEntity(particle))
		return;

	DispatchKeyValue(particle, "effect_name", particlename);
	DispatchKeyValue(particle, "targetname", "particle");
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CreateTimer(0.1, _FX_DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Precachea múltiples partículas de un array.
 *
 * @param particles     Array de nombres de partículas.
 * @param count         Cantidad de elementos en el array.
 */
stock void FX_PrecacheParticles(const char[][] particles, int count)
{
	for (int i = 0; i < count; i++)
		FX_PrecacheParticle(particles[i]);
}

/**
 * Crea una partícula estática en la posición de una entidad.
 *
 * @param target        Entidad de referencia.
 * @param particlename  Nombre del efecto.
 * @param time          Duración en segundos.
 * @param origin        Offset en Z sobre la entidad.
 * @return              Índice de la entidad creada, o -1 si falló.
 */
stock int FX_CreateParticle(int target, const char[] particlename, float time, float origin = 0.0)
{
	if (target <= 0 || !IsValidEntity(target))
		return -1;

	if (g_iFXParticleCount >= FX_MAX_PARTICLES)
		return -1;

	int particle = CreateEntityByName("info_particle_system");
	if (!IsValidEntity(particle))
		return -1;

	float pos[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
	pos[2] += origin;
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(particle, "effect_name", particlename);
	DispatchKeyValue(particle, "targetname", "particle");
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");

	g_iFXParticleCount++;
	CreateTimer(time, _FX_DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
	return particle;
}

/**
 * Crea una partícula en coordenadas absolutas del mundo.
 *
 * @param pos           Posición en el mundo [x, y, z].
 * @param particlename  Nombre del efecto.
 * @param time          Duración en segundos.
 * @return              Índice de la entidad creada, o -1 si falló.
 */
stock int FX_CreateParticleAtPos(const float pos[3], const char[] particlename, float time)
{
	if (g_iFXParticleCount >= FX_MAX_PARTICLES)
		return -1;

	int particle = CreateEntityByName("info_particle_system");
	if (!IsValidEntity(particle))
		return -1;

	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(particle, "effect_name", particlename);
	DispatchKeyValue(particle, "targetname", "particle");
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");

	g_iFXParticleCount++;
	CreateTimer(time, _FX_DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
	return particle;
}

/**
 * Crea una partícula adjunta a una entidad (la sigue si se mueve).
 *
 * @param target        Entidad a la que se adjunta.
 * @param particlename  Nombre del efecto.
 * @param time          Duración en segundos.
 * @param origin        Offset en Z sobre la entidad.
 * @return              Índice de la entidad creada, o -1 si falló.
 */
stock int FX_AttachParticle(int target, const char[] particlename, float time, float origin = 0.0)
{
	if (target <= 0 || !IsValidEntity(target))
		return -1;

	if (g_iFXParticleCount >= FX_MAX_PARTICLES)
		return -1;

	int particle = CreateEntityByName("info_particle_system");
	if (!IsValidEntity(particle))
		return -1;

	float pos[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
	pos[2] += origin;
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

	char tName[64];
	Format(tName, sizeof(tName), "Attach%d", target);
	DispatchKeyValue(target, "targetname", tName);
	GetEntPropString(target, Prop_Data, "m_iName", tName, sizeof(tName));

	DispatchKeyValue(particle, "scale", "");
	DispatchKeyValue(particle, "effect_name", particlename);
	DispatchKeyValue(particle, "parentname", tName);
	DispatchKeyValue(particle, "targetname", "particle");
	DispatchSpawn(particle);
	ActivateEntity(particle);
	SetVariantString(tName);
	AcceptEntityInput(particle, "SetParent", particle, particle);
	AcceptEntityInput(particle, "Enable");
	AcceptEntityInput(particle, "start");

	g_iFXParticleCount++;
	CreateTimer(time, _FX_DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
	return particle;
}

/**
 * Crea una partícula adjunta a un attachment point del modelo (hueso exacto).
 * Útil para efectos en manos, cabeza, pies, etc.
 *
 * @param target        Entidad a la que se adjunta.
 * @param particlename  Nombre del efecto.
 * @param attachment    Nombre del attachment point (ej: "head", "rhand", "lhand").
 * @param time          Duración en segundos.
 * @return              Índice de la entidad creada, o -1 si falló.
 */
stock int FX_AttachParticleToAttachment(int target, const char[] particlename, const char[] attachment, float time)
{
	if (target <= 0 || !IsValidEntity(target))
		return -1;

	if (g_iFXParticleCount >= FX_MAX_PARTICLES)
		return -1;

	int particle = CreateEntityByName("info_particle_system");
	if (!IsValidEntity(particle))
		return -1;

	float pos[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

	char tName[64];
	Format(tName, sizeof(tName), "Attach%d", target);
	DispatchKeyValue(target, "targetname", tName);
	GetEntPropString(target, Prop_Data, "m_iName", tName, sizeof(tName));

	DispatchKeyValue(particle, "scale", "");
	DispatchKeyValue(particle, "effect_name", particlename);
	DispatchKeyValue(particle, "parentname", tName);
	DispatchKeyValue(particle, "targetname", "particle");
	DispatchSpawn(particle);
	ActivateEntity(particle);

	// Vincula al attachment point específico del modelo
	SetVariantString(tName);
	AcceptEntityInput(particle, "SetParent", particle, particle);
	SetVariantString(attachment);
	AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset");

	AcceptEntityInput(particle, "Enable");
	AcceptEntityInput(particle, "start");

	g_iFXParticleCount++;
	CreateTimer(time, _FX_DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
	return particle;
}

/**
 * Elimina todas las partículas activas del mundo inmediatamente.
 * Útil en OnMapEnd() o al limpiar una ronda.
 */
stock void FX_KillAllParticles()
{
	int particle = -1;
	while ((particle = FindEntityByClassname(particle, "info_particle_system")) != -1)
		AcceptEntityInput(particle, "Kill");

	g_iFXParticleCount = 0;
}

/**
 * Elimina partículas activas que tengan un targetname específico.
 *
 * @param targetname    El targetname asignado al crear las partículas.
 */
stock void FX_KillParticlesByName(const char[] targetname)
{
	int	 particle = -1;
	char name[64];
	while ((particle = FindEntityByClassname(particle, "info_particle_system")) != -1)
	{
		GetEntPropString(particle, Prop_Data, "m_iName", name, sizeof(name));
		if (StrEqual(name, targetname, false))
			AcceptEntityInput(particle, "Kill");
	}
}

/**
 * Retorna cuántas partículas FX están activas actualmente.
 *
 * @return  Cantidad de partículas activas.
 */
stock int FX_GetParticleCount()
{
	return g_iFXParticleCount;
}

/**
 * Retorna true si se alcanzó el límite de partículas.
 */
stock bool FX_IsParticleLimitReached()
{
	return g_iFXParticleCount >= FX_MAX_PARTICLES;
}

// =============================================================================
// INTERNAL
// =============================================================================

/**
 * @internal — No llamar directamente.
 */
public Action _FX_DeleteParticle(Handle timer, any particle)
{
	if (g_iFXParticleCount > 0)
		g_iFXParticleCount--;

	if (!IsValidEntity(particle))
		return Plugin_Stop;

	char classname[64];
	GetEdictClassname(particle, classname, sizeof(classname));
	if (StrEqual(classname, "info_particle_system", false))
		AcceptEntityInput(particle, "Kill");

	return Plugin_Stop;
}
