//==================================================
// === SHOULDER CANNON ABILITY (Level 35) ===
// Automatic targeting shoulder-mounted cannon
// Duration: 60 seconds
// Cooldown: 5 minutes
// Features: Auto-targeting, unlimited ammo during duration
//==================================================

// Models and Sounds
#define MODEL_M60 "models/w_models/weapons/w_m60.mdl"
#define SOUND_M60_FIRE "weapons/machinegun_m60/gunfire/machinegun_fire_1.wav"

// Particles
#define PARTICLE_BLOOD "blood_impact_red_01"
#define PARTICLE_50CAL_TRACER "weapon_tracers_50cal"
#define PARTICLE_RIFLE_FLASH "weapon_muzzle_flash_assaultrifle"

// Constants
#define SHOULDER_CANNON_DAMAGE 12
#define SHOULDER_CANNON_RANGE 600.0
#define SHOULDER_CANNON_FIRE_RATE 0.15

// Target types
#define TARGET_NEVER_NONE 0
#define TARGET_NEVER_COMMONS 1
#define TARGET_NEVER_SPECIALS 2
#define TARGET_NEVER_WITCHES 3
#define TARGET_NEVER_TANKS 4
#define TARGET_NEVER_COMMONS_SPECIALS 5
#define TARGET_NEVER_COMMONS_WITCHES 6
#define TARGET_NEVER_WITCHES_TANKS 7

#define TARGET_FIRST_COMMONS 0
#define TARGET_FIRST_SPECIALS 1
#define TARGET_FIRST_WITCHES 2
#define TARGET_FIRST_TANKS 3

// Estado del jugador
int g_iShoulderCannon_Entity[MAXPLAYERS + 1];
Handle g_hShoulderCannon_FireTimer[MAXPLAYERS + 1];

// Configuración del Shoulder Cannon (guardadas en BBDD via g_bShoulderCannon_AutoEquip en leveling)
bool g_bCannon_Disabled[MAXPLAYERS + 1];  // Desactivar disparo automático
int g_iCannon_NeverTarget[MAXPLAYERS + 1];  // Qué no atacar nunca
int g_iCannon_TargetFirst[MAXPLAYERS + 1];  // Qué atacar primero
float g_fCannon_FireRate[MAXPLAYERS + 1];  // Velocidad de disparo

/**
 * Precache de recursos
 */
void Ability_ShoulderCannon_Precache()
{
	PrecacheModel(MODEL_M60, true);
	PrecacheSound(SOUND_M60_FIRE, true);
}

/**
 * Activa Shoulder Cannon
 */
bool Ability_ShoulderCannon_Activate(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return false;

	if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "\x04[Shoulder Cannon]\x01 Solo Survivors pueden usar esta ability.");
		return false;
	}

	// Crear entidad del cañón
	int entity = CreateEntityByName("prop_dynamic_override");
	if (entity == -1)
		entity = CreateEntityByName("prop_dynamic");

	if (!IsValidEntity(entity))
		return false;

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
	g_hShoulderCannon_FireTimer[client] = CreateTimer(SHOULDER_CANNON_FIRE_RATE, Timer_ShoulderCannon_Fire, GetClientUserId(client), TIMER_REPEAT);

	// Hook de transmisión
	SDKHook(entity, SDKHook_SetTransmit, ShoulderCannon_Hook_SetTransmit);

	// Efecto visual gris metálico
	int clients[1];
	clients[0] = client;
	int color[4] = {150, 150, 150, 80};
	int duration = 60000;
	int flags = 0x0001;

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, 500);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
		EndMessage();
	}

	PrintToChat(client, "\x04[Shoulder Cannon]\x01 Cannon equipado! Disparo automatico activado.");
	return true;
}

/**
 * Desactiva Shoulder Cannon
 */
void Ability_ShoulderCannon_Deactivate(int client)
{
	// Remover entidad
	int entity = g_iShoulderCannon_Entity[client];
	if (entity > 0 && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic", false))
		{
			char model[64];
			GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_M60, false))
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
	}

	g_iShoulderCannon_Entity[client] = 0;

	// Detener timer
	if (g_hShoulderCannon_FireTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hShoulderCannon_FireTimer[client]);
		g_hShoulderCannon_FireTimer[client] = INVALID_HANDLE;
	}

	if (!IsClientInGame(client))
		return;

	// Limpiar efecto visual
	int clients[1];
	clients[0] = client;
	int color[4] = {0, 0, 0, 0};

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, 500);
		BfWriteShort(message, 500);
		BfWriteShort(message, 0x0002);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
		EndMessage();
	}

	PrintToChat(client, "\x04[Shoulder Cannon]\x01 Cañón desequipado.");
}

/**
 * Hook de transmisión
 */
public Action ShoulderCannon_Hook_SetTransmit(int entity, int client)
{
	return Plugin_Continue;
}

/**
 * Timer: Disparo automático
 */
public Action Timer_ShoulderCannon_Fire(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	// Verificar si está equipado (ya no depende de Abilities system)
	// if (!Abilities_IsActive(client, Ability_ShoulderCannon))
	// 	return Plugin_Stop;

	int cannon = g_iShoulderCannon_Entity[client];
	if (cannon <= 0 || !IsValidEntity(cannon))
		return Plugin_Stop;

	// No disparar si está incapacitado
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		return Plugin_Continue;

	// No disparar si está siendo agarrado
	if (IsPlayerHeld(client))
		return Plugin_Continue;

	// No disparar si el jugador lo deshabilitó
	if (g_bCannon_Disabled[client])
		return Plugin_Continue;

	// Buscar objetivo
	int target = ShoulderCannon_FindTarget(client);
	if (target > 0)
	{
		ShoulderCannon_FireAtTarget(client, cannon, target);
	}

	return Plugin_Continue;
}

/**
 * Busca un objetivo válido
 */
int ShoulderCannon_FindTarget(int client)
{
	float Origin[3], TOrigin[3];
	float storeddist = 0.0, distance = 0.0;
	int zombie = 0, special = 0, tank = 0, witch = 0;

	GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);

	// Buscar zombies comunes
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
	{
		int ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
		if (ragdoll == 0)
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
			distance = GetVectorDistance(Origin, TOrigin);
			if (distance < SHOULDER_CANNON_RANGE)
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

	// Buscar witches
	entity = -1;
	while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
	{
		int ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
		if (ragdoll == 0)
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
			distance = GetVectorDistance(Origin, TOrigin);
			if (distance < SHOULDER_CANNON_RANGE)
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

	// Buscar infectados especiales y tanks
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
		{
			int zombieClass = GetEntProp(i, Prop_Send, "m_zombieClass");

			// Tank (clase 8)
			if (zombieClass == 8)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", TOrigin);
				distance = GetVectorDistance(Origin, TOrigin);
				if (distance < SHOULDER_CANNON_RANGE)
				{
					if (storeddist == 0.0 || storeddist > distance)
					{
						if (ShoulderCannon_IsVisible(client, i))
						{
							storeddist = distance;
							tank = i;
						}
					}
				}
			}
			// Infectados especiales (clases 1-6)
			else if (zombieClass >= 1 && zombieClass <= 6)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", TOrigin);
				distance = GetVectorDistance(Origin, TOrigin);
				if (distance < SHOULDER_CANNON_RANGE)
				{
					if (storeddist == 0.0 || storeddist > distance)
					{
						if (ShoulderCannon_IsVisible(client, i))
						{
							storeddist = distance;
							special = i;
						}
					}
				}
			}
		}
	}

	// Prioridad: Especiales > Witches > Tanks > Commons
	if (special > 0) return special;
	if (witch > 0) return witch;
	if (tank > 0) return tank;
	return zombie;
}

/**
 * Verifica visibilidad del objetivo
 */
bool ShoulderCannon_IsVisible(int client, int target)
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
	if (fDistance_Length > SHOULDER_CANNON_RANGE)
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
void ShoulderCannon_FireAtTarget(int client, int cannon, int target)
{
	// Efectos visuales
	ShoulderCannon_ShowMuzzleFlash(cannon);
	ShoulderCannon_AttachParticle(target, PARTICLE_BLOOD, 0.1, 0.0, 0.0, 30.0);
	ShoulderCannon_CreateTracerParticles(cannon, target);
	EmitSoundToAll(SOUND_M60_FIRE, client);

	// Aplicar daño
	bool isPlayer = (target > 0 && target <= MaxClients);

	if (isPlayer)
		SDKHooks_TakeDamage(target, client, client, float(SHOULDER_CANNON_DAMAGE), DMG_BULLET);
	else
		ShoulderCannon_DealDamageEntity(target, client, SHOULDER_CANNON_DAMAGE);
}

/**
 * Aplica daño a entidad
 */
void ShoulderCannon_DealDamageEntity(int target, int attacker, int dmg)
{
	if (target <= 32 || !IsValidEntity(target))
		return;

	int ragdoll = GetEntProp(target, Prop_Data, "m_bClientSideRagdoll");
	if (ragdoll != 0)
		return;

	// Para infected comunes, aplicar efecto de muerte si HP es bajo
	char classname[16];
	GetEdictClassname(target, classname, sizeof(classname));

	if (StrEqual(classname, "infected"))
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
	IntToString(2, type, sizeof(type)); // DMG_BULLET

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
void ShoulderCannon_ShowMuzzleFlash(int target)
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
void ShoulderCannon_CreateTracerParticles(int entity, int target)
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
void ShoulderCannon_AttachParticle(int target, const char[] ParticleName, float time, float x, float y, float z)
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
 * Verifica si un jugador está siendo agarrado
 */
bool IsPlayerHeld(int client)
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

//==================================================
// === SHOULDER CANNON MENU SYSTEM ===
//==================================================

/**
 * Inicializa valores por defecto del cannon
 */
void ShoulderCannon_InitializeDefaults(int client)
{
	g_bCannon_Disabled[client] = false;
	g_iCannon_NeverTarget[client] = TARGET_NEVER_NONE;
	g_iCannon_TargetFirst[client] = TARGET_FIRST_COMMONS;
	g_fCannon_FireRate[client] = SHOULDER_CANNON_FIRE_RATE;
}

/**
 * Muestra el menú principal del Shoulder Cannon
 */
void ShoulderCannon_ShowMenu(int client)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != 2)
		return;

	int level = Leveling_GetPlayerLevel(client);
	if (level < 35)
	{
		PrintToChat(client, "\x04[Shoulder Cannon]\x01 Necesitas nivel 35 para usar Shoulder Cannon (Actual: %d)", level);
		return;
	}

	Menu menu = new Menu(ShoulderCannon_MenuHandler);
	menu.SetTitle("Shoulder Cannon Menu\n \nConfiguracion:");

	char buffer[128];

	// Opción 1: Auto-equipar
	Format(buffer, sizeof(buffer), "%s Auto Equip al Spawnar",
		g_bShoulderCannon_AutoEquip[client] ? "[X]" : "[ ]");
	menu.AddItem("autoequip", buffer);

	// Opción 2: Desactivar disparo
	Format(buffer, sizeof(buffer), "%s Desactivar Disparo",
		g_bCannon_Disabled[client] ? "[X]" : "[ ]");
	menu.AddItem("disable", buffer);

	// Opción 3: Never Target
	char neverText[64];
	switch(g_iCannon_NeverTarget[client])
	{
		case TARGET_NEVER_NONE: Format(neverText, sizeof(neverText), "None");
		case TARGET_NEVER_COMMONS: Format(neverText, sizeof(neverText), "Commons");
		case TARGET_NEVER_SPECIALS: Format(neverText, sizeof(neverText), "Specials");
		case TARGET_NEVER_WITCHES: Format(neverText, sizeof(neverText), "Witches");
		case TARGET_NEVER_TANKS: Format(neverText, sizeof(neverText), "Tanks");
		case TARGET_NEVER_COMMONS_SPECIALS: Format(neverText, sizeof(neverText), "Commons/Specials");
		case TARGET_NEVER_COMMONS_WITCHES: Format(neverText, sizeof(neverText), "Commons/Witches");
		case TARGET_NEVER_WITCHES_TANKS: Format(neverText, sizeof(neverText), "Witches/Tanks");
	}
	Format(buffer, sizeof(buffer), "[%s] Never Target", neverText);
	menu.AddItem("never", buffer);

	// Opción 4: Target First
	char firstText[64];
	switch(g_iCannon_TargetFirst[client])
	{
		case TARGET_FIRST_COMMONS: Format(firstText, sizeof(firstText), "Commons");
		case TARGET_FIRST_SPECIALS: Format(firstText, sizeof(firstText), "Specials");
		case TARGET_FIRST_WITCHES: Format(firstText, sizeof(firstText), "Witches");
		case TARGET_FIRST_TANKS: Format(firstText, sizeof(firstText), "Tanks");
	}
	Format(buffer, sizeof(buffer), "[%s] Target First", firstText);
	menu.AddItem("first", buffer);

	// Opción 5: Fire Rate
	char rateText[64];
	if (g_fCannon_FireRate[client] <= 0.05) Format(rateText, sizeof(rateText), "+0.05 Fastest");
	else if (g_fCannon_FireRate[client] <= 0.10) Format(rateText, sizeof(rateText), "+0.10 Faster");
	else if (g_fCannon_FireRate[client] <= 0.15) Format(rateText, sizeof(rateText), "+0.15 Default");
	else if (g_fCannon_FireRate[client] <= 0.20) Format(rateText, sizeof(rateText), "+0.20 Slower");
	else Format(rateText, sizeof(rateText), "+0.25 Slowest");
	Format(buffer, sizeof(buffer), "[%s] Fire Rate", rateText);
	menu.AddItem("rate", buffer);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menú principal
 */
public int ShoulderCannon_MenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));

		if (StrEqual(info, "autoequip"))
		{
			g_bShoulderCannon_AutoEquip[client] = !g_bShoulderCannon_AutoEquip[client];
			Leveling_SaveShoulderCannonAutoEquip(client, g_bShoulderCannon_AutoEquip[client]);
			PrintToChat(client, "\x04[Shoulder Cannon]\x01 Auto-equip: %s",
				g_bShoulderCannon_AutoEquip[client] ? "ON" : "OFF");
			ShoulderCannon_ShowMenu(client);
		}
		else if (StrEqual(info, "disable"))
		{
			g_bCannon_Disabled[client] = !g_bCannon_Disabled[client];
			PrintToChat(client, "\x04[Shoulder Cannon]\x01 Disparo: %s",
				g_bCannon_Disabled[client] ? "DESACTIVADO" : "ACTIVADO");
			ShoulderCannon_ShowMenu(client);
		}
		else if (StrEqual(info, "never"))
		{
			ShoulderCannon_ShowNeverTargetMenu(client);
		}
		else if (StrEqual(info, "first"))
		{
			ShoulderCannon_ShowTargetFirstMenu(client);
		}
		else if (StrEqual(info, "rate"))
		{
			ShoulderCannon_ShowFireRateMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Menú Never Target
 */
void ShoulderCannon_ShowNeverTargetMenu(int client)
{
	Menu menu = new Menu(ShoulderCannon_NeverTargetHandler);
	menu.SetTitle("Never Target:");

	menu.AddItem("0", "None");
	menu.AddItem("1", "Commons");
	menu.AddItem("2", "Specials");
	menu.AddItem("3", "Witches");
	menu.AddItem("4", "Tanks");
	menu.AddItem("5", "Commons/Specials");
	menu.AddItem("6", "Commons/Witches");
	menu.AddItem("7", "Witches/Tanks");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ShoulderCannon_NeverTargetHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));
		g_iCannon_NeverTarget[client] = StringToInt(info);
		PrintToChat(client, "\x04[Shoulder Cannon]\x01 Never Target actualizado");
		ShoulderCannon_ShowMenu(client);
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShoulderCannon_ShowMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Menú Target First
 */
void ShoulderCannon_ShowTargetFirstMenu(int client)
{
	Menu menu = new Menu(ShoulderCannon_TargetFirstHandler);
	menu.SetTitle("Target First:");

	menu.AddItem("0", "Commons");
	menu.AddItem("1", "Specials");
	menu.AddItem("2", "Witches");
	menu.AddItem("3", "Tanks");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ShoulderCannon_TargetFirstHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));
		g_iCannon_TargetFirst[client] = StringToInt(info);
		PrintToChat(client, "\x04[Shoulder Cannon]\x01 Target First actualizado");
		ShoulderCannon_ShowMenu(client);
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShoulderCannon_ShowMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Menú Fire Rate
 */
void ShoulderCannon_ShowFireRateMenu(int client)
{
	Menu menu = new Menu(ShoulderCannon_FireRateHandler);
	menu.SetTitle("Fire Rate:");

	menu.AddItem("0.05", "[+0.05] Fastest");
	menu.AddItem("0.10", "[+0.10] Faster");
	menu.AddItem("0.15", "[+0.15] Default");
	menu.AddItem("0.20", "[+0.20] Slower");
	menu.AddItem("0.25", "[+0.25] Slowest");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ShoulderCannon_FireRateHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));
		g_fCannon_FireRate[client] = StringToFloat(info);
		PrintToChat(client, "\x04[Shoulder Cannon]\x01 Fire Rate actualizado a %.2f", g_fCannon_FireRate[client]);
		ShoulderCannon_ShowMenu(client);
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShoulderCannon_ShowMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

//==================================================
// === SHOULDER CANNON EQUIP/UNEQUIP (FROM BUY MENU) ===
//==================================================

/**
 * Equipa el Shoulder Cannon (sin cooldown ni costo)
 * Llamado desde el menú !buy -> Specials
 */
void ShoulderCannon_Equip(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "\x04[Shoulder Cannon]\x01 Solo Survivors pueden usar Shoulder Cannon");
		return;
	}

	// Si ya está equipado, no hacer nada
	if (g_iShoulderCannon_Entity[client] > 0 && IsValidEntity(g_iShoulderCannon_Entity[client]))
	{
		PrintToChat(client, "\x04[Shoulder Cannon]\x01 Ya está equipado");
		return;
	}

	// Crear entidad del cañón
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

	// Iniciar timer de disparo usando fire rate configurado
	float fireRate = g_fCannon_FireRate[client];
	if (fireRate <= 0.0)
		fireRate = SHOULDER_CANNON_FIRE_RATE;

	g_hShoulderCannon_FireTimer[client] = CreateTimer(fireRate, Timer_ShoulderCannon_Fire, GetClientUserId(client), TIMER_REPEAT);

	// Hook de transmisión
	SDKHook(entity, SDKHook_SetTransmit, ShoulderCannon_Hook_SetTransmit);

	PrintToChat(client, "\x04[Shoulder Cannon]\x01 Cannon equipado! Disparo automatico %s", g_bCannon_Disabled[client] ? "DESACTIVADO" : "activado");
}

/**
 * Desequipa el Shoulder Cannon
 * Llamado desde el menú !buy -> Specials
 */
void ShoulderCannon_Unequip(int client)
{
	// Remover entidad
	int entity = g_iShoulderCannon_Entity[client];
	if (entity > 0 && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic", false))
		{
			char model[64];
			GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_M60, false))
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
	}

	g_iShoulderCannon_Entity[client] = 0;

	// Detener timer
	if (g_hShoulderCannon_FireTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hShoulderCannon_FireTimer[client]);
		g_hShoulderCannon_FireTimer[client] = INVALID_HANDLE;
	}

	PrintToChat(client, "\x04[Shoulder Cannon]\x01 Cannon desequipado");
}
