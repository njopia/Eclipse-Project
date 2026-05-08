#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === SENTRY GUN FEATURE ===
// Torreta automatica desplegable, nivel 28.
// Sin currency. Cooldown 300s. Vida 300s.
// Escanea y dispara a infectados en rango/LOS.
//==================================================

#define _SENTRY_GUN_FEATURE_

#define SENTRY_MODEL           "models/w_models/weapons/50cal.mdl"
#define SENTRY_PARTICLE_MUZZLE "weapon_muzzle_flash_autoshotgun"
#define SENTRY_PARTICLE_BLOOD  "blood_impact_red_01"

#define SENTRY_DAMAGE      30
#define SENTRY_RANGE       1500.0
#define SENTRY_FIRE_RATE   0.07
#define SENTRY_FOV_COS     0.73   // ~43 degrees half-angle
#define SENTRY_TURN_YAW    180.0  // degrees per second
#define SENTRY_TURN_PITCH  45.0   // degrees per second
#define SENTRY_LIFETIME    300.0
#define SENTRY_COOLDOWN    300.0
#define SENTRY_WARN_AT     250.0  // seconds remaining when warning fires

// NeverTarget options
#define SENTRY_NT_NONE    0
#define SENTRY_NT_SMOKER  1
#define SENTRY_NT_BOOMER  2
#define SENTRY_NT_HUNTER  3
#define SENTRY_NT_SPITTER 4
#define SENTRY_NT_JOCKEY  5
#define SENTRY_NT_CHARGER 6

// TargetFirst options
#define SENTRY_TF_NONE    0
#define SENTRY_TF_TANK    1
#define SENTRY_TF_WITCH   2
#define SENTRY_TF_SPECIAL 3

// --- Per-player state ---
int   g_iSentryEnt[MAXPLAYERS + 1];
float g_fSentryAngle[MAXPLAYERS + 1][3];
float g_fSentryLifeEnd[MAXPLAYERS + 1];
float g_fSentryCooldownEnd[MAXPLAYERS + 1];
bool  g_bSentryWarned[MAXPLAYERS + 1];
int   g_iSentryTarget[MAXPLAYERS + 1];
float g_fSentryNextFire[MAXPLAYERS + 1];
int   g_iSentryNeverTarget[MAXPLAYERS + 1];
int   g_iSentryTargetFirst[MAXPLAYERS + 1];

// =============================================================================
// LIFECYCLE
// =============================================================================

void SentryGun_OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++)
		_SG_ResetClient(i);
}

void SentryGun_OnMapStart()
{
	PrecacheModel(SENTRY_MODEL, true);
	CreateTimer(SENTRY_FIRE_RATE, _SG_ThinkAll, _, TIMER_REPEAT);
}

void SentryGun_OnPlayerDeath(int client)
{
	SentryGun_Destroy(client);
}

void SentryGun_OnClientDisconnect(int client)
{
	SentryGun_Destroy(client);
	_SG_ResetClient(client);
}

void SentryGun_ResetCooldown(int client)
{
	g_fSentryCooldownEnd[client] = 0.0;
}

static void _SG_ResetClient(int client)
{
	g_iSentryEnt[client]         = INVALID_ENT_REFERENCE;
	g_fSentryLifeEnd[client]     = 0.0;
	g_fSentryCooldownEnd[client] = 0.0;
	g_bSentryWarned[client]      = false;
	g_iSentryTarget[client]      = INVALID_ENT_REFERENCE;
	g_fSentryNextFire[client]    = 0.0;
	g_iSentryNeverTarget[client] = SENTRY_NT_NONE;
	g_iSentryTargetFirst[client] = SENTRY_TF_NONE;
	g_fSentryAngle[client][0]    = 0.0;
	g_fSentryAngle[client][1]    = 0.0;
	g_fSentryAngle[client][2]    = 0.0;
}

// =============================================================================
// DEPLOY / DESTROY
// =============================================================================

bool SentryGun_CanDeploy(int client)
{
	if (g_fSentryCooldownEnd[client] > GetGameTime()) return false;
	return !SentryGun_IsActive(client);
}

int SentryGun_GetCooldownRemaining(int client)
{
	float rem = g_fSentryCooldownEnd[client] - GetGameTime();
	return rem > 0.0 ? RoundToFloor(rem) : 0;
}

bool SentryGun_IsActive(int client)
{
	if (g_iSentryEnt[client] == INVALID_ENT_REFERENCE) return false;
	int ent = EntRefToEntIndex(g_iSentryEnt[client]);
	return (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent));
}

void SentryGun_Deploy(int client)
{
	if (!(GetEntityFlags(client) & FL_ONGROUND))
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Debes estar en el suelo para desplegar la Sentry Gun.");
		return;
	}

	float vPos[3], vAng[3];
	GetClientAbsOrigin(client, vPos);
	GetClientAbsAngles(client, vAng);
	vPos[2] += 2.0;
	vAng[0]  = 0.0;

	int ent = CreateEntityByName("prop_dynamic_override");
	if (ent < 1)
	{
		PrintToChat(client, "\x04[Eclipse]\x01 No se pudo crear la Sentry Gun.");
		return;
	}

	DispatchKeyValue(ent, "model",          SENTRY_MODEL);
	DispatchKeyValue(ent, "solid",          "6");
	DispatchKeyValue(ent, "disableshadows", "1");
	DispatchKeyValue(ent, "rendermode",     "0");
	DispatchSpawn(ent);
	TeleportEntity(ent, vPos, vAng, NULL_VECTOR);

	g_iSentryEnt[client]         = EntIndexToEntRef(ent);
	g_fSentryAngle[client]       = vAng;
	g_fSentryLifeEnd[client]     = GetGameTime() + SENTRY_LIFETIME;
	g_bSentryWarned[client]      = false;
	g_iSentryTarget[client]      = INVALID_ENT_REFERENCE;
	g_fSentryNextFire[client]    = 0.0;

	PrintToChat(client, "\x04[Sentry]\x01 Sentry Gun desplegada. Duracion: \x05%ds\x01.", RoundToFloor(SENTRY_LIFETIME));

	// warn timer fires when 50s remain
	CreateTimer(SENTRY_WARN_AT, _SG_WarnTimer, GetClientUserId(client));
}

void SentryGun_Destroy(int client)
{
	if (g_iSentryEnt[client] == INVALID_ENT_REFERENCE) return;
	int ent = EntRefToEntIndex(g_iSentryEnt[client]);
	if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
		RemoveEntity(ent);
	g_iSentryEnt[client]         = INVALID_ENT_REFERENCE;
	g_iSentryTarget[client]      = INVALID_ENT_REFERENCE;
	g_fSentryCooldownEnd[client] = GetGameTime() + SENTRY_COOLDOWN;
}

public Action _SG_WarnTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client)) return Plugin_Stop;
	if (!SentryGun_IsActive(client) || g_bSentryWarned[client]) return Plugin_Stop;
	g_bSentryWarned[client] = true;
	PrintToChat(client, "\x04[Sentry]\x01 \x05Advertencia:\x01 Tu Sentry Gun se destruira en \x0550s\x01.");
	return Plugin_Stop;
}

// =============================================================================
// THINK LOOP
// =============================================================================

public Action _SG_ThinkAll(Handle timer)
{
	float now = GetGameTime();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || !IsSurvivor(i)) continue;
		if (g_iSentryEnt[i] == INVALID_ENT_REFERENCE) continue;

		int ent = EntRefToEntIndex(g_iSentryEnt[i]);
		if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent))
		{
			g_iSentryEnt[i]         = INVALID_ENT_REFERENCE;
			g_fSentryCooldownEnd[i] = now + SENTRY_COOLDOWN;
			continue;
		}

		if (now >= g_fSentryLifeEnd[i])
		{
			PrintToChat(i, "\x04[Sentry]\x01 Tu Sentry Gun ha expirado.");
			SentryGun_Destroy(i);
			continue;
		}

		_SG_Think(i, ent, now);
	}
	return Plugin_Continue;
}

static void _SG_Think(int client, int ent, float now)
{
	// Validate current target
	int target = -1;
	if (g_iSentryTarget[client] != INVALID_ENT_REFERENCE)
	{
		int tEnt = EntRefToEntIndex(g_iSentryTarget[client]);
		if (tEnt != INVALID_ENT_REFERENCE && IsValidEntity(tEnt) && _SG_IsValidTarget(tEnt))
			target = tEnt;
		else
			g_iSentryTarget[client] = INVALID_ENT_REFERENCE;
	}

	if (target == -1)
		target = _SG_FindTarget(client, ent);

	if (target == -1) return;

	// Compute desired angles
	float vFrom[3], vTo[3];
	GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vFrom);
	_SG_GetTargetCenter(target, vTo);

	float dx      = vTo[0] - vFrom[0];
	float dy      = vTo[1] - vFrom[1];
	float dz      = vTo[2] - vFrom[2];
	float dist2d  = SquareRoot(dx * dx + dy * dy);

	float wantYaw   = RadToDeg(ArcTangent2(dy, dx));
	float wantPitch = RadToDeg(ArcTangent2(-dz, dist2d));

	float maxYaw    = SENTRY_TURN_YAW   * SENTRY_FIRE_RATE;
	float maxPitch  = SENTRY_TURN_PITCH * SENTRY_FIRE_RATE;

	float dyaw   = _SG_AngleDiff(wantYaw,   g_fSentryAngle[client][1]);
	float dpitch = _SG_AngleDiff(wantPitch, g_fSentryAngle[client][0]);

	if (FloatAbs(dyaw)   > maxYaw)   dyaw   = (dyaw   > 0.0) ? maxYaw   : -maxYaw;
	if (FloatAbs(dpitch) > maxPitch) dpitch = (dpitch > 0.0) ? maxPitch : -maxPitch;

	g_fSentryAngle[client][0] += dpitch;
	g_fSentryAngle[client][1] += dyaw;
	g_fSentryAngle[client][2]  = 0.0;

	TeleportEntity(ent, NULL_VECTOR, g_fSentryAngle[client], NULL_VECTOR);

	// Fire when aimed close enough
	if (FloatAbs(_SG_AngleDiff(wantYaw,   g_fSentryAngle[client][1])) < 5.0
	&&  FloatAbs(_SG_AngleDiff(wantPitch, g_fSentryAngle[client][0])) < 5.0
	&&  now >= g_fSentryNextFire[client])
	{
		if (_SG_HasLOS(vFrom, vTo, target))
		{
			_SG_Fire(client, ent, target, vFrom, vTo);
			g_fSentryNextFire[client] = now + SENTRY_FIRE_RATE;
		}
	}
}

static int _SG_FindTarget(int client, int ent)
{
	float vPos[3];
	GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vPos);

	int   bestEnt = -1;
	float bestPri = -1.0;

	// Iterate all clients (special infected, tank)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!_SG_IsValidTarget(i)) continue;
		if (_SG_NeverTarget(client, i)) continue;

		float vTgt[3];
		GetClientAbsOrigin(i, vTgt);
		vTgt[2] += 36.0;

		float dist = GetVectorDistance(vPos, vTgt);
		if (dist > SENTRY_RANGE) continue;
		if (!_SG_InFOV(vPos, vTgt, client)) continue;
		if (!_SG_HasLOS(vPos, vTgt, i)) continue;

		float pri = 1000.0 / (dist + 1.0);
		if (_SG_IsTargetFirst(client, i)) pri += 1000.0;
		if (pri > bestPri) { bestPri = pri; bestEnt = i; }
	}

	// Iterate entities (common infected, witch)
	for (int i = MaxClients + 1; i < 2048; i++)
	{
		if (!IsValidEdict(i) || !IsValidEntity(i)) continue;
		if (!_SG_IsValidTarget(i)) continue;

		float vTgt[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vTgt);
		vTgt[2] += 36.0;

		float dist = GetVectorDistance(vPos, vTgt);
		if (dist > SENTRY_RANGE) continue;
		if (!_SG_InFOV(vPos, vTgt, client)) continue;
		if (!_SG_HasLOS(vPos, vTgt, i)) continue;

		float pri = 1000.0 / (dist + 1.0);
		if (_SG_IsTargetFirst(client, i)) pri += 1000.0;
		if (pri > bestPri) { bestPri = pri; bestEnt = i; }
	}

	if (bestEnt != -1)
		g_iSentryTarget[client] = EntIndexToEntRef(bestEnt);

	return bestEnt;
}

// True if target is a living infected entity or client
static bool _SG_IsValidTarget(int ent)
{
	if (ent >= 1 && ent <= MaxClients)
	{
		// Special infected / tank (team 3 clients)
		if (!IsClientInGame(ent) || !IsPlayerAlive(ent)) return false;
		return GetClientTeam(ent) == 3;
	}
	// Common infected
	if (IsInfected(ent))
	{
		return GetEntProp(ent, Prop_Data, "m_iHealth") > 0;
	}
	// Witch
	return IsWitch(ent);
}

static bool _SG_NeverTarget(int client, int target)
{
	int nt = g_iSentryNeverTarget[client];
	if (nt == SENTRY_NT_NONE) return false;
	// NeverTarget only applies to special infected (clients on team 3)
	if (target < 1 || target > MaxClients) return false;
	if (!IsClientInGame(target) || !IsPlayerAlive(target)) return false;
	if (GetClientTeam(target) != 3) return false;
	int zc = GetEntProp(target, Prop_Send, "m_zombieClass");
	switch (nt)
	{
		case SENTRY_NT_SMOKER:  return zc == ZOMBIECLASS_SMOKER;
		case SENTRY_NT_BOOMER:  return zc == ZOMBIECLASS_BOOMER;
		case SENTRY_NT_HUNTER:  return zc == ZOMBIECLASS_HUNTER;
		case SENTRY_NT_SPITTER: return zc == ZOMBIECLASS_SPITTER;
		case SENTRY_NT_JOCKEY:  return zc == ZOMBIECLASS_JOCKEY;
		case SENTRY_NT_CHARGER: return zc == ZOMBIECLASS_CHARGER;
	}
	return false;
}

static bool _SG_IsTargetFirst(int client, int target)
{
	int tf = g_iSentryTargetFirst[client];
	if (tf == SENTRY_TF_NONE) return false;
	if (tf == SENTRY_TF_WITCH)
		return (target > MaxClients && IsWitch(target));
	if (target < 1 || target > MaxClients) return false;
	if (!IsClientInGame(target) || !IsPlayerAlive(target)) return false;
	if (GetClientTeam(target) != 3) return false;
	int zc = GetEntProp(target, Prop_Send, "m_zombieClass");
	if (tf == SENTRY_TF_TANK)    return zc == ZOMBIECLASS_TANK;
	if (tf == SENTRY_TF_SPECIAL) return zc >= 1 && zc <= 6;
	return false;
}

static bool _SG_InFOV(float vFrom[3], float vTo[3], int client)
{
	float vDir[3];
	vDir[0] = vTo[0] - vFrom[0];
	vDir[1] = vTo[1] - vFrom[1];
	vDir[2] = vTo[2] - vFrom[2];
	NormalizeVector(vDir, vDir);

	float vFwd[3];
	GetAngleVectors(g_fSentryAngle[client], vFwd, NULL_VECTOR, NULL_VECTOR);
	return GetVectorDotProduct(vDir, vFwd) >= SENTRY_FOV_COS;
}

static bool _SG_HasLOS(float vFrom[3], float vTo[3], int ignoreEnt)
{
	TR_TraceRayFilter(vFrom, vTo, MASK_SOLID, RayType_EndPoint, _SG_TraceFilter, ignoreEnt);
	return !TR_DidHit();
}

public bool _SG_TraceFilter(int entity, int contentsMask, int ignoreEnt)
{
	if (entity == ignoreEnt) return false;
	if (entity > 0 && entity <= MaxClients) return false;
	return true;
}

static void _SG_GetTargetCenter(int target, float vOut[3])
{
	if (target >= 1 && target <= MaxClients)
		GetClientAbsOrigin(target, vOut);
	else
		GetEntPropVector(target, Prop_Data, "m_vecOrigin", vOut);
	vOut[2] += 36.0;
}

static void _SG_Fire(int client, int ent, int target, float vFrom[3], float vTo[3])
{
	// Muzzle flash
	int muzzle = CreateEntityByName("info_particle_system");
	if (muzzle > 0)
	{
		DispatchKeyValue(muzzle, "effect_name",  SENTRY_PARTICLE_MUZZLE);
		DispatchKeyValue(muzzle, "start_active", "1");
		DispatchSpawn(muzzle);
		ActivateEntity(muzzle);
		TeleportEntity(muzzle, vFrom, NULL_VECTOR, NULL_VECTOR);
		CreateTimer(0.15, _SG_KillParticle, EntIndexToEntRef(muzzle));
	}

	// Damage
	if (target > MaxClients)
	{
		// Common infected or witch → entity-based damage
		DealDamageEntity(target, client, DMG_BULLET, SENTRY_DAMAGE, "sentry_gun");
	}
	else
	{
		// Special infected or tank → client-based damage
		SDKHooks_TakeDamage(target, ent, client, float(SENTRY_DAMAGE), DMG_BULLET);
	}

	// Blood at impact point
	int blood = CreateEntityByName("info_particle_system");
	if (blood > 0)
	{
		DispatchKeyValue(blood, "effect_name",  SENTRY_PARTICLE_BLOOD);
		DispatchKeyValue(blood, "start_active", "1");
		DispatchSpawn(blood);
		ActivateEntity(blood);
		TeleportEntity(blood, vTo, NULL_VECTOR, NULL_VECTOR);
		CreateTimer(0.5, _SG_KillParticle, EntIndexToEntRef(blood));
	}
}

public Action _SG_KillParticle(Handle timer, int entref)
{
	int ent = EntRefToEntIndex(entref);
	if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
		RemoveEntity(ent);
	return Plugin_Stop;
}

static float _SG_AngleDiff(float a, float b)
{
	float d = a - b;
	while (d >  180.0) d -= 360.0;
	while (d < -180.0) d += 360.0;
	return d;
}

// =============================================================================
// CONFIG MENU  (!sentrycontrol)
// =============================================================================

public Action Cmd_SentryControl(int client, int args)
{
	if (!IsSurvivor(client))
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Solo disponible para sobrevivientes.");
		return Plugin_Handled;
	}
	SentryGun_ShowControlMenu(client);
	return Plugin_Handled;
}

void SentryGun_ShowControlMenu(int client)
{
	Menu menu = new Menu(SentryGun_ControlMenuHandler);
	menu.SetTitle("Sentry Gun Config\n=================");

	static const char sNT[7][] = {
		"NeverTarget: Ninguno",
		"NeverTarget: Smoker",
		"NeverTarget: Boomer",
		"NeverTarget: Hunter",
		"NeverTarget: Spitter",
		"NeverTarget: Jockey",
		"NeverTarget: Charger"
	};
	static const char sTF[4][] = {
		"TargetFirst: Ninguno",
		"TargetFirst: Tank",
		"TargetFirst: Witch",
		"TargetFirst: Especiales"
	};

	char info[8], text[48];
	for (int i = 0; i < 7; i++)
	{
		Format(info, sizeof(info), "nt%d", i);
		Format(text, sizeof(text), "%s%s", sNT[i], g_iSentryNeverTarget[client] == i ? " [*]" : "");
		menu.AddItem(info, text);
	}
	for (int i = 0; i < 4; i++)
	{
		Format(info, sizeof(info), "tf%d", i);
		Format(text, sizeof(text), "%s%s", sTF[i], g_iSentryTargetFirst[client] == i ? " [*]" : "");
		menu.AddItem(info, text);
	}

	menu.ExitButton = true;
	menu.Display(client, 30);
}

public int SentryGun_ControlMenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(item, info, sizeof(info));
		if (info[0] == 'n' && info[1] == 't')
			g_iSentryNeverTarget[client] = StringToInt(info[2]);
		else if (info[0] == 't' && info[1] == 'f')
			g_iSentryTargetFirst[client] = StringToInt(info[2]);
		SentryGun_ShowControlMenu(client);
	}
	else if (action == MenuAction_End)
		delete menu;
	return 0;
}
