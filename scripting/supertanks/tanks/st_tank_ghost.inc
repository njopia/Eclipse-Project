#if defined _st_tank_ghost_included
 #endinput
#endif
#define _st_tank_ghost_included

// ============================================================================
// GHOST TANK MODULE
// Ghost Tank abilities and mechanics
// Color: RGB(100, 100, 100) = 100100100
// ============================================================================

/**
 * Ghost Tank passive ability
 * Cloaks nearby special infected and has chance to disarm survivors
 *
 * @param client    Ghost Tank client index
 * @noreturn
 */
stock GhostTankAbility(client)
{
	if (bGhostDisarm)
	{
		if (IsTank(client) && GetEntRenderColor(client) == 100100100)
		{
			for (new i=1; i<=MaxClients; i++)
			{
				if (IsSurvivor(i) && IsPlayerAlive(i))
				{
					if (SurvInRange(client, i, 300))
					{
						new random = GetRandomInt(1,8);
						if (random == 1)
						{
							if (ForceWeaponDrop(i))
							{
								PrintToChat(i, "Something disarmed you...");
								EmitSoundToAll("npc/infected/action/die/male/death_43.wav", i);
							}
							return;
						}
					}
				}
			}
		}
	}
}

/**
 * Ghost Tank cloak ability
 * Makes nearby special infected translucent
 *
 * @param client    Ghost Tank client index
 * @noreturn
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
 * Force a survivor to drop their weapon
 *
 * @param client    Survivor client index
 * @return          True if weapon dropped, false otherwise
 */
stock ForceWeaponDrop(client)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		decl String:classname[32];
		GetClientWeapon(client, classname, sizeof(classname));
		if (StrEqual(classname, "weapon_melee", false))
		{
			new weaponid = GetPlayerWeaponSlot(client, 1);
			new String:Model[48];
			GetEntPropString(weaponid, Prop_Data, "m_ModelName", Model, sizeof(Model));
			if (StrEqual(Model, MODEL_V_FIREAXE, false)) classname = "weapon_fireaxe";
			else if (StrEqual(Model, MODEL_V_FRYING_PAN, false)) classname = "weapon_frying_pan";
			else if (StrEqual(Model, MODEL_V_MACHETE, false)) classname = "weapon_machete";
			else if (StrEqual(Model, MODEL_V_BAT, false)) classname = "weapon_baseball_bat";
			else if (StrEqual(Model, MODEL_V_CROWBAR, false)) classname = "weapon_crowbar";
			else if (StrEqual(Model, MODEL_V_CRICKET_BAT, false)) classname = "weapon_cricket_bat";
			else if (StrEqual(Model, MODEL_V_TONFA, false)) classname = "weapon_tonfa";
			else if (StrEqual(Model, MODEL_V_KATANA, false)) classname = "weapon_katana";
			else if (StrEqual(Model, MODEL_V_ELECTRIC_GUITAR, false)) classname = "weapon_electric_guitar";
			else if (StrEqual(Model, MODEL_V_KNIFE, false)) classname = "weapon_knife";
			else if (StrEqual(Model, MODEL_V_GOLFCLUB, false)) classname = "weapon_golfclub";
		}

		new slot;
		if (StrEqual(classname, "weapon_pistol", false) ||
			StrEqual(classname, "weapon_pistol_magnum", false) ||
			StrEqual(classname, "weapon_chainsaw", false))
		{
			slot = 1;
		}
		else if (StrEqual(classname, "weapon_first_aid_kit", false) ||
			StrEqual(classname, "weapon_defibrillator", false) ||
			StrEqual(classname, "weapon_pain_pills", false) ||
			StrEqual(classname, "weapon_adrenaline", false))
		{
			slot = 3;
		}
		else if (StrEqual(classname, "weapon_pipe_bomb", false) ||
			StrEqual(classname, "weapon_molotov", false) ||
			StrEqual(classname, "weapon_vomitjar", false))
		{
			slot = 2;
		}
		else if (StrContains(classname, "weapon_", false) >= 0 &&
			!StrEqual(classname, "weapon_gascan", false))
		{
			slot = 0;
		}
		else
		{
			return false;
		}

		new entity = GetPlayerWeaponSlot(client, slot);
		if (entity > 32 && IsValidEntity(entity))
		{
			SDKHooks_DropWeapon(client, entity, NULL_VECTOR, NULL_VECTOR);
			return true;
		}
	}
	return false;
}
