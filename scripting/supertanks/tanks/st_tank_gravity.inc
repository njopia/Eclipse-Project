#if defined _st_tank_gravity_included
 #endinput
#endif
#define _st_tank_gravity_included

// ============================================================================
// GRAVITY TANK MODULE
// Gravity Tank abilities and mechanics
// Color: RGB(33, 34, 35) = 333435
// ============================================================================

/**
 * Gravity Tank claw skill
 * Applies gravity effect to the target
 *
 * @param target    Survivor client index
 * @noreturn
 */
public SkillGravityClaw(target)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			GravityClaw[target] = 1;
			CreateTimer(2.0, Timer_ResetGravity, target, TIMER_FLAG_NO_MAPCHANGE);
			PerformFade(target, 500, 250, 10, 1, {100, 50, 100, 150});
			ScreenShake(target, 5.0);
		}
	}
}

/**
 * Timer callback: Reset gravity effect on survivor
 *
 * @param timer     Timer handle
 * @param client    Survivor client index
 * @return          Plugin_Stop
 */
public Action:Timer_ResetGravity(Handle:timer, any:client)
{
	if (client > 0)
	{
		if (IsClientInGame(client))
		{
			GravityClaw[client] = 0;
		}
	}
	return Plugin_Stop;
}
