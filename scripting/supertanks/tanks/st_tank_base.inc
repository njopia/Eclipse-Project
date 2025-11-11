#if defined _st_tank_base_included
 #endinput
#endif
#define _st_tank_base_included

// ============================================================================
// TANK BASE SYSTEM
// Core tank functionality - spawning, selection, death
// ============================================================================

/**
 * Randomize tank type and apply render color
 * Called when a tank spawns
 *
 * @param client    Tank client index
 * @noreturn
 */
stock RandomizeTank(client)
{
	if (!bDefaultTanks)
	{
		if (bNightmare)
		{
			//Demon
      	 		SetEntityRenderColor(client, 255, 150, 100, 255);
		}
		else
		{
			new count;
			new TempArray[15+1];

			for (new index=1; index<=15; index++)
			{
				if (bTankEnabled[index])
				{
					TempArray[count+1] = index;
					count++;	
				}
			}
			if (count > 0)
			{
				new random = GetRandomInt(1,count);
				new tankpick = TempArray[random];
				switch(tankpick)
				{
					case 1:
					{
						//Smasher
      	 					SetEntityRenderColor(client, 70, 80, 100, 255);
					}
					case 2:
					{
						//Warp
      	 					SetEntityRenderColor(client, 130, 130, 255, 255);
					}
					case 3:
					{
						//Meteor
      	 					SetEntityRenderColor(client, 100, 25, 25, 255);
					}
					case 4:
					{
						//Spitter
      	 					SetEntityRenderColor(client, 12, 115, 128, 255);
					}
					case 5:
					{
						//Heal
      	 					SetEntityRenderColor(client, 100, 255, 200, 255);
					}
					case 6:
					{
						//Fire
      	 					SetEntityRenderColor(client, 128, 0, 0, 255);
					}
					case 7:
					{
						//Ice
						SetEntityRenderMode(client, RenderMode:3);
      	 					SetEntityRenderColor(client, 0, 100, 170, 200);
					}
					case 8:
					{
						//Jockey
      	 					SetEntityRenderColor(client, 255, 200, 0, 255);
					}
					case 9:
					{
						//Ghost
						SetEntityRenderMode(client, RenderMode:3);
      	 					SetEntityRenderColor(client, 100, 100, 100, 0);
					}
					case 10:
					{
						//Shock
      	 					SetEntityRenderColor(client, 100, 165, 255, 255);
					}
					case 11:
					{
						//Witch
      	 					SetEntityRenderColor(client, 255, 200, 255, 255);
					}
					case 12:
					{
						//Shield
      	 					SetEntityRenderColor(client, 135, 205, 255, 255);
					}
					case 13:
					{
						//Cobalt
      	 					SetEntityRenderColor(client, 0, 105, 255, 255);
					}
					case 14:
					{
						//Jumper
      	 					SetEntityRenderColor(client, 200, 255, 0, 255);
					}
					case 15:
					{
						//Gravity
      	 					SetEntityRenderColor(client, 33, 34, 35, 255);
					}
				}
			}
		}
	}
}


stock GetSuperTankByRenderColor(color)
{
	switch(color)
	{
		//Fire Tank
		case 12800:
		{
			return 6;
		}
		//Gravity Tank
		case 333435:
		{
			return 15;
		}
		//Ice Tank
		case 0100170:
		{
			return 7;
		}
		//Cobalt Tank
		case 0105255:
		{
			return 13;
		}
		//Meteor Tank
		case 1002525:
		{
			return 3;
		}
		//Jumper Tank
		case 2002550:
		{
			return 14;
		}
		//Jockey Tank
		case 2552000:
		{
			return 8;
		}
		//Smasher Tank
		case 7080100:
		{
			return 1;
		}		
		//Spitter Tank
		case 12115128:
		{
			return 4;
		}
		//Heal Tank
		case 100255200:
		{
			return 5;
		}				
		//Ghost Tank
		case 100100100:
		{
			return 9;
		}
		//Shock Tank
		case 100165255:
		{
			return 10;
		}
		//Warp Tank
		case 130130255:
		{
			return 2;
		}
		//Shield Tank
		case 135205255:
		{
			return 12;
		}
		//Demon Tank
		case 255150100:
		{
			return 16;
		}		
		//Witch Tank
		case 255200255:
		{
			return 11;
		}
		//Default Tank
		case 255255255:
		{
			return 0;
		}
	}
	return -1;
}


public TankController()
{
	CountTanks();
	if (iNumTanks > 0)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsTank(i))
			{
				new index = GetSuperTankByRenderColor(GetEntRenderColor(i));
				if (index >= 0 && index <= 16)
				{
					if (index != 0 || (index == 0 && bDefaultOverride))
					{
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", flTankSpeed[index]);
						switch(index)
						{
							case 1:
							{
								new glowcolor = RGB_TO_INT(50, 50, 50);
								SetEntProp(i, Prop_Send, "m_glowColorOverride", glowcolor);
								SetEntProp(i, Prop_Send, "m_iGlowType", 2);	
							}
							case 2:
							{
								TeleportTank(i);
							}
							case 3:
							{
								if (TankAbility[i] == 0)
								{
									new random = GetRandomInt(1,iMeteorStormDelay);
									if (random == 1)
									{
										StartMeteorFall(i);
									}
								}
							}
							case 4:
							{
								SpitterTankAbility(i);
							}
							case 5:
							{
								HulkTankAbility(i);
								if (TankAbilityTimer[i] > 0)
								{
									TankAbilityTimer[i] -= 1;
								}
							}
							case 6:
							{
								IgniteEntity(i, 1.0);
								FireTankAbility(i);
							}
							case 7:
							{
								IceTankAbility(i);
							}
							case 9:
							{
								InfectedCloak(i);
								if (CountSurvOutRange(i, 120) == CountSurvivorsAliveAll())
								{
									SetEntityRenderMode(i, RenderMode:3);
      	 								SetEntityRenderColor(i, 100, 100, 100, 50);
									EmitSoundToAll("npc/infected/action/die/male/death_43.wav", i);
								}
								else
								{
									SetEntityRenderMode(i, RenderMode:3);
      	 								SetEntityRenderColor(i, 100, 100, 100, 150);
									EmitSoundToAll("npc/infected/action/die/male/death_42.wav", i);
								}
								GhostTankAbility(i);
							}
							case 10:
							{
								ShockTankAbility(i);
							}
							case 11:
							{
								WitchTankAbility(i);
							}
							case 12:
							{
								ShieldState[i] -= 1;
								if (ShieldState[i] <= -60)
								{
									DeactivateShield(i, 30.0);
									ShieldState[i] = 0;
								}
								if (ShieldsUp[i] > 0)
								{
									new glowcolor = RGB_TO_INT(120, 90, 150);
									SetEntProp(i, Prop_Send, "m_iGlowType", 2);
									SetEntProp(i, Prop_Send, "m_bFlashing", 2);
									SetEntProp(i, Prop_Send, "m_glowColorOverride", glowcolor);
								}
								else
								{
									SetEntProp(i, Prop_Send, "m_iGlowType", 0);
									SetEntProp(i, Prop_Send, "m_bFlashing", 0);
									SetEntProp(i, Prop_Send, "m_glowColorOverride", 0);
								}
							}
							case 13:
							{
								if (TankAbility[i] == 0)
								{
									SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
									new random = GetRandomInt(1,9);
									if (random == 1)
									{
										TankAbility[i] = 1;
										CreateTimer(0.3, BlurEffect, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
									}
								}
								else if (TankAbility[i] == 1)
								{
									SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", flCobaltSpecialSpeed);
								}
							}
							case 15:
							{
								SetEntityGravity(i, 0.5);
							}
							case 16:
							{
								SetEntityGravity(i, 0.5);
							}
						}
						if (bTankFireImmunity[index])
						{
							if (IsPlayerBurning(i))
							{
								ExtinguishEntity(i);
								SetEntPropFloat(i, Prop_Send, "m_burnPercent", 1.0);
							}
						}
					}
				}		
			}
		}
	}
}


stock ExecTankDeath(client)
{
	TankAlive[client] = 0;
	TankAbility[client] = 0;

	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
	{
		decl String:model[64];
            	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, "models/props_debris/concrete_chunk01a.mdl", false))
		{
			new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == client)
			{
				SetEntPropFloat(entity, Prop_Data, "m_flModelScale", 1.0);
				AcceptEntityInput(entity, "Kill");
			}
		}
		else if (StrEqual(model, "models/props_vehicles/tire001c_car.mdl", false))
		{
			new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == client)
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
		else if (StrEqual(model, "models/props_unique/airport/atlas_break_ball.mdl", false))
		{
			new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == client)
			{
				SetEntPropFloat(entity, Prop_Data, "m_flModelScale", 1.0);
				AcceptEntityInput(entity, "Kill");
			}
		}
		else if (StrEqual(model, "models/props_c17/substation_circuitbreaker03.mdl", false))
		{
			new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == client)
			{
				SetEntPropFloat(entity, Prop_Data, "m_flModelScale", 1.0);
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
	while ((entity = FindEntityByClassname(entity, "beam_spotlight")) != INVALID_ENT_REFERENCE)
	{
		new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
		if (owner == client)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	while ((entity = FindEntityByClassname(entity, "point_push")) != INVALID_ENT_REFERENCE)
	{
		new owner = GetEntProp(entity, Prop_Send, "m_glowColorOverride");
		if (owner == client)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	while ((entity = FindEntityByClassname(entity, "info_particle_system")) != INVALID_ENT_REFERENCE)
	{
		new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
		if (owner == client)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	switch(iFinaleStage)
	{
		case 1: CreateTimer(5.0, TimerTankWave2, _, TIMER_FLAG_NO_MAPCHANGE);
		case 2: CreateTimer(5.0, TimerTankWave3, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * Timer: Tank Spawn
 * Called 0.1s after tank spawns to configure abilities
 */
public Action:TankSpawnTimer(Handle:timer, any:client)
{
	if (IsTank(client))
	{
		new index = GetSuperTankByRenderColor(GetEntRenderColor(client));
		if (index >= 0 && index <= 16)
		{
			if (index != 0 || (index == 0 && bDefaultOverride))
			{
				switch(index)
				{
					case 1:
					{
						SetEntProp(client, Prop_Send, "m_iGlowType", 3);
						new glowcolor = RGB_TO_INT(50, 50, 50);
						SetEntProp(client, Prop_Send, "m_glowColorOverride", glowcolor);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Smasher Tank");
						}
					}
					case 2:
					{
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Warp Tank");
						}
					}
					case 3:
					{
						CreateTimer(0.1, MeteorTankTimer, client, TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(6.0, Timer_AttachMETEOR, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Meteor Tank");
						}
					}
					case 4:
					{
						CreateTimer(2.0, Timer_AttachSPIT, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Spitter Tank");
						}
					}
					case 5:
					{
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Heal Tank");
						}
					}
					case 6:
					{
						CreateTimer(0.8, Timer_AttachFIRE, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Fire Tank");
						}
					}
					case 7:
					{
						CreateTimer(2.0, Timer_AttachICE, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Ice Tank");
						}
					}
					case 8:
					{
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Jockey Tank");
						}
					}
					case 9:
					{
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Ghost Tank");
						}
					}
					case 10:
					{
						CreateTimer(0.8, Timer_AttachELEC, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Shock Tank");
						}
					}
					case 11:
					{
						CreateTimer(2.0, Timer_AttachBLOOD, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Witch Tank");
						}
					}
					case 12:
					{
						if (ShieldsUp[client] == 0)
						{
							ActivateShield(client);
						}
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Shield Tank");
						}
					}
					case 13:
					{
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Cobalt Tank");
						}
					}
					case 14:
					{
						CreateTimer(0.1, JumperTankTimer, client, TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Jumper Tank");
						}
					}
					case 15:
					{
						CreateTimer(0.1, GravityTankTimer, client, TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Gravity Tank");
						}
					}
					case 16:
					{
						SetDemonTankHealth(client);
						CreateTimer(0.1, DemonTankTimer, client, TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Demon Tank");
						}
					}
				}
				if (iTankExtraHealth[index] > 0)
				{
					new health = GetEntProp(client, Prop_Send, "m_iHealth");
					new maxhealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
					SetEntProp(client, Prop_Send, "m_iMaxHealth", maxhealth + iTankExtraHealth[index]);
					SetEntProp(client, Prop_Send, "m_iHealth", health + iTankExtraHealth[index]);
				}
				ResetInfectedAbility(client, flTankThrow[index]);
			}
		}

		// Eclipse Integration: Modificar stats según modo de dificultad Eclipse
		#if defined ECLIPSE_INTEGRATION
		SuperTanksEclipse_ModifyTankStats(client);
		#endif
	}
	return Plugin_Stop;
}

/**
 * Teleport Warp Tank to survivors
 */
stock TeleportTank(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 130130255)
	{
		new random = GetRandomInt(1,iWarpTeleportDelay);
		if (random == 1)
		{
			new target = Pick();
			if (target)
			{
				new Float:Origin[3], Float:Angles[3];
				GetClientAbsOrigin(target, Origin);
				GetClientAbsAngles(target, Angles);
				CreateParticle(client, PARTICLE_WARP, 1.0, 0.0);
				TeleportEntity(client, Origin, Angles, NULL_VECTOR);
			}
		}
	}
}

/**
 * Cloak special infected near Ghost Tank
 */
stock InfectedCloak(client)
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3], Float:InfectedPos[3];
			GetClientAbsOrigin(client, TankPos);
			GetClientAbsOrigin(i, InfectedPos);
			new Float:distance = GetVectorDistance(TankPos, InfectedPos);
			if (distance < 500)
			{
				SetEntityRenderMode(i, RenderMode:3);
				SetEntityRenderColor(i, 255, 255, 255, 50);
			}
			else
			{
				SetEntityRenderMode(i, RenderMode:3);
				SetEntityRenderColor(i, 255, 255, 255, 255);
			}
		}
	}
}

/**
 * Check if survivor is in range of tank
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
 * Count survivors in range of tank
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
 * Count survivors out of range of tank
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
 * Blur effect for Cobalt Tank
 */
public Action:BlurEffect(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 0105255 && TankAbility[client] == 1)
	{
		new Float:TankPos[3], Float:TankAng[3];
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, Prop_Send, "m_nSequence");
		new entity = CreateEntityByName("prop_dynamic");
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "6");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision");
			SetEntityRenderColor(entity, 0, 105, 255, 255);
			SetEntProp(entity, Prop_Send, "m_nSequence", Anim);
			SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", 15.0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect, entity, TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

/**
 * Remove blur effect entity
 */
public Action:RemoveBlurEffect(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		new iAlpha = GetEntityRenderColor(entity);
		if (iAlpha - 25 <= 0)
		{
			AcceptEntityInput(entity, "Kill");
			return Plugin_Stop;
		}
		else
		{
			SetEntityRenderColor(entity, 0, 105, 255, iAlpha - 25);
			CreateTimer(0.3, RemoveBlurEffect, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Stop;
}

