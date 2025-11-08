#if defined _st_tank_witch_included
 #endinput
#endif
#define _st_tank_witch_included

// ============================================================================
// WITCH TANK MODULE
// Witch Tank abilities and mechanics
// Color: RGB(255, 200, 255) = 255200255
// ============================================================================

/**
 * Witch Tank passive ability
 * Spawns witches around survivors when they are in range
 *
 * @param client    Witch Tank client index
 * @noreturn
 */
stock WitchTankAbility(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 255200255)
	{
		new random = GetRandomInt(1,3);
		if (random == 1)
		{
			new Float:Origin[3], Float:Angles[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
			GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);

			for (new i=1; i<=MaxClients; i++)
			{
				if (SurvInRange(client, i, 400))
				{
					if (CountWitches() < iWitchMaxWitches)
					{
						new witch = CreateEntityByName("witch");
						DispatchSpawn(witch);
						ActivateEntity(witch);
						TeleportEntity(witch, Origin, Angles, NULL_VECTOR);

						new Handle:Pack = CreateDataPack();
						WritePackCell(Pack, witch);
						WritePackCell(Pack, i);
						CreateTimer(0.1, AngerWitch, Pack, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
}

/**
 * Timer callback to anger a newly spawned witch
 * Makes the witch target a specific survivor
 *
 * @param timer    Timer handle
 * @param Pack     Data pack containing witch entity and target survivor
 * @return         Plugin_Stop
 */
public Action:AngerWitch(Handle:timer, any:Pack)
{
	ResetPack(Pack, false);
	new entity = ReadPackCell(Pack);
	new client = ReadPackCell(Pack);
	CloseHandle(Pack);

	if (IsWitch(entity) && IsSurvivor(client) && IsPlayerAlive(client))
	{
		DealDamageEntity(entity, client, 2, 1, "point_hurt");
		SetEntProp(entity, Prop_Send, "m_hOwnerEntity", 255200255);
	}
}

// CountWitches is defined in utilities/st_utils.inc
