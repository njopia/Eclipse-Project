#if defined _st_tank_shock_included
 #endinput
#endif
#define _st_tank_shock_included

// ============================================================================
// SHOCK TANK MODULE
// Shock Tank abilities and mechanics
// Color: RGB(100, 165, 255) = 100165255
// ============================================================================

/**
 * Shock Tank claw skill
 * Applies electric shock effect with stun
 *
 * @param target    Survivor client index
 * @param tank      Shock Tank client index (attacker)
 * @noreturn
 */
public SkillElecClaw(target, tank)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			PlayerSpeed[target] += 3;
			new Handle:Pack = CreateDataPack();
			WritePackCell(Pack, iRound);
			WritePackCell(Pack, target);
			WritePackCell(Pack, tank);
			WritePackCell(Pack, 4);
			CreateTimer(5.0, Timer_Volt, Pack);

			PerformFade(target, 250, 100, 10, 1, {50, 150, 250, 100});
			ScreenShake(target, 15.0);
			AttachParticle(target, PARTICLE_ELEC, 2.0, 0.0, 0.0, 30.0);

			new random = GetRandomInt(1,2);
			switch(random)
			{
				case 1: EmitSoundToAll("ambient/energy/spark5.wav", target);
				case 2: EmitSoundToAll("ambient/energy/spark6.wav", target);
			}
		}
	}
}

/**
 * Shock Tank passive ability
 * Shoots lightning bolts at nearby survivors
 *
 * @param client    Shock Tank client index
 * @noreturn
 */
stock ShockTankAbility(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 100165255)
	{
		new count = CountSurvInRange(client, 400);

		for (new i=1; i<=MaxClients; i++)
		{
			if (IsSurvivor(i) && IsPlayerAlive(i))
			{
				if (SurvInRange(client, i, 400))
				{
					ShockBolt(client, i, count);
				}
			}
		}
	}
}

/**
 * Create a lightning bolt effect from tank to target
 *
 * @param client    Shock Tank client index
 * @param target    Target survivor index
 * @param damage    Damage amount
 * @noreturn
 */
stock ShockBolt(client, target, damage)
{
	if (IsTank(client) && GetEntRenderColor(client) == 100165255)
	{
		if (IsSurvivor(target))
		{
			decl String:name[32];
			decl Float:Origin[3], Float:TOrigin[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", TOrigin);
			Origin[2] += 30.0;
			TOrigin[2] += 30.0;
			new endpoint = CreateEntityByName("info_particle_target");
			if (endpoint > 0 && IsValidEntity(endpoint))
			{
				Format(name, sizeof(name), "bolttarget%i", endpoint);
				DispatchKeyValue(endpoint, "targetname", name);
				DispatchKeyValueVector(endpoint, "origin", TOrigin);
				DispatchSpawn(endpoint);
				ActivateEntity(endpoint);
				SetVariantString("OnUser1 !self:Kill::0.8:-1");
				AcceptEntityInput(endpoint, "AddOutput");
				AcceptEntityInput(endpoint, "FireUser1");
			}
			new particle = CreateEntityByName("info_particle_system");
			if (particle > 0 && IsValidEntity(particle))
			{
				DispatchKeyValue(particle, "effect_name", PARTICLE_LS_BOLT);
				DispatchKeyValue(particle, "cpoint1", name);
				DispatchKeyValueVector(particle, "origin", Origin);
				DispatchSpawn(particle);
				ActivateEntity(particle);
				SetVariantString("!activator");
				AcceptEntityInput(particle, "SetParent", client);
				AcceptEntityInput(particle, "start");
				SetVariantString("OnUser1 !self:Kill::0.8:-1");
				AcceptEntityInput(particle, "AddOutput");
				AcceptEntityInput(particle, "FireUser1");
			}
			if (damage > 4)
			{
				damage = 4;
			}
			DealDamagePlayer(target, client, 128, damage, "point_hurt");
			if (damage >= 3)
			{
				new random = GetRandomInt(1,5);
				switch(random)
				{
					case 1: EmitSoundToAll("ambient/energy/zap5.wav", target);
					case 2: EmitSoundToAll("ambient/energy/zap6.wav", target);
					case 3: EmitSoundToAll("ambient/energy/zap7.wav", target);
					case 4: EmitSoundToAll("ambient/energy/zap8.wav", target);
					case 5: EmitSoundToAll("ambient/energy/zap9.wav", target);
				}
			}
		}
	}
}

/**
 * Timer callback: Periodic electric shock damage
 *
 * @param timer    Timer handle
 * @param Pack     Data pack with client info
 * @return         Plugin_Continue
 */
public Action:Timer_Volt(Handle:timer, any:Pack)
{
	ResetPack(Pack, false);
	new round = ReadPackCell(Pack);
	new client = ReadPackCell(Pack);
	new tank = ReadPackCell(Pack);
	new amount = ReadPackCell(Pack);
	CloseHandle(Pack);

	if (iRound != round || !IsServerProcessing())
	{
		return Plugin_Continue;
	}

	if (client > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && PlayerSpeed[client] == 0 && IsTank(tank))
		{
			if (amount > 0)
			{
				PlayerSpeed[client] += 2;
				ScreenShake(client, 2.0);
				DealDamagePlayer(client, tank, 128, iShockStunDamage, "point_hurt");
				AttachParticle(client, PARTICLE_ELEC, 2.0, 0.0, 0.0, 30.0);
				new random = GetRandomInt(1,2);
				switch(random)
				{
					case 1: EmitSoundToAll("ambient/energy/spark5.wav", client);
					case 2: EmitSoundToAll("ambient/energy/spark6.wav", client);
				}
				new Handle:NewPack = CreateDataPack();
				WritePackCell(NewPack, iRound);
				WritePackCell(NewPack, client);
				WritePackCell(NewPack, tank);
				WritePackCell(NewPack, amount - 1);
				CreateTimer(5.0, Timer_Volt, NewPack);
			}
		}
	}
	return Plugin_Continue;
}
