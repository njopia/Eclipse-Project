#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === DEFENSE GRID DEPLOYABLE ===
// Sistema de defensa eléctrica que repele enemigos
//==================================================

// Models
#define MODEL_DEFENSEGRID "models/props_shacks/bug_lamp01.mdl"
#define MODEL_DEFENSEGRID_BASE "models/props_interiors/makeshift_stove_battery.mdl"
#define MODEL_DEFENSEGRID_SPHERE "models/props_unique/airport/atlas_break_ball.mdl"

// Particles
#define PARTICLE_DEFENSEGRID_GLOW "electrical_arc_01_cp0"
#define PARTICLE_LS_BOLT "electrical_arc_01_system"

// Sounds (electrical zap sounds)
#define SOUND_ZAP1 "ambient/energy/zap5.wav"
#define SOUND_ZAP2 "ambient/energy/zap6.wav"
#define SOUND_ZAP3 "ambient/energy/zap7.wav"
#define SOUND_ZAP4 "ambient/energy/zap8.wav"
#define SOUND_ZAP5 "ambient/energy/zap9.wav"

// Configuration
#define DEFENSEGRID_MAX_DURATION 300  // 5 minutos de duración
#define DEFENSEGRID_COOLDOWN 300.0    // 5 minutos de cooldown
#define DEFENSEGRID_LOG_FILE "logs/defense_grid_debug.log"

// Global arrays
static int g_iDefenseGridEnt[MAXPLAYERS + 1][6];  // Entidades del grid (6 componentes: base, lámpara, 4 triggers)
static int g_iDefenseGridTimer[MAXPLAYERS + 1];   // Timer del deployable
static float g_fDefenseGridCooldown[MAXPLAYERS + 1]; // Cooldown para desplegar

// Logging
static char g_sLogPath[PLATFORM_MAX_PATH];

/**
 * Helper para escribir al log de debug
 */
void DefenseGrid_Log(const char[] format, any ...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);

	// También imprimir al servidor para debug inmediato
	PrintToServer("[DEFENSE GRID] %s", buffer);

	// Escribir al archivo
	LogToFile(g_sLogPath, "%s", buffer);
}

/**
 * Precarga recursos del Defense Grid
 */
public void DefenseGrid_OnMapStart()
{
	// Inicializar logging
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), DEFENSEGRID_LOG_FILE);
	DefenseGrid_Log("=== Defense Grid Debug Log Initialized ===");
	DefenseGrid_Log("Map: %s", "CurrentMap");

	// Precache models
	PrecacheModel(MODEL_DEFENSEGRID, true);
	PrecacheModel(MODEL_DEFENSEGRID_BASE, true);
	PrecacheModel(MODEL_DEFENSEGRID_SPHERE, true);

	// Precache sounds
	PrecacheSound(SOUND_ZAP1, true);
	PrecacheSound(SOUND_ZAP2, true);
	PrecacheSound(SOUND_ZAP3, true);
	PrecacheSound(SOUND_ZAP4, true);
	PrecacheSound(SOUND_ZAP5, true);

	// Precache particles
	DefenseGrid_PrecacheParticle(PARTICLE_DEFENSEGRID_GLOW);
	DefenseGrid_PrecacheParticle(PARTICLE_LS_BOLT);
}

/**
 * Helper: Precarga un sistema de partículas
 */
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

/**
 * Timer para eliminar partícula de precache
 */
public Action Timer_DeletePrecacheParticle(Handle timer, int particle)
{
	if (IsValidEntity(particle))
	{
		AcceptEntityInput(particle, "Kill");
	}
	return Plugin_Stop;
}

/**
 * Inicializa el deployable cuando un cliente se conecta
 */
public void DefenseGrid_OnClientConnect(int client)
{
	for (int i = 0; i < 6; i++)
	{
		g_iDefenseGridEnt[client][i] = 0;
	}
	g_iDefenseGridTimer[client] = 0;
	g_fDefenseGridCooldown[client] = 0.0;
}

/**
 * Limpia el deployable cuando un cliente se desconecta
 */
public void DefenseGrid_OnClientDisconnect(int client)
{
	DefenseGrid_Destroy(client);
	g_iDefenseGridTimer[client] = 0;
	g_fDefenseGridCooldown[client] = 0.0;
}

/**
 * Verifica si el jugador puede desplegar el Defense Grid
 */
public bool DefenseGrid_CanDeploy(int client)
{
	float currentTime = GetGameTime();

	// Verificar cooldown
	if (g_fDefenseGridCooldown[client] > currentTime)
	{
		int remaining = RoundToFloor(g_fDefenseGridCooldown[client] - currentTime);
		PrintToChat(client, "\x04[Defense Grid]\x01 Debes esperar \x03%d\x01 segundos para usar esto nuevamente.", remaining);
		return false;
	}

	// Verificar que esté en el suelo
	if (!(GetEntityFlags(client) & FL_ONGROUND))
	{
		PrintToChat(client, "\x04[Defense Grid]\x01 Debes estar en el suelo para desplegar esto.");
		return false;
	}

	// Verificar que no tenga ya uno activo
	if (g_iDefenseGridEnt[client][0] > 0 && IsValidEntity(g_iDefenseGridEnt[client][0]))
	{
		PrintToChat(client, "\x04[Defense Grid]\x01 Ya tienes un Defense Grid activo.");
		return false;
	}

	return true;
}

/**
 * Despliega el Defense Grid
 */
public void DefenseGrid_Deploy(int client)
{
	if (!DefenseGrid_CanDeploy(client))
		return;

	float origin[3], angles[3], direction[3];
	GetClientAbsOrigin(client, origin);
	GetClientEyeAngles(client, angles);
	GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);

	// Posicionar frente al jugador
	origin[0] += direction[0] * 32.0;
	origin[1] += direction[1] * 32.0;
	origin[2] += direction[2] * 1.0;
	angles[0] = 0.0;
	angles[2] = 0.0;

	// Crear entidad base (batería)
	int entity = CreateEntityByName("prop_dynamic_override");
	if (entity > 0 && IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "model", MODEL_DEFENSEGRID_BASE);
		DispatchKeyValueVector(entity, "Origin", origin);
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "DisableCollision");
		AcceptEntityInput(entity, "DisableShadow");
		g_iDefenseGridEnt[client][0] = entity;
		g_iDefenseGridTimer[client] = DEFENSEGRID_MAX_DURATION;

		// Crear lámpara principal (bug lamp con glow)
		entity = CreateEntityByName("prop_dynamic_override");
		if (entity > 0 && IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", MODEL_DEFENSEGRID);
			DispatchKeyValueVector(entity, "Origin", origin);
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision");
			AcceptEntityInput(entity, "DisableShadow");

			// Glow blanco
			int glowcolor = RGB_TO_INT(255, 255, 255);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", glowcolor);
			SetEntProp(entity, Prop_Send, "m_iGlowType", 2);

			// Ajustar posición
			float tempOrigin[3];
			tempOrigin[0] = origin[0] - 2.0;
			tempOrigin[1] = origin[1] - 6.5;
			tempOrigin[2] = origin[2] + 17.0;
			TeleportEntity(entity, tempOrigin, NULL_VECTOR, NULL_VECTOR);
			g_iDefenseGridEnt[client][1] = entity;

			// No necesitamos filtro - lo manejamos manualmente en OnTouch
			// Crear 4 trigger_push en formación de cruz (sin filtro)
			// Slots: [0]=base, [1]=lamp, [2-5]=4 triggers
			DefenseGrid_CreateTriggerPush(client, origin, 2, "0 45 0", 55.0, 55.0);
			DefenseGrid_CreateTriggerPush(client, origin, 3, "0 -45 0", 55.0, -55.0);
			DefenseGrid_CreateTriggerPush(client, origin, 4, "0 135 0", -55.0, 55.0);
			DefenseGrid_CreateTriggerPush(client, origin, 5, "0 -135 0", -55.0, -55.0);
		}
	}

	// Establecer cooldown
	g_fDefenseGridCooldown[client] = GetGameTime() + DEFENSEGRID_COOLDOWN;

	DefenseGrid_Log("Defense Grid deployed by %N (client %d) at position [%.1f, %.1f, %.1f]", client, client, origin[0], origin[1], origin[2]);
	DefenseGrid_Log("Entities created - Base: %d, Lamp: %d, Triggers: [%d, %d, %d, %d]",
		g_iDefenseGridEnt[client][0], g_iDefenseGridEnt[client][1],
		g_iDefenseGridEnt[client][2], g_iDefenseGridEnt[client][3], g_iDefenseGridEnt[client][4], g_iDefenseGridEnt[client][5]);

	PrintToChat(client, "\x04[Defense Grid]\x01 Desplegado. Duración: \x03%d\x01 segundos.", DEFENSEGRID_MAX_DURATION);
}

/**
 * Crea un trigger_push para el Defense Grid
 */
void DefenseGrid_CreateTriggerPush(int client, float origin[3], int slot, const char[] pushdir, float offsetX, float offsetY)
{
	int entity = CreateEntityByName("trigger_push");
	DefenseGrid_Log("Creating trigger_push for slot %d, entity ID: %d", slot, entity);

	if (entity > 0 && IsValidEntity(entity))
	{
		float minbounds[3] = {-55.0, -55.0, 0.0};
		float maxbounds[3] = {55.0, 55.0, 155.0};
		float triggerOrigin[3];

		triggerOrigin[0] = origin[0] + offsetX;
		triggerOrigin[1] = origin[1] + offsetY;
		triggerOrigin[2] = origin[2];

		// Note: trigger_push doesn't need a visual model
		DispatchKeyValueVector(entity, "Origin", triggerOrigin);
		DispatchKeyValue(entity, "spawnflags", "1");  // Clients only
		DispatchKeyValue(entity, "speed", "0");  // We handle pushing manually
		DispatchKeyValue(entity, "pushdir", pushdir);
		// No filter needed - we check manually in OnTouch

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
		DefenseGrid_Log("Trigger slot %d created successfully at [%.1f, %.1f, %.1f]", slot, triggerOrigin[0], triggerOrigin[1], triggerOrigin[2]);
	}
	else
	{
		DefenseGrid_Log("FAILED to create trigger_push for slot %d", slot);
	}
}

/**
 * Hook cuando algo toca el Defense Grid
 */
public Action DefenseGrid_OnTouch(int caller, int activator)
{
	if (activator <= 0 || !IsValidEntity(activator))
		return Plugin_Continue;

	DefenseGrid_Log("OnTouch triggered - Caller: %d, Activator: %d", caller, activator);

	// Encontrar el dueño del grid
	int owner = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		for (int j = 2; j <= 5; j++)  // Índices actualizados (2-5 son los triggers)
		{
			if (g_iDefenseGridEnt[i][j] == caller)
			{
				owner = i;
				DefenseGrid_Log("Found owner: %d (Client: %N)", owner, owner);
				break;
			}
		}
		if (owner > 0)
			break;
	}

	if (owner <= 0 || !IsClientInGame(owner))
	{
		DefenseGrid_Log("No valid owner found or not in game");
		return Plugin_Continue;
	}

	DefenseGrid_Log("Calling GetDamageType for activator %d...", activator);
	int damageType = DefenseGrid_GetDamageType(owner, activator);
	DefenseGrid_Log("DamageType returned: %d", damageType);

	if (damageType > 0)
	{
		DefenseGrid_AwardXP(owner, damageType);
	}

	return Plugin_Continue;
}

/**
 * Determina el tipo de enemigo/proyectil y lo destruye si corresponde
 */
int DefenseGrid_GetDamageType(int owner, int entity)
{
	// Verificar si es sobreviviente con infected agarrado
	if (entity > 0 && entity <= MaxClients && IsClientInGame(entity) && GetClientTeam(entity) == 2)
	{
		// TODO: Implementar check de infected hold y liberación
		return 0;
	}

	// Verificar infected especial
	if (entity > 0 && entity <= MaxClients && IsClientInGame(entity) && GetClientTeam(entity) == 3)
	{
		int zombieClass = GetEntProp(entity, Prop_Send, "m_zombieClass");
		DefenseGrid_Log("Infected player detected - Entity: %d, Client: %N, Class: %d", entity, entity, zombieClass);

		if (zombieClass == 8) // Tank
		{
			DefenseGrid_Log("Tank detected! Calling fling with force 600.0");
			// Repeler al Tank con fuerza
			DefenseGrid_FlingInfected(owner, entity, 600.0);
			return 2;
		}
		else if (zombieClass >= 1 && zombieClass <= 6) // Special infected
		{
			DefenseGrid_Log("Special Infected detected! Calling fling with force 700.0");
			// Repeler al Special Infected con fuerza
			DefenseGrid_FlingInfected(owner, entity, 700.0);
			return 1;
		}
	}

	// Verificar proyectiles y otras entidades
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
		// Matar al zombie común
		DefenseGrid_DealDamageEntity(entity, 1000);
		return 6; // Common infected
	}
	else if (StrEqual(classname, "witch", false))
	{
		// Matar a la witch
		DefenseGrid_DealDamageEntity(entity, 10000);
		return 8; // Witch
	}

	return 0;
}

/**
 * Otorga XP al jugador según el tipo de bloqueo
 */
void DefenseGrid_AwardXP(int client, int type)
{
	int xpAmount = 0;

	switch (type)
	{
		case 1: xpAmount = 4;   // Special Infected (repelido, no matado)
		case 2: xpAmount = 6;   // Tank (repelido, no matado)
		case 3: xpAmount = 3;   // Spitter Projectile
		case 4: xpAmount = 3;   // Tank Rock
		case 5: xpAmount = 10;  // Uncommon Zombie (matado)
		case 6: xpAmount = 5;   // Common Zombie (matado)
		case 7: xpAmount = 50;  // Lesser Witch (matada)
		case 8: xpAmount = 100; // Witch (matada)
	}

	if (xpAmount > 0)
	{
		// Otorgar currency (puntos) en lugar de XP
		int currencyAmount = xpAmount / 2; // Mitad del XP como puntos
		if (currencyAmount > 0)
		{
			g_iPlayerCurrency[client] += currencyAmount;
		}

		// Mensaje al jugador
		char typename[32];
		switch (type)
		{
			case 1: typename = "Special Infected Repelido";
			case 2: typename = "Tank Repelido";
			case 3: typename = "Proyectil de Spitter Destruido";
			case 4: typename = "Roca de Tank Destruida";
			case 5: typename = "Uncommon Zombie Eliminado";
			case 6: typename = "Zombie Eliminado";
			case 7: typename = "Lesser Witch Eliminada";
			case 8: typename = "Witch Eliminada";
		}

		PrintToChat(client, "\x04[Defense Grid]\x01 %s: \x03+%d\x01 puntos", typename, currencyAmount);
	}
}

/**
 * Actualiza el Defense Grid (efectos visuales y timer)
 */
public void DefenseGrid_Update(int client)
{
	int entity = g_iDefenseGridEnt[client][1];
	if (entity > 0 && IsValidEntity(entity))
	{
		char classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));

		if (StrEqual(classname, "prop_dynamic", false))
		{
			char model[64];
			GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));

			if (StrEqual(model, MODEL_DEFENSEGRID, false))
			{
				// Hacer flash cuando quedan 20 segundos
				if (g_iDefenseGridTimer[client] <= 20)
				{
					SetEntProp(entity, Prop_Send, "m_bFlashing", 1);
				}

				// Ejecutar efectos eléctricos
				DefenseGrid_ExecuteEffects(client);
				CreateTimer(0.3, Timer_DefenseGridEffects, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.5, Timer_DefenseGridEffects, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.7, Timer_DefenseGridEffects, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}

	g_iDefenseGridTimer[client]--;

	// Auto-destruir cuando se acaba el tiempo
	if (g_iDefenseGridTimer[client] <= 0)
	{
		DefenseGrid_Destroy(client);
		PrintToChat(client, "\x04[Defense Grid]\x01 Tu Defense Grid ha expirado.");
	}
}

/**
 * Timer para ejecutar efectos visuales adicionales
 */
public Action Timer_DefenseGridEffects(Handle timer, int client)
{
	DefenseGrid_ExecuteEffects(client);
	return Plugin_Stop;
}

/**
 * Ejecuta efectos visuales del Defense Grid
 */
void DefenseGrid_ExecuteEffects(int client)
{
	int entity = g_iDefenseGridEnt[client][1];
	if (entity > 0 && IsValidEntity(entity))
	{
		// Partícula de brillo
		AttachParticle(entity, PARTICLE_DEFENSEGRID_GLOW, 0.5, 0.0, 0.0, 12.0);

		// Crear rayo eléctrico
		DefenseGrid_CreateBolt(entity);
	}
}

/**
 * Crea un rayo eléctrico visual
 */
void DefenseGrid_CreateBolt(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity))
		return;

	float origin[3], targetOrigin[3], angles[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);

	// Generar ángulo aleatorio
	angles[0] = GetRandomFloat(-360.0, 360.0);
	angles[1] = GetRandomFloat(-360.0, 360.0);
	angles[2] = 0.0;

	GetAngleVectors(angles, targetOrigin, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(targetOrigin, targetOrigin);
	ScaleVector(targetOrigin, 110.0);
	AddVectors(origin, targetOrigin, targetOrigin);

	// Crear endpoint para el rayo
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

		// Crear partícula de rayo
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

		// Sonido aleatorio de zap
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

/**
 * Destruye el Defense Grid
 */
public void DefenseGrid_Destroy(int client)
{
	for (int i = 0; i < 6; i++)
	{
		int entity = g_iDefenseGridEnt[client][i];
		if (entity > 0 && IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
		g_iDefenseGridEnt[client][i] = 0;
	}
	g_iDefenseGridTimer[client] = 0;
}

/**
 * Obtiene el tiempo restante del Defense Grid
 */
public int DefenseGrid_GetTimeRemaining(int client)
{
	return g_iDefenseGridTimer[client];
}

/**
 * Verifica si el Defense Grid está activo
 */
public bool DefenseGrid_IsActive(int client)
{
	return (g_iDefenseGridEnt[client][0] > 0 && IsValidEntity(g_iDefenseGridEnt[client][0]));
}

/**
 * Obtiene el tiempo de cooldown restante
 */
public int DefenseGrid_GetCooldown(int client)
{
	float currentTime = GetGameTime();
	if (g_fDefenseGridCooldown[client] > currentTime)
	{
		return RoundToFloor(g_fDefenseGridCooldown[client] - currentTime);
	}
	return 0;
}

/**
 * Helper: Adjunta una partícula a una entidad
 */
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

/**
 * Timer para eliminar partícula adjunta
 */
public Action Timer_DeleteAttachedParticle(Handle timer, int particle)
{
	if (IsValidEntity(particle))
	{
		AcceptEntityInput(particle, "Kill");
	}
	return Plugin_Stop;
}

/**
 * Repele/empuja a un infected especial o tank lejos del Defense Grid
 */
void DefenseGrid_FlingInfected(int owner, int victim, float force)
{
	DefenseGrid_Log("FlingInfected called - Owner: %d (%N), Victim: %d (%N), Force: %.1f", owner, owner, victim, victim, force);

	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
	{
		DefenseGrid_Log("Invalid victim - aborting fling");
		return;
	}

	// Obtener posiciones
	float ownerPos[3], victimPos[3];

	// Encontrar el centro del Defense Grid (entidad base)
	int gridEntity = g_iDefenseGridEnt[owner][0];
	if (gridEntity > 0 && IsValidEntity(gridEntity))
	{
		GetEntPropVector(gridEntity, Prop_Send, "m_vecOrigin", ownerPos);
		DefenseGrid_Log("Grid entity %d position: [%.1f, %.1f, %.1f]", gridEntity, ownerPos[0], ownerPos[1], ownerPos[2]);
	}
	else
	{
		// Fallback: usar posición del owner
		GetClientAbsOrigin(owner, ownerPos);
		DefenseGrid_Log("Using owner position (fallback): [%.1f, %.1f, %.1f]", ownerPos[0], ownerPos[1], ownerPos[2]);
	}

	GetClientAbsOrigin(victim, victimPos);
	DefenseGrid_Log("Victim position: [%.1f, %.1f, %.1f]", victimPos[0], victimPos[1], victimPos[2]);

	// Calcular vector de dirección (desde grid hacia el infected)
	float traceVec[3], resultingFling[3];
	MakeVectorFromPoints(ownerPos, victimPos, traceVec);
	GetVectorAngles(traceVec, resultingFling);

	// Aplicar fuerza en dirección radial desde el grid
	resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * force;
	resultingFling[1] = Sine(DegToRad(resultingFling[1])) * force;
	resultingFling[2] = force * 0.8; // Fuerza vertical (80% de la horizontal)

	DefenseGrid_Log("Calculated fling vector: [%.1f, %.1f, %.1f]", resultingFling[0], resultingFling[1], resultingFling[2]);

	// Obtener velocidad actual y sumarla
	float currentVel[3];
	GetEntPropVector(victim, Prop_Data, "m_vecVelocity", currentVel);
	DefenseGrid_Log("Current velocity: [%.1f, %.1f, %.1f]", currentVel[0], currentVel[1], currentVel[2]);

	resultingFling[0] += currentVel[0];
	resultingFling[1] += currentVel[1];
	resultingFling[2] += currentVel[2];

	DefenseGrid_Log("Final fling vector (with velocity): [%.1f, %.1f, %.1f]", resultingFling[0], resultingFling[1], resultingFling[2]);

	// Aplicar el empujón
	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, resultingFling);
	DefenseGrid_Log("TeleportEntity applied successfully");

	// Aplicar stagger visual
	L4D_StaggerPlayer(victim, owner, resultingFling);
	DefenseGrid_Log("L4D_StaggerPlayer applied successfully");
}

/**
 * Aplica daño a una entidad (common infected, witch, etc)
 */
void DefenseGrid_DealDamageEntity(int target, int damage)
{
	if (target <= 0 || !IsValidEntity(target))
		return;

	// Verificar que no esté ya muerto/ragdoll
	int ragdoll = GetEntProp(target, Prop_Data, "m_bClientSideRagdoll");
	if (ragdoll != 0)
		return;

	// Crear point_hurt para aplicar daño
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
		DispatchKeyValue(pointHurt, "DamageType", "8"); // DMG_SHOCK

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt");
		AcceptEntityInput(pointHurt, "Kill");

		// Limpiar targetname
		DispatchKeyValue(target, "targetname", "");
	}
}
