#if defined _st_events_included
 #endinput
#endif
#define _st_events_included

// ============================================================================
// EVENT SYSTEM
// Handles all game events for SuperTanks
// ============================================================================

/**
 * Register all SuperTanks events
 * Should be called from OnPluginStart
 *
 * @noreturn
 */
stock RegisterSuperTanksEvents()
{
	HookEvent("ability_use", ST_Event_Ability_Use);
	HookEvent("difficulty_changed", ST_Event_Difficulty_Changed);
	HookEvent("finale_escape_start", ST_Event_Finale_Escape_Start);
	HookEvent("finale_start", ST_Event_Finale_Start, EventHookMode_Pre);
	HookEvent("finale_vehicle_leaving", ST_Event_Finale_Vehicle_Leaving);
	HookEvent("finale_vehicle_ready", ST_Event_Finale_Vehicle_Ready);
	HookEvent("gauntlet_finale_start", ST_Event_Finale_Start);
	HookEvent("player_death", ST_Event_Player_Death);
	HookEvent("player_now_it", ST_Event_Player_Now_It);
	HookEvent("player_spawn", ST_Event_Player_Spawn);
	HookEvent("player_use", ST_Event_Player_Use);
	HookEvent("round_end", ST_Event_Round_End);
	HookEvent("round_start", ST_Event_Round_Start);
}

/**
 * Event: Ability Use
 * Called when a tank uses an ability (rock throw, etc)
 */
public Action:ST_Event_Ability_Use(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (bSuperTanksEnabled)
	{
		if (IsTank(client))
		{
			new index = GetSuperTankByRenderColor(GetEntRenderColor(client));
			if (index >= 0 && index <= 16)
			{
				if (index != 0 || (index == 0 && bDefaultOverride))
				{
					ResetInfectedAbility(client, flTankThrow[index]);
				}
			}
		}
	}
	return Plugin_Continue;
}

/**
 * Event: Difficulty Changed
 * Called when game difficulty changes
 */
public Action:ST_Event_Difficulty_Changed(Handle:event, String:event_name[], bool:dontBroadcast)
{
	SetGameDifficulty();
	CreateTimer(0.1, AutoDiffTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

/**
 * Event: Finale Escape Start
 * Called when finale escape sequence starts
 */
public Action:ST_Event_Finale_Escape_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iFinaleStage = 3;
	return Plugin_Continue;
}

/**
 * Event: Finale Start
 * Called when finale starts
 */
public Action:ST_Event_Finale_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iFinaleStage = 1;
	return Plugin_Continue;
}

/**
 * Event: Finale Vehicle Leaving
 * Called when finale vehicle is leaving
 */
public Action:ST_Event_Finale_Vehicle_Leaving(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iFinaleStage = 4;
	return Plugin_Continue;
}

/**
 * Event: Finale Vehicle Ready
 * Called when finale vehicle is ready
 */
public Action:ST_Event_Finale_Vehicle_Ready(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iFinaleStage = 3;
	if (bSuperTanksEnabled)
	{
		SetConVarInt(hNightmareBegin, 1);
	}
	return Plugin_Continue;
}

/**
 * Event: Player Death
 * Called when a player dies
 */
public Action:ST_Event_Player_Death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weaponused[16];
	GetEventString(event, "weapon", weaponused, sizeof(weaponused));
	if (bSuperTanksEnabled)
	{
		if (client > 0)
		{
			if (IsClientInGame(client))
			{
				if (GetClientTeam(client) == 2)
				{
					SetEntityMoveType(client, MOVETYPE_OBSERVER);
					new entity = -1;
					while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != INVALID_ENT_REFERENCE)
					{
						new Float:Origin[3], Float:EOrigin[3];
						GetClientAbsOrigin(client, Origin);
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", EOrigin);
						if (Origin[0] == EOrigin[0] && Origin[1] == EOrigin[1] && Origin[2] == EOrigin[2])
						{
							SetEntProp(entity, Prop_Send, "m_hOwnerEntity", client);
						}
					}
				}
				else if (GetClientTeam(client) == 3)
				{
					if (IsTank(client))
					{
						// Eclipse Integration: Otorgar recompensas antes de limpiar el tank
						#if defined ECLIPSE_INTEGRATION
						new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
						if (attacker > 0 && GetClientTeam(attacker) == 2)
						{
							SuperTanksEclipse_OnSuperTankKilled(client, attacker);
						}
						#endif

						ExecTankDeath(client);
					}
				}
				SetEntityGravity(client, 1.0);
				SetEntProp(client, Prop_Send, "m_iGlowType", 0);
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
			}
		}
	}
	return Plugin_Continue;
}

/**
 * Event: Player Now It
 * Called when a player is vomited on
 */
public Action:ST_Event_Player_Now_It(Handle:event, const String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (bSuperTanksEnabled)
	{
		if (attacker > 0 && client > 0)
		{
			if (IsTank(client) && GetEntRenderColor(client) == 100255200)
			{
				//disable healing ability for 20 secs
				TankAbilityTimer[client] = 20;
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
				SetEntProp(client, Prop_Send, "m_iGlowType", 0);
				SetEntProp(client, Prop_Send, "m_bFlashing", 0);
			}
		}
	}
	return Plugin_Continue;
}

/**
 * Event: Player Spawn
 * Called when a player spawns
 */
public Action:ST_Event_Player_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (bSuperTanksEnabled)
	{
		if (client > 0)
		{
			if (IsClientInGame(client))
			{
				SetEntityGravity(client, 1.0);

				if (GetClientTeam(client) == 3)
				{
					decl String:classname[16];
					GetEntityNetClass(client, classname, sizeof(classname));
					if (StrEqual(classname, "Tank", false))
					{
						CountTanks();

						TankAlive[client] = 1;
						TankAbility[client] = 0;
						CreateTimer(0.1, TankSpawnTimer, client, TIMER_FLAG_NO_MAPCHANGE);

						if (bNightmare || !bFinaleOnly || (bFinaleOnly && iFinaleStage > 0))
						{
							RandomizeTank(client);
							switch(iFinaleStage)
							{
								case 1:
								{
									if (iNumTanks < iWave1Cvar)
									{
										CreateTimer(5.0, SpawnTankTimer, _, TIMER_FLAG_NO_MAPCHANGE);
									}
									else if (bNightmare && iNumTanks > 6)
									{
										if (IsFakeClient(client))
										{
											KickClient(client);
										}
									}
									else if (iNumTanks > iWave1Cvar)
									{
										if (IsFakeClient(client))
										{
											KickClient(client);
										}
									}
								}
								case 2:
								{
									if (iNumTanks < iWave2Cvar)
									{
										CreateTimer(5.0, SpawnTankTimer, _, TIMER_FLAG_NO_MAPCHANGE);
									}
									else if (bNightmare && iNumTanks > 6)
									{
										if (IsFakeClient(client))
										{
											KickClient(client);
										}
									}
									else if (iNumTanks > iWave2Cvar)
									{
										if (IsFakeClient(client))
										{
											KickClient(client);
										}
									}
								}
								case 3:
								{
									if (iNumTanks < iWave3Cvar)
									{
										CreateTimer(5.0, SpawnTankTimer, _, TIMER_FLAG_NO_MAPCHANGE);
									}
									else if (bNightmare && iNumTanks > 6)
									{
										if (IsFakeClient(client))
										{
											KickClient(client);
										}
									}
									else if (iNumTanks > iWave3Cvar)
									{
										if (IsFakeClient(client))
										{
											KickClient(client);
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

/**
 * Event: Player Use
 * Called when a player uses an entity
 */
public Action:ST_Event_Player_Use(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new entity = GetEventInt(event, "targetid");
	if (bSuperTanksEnabled)
	{
		if (entity == iSRDoor)
		{
			if (!bIsFinale && !bNightmare && iNightmareBegin == 0)
			{
				SetConVarInt(hNightmareBegin, 1);
			}
		}
	}
	return Plugin_Continue;
}

/**
 * Event: Round End
 * Called when round ends
 */
public Action:ST_Event_Round_End(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (bSuperTanksEnabled)
	{
		KickAIBots();
	}
	return Plugin_Continue;
}

/**
 * Event: Round Start
 * Called when round starts
 */
public Action:ST_Event_Round_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iRound++;
	SetGameDifficulty();
	ResetVariables();
	ReturnChapterData();
	IdentifySRDoor();

	if (bSuperTanksEnabled)
	{
		CloseSRDoor();
	}

	SetConVarInt(hNightmareBegin, 0);
	SetConVarBool(hNightmare, false);

	ResetClientArraysAll();
	AutoDifficulty(true);
	return Plugin_Continue;
}

/**
 * Entity Created callback
 * Called when entities are created
 */
public OnEntityCreated(entity, const String:classname[])
{
	if (bSuperTanksEnabled)
	{
		if (StrEqual(classname, "tank_rock", false))
		{
			CreateTimer(0.1, RockThrowTimer, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if (StrEqual(classname, "witch", false))
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnEntityTakeDamage);
		}
	}
}

/**
 * Entity Destroyed callback
 * Called when entities are destroyed
 */
public OnEntityDestroyed(entity)
{
	if (!IsServerProcessing()) return;

	if (bSuperTanksEnabled)
	{
		// Validate entity more strictly to prevent Invalid edict errors
		if (entity > 0 && IsValidEdict(entity) && IsValidEntity(entity))
		{
			decl String:classname[64];
			GetEdictClassname(entity, classname, sizeof(classname));

			if (StrEqual(classname, "prop_physics", false))
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (Rock[i] == entity)
					{
						Rock[i] = 0;
					}
				}
			}
		}
	}
}
