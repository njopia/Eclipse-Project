#if defined _st_sdk_included
 #endinput
#endif
#define _st_sdk_included

// ============================================================================
// SDK MODULE
// Handles SDK calls initialization and wrappers
// ============================================================================

/**
 * Initialize all SDK calls
 * Called from OnPluginStart()
 *
 * Requires gamedata file: addons/sourcemod/gamedata/supertanks.txt
 *
 * SDK Calls initialized:
 * - CSpitterProjectile_Detonate: Makes spitter projectiles explode
 * - Infected_OnHitByVomitJar: Applies vomit jar effect to infected
 * - IsMissionFinalMap: Checks if current map is a finale map
 */
stock ST_SDK_Init()
{
	new Handle:ConfigFile = LoadGameConfigFile("supertanks");
	new Handle:MySDKCall = INVALID_HANDLE;

	/////////////
	// SpitBurst
	/////////////
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CSpitterProjectile_Detonate");
	MySDKCall = EndPrepSDKCall();
	if (MySDKCall == INVALID_HANDLE)
	{
		SetFailState("Cant initialize CSpitterProjectile_Detonate SDKCall");
	}
	SDKSpitBurst = CloneHandle(MySDKCall, SDKSpitBurst);

	/////////////////////////
	// InfectedHitByVomitJar
	/////////////////////////
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "Infected_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	MySDKCall = EndPrepSDKCall();
	if (MySDKCall == INVALID_HANDLE)
	{
		SetFailState("Cant initialize Infected_OnHitByVomitJar SDKCall");
	}
	SDKInfectedHitByVomitJar = CloneHandle(MySDKCall, SDKInfectedHitByVomitJar);

	//////////////////////
	// IsMissionFinalMap
	//////////////////////
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "IsMissionFinalMap");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	MySDKCall = EndPrepSDKCall();
	if (MySDKCall == INVALID_HANDLE)
	{
		SetFailState("Cant initialize IsMissionFinalMap SDKCall");
	}
	SDKIsMissionFinalMap = CloneHandle(MySDKCall, SDKIsMissionFinalMap);

	CloseHandle(ConfigFile);
	CloseHandle(MySDKCall);
}

// ============================================================================
// SDK CALL WRAPPERS
// ============================================================================

/**
 * Makes a spitter projectile entity explode/detonate
 *
 * @param entity    Entity index of the spitter projectile
 * @noreturn
 */
stock L4D2_SpitBurst(entity)
{
	SDKCall(SDKSpitBurst, entity);
}

/**
 * Applies vomit jar effect to an infected entity
 *
 * @param victim    Entity index of the infected to be vomited
 * @param attacker  Entity index of the attacker (player who threw jar)
 * @noreturn
 */
stock L4D2_InfectedHitByVomitJar(victim, attacker)
{
	SDKCall(SDKInfectedHitByVomitJar, victim, attacker);
}

/**
 * Checks if the current mission is a finale map
 *
 * @return          True if finale map, false otherwise
 */
stock bool:L4D2_IsMissionFinalMap()
{
	return SDKCall(SDKIsMissionFinalMap);
}
