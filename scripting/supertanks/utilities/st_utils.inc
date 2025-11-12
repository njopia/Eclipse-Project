#if defined _st_utils_included
 #endinput
#endif
#define _st_utils_included

// ============================================================================
// UTILITIES MODULE
// Common utility functions used throughout the plugin
// ============================================================================

// ============================================================================
// ECLIPSE INTEGRATION - Usar funciones de helpers cuando ECLIPSE_INTEGRATION está definido
// ============================================================================
#if defined ECLIPSE_INTEGRATION && !defined ST_SKIP_COMMON_FUNCTIONS
	// Las funciones comunes ya están definidas en helpers/entities.helpers.sp
	// No redefinir aquí para evitar conflictos
	#define ST_SKIP_COMMON_FUNCTIONS
#endif

// ============================================================================
// CLIENT VALIDATION FUNCTIONS
// ============================================================================

#if !defined ST_SKIP_COMMON_FUNCTIONS

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

#endif // !ST_SKIP_COMMON_FUNCTIONS

/**
 * Check if a client is a special infected (not tank)
 * NOTE: SuperTanks always needs this function, so keep it outside guards
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
#if !defined ST_SKIP_COMMON_FUNCTIONS
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
	if (entity > 32 && IsValidEdict(entity) && IsValidEntity(entity))
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
	if (entity > 32 && IsValidEdict(entity) && IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "witch", false))
			return true;
		return false;
	}
	return false;
}
#endif

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

#if !defined ST_SKIP_COMMON_FUNCTIONS
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
#endif

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

#if !defined ST_SKIP_COMMON_FUNCTIONS
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
#endif

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

#if !defined ST_SKIP_COMMON_FUNCTIONS
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
#endif

// ============================================================================
// CHEAT COMMAND EXECUTION
// ============================================================================

#if !defined ST_SKIP_COMMON_FUNCTIONS
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
#endif

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
// RANDOM SELECTION FUNCTIONS
// ============================================================================

/**
 * Pick a random alive survivor
 *
 * @return    Random survivor client index, or 0 if none found
 */
stock Pick()
{
	new count, clients[MaxClients];
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			clients[count++] = i;
	}
	if (count == 0) return 0;
	return clients[GetRandomInt(0, count-1)];
}

// ============================================================================
// RAY TRACING FUNCTIONS
// ============================================================================

/**
 * Get the distance from entity to ground
 *
 * @param i_Ent    Entity index
 * @return         Distance to ground in units, 0.0 if on ground
 */
public Float:OnGroundUnits(i_Ent)
{
	if (!(GetEntityFlags(i_Ent) & (FL_ONGROUND)))
	{
		decl Handle:h_Trace, Float:f_Origin[3], Float:f_Position[3], Float:f_Down[3] = { 90.0, 0.0, 0.0 };
		GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin);
		h_Trace = TR_TraceRayFilterEx(f_Origin, f_Down, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceRayDontHitSelfAndLive, i_Ent);
		if (TR_DidHit(h_Trace))
		{
			decl Float:f_Units;
			TR_GetEndPosition(f_Position, h_Trace);
			f_Units = f_Origin[2] - f_Position[2];
			CloseHandle(h_Trace);
			return f_Units;
		}
		CloseHandle(h_Trace);
	}

	return 0.0;
}

/**
 * Get ray hit position from a trace
 *
 * @param pos         Starting position
 * @param angle       Ray angle
 * @param hitpos      Output: Hit position
 * @param ent         Entity to ignore (0 = none)
 * @param useoffset   Whether to offset result by 15 units
 * @return            Entity index hit, or 0
 */
stock GetRayHitPos(Float:pos[3], Float:angle[3], Float:hitpos[3], ent=0, bool:useoffset=false)
{
	new Handle:trace;
	new hit=0;

	trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndLive, ent);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		hit=TR_GetEntityIndex(trace);
	}
	CloseHandle(trace);

	if (useoffset)
	{
		decl Float:v[3];
		MakeVectorFromPoints(hitpos, pos, v);
		NormalizeVector(v, v);
		ScaleVector(v, 15.0);
		AddVectors(hitpos, v, hitpos);
	}
	return hit;
}

/**
 * Trace ray filter - don't hit self or living players
 *
 * @param entity    Entity being tested
 * @param mask      Contents mask
 * @param data      Data (entity to exclude)
 * @return          True to hit, false to ignore
 */
public bool:TraceRayDontHitSelfAndLive(entity, mask, any:data)
{
	if (entity == data)
	{
		return false;
	}
	else if (entity > 0 && entity <= MaxClients)
	{
		if (IsClientInGame(entity))
		{
			return false;
		}
	}
	return true;
}

// ============================================================================
// SAFEROOM DOOR SYSTEM
// ============================================================================

/**
 * Identify and store the saferoom door entity
 * Should be called on round start
 *
 * @noreturn
 */
stock IdentifySRDoor()
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) != INVALID_ENT_REFERENCE)
	{
		if (GetEntProp(entity, Prop_Data, "m_hasUnlockSequence") == 0)
		{
			iSRDoor = entity;
		}
	}
}

/**
 * Close the saferoom door
 * Used to prevent early door opening
 *
 * @noreturn
 */
stock CloseSRDoor()
{
	new entity = iSRDoor;
	if (entity > 0 && IsValidEntity(entity))
	{
		if (GetEntProp(entity, Prop_Data, "m_hasUnlockSequence") == 0)
		{
			if (GetEntProp(entity, Prop_Data, "m_eDoorState") == 2)
			{
				AcceptEntityInput(entity, "Close");
			}
		}
	}
}

/**
 * Check if current map is a finale map
 * Updates bIsFinale global variable
 *
 * @noreturn
 */
stock ReturnChapterData()
{
	bIsFinale = (L4D_IsMissionFinalMap() == true);
}

/**
 * Wrapper for L4D IsMissionFinalMap
 * @return    True if finale map, false otherwise
 */
stock bool:IsMissionFinalMap()
{
	return L4D_IsMissionFinalMap();
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
// BOT MANAGEMENT FUNCTIONS
// ============================================================================

/**
 * Kick excess AI bots (special infected)
 * Used to prevent bot buildup
 *
 * @noreturn
 */
stock KickAIBots()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsSpecialInfected(i) && IsFakeClient(i))
		{
			if (CountInfectedAll() > 16)
			{
				KickClient(i);
			}
		}
	}
}

/**
 * Count all infected players
 * @return    Number of infected team players
 */
stock CountInfectedAll()
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			count++;
		}
	}
	return count;
}

// ============================================================================
// RESET FUNCTIONS
// ============================================================================

/**
 * Reset all SuperTanks global variables
 * Called on round start
 *
 * @noreturn
 */
stock ResetVariables()
{
	iCountDownTimer = 0;
	iSpawnBotTick = 0;
	iFinaleStage = 0;
	iCCEnt = 0;
	iFogVolEnt = 0;
	iSRDoor = 0;
}

/**
 * Reset SuperTanks arrays for a specific client
 *
 * @param client    Client index
 * @noreturn
 */
stock ResetClientArrays(client)
{
	GravityClaw[client] = 0;
	PlayerSpeed[client] = 0;
	ShieldsUp[client] = 0;
	TankAbility[client] = 0;
	TankAlive[client] = 0;
	TankAbilityTimer[client] = 0;
}

/**
 * Reset SuperTanks arrays for all clients
 * Called on round start
 *
 * @noreturn
 */
stock ResetClientArraysAll()
{
	for (new client=1; client<=MaxClients; client++)
	{
		GravityClaw[client] = 0;
		PlayerSpeed[client] = 0;
		ShieldsUp[client] = 0;
		TankAbility[client] = 0;
		TankAlive[client] = 0;
		TankAbilityTimer[client] = 0;
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
