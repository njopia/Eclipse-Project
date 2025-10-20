// ===== Ion Cannon (Standalone, Slow+Debug v1.1.0) =====
// Requires: sdktools, sdkhooks, sdktools_trace
// Game: L4D2 (probado); puede funcionar en otros Source con rutas adecuadas

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_trace>	 // TR_TraceRayFilter
public Plugin myinfo =
{
	name		= "Ion Cannon (Standalone, Slow+Debug)",
	author		= "Socius (port) + helper",
	description = "Marca un punto y descarga haces de energía desde el cielo con daño por pulsos y FX. Versión lenta con logging.",
	version		= "1.1.0",
	url			= ""
};

// ===================== Logging =====================
#define ION_LOGFILE "addons/sourcemod/logs/ion_cannon.log"
void IonLog(const char[] fmt, any...)
{
	static char buffer[512];
	VFormat(buffer, sizeof(buffer), fmt, 2);
	LogToFileEx(ION_LOGFILE, "[%8.3f] %s", GetGameTime(), buffer);
	PrintToServer("[Ion] %s", buffer);
}

// ===================== Config / Assets =====================

// ConVars de assets
ConVar		 g_cvModelFlare;
ConVar		 g_cvSoundCrackle;
ConVar		 g_cvSoundIon;
ConVar		 g_cvParticleFlare;	   // efecto visual de flare
ConVar		 g_cvParticleFuse;	   // humo/chispa sobre el flare
ConVar		 g_cvSpriteBeam;	   // vmt para beam
ConVar		 g_cvSpriteHalo;	   // halo del beam

// Buffers de strings precargados desde las ConVars
char		 g_sModelFlare[PLATFORM_MAX_PATH];
char		 g_sSoundCrackle[PLATFORM_MAX_PATH];
char		 g_sSoundIon[PLATFORM_MAX_PATH];
char		 g_sParticleFlare[128];
char		 g_sParticleFuse[128];
char		 g_sSpriteBeam[PLATFORM_MAX_PATH];
char		 g_sSpriteHalo[PLATFORM_MAX_PATH];

// ConVars de lógica
ConVar		 g_cvDelay;			// seg. entre flare y el disparo principal
ConVar		 g_cvWindow;		// duración total (seg)
ConVar		 g_cvPulseEvery;	// cada cuánto hace daño (seg)
ConVar		 g_cvDamageCommon;
ConVar		 g_cvDamageSI;
ConVar		 g_cvShakeNear;	   // radios shake
ConVar		 g_cvShakeMid;
ConVar		 g_cvShakeFar;

// Ritmos visuales (nuevos)
ConVar		 g_cvTickRotate;	 // intervalo (s) del orbit rotate
ConVar		 g_cvTickRing;		 // intervalo (s) de rings secundarios
ConVar		 g_cvTickCenter;	 // intervalo (s) del beam central
ConVar		 g_cvBlastRings;	 // cantidad de anillos "grandes" del blast
ConVar		 g_cvBlastGap;		 // separación entre anillos del blast (s)
ConVar		 g_cvVisualScale;	 // factor global de ralentización visual

// Acceso
ConVar		 g_cvAccessFlag;	// "" = todos, "b" admin generic, etc.

// ===================== Per-Client State =====================
static float g_IonOrigin[MAXPLAYERS + 1][3];
static float g_BeamOrigin[MAXPLAYERS + 1][6][3];
static float g_BeamDeg[MAXPLAYERS + 1][6];
static int	 g_IonEnts[MAXPLAYERS + 1][6];	  // [1]=flare prop, [2]=spotlight, [3]=particle flare, [4]=particle fuse, [5]=steam
static float g_EndTime[MAXPLAYERS + 1];		  // GameTime en que termina la ventana

// ===================== Forwards =====================
public void OnPluginStart()
{
	RegAdminCmd("sm_ion", Cmd_Ion, ADMFLAG_GENERIC, "Dispara un Ion Cannon en tu posición (o usa !ion).");
	RegConsoleCmd("say", Cmd_Say);
	RegConsoleCmd("say_team", Cmd_Say);

	// ConVars
	g_cvModelFlare	  = CreateConVar("ic_model_flare", "models/props_unique/hospital/iv_pole.mdl", "Modelo usado para marcar el punto (flare).");
	g_cvSoundCrackle  = CreateConVar("ic_sound_crackle", "ambient/energy/zap9.wav", "Sonido de crackle del flare.");
	g_cvSoundIon	  = CreateConVar("ic_sound_ion", "vehicles/airboat/fan_blade_fullthrottle_loop1.wav", "Rugido al impacto del Ion.");
	g_cvParticleFlare = CreateConVar("ic_particle_flare", "smoke_trail", "Particle name para flare (info_particle_system).");
	g_cvParticleFuse  = CreateConVar("ic_particle_fuse", "smoke_trail", "Particle name para el fuse del flare.");
	g_cvSpriteBeam	  = CreateConVar("ic_sprite_beam", "materials/sprites/laserbeam.vmt", "Sprite para beams.");
	g_cvSpriteHalo	  = CreateConVar("ic_sprite_halo", "materials/sprites/halo01.vmt", "Sprite para halo de beams.");

	g_cvDelay		  = CreateConVar("ic_delay", "6.0", "Segundos desde flare a descarga principal.");
	g_cvWindow		  = CreateConVar("ic_window", "30.0", "Duración total en segundos.");
	g_cvPulseEvery	  = CreateConVar("ic_pulse_every", "8.0", "Cada cuántos segundos se hace un pulso de daño.");
	g_cvDamageCommon  = CreateConVar("ic_dmg_common", "10", "Daño por pulso a infected/witch.");
	g_cvDamageSI	  = CreateConVar("ic_dmg_si", "10", "Daño por pulso a special infected.");
	g_cvShakeNear	  = CreateConVar("ic_shake_r1", "900", "Radio shake fuerte.");
	g_cvShakeMid	  = CreateConVar("ic_shake_r2", "1800", "Radio shake medio.");
	g_cvShakeFar	  = CreateConVar("ic_shake_r3", "2600", "Radio shake leve.");

	// Ritmos lentos por defecto
	g_cvTickRotate	  = CreateConVar("ic_tick_rotate", "1.0", "Frecuencia de rotación de haces (s).");
	g_cvTickRing	  = CreateConVar("ic_tick_ring", "2.5", "Frecuencia de anillos periódicos (s).");
	g_cvTickCenter	  = CreateConVar("ic_tick_center", "3.0", "Frecuencia del beam central (s).");
	g_cvBlastRings	  = CreateConVar("ic_blast_rings", "3", "Cantidad de anillos grandes en el blast.");
	g_cvBlastGap	  = CreateConVar("ic_blast_gap", "0.5", "Separación (s) entre anillos grandes del blast.");
	g_cvVisualScale	  = CreateConVar("ic_visual_scale", "3.0", "Factor global de ralentización visual (1.0 = normal).");

	g_cvAccessFlag	  = CreateConVar("ic_access_flag", "", "Flag requerido para usar !ion (vacío = todos). Ej: b, z, etc.");

	AutoExecConfig(true, "ion_cannon_debug");

	HookEvent("round_end", Event_Cleanup, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", Event_Cleanup, EventHookMode_PostNoCopy);

	IonLog("Plugin cargado correctamente.");
}

// Cargar todas las ConVars string en buffers (se invoca en OnMapStart y OnConfigsExecuted)
void RefreshAssetStrings()
{
	g_cvModelFlare.GetString(g_sModelFlare, sizeof(g_sModelFlare));
	g_cvSoundCrackle.GetString(g_sSoundCrackle, sizeof(g_sSoundCrackle));
	g_cvSoundIon.GetString(g_sSoundIon, sizeof(g_sSoundIon));
	g_cvParticleFlare.GetString(g_sParticleFlare, sizeof(g_sParticleFlare));
	g_cvParticleFuse.GetString(g_sParticleFuse, sizeof(g_sParticleFuse));
	g_cvSpriteBeam.GetString(g_sSpriteBeam, sizeof(g_sSpriteBeam));
	g_cvSpriteHalo.GetString(g_sSpriteHalo, sizeof(g_sSpriteHalo));
}

public void OnConfigsExecuted()
{
	RefreshAssetStrings();
	IonLog("Configs ejecutados. Assets: model=%s, soundIon=%s", g_sModelFlare, g_sSoundIon);
}

public void OnMapStart()
{
	RefreshAssetStrings();

	PrecacheModel(g_sModelFlare, true);
	PrecacheSound(g_sSoundCrackle, true);
	PrecacheSound(g_sSoundIon, true);
	PrecacheModel(g_sSpriteBeam, true);
	PrecacheModel(g_sSpriteHalo, true);

	IonLog("OnMapStart: assets precache OK.");
}

// ============ Chat trigger ============
public Action Cmd_Say(int client, int args)
{
	if (!IsValidClient(client)) return Plugin_Continue;

	char text[192];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);

	if (StrEqual(text, "!ion", false))
	{
		if (!IonHasAccess(client))
		{
			PrintToChat(client, "\x05[Ion]\x01 No tienes permiso.");
			return Plugin_Handled;
		}
		StartIonCannon(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// ============ Command ============
public Action Cmd_Ion(int client, int args)
{
	if (!IsValidClient(client)) return Plugin_Handled;
	if (!IonHasAccess(client))
	{
		ReplyToCommand(client, "[Ion] No tienes permiso.");
		return Plugin_Handled;
	}
	StartIonCannon(client);
	return Plugin_Handled;
}

// ============ Core flow ============
void StartIonCannon(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return;

	// Guardar ventana en tiempo absoluto (respetando visual scale)
	float slow		  = g_cvVisualScale.FloatValue;
	g_EndTime[client] = GetGameTime() + (g_cvWindow.FloatValue * slow);

	CreateIonFlare(client);

	float delay = g_cvDelay.FloatValue * slow;
	CreateTimer(delay, Timer_StartIonCannon, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	IonLog("StartIonCannon: client=%d slow=%.2f endT=%.2f", client, slow, g_EndTime[client]);
	PrintToChatAll("[Ion Debug] Iniciado por %N (delay %.1fs)", client, delay);
}

public Action Timer_StartIonCannon(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Stop;

	SetupOrbitBeams(client);

	float slow = g_cvVisualScale.FloatValue;

	CreateTimer(2.4 * slow, Timer_CreateIonRing, userid, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(3.0 * slow, Timer_CreateIonBlast, userid, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_cvTickRotate.FloatValue * slow, Timer_LaserRotate, userid, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_cvTickRing.FloatValue * slow, Timer_IonRingTick, userid, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_cvTickCenter.FloatValue * slow, Timer_IonCenterBeamLoop, userid, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_cvPulseEvery.FloatValue * slow, Timer_IonPulse, userid, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	IonLog("Timer_StartIonCannon: client=%d timers armados", client);
	return Plugin_Stop;
}

// Marca y FX de flare
void CreateIonFlare(int client)
{
	float org[3], ang[3];
	GetClientAbsOrigin(client, org);
	GetClientAbsAngles(client, ang);

	int prop = CreateEntityByName("prop_dynamic");
	if (prop > MaxClients && IsValidEntity(prop))
	{
		SetEntityModel(prop, g_sModelFlare);
		DispatchSpawn(prop);
		TeleportEntity(prop, org, ang, NULL_VECTOR);
		g_IonEnts[client][1] = prop;
		GetEntPropVector(prop, Prop_Send, "m_vecOrigin", g_IonOrigin[client]);

		// Sonido de crackle SOLO aquí
		EmitSoundToAll(g_sSoundCrackle, prop);
		IonLog("CreateIonFlare: prop=%d pos=(%.1f,%.1f,%.1f)", prop, org[0], org[1], org[2]);
	}

	// spotlight encima del flare
	int spot = CreateEntityByName("point_spotlight");
	if (spot > MaxClients && IsValidEntity(spot))
	{
		DispatchKeyValue(spot, "rendercolor", "200 20 15");
		DispatchKeyValue(spot, "rendermode", "9");
		DispatchKeyValue(spot, "spotlightwidth", "1");
		DispatchKeyValue(spot, "spotlightlength", "3");
		DispatchKeyValue(spot, "renderamt", "255");
		DispatchKeyValue(spot, "spawnflags", "1");
		DispatchSpawn(spot);
		AcceptEntityInput(spot, "TurnOn");
		DispatchKeyValue(spot, "angles", "90 0 0");
		TeleportEntity(spot, org, NULL_VECTOR, NULL_VECTOR);
		g_IonEnts[client][2] = spot;
	}

	// Particles sobre el flare (flare + fuse)
	float ang1[3];
	ang1[0] = -80.0;
	ang1[1] = GetRandomFloat(1.0, 360.0);
	ang1[2] = 0.0;
	int p1	= DisplayParticle(g_sParticleFlare, org, ang1);
	if (p1 > MaxClients) g_IonEnts[client][3] = p1;

	float ang2[3];
	ang2[0] = -80.0;
	ang2[1] = GetRandomFloat(1.0, 360.0);
	ang2[2] = 0.0;
	int p2	= DisplayParticle(g_sParticleFuse, org, ang2);
	if (p2 > MaxClients) g_IonEnts[client][4] = p2;

	// vapor / steam decorativo
	int steam = CreateEntityByName("env_steam");
	if (steam > MaxClients && IsValidEntity(steam))
	{
		DispatchKeyValue(steam, "SpawnFlags", "1");
		DispatchKeyValue(steam, "rendercolor", "200 20 15");
		DispatchKeyValue(steam, "SpreadSpeed", "1");
		DispatchKeyValue(steam, "Speed", "15");
		DispatchKeyValue(steam, "StartSize", "1");
		DispatchKeyValue(steam, "EndSize", "3");
		DispatchKeyValue(steam, "Rate", "10");
		DispatchKeyValue(steam, "JetLength", "100");
		DispatchKeyValue(steam, "renderamt", "60");
		DispatchKeyValue(steam, "InitialState", "1");
		DispatchSpawn(steam);
		AcceptEntityInput(steam, "TurnOn");
		TeleportEntity(steam, org, ang, NULL_VECTOR);
		g_IonEnts[client][5] = steam;
	}

	PrintToChatAll("[Ion Debug] Flare creado por %N", client);
}

// ===================== FX & Damage Timers =====================
public Action Timer_CreateIonRing(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Stop;
	IonLog("Timer_CreateIonRing start client=%d", client);
	return Plugin_Stop;
}

public Action Timer_IonRingTick(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Stop;
	if (!WindowTick(client)) return Plugin_Stop;

	float p[3];
	p = g_IonOrigin[client];
	p[2] += 20.0;

	int sBeam = PrecacheModel(g_sSpriteBeam, true);
	int sHalo = PrecacheModel(g_sSpriteHalo, true);

	// life y width ALTOS para verlo lento
	TE_SetupBeamRingPoint(p, 350.0, 1000.0, sBeam, sHalo, 0, 30, 4.0, 80.0, 5.0, { 160, 145, 255, 155 }, 0, 0);
	TE_SendToAll();

	IonLog("Timer_IonRingTick client=%d p=(%.1f,%.1f,%.1f)", client, p[0], p[1], p[2]);
	return Plugin_Continue;
}

// impacto central: beams gruesos + rings anclados al flare
public Action Timer_CreateIonBlast(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Stop;

	float flarePos[3];
	int	  flare = g_IonEnts[client][1];
	if (flare > MaxClients && IsValidEntity(flare))
		GetEntPropVector(flare, Prop_Send, "m_vecOrigin", flarePos);
	else
		flarePos = g_IonOrigin[client];

	float endUp[3];
	endUp = flarePos;
	endUp[2] += 8192.0;

	// ⭐ RayType_EndPoint aquí
	Handle tr = TR_TraceRayFilterEx(flarePos, endUp, MASK_VISIBLE, RayType_EndPoint, TraceFilter_NoPlayers, 0);

	float  sky[3];
	if (TR_DidHit(tr))
	{
		TR_GetEndPosition(sky, tr);
		sky[2] += 8.0;
	}
	else {
		sky = endUp;
	}
	CloseHandle(tr);
	SmashIonFlare(client);
	EmitSoundToAll(g_sSoundIon, flare);

	int sBeam = PrecacheModel(g_sSpriteBeam, true);
	int sHalo = PrecacheModel(g_sSpriteHalo, true);

	TE_SetupBeamPoints(sky, flarePos, sBeam, sHalo, 0, 10, 6.0, 400.0, 450.0, 10, 4.0, { 160, 145, 255, 200 }, 0);
	TE_SendToAll();

	int	  rings = g_cvBlastRings.IntValue;
	float gap	= g_cvBlastGap.FloatValue * g_cvVisualScale.FloatValue;
	for (int k = 0; k < rings; k++)
		CreateTimer(k * gap, Timer_BlastExtraRing, userid, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Stop;
}

public Action Timer_BlastExtraRing(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Stop;
	if (!WindowTick(client)) return Plugin_Stop;

	float flarePos[3];
	int	  flare = g_IonEnts[client][1];
	if (flare > MaxClients && IsValidEntity(flare))
		GetEntPropVector(flare, Prop_Send, "m_vecOrigin", flarePos);
	else
		flarePos = g_IonOrigin[client];

	float p[3];
	p = flarePos;
	p[2] += 20.0;

	int sBeam = PrecacheModel(g_sSpriteBeam, true);
	int sHalo = PrecacheModel(g_sSpriteHalo, true);

	TE_SetupBeamRingPoint(p, 0.0, 1800.0, sBeam, sHalo, 0, 30, 6.0, 70.0, 5.0, { 160, 145, 255, 180 }, 0, 0);
	TE_SendToAll();

	IonLog("Timer_BlastExtraRing client=%d", client);
	return Plugin_Stop;
}

// center beam loop (relampagueo) anclado al flare
public Action Timer_IonCenterBeamLoop(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Stop;
	if (!WindowTick(client)) return Plugin_Stop;

	float flarePos[3];
	int	  flare = g_IonEnts[client][1];
	if (flare > MaxClients && IsValidEntity(flare))
		GetEntPropVector(flare, Prop_Send, "m_vecOrigin", flarePos);
	else
		flarePos = g_IonOrigin[client];

	float endUp[3];
	endUp = flarePos;
	endUp[2] += 8192.0;

	// ⭐ RayType_EndPoint aquí también
	Handle tr = TR_TraceRayFilterEx(flarePos, endUp, MASK_VISIBLE, RayType_EndPoint, TraceFilter_NoPlayers, 0);

	float  sky[3];
	if (TR_DidHit(tr))
	{
		TR_GetEndPosition(sky, tr);
		sky[2] += 8.0;
	}
	else {
		sky = endUp;
	}
	CloseHandle(tr);

	int sBeam = PrecacheModel(g_sSpriteBeam, true);
	int sHalo = PrecacheModel(g_sSpriteHalo, true);

	TE_SetupBeamPoints(sky, flarePos, sBeam, sHalo, 0, 10, 3.0, 350.0, 420.0, 10, 4.0, { 160, 145, 255, 160 }, 50);
	TE_SendToAll();

	return Plugin_Continue;
}

// órbita (6 haces girando sobre el punto)
public Action Timer_LaserRotate(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Stop;
	if (!WindowTick(client)) return Plugin_Stop;

	float dist = 250.0;
	for (int i = 0; i < 6; i++)
	{
		g_BeamDeg[client][i] += 1.5;	// más lento
		if (g_BeamDeg[client][i] > 360.0) g_BeamDeg[client][i] -= 360.0;

		g_BeamOrigin[client][i][0] = g_IonOrigin[client][0] + Sine(DegToRad(g_BeamDeg[client][i])) * dist;
		g_BeamOrigin[client][i][1] = g_IonOrigin[client][1] + Cosine(DegToRad(g_BeamDeg[client][i])) * dist;
		g_BeamOrigin[client][i][2] = g_IonOrigin[client][2];
	}

	int sBeam = PrecacheModel(g_sSpriteBeam, true);
	int sHalo = PrecacheModel(g_sSpriteHalo, true);
	for (int i = 0; i < 6; i++)
	{
		float start[3];
		start[0] = g_BeamOrigin[client][i][0];
		start[1] = g_BeamOrigin[client][i][1];
		start[2] = g_IonOrigin[client][2] + GetRandomFloat(300.0, 1200.0);

		TE_SetupBeamPoints(start, g_BeamOrigin[client][i], sBeam, sHalo, 0, 0, 1.2, 25.0, 25.0, 0, 0.0, { 160, 145, 255, 120 }, 10);
		TE_SendToAll();
	}
	IonLog("Timer_LaserRotate client=%d", client);
	return Plugin_Continue;
}

// Daño por pulso y screenshake
public Action Timer_IonPulse(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Stop;
	if (!WindowTick(client)) return Plugin_Stop;

	int dmgCommon = g_cvDamageCommon.IntValue;
	int dmgSI	  = g_cvDamageSI.IntValue;

	int ent		  = -1;
	while ((ent = FindEntityByClassname(ent, "infected")) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(ent))
		{
			SDKHooks_TakeDamage(ent, 0, client, float(dmgCommon), DMG_ENERGYBEAM);
		}
	}
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "witch")) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(ent))
		{
			SDKHooks_TakeDamage(ent, 0, client, float(dmgCommon), DMG_ENERGYBEAM);
		}
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		if (GetClientTeam(i) != 3) continue;
		if (GetEntProp(i, Prop_Send, "m_isGhost") != 0) continue;

		SDKHooks_TakeDamage(i, 0, client, float(dmgSI), DMG_ENERGYBEAM);
	}

	float r1 = g_cvShakeNear.FloatValue, r2 = g_cvShakeMid.FloatValue, r3 = g_cvShakeFar.FloatValue;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		int team = GetClientTeam(i);
		if (team != 2 && team != 3) continue;

		float pos[3];
		GetClientAbsOrigin(i, pos);
		float d = GetVectorDistance(g_IonOrigin[client], pos);
		if (d <= r1) ScreenShakeSimple(i, 5.0);
		else if (d <= r2) ScreenShakeSimple(i, 3.0);
		else if (d <= r3) ScreenShakeSimple(i, 1.0);
	}

	IonLog("Timer_IonPulse client=%d", client);
	return Plugin_Continue;
}

// ===================== Helpers =====================

bool WindowTick(int client)
{
	if (GetGameTime() >= g_EndTime[client])
	{
		IonLog("Window ended for client=%d", client);
		DestroyIonFlare(client);
		return false;
	}
	return true;
}

void SmashIonFlare(int client)
{
	int ent = g_IonEnts[client][1];
	if (ent > MaxClients && IsValidEntity(ent))
	{
		StopSound(ent, SNDCHAN_AUTO, g_sSoundCrackle);	  // parar crackle
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
		SetEntityRenderColor(ent, 100, 100, 100, 0);
		IonLog("SmashIonFlare: stopped crackle and faded prop=%d", ent);
	}
	// apagar partículas/luz/steam con delay
	for (int i = 2; i <= 5; i++)
	{
		ent = g_IonEnts[client][i];
		if (ent > MaxClients && IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "TurnOff");
			SetVariantString("OnUser1 !self:Kill::1.0:-1");
			AcceptEntityInput(ent, "AddOutput");
			AcceptEntityInput(ent, "FireUser1");
			g_IonEnts[client][i] = 0;
		}
	}
}

void DestroyIonFlare(int client)
{
	int ent = g_IonEnts[client][1];
	if (ent > MaxClients && IsValidEntity(ent))
	{
		StopSound(ent, SNDCHAN_AUTO, g_sSoundIon);		  // parar rugido
		StopSound(ent, SNDCHAN_AUTO, g_sSoundCrackle);	  // por si acaso
		AcceptEntityInput(ent, "Kill");
		g_IonEnts[client][1] = 0;
		IonLog("DestroyIonFlare: killed prop for client=%d", client);
	}

	// Fallback: asegurar que nadie quedó sonando
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			StopSound(i, SNDCHAN_AUTO, g_sSoundIon);
		}
	}

	g_IonOrigin[client][0] = 0.0;
	g_IonOrigin[client][1] = 0.0;
	g_IonOrigin[client][2] = 0.0;
}

int DisplayParticle(const char[] effectName, const float origin[3], const float angles[3])
{
	int p = CreateEntityByName("info_particle_system");
	if (p > MaxClients && IsValidEntity(p))
	{
		DispatchKeyValue(p, "effect_name", effectName);
		DispatchKeyValueVector(p, "origin", origin);
		DispatchKeyValueVector(p, "angles", angles);
		DispatchSpawn(p);
		ActivateEntity(p);
		AcceptEntityInput(p, "start");
		return p;
	}
	return -1;
}

void SetupOrbitBeams(int client)
{
	float base[3];
	base			 = g_IonOrigin[client];
	float offs[6][2] = {
		{200.0,	 150.0 },
		{ 200.0,	 -150.0},
		{ -200.0, -150.0},
		{ -200.0, 150.0 },
		{ 150.0,	 200.0 },
		{ 150.0,	 -200.0}
	};
	float degs[6] = { 0.0, 45.0, 90.0, 135.0, 180.0, 225.0 };

	for (int i = 0; i < 6; i++)
	{
		g_BeamOrigin[client][i][0] = base[0] + offs[i][0];
		g_BeamOrigin[client][i][1] = base[1] + offs[i][1];
		g_BeamOrigin[client][i][2] = base[2];
		g_BeamDeg[client][i]	   = degs[i];
	}
}

void ScreenShakeSimple(int client, float amp)
{
	TE_Start("Shake");
	TE_WriteFloat("amplitude", amp);
	TE_WriteFloat("frequency", 1.0);
	TE_WriteFloat("duration", 1.0);
	TE_WriteVector("center", g_IonOrigin[client]);
	TE_SendToClient(client);
}

bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}

bool IonHasAccess(int client)
{
	char flag[4];
	g_cvAccessFlag.GetString(flag, sizeof(flag));
	if (flag[0] == '\0') return true;

	int needed = ReadFlagString(flag);
	return (GetUserFlagBits(client) & needed) != 0;
}

// Filtro de rayos: ignora jugadores
public bool TraceFilter_NoPlayers(int entity, int contentsMask, any data)
{
	return (entity <= 0 || entity > MaxClients);
}

// Limpieza global al terminar ronda
public void Event_Cleanup(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		DestroyIonFlare(i);
	}
	IonLog("Event_Cleanup ejecutado.");
}
