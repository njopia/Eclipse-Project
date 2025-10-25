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
}

/**
 * Resetea el estado al conectar
 */
public void LaserRounds_OnClientConnect(int client)
{
	g_bLaserRounds_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void LaserRounds_OnClientDisconnect(int client)
{
	g_bLaserRounds_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void LaserRounds_OnPlayerSpawn(int client, int level)
{
	if (LaserRounds_IsUnlocked(client, level))
	{
		g_bLaserRounds_Enabled[client] = true;
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

	// Verificar si el viewmodel es un arma compatible
	int viewmodel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
	if (viewmodel > 0 && IsValidEntity(viewmodel) && LaserRounds_IsLaserViewModel(viewmodel))
	{
		float origin[3];
		LaserRounds_GetPlayerEye(client, origin);

		// Crear efecto láser
		LaserRounds_CreateLaser(viewmodel, origin);

		// Sonido de láser
		EmitSoundToAll("ambient/energy/zap6.wav", client, SNDCHAN_AUTO, SNDLEVEL_HOME, SND_NOFLAGS, SNDVOL_NORMAL, 125);
	}

	return Plugin_Continue;
}

/**
 * Verifica si un viewmodel es compatible con láser
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
