#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === SHOULDER CANNON ACTIVE ABILITY ===
// Cañón montado en el hombro con disparo automático
// Nivel: 7
// Duración: Munición limitada (500 balas)
// Cooldown: No tiene cooldown, pero requiere munición
//==================================================

// =========================
// Models and Sounds
// =========================
#define MODEL_M60 "models/w_models/weapons/w_m60.mdl"
#define SOUND_M60_FIRE "weapons/machinegun_m60/gunfire/machinegun_fire_1.wav"

// =========================
// Particles
// =========================
#define PARTICLE_BLOOD "blood_impact_red_01"
#define PARTICLE_50CAL_TRACER "weapon_tracers_50cal"
#define PARTICLE_RIFLE_FLASH "weapon_muzzle_flash_assaultrifle"

// =========================
// ConVars
// =========================
Handle cvar_ShoulderCannon_RequiredLevel = INVALID_HANDLE;
Handle cvar_ShoulderCannon_MaxAmmo = INVALID_HANDLE;
Handle cvar_ShoulderCannon_FireRate = INVALID_HANDLE;
Handle cvar_ShoulderCannon_Damage = INVALID_HANDLE;
Handle cvar_ShoulderCannon_Range = INVALID_HANDLE;

// =========================
// Estado del jugador
// =========================
int   g_iShoulderCannon_Entity[MAXPLAYERS + 1];
int   g_iShoulderCannon_Ammo[MAXPLAYERS + 1];
bool  g_bShoulderCannon_Disabled[MAXPLAYERS + 1];
bool  g_bShoulderCannon_AutoEquip[MAXPLAYERS + 1];
int   g_iShoulderCannon_NeverTarget[MAXPLAYERS + 1];
int   g_iShoulderCannon_TargetFirst[MAXPLAYERS + 1];
float g_fShoulderCannon_FireRate[MAXPLAYERS + 1];
Handle g_hShoulderCannon_Timer[MAXPLAYERS + 1];

// Constantes
static const char AMMO_CLASSES[][] =
{
	"weapon_ammo_spawn",
	"upgrade_ammo_incendiary",
	"upgrade_ammo_explosive"
};

/**
 * Inicializa el módulo de Shoulder Cannon
 */
public void ShoulderCannon_OnPluginStart()
{
	cvar_ShoulderCannon_RequiredLevel = CreateConVar(
		"ability_shouldercannon_level",
		"1",
		"Nivel requerido para desbloquear Shoulder Cannon",
		FCVAR_PLUGIN
	);

	cvar_ShoulderCannon_MaxAmmo = CreateConVar(
		"ability_shouldercannon_ammo",
		"500",
		"Munición máxima del Shoulder Cannon",
		FCVAR_PLUGIN
	);

	cvar_ShoulderCannon_FireRate = CreateConVar(
		"ability_shouldercannon_firerate",
		"0.15",
		"Velocidad de disparo del Shoulder Cannon",
		FCVAR_PLUGIN
	);

	cvar_ShoulderCannon_Damage = CreateConVar(
		"ability_shouldercannon_damage",
		"12",
		"Daño por disparo del Shoulder Cannon",
		FCVAR_PLUGIN
	);

	cvar_ShoulderCannon_Range = CreateConVar(
		"ability_shouldercannon_range",
		"600.0",
		"Rango de detección del Shoulder Cannon",
		FCVAR_PLUGIN
	);

	// Hook de eventos
	HookEvent("player_use", ShoulderCannon_Event_PlayerUse, EventHookMode_Post);

	// Precache
	PrecacheModel(MODEL_M60, true);
	PrecacheSound(SOUND_M60_FIRE, true);
}

/**
 * Resetea el estado al conectar
 */
public void ShoulderCannon_OnClientConnect(int client)
{
	g_iShoulderCannon_Entity[client] = 0;
	g_iShoulderCannon_Ammo[client] = GetConVarInt(cvar_ShoulderCannon_MaxAmmo);
	g_bShoulderCannon_Disabled[client] = false;
	g_bShoulderCannon_AutoEquip[client] = false;
	g_iShoulderCannon_NeverTarget[client] = 0;
	g_iShoulderCannon_TargetFirst[client] = 0;
	g_fShoulderCannon_FireRate[client] = 0.15; // Default fire rate
	g_hShoulderCannon_Timer[client] = INVALID_HANDLE;
}

/**
 * Limpia recursos al desconectar
 */
public void ShoulderCannon_OnClientDisconnect(int client)
{
	ShoulderCannon_Remove(client);

	if (g_hShoulderCannon_Timer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hShoulderCannon_Timer[client], false);
		g_hShoulderCannon_Timer[client] = INVALID_HANDLE;
	}
}

/**
 * Limpia al morir
 */
public void ShoulderCannon_OnPlayerDeath(int client)
{
	ShoulderCannon_Remove(client);
}

// =========================
// Helper Functions
// =========================

/**
 * Verifica si un jugador está incapacitado
 */
stock bool IsPlayerIncap(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		return true;
	return false;
}

/**
 * Verifica si un jugador está siendo agarrado por un infectado especial
 */
stock bool IsPlayerHeld(int client)
{
	int jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	int charger = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	int hunter = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	int smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");

	if ((jockey > 0 && jockey <= MaxClients) ||
		(charger > 0 && charger <= MaxClients) ||
		(hunter > 0 && hunter <= MaxClients) ||
		(smoker > 0 && smoker <= MaxClients))
	{
		return true;
	}
	return false;
}

/**
 * Verifica si un jugador es un infectado especial
 */
stock bool IsSpecialInfected(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		char classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Smoker", false) || StrEqual(classname, "Boomer", false) ||
			StrEqual(classname, "Hunter", false) || StrEqual(classname, "Spitter", false) ||
			StrEqual(classname, "Jockey", false) || StrEqual(classname, "Charger", false))
		{
			return true;
		}
	}
	return false;
}

// Nota: IsTank, IsPlayerGhost, IsInfected, IsWitch ya están definidas en el core

// =========================
// Main Functions
// =========================

/**
 * Verifica si el jugador puede equipar Shoulder Cannon
 */
public bool ShoulderCannon_CanUse(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_ShoulderCannon_RequiredLevel);

	if (level < requiredLevel)
	{
		PrintToChat(client, "\x05[DEBUG Shoulder Cannon]\x01 Nivel insuficiente: %d/%d", level, requiredLevel);
		return false;
	}

	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		PrintToChat(client, "\x05[DEBUG Shoulder Cannon]\x01 No estás en juego o no estás vivo");
		return false;
	}

	if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "\x05[DEBUG Shoulder Cannon]\x01 Debes estar en el equipo de Survivors (team 2), tu team actual es: %d", GetClientTeam(client));
		return false;
	}

	PrintToChat(client, "\x04[DEBUG Shoulder Cannon]\x01 Todos los requisitos cumplidos!");
	return true;
}

/**
 * Obtiene si el jugador tiene el cañón equipado
 */
public bool ShoulderCannon_HasCannon(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	if (g_iShoulderCannon_Entity[client] > 0 && IsValidEntity(g_iShoulderCannon_Entity[client]))
		return true;

	return false;
}

/**
 * Equipa el Shoulder Cannon
 */
public void ShoulderCannon_Activate(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	if (GetClientTeam(client) != 2)
		return;

	if (g_iShoulderCannon_Entity[client] > 0)
		return;

	// Crear entidad
	int entity = CreateEntityByName("prop_dynamic_override");
	if (entity == -1)
		entity = CreateEntityByName("prop_dynamic");

	if (!IsValidEntity(entity))
		return;

	// Configurar modelo
	DispatchKeyValue(entity, "model", MODEL_M60);
	DispatchKeyValue(entity, "spawnflags", "2");
	DispatchSpawn(entity);
	ActivateEntity(entity);

	// Parentear al jugador
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);
	SetVariantString("eyes");
	AcceptEntityInput(entity, "SetParentAttachment");

	// Configurar propiedades
	AcceptEntityInput(entity, "DisableCollision");
	AcceptEntityInput(entity, "DisableShadow");
	SetEntProp(entity, Prop_Data, "m_iEFlags", 0);
	SetEntPropFloat(entity, Prop_Data, "m_flModelScale", 0.43);

	// Posicionar
	float Origin[3] = {-5.0, -5.0, -6.0};
	float Angles[3] = {-15.0, 0.0, 90.0};
	TeleportEntity(entity, Origin, Angles, NULL_VECTOR);

	g_iShoulderCannon_Entity[client] = entity;

	// Iniciar timer de disparo
	ShoulderCannon_StartRepeater(client);

	// Hook de transmisión
	SDKHook(entity, SDKHook_SetTransmit, ShoulderCannon_Hook_SetTransmit);

	PrintToChat(client, "\x04[Shoulder Cannon]\x01 Equipped! Ammo: \x05%i\x01", g_iShoulderCannon_Ammo[client]);
}

/**
 * Remueve el Shoulder Cannon
 */
public void ShoulderCannon_Remove(int client)
{
	int entity = g_iShoulderCannon_Entity[client];
	if (entity > 0 && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic", false))
		{
			char model[34];
			GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_M60, false))
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
	}

	g_iShoulderCannon_Entity[client] = 0;

	if (g_hShoulderCannon_Timer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hShoulderCannon_Timer[client], false);
		g_hShoulderCannon_Timer[client] = INVALID_HANDLE;
	}
}

/**
 * Hook de transmisión para visibilidad
 */
public Action ShoulderCannon_Hook_SetTransmit(int entity, int client)
{
	return Plugin_Continue;
}

/**
 * Inicia el timer de disparo
 */
stock void ShoulderCannon_StartRepeater(int client)
{
	if (g_fShoulderCannon_FireRate[client] <= 0.0)
		g_fShoulderCannon_FireRate[client] = GetConVarFloat(cvar_ShoulderCannon_FireRate);

	if (g_hShoulderCannon_Timer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hShoulderCannon_Timer[client], false);
		g_hShoulderCannon_Timer[client] = INVALID_HANDLE;
	}

	g_hShoulderCannon_Timer[client] = CreateTimer(g_fShoulderCannon_FireRate[client], ShoulderCannon_Timer_Fire, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Timer de disparo automático
 */
public Action ShoulderCannon_Timer_Fire(Handle timer, any client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	int cannon = g_iShoulderCannon_Entity[client];
	if (cannon <= 0 || !IsValidEntity(cannon))
		return Plugin_Stop;

	// Verificar si está deshabilitado o incapacitado
	if (g_bShoulderCannon_Disabled[client])
		return Plugin_Continue;

	if (IsPlayerIncap(client) || IsPlayerHeld(client))
		return Plugin_Continue;

	int ammo = g_iShoulderCannon_Ammo[client];
	if (ammo <= 0)
	{
		if (ammo == 0)
		{
			g_iShoulderCannon_Ammo[client] = -1;
			PrintToChat(client, "\x04[Shoulder Cannon]\x01 Out of Ammo.");
		}
		return Plugin_Continue;
	}

	// Buscar objetivo
	int target = ShoulderCannon_FindTarget(client);
	if (target > 0)
	{
		ShoulderCannon_FireAtTarget(client, target);
		g_iShoulderCannon_Ammo[client]--;
	}

	return Plugin_Continue;
}

/**
 * Busca un objetivo válido
 */
stock int ShoulderCannon_FindTarget(int client)
{
	float Origin[3], TOrigin[3];
	float storeddist = 0.0, distance = 0.0;
	float range = GetConVarFloat(cvar_ShoulderCannon_Range);
	int targetfirst = g_iShoulderCannon_TargetFirst[client];
	int nevertarget = g_iShoulderCannon_NeverTarget[client];
	int zombie = 0, special = 0, tank = 0, witch = 0;

	GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);

	// Buscar zombies comunes
	if (nevertarget != 1 && nevertarget != 5 && nevertarget != 6)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
		{
			int ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
			if (ragdoll == 0)
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
				distance = GetVectorDistance(Origin, TOrigin);
				if (distance < range)
				{
					if (storeddist == 0.0 || storeddist > distance)
					{
						if (ShoulderCannon_IsVisible(client, entity))
						{
							storeddist = distance;
							zombie = entity;
						}
					}
				}
			}
		}
	}

	// Buscar witches
	if (nevertarget != 3 && nevertarget != 6 && nevertarget != 7)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
		{
			int ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
			if (ragdoll == 0)
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
				distance = GetVectorDistance(Origin, TOrigin);
				if (distance < range)
				{
					if (storeddist == 0.0 || storeddist > distance)
					{
						if (ShoulderCannon_IsVisible(client, entity))
						{
							storeddist = distance;
							witch = entity;
						}
					}
				}
			}
		}
	}

	// Buscar infectados especiales y tanks
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "player")) != INVALID_ENT_REFERENCE)
	{
		if (IsClientInGame(entity) && IsPlayerAlive(entity) && !IsPlayerGhost(entity) && GetClientTeam(entity) == 3)
		{
			if (IsTank(entity) && nevertarget != 4 && nevertarget != 7)
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
				distance = GetVectorDistance(Origin, TOrigin);
				if (distance < range)
				{
					if (storeddist == 0.0 || storeddist > distance)
					{
						if (ShoulderCannon_IsVisible(client, entity))
						{
							storeddist = distance;
							tank = entity;
						}
					}
				}
			}
			else if (IsSpecialInfected(entity) && nevertarget != 2 && nevertarget != 5)
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
				distance = GetVectorDistance(Origin, TOrigin);
				if (distance < range)
				{
					if (storeddist == 0.0 || storeddist > distance)
					{
						if (ShoulderCannon_IsVisible(client, entity))
						{
							storeddist = distance;
							special = entity;
						}
					}
				}
			}
		}
	}

	// Seleccionar objetivo basado en prioridad
	switch(targetfirst)
	{
		case 0: return (zombie > 0) ? zombie : ((special > 0) ? special : ((witch > 0) ? witch : tank));
		case 1: return (special > 0) ? special : ((witch > 0) ? witch : ((tank > 0) ? tank : zombie));
		case 2: return (witch > 0) ? witch : ((tank > 0) ? tank : ((zombie > 0) ? zombie : special));
		case 3: return (tank > 0) ? tank : ((zombie > 0) ? zombie : ((special > 0) ? special : witch));
	}

	return 0;
}

/**
 * Verifica visibilidad del objetivo
 */
stock bool ShoulderCannon_IsVisible(int client, int target)
{
	float fViewPos[3], fViewAng[3], fTargetPos[3];
	float fViewDir[3], fTargetDir[3], fDistance[3];

	GetClientEyePosition(client, fViewPos);
	GetClientEyeAngles(client, fViewAng);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", fTargetPos);
	fTargetPos[2] += 30;

	GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);

	fDistance[0] = fTargetPos[0] - fViewPos[0];
	fDistance[1] = fTargetPos[1] - fViewPos[1];
	fDistance[2] = fTargetPos[2] - fViewPos[2];

	float fDistance_Length = GetVectorLength(fDistance);
	float range = GetConVarFloat(cvar_ShoulderCannon_Range);
	if (fDistance_Length > range)
		return false;

	NormalizeVector(fDistance, fTargetDir);
	float dotProduct = GetVectorDotProduct(fViewDir, fTargetDir);

	if (dotProduct < 0.5)
		return false;

	Handle hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_SOLID, RayType_EndPoint, ShoulderCannon_Filter_Trace);
	bool bBlocked = TR_DidHit(hTrace);
	delete hTrace;

	return !bBlocked;
}

/**
 * Filtro para raycast
 */
public bool ShoulderCannon_Filter_Trace(int Entity, int Mask, any Junk)
{
	if (Entity <= MaxClients)
		return false;

	if (GetEntProp(Entity, Prop_Data, "m_iHealth") > 0)
	{
		char classname[16];
		GetEdictClassname(Entity, classname, sizeof(classname));

		if (StrEqual(classname, "infected") || StrEqual(classname, "witch"))
			return false;
	}

	return true;
}

/**
 * Dispara al objetivo
 */
stock void ShoulderCannon_FireAtTarget(int client, int target)
{
	int cannon = g_iShoulderCannon_Entity[client];
	if (cannon <= 0 || !IsValidEntity(cannon))
		return;

	// Efectos visuales
	ShoulderCannon_ShowMuzzleFlash(cannon);
	ShoulderCannon_AttachParticle(target, PARTICLE_BLOOD, 0.1, 0.0, 0.0, 30.0);
	ShoulderCannon_CreateTracerParticles(cannon, target);
	EmitSoundToAll(SOUND_M60_FIRE, client);

	// Aplicar daño
	int damage = GetConVarInt(cvar_ShoulderCannon_Damage);
	bool isPlayer = (target > 0 && target <= MaxClients);

	if (isPlayer)
		ShoulderCannon_DealDamagePlayer(target, client, 2, damage);
	else
		ShoulderCannon_DealDamageEntity(target, client, 2, damage);
}

/**
 * Aplica daño a jugador
 */
stock void ShoulderCannon_DealDamagePlayer(int target, int attacker, int dmgtype, int dmg)
{
	if (target <= 0 || target > MaxClients)
		return;

	if (!IsClientInGame(target) || !IsPlayerAlive(target))
		return;

	char damage[16], type[16];
	IntToString(dmg, damage, sizeof(damage));
	IntToString(dmgtype, type, sizeof(type));

	int pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt > 0)
	{
		DispatchKeyValue(target, "targetname", "hurtme");
		DispatchKeyValue(pointHurt, "Damage", damage);
		DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
		DispatchKeyValue(pointHurt, "DamageType", type);
		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", (attacker > 0 && IsClientInGame(attacker)) ? attacker : -1);
		AcceptEntityInput(pointHurt, "Kill");
		DispatchKeyValue(target, "targetname", "");
	}
}

/**
 * Aplica daño a entidad
 */
stock void ShoulderCannon_DealDamageEntity(int target, int attacker, int dmgtype, int dmg)
{
	if (target <= 32 || !IsValidEntity(target))
		return;

	if (!(IsInfected(target) || IsWitch(target)))
		return;

	int ragdoll = GetEntProp(target, Prop_Data, "m_bClientSideRagdoll");
	if (ragdoll != 0)
		return;

	if (IsInfected(target))
	{
		int health = GetEntProp(target, Prop_Data, "m_iHealth");
		if (health <= dmg)
		{
			SetEntProp(target, Prop_Send, "m_iRequestedWound1", GetRandomInt(21, 25));
			SetEntProp(target, Prop_Data, "m_bClientSideRagdoll", 1);
		}
	}

	char damage[16], type[16];
	IntToString(dmg, damage, sizeof(damage));
	IntToString(dmgtype, type, sizeof(type));

	int pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt > 0)
	{
		DispatchKeyValue(target, "targetname", "hurtme");
		DispatchKeyValue(pointHurt, "Damage", damage);
		DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
		DispatchKeyValue(pointHurt, "DamageType", type);
		DispatchSpawn(pointHurt);
		if (IsClientInGame(attacker))
		{
			AcceptEntityInput(pointHurt, "Hurt", attacker);
		}
		AcceptEntityInput(pointHurt, "Kill");
		DispatchKeyValue(target, "targetname", "");
	}
}

/**
 * Crea efecto de destello del cañón
 */
stock void ShoulderCannon_ShowMuzzleFlash(int target)
{
	if (target <= 0 || !IsValidEntity(target))
		return;

	int particle = CreateEntityByName("info_particle_system");
	if (particle > 0 && IsValidEntity(particle))
	{
		float Origin[3], Angles[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", Origin);
		DispatchKeyValue(particle, "effect_name", PARTICLE_RIFLE_FLASH);
		DispatchKeyValueVector(particle, "origin", Origin);
		DispatchKeyValueVector(particle, "angles", Angles);
		DispatchSpawn(particle);
		ActivateEntity(particle);

		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", target);
		SetVariantString("muzzle_flash");
		AcceptEntityInput(particle, "SetParentAttachment");
		AcceptEntityInput(particle, "Enable");
		AcceptEntityInput(particle, "start");
		GetEntPropVector(particle, Prop_Send, "m_angRotation", Angles);
		Angles[0] -= 90.0;
		TeleportEntity(particle, NULL_VECTOR, Angles, NULL_VECTOR);
		SetVariantString("OnUser1 !self:Kill::0.1:-1");
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
		AcceptEntityInput(particle, "ClearParent");
	}
}

/**
 * Crea trazador de bala
 */
stock void ShoulderCannon_CreateTracerParticles(int entity, int target)
{
	if (entity <= 32 || !IsValidEntity(entity) || target <= 0 || !IsValidEntity(target))
		return;

	char name[8];
	float Origin[3], TOrigin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", TOrigin);
	TOrigin[2] += 30.0;

	int endpoint = CreateEntityByName("info_particle_target");
	if (endpoint > 0 && IsValidEntity(endpoint))
	{
		Format(name, sizeof(name), "cpt%i", endpoint);
		DispatchKeyValue(endpoint, "targetname", name);
		DispatchKeyValueVector(endpoint, "origin", TOrigin);
		DispatchSpawn(endpoint);
		ActivateEntity(endpoint);
		SetVariantString("OnUser1 !self:Kill::0.1:-1");
		AcceptEntityInput(endpoint, "AddOutput");
		AcceptEntityInput(endpoint, "FireUser1");
	}

	int particle = CreateEntityByName("info_particle_system");
	if (particle > 0 && IsValidEntity(particle))
	{
		DispatchKeyValue(particle, "effect_name", PARTICLE_50CAL_TRACER);
		DispatchKeyValue(particle, "cpoint1", name);
		DispatchKeyValueVector(particle, "origin", Origin);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", entity);
		SetVariantString("muzzle_flash");
		AcceptEntityInput(particle, "SetParentAttachment");
		AcceptEntityInput(particle, "start");
		SetVariantString("OnUser1 !self:Kill::0.1:-1");
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
		AcceptEntityInput(particle, "ClearParent");
	}
}

/**
 * Adjunta partícula a entidad
 */
stock void ShoulderCannon_AttachParticle(int target, const char[] ParticleName, float time, float x, float y, float z)
{
	if (target <= 0 || !IsValidEntity(target))
		return;

	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		char text[28];
		float Origin[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", Origin);
		Origin[0] += x;
		Origin[1] += y;
		Origin[2] += z;
		TeleportEntity(particle, Origin, NULL_VECTOR, NULL_VECTOR);

		DispatchKeyValue(particle, "effect_name", ParticleName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", target);
		AcceptEntityInput(particle, "Enable");
		AcceptEntityInput(particle, "start");
		Format(text, sizeof(text), "OnUser1 !self:Kill::%f:-1", time);
		SetVariantString(text);
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
	}
}

/**
 * Evento player_use para recargar munición
 */
public Action ShoulderCannon_Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client <= 0 || !IsClientInGame(client))
		return Plugin_Continue;

	if (!ShoulderCannon_HasCannon(client))
		return Plugin_Continue;

	int target = event.GetInt("targetid");
	if (!IsValidEntity(target))
		return Plugin_Continue;

	char cls[64];
	GetEntityClassname(target, cls, sizeof(cls));

	if (IsAmmoClass(cls) || StrContains(cls, "ammo", false) != -1 || StrContains(cls, "upgrade", false) != -1)
	{
		int maxAmmo = GetConVarInt(cvar_ShoulderCannon_MaxAmmo);
		g_iShoulderCannon_Ammo[client] = maxAmmo;
		PrintToChat(client, "\x04[Shoulder Cannon]\x01 Ammo refilled! (\x05%i\x01)", maxAmmo);
	}

	return Plugin_Continue;
}

/**
 * Verifica si la clase es de munición
 */
stock bool IsAmmoClass(const char[] classname)
{
	for (int i = 0; i < sizeof(AMMO_CLASSES); i++)
	{
		if (StrEqual(classname, AMMO_CLASSES[i], false))
			return true;
	}
	return false;
}

/**
 * Obtiene la munición restante
 */
public int ShoulderCannon_GetAmmo(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	return g_iShoulderCannon_Ammo[client];
}

/**
 * Establece la munición
 */
public void ShoulderCannon_SetAmmo(int client, int ammo)
{
	if (client <= 0 || client > MaxClients)
		return;

	g_iShoulderCannon_Ammo[client] = ammo;
}

/**
 * Obtiene si está activo
 */
public bool ShoulderCannon_IsActive(int client)
{
	return ShoulderCannon_HasCannon(client);
}

/**
 * Abre el menú de configuración del Shoulder Cannon
 */
public void ShoulderCannon_OpenMenu(int client)
{
	if (!IsClientInGame(client))
		return;

	char name[64];
	char text[128];
	bool hasCannon = ShoulderCannon_HasCannon(client);
	bool disabled = g_bShoulderCannon_Disabled[client];
	bool autoEquip = g_bShoulderCannon_AutoEquip[client];
	int neverTarget = g_iShoulderCannon_NeverTarget[client];
	int targetFirst = g_iShoulderCannon_TargetFirst[client];
	float fireRate = g_fShoulderCannon_FireRate[client];

	Menu menu = new Menu(ShoulderCannon_MenuHandler);
	Format(text, sizeof(text), "Shoulder Cannon Menu\n====================\nMunición: %i\n====================", g_iShoulderCannon_Ammo[client]);
	menu.SetTitle(text);

	// 1. Opción de equipar/desequipar
	if (!hasCannon)
	{
		Format(name, sizeof(name), "[ ] Equipar Shoulder Cannon");
		menu.AddItem("equip", name);
	}
	else
	{
		Format(name, sizeof(name), "[X] Equipar Shoulder Cannon");
		menu.AddItem("unequip", name);

		// 2. Auto Equip
		if (autoEquip)
			Format(name, sizeof(name), "[X] Auto Equip Cannon");
		else
			Format(name, sizeof(name), "[ ] Auto Equip Cannon");
		menu.AddItem("autoequip", name);

		// 3. Disable Cannon
		if (disabled)
			Format(name, sizeof(name), "[X] Disable Cannon");
		else
			Format(name, sizeof(name), "[ ] Disable Cannon");
		menu.AddItem("disable", name);

		// 4. Never Target
		switch(neverTarget)
		{
			case 0: Format(name, sizeof(name), "[None] Never Target");
			case 1: Format(name, sizeof(name), "[Commons] Never Target");
			case 2: Format(name, sizeof(name), "[Specials] Never Target");
			case 3: Format(name, sizeof(name), "[Witches] Never Target");
			case 4: Format(name, sizeof(name), "[Tanks] Never Target");
			case 5: Format(name, sizeof(name), "[Commons/Specials] Never Target");
			case 6: Format(name, sizeof(name), "[Commons/Witches] Never Target");
			case 7: Format(name, sizeof(name), "[Witches/Tanks] Never Target");
		}
		menu.AddItem("nevertarget", name);

		// 5. Target First
		switch(targetFirst)
		{
			case 0: Format(name, sizeof(name), "[Commons] Target First");
			case 1: Format(name, sizeof(name), "[Specials] Target First");
			case 2: Format(name, sizeof(name), "[Witches] Target First");
			case 3: Format(name, sizeof(name), "[Tanks] Target First");
		}
		menu.AddItem("targetfirst", name);

		// 6. Fire Rate
		if (fireRate == 0.05)
			Format(name, sizeof(name), "[+0.05] Fastest Fire Rate");
		else if (fireRate == 0.10)
			Format(name, sizeof(name), "[+0.10] Faster Fire Rate");
		else if (fireRate == 0.15)
			Format(name, sizeof(name), "[+0.15] Default Fire Rate");
		else if (fireRate == 0.20)
			Format(name, sizeof(name), "[+0.20] Slower Fire Rate");
		else if (fireRate == 0.25)
			Format(name, sizeof(name), "[+0.25] Slowest Fire Rate");
		else
			Format(name, sizeof(name), "[+%.2f] Fire Rate", fireRate);
		menu.AddItem("firerate", name);
	}

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menú de Shoulder Cannon
 */
public int ShoulderCannon_MenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));

		if (StrEqual(info, "equip"))
		{
			if (!ShoulderCannon_HasCannon(client) && IsPlayerAlive(client))
			{
				ShoulderCannon_Activate(client);
			}
			ShoulderCannon_OpenMenu(client);
		}
		else if (StrEqual(info, "unequip"))
		{
			ShoulderCannon_Remove(client);
			PrintToChat(client, "\x05[Shoulder Cannon]\x01 Desequipado.");
			ShoulderCannon_OpenMenu(client);
		}
		else if (StrEqual(info, "autoequip"))
		{
			g_bShoulderCannon_AutoEquip[client] = !g_bShoulderCannon_AutoEquip[client];
			PrintToChat(client, "\x04[Shoulder Cannon]\x01 Auto Equip: %s", g_bShoulderCannon_AutoEquip[client] ? "Activado" : "Desactivado");
			ShoulderCannon_OpenMenu(client);
		}
		else if (StrEqual(info, "disable"))
		{
			g_bShoulderCannon_Disabled[client] = !g_bShoulderCannon_Disabled[client];
			PrintToChat(client, "\x04[Shoulder Cannon]\x01 Disparo: %s", g_bShoulderCannon_Disabled[client] ? "Deshabilitado" : "Habilitado");
			ShoulderCannon_OpenMenu(client);
		}
		else if (StrEqual(info, "nevertarget"))
		{
			// Cycle through never target options
			g_iShoulderCannon_NeverTarget[client]++;
			if (g_iShoulderCannon_NeverTarget[client] > 7)
				g_iShoulderCannon_NeverTarget[client] = 0;
			ShoulderCannon_OpenMenu(client);
		}
		else if (StrEqual(info, "targetfirst"))
		{
			// Cycle through target first options
			g_iShoulderCannon_TargetFirst[client]++;
			if (g_iShoulderCannon_TargetFirst[client] > 3)
				g_iShoulderCannon_TargetFirst[client] = 0;
			ShoulderCannon_OpenMenu(client);
		}
		else if (StrEqual(info, "firerate"))
		{
			// Cycle through fire rates
			if (g_fShoulderCannon_FireRate[client] == 0.05)
				g_fShoulderCannon_FireRate[client] = 0.10;
			else if (g_fShoulderCannon_FireRate[client] == 0.10)
				g_fShoulderCannon_FireRate[client] = 0.15;
			else if (g_fShoulderCannon_FireRate[client] == 0.15)
				g_fShoulderCannon_FireRate[client] = 0.20;
			else if (g_fShoulderCannon_FireRate[client] == 0.20)
				g_fShoulderCannon_FireRate[client] = 0.25;
			else
				g_fShoulderCannon_FireRate[client] = 0.05;

			// Restart timer with new fire rate
			if (ShoulderCannon_HasCannon(client))
				ShoulderCannon_StartRepeater(client);

			ShoulderCannon_OpenMenu(client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		// Si presionan Exit Back, podrían regresar al menú de habilidades
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}
