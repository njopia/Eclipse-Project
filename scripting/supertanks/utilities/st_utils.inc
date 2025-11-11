#if defined _st_utils_included
 #endinput
#endif
#define _st_utils_included

// ============================================================================
// UTILITIES MODULE
// Common utility functions used throughout the plugin
// ============================================================================

// ============================================================================
// CLIENT VALIDATION FUNCTIONS
// ============================================================================

/**
 * Check if a client index is valid and in game
 *
 * @param client    Client index
 * @return          True if valid, false otherwise
 */
stock bool:IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

/**
 * Check if a client is a survivor
 *
 * @param client    Client index
 * @return          True if survivor, false otherwise
 */
stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

/**
 * Check if a client is a spectator
 *
 * @param client    Client index
 * @return          True if spectator, false otherwise
 */
stock bool:IsSpectator(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1)
	{
		return true;
	}
	return false;
}

/**
 * Check if a client is a special infected (not tank)
 *
 * @param client    Client index
 * @return          True if special infected, false otherwise
 */
stock bool:IsSpecialInfected(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		decl String:classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Smoker", false) || StrEqual(classname, "Boomer", false) || StrEqual(classname, "Hunter", false) || StrEqual(classname, "Spitter", false) || StrEqual(classname, "Jockey", false) || StrEqual(classname, "Charger", false))
		{
			return true;
		}
	}
	return false;
}

/**
 * Check if a client is a tank
 *
 * @param client    Client index
 * @return          True if tank, false otherwise
 */
stock bool:IsTank(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && !IsPlayerIncap(client) && TankAlive[client] == 1)
	{
		decl String:classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Tank", false))
		{
			return true;
		}
	}
	return false;
}

/**
 * Check if an entity is an infected (common infected)
 *
 * @param entity    Entity index
 * @return          True if infected, false otherwise
 */
stock bool:IsInfected(entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "infected", false))
		{
			return true;
		}
	}
	return false;
}

/**
 * Check if an entity is a witch
 *
 * @param entity    Entity index
 * @return          True if witch, false otherwise
 */
stock bool:IsWitch(entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "witch", false))
			return true;
		return false;
	}
	return false;
}

/**
 * Check if a witch entity is angry
 *
 * @param entity    Witch entity index
 * @return          True if angry, false otherwise
 */
stock bool:IsWitchAngry(entity)
{
	if (IsWitch(entity))
	{
		new ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
		if (ragdoll <= 0)
		{
			new Float:rage = GetEntPropFloat(entity, Prop_Send, "m_rage");
			new Float:wanderrage = GetEntPropFloat(entity, Prop_Send, "m_wanderrage");
			if (rage < wanderrage)
			{
				return true;
			}
		}
	}
	return false;
}

// ============================================================================
// COUNTING FUNCTIONS
// ============================================================================

/**
 * Count all living survivors
 *
 * @return    Number of alive survivors
 */
stock CountSurvivorsAliveAll()
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			count++;
		}
	}
	return count;
}

/**
 * Count special infected (SI) players
 *
 * @return    Number of SI players
 */
stock CountSI()
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
		{
			count++;
		}
	}
	return count;
}

/**
 * Count all tanks and update global iNumTanks variable
 *
 * @noreturn
 */
stock CountTanks()
{
	iNumTanks = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsTank(i))
		{
			iNumTanks++;
		}
	}
}

/**
 * Count all witches in the map
 *
 * @return    Number of witches
 */
stock CountWitches()
{
	new count;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
	{
		count++;
	}
	return count;
}

// ============================================================================
// DISTANCE CALCULATION FUNCTIONS
// ============================================================================

/**
 * Get the distance to the nearest survivor from a client (usually tank)
 *
 * @param client    Client index (usually a tank)
 * @return          Distance to nearest survivor, 0.0 if none found
 */
stock Float:GetNearestSurvivorDist(client)
{
	new Float:TankPos[3], Float:SurvPos[3], Float:nearest = 0.0, Float:distance = 0.0;
	if (client > 0)
	{
		if (IsTank(client))
		{
			GetClientAbsOrigin(client, TankPos);
			for (new i=1; i<=MaxClients; i++)
			{
				if (IsSurvivor(i) && IsPlayerAlive(i))
				{
					GetClientAbsOrigin(i, SurvPos);
					distance = GetVectorDistance(TankPos, SurvPos);
					if (nearest == 0.0 || nearest > distance)
					{
						nearest = distance;
					}
				}
			}
		}
	}
	return nearest;
}

/**
 * Get the distance to the nearest survivor from an entity (witch or infected)
 *
 * @param entity    Entity index
 * @return          Distance to nearest survivor, 0.0 if none found or invalid
 */
stock Float:GetNearestSurvivorDistEnt(entity)
{
	new Float:EntityPos[3], Float:TargetPos[3], Float:nearest = 0.0, Float:distance = 0.0;
	if (IsWitch(entity) || IsInfected(entity))
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", EntityPos);
		if (EntityPos[0] == 0.0 && EntityPos[1] == 0.0 && EntityPos[2] == 0.0)
		{
			return 0.0;
		}
		new ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
		if (ragdoll != 0)
		{
			return 0.0;
		}
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsSurvivor(i) && IsPlayerAlive(i))
			{
				GetClientAbsOrigin(i, TargetPos);
				distance = GetVectorDistance(EntityPos, TargetPos);
				if (nearest == 0.0 || nearest > distance)
				{
					nearest = distance;
				}
			}
		}
	}
	return nearest;
}

// ============================================================================
// COLOR UTILITY FUNCTIONS
// ============================================================================

/**
 * Convert RGB values to integer color value
 *
 * @param red      Red component (0-255)
 * @param green    Green component (0-255)
 * @param blue     Blue component (0-255)
 * @return         Integer color value
 */
stock RGB_TO_INT(red, green, blue)
{
	return (blue * 65536) + (green * 256) + red;
}

/**
 * Get entity render color as integer
 *
 * @param client    Client/entity index
 * @return          Integer color value, or 0 if invalid
 */
stock GetEntRenderColor(client)
{
	if (client > 0)
	{
		new offset = GetEntSendPropOffs(client, "m_clrRender");
		new r = GetEntData(client, offset, 1);
		new g = GetEntData(client, offset+1, 1);
		new b = GetEntData(client, offset+2, 1);
		return RGB_TO_INT(r, g, b);
	}
	return 0;
}

/**
 * Get entity glow color as integer
 *
 * @param client    Client/entity index
 * @return          Integer glow color value, or 0 if invalid
 */
stock GetEntGlowColor(client)
{
	if (client > 0)
	{
		new offset = GetEntSendPropOffs(client, "m_glowColorOverride");
		return GetEntData(client, offset);
	}
	return 0;
}

// ============================================================================
// PLAYER SPEED/MOVEMENT FUNCTIONS
// ============================================================================

/**
 * Update a survivor's movement speed based on their state
 * Handles speed reduction from shock tank stun effect
 *
 * @param client    Survivor client index
 * @noreturn
 */
stock UpdateMovementSpeed(client)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		decl Float:value;
		if (PlayerSpeed[client] > 0)
		{
			value = flShockStunMovement;
		}
		else
		{
			value = 1.0;
		}
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", value);
	}
}

// ============================================================================
// PLAYER STATE FUNCTIONS
// ============================================================================

/**
 * Check if a player is incapacitated
 *
 * @param client    Client index
 * @return          True if incapacitated, false otherwise
 */
stock bool:IsPlayerIncap(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		return true;
	return false;
}

/**
 * Check if a player is hanging from a ledge
 *
 * @param client    Client index
 * @return          True if hanging, false otherwise
 */
stock bool:IsPlayerHanging(client)
{
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))
		return true;
	return false;
}

// ============================================================================
// ENTITY UTILITY FUNCTIONS
// ============================================================================

/**
 * Get the entity a client is aiming at
 *
 * @param client    Client index
 * @return          Entity index, or -1 if none
 */
stock ST_GetClientAimTarget(client)
{
	if (client > 0 && IsClientInGame(client))
	{
		new Float:vAngles[3], Float:vOrigin[3];
		GetClientEyePosition(client, vOrigin);
		GetClientEyeAngles(client, vAngles);

		new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, client);

		new entity = -1;
		if (TR_DidHit(trace))
		{
			entity = TR_GetEntityIndex(trace);
		}
		CloseHandle(trace);

		return entity;
	}
	return -1;
}

/**
 * Trace ray filter callback - don't hit the client itself
 *
 * @param entity        Entity being tested
 * @param contentsMask  Contents mask
 * @param client        Client to exclude
 * @return              True to hit entity, false to ignore
 */
public bool:TraceRayDontHitSelf(entity, contentsMask, any:client)
{
	if (entity == client)
	{
		return false;
	}
	return true;
}

// ============================================================================
// RANGE AND COUNTING FUNCTIONS (CONTINUED)
// ============================================================================

/**
 * Check if a specific survivor is within range of a client
 *
 * @param client       Client index (usually a tank)
 * @param target       Target survivor index
 * @param targetDist   Distance threshold
 * @return             True if survivor is within range, false otherwise
 */
stock bool:SurvInRange(client, target, targetDist)
{
	if (IsSurvivor(target) && IsPlayerAlive(target))
	{
		decl Float:TankPos[3], Float:PlayerPos[3];
                GetClientAbsOrigin(client, TankPos);
                GetClientAbsOrigin(target, PlayerPos);
                new Float:distance = GetVectorDistance(TankPos, PlayerPos);
                if (distance <= targetDist)
		{
			return true;
		}
	}
	return false;
}

/**
 * Count survivors that are within range of a client
 *
 * @param client       Client index (usually a tank)
 * @param targetDist   Distance threshold
 * @return             Number of survivors within range
 */
stock CountSurvInRange(client, targetDist)
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i))
		{
			decl Float:TankPos[3], Float:PlayerPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, PlayerPos);
                       	new Float:distance = GetVectorDistance(TankPos, PlayerPos);
                        if (distance <= targetDist)
			{
				count++;
			}
		}
	}
	return count;
}

/**
 * Count survivors that are outside a specific range from a client
 *
 * @param client       Client index (usually a tank)
 * @param targetDist   Distance threshold
 * @return             Number of survivors outside range
 */
stock CountSurvOutRange(client, targetDist)
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i))
		{
			decl Float:TankPos[3], Float:PlayerPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, PlayerPos);
                       	new Float:distance = GetVectorDistance(TankPos, PlayerPos);
                        if (distance > targetDist)
			{
				count++;
			}
		}
	}
	return count;
}

/**
 * Check if a player is on fire
 *
 * @param client    Client index
 * @return          True if burning, false otherwise
 */
stock bool:IsPlayerBurning(client)
{
	if (GetEntityFlags(client) & FL_ONFIRE)
		return true;
	return false;
}

/**
 * Update client timers (reduces timer counters)
 *
 * @param client    Client index
 * @noreturn
 */
stock UpdateTimers(client)
{
	if (IsSurvivor(client) || IsSpectator(client))
	{
		if (PlayerSpeed[client] > 0)
		{
			PlayerSpeed[client] -= 1;
		}
	}
}

// ============================================================================
// CHEAT COMMAND EXECUTION
// ============================================================================

/**
 * Execute a cheat command by temporarily removing sv_cheats flag
 *
 * @param client      Client to execute command for
 * @param command     Command name
 * @param arguments   Command arguments
 * @noreturn
 */
stock CheatCommand(client, const String:command[], const String:arguments[])
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}

// ============================================================================
// EXPLOSION UTILITY FUNCTIONS
// ============================================================================

/**
 * Create propane explosion at location
 *
 * @param client    Client that triggered explosion (for attribution)
 * @param Origin    Explosion location
 * @noreturn
 */
stock PropaneExplode(client, Float:Origin[3])
{
	new propane = CreateEntityByName("prop_physics");
	if (propane > 32 && IsValidEntity(propane))
	{
		DispatchKeyValue(propane, "model", MODEL_PROPANE);
		DispatchSpawn(propane);
		if (IsValidClient(client))
		{
			SetEntPropEnt(propane, Prop_Data, "m_hLastAttacker", client);
		}
		TeleportEntity(propane, Origin, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(propane);
		AcceptEntityInput(propane, "Break");
	}
}

// ============================================================================
// DIFFICULTY SYSTEM FUNCTIONS
// ============================================================================

/**
 * Sets the game difficulty multiplier based on z_difficulty cvar
 * Updates the global iDifficulty variable
 *
 * @noreturn
 */
stock SetGameDifficulty()
{
	decl String:GameDifficulty[16];
	GetConVarString(FindConVar("z_difficulty"), GameDifficulty, sizeof(GameDifficulty));
	if (StrEqual(GameDifficulty, "Easy", false))
	{
		iDifficulty = 1;
	}
	else if (StrEqual(GameDifficulty, "Normal", false))
	{
		iDifficulty = 2;
	}
	else if (StrEqual(GameDifficulty, "Hard", false))
	{
		iDifficulty = 3;
	}
	else if (StrEqual(GameDifficulty, "Impossible", false))
	{
		if (!bNightmare)
		{
			iDifficulty = 4;
		}
	}
}

// ============================================================================
// NOTES
// ============================================================================
/*
This utility module contains the most essential functions.
Additional utility functions from the original file that may need to be added:

- Weapon management functions (ForceWeaponDrop, DropSlot, etc.)
- Additional entity management functions
- Tank color identification (GetSuperTankByRenderColor)
- Client viewing checks (IsClientViewing)
- Additional player state setters/getters

These can be added as needed during further modularization.
*/
