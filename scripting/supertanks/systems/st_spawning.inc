#if defined _st_spawning_included
 #endinput
#endif
#define _st_spawning_included

// ============================================================================
// SPAWNING SYSTEM
// Infected bot spawning, special infected management
// ============================================================================

/**
 * Interval-based infected spawning logic
 * Called every second by main timer
 * @noreturn
 */
stock SpawnInfectedInterval()
{
	iSpawnBotTick += 1;
	new spawninterval = GetRandomInt(iSpecialMin,iSpecialMax);
	if (iSpawnBotTick >= spawninterval)
	{
		if (CountSI() < iSpecialAmount)
		{
			SpawnInfectedBot();
		}
		iSpawnBotTick = 0;
	}
}

/**
 * Spawn a random special infected bot
 * @noreturn
 */
stock SpawnInfectedBot()
{
	if (CountTotal() < 29)
	{
		new bot = CreateFakeClient("Smoker");
		if (bot > 0)
		{
			new random = GetRandomInt(1,6);
			SpawnInfected(bot, random, true);
		}
	}
}

/**
 * Spawn a specific class of infected for a client
 *
 * @param client   Client index
 * @param class    Infected class (1=smoker, 2=boomer, 3=hunter, 4=spitter, 5=jockey, 6=charger, 8=tank)
 * @param bAuto    Auto-spawn (true) or manual spawn (false)
 * @return         True if spawned successfully, false otherwise
 */
stock SpawnInfected(client, class, bool:bAuto)
{
	new bool:resetGhostState[MaxClients+1];
	new bool:resetIsAlive[MaxClients+1];
	new bool:resetLifeState[MaxClients+1];
	ChangeClientTeam(client, 3);
	new String:classname[16];
	new String:options[32];
	switch(class)
	{
		case 1: classname = "smoker";
		case 2: classname = "boomer";
		case 3: classname = "hunter";
		case 4: classname = "spitter";
		case 5: classname = "jockey";
		case 6: classname = "charger";
		case 8: classname = "tank";
	}
	if (class == 7 || (class < 1 || class > 8)) return false;
	if (GetClientTeam(client) != 3) return false;
	if (!IsClientInGame(client)) return false;
	if (IsPlayerAlive(client)) return false;

	for (new i=1; i<=MaxClients; i++)
	{
		if (i == client) continue; //dont disable the chosen one
		if (!IsClientInGame(i)) continue; //not ingame? skip
		if (GetClientTeam(i) != 3) continue; //not infected? skip
		if (IsFakeClient(i)) continue; //a bot? skip

		if (IsPlayerGhost(i))
		{
			resetGhostState[i] = true;
			SetPlayerGhostStatus(i, false);
			resetIsAlive[i] = true;
			SetPlayerIsAlive(i, true);
		}
		else if (!IsPlayerAlive(i))
		{
			resetLifeState[i] = true;
			SetPlayerLifeState(i, false);
		}
	}
	if (bAuto)
	{
		Format(options, sizeof(options), "%s auto", classname);
		CheatCommand(client, "z_spawn_old", options);
	}
	else
	{
		decl Float:Origin[3], Float:Angles[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
		ForceSpawnInfected(classname, Origin, Angles);
	}
	if (IsFakeClient(client)) KickClient(client);
	for (new i=1; i<=MaxClients; i++)
	{
		if (resetGhostState[i]) SetPlayerGhostStatus(i, true);
		if (resetIsAlive[i]) SetPlayerIsAlive(i, false);
		if (resetLifeState[i]) SetPlayerLifeState(i, true);
	}
	return true;
}

/**
 * Force spawn an infected at a specific location
 *
 * @param classname  Infected class name
 * @param Origin     Spawn position
 * @param Angles     Spawn angles
 * @noreturn
 */
stock ForceSpawnInfected(String:classname[], Float:Origin[3], Float:Angles[3])
{
	new entity = CreateEntityByName("info_zombie_spawn");
	if (entity > 0 && IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "population", classname);
		DispatchKeyValueVector(entity, "origin", Origin);
		DispatchKeyValueVector(entity, "angles", Angles);
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "SpawnZombie");
		AcceptEntityInput(entity, "Kill");
	}
}

/**
 * Count total players/bots in the server
 *
 * @return  Total count
 */
stock CountTotal()
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			count++;
		}
	}
	return count;
}

/**
 * Helper functions for player state manipulation
 * These wrap netprop access for ghost/alive/life states
 */
stock bool:IsPlayerGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1))
		return true;
	return false;
}

stock SetPlayerGhostStatus(client, bool:bIsGhost)
{
	SetEntProp(client, Prop_Send, "m_isGhost", bIsGhost ? 1 : 0);
}

stock SetPlayerIsAlive(client, bool:bIsAlive)
{
	SetEntProp(client, Prop_Send, "m_isAlive", bIsAlive ? 1 : 0);
}

stock SetPlayerLifeState(client, bool:bDead)
{
	SetEntProp(client, Prop_Send, "m_lifeState", bDead ? 1 : 0);
}

/**
 * Spawn command wrapper with team change
 * Changes client to infected team and executes spawn command
 *
 * @param client      Client index
 * @param command     Command to execute
 * @param arguments   Command arguments
 * @noreturn
 */
stock SpawnCommand(client, String:command[], String:arguments[] = "")
{
	ChangeClientTeam(client, 3);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags | FCVAR_CHEAT);
	KickClient(client);
}
