#if defined _st_tank_ice_included
 #endinput
#endif
#define _st_tank_ice_included

// ============================================================================
// ICE TANK MODULE
// Ice Tank abilities and mechanics
// Color: RGB(0, 100, 170) = 0100170
// ============================================================================

/**
 * Ice Tank claw skill
 * Freezes the target on claw hit
 *
 * @param target     Survivor client index
 * @param client     Ice Tank client index (attacker)
 * @noreturn
 */
public SkillIceClaw(target, client)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			DealDamagePlayer(target, client, 128, GetRandomInt(2,6), "point_hurt");
			SetEntityRenderMode(target, RenderMode:3);
			SetEntityRenderColor(target, 0, 100, 170, 180);
			SetEntityMoveType(target, MOVETYPE_VPHYSICS);
			CreateTimer(5.0, Timer_UnFreeze, target, TIMER_FLAG_NO_MAPCHANGE);
			EmitSoundToAll("ambient/ambience/rainscapes/rain/debris_05.wav", target);
			PerformFade(target, 500, 250, 10, 1, {0, 50, 100, 150});
		}
	}
}

/**
 * Ice Tank passive ability
 * Freezes all survivors within 300 units when 3+ are nearby
 *
 * @param client    Ice Tank client index
 * @noreturn
 */
stock IceTankAbility(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 0100170)
	{
		new count = CountSurvInRange(client, 300);

		SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);

		if (count >= 3)
		{
			new random = GetRandomInt(1,6);
			if (random == 1)
			{
				new glowcolor = RGB_TO_INT(30, 130, 230);
				SetEntProp(client, Prop_Send, "m_glowColorOverride", glowcolor);
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				for (new j=1; j<=MaxClients; j++)
				{
					if (SurvInRange(client, j, 300))
					{
						SkillIceClaw(j, client);
					}
				}
			}
		}
	}
}

/**
 * Timer callback: Unfreeze a frozen survivor
 *
 * @param timer     Timer handle
 * @param client    Frozen survivor client index
 * @return          Plugin_Stop
 */
public Action:Timer_UnFreeze(Handle:timer, any:client)
{
	if (client > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			SetEntityRenderMode(client, RenderMode:3);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
	return Plugin_Stop;
}
