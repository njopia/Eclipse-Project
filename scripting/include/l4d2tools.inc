forward Action:L4D2_OnSpawnTank(const Float:vector[3], const Float:qangle[3]);
forward Action:L4D2_OnSpawnWitch(const Float:vector[3], const Float:qangle[3]);
forward Action:L4D2_OnSpawnWitchBride(const Float:vector[3], const Float:qangle[3]);
forward Action:L4D2_OnSpawnSpecial(&zombieClass, const Float:vector[3], const Float:qangle[3]);
forward Action:L4D2_OnFirstSurvivorLeftSafeArea(client);
forward L4D2_OnEnterGhostState(client);
forward Action:L4D2_OnTryOfferingTankBot(tank_index, &bool:enterStasis);
forward Action:L4D2_OnMobRushStart();
forward Action:L4D2_OnSpawnITMob(&amount);
forward Action:L4D2_OnSpawnMob(&amount);
forward Action:L4D2_OnGetCrouchTopSpeed(target, &Float:retVal);
forward Action:L4D2_OnGetRunTopSpeed(target, &Float:retVal);
forward Action:L4D2_OnGetWalkTopSpeed(target, &Float:retVal);
forward Action:L4D2_OnHasConfigurableDifficulty(&retVal);
forward Action:L4D2_OnCThrowActivate(ability);
forward Action:L4D2_OnStartMeleeSwing(client, bool:boolean);
forward Action:L4D2_OnSendInRescueVehicle();
forward Action:L4D2_OnChangeFinaleStage(&finaleType, const String:arg[]);
forward Action:L4D2_OnSelectSequence(client, &sequence);
forward Action:L4D2_OnRevived(client);
forward Action:L4D2_OnStagger(target, source);
forward Action:L4D2_OnGetScriptValueInt(const String:key[], &retVal);
forward Action:L4D2_OnGetScriptValueFloat(const String:key[], &Float:retVal);
forward Action:L4D2_OnGetScriptValueString(const String:key[], const String:defaultVal[], String:retVal[128]);

native L4D2_GetTankCount();
native L4D2_RestartScenarioFromVote(const String:map[]);
native bool:L4D2_IsMissionFinalMap();
native L4D2_ResetMobTimer();
native L4D2_StaggerPlayer(target, source_ent, Float:source_vector[3]);
native L4D2_ShoveInfectedPlayer(target, source_ent, Float:source_vector[3]);
native L4D2_SendInRescueVehicle();
native L4D2_ChangeFinaleStage(finaleType, const String:arg[]);
native L4D2_SpawnTank(const Float:vector[3], const Float:qangle[3]);
native L4D2_SpawnSpecial(zombieClass, const Float:vector[3], const Float:qangle[3]);
native L4D2_SpawnWitch(const Float:vector[3], const Float:qangle[3]);
native L4D2_SpawnWitchBride(const Float:vector[3], const Float:qangle[3]);
native L4D2_FlashLightTurnOn(target);
native L4D2_PummelEnd(target);
native L4D2_PounceEnd(target);
native L4D2_RideEnd(target);
native L4D2_TongueBreak(target);
native L4D2_Respawn(target);
native L4D2_SpitBurst(target);
native L4D2_VomitOnPlayer(target, source_ent);
native L4D2_AdrenalineUsed(target, Float:duration);
native L4D2_WeaponDrop(target, weapon);
native L4D2_BecomeGhost(target);
native L4D2_CreateAbility(target);
native L4D2_SetClass(target, zombieclass);
native L4D2_PlayerHitByVomitJar(target, source_ent);
native L4D2_InfectedHitByVomitJar(target, source_ent);
native L4D2_ReviveSurvivor(target);
native L4D2_Fling(target, Float:velocity[3], anim_event, source_ent, Float:stun_time);
native L4D2_ReplaceTank(target, source_ent);
native L4D2_ReplaceWithBot(target);
native L4D2_ZombieAbortControl(target);
native L4D2_RefEntityHandle();
native L4D2_StateTransition(target);
native L4D2_CarryEnd(target);
native L4D2_RevivedByDefibrillator(target, source_ent);

public Extension:__ext_L4D2Tools = 
{
	name = "L4D2Tools",
	file = "L4D2Tools.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};
