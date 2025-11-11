#if defined _st_damage_included
 #endinput
#endif
#define _st_damage_included

// ============================================================================
// DAMAGE SYSTEM
// Damage dealing, damage hooks, fire immunity, shield mechanics
// ============================================================================

/**
 * Deal damage to a player using point_hurt entity
 *
 * @param target     Target player client index
 * @param attacker   Attacker client index
 * @param dmgtype    Damage type flags
 * @param dmg        Damage amount
 * @param inflictor  Inflictor classname
 * @noreturn
 */
stock DealDamagePlayer(target, attacker, dmgtype, dmg, String:inflictor[])
{
	if (target > 0 && target <= 32)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target))
		{
   	 		decl String:damage[16], String:type[16];
    			IntToString(dmg, damage, sizeof(damage));
    			IntToString(dmgtype, type, sizeof(type));
			new pointHurt = CreateEntityByName("point_hurt");
			if (pointHurt)
			{
				DispatchKeyValue(target, "targetname", "hurtme");
				DispatchKeyValue(pointHurt, "Damage", damage);
				DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
				DispatchKeyValue(pointHurt, "DamageType", type);
				DispatchKeyValue(pointHurt, "classname", inflictor);
				DispatchSpawn(pointHurt);
				AcceptEntityInput(pointHurt, "Hurt", (attacker > 0 && IsClientInGame(attacker))?attacker:-1);
				AcceptEntityInput(pointHurt, "Kill");
				DispatchKeyValue(target, "targetname", "donthurtme");
			}
		}
	}
}

/**
 * Deal damage to an entity (infected, witch) using point_hurt
 *
 * @param target     Target entity index
 * @param attacker   Attacker client index
 * @param dmgtype    Damage type flags
 * @param dmg        Damage amount
 * @param inflictor  Inflictor classname
 * @noreturn
 */
stock DealDamageEntity(target, attacker, dmgtype, dmg, String:inflictor[])
{
	if (target > 32)
	{
		if (IsValidEntity(target))
		{
   	 		decl String:damage[16], String:type[16];
    			IntToString(dmg, damage, sizeof(damage));
    			IntToString(dmgtype, type, sizeof(type));
			new pointHurt = CreateEntityByName("point_hurt");
			if (pointHurt)
			{
				if (IsInfected(target) || IsWitch(target))
				{
					new ragdoll = GetEntProp(target, Prop_Data, "m_bClientSideRagdoll");
					if (ragdoll == 0)
					{
						DispatchKeyValue(target, "targetname", "hurtme");
						DispatchKeyValue(pointHurt, "Damage", damage);
						DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
						DispatchKeyValue(pointHurt, "DamageType", type);
						DispatchKeyValue(pointHurt, "classname", inflictor);
						DispatchSpawn(pointHurt);
						if (IsClientInGame(attacker))
						{
							AcceptEntityInput(pointHurt, "Hurt", attacker);
						}
						DispatchKeyValue(target, "targetname", "donthurtme");
					}
				}
				AcceptEntityInput(pointHurt, "Kill");
			}
		}
	}
}

/**
 * Hook: Called when an entity takes damage
 * Handles witch-on-witch damage prevention
 */
public Action:OnEntityTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (damage > 0.0 && victim > 32 && IsValidEntity(victim))
	{
		if (IsWitch(victim) && IsWitch(attacker))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

/**
 * Hook: Called when a player takes damage
 * Handles:
 * - Nightmare mode damage multipliers
 * - Tank-specific claw abilities
 * - Fire immunity for tanks
 * - Shield tank damage blocking
 * - Special infected damage in nightmare mode
 */
public Action:OnPlayerTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (bSuperTanksEnabled && damage > 0.0)
	{
		decl String:inflictorname[28];
		decl String:weaponname[28];
		if (weapon > 0)
		{
			GetEdictClassname(weapon, weaponname, sizeof(weaponname));
		}
		if (inflictor > 0)
		{
			GetEdictClassname(inflictor, inflictorname, sizeof(inflictorname));
		}

		// ====================================================================
		// SURVIVOR TAKING DAMAGE
		// ====================================================================
		if (IsSurvivor(victim))
		{
			// Damage from common infected
			if (IsInfected(attacker))
			{
				if (bNightmare)
				{
					damage = 30.0;
				}
			}
			// Damage from witch
			else if (IsWitch(attacker))
			{
				if (bNightmare)
				{
					damage = 500.0;
				}
				else if (GetEntProp(attacker, Prop_Send, "m_hOwnerEntity") == 255200255)
				{
					damage = 10.0;
				}
			}
			// Damage from infected team (tanks, SI)
			else if (IsValidClient(attacker))
			{
				if (GetClientTeam(attacker) == 3)
				{
					if (IsTank(attacker))
					{
						new color = GetEntRenderColor(attacker);

						// Tank-specific claw abilities
						switch(color)
						{
							case 12800: // Fire Tank
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false) || StrEqual(inflictorname, "tank_rock", false))
								{
									SkillFlameClaw(victim);
								}
							}
							case 333435: // Gravity Tank
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false))
								{
									SkillGravityClaw(victim);
								}
							}
							case 0100170: // Ice Tank
							{
								new flags = GetEntityFlags(victim);
								if (flags & FL_ONGROUND)
								{
									new random = GetRandomInt(1,3);
									if (random == 1)
									{
										SkillIceClaw(victim, attacker);
									}
								}
							}
							case 0105255: // Cobalt Tank
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false))
								{
									TankAbility[attacker] = 0;
								}
							}
							case 7080100: // Smasher Tank
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false))
								{
									new random = GetRandomInt(1,2);
									if (random == 1)
									{
										SkillSmashClawKill(victim, attacker);
									}
									else
									{
										SkillSmashClaw(victim);
									}
								}
							}
							case 100165255: // Shock Tank
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false))
								{
									SkillElecClaw(victim, attacker);
								}
							}
							case 130130255: // Warp Tank
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false))
								{
									new dmg = RoundFloat(damage / 2);
									DealDamagePlayer(victim, attacker, 128, dmg, "point_hurt");
								}
							}
							case 255150100: // Demon Tank
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false))
								{
									SkillSmashClawKill(victim, attacker);
								}
							}
						}

						// Nightmare mode tank damage multiplier
						if (!StrEqual(inflictorname, "inferno", false) && !StrEqual(inflictorname, "pipe_bomb_project", false) && !StrEqual(inflictorname, "insect_swarm", false) && !StrEqual(inflictorname, "point_hurt", false))
						{
							if (bNightmare)
							{
								damage = 200.0;
							}
						}
					}
					// Special infected damage in nightmare mode
					else if (IsSpecialInfected(attacker) && bNightmare)
					{
						if (damagetype != 263168 && damagetype != 265216) // not acid
						{
							if (!StrEqual(inflictorname, "pipe_bomb_project", false) && !StrEqual(inflictorname, "point_hurt", false))
							{
								damage = 50.0;
							}
						}
					}
				}
			}
		}
		// ====================================================================
		// TANK TAKING DAMAGE
		// ====================================================================
		else if (IsValidClient(victim) && GetClientTeam(victim) == 3)
		{
			if (IsTank(victim))
			{
				// Fire immunity check
				if (damagetype == 8 || damagetype == 2056 || damagetype == 268435464)
				{
					new index = GetSuperTankByRenderColor(GetEntRenderColor(victim));
					if (index >= 0 && index <= 15)
					{
						if (bTankFireImmunity[index])
						{
							if (index != 0 || (index == 0 && bDefaultOverride))
							{
								return Plugin_Handled;
							}
						}
					}
				}

				// Tank abilities triggered by taking damage
				if (IsSurvivor(attacker))
				{
					new color = GetEntRenderColor(victim);
					switch(color)
					{
						case 1002525: // Meteor Tank - melee triggers meteor
						{
							if (weapon > 32 && IsValidEntity(weapon))
							{
								if (StrEqual(weaponname, "weapon_melee", false))
								{
									new random = GetRandomInt(1,2);
									if (random == 1)
									{
										if (TankAbility[victim] == 0)
										{
											StartMeteorFall(victim);
										}
									}
								}
							}
						}
						case 100100100: // Ghost Tank - weapon disarm
						{
							if (bGhostDisarm)
							{
								if (weapon > 32 && IsValidEntity(weapon))
								{
									new random = GetRandomInt(1,15);
									if (random == 1)
									{
										ForceWeaponDrop(attacker);
									}
								}
							}
						}
						case 135205255: // Shield Tank - damage blocking
						{
							if (ShieldsUp[victim] > 0)
							{
								return Plugin_Handled;
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Changed;
}

// IsSpecialInfected is now defined in utilities/st_utils.inc
