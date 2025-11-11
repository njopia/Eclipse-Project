#if defined _st_nightmare_spawning_included
 #endinput
#endif
#define _st_nightmare_spawning_included

// ============================================================================
// NIGHTMARE MODE - SPAWNING MODULE
// Enhanced spawning system and meteor mechanics
// ============================================================================

/**
 * Inferno meteor fall system
 * Creates falling meteors that target survivors
 */
stock InfernoMeteorFall()
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != INVALID_ENT_REFERENCE)
	{
		if (OnGroundUnits(entity) < 200.0)
		{
			ExplodeInfernoMeteor(entity);
		}
	}
	if (GetRandomInt(1,2) == 1)
	{
		new target = Pick();
		if (IsSurvivor(target) && IsPlayerAlive(target))
		{
			decl Float:pos[3];
			GetClientEyePosition(target, pos);
			decl Float:angle[3], Float:velocity[3], Float:hitpos[3];
			angle[0] = 0.0 + GetRandomFloat(-20.0, 20.0);
			angle[1] = 0.0 + GetRandomFloat(-20.0, 20.0);
			angle[2] = 60.0;

			GetVectorAngles(angle, angle);
			GetRayHitPos(pos, angle, hitpos, target, true);
			new Float:dis = GetVectorDistance(pos, hitpos);
			if (GetVectorDistance(pos, hitpos) > 2000.0)
			{
				dis = 1600.0;
			}
			decl Float:t[3];
			MakeVectorFromPoints(pos, hitpos, t);
			NormalizeVector(t, t);
			ScaleVector(t, dis - 40.0);
			AddVectors(pos, t, hitpos);

			if (dis > 500.0)
			{
				new ent = CreateEntityByName("tank_rock");
				if (ent > 0)
				{
					DispatchKeyValue(ent, "model", "models/props_debris/concrete_chunk01a.mdl");
					DispatchSpawn(ent);
					decl Float:angle2[3];
					angle2[0] = GetRandomFloat(-180.0, 180.0);
					angle2[1] = GetRandomFloat(-180.0, 180.0);
					angle2[2] = GetRandomFloat(-180.0, 180.0);

					velocity[0] = GetRandomFloat(0.0, 350.0);
					velocity[1] = GetRandomFloat(0.0, 350.0);
					velocity[2] = GetRandomFloat(0.0, 30.0);

					TeleportEntity(ent, hitpos, angle2, velocity);
					ActivateEntity(ent);

					AcceptEntityInput(ent, "Ignite");
					SetVariantString("OnUser1 !self:Kill::7.0:-1");
					AcceptEntityInput(ent, "AddOutput");
					AcceptEntityInput(ent, "FireUser1");
				}
			}
		}
	}
}

/**
 * Explode inferno meteor on ground impact
 */
stock ExplodeInfernoMeteor(entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		new attacker, target;
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsSurvivor(i))
			{
				target = i;
				break;
			}
		}
		for (new j=1; j<=MaxClients; j++)
		{
			if (IsTank(j) || IsSpecialInfected(j))
			{
				attacker = j;
				break;
			}
		}
		decl String:classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (!StrEqual(classname, "tank_rock", true))
		{
			return;
		}
		decl Float:RockPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", RockPos);
		new ent;
		new m = 0;
		for (new n=1; n<=MaxClients; n++)
		{
			if (IsSurvivor(n) && IsPlayerAlive(n))
			{
				m++;
			}
		}
		new i;
		for (new x=1; x<=m; x++)
		{
			i++;
			ent = CreateEntityByName("inferno");
			if (ent > 0)
			{
				DispatchSpawn(ent);
				TeleportEntity(ent, RockPos, NULL_VECTOR, NULL_VECTOR);
				ActivateEntity(ent);
				AcceptEntityInput(ent, "Start");
				if (attacker > 0 && target > 0)
				{
					SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", attacker);
				}
			}
		}
		AcceptEntityInput(entity, "Kill");
	}
}

// GetNearestSurvivorDistEnt is defined in utilities/st_utils.inc

/**
 * Check if client is viewing target entity
 */
stock bool:IsClientViewing(client, target)
{
	new Float:fThreshold = 0.73;
    	decl Float:fViewPos[3];
	GetClientEyePosition(client, fViewPos);
    	decl Float:fViewAng[3];
	GetClientEyeAngles(client, fViewAng);
    	decl Float:fViewDir[3];
    	decl Float:fTargetPos[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", fTargetPos);
	fTargetPos[2] += 30;
    	decl Float:fDistance[3];
    	decl Float:fTargetDir[3];
    	MakeVectorFromPoints(fViewPos, fTargetPos, fDistance);
    	GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
    	fDistance[2] = 0.0;
    	NormalizeVector(fDistance, fTargetDir);
    	if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;
    	new Handle:hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    	if (TR_DidHit(hTrace))
	{
		CloseHandle(hTrace);
		return false;
	}
    	CloseHandle(hTrace);
    	return true;
}

/**
 * Filter for client viewing raytrace
 */
public bool:ClientViewsFilter(Entity, Mask, any:Junk)
{
    	if (Entity > 0 && IsValidEntity(Entity)) return false;
    	return true;
}

/**
 * Director command wrapper
 */
stock DirectorCommand(client, String:command[])
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s", command);
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}

// Pick is defined in utilities/st_utils.inc
