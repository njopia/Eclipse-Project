#if defined _st_nightmare_core_included
 #endinput
#endif
#define _st_nightmare_core_included

// ============================================================================
// NIGHTMARE MODE - CORE MODULE
// Main nightmare logic, witch spawning, and countdown system
// ============================================================================

/**
 * Main Nightmare execution
 * Spawns tanks, witches, meteors, and triggers panic events
 */
stock ExecNightmare()
{
	if (bNightmare)
	{
		new random = GetRandomInt(1,15);
		if (random == 1)
		{
			EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");
		}
		if (iNumTanks < 3)
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
		new witchcount = CountWitches();
		if (witchcount < 66)
		{
			CreateWitchEvent();
			if (witchcount < 50)
			{
				CreateWitchEvent();
				if (witchcount < 40)
				{
					CreateWitchEvent();
					if (witchcount < 30)
					{
						CreateWitchEvent();
						if (witchcount < 20)
						{
							CreateWitchEvent();
						}
					}
				}
			}
		}
		RecycleWitches();
		EnrageAllWitches();
		InfernoMeteorFall();
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				DirectorCommand(i, "director_force_panic_event");
				break;
			}
		}
		if (iCCEnt <= 0)
		{
			CreateColorCorrection("materials/correction/urban_night_red.pwl.raw");
		}
	}
	else if (iNightmareBegin == 1)
	{
		if (iFinaleStage < 4)
		{
			StartCountdown();
		}
	}
	else
	{
		if (bIsFinale)
		{
			iCountDownTimer = 60;
		}
		else
		{
			iCountDownTimer = 30;
		}
	}
}

/**
 * Create witch spawn event
 */
stock CreateWitchEvent()
{
	new bot = CreateFakeClient("Witch");
	if (bot > 0)
	{
		SpawnCommand(bot, "z_spawn_old", "witch auto");
	}
}

/**
 * Start nightmare countdown
 */
stock StartCountdown()
{
	if (iFinaleStage < 4)
	{
		new amount;
		if (bIsFinale)
		{
			amount = 60;
		}
		else
		{
			amount = 30;
		}
		if (iNightmareTick >= 0 && iNightmareTick < amount)
		{
			if (bIsFinale)
			{
				if (iFinaleStage <= 0)
				{
					PrintHintTextToAll("Entering Nightmare mode in %i seconds. You must start the finale!", iCountDownTimer);
				}
				else
				{
					PrintHintTextToAll("Entering Nightmare mode in %i seconds. Get to the escape vehicle!", iCountDownTimer);
				}
			}
			else
			{
				PrintHintTextToAll("Entering Nightmare mode in %i seconds. Get to the saferoom!", iCountDownTimer);
			}
			switch(iCountDownTimer)
			{
				case 5: EmitSoundToAll("ui/beep22.wav");
				case 10: EmitSoundToAll("ui/beep22.wav");
				case 15: EmitSoundToAll("ui/beep22.wav");
				case 20: EmitSoundToAll("ui/beep22.wav");
				case 25: EmitSoundToAll("ui/beep22.wav");
				case 30: EmitSoundToAll("ui/beep22.wav");
				case 35: EmitSoundToAll("ui/beep22.wav");
				case 40: EmitSoundToAll("ui/beep22.wav");
				case 45: EmitSoundToAll("ui/beep22.wav");
				case 50: EmitSoundToAll("ui/beep22.wav");
				case 55: EmitSoundToAll("ui/beep22.wav");
				case 60: EmitSoundToAll("ui/beep22.wav");
			}
			iCountDownTimer -= 1;
		}
		else if (iNightmareTick == amount)
		{
			PrintHintTextToAll("Time limit reached. Entering Nightmare mode...");
			SetConVarBool(hNightmare, true);
		}
		else if (iNightmareTick == (amount + 5))
		{
			PrintHintTextToAll("Nightmare mode enabled, Zombies grow stronger!");
			EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");
		}
		iNightmareTick += 1;
	}
}

/**
 * Recycle witches that are far from survivors
 */
stock RecycleWitches()
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
	{
		new ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
		if (ragdoll <= 0)
		{
			new time = GetEntProp(entity, Prop_Send, "m_hEffectEntity");
			SetEntProp(entity, Prop_Send, "m_hEffectEntity", time+1);
			new Float:distance = GetNearestSurvivorDistEnt(entity);
			if (distance > 1000 && time > 20)
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
}

// IsWitchAngry is defined in utilities/st_utils.inc

/**
 * Count angry witches
 */
stock AngryWitchAmount()
{
	new count = 0;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
	{
		if (IsWitchAngry(entity))
		{
			count++;
		}
	}
	return count;
}

/**
 * Enrage all witches
 */
stock EnrageAllWitches()
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
	{
		new ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
		if (ragdoll == 0)
		{
			new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner <= 0 || !IsWitchAngry(entity))
			{
				new target = Pick();
				if (IsSurvivor(target) && IsPlayerAlive(target))
				{
					L4D2_InfectedHitByVomitJar(entity, target);
					SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
					SetEntProp(entity, Prop_Send, "m_hOwnerEntity", target);
				}
			}
		}
	}
}

// NightmareChanged and NightmareBeginChanged callbacks are in st_config.inc
