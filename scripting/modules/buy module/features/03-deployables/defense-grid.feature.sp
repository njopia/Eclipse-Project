#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === DEFENSE GRID DEPLOYABLE ===
// Sistema de defensa electrica que repele enemigos
//==================================================

// Models
#define MODEL_DEFENSEGRID		  "models/props_shacks/bug_lamp01.mdl"
#define MODEL_DEFENSEGRID_BASE	  "models/props_interiors/makeshift_stove_battery.mdl"
#define MODEL_DEFENSEGRID_SPHERE  "models/props_unique/airport/atlas_break_ball.mdl"

// Particles
#define PARTICLE_DEFENSEGRID_GLOW "electrical_arc_01_cp0"
#define PARTICLE_LS_BOLT		  "electrical_arc_01_system"

// Sounds
#define SOUND_ZAP1				  "ambient/energy/zap5.wav"
#define SOUND_ZAP2				  "ambient/energy/zap6.wav"
#define SOUND_ZAP3				  "ambient/energy/zap7.wav"
#define SOUND_ZAP4				  "ambient/energy/zap8.wav"
#define SOUND_ZAP5				  "ambient/energy/zap9.wav"

// Configuration
#define DEFENSEGRID_MAX_DURATION  300	   // 5 minutos de duracion
#define DEFENSEGRID_COOLDOWN	  300.0	   // 5 minutos de cooldown
#define DEFENSEGRID_LOG_FILE	  "logs/defense_grid_debug.log"

// Global arrays
static int	 g_iDefenseGridEnt[MAXPLAYERS + 1][6];	  // [0]=base, [1]=lamp, [2-5]=triggers
static int	 g_iDefenseGridTimer[MAXPLAYERS + 1];	  // Duracion restante del deployable
static bool	 g_bDefenseGridReady[MAXPLAYERS + 1];	  // true = puede desplegar
static float g_fDefenseGridCooldownEnd[MAXPLAYERS + 1];
// Logging
static char	 g_sLogPath[PLATFORM_MAX_PATH];

// ============================================================================
// Logging
// ============================================================================

void		 DefenseGrid_Log(const char[] format, any...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);
	PrintToServer("[DEFENSE GRID] %s", buffer);
	LogToFile(g_sLogPath, "%s", buffer);
}

// ============================================================================
// Lifecycle
// ============================================================================
public void DefenseGrid_OnMapStart()
{
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), DEFENSEGRID_LOG_FILE);
	DefenseGrid_Log("=== Defense Grid Debug Log Initialized ===");

	PrecacheModel(MODEL_DEFENSEGRID, true);
	PrecacheModel(MODEL_DEFENSEGRID_BASE, true);
	PrecacheModel(MODEL_DEFENSEGRID_SPHERE, true);

	PrecacheSound(SOUND_ZAP1, true);
	PrecacheSound(SOUND_ZAP2, true);
	PrecacheSound(SOUND_ZAP3, true);
	PrecacheSound(SOUND_ZAP4, true);
	PrecacheSound(SOUND_ZAP5, true);

	DefenseGrid_PrecacheParticle(PARTICLE_DEFENSEGRID_GLOW);
	DefenseGrid_PrecacheParticle(PARTICLE_LS_BOLT);
}

public void DefenseGrid_OnClientConnect(int client)
{
	for (int i = 0; i < 6; i++)
		g_iDefenseGridEnt[client][i] = 0;

	g_iDefenseGridTimer[client] = 0;
	g_bDefenseGridReady[client] = true;
}

public void DefenseGrid_OnClientDisconnect(int client)
{
	DefenseGrid_Destroy(client);
	g_iDefenseGridTimer[client] = 0;
	g_bDefenseGridReady[client] = true;
}

// ============================================================================
// API publica
// ============================================================================

/**
 * Resetea el cooldown — llamar solo en cambio de mapa.
 * NO llamar en player_spawn (cooldown de 5min es intencional entre spawns).
 */
stock void DefenseGrid_ResetCooldown(int client)
{
	g_bDefenseGridReady[client] = true;
	g_iDefenseGridTimer[client] = 0;
}

public bool DefenseGrid_IsActive(int client)
{
	return (g_iDefenseGridEnt[client][0] > 0 && IsValidEntity(g_iDefenseGridEnt[client][0]));
}

public int DefenseGrid_GetTimeRemaining(int client)
{
	return g_iDefenseGridTimer[client];
}

// ============================================================================
// Deploy
// ============================================================================
public bool DefenseGrid_CanDeploy(int client)
{
	if (!g_bDefenseGridReady[client])
	{
		PrintToChat(client, "\x04[Defense Grid]\x01 Aun en cooldown.");
		return false;
	}

	if (!(GetEntityFlags(client) & FL_ONGROUND))
	{
		PrintToChat(client, "\x04[Defense Grid]\x01 Debes estar en el suelo para desplegar esto.");
		return false;
	}

	if (DefenseGrid_IsActive(client))
	{
		PrintToChat(client, "\x04[Defense Grid]\x01 Ya tienes un Defense Grid activo.");
		return false;
	}

	return true;
}

public void DefenseGrid_Deploy(int client)
{
	if (!DefenseGrid_CanDeploy(client))
		return;

	float origin[3], angles[3], direction[3];
	GetClientAbsOrigin(client, origin);
	GetClientEyeAngles(client, angles);
	GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);

	origin[0] += direction[0] * 32.0;
	origin[1] += direction[1] * 32.0;
	origin[2] += direction[2] * 1.0;
	angles[0]  = 0.0;
	angles[2]  = 0.0;

	// Crear base
	int entity = CreateEntityByName("prop_dynamic_override");
	if (entity > 0 && IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "model", MODEL_DEFENSEGRID_BASE);
		DispatchKeyValueVector(entity, "Origin", origin);
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "DisableCollision");
		AcceptEntityInput(entity, "DisableShadow");
		g_iDefenseGridEnt[client][0] = entity;
		g_iDefenseGridTimer[client]	 = DEFENSEGRID_MAX_DURATION;

		// Crear lampara
		entity						 = CreateEntityByName("prop_dynamic_override");
		if (entity > 0 && IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", MODEL_DEFENSEGRID);
			DispatchKeyValueVector(entity, "Origin", origin);
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision");
			AcceptEntityInput(entity, "DisableShadow");

			int glowcolor = RGB_TO_INT(255, 255, 255);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", glowcolor);
			SetEntProp(entity, Prop_Send, "m_iGlowType", 2);

			float tempOrigin[3];
			tempOrigin[0] = origin[0] - 2.0;
			tempOrigin[1] = origin[1] - 6.5;
			tempOrigin[2] = origin[2] + 17.0;
			TeleportEntity(entity, tempOrigin, NULL_VECTOR, NULL_VECTOR);
			g_iDefenseGridEnt[client][1] = entity;

			// Crear 4 triggers en cruz
			DefenseGrid_CreateTriggerPush(client, origin, 2, "0 45 0", 55.0, 55.0);
			DefenseGrid_CreateTriggerPush(client, origin, 3, "0 -45 0", 55.0, -55.0);
			DefenseGrid_CreateTriggerPush(client, origin, 4, "0 135 0", -55.0, 55.0);
			DefenseGrid_CreateTriggerPush(client, origin, 5, "0 -135 0", -55.0, -55.0);
		}
	}

	// Marcar no disponible e iniciar cooldown
	g_bDefenseGridReady[client]		  = false;
	g_fDefenseGridCooldownEnd[client] = GetGameTime() + DEFENSEGRID_COOLDOWN;
	CreateTimer(DEFENSEGRID_COOLDOWN, _Timer_DefenseGridCooldown, client);

	DefenseGrid_Log("Deployed by %N at [%.1f, %.1f, %.1f]", client, origin[0], origin[1], origin[2]);
	PrintToChat(client, "\x04[Defense Grid]\x01 Desplegado. Duracion: \x03%d\x01 segundos.", DEFENSEGRID_MAX_DURATION);
}

// ============================================================================
// Timer de cooldown
// ============================================================================
public Action _Timer_DefenseGridCooldown(Handle timer, any client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		g_bDefenseGridReady[client] = true;
		PrintToChat(client, "\x04[Defense Grid]\x01 Ya puedes desplegar otro.");
	}
	return Plugin_Stop;
}

// ============================================================================
// Triggers
// ============================================================================

void DefenseGrid_CreateTriggerPush(int client, float origin[3], int slot, const char[] pushdir, float offsetX, float offsetY)
{
	int entity = CreateEntityByName("trigger_push");
	DefenseGrid_Log("Creating trigger_push slot %d, entity: %d", slot, entity);

	if (entity > 0 && IsValidEntity(entity))
	{
		float minbounds[3] = { -55.0, -55.0, 0.0 };
		float maxbounds[3] = { 55.0, 55.0, 155.0 };
		float triggerOrigin[3];

		triggerOrigin[0] = origin[0] + offsetX;
		triggerOrigin[1] = origin[1] + offsetY;
		triggerOrigin[2] = origin[2];

		DispatchKeyValueVector(entity, "Origin", triggerOrigin);
		DispatchKeyValue(entity, "spawnflags", "1");
		DispatchKeyValue(entity, "speed", "0");
		DispatchKeyValue(entity, "pushdir", pushdir);

		bool spawned = DispatchSpawn(entity);
		DefenseGrid_Log("Trigger slot %d spawn result: %d", slot, spawned);

		ActivateEntity(entity);

		SetEntPropVector(entity, Prop_Send, "m_vecMins", minbounds);
		SetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxbounds);

		int enteffects = GetEntProp(entity, Prop_Send, "m_fEffects");
		enteffects |= 32;
		SetEntProp(entity, Prop_Send, "m_fEffects", enteffects);
		SetEntProp(entity, Prop_Send, "m_nSolidType", 2);

		SDKHook(entity, SDKHook_StartTouch, DefenseGrid_OnTouch);
		TeleportEntity(entity, triggerOrigin, NULL_VECTOR, NULL_VECTOR);

		g_iDefenseGridEnt[client][slot] = entity;
		DefenseGrid_Log("Trigger slot %d created at [%.1f, %.1f, %.1f]", slot, triggerOrigin[0], triggerOrigin[1], triggerOrigin[2]);
	}
	else
	{
		DefenseGrid_Log("FAILED to create trigger_push for slot %d", slot);
	}
}

// ============================================================================
// Touch handler
// ============================================================================
public Action DefenseGrid_OnTouch(int caller, int activator)
{
	if (activator <= 0 || !IsValidEntity(activator))
		return Plugin_Continue;

	DefenseGrid_Log("OnTouch - Caller: %d, Activator: %d", caller, activator);

	int owner = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		for (int j = 2; j <= 5; j++)
		{
			if (g_iDefenseGridEnt[i][j] == caller)
			{
				owner = i;
				break;
			}
		}
		if (owner > 0) break;
	}

	if (owner <= 0 || !IsClientInGame(owner))
		return Plugin_Continue;

	int damageType = DefenseGrid_GetDamageType(owner, activator);
	if (damageType > 0)
		DefenseGrid_AwardXP(owner, damageType);

	return Plugin_Continue;
}

// ============================================================================
// Damage / enemy handling
// ============================================================================

int DefenseGrid_GetDamageType(int owner, int entity)
{
	// Sobreviviente — ignorar
	if (entity > 0 && entity <= MaxClients && IsClientInGame(entity) && GetClientTeam(entity) == 2)
		return 0;

	// Infected especial / Tank
	if (entity > 0 && entity <= MaxClients && IsClientInGame(entity) && GetClientTeam(entity) == 3)
	{
		int zombieClass = GetEntProp(entity, Prop_Send, "m_zombieClass");
		DefenseGrid_Log("Infected - Entity: %d, Class: %d", entity, zombieClass);

		if (zombieClass == 8)
		{
			DefenseGrid_FlingInfected(owner, entity, 600.0);
			return 2;	 // Tank
		}
		else if (zombieClass >= 1 && zombieClass <= 6)
		{
			DefenseGrid_FlingInfected(owner, entity, 700.0);
			return 1;	 // Special infected
		}
	}

	// Entidades
	char classname[32];
	GetEdictClassname(entity, classname, sizeof(classname));

	if (StrEqual(classname, "spitter_projectile", false))
	{
		AcceptEntityInput(entity, "Kill");
		return 3;
	}
	else if (StrEqual(classname, "tank_rock", false))
	{
		AcceptEntityInput(entity, "Kill");
		return 4;
	}
	else if (StrEqual(classname, "infected", false))
	{
		DefenseGrid_DealDamageEntity(entity, 1000);
		return 6;	 // Common infected
	}
	else if (StrEqual(classname, "witch", false))
	{
		DefenseGrid_DealDamageEntity(entity, 10000);
		return 8;	 // Witch
	}

	return 0;
}

/**
 * Otorga currency al dueno segun el tipo de enemigo bloqueado.
 */
void DefenseGrid_AwardXP(int client, int type)
{
	int xpAmount = 0;
	switch (type)
	{
		case 1: xpAmount = 4;	   // Special Infected repelido
		case 2: xpAmount = 6;	   // Tank repelido
		case 3: xpAmount = 3;	   // Spitter projectile
		case 4: xpAmount = 3;	   // Tank rock
		case 6: xpAmount = 5;	   // Common infected
		case 8: xpAmount = 100;	   // Witch
	}

	if (xpAmount <= 0)
		return;

	int currencyAmount = xpAmount / 2;
	if (currencyAmount > 0)
		AwardCurrency(client, currencyAmount, "Defense Grid Reward");

	char typename[64];
	switch (type)
	{
		case 1: typename = "Special Infected Repelido";
		case 2: typename = "Tank Repelido";
		case 3: typename = "Proyectil de Spitter Destruido";
		case 4: typename = "Roca de Tank Destruida";
		case 6: typename = "Zombie Eliminado";
		case 8: typename = "Witch Eliminada";
	}

	PrintToChat(client, "\x04[Defense Grid]\x01 %s: \x03+%d\x01 puntos", typename, currencyAmount);
}

// ============================================================================
// Update (llamado desde UpdateTimers cada segundo)
// ============================================================================
public void DefenseGrid_Update(int client)
{
	int entity = g_iDefenseGridEnt[client][1];
	if (entity > 0 && IsValidEntity(entity))
	{
		if (g_iDefenseGridTimer[client] <= 20)
			SetEntProp(entity, Prop_Send, "m_bFlashing", 1);

		DefenseGrid_ExecuteEffects(client);
		CreateTimer(0.3, Timer_DefenseGridEffects, client, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.5, Timer_DefenseGridEffects, client, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.7, Timer_DefenseGridEffects, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	g_iDefenseGridTimer[client]--;

	if (g_iDefenseGridTimer[client] <= 0)
	{
		DefenseGrid_Destroy(client);
		PrintToChat(client, "\x04[Defense Grid]\x01 Tu Defense Grid ha expirado.");
	}
}

public Action Timer_DefenseGridEffects(Handle timer, int client)
{
	DefenseGrid_ExecuteEffects(client);
	return Plugin_Stop;
}

void DefenseGrid_ExecuteEffects(int client)
{
	int entity = g_iDefenseGridEnt[client][1];
	if (entity > 0 && IsValidEntity(entity))
	{
		AttachParticle(entity, PARTICLE_DEFENSEGRID_GLOW, 0.5, 0.0, 0.0, 12.0);
		DefenseGrid_CreateBolt(entity);
	}
}

// ============================================================================
// Destroy
// ============================================================================
public void DefenseGrid_Destroy(int client)
{
	for (int i = 0; i < 6; i++)
	{
		int entity = g_iDefenseGridEnt[client][i];
		if (entity > 0 && IsValidEntity(entity))
			AcceptEntityInput(entity, "Kill");
		g_iDefenseGridEnt[client][i] = 0;
	}
	g_iDefenseGridTimer[client] = 0;
}

// ============================================================================
// Visual effects
// ============================================================================

void DefenseGrid_CreateBolt(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity))
		return;

	float origin[3], targetOrigin[3], angles[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);

	angles[0] = GetRandomFloat(-360.0, 360.0);
	angles[1] = GetRandomFloat(-360.0, 360.0);
	angles[2] = 0.0;

	GetAngleVectors(angles, targetOrigin, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(targetOrigin, targetOrigin);
	ScaleVector(targetOrigin, 110.0);
	AddVectors(origin, targetOrigin, targetOrigin);

	int endpoint = CreateEntityByName("info_particle_target");
	if (endpoint > 0 && IsValidEntity(endpoint))
	{
		char name[32];
		Format(name, sizeof(name), "bolt_target%d", endpoint);
		DispatchKeyValue(endpoint, "targetname", name);
		DispatchKeyValueVector(endpoint, "origin", targetOrigin);
		DispatchSpawn(endpoint);
		ActivateEntity(endpoint);

		SetVariantString("OnUser1 !self:Kill::0.4:-1");
		AcceptEntityInput(endpoint, "AddOutput");
		AcceptEntityInput(endpoint, "FireUser1");

		int particle = CreateEntityByName("info_particle_system");
		if (particle > 0 && IsValidEntity(particle))
		{
			DispatchKeyValue(particle, "effect_name", PARTICLE_LS_BOLT);
			DispatchKeyValue(particle, "cpoint1", name);
			DispatchKeyValueVector(particle, "origin", origin);
			DispatchSpawn(particle);
			ActivateEntity(particle);

			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity);
			AcceptEntityInput(particle, "start");

			SetVariantString("OnUser1 !self:Kill::0.4:-1");
			AcceptEntityInput(particle, "AddOutput");
			AcceptEntityInput(particle, "FireUser1");
		}

		int random = GetRandomInt(1, 5);
		switch (random)
		{
			case 1: EmitSoundToAll(SOUND_ZAP1, endpoint);
			case 2: EmitSoundToAll(SOUND_ZAP2, endpoint);
			case 3: EmitSoundToAll(SOUND_ZAP3, endpoint);
			case 4: EmitSoundToAll(SOUND_ZAP4, endpoint);
			case 5: EmitSoundToAll(SOUND_ZAP5, endpoint);
		}
	}
}

void AttachParticle(int target, const char[] particleName, float lifetime, float x, float y, float z)
{
	if (target <= 0 || !IsValidEntity(target))
		return;

	int particle = CreateEntityByName("info_particle_system");
	if (particle > 0 && IsValidEntity(particle))
	{
		float pos[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
		pos[0] += x;
		pos[1] += y;
		pos[2] += z;

		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

		char tName[64];
		Format(tName, sizeof(tName), "target%d", target);
		DispatchKeyValue(target, "targetname", tName);
		DispatchKeyValue(particle, "effect_name", particleName);
		DispatchKeyValue(particle, "parentname", tName);
		DispatchSpawn(particle);
		ActivateEntity(particle);

		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle);
		AcceptEntityInput(particle, "start");

		CreateTimer(lifetime, Timer_DeleteAttachedParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_DeleteAttachedParticle(Handle timer, int particle)
{
	if (IsValidEntity(particle))
		AcceptEntityInput(particle, "Kill");
	return Plugin_Stop;
}

// ============================================================================
// Precache helper
// ============================================================================

void DefenseGrid_PrecacheParticle(const char[] particleName)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particleName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.3, Timer_DeletePrecacheParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_DeletePrecacheParticle(Handle timer, int particle)
{
	if (IsValidEntity(particle))
		AcceptEntityInput(particle, "Kill");
	return Plugin_Stop;
}

// ============================================================================
// Fling / damage helpers
// ============================================================================

void DefenseGrid_FlingInfected(int owner, int victim, float force)
{
	DefenseGrid_Log("FlingInfected - Owner: %d, Victim: %d, Force: %.1f", owner, victim, force);

	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
		return;

	float ownerPos[3], victimPos[3];

	int	  gridEntity = g_iDefenseGridEnt[owner][0];
	if (gridEntity > 0 && IsValidEntity(gridEntity))
		GetEntPropVector(gridEntity, Prop_Send, "m_vecOrigin", ownerPos);
	else
		GetClientAbsOrigin(owner, ownerPos);

	GetClientAbsOrigin(victim, victimPos);

	float traceVec[3], resultingFling[3];
	MakeVectorFromPoints(ownerPos, victimPos, traceVec);
	GetVectorAngles(traceVec, resultingFling);

	resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * force;
	resultingFling[1] = Sine(DegToRad(resultingFling[1])) * force;
	resultingFling[2] = force * 0.8;

	float currentVel[3];
	GetEntPropVector(victim, Prop_Data, "m_vecVelocity", currentVel);
	AddVectors(resultingFling, currentVel, resultingFling);

	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, resultingFling);
	L4D_StaggerPlayer(victim, owner, resultingFling);
}

void DefenseGrid_DealDamageEntity(int target, int damage)
{
	if (target <= 0 || !IsValidEntity(target))
		return;

	int ragdoll = GetEntProp(target, Prop_Data, "m_bClientSideRagdoll");
	if (ragdoll != 0)
		return;

	int pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt > 0)
	{
		char targetName[32];
		Format(targetName, sizeof(targetName), "defgrid_target%d", target);
		DispatchKeyValue(target, "targetname", targetName);
		DispatchKeyValue(pointHurt, "DamageTarget", targetName);

		char dmgStr[16];
		IntToString(damage, dmgStr, sizeof(dmgStr));
		DispatchKeyValue(pointHurt, "Damage", dmgStr);
		DispatchKeyValue(pointHurt, "DamageType", "8");	   // DMG_SHOCK

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt");
		AcceptEntityInput(pointHurt, "Kill");

		DispatchKeyValue(target, "targetname", "");
	}
}

public int DefenseGrid_GetCooldown(int client)
{
	if (g_bDefenseGridReady[client])
		return 0;

	int remaining = RoundToFloor(g_fDefenseGridCooldownEnd[client] - GetGameTime());
	return remaining > 0 ? remaining : 0;
}