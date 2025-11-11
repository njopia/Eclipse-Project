#if defined _st_effects_included
	#endinput
#endif
#define _st_effects_included
#include <sdktools>
Handle hFadeClient = INVALID_HANDLE;
Handle msg		   = INVALID_HANDLE;
// ============================================================================
// EFFECTS SYSTEM
// Visual effects, particles, screen effects
// ============================================================================

/**
 * Create a particle effect at a target entity's location
 *
 * @param target        Target entity
 * @param ParticleName  Particle system name
 * @param time          Duration in seconds
 * @param origin        Z-axis offset from entity origin
 * @noreturn
 */
stock  CreateParticle(int target, char[] ParticleName, float time, float origin)
{
	if (target > 0 && IsValidEntity(target))
	{
		int particle = CreateEntityByName("info_particle_system");
		if (IsValidEntity(particle))
		{
			char  text[28];
			float pos[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
			pos[2] += origin;
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(particle, "effect_name", ParticleName);
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			Format(text, sizeof(text), "OnUser1 !self:Kill::%f:-1", time);
			SetVariantString(text);
			AcceptEntityInput(particle, "AddOutput");
			AcceptEntityInput(particle, "FireUser1");
		}
	}
}

/**
 * Attach a particle effect to a target entity
 *
 * @param target        Target entity
 * @param ParticleName  Particle system name
 * @param time          Duration in seconds
 * @param x             X-axis offset from entity origin
 * @param y             Y-axis offset from entity origin
 * @param z             Z-axis offset from entity origin
 * @noreturn
 */
stock AttachParticle(int target, const char[] ParticleName, float time, float x, float y, float z)
{
	if (target > 0 && IsValidEntity(target))
	{
		int particle = CreateEntityByName("info_particle_system");
		if (IsValidEntity(particle))
		{
			char  text[28];
			float Origin[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", Origin);
			Origin[0] += x;
			Origin[1] += y;
			Origin[2] += z;
			TeleportEntity(particle, Origin, NULL_VECTOR, NULL_VECTOR);

			DispatchKeyValue(particle, "effect_name", ParticleName);
			DispatchSpawn(particle);
			ActivateEntity(particle);
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", target);
			AcceptEntityInput(particle, "Enable");
			AcceptEntityInput(particle, "start");
			Format(text, sizeof(text), "OnUser1 !self:Kill::%f:-1", time);
			SetVariantString(text);
			AcceptEntityInput(particle, "AddOutput");
			AcceptEntityInput(particle, "FireUser1");
		}
	}
}

/**
 * Attach a particle effect at a specific location
 *
 * @param Origin        3D position vector
 * @param ParticleName  Particle system name
 * @param time          Duration in seconds
 * @noreturn
 */
stock AttachParticleLoc(float Origin[3], const char[] ParticleName, float time)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		TeleportEntity(particle, Origin, NULL_VECTOR, NULL_VECTOR);
		char text[28];
		DispatchKeyValue(particle, "effect_name", ParticleName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Enable");
		AcceptEntityInput(particle, "start");
		Format(text, sizeof(text), "OnUser1 !self:Kill::%f:-1", time);
		SetVariantString(text);
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
	}
}

/**
 * Display a particle effect at a position and angle
 *
 * @param ParticleName  Particle system name
 * @param vPos          Position vector
 * @param vAng          Angle vector
 * @return              Entity index of particle, or 0 if failed
 */
stock DisplayParticle(const char[] ParticleName, const float vPos[3], const float vAng[3])
{
	int entity = CreateEntityByName("info_particle_system");
	if (entity > 32 && IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "effect_name", ParticleName);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		return entity;
	}
	return 0;
}

/**
 * Perform a screen fade effect on a client
 *
 * @param client    Client index
 * @param duration  Fade duration
 * @param unknown   Unknown parameter
 * @param type1     Fade type 1 (1=IN, 2=OUT, 4=MODULATE, 8=STAYOUT, 10=PURGE)
 * @param type2     Fade type 2 (same values)
 * @param Color     RGBA color array
 * @noreturn
 */
public PerformFade(int client,int duration,int unknown, type1, type2, const Color[4])
{
	switch (type1)
	{
		case 1: type1 = FFADE_IN;
		case 2: type1 = FFADE_OUT;
		case 4: type1 = FFADE_MODULATE;
		case 8: type1 = FFADE_STAYOUT;
		case 10: type1 = FFADE_PURGE;
	}
	switch (type2)
	{
		case 1: type2 = FFADE_IN;
		case 2: type2 = FFADE_OUT;
		case 4: type2 = FFADE_MODULATE;
		case 8: type2 = FFADE_STAYOUT;
		case 10: type2 = FFADE_PURGE;
	}
	hFadeClient = StartMessageOne("Fade", client);
	BfWriteShort(hFadeClient, duration);
	BfWriteShort(hFadeClient, unknown);
	BfWriteShort(hFadeClient, (type1 | type2));
	BfWriteByte(hFadeClient, Color[0]);
	BfWriteByte(hFadeClient, Color[1]);
	BfWriteByte(hFadeClient, Color[2]);
	BfWriteByte(hFadeClient, Color[3]);
	EndMessage();
}

/**
 * Perform a screen shake effect on a client
 *
 * @param target      Client index
 * @param intensity   Shake intensity (0.0 - x.x)
 * @noreturn
 */
public ScreenShake(int target, float intensity)
{
	msg = StartMessageOne("Shake", target);

	BfWriteByte(msg, 0);
	BfWriteFloat(msg, intensity);
	BfWriteFloat(msg, 10.0);
	BfWriteFloat(msg, 3.0);
	EndMessage();
}
