#if defined _st_tank_jockey_included
 #endinput
#endif
#define _st_tank_jockey_included

// ============================================================================
// JOCKEY TANK MODULE
// Jockey Tank abilities and mechanics
// Color: RGB(255, 200, 0) = 2552000
// ============================================================================

/**
 * Jockey Tank rock throw - Spawns Jockey instead of rock
 * Called from RockThrowTimer when rock reaches throwing velocity
 *
 * @param client    Jockey Tank client index
 * @return          Plugin_Continue or Plugin_Stop
 */
public Action:JockeyThrow(Handle:timer, any:client)
{
	new Float:velocity[3];
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity);
		if (v > 500.0)
		{
			if (CountTotal() < 29)
			{
				new bot = CreateFakeClient("Jockey");
				if (bot > 0)
				{
					SpawnInfected(bot, 5, true);
					new Float:Pos[3];
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);
					AcceptEntityInput(entity, "Kill");
					NormalizeVector(velocity, velocity);
					new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
					ScaleVector(velocity, speed*1.4);
					TeleportEntity(bot, Pos, NULL_VECTOR, velocity);
				}
				return Plugin_Stop;
			}
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
