/**
 * L4D2 - Spawn de pila/packs de munición donde apuntas, con cooldown, vida y DEBUG.
 *
 * Comando:
 *   sm_spawnammo <pile|explosive|incendiary>
 *
 * API:
 *   SpawnAmmoByName(int client, const char[] typeName);
 *   SpawnAmmo(int client, AmmoKind kind);
 */

// ===== Config =====
#define RAYCAST_MAXDIST 1200.0

ConVar g_cvarDebug;

// ===== Tipos =====
enum AmmoKind
{
	AMMO_PILE		= 0,
	AMMO_EXPLOSIVE	= 1,
	AMMO_INCENDIARY = 2,
	AMMO_KINDS_COUNT
};

static const char g_AmmoAlias[AMMO_KINDS_COUNT][] = {
	"pile",
	"explosive",
	"incendiary"
};

// Pila estándar (1 candidato)
static const char g_ClassPile[][] = {
	"weapon_ammo_spawn"
};

// Explosive: probamos ambas familias
static const char g_ClassExplosive[][] = {
	"weapon_upgradepack_explosive",	   // carry/deploy
	"upgrade_ammo_explosive_spawn"	   // spawn mapeable
};

// Incendiary: probamos ambas familias
static const char g_ClassIncendiary[][] = {
	"weapon_upgradepack_incendiary",	// carry/deploy
	"upgrade_ammo_incendiary_spawn"		// spawn mapeable
};

// cooldown por jugador y tipo
float g_LastUse[MAXPLAYERS + 1][AMMO_KINDS_COUNT];

/**
 * Resetea el cooldown de Ammo Pile para un jugador
 */
stock void AmmoPile_ResetCooldown(int client)
{
	for (int i = 0; i < view_as<int>(AMMO_KINDS_COUNT); i++)
	{
		g_LastUse[client][i] = 0.0;
	}
}


// ======================================================================
// Helpers de debug

static void DLog(int client, const char[] fmt, any...)
{
	if (!g_cvarDebug.BoolValue) return;

	char msg[256];
	VFormat(msg, sizeof msg, fmt, 3);
	LogMessage("%s", msg);
	if (client > 0 && IsClientInGame(client))
	{
		PrintToChat(client, "[SpawnAmmo DBG] %s", msg);
	}
}

static void ELog(int client, const char[] fmt, any...)
{
	char msg[256];
	VFormat(msg, sizeof msg, fmt, 3);
	LogError("%s", msg);
	if (client > 0 && IsClientInGame(client))
	{
		PrintToChat(client, "[SpawnAmmo ERR] %s", msg);
	}
}

// ======================================================================
// Comando
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
	ToLowerCase(arg);

	SpawnAmmoByName(client, arg);
	return Plugin_Handled;
}

// ======================================================================
// API

stock void SpawnAmmoByName(int client, const char[] typeName)
{
	AmmoKind kind  = AMMO_PILE;
	bool	 found = false;

	for (int i = 0; i < view_as<int>(AMMO_KINDS_COUNT); i++)
	{
		if (StrEqual(typeName, g_AmmoAlias[i], false))
		{
			kind  = view_as<AmmoKind>(i);
			found = true;
			break;
		}
	}

	if (!found)
	{
		PrintToChat(client, "[Ammo] Tipo invalido: %s (usa: pile | explosive | incendiary)", typeName);
		return;
	}

	SpawnAmmo(client, kind);
}

stock void SpawnAmmo(int client, AmmoKind kind)
{
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	// Cooldown
	float now  = GetGameTime();
	float last = g_LastUse[client][kind];
	float left = (CONFIG_AMMO_PILE_COOLDOWN - (now - last));
	if (left > 0.0)
	{
		PrintToChat(client, "[Ammo] Espera %.1fs para %s.", left, g_AmmoAlias[kind]);
		return;
	}

	float hitPos[3], hitNormal[3];
	if (!GetAimGroundPoint(client, hitPos, hitNormal))
	{
		ELog(client, "Raycast fallido (sin superficie).");
		PrintToChat(client, "[Ammo] No encuentro una superficie valida frente a ti.");
		return;
	}
	hitPos[2] += 2.0;

	int ent = SpawnEntityForKind(client, kind, hitPos);
	if (ent == -1)
	{
		ELog(client, "Fallo total al crear entidad para tipo '%s'.", g_AmmoAlias[kind]);
		PrintToChat(client, "[Ammo] No pude crear entidad para %s.", g_AmmoAlias[kind]);
		return;
	}

	// Vida y cooldown
	CreateTimer(CONFIG_AMMO_PILE_LIFETIME, Timer_KillEntity, EntIndexToEntRef(ent));
	g_LastUse[client][kind] = now;

	PrintToChat(client, "[Ammo] %s creado. (vida %.0fs, cd %.0fs)", g_AmmoAlias[kind], CONFIG_AMMO_PILE_LIFETIME, CONFIG_AMMO_PILE_COOLDOWN);
}

// ======================================================================
// Núcleo de spawn con fallbacks y logs

static int SpawnEntityForKind(int client, AmmoKind kind, const float pos[3])
{
	char classname[64];
	int	 ent = -1;

	if (kind == AMMO_PILE)
	{
		for (int i = 0; i < sizeof(g_ClassPile); i++)
		{
			strcopy(classname, sizeof(classname), g_ClassPile[i]);
			ent = TryCreateBaseEntity(client, classname, pos);
			if (ent != -1) return ent;
		}
		return -1;
	}

	if (kind == AMMO_EXPLOSIVE)
	{
		for (int i = 0; i < sizeof(g_ClassExplosive); i++)
		{
			strcopy(classname, sizeof(classname), g_ClassExplosive[i]);
			ent = TryCreateUpgradeEntity(client, classname, pos);
			if (ent != -1) return ent;
		}
		return -1;
	}

	if (kind == AMMO_INCENDIARY)
	{
		for (int i = 0; i < sizeof(g_ClassIncendiary); i++)
		{
			strcopy(classname, sizeof(classname), g_ClassIncendiary[i]);
			ent = TryCreateUpgradeEntity(client, classname, pos);
			if (ent != -1) return ent;
		}
		return -1;
	}

	return -1;
}

// Crea entidad pila básica
static int TryCreateBaseEntity(int client, const char[] classname, const float pos[3])
{
	DLog(client, "Intentando crear '%s' ...", classname);

	int ent = CreateEntityByName(classname);
	if (ent == -1 || !IsValidEntity(ent))
	{
		ELog(client, "CreateEntityByName('%s') devolvio %d (invalido).", classname, ent);
		return -1;
	}

	// Para la pila base suele bastar con solid y spawn
	DispatchKeyValue(ent, "solid", "6");	// SOLID_VPHYSICS

	if (!DispatchSpawnSafe(client, ent, classname))
		return -1;

	float ang[3] = { 0.0, 0.0, 0.0 };
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
	SetEntityMoveType(ent, MOVETYPE_NONE);

	DLog(client, "OK '%s' entindex=%d, pos=(%.1f, %.1f, %.1f)", classname, ent, pos[0], pos[1], pos[2]);
	return ent;
}

// Crea packs mejorados (ambas familias).
static int TryCreateUpgradeEntity(int client, const char[] classname, const float pos[3])
{
	DLog(client, "Intentando crear upgrade '%s' ...", classname);

	int ent = CreateEntityByName(classname);
	if (ent == -1 || !IsValidEntity(ent))
	{
		ELog(client, "CreateEntityByName('%s') devolvio %d (invalido).", classname, ent);
		return -1;
	}

	// Algunos mapas esperan ciertos spawnflags; poner 0 es seguro.
	DispatchKeyValue(ent, "spawnflags", "0");

	// Los 'upgrade_ammo_*_spawn' aceptan un 'count' (cuantos usan) en ciertos entornos.
	// No todos lo usan; seteamos 1 por si aplica. No falla si no existe.
	DispatchKeyValue(ent, "count", "1");

	// Poner solidez estable
	DispatchKeyValue(ent, "solid", "6");

	if (!DispatchSpawnSafe(client, ent, classname))
		return -1;

	float ang[3] = { 0.0, 0.0, 0.0 };
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
	SetEntityMoveType(ent, MOVETYPE_NONE);

	// Para algunas variantes conviene activarlas explícitamente
	AcceptEntityInput(ent, "Enable");
	AcceptEntityInput(ent, "TurnOn");
	AcceptEntityInput(ent, "Activate");

	DLog(client, "OK '%s' entindex=%d, pos=(%.1f, %.1f, %.1f)", classname, ent, pos[0], pos[1], pos[2]);
	return ent;
}

static bool DispatchSpawnSafe(int client, int ent, const char[] classname)
{
	DispatchSpawn(ent);
	if (!IsValidEntity(ent))
	{
		ELog(client, "Despues de DispatchSpawn, entidad '%s' se invalido.", classname);
		return false;
	}

	// Comprobar networkeable (útil para detectar fallos silenciosos)
	bool net = IsEntNetworkable(ent);
	DLog(client, "Post-Spawn '%s' net=%d", classname, net ? 1 : 0);
	return true;
}

// ======================================================================
// Timers
public Action Timer_KillEntity(Handle timer, any entRef)
{
	int ent = EntRefToEntIndex(entRef);
	if (ent != -1 && IsValidEntity(ent))
	{
		char cls[64];
		GetEntityClassname(ent, cls, sizeof cls);
		AcceptEntityInput(ent, "Kill");
		LogMessage("[SpawnAmmo] Autodestruyo entindex=%d classname=%s", ent, cls);
	}
	return Plugin_Stop;
}

// ======================================================================
// Raycast util

static bool GetAimGroundPoint(int client, float outPos[3], float outNormal[3])
{
	float eyePos[3], eyeAng[3];
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);

	DLog(client, "Raycast desde (%.1f, %.1f, %.1f) ang(%.1f, %.1f, %.1f)",
		 eyePos[0], eyePos[1], eyePos[2], eyeAng[0], eyeAng[1], eyeAng[2]);

	Handle trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);

	bool   hit	 = false;
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(outPos, trace);
		TR_GetPlaneNormal(trace, outNormal);
		hit = true;
		DLog(client, "Raycast HIT pos=(%.1f, %.1f, %.1f) n=(%.2f, %.2f, %.2f)",
			 outPos[0], outPos[1], outPos[2], outNormal[0], outNormal[1], outNormal[2]);
	}
	CloseHandle(trace);

	if (!hit)
	{
		float fwd[3];
		GetAngleVectors(eyeAng, fwd, NULL_VECTOR, NULL_VECTOR);

		float ahead[3];
		ahead[0] = eyePos[0] + fwd[0] * RAYCAST_MAXDIST;
		ahead[1] = eyePos[1] + fwd[1] * RAYCAST_MAXDIST;
		ahead[2] = eyePos[2] + fwd[2] * RAYCAST_MAXDIST;

		float down[3];
		float dest[3];
		down[0]	  = ahead[0];
		down[1]	  = ahead[1];
		down[2]	  = ahead[2] + 32.0;
		dest[0]	  = ahead[0];
		dest[1]	  = ahead[1];
		dest[2]	  = ahead[2] - 4096.0;

		Handle t2 = TR_TraceRayFilterEx(down, dest, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceRayDontHitSelf, client);
		if (TR_DidHit(t2))
		{
			TR_GetEndPosition(outPos, t2);
			TR_GetPlaneNormal(t2, outNormal);
			hit = true;
			DLog(client, "Fallback HIT pos=(%.1f, %.1f, %.1f) n=(%.2f, %.2f, %.2f)",
				 outPos[0], outPos[1], outPos[2], outNormal[0], outNormal[1], outNormal[2]);
		}
		CloseHandle(t2);
	}

	return hit;
}

public bool TraceRayDontHitSelf(int entity, int contentsMask, any data)
{
	int client = data;
	if (entity == client) return false;
	return true;
}

// ======================================================================
// Utils

stock void ToLowerCase(char[] str)
{
	int len = strlen(str);
	for (int i = 0; i < len; i++)
	{
		str[i] = CharToLower(str[i]);
	}
}
