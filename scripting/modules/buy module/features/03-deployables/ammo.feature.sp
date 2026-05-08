/**
 * ============================================================================
 * ECLIPSE MANAGEMENT SYSTEM — AMMO SPAWN MODULE
 * ============================================================================
 * Spawnea pilas/packs de municion donde apunta el jugador.
 * Limite de distancia: CONFIG_AMMO_MAX_DIST unidades (~3 metros = ~192 u.)
 *
 * API publica:
 *   SpawnAmmo(int client, AmmoKind kind)
 *   SpawnAmmoByName(int client, const char[] typeName)
 *   AmmoPile_ResetCooldown(int client)
 *   AmmoSpawn_OnClientDisconnect(int client)
 * ============================================================================
 */

#if !defined EMS_MAIN_FILE
	#error Compile from "Eclipse Management System.sp". Este es un modulo auxiliar.
#endif

// ============================================================================
// Defines (override desde main si es necesario)
// ============================================================================
#if !defined CONFIG_AMMO_PILE_COOLDOWN
	#define CONFIG_AMMO_PILE_COOLDOWN 30.0
#endif
#if !defined CONFIG_AMMO_PILE_LIFETIME
	#define CONFIG_AMMO_PILE_LIFETIME 60.0
#endif
#if !defined CONFIG_AMMO_MAX_DIST
	#define CONFIG_AMMO_MAX_DIST 192.0	  // ~3 metros en unidades Hammer
#endif

// ============================================================================
// Tipos
// ============================================================================
enum AmmoKind
{
	AMMO_PILE		= 0,
	AMMO_EXPLOSIVE	= 1,
	AMMO_INCENDIARY = 2,
	AMMO_KINDS_COUNT
};

// ============================================================================
// Constantes de classnames
// ============================================================================
static const char g_AmmoAlias[AMMO_KINDS_COUNT][] = {
	"pile",
	"explosive",
	"incendiary"
};

// Classnames ordenados por probabilidad de exito (primero el mas comun)
static const char g_ClassPile[1][] = {
	"weapon_ammo_spawn"
};

static const char g_ClassExplosive[2][] = {
	"upgrade_ammo_explosive_spawn",
	"weapon_upgradepack_explosive"
};

static const char g_ClassIncendiary[2][] = {
	"upgrade_ammo_incendiary_spawn",
	"weapon_upgradepack_incendiary"
};

// ============================================================================
// Estado — bool en vez de timestamp, inmune a reinicios de GetGameTime
// ============================================================================
static bool   g_bReady[MAXPLAYERS + 1][AMMO_KINDS_COUNT];
static ConVar g_cvDebug;

// ============================================================================
// Init
// ============================================================================
public void AmmoSpawn_OnPluginStart()
{
	g_cvDebug = CreateConVar("ems_ammo_debug", "0", "Debug del modulo de ammo spawn", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	RegAdminCmd("sm_spawnammo", Cmd_SpawnAmmo, ADMFLAG_CHEATS, "Spawnea municion: sm_spawnammo <pile|explosive|incendiary>");

	// Todos listos al arrancar
	for (int i = 1; i <= MaxClients; i++)
		AmmoPile_ResetCooldown(i);
}

// ============================================================================
// Lifecycle
// ============================================================================

/**
 * Llamar desde BuyMenu_OnClientPutInServer y OnClientDisconnect.
 */
public void AmmoSpawn_OnClientDisconnect(int client)
{
	AmmoPile_ResetCooldown(client);
}

// ============================================================================
// Logging interno
// ============================================================================
static void _DLog(int client, const char[] fmt, any...)
{
	if (!g_cvDebug.BoolValue) return;
	char msg[256];
	VFormat(msg, sizeof(msg), fmt, 3);
	LogMessage("[AmmoSpawn] %s", msg);
	if (client > 0 && IsClientInGame(client))
		PrintToChat(client, "\x04[AmmoSpawn DBG]\x01 %s", msg);
}

static void _ELog(int client, const char[] fmt, any...)
{
	char msg[256];
	VFormat(msg, sizeof(msg), fmt, 3);
	LogError("[AmmoSpawn] %s", msg);
	if (client > 0 && IsClientInGame(client))
		PrintToChat(client, "\x02[AmmoSpawn ERR]\x01 %s", msg);
}

// ============================================================================
// Comando admin
// ============================================================================
public Action Cmd_SpawnAmmo(int client, int args)
{
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		if (client > 0) PrintToChat(client, "[Ammo] Debes estar vivo para usar esto.");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		PrintToChat(client, "[Ammo] Uso: sm_spawnammo <pile|explosive|incendiary>");
		return Plugin_Handled;
	}

	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	SpawnAmmoByName(client, arg);
	return Plugin_Handled;
}

// ============================================================================
// API publica
// ============================================================================

/**
 * Resetea el cooldown de todos los tipos para un jugador.
 * Seguro de llamar en spawn, cambio de mapa y disconnect.
 */
stock void AmmoPile_ResetCooldown(int client)
{
	for (int i = 0; i < view_as<int>(AMMO_KINDS_COUNT); i++)
		g_bReady[client][i] = true;
}

/**
 * Spawnea municion por nombre de tipo.
 */
stock void SpawnAmmoByName(int client, const char[] typeName)
{
	for (int i = 0; i < view_as<int>(AMMO_KINDS_COUNT); i++)
	{
		if (StrEqual(typeName, g_AmmoAlias[i], false))
		{
			SpawnAmmo(client, view_as<AmmoKind>(i));
			return;
		}
	}
	PrintToChat(client, "[Ammo] Tipo invalido: '%s' (pile | explosive | incendiary)", typeName);
}

/**
 * Spawnea municion del tipo dado en el punto de mira del cliente.
 * Usa bool de disponibilidad en vez de timestamps — inmune a cambios de mapa.
 */
stock void SpawnAmmo(int client, AmmoKind kind)
{
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	// Verificar cooldown
	if (!g_bReady[client][kind])
	{
		PrintToChat(client, "[Ammo] \x04%s\x01 aun en cooldown (\x05%.0fs\x01).", g_AmmoAlias[kind], CONFIG_AMMO_PILE_COOLDOWN);
		return;
	}

	// Raycast con validacion de distancia
	float hitPos[3];
	if (!_GetAimPoint(client, hitPos))
	{
		PrintToChat(client, "[Ammo] No hay superficie valida frente a ti.");
		return;
	}

	// Crear entidad
	int ent = _SpawnEntity(client, kind, hitPos);
	if (ent == -1)
	{
		PrintToChat(client, "[Ammo] No se pudo crear la entidad para '%s'.", g_AmmoAlias[kind]);
		return;
	}

	// Marcar como no disponible e iniciar cooldown
	g_bReady[client][kind] = false;

	// Empaquetar client + kind en un solo int para el timer
	int data = client * 10 + view_as<int>(kind);
	CreateTimer(CONFIG_AMMO_PILE_COOLDOWN, _Timer_AmmoCooldown, data);
	CreateTimer(CONFIG_AMMO_PILE_LIFETIME, _Timer_KillEnt, EntIndexToEntRef(ent));

	PrintToChat(client, "[Ammo] \x04%s\x01 spawneado. (vida \x05%.0fs\x01, cd \x05%.0fs\x01)",
				g_AmmoAlias[kind], CONFIG_AMMO_PILE_LIFETIME, CONFIG_AMMO_PILE_COOLDOWN);
}

// ============================================================================
// Timers
// ============================================================================

/**
 * Restaura disponibilidad del tipo de ammo para el jugador.
 */
public Action _Timer_AmmoCooldown(Handle timer, any data)
{
	int client	 = data / 10;
	AmmoKind kind = view_as<AmmoKind>(data % 10);

	if (client > 0 && client <= MaxClients && IsClientInGame(client))
		g_bReady[client][kind] = true;

	return Plugin_Stop;
}

/**
 * Destruye la entidad de ammo al expirar su vida util.
 */
public Action _Timer_KillEnt(Handle timer, any entRef)
{
	int ent = EntRefToEntIndex(entRef);
	if (ent != -1 && IsValidEntity(ent))
		AcceptEntityInput(ent, "Kill");
	return Plugin_Stop;
}

// ============================================================================
// Raycast
// ============================================================================

/**
 * Lanza un ray desde los ojos del cliente y devuelve el punto de impacto
 * si esta dentro de CONFIG_AMMO_MAX_DIST. Devuelve false si no hay impacto
 * o si esta fuera de rango.
 */
static bool _GetAimPoint(int client, float outPos[3])
{
	float eyePos[3], eyeAng[3];
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);

	_DLog(client, "Raycast desde (%.1f, %.1f, %.1f)", eyePos[0], eyePos[1], eyePos[2]);

	Handle trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SOLID, RayType_Infinite, _TraceFilter, client);
	bool   hit	 = TR_DidHit(trace);
	if (hit)
		TR_GetEndPosition(outPos, trace);
	delete trace;

	if (!hit)
	{
		_DLog(client, "Raycast sin impacto.");
		return false;
	}

	// Validar distancia
	float dist = GetVectorDistance(eyePos, outPos);
	_DLog(client, "Impacto a %.1f unidades (max %.1f)", dist, CONFIG_AMMO_MAX_DIST);

	if (dist > CONFIG_AMMO_MAX_DIST)
	{
		PrintToChat(client, "[Ammo] Superficie demasiado lejos (%.1f u. / max %.0f u.).", dist, CONFIG_AMMO_MAX_DIST);
		return false;
	}

	outPos[2] += 2.0;	 // pequeno offset para que no quede enterrado
	return true;
}

public bool _TraceFilter(int entity, int contentsMask, any data)
{
	return entity != data;	  // ignorar al propio cliente
}

// ============================================================================
// Spawn de entidades
// ============================================================================

static int _SpawnEntity(int client, AmmoKind kind, const float pos[3])
{
	switch (kind)
	{
		case AMMO_PILE:
		{
			for (int i = 0; i < sizeof(g_ClassPile); i++)
			{
				int ent = _TrySpawn(client, g_ClassPile[i], pos, false);
				if (ent != -1) return ent;
			}
		}
		case AMMO_EXPLOSIVE:
		{
			for (int i = 0; i < sizeof(g_ClassExplosive); i++)
			{
				int ent = _TrySpawn(client, g_ClassExplosive[i], pos, true);
				if (ent != -1) return ent;
			}
		}
		case AMMO_INCENDIARY:
		{
			for (int i = 0; i < sizeof(g_ClassIncendiary); i++)
			{
				int ent = _TrySpawn(client, g_ClassIncendiary[i], pos, true);
				if (ent != -1) return ent;
			}
		}
	}
	return -1;
}

/**
 * Intenta crear y spawnear una entidad.
 * isUpgrade=true activa inputs adicionales para packs de upgrade.
 */
static int _TrySpawn(int client, const char[] classname, const float pos[3], bool isUpgrade)
{
	_DLog(client, "Intentando '%s' (upgrade=%d)...", classname, isUpgrade ? 1 : 0);

	int ent = CreateEntityByName(classname);
	if (ent == -1)
	{
		_ELog(client, "CreateEntityByName('%s') fallo.", classname);
		return -1;
	}

	DispatchKeyValue(ent, "solid", "6");	// SOLID_VPHYSICS

	if (isUpgrade)
	{
		DispatchKeyValue(ent, "spawnflags", "0");
		DispatchKeyValue(ent, "count", "1");
	}

	DispatchSpawn(ent);

	if (!IsValidEntity(ent))
	{
		_ELog(client, "DispatchSpawn('%s') invalido la entidad.", classname);
		return -1;
	}

	float ang[3];	 // {0,0,0}
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
	SetEntityMoveType(ent, MOVETYPE_NONE);

	if (isUpgrade)
	{
		AcceptEntityInput(ent, "Enable");
		AcceptEntityInput(ent, "TurnOn");
	}

	_DLog(client, "OK '%s' ent=%d pos=(%.1f, %.1f, %.1f)", classname, ent, pos[0], pos[1], pos[2]);
	return ent;
}
stock bool AmmoPile_IsReady(int client, AmmoKind kind)
{
    return g_bReady[client][kind];
}