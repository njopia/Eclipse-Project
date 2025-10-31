#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === LASER ROUNDS PASSIVE REWARD ===
// Actualiza rifles y SMGs a munición láser con daño extra e incineración
// Based on Master_3_46 implementation
//==================================================

// Particle y modelos
#define PARTICLE_LASER "weapon_tracers_50cal_low"

static const char WeaponViewModels[][] = {
	"models/v_models/v_rifle.mdl",
	"models/v_models/v_smg.mdl",
	"models/v_models/v_huntingrifle.mdl",
	"models/v_models/v_snip_scout.mdl",
	"models/v_models/v_sniper_military.mdl",
	"models/v_models/v_snip_awp.mdl",
	"models/v_models/v_silenced_smg.mdl",
	"models/v_models/v_smg_mp5.mdl",
	"models/v_models/v_rif_sg552.mdl",
	"models/v_models/v_desert_rifle.mdl",
	"models/v_models/v_rifle_ak47.mdl",
	"models/v_models/v_m60.mdl"
};

// --- ConVars ---
Handle cvar_LaserRounds_RequiredLevel = INVALID_HANDLE;
Handle cvar_LaserRounds_DamageBonus = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bLaserRounds_Enabled[MAXPLAYERS + 1];
int g_iLaserRounds_LastWeapon[MAXPLAYERS + 1];  // Última arma a la que se aplicó láser
Handle g_hLaserRounds_CheckTimer[MAXPLAYERS + 1];  // Timer de verificación periódica

/**
 * Inicializa el módulo de Laser Rounds
 */
public void LaserRounds_OnPluginStart()
{
	cvar_LaserRounds_RequiredLevel = CreateConVar(
		"reward_laserrounds_level",
		"47",
		"Nivel requerido para desbloquear Laser Rounds",
		FCVAR_PLUGIN
	);

	cvar_LaserRounds_DamageBonus = CreateConVar(
		"reward_laserrounds_damage",
		"1.5",
		"Multiplicador de daño para Laser Rounds",
		FCVAR_PLUGIN
	);

	// Hook para evento de disparo
	HookEvent("weapon_fire", Event_LaserRounds_WeaponFire, EventHookMode_Post);

	// Hook para cuando el jugador recoge un arma
	HookEvent("item_pickup", Event_LaserRounds_ItemPickup, EventHookMode_Post);
}

/**
 * Resetea el estado al conectar
 */
public void LaserRounds_OnClientConnect(int client)
{
	g_bLaserRounds_Enabled[client] = false;
	g_iLaserRounds_LastWeapon[client] = -1;
	g_hLaserRounds_CheckTimer[client] = INVALID_HANDLE;
}

/**
 * Limpia recursos al desconectar
 */
public void LaserRounds_OnClientDisconnect(int client)
{
	g_bLaserRounds_Enabled[client] = false;
	g_iLaserRounds_LastWeapon[client] = -1;

	// Limpiar timer
	if (g_hLaserRounds_CheckTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hLaserRounds_CheckTimer[client]);
		g_hLaserRounds_CheckTimer[client] = INVALID_HANDLE;
	}
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void LaserRounds_OnPlayerSpawn(int client, int level)
{
	if (LaserRounds_IsUnlocked(client, level))
	{
		g_bLaserRounds_Enabled[client] = true;
		g_iLaserRounds_LastWeapon[client] = -1;

		// Iniciar timer repetitivo que verifica el arma cada 0.5 segundos
		if (g_hLaserRounds_CheckTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_hLaserRounds_CheckTimer[client]);
		}
		g_hLaserRounds_CheckTimer[client] = CreateTimer(0.5, Timer_LaserRounds_CheckWeapon, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void LaserRounds_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_LaserRounds_RequiredLevel);

	if (level == requiredLevel)
	{
		g_bLaserRounds_Enabled[client] = true;
		PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste \x05Laser Rounds\x01! (Munición láser con daño extra e incineración)");
	}
	else if (level > requiredLevel)
	{
		g_bLaserRounds_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool LaserRounds_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_LaserRounds_RequiredLevel);
}

/**
 * Evento: Item Pickup - Marca que se recogió un arma nueva
 */
public Action Event_LaserRounds_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	if (!g_bLaserRounds_Enabled[client])
		return Plugin_Continue;

	// Obtener el nombre del item recogido
	char itemName[64];
	event.GetString("item", itemName, sizeof(itemName));

	// Si es un arma primaria compatible, resetear el tracker para forzar verificación
	if (LaserRounds_IsLaserWeapon(itemName))
	{
		g_iLaserRounds_LastWeapon[client] = -1;
	}

	return Plugin_Continue;
}

/**
 * Timer: Verifica constantemente si el arma actual necesita láser
 */
public Action Timer_LaserRounds_CheckWeapon(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		if (client > 0 && client <= MaxClients)
			g_hLaserRounds_CheckTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	if (!g_bLaserRounds_Enabled[client])
	{
		g_hLaserRounds_CheckTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	// Obtener arma activa
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if (weapon > 0 && IsValidEntity(weapon))
	{
		// Verificar si es una arma diferente a la última procesada
		if (weapon != g_iLaserRounds_LastWeapon[client])
		{
			char weaponClass[64];
			GetEntityClassname(weapon, weaponClass, sizeof(weaponClass));

			// Verificar si es un arma primaria (rifles, SMGs, snipers, escopetas)
			if (StrContains(weaponClass, "weapon_rifle", false) != -1 ||
				StrContains(weaponClass, "weapon_smg", false) != -1 ||
				StrContains(weaponClass, "weapon_sniper", false) != -1 ||
				StrContains(weaponClass, "weapon_hunting_rifle", false) != -1 ||
				StrContains(weaponClass, "weapon_shotgun", false) != -1 ||
				StrContains(weaponClass, "weapon_autoshotgun", false) != -1 ||
				StrContains(weaponClass, "weapon_pumpshotgun", false) != -1)
			{
				// Aplicar upgrade de laser sight (upgrade flag 4)
				int upgrades = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
				if (!(upgrades & 4)) // Si no tiene láser
				{
					SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", upgrades | 4);
					SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", GetEntProp(weapon, Prop_Send, "m_iClip1"));

					// Feedback visual sutil
					PrintToChat(client, "\x04[Laser Rounds]\x01 Láser aplicado al arma");
				}

				// Actualizar última arma procesada
				g_iLaserRounds_LastWeapon[client] = weapon;
			}
		}
	}

	return Plugin_Continue;
}

/**
 * Evento: Weapon Fire - Crea efecto de láser
 */
public Action Event_LaserRounds_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	if (!g_bLaserRounds_Enabled[client])
		return Plugin_Continue;

	// Obtener el arma que disparó desde el evento
	char weaponName[32];
	event.GetString("weapon", weaponName, sizeof(weaponName));

	// Verificar si es un arma compatible con láser
	if (!LaserRounds_IsLaserWeapon(weaponName))
		return Plugin_Continue;

	// Obtener viewmodel para attachar el efecto
	int viewmodel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
	if (viewmodel > 0 && IsValidEntity(viewmodel))
	{
		float origin[3];
		LaserRounds_GetPlayerEye(client, origin);

		// Crear efecto láser
		LaserRounds_CreateLaser(viewmodel, origin);

		// Sonido de láser (volumen reducido y pitch más bajo)
		EmitSoundToAll("ambient/energy/zap6.wav", client, SNDCHAN_AUTO, SNDLEVEL_HOME, SND_NOFLAGS, 0.2, 90);
	}

	return Plugin_Continue;
}

/**
 * Verifica si un arma es compatible con láser (por nombre del weapon_fire event)
 */
stock bool LaserRounds_IsLaserWeapon(const char[] weaponName)
{
	// Rifles de asalto
	if (StrEqual(weaponName, "rifle", false) ||           // M16
		StrEqual(weaponName, "rifle_ak47", false) ||      // AK-47
		StrEqual(weaponName, "rifle_desert", false) ||    // Desert Rifle
		StrEqual(weaponName, "rifle_sg552", false) ||     // SG552
		StrEqual(weaponName, "rifle_m60", false))         // M60
		return true;

	// SMGs
	if (StrEqual(weaponName, "smg", false) ||             // Uzi
		StrEqual(weaponName, "smg_silenced", false) ||    // Silenced SMG
		StrEqual(weaponName, "smg_mp5", false))           // MP5
		return true;

	// Rifles de francotirador
	if (StrEqual(weaponName, "hunting_rifle", false) ||   // Hunting Rifle
		StrEqual(weaponName, "sniper_military", false) || // Military Sniper
		StrEqual(weaponName, "sniper_awp", false) ||      // AWP
		StrEqual(weaponName, "sniper_scout", false))      // Scout
		return true;

	// Escopetas
	if (StrEqual(weaponName, "pumpshotgun", false) ||     // Pump Shotgun
		StrEqual(weaponName, "shotgun_chrome", false) ||  // Chrome Shotgun
		StrEqual(weaponName, "autoshotgun", false) ||     // Auto Shotgun
		StrEqual(weaponName, "shotgun_spas", false))      // SPAS Shotgun
		return true;

	return false;
}

/**
 * Verifica si un viewmodel es compatible con láser
 * OBSOLETO: Ya no se usa, se mantiene por compatibilidad
 */
stock bool LaserRounds_IsLaserViewModel(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity))
		return false;

	char classname[32];
	GetEdictClassname(entity, classname, sizeof(classname));

	if (!StrEqual(classname, "predicted_viewmodel", false))
		return false;

	char model[64];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));

	for (int i = 0; i < sizeof(WeaponViewModels); i++)
	{
		if (StrEqual(model, WeaponViewModels[i], false))
			return true;
	}

	return false;
}

/**
 * Crea el efecto visual de láser
 */
stock void LaserRounds_CreateLaser(int entity, float position[3])
{
	if (entity <= 0 || !IsValidEntity(entity))
		return;

	// Crear punto final
	char targetName[16];
	int endpoint = CreateEntityByName("info_particle_target");
	if (endpoint > 0 && IsValidEntity(endpoint))
	{
		Format(targetName, sizeof(targetName), "cptarget%d", endpoint);
		DispatchKeyValue(endpoint, "targetname", targetName);
		DispatchKeyValueVector(endpoint, "origin", position);
		DispatchSpawn(endpoint);
		ActivateEntity(endpoint);

		SetVariantString("OnUser1 !self:Kill::0.1:-1");
		AcceptEntityInput(endpoint, "AddOutput");
		AcceptEntityInput(endpoint, "FireUser1");
	}

	// Crear partícula de láser
	int particle = CreateEntityByName("info_particle_system");
	if (particle > 0 && IsValidEntity(particle))
	{
		DispatchKeyValue(particle, "effect_name", PARTICLE_LASER);
		DispatchKeyValue(particle, "cpoint1", targetName);
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
 * Obtiene la posición del ojo del jugador (para el endpoint del láser)
 */
stock void LaserRounds_GetPlayerEye(int client, float position[3])
{
	float eyePos[3], eyeAngles[3], direction[3];

	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAngles);

	// Crear un trace hacia adelante
	Handle trace = TR_TraceRayFilterEx(eyePos, eyeAngles, MASK_SHOT, RayType_Infinite, LaserRounds_TraceFilter, client);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(position, trace);
	}
	else
	{
		// Si no impacta nada, usar una posición muy lejana
		GetAngleVectors(eyeAngles, direction, NULL_VECTOR, NULL_VECTOR);
		position[0] = eyePos[0] + direction[0] * 10000.0;
		position[1] = eyePos[1] + direction[1] * 10000.0;
		position[2] = eyePos[2] + direction[2] * 10000.0;
	}

	delete trace;
}

/**
 * Filtro para el trace del láser
 */
public bool LaserRounds_TraceFilter(int entity, int contentsMask, int client)
{
	return entity != client;
}

/**
 * Obtiene el multiplicador de daño
 * Debe ser llamado desde OnTakeDamage
 */
public float LaserRounds_GetDamageMultiplier(int attacker)
{
	if (g_bLaserRounds_Enabled[attacker])
	{
		return GetConVarFloat(cvar_LaserRounds_DamageBonus);
	}

	return 1.0;
}

/**
 * Obtiene si Laser Rounds está habilitado para un jugador
 */
public bool LaserRounds_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bLaserRounds_Enabled[client];
}
