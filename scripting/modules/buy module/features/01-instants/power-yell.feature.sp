#if !defined  EMS_MAIN_FILE
	 #error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif


// ---  Efectos de sonido/grito ---
#define YELLNICK_1			  "player/survivor/voice/gambler/battlecry04.wav"
#define YELLNICK_2			  "player/survivor/voice/gambler/battlecry01.wav"
#define YELLNICK_3			  "player/survivor/voice/gambler/battlecry02.wav"

// --- Defines ---
#define POWER_YELL_RADIUS	  400.0	   // Radio en unidades para repeler a los infectados.
#define POWER_YELL_PUSH_FORCE 700.0	   // Fuerza del empujón.
#define POWER_YELL_COOLDOWN	  5.0	   // Cooldown en segundos.

// Efectos de partículas
#define PARTICLE_ELECTRIC	  "electrical_arc_01_system"
#define PARTICLE_FIRE		  "gas_explosion_ground_fire"
#define PARTICLE_SHOCKWAVE	  "bomb_explosion_huge"

stock Yell(int client)
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
		for (new i = 1; i <= MaxClients; i++)
		{
			if (i == 0 || !IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || (IsPlayerGhost(i)))
			{
				continue;
			}
			if (GetClientTeam(client) == GetClientTeam(i))
			{
				continue;
			}

			GetClientAbsOrigin(i, tpos);
			distance = GetVectorDistance(pos, tpos);

			if ((FloatCompare(distance, POWER_YELL_RADIUS) == -1) && (!IsTank(i)))
				AttachParticle(i, PARTICLE_ELECTRIC, 2.0, 0.0);
			{
				PrintToChatAll("Applying fling to player %d", i);
				MakeVectorFromPoints(pos, tpos, traceVec);
				GetVectorAngles(traceVec, resultingFling);

				resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * POWER_YELL_PUSH_FORCE;
				resultingFling[1] = Sine(DegToRad(resultingFling[1])) * POWER_YELL_PUSH_FORCE;
				resultingFling[2] = POWER_YELL_PUSH_FORCE;

				GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);
				resultingFling[0] += currentVelVec[0];
				resultingFling[1] += currentVelVec[1];
				resultingFling[2] += currentVelVec[2];
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resultingFling);
				L4D_StaggerPlayer(i, client, resultingFling);
			}
		}
		char class[32];
		GetClientAbsOrigin(client, pos);
		for (new i = MaxClients + 1; i < GetMaxEntities(); i++)
		{
			if (IsValidEntity(i) && IsValidEdict(i))
			{
				GetEdictClassname(i, class, sizeof(class));
				if ((StrEqual(class, "infected")) || (StrEqual(class, "&infected")))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", tpos);
					distance = GetVectorDistance(pos, tpos);
					if (FloatCompare(distance, POWER_YELL_RADIUS) == -1)
					{
						HurtPoint(client, i, 0, 536870912, 100);
					}
				}
			}
		}
	}
	float origin[3];
	GetClientAbsOrigin(client, origin);
	CreateParticleEffect(origin, PARTICLE_ELECTRIC, 2.0);
	CreateShockwaveEffect(origin);
}
HurtPoint(client, ent, dmg, dmg_type, dmg_radius)
{
	if (!IsValidPlayer(client)) return;
	if (!IsValidEdict(ent)) return;

	float pos[3];
	char  StrDamage[16];
	char  StrDamageType[16];
	char  StrDamageRadius[16];
	char  strDamageTarget[16];

	Format(StrDamageType, sizeof(StrDamage), "%i", dmg);
	Format(StrDamageType, sizeof(StrDamageType), "%i", dmg_type);
	Format(StrDamageRadius, sizeof(StrDamageRadius), "%i", dmg_radius);
	Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", ent);

	// GetClientAbsOrigin(client, pos);
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	pos[2] += 1.0;

	new pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(ent, "targetname", strDamageTarget);
	DispatchKeyValue(pointHurt, "DamageTarget", strDamageTarget);
	DispatchKeyValue(pointHurt, "Damage", StrDamage);
	DispatchKeyValue(pointHurt, "DamageRadius", StrDamageRadius);
	DispatchKeyValue(pointHurt, "DamageType", StrDamageType);
	// DispatchKeyValue(pointHurt, "DamageDelay", "1.0");
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(pointHurt, "Hurt", (client > 0 && client < MaxClients && IsClientInGame(client)) ? client : -1);

	// PrintToChat(client, "point_hurtDamage %s, DamageType %s, DamageRadius %s, TargetName %s  successfully created", StrDamage, StrDamageType, StrDamageRadius, strDamageTarget);

	DispatchKeyValue(pointHurt, "classname", "point_hurt");
	DispatchKeyValue(ent, "targetname", "null");
	AcceptEntityInput(pointHurt, "Kill");
}

public IsValidPlayer(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	if (!IsClientConnected(client)) return false;

	return true;
}

public IsNormalPlayer(client)
{
	if (client <= 0)
		return false;

	if (client > MaxClients)
		return false;

	if (!IsClientConnected(client))
		return false;

	if (!IsClientInGame(client))
		return false;

	return true;
}

static void AttachParticle(target, char[] particlename, float time, float origin)
{
	PrintToChatAll("1Particle %s attached to entity %d", particlename, target);
	if (target > 0 && IsValidEntity(target))
	{
		PrintToChatAll("2Particle %s attached to entity %d", particlename, target);
		new particle = CreateEntityByName("info_particle_system");
		if (IsValidEntity(particle))
		{
			PrintToChatAll("3Particle %s attached to entity %d", particlename, target);
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
			CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

static void DeleteParticles(Handle
								timer,
							any
								particle)
{
	if (IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
			AcceptEntityInput(particle, "Kill");
	}
}
stock bool IsPlayerGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	return false;
}
stock EmitYell(client)
{
	char model[256];
	GetClientModel(client, model, sizeof(model));

	if (!IsValidPlayer(client)) return;

	if (GetClientTeam(client) == 2)
	{
		switch (GetRandomInt(1, 3))
		{
			case 1:
				EmitSoundToAll(YELLNICK_1, client);
			case 2:
				EmitSoundToAll(YELLNICK_2, client);
			case 3:
				EmitSoundToAll(YELLNICK_3, client);
		}
	}
}
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
