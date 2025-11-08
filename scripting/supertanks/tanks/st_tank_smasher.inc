#if defined _st_tank_smasher_included
 #endinput
#endif
#define _st_tank_smasher_included

// ============================================================================
// SMASHER TANK MODULE
// Smasher Tank abilities and mechanics
// Color: RGB(70, 80, 100) = 7080100
// ============================================================================

/**
 * Smasher Tank claw skill - Maim attack
 * Reduces survivor health drastically but doesn't kill
 *
 * @param target    Survivor client index
 * @noreturn
 */
public SkillSmashClaw(target)
{
	new health = GetEntProp(target, Prop_Data, "m_iHealth");
	if (health > 1 && !IsPlayerIncap(target))
	{
		new Float:time = GetGameTime();
		SetEntProp(target, Prop_Data, "m_iHealth", iSmasherMaimDamage);
		new Float:hbuffer = float(health) - float(iSmasherMaimDamage);
		if (hbuffer > 0.0)
		{
			SetEntPropFloat(target, Prop_Send, "m_healthBuffer", hbuffer);
		}
		SetEntPropFloat(target, Prop_Send, "m_healthBufferTime", time);
	}
	EmitSoundToAll("player/charger/hit/charger_smash_02.wav", target);
	PerformFade(target, 800, 300, 10, 1, {10, 0, 0, 250});
	ScreenShake(target, 30.0);
}

/**
 * Smasher Tank claw skill - Instant kill attack
 * Kills the survivor with explosion effects
 *
 * @param client     Survivor client index (victim)
 * @param attacker   Smasher Tank client index
 * @noreturn
 */
public SkillSmashClawKill(client, attacker)
{
	EmitSoundToAll("player/tank/voice/growl/tank_climb_01.wav", attacker);
	AttachParticle(client, PARTICLE_EXPLODE, 0.1, 0.0, 0.0, 0.0);
	new random = GetRandomInt(1,3);
	switch(random)
	{
		case 1: EmitSoundToAll("player/boomer/explode/explo_medium_09.wav", client);
		case 2: EmitSoundToAll("player/boomer/explode/explo_medium_10.wav", client);
		case 3: EmitSoundToAll("player/boomer/explode/explo_medium_14.wav", client);
	}
	if (IsTank(client) && GetEntRenderColor(client) == 7080100)
	{
		DealDamagePlayer(client, attacker, 128, iSmasherCrushDamage, "point_hurt");
		DealDamagePlayer(client, attacker, 128, iSmasherCrushDamage, "point_hurt");
		CreateTimer(0.1, RemoveDeathBody, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		DealDamagePlayer(client, attacker, 128, 999, "point_hurt");
		DealDamagePlayer(client, attacker, 128, 999, "point_hurt");
	}
}

/**
 * Timer callback: Remove death body model
 *
 * @param timer     Timer handle
 * @param client    Client index
 * @return          Plugin_Stop
 */
public Action:RemoveDeathBody(Handle:timer, any:client)
{
	if (bSmasherRemoveBody)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				new entity = -1;
				while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != INVALID_ENT_REFERENCE)
				{
					new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
					if (client == owner)
					{
						AcceptEntityInput(entity, "Kill");
					}
				}
			}
		}
	}
	return Plugin_Stop;
}
