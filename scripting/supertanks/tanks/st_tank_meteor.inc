#if defined _st_tank_meteor_included
 #endinput
#endif
#define _st_tank_meteor_included

// ============================================================================
// METEOR TANK MODULE
// Meteor Tank abilities and mechanics
// Color: RGB(100, 25, 25) = 1002525
// ============================================================================

/**
 * Initialize Meteor Tank - Attach debris props to body
 * Called on tank spawn (TankInitialize)
 *
 * @param client    Meteor Tank client index
 * @return          Plugin_Continue or Plugin_Stop
 */
public Action:MeteorTankTimer(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 1002525)
	{
		new Float:Origin[3], Float:Angles[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
		new ent[5];
		for (new count=1; count<=4; count++)
		{
			ent[count] = CreateEntityByName("prop_dynamic_override");
			if (IsValidEntity(ent[count]))
			{
				DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
				DispatchKeyValueVector(ent[count], "origin", Origin);
				DispatchKeyValueVector(ent[count], "angles", Angles);
				DispatchSpawn(ent[count]);
				AcceptEntityInput(ent[count], "DisableCollision");
				SetEntProp(ent[count], Prop_Send, "m_hOwnerEntity", client);

				SetVariantString("!activator");
				AcceptEntityInput(ent[count], "SetParent", client);
				switch(count)
				{
					case 1:SetVariantString("relbow");
					case 2:SetVariantString("lelbow");
					case 3:SetVariantString("rshoulder");
					case 4:SetVariantString("lshoulder");
				}
				AcceptEntityInput(ent[count], "SetParentAttachment");
				switch(count)
				{
					case 1,2:SetEntPropFloat(ent[count], Prop_Data, "m_flModelScale", 0.4);
					case 3,4:SetEntPropFloat(ent[count], Prop_Data, "m_flModelScale", 0.5);
				}
				Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
				Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
				Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
				TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

/**
 * Attach meteor particle effect to tank
 *
 * @param client    Meteor Tank client index
 * @return          Plugin_Continue or Plugin_Stop
 */
public Action:Timer_AttachMETEOR(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 1002525)
	{
		AttachParticle(client, PARTICLE_METEOR, 6.0, 0.0, 0.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

/**
 * Start meteor storm attack
 *
 * @param client    Meteor Tank client index
 * @noreturn
 */
stock StartMeteorFall(client)
{
	TankAbility[client] = 1;
	decl Float:pos[3];
	GetClientEyePosition(client, pos);

	new Handle:Pack = CreateDataPack();
	WritePackCell(Pack, iRound);
	WritePackCell(Pack, client);
	WritePackFloat(Pack, pos[0]);
	WritePackFloat(Pack, pos[1]);
	WritePackFloat(Pack, pos[2]);
	WritePackFloat(Pack, GetEngineTime());
	CreateTimer(0.6, UpdateMeteorFall, Pack);
}

/**
 * Update meteor fall - Spawns meteors and handles explosions
 *
 * @param timer    Timer handle
 * @param data     Data pack with meteor info
 * @noreturn
 */
public Action:UpdateMeteorFall(Handle:timer, any:data)
{
	ResetPack(data);
	new round = ReadPackCell(data);
	new client = ReadPackCell(data);
	decl Float:pos[3];
	pos[0] = ReadPackFloat(data);
	pos[1] = ReadPackFloat(data);
	pos[2] = ReadPackFloat(data);
	new Float:time = ReadPackFloat(data);
	CloseHandle(data);

	if (iRound != round || !IsServerProcessing())
	{
		return;
	}

	if ((GetEngineTime() - time) > 5.0)
	{
		TankAbility[client] = 0;
	}
	new entity = -1;
	if (IsTank(client) && TankAbility[client] == 1)
	{
		decl Float:angle[3], Float:velocity[3], Float:hitpos[3];
		angle[0] = 0.0 + GetRandomFloat(-20.0, 20.0);
		angle[1] = 0.0 + GetRandomFloat(-20.0, 20.0);
		angle[2] = 60.0;

		GetVectorAngles(angle, angle);
		GetRayHitPos(pos, angle, hitpos, client, true);
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

		if (dis > 100.0)
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
				SetEntProp(ent, Prop_Send, "m_hOwnerEntity", client);
			}
		}
	}
	else if (TankAbility[client] == 0)
	{
		while ((entity = FindEntityByClassname(entity, "tank_rock")) != INVALID_ENT_REFERENCE)
		{
			new ownerent = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (client == ownerent)
			{
				ExplodeMeteor(entity, ownerent);
			}
		}
		return;
	}
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != INVALID_ENT_REFERENCE)
	{
		new ownerent = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
		if (client == ownerent)
		{
			if (OnGroundUnits(entity) < 200.0)
			{
				ExplodeMeteor(entity, ownerent);
			}
		}
	}

	new Handle:Pack = CreateDataPack();
	WritePackCell(Pack, round);
	WritePackCell(Pack, client);
	WritePackFloat(Pack, pos[0]);
	WritePackFloat(Pack, pos[1]);
	WritePackFloat(Pack, pos[2]);
	WritePackFloat(Pack, time);
	CreateTimer(0.6, UpdateMeteorFall, Pack);
}

/**
 * Check distance from entity to ground
 *
 * @param i_Ent    Entity index
 * @return         Distance in units, or 0.0 if on ground
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
 * Get ray trace hit position
 *
 * @param pos          Start position
 * @param angle        Trace angle
 * @param hitpos       Output hit position
 * @param ent          Entity to exclude
 * @param useoffset    Use offset from hit position
 * @return             Hit entity index
 */
stock GetRayHitPos(Float:pos[3], Float:angle[3], Float:hitpos[3], ent=0, bool:useoffset=false)
{
	new Handle:trace;
	new hit=0;

	trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndLive, ent);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		hit=TR_GetEntityIndex( trace);
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
 * Explode a meteor rock
 *
 * @param entity    Meteor rock entity
 * @param client    Meteor Tank client index
 * @noreturn
 */
stock ExplodeMeteor(entity, client)
{
	if (entity > 32 && IsValidEntity(entity) && IsTank(client))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, 20);
		if (!StrEqual(classname, "tank_rock", true))
		{
			return;
		}
		new target;
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsSurvivor(i))
			{
				target = i;
				break;
			}
		}

		new Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		pos[2]+=50.0;
		AcceptEntityInput(entity, "Kill");

		PropaneExplode(target, pos);

		new pointHurt = CreateEntityByName("point_hurt");
		DispatchKeyValueFloat(pointHurt, "Damage", flMeteorStormDamage);
		DispatchKeyValue(pointHurt, "DamageType", "128");
		DispatchKeyValue(pointHurt, "DamageDelay", "0.0");
		DispatchKeyValueFloat(pointHurt, "DamageRadius", 200.0);
		DispatchSpawn(pointHurt);
		TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(pointHurt, "Hurt", client);
		SetVariantString("OnUser1 !self:Kill::0.1:-1");
		AcceptEntityInput(pointHurt, "AddOutput");
		AcceptEntityInput(pointHurt, "FireUser1");
	}
}

/**
 * Trace ray filter - Don't hit self or alive players
 *
 * @param entity    Entity being tested
 * @param mask      Contents mask
 * @param data      Entity to exclude
 * @return          True to hit entity, false to ignore
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
