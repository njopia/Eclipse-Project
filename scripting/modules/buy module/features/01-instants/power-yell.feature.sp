#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

// ---  Efectos de sonido/grito ---
#define YELLNICK_1			"player/survivor/voice/gambler/battlecry04.wav"
#define YELLNICK_2			"player/survivor/voice/gambler/battlecry01.wav"
#define YELLNICK_3			"player/survivor/voice/gambler/battlecry02.wav"

// --- Defines ---
#define POWER_YELL_RADIUS	400.0	// Radio en unidades para repeler a los infectados.
#define POWER_YELL_PUSH_FORCE	700.0	// Fuerza del empujon.
#define POWER_YELL_COOLDOWN	5.0	// Cooldown en segundos.

// Efectos de particulas — ahora usando macros de particle_effects.inc
#define PARTICLE_POWERYELL_ELECTRIC	PARTICLE_ELECTRIC_SPARK
#define PARTICLE_POWERYELL_FIRE		PARTICLE_FIRE_LARGE
#define PARTICLE_POWERYELL_EXPLOSION	PARTICLE_EXPLOSION_LARGE

stock void Yell(int client)
{
	if (!IsNormalPlayer(client)) return;

	EmitYell(client);

	float pos[3];
	float tpos[3];
	float traceVec[3];
	float resultingFling[3];
	float currentVelVec[3];

	GetClientAbsOrigin(client, pos);
	float distance;

	if (GetClientTeam(client) == 2)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i == 0 || !IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || IsPlayerGhost(i))
				continue;

			if (GetClientTeam(client) == GetClientTeam(i))
				continue;

			GetClientAbsOrigin(i, tpos);
			distance = GetVectorDistance(pos, tpos);

			if (FloatCompare(distance, POWER_YELL_RADIUS) == -1 && !IsTank(i))
			{
				// Particula adjunta al infectado usando el nuevo include
				FX_AttachParticle(i, PARTICLE_POWERYELL_ELECTRIC, 2.0);
			}

			MakeVectorFromPoints(pos, tpos, traceVec);
			GetVectorAngles(traceVec, resultingFling);

			resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * POWER_YELL_PUSH_FORCE;
			resultingFling[1] = Sine(DegToRad(resultingFling[1]))   * POWER_YELL_PUSH_FORCE;
			resultingFling[2] = POWER_YELL_PUSH_FORCE;

			GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);
			resultingFling[0] += currentVelVec[0];
			resultingFling[1] += currentVelVec[1];
			resultingFling[2] += currentVelVec[2];

			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resultingFling);
			L4D_StaggerPlayer(i, client, resultingFling);
		}

		char class[32];
		GetClientAbsOrigin(client, pos);
		for (int i = MaxClients + 1; i < GetMaxEntities(); i++)
		{
			if (!IsValidEntity(i) || !IsValidEdict(i))
				continue;

			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "infected") || StrEqual(class, "&infected"))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", tpos);
				distance = GetVectorDistance(pos, tpos);
				if (FloatCompare(distance, POWER_YELL_RADIUS) == -1)
					HurtPoint(client, i, 0, 536870912, 100);
			}
		}
	}

	// Particula y shockwave en la posicion del jugador
	float origin[3];
	GetClientAbsOrigin(client, origin);

	FX_CreateParticleAtPos(origin, PARTICLE_POWERYELL_ELECTRIC, 2.0);
	CreateShockwaveEffect(origin);
}

void HurtPoint(int client, int ent, int dmg, int dmg_type, int dmg_radius)
{
	if (!IsValidPlayer(client)) return;
	if (!IsValidEdict(ent)) return;

	float pos[3];
	char  StrDamage[16];
	char  StrDamageType[16];
	char  StrDamageRadius[16];
	char  strDamageTarget[16];

	Format(StrDamage,       sizeof(StrDamage),       "%i", dmg);
	Format(StrDamageType,   sizeof(StrDamageType),   "%i", dmg_type);
	Format(StrDamageRadius, sizeof(StrDamageRadius),  "%i", dmg_radius);
	Format(strDamageTarget, sizeof(strDamageTarget),  "hurtme%d", ent);

	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	pos[2] += 1.0;

	int pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(ent,       "targetname",    strDamageTarget);
	DispatchKeyValue(pointHurt, "DamageTarget",  strDamageTarget);
	DispatchKeyValue(pointHurt, "Damage",        StrDamage);
	DispatchKeyValue(pointHurt, "DamageRadius",  StrDamageRadius);
	DispatchKeyValue(pointHurt, "DamageType",    StrDamageType);
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(pointHurt, "Hurt",
		(client > 0 && client < MaxClients && IsClientInGame(client)) ? client : -1);

	DispatchKeyValue(pointHurt, "classname", "point_hurt");
	DispatchKeyValue(ent, "targetname", "null");
	AcceptEntityInput(pointHurt, "Kill");
}

// =============================================================================
// HELPERS
// =============================================================================

stock bool IsValidPlayer(int client)
{
	return client > 0
		&& client <= MaxClients
		&& IsClientConnected(client)
		&& IsClientInGame(client)
		&& !IsFakeClient(client);
}

stock bool IsNormalPlayer(int client)
{
	return client > 0
		&& client <= MaxClients
		&& IsClientConnected(client)
		&& IsClientInGame(client);
}

stock bool IsPlayerGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost", 1));
}

stock void EmitYell(int client)
{
	if (!IsValidPlayer(client)) return;
	if (GetClientTeam(client) != 2) return;

	switch (GetRandomInt(1, 3))
	{
		case 1: EmitSoundToAll(YELLNICK_1, client);
		case 2: EmitSoundToAll(YELLNICK_2, client);
		case 3: EmitSoundToAll(YELLNICK_3, client);
	}
}

/**
 * Crea efecto de onda de choque visual.
 * Se mantiene aqui porque es especifico de esta feature (env_sprite, no particula).
 */
static void CreateShockwaveEffect(const float origin[3])
{
	int sprite = CreateEntityByName("env_sprite");
	if (sprite == -1) return;

	float adjustedOrigin[3];
	adjustedOrigin[0] = origin[0];
	adjustedOrigin[1] = origin[1];
	adjustedOrigin[2] = origin[2] + 10.0;

	DispatchKeyValue(sprite, "model",       "sprites/blueglow1.vmt");
	DispatchKeyValue(sprite, "rendercolor", "100 200 255");
	DispatchKeyValue(sprite, "renderamt",   "200");
	DispatchKeyValue(sprite, "scale",       "2.0");

	TeleportEntity(sprite, adjustedOrigin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(sprite);

	SetVariantString("OnUser1 !self:Kill::0.5:-1");
	AcceptEntityInput(sprite, "AddOutput");
	AcceptEntityInput(sprite, "FireUser1");
}

/**
 * Resetea el cooldown de Power Yell para un jugador.
 * Existe para compatibilidad con el sistema de reseteo global.
 */
stock void ResetPowerYellCooldown(int client)
{
	#pragma unused client
}
