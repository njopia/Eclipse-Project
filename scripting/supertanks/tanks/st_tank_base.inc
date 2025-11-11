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

