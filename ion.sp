// ===== Ion Cannon (Optimized v1.2.0) =====
// Fixed: Multiple execution issues, precache optimization, sound cleanup
// Game: L4D2

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_trace>
#include <sdktools_tempents>

public Plugin myinfo =
{
	name		= "Ion Cannon (Optimized)",
	author		= "Socius (port) + optimizer",
	description = "Ion cannon con ejecuciÃ³n optimizada sin duplicados",
	version		= "1.2.0",
	url			= ""
};

// ===================== State Management =====================
bool g_IonActive[MAXPLAYERS + 1];
int	 g_IonToken[MAXPLAYERS + 1];

// ===================== Cached Sprites (OPTIMIZADO) =====================
int g_iCachedBeamSprite = -1;
int g_iCachedHaloSprite = -1;

// ===================== Logging & Debug =====================
#define ION_LOGFILE "addons/sourcemod/logs/ion_cannon.log"
void IonLog(const char[] fmt, any...)
{
	static char buffer[512];
	VFormat(buffer, sizeof(buffer), fmt, 2);
	LogToFileEx(ION_LOGFILE, "[%8.3f] %s", GetGameTime(), buffer);
}

// NUEVO: Debug en chat para todas las secuencias
void IonDebug(const char[] fmt, any...)
{
	static char buffer[256];
	VFormat(buffer, sizeof(buffer), fmt, 2);

	// Log a archivo
	IonLog("[DEBUG] %s", buffer);

	// Enviar a todos los jugadores en chat
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			PrintToChat(i, "\x04[Ion Debug]\x01 %s", buffer);
		}
	}
}

// ===================== ConVars =====================
ConVar g_cvModelFlare, g_cvSoundCrackle, g_cvSoundIon;
ConVar g_cvParticleFlare, g_cvParticleFuse;
ConVar g_cvSpriteBeam, g_cvSpriteHalo;
ConVar g_cvDelay, g_cvWindow, g_cvPulseEvery;
ConVar g_cvDamageCommon, g_cvDamageSI;
ConVar g_cvShakeNear, g_cvShakeMid, g_cvShakeFar;
ConVar g_cvTickRotate, g_cvTickRing, g_cvTickCenter;
ConVar g_cvBlastRings, g_cvBlastGap, g_cvVisualScale;
ConVar g_cvAccessFlag;

// String buffers
char g_sModelFlare[PLATFORM_MAX_PATH];
char g_sSoundCrackle[PLATFORM_MAX_PATH];
char g_sSoundIon[PLATFORM_MAX_PATH];
char g_sParticleFlare[128];
char g_sParticleFuse[128];
char g_sSpriteBeam[PLATFORM_MAX_PATH];
char g_sSpriteHalo[PLATFORM_MAX_PATH];

// ===================== Per-Client State =====================
static float g_IonOrigin[MAXPLAYERS + 1][3];
static float g_BeamOrigin[MAXPLAYERS + 1][6][3];
static float g_BeamDeg[MAXPLAYERS + 1][6];
static int	 g_IonEnts[MAXPLAYERS + 1][6];
static float g_EndTime[MAXPLAYERS + 1];

// ===================== Plugin Lifecycle =====================
public void OnPluginStart()
{
	RegAdminCmd("sm_ion", Cmd_Ion, ADMFLAG_GENERIC);
	RegConsoleCmd("say", Cmd_Say);
	RegConsoleCmd("say_team", Cmd_Say);

	// ConVars
	g_cvModelFlare	  = CreateConVar("ic_model_flare", "models/props_unique/hospital/iv_pole.mdl");
	g_cvSoundCrackle  = CreateConVar("ic_sound_crackle", "ambient/energy/zap9.wav");
	g_cvSoundIon	  = CreateConVar("ic_sound_ion", "vehicles/airboat/fan_blade_fullthrottle_loop1.wav");
	g_cvParticleFlare = CreateConVar("ic_particle_flare", "weapon_pipebomb");
	g_cvParticleFuse  = CreateConVar("ic_particle_fuse", "weapon_pipebomb");
	g_cvSpriteBeam	  = CreateConVar("ic_sprite_beam", "materials/sprites/laserbeam.vmt");
	g_cvSpriteHalo	  = CreateConVar("ic_sprite_halo", "materials/sprites/halo01.vmt");

	// OPTIMIZADO: Secuencia rápida de 10s delay + 3 anillos grandes cada 5s
	g_cvDelay		  = CreateConVar("ic_delay", "10.0");          // 10 segundos hasta primera explosión
	g_cvWindow		  = CreateConVar("ic_window", "17.0");         // 17 segundos totales (permite 3 anillos: 5s, 10s, 15s desde inicio)
	g_cvPulseEvery	  = CreateConVar("ic_pulse_every", "3.0");     // Pulso de daño cada 3s
	g_cvDamageCommon  = CreateConVar("ic_dmg_common", "10");
	g_cvDamageSI	  = CreateConVar("ic_dmg_si", "10");
	g_cvShakeNear	  = CreateConVar("ic_shake_r1", "900");
	g_cvShakeMid	  = CreateConVar("ic_shake_r2", "1800");
	g_cvShakeFar	  = CreateConVar("ic_shake_r3", "2600");

	g_cvTickRotate	  = CreateConVar("ic_tick_rotate", "0.5");     // Rayos orbitales cada 0.5s (más rápido)
	g_cvTickRing	  = CreateConVar("ic_tick_ring", "5.0");       // Anillos grandes cada 5s (3 en 15s)
	g_cvTickCenter	  = CreateConVar("ic_tick_center", "1.5");     // Rayo central cada 1.5s
	g_cvBlastRings	  = CreateConVar("ic_blast_rings", "3");       // 3 anillos grandes
	g_cvBlastGap	  = CreateConVar("ic_blast_gap", "0.3");       // 0.3s entre anillos iniciales
	g_cvVisualScale	  = CreateConVar("ic_visual_scale", "1.0");    // Sin multiplicador (tiempo real)

	g_cvAccessFlag	  = CreateConVar("ic_access_flag", "");

	AutoExecConfig(true, "ion_cannon_optimized");

	HookEvent("round_end", Event_Cleanup, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", Event_Cleanup, EventHookMode_PostNoCopy);

	IonLog("Plugin loaded (optimized version)");
}

// OPTIMIZADO: Solo se ejecuta UNA VEZ por mapa
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

// OPTIMIZADO: Solo OnMapStart (no en OnConfigsExecuted)
public void OnMapStart()
{
	RefreshAssetStrings();

	// Precache UNA VEZ
	PrecacheModel(g_sModelFlare, true);
	PrecacheSound(g_sSoundCrackle, true);
	PrecacheSound(g_sSoundIon, true);

	// NUEVO: Sonidos de explosión variados de L4D2
	PrecacheSound("weapons/grenade_launcher/grenade_launcher_explode.wav", true);
	PrecacheSound("weapons/hegrenade/explode3.wav", true);
	PrecacheSound("weapons/hegrenade/explode4.wav", true);
	PrecacheSound("weapons/hegrenade/explode5.wav", true);
	PrecacheSound("ambient/explosions/explode_1.wav", true);
	PrecacheSound("ambient/explosions/explode_2.wav", true);
	PrecacheSound("ambient/explosions/explode_3.wav", true);

	// NUEVO: Sonidos de láser/energía para los beams
	PrecacheSound("ambient/energy/zap5.wav", true);
	PrecacheSound("ambient/energy/zap7.wav", true);
	PrecacheSound("ambient/energy/zap8.wav", true);
	PrecacheSound("ambient/energy/weld1.wav", true);
	PrecacheSound("ambient/energy/spark1.wav", true);

	// NUEVO: Precache de partículas L4D2 nativas (SOLO las que realmente EXISTEN)
	// NOTA: Solo weapon_pipebomb es 100% confiable en L4D2
	PrecacheParticle("weapon_pipebomb");
	
	// CACHE sprites para uso posterior
	g_iCachedBeamSprite = PrecacheModel(g_sSpriteBeam, true);
	g_iCachedHaloSprite = PrecacheModel(g_sSpriteHalo, true);

	IonLog("OnMapStart: assets precached (beam=%d, halo=%d)", g_iCachedBeamSprite, g_iCachedHaloSprite);
}

public void OnMapEnd()
{
	// Reset cache
	g_iCachedBeamSprite = -1;
	g_iCachedHaloSprite = -1;
}

// ===================== Commands =====================
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

// ===================== Core Flow =====================
void StartIonCannon(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return;

	if (g_IonActive[client] && GetGameTime() < g_EndTime[client])
	{
		PrintToChat(client, "[Ion] Ya hay un Ion Cannon activo.");
		return;
	}

	// Limpiar COMPLETAMENTE antes de iniciar nuevo
	CleanupClientIon(client);

	g_IonActive[client] = true;
	g_IonToken[client]++;
	int token = g_IonToken[client];

	float slow = g_cvVisualScale.FloatValue;
	g_EndTime[client] = GetGameTime() + (g_cvWindow.FloatValue * slow);

	CreateIonFlare(client);

	float delay = g_cvDelay.FloatValue * slow;
	CreateTimer(delay, Timer_StartIonCannon, PackCell(client, token), TIMER_FLAG_NO_MAPCHANGE);

	IonLog("StartIonCannon: client=%d token=%d", client, token);
	IonDebug("FASE 1: Ion Cannon iniciado - Delay: %.1fs", delay);
}

public Action Timer_StartIonCannon(Handle timer, any data)
{
	int client, token;
	UnpackCell(data, client, token);
	if (AbortIfStale(client, token)) return Plugin_Stop;

	float slow = g_cvVisualScale.FloatValue;
	SetupOrbitBeams(client);

	IonDebug("FASE 2: Timers iniciados - Beams activos");

	// Secuencia rápida: impacto a los 0.5s, beams inmediatos
	CreateTimer(0.5 * slow, Timer_CreateIonRing, data, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0 * slow, Timer_CreateIonBlast, data, TIMER_FLAG_NO_MAPCHANGE);

	// Timers repetitivos comienzan inmediatamente
	CreateTimer(g_cvTickRotate.FloatValue * slow, Timer_LaserRotate, data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_cvTickRing.FloatValue * slow, Timer_IonRingTick, data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_cvTickCenter.FloatValue * slow, Timer_IonCenterBeamLoop, data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_cvPulseEvery.FloatValue * slow, Timer_IonPulse, data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	IonLog("Timers armed: client=%d token=%d", client, token);
	IonDebug("Tick Orbital: %.1fs | Anillo: %.1fs | Central: %.1fs",
		g_cvTickRotate.FloatValue, g_cvTickRing.FloatValue, g_cvTickCenter.FloatValue);
	return Plugin_Stop;
}

// ===================== Flare Creation =====================
void CreateIonFlare(int client)
{
	float org[3], ang[3];
	GetClientAbsOrigin(client, org);
	GetClientAbsAngles(client, ang);

	// Prop
	int prop = CreateEntityByName("prop_dynamic");
	if (prop > MaxClients && IsValidEntity(prop))
	{
		SetEntityModel(prop, g_sModelFlare);
		DispatchSpawn(prop);
		TeleportEntity(prop, org, ang, NULL_VECTOR);
		g_IonEnts[client][1] = prop;
		GetEntPropVector(prop, Prop_Send, "m_vecOrigin", g_IonOrigin[client]);

		// OPTIMIZADO: Solo emitir sonido UNA VEZ aquÃ­
		EmitSoundToAll(g_sSoundCrackle, prop, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8);
		IonLog("Flare created: prop=%d", prop);
	}

	// Spotlight
	int spot = CreateEntityByName("point_spotlight");
	if (spot > MaxClients && IsValidEntity(spot))
	{
		DispatchKeyValue(spot, "rendercolor", "200 20 15");
		DispatchKeyValue(spot, "spotlightwidth", "1");
		DispatchKeyValue(spot, "spotlightlength", "3");
		DispatchKeyValue(spot, "renderamt", "255");
		DispatchSpawn(spot);
		AcceptEntityInput(spot, "TurnOn");
		DispatchKeyValue(spot, "angles", "90 0 0");
		TeleportEntity(spot, org, NULL_VECTOR, NULL_VECTOR);
		g_IonEnts[client][2] = spot;
	}

	// Particles
	float ang1[3];
	ang1[0] = -80.0;
	ang1[1] = GetRandomFloat(1.0, 360.0);
	int p1 = DisplayParticle(g_sParticleFlare, org, ang1);
	if (p1 > MaxClients) g_IonEnts[client][3] = p1;

	float ang2[3];
	ang2[0] = -80.0;
	ang2[1] = GetRandomFloat(1.0, 360.0);
	int p2 = DisplayParticle(g_sParticleFuse, org, ang2);
	if (p2 > MaxClients) g_IonEnts[client][4] = p2;

	// Steam
	int steam = CreateEntityByName("env_steam");
	if (steam > MaxClients && IsValidEntity(steam))
	{
		DispatchKeyValue(steam, "SpawnFlags", "1");
		DispatchKeyValue(steam, "rendercolor", "200 20 15");
		DispatchKeyValue(steam, "Speed", "15");
		DispatchKeyValue(steam, "Rate", "10");
		DispatchKeyValue(steam, "renderamt", "60");
		DispatchSpawn(steam);
		AcceptEntityInput(steam, "TurnOn");
		TeleportEntity(steam, org, ang, NULL_VECTOR);
		g_IonEnts[client][5] = steam;
	}
}

// ===================== Visual Effects =====================
public Action Timer_CreateIonRing(Handle timer, any data)
{
	int client, token;
	UnpackCell(data, client, token);
	if (AbortIfStale(client, token)) return Plugin_Stop;

	IonDebug("Anillo visual inicial (0.5s)");
	return Plugin_Stop;
}

// Variable global para contar anillos
static int g_RingCount[MAXPLAYERS + 1] = {0, ...};

public Action Timer_IonRingTick(Handle timer, any data)
{
	int client, token;
	UnpackCell(data, client, token);
	if (AbortIfStale(client, token) || !WindowTick(client)) return Plugin_Stop;

	g_RingCount[client]++;

	float p[3];
	p[0] = g_IonOrigin[client][0];
	p[1] = g_IonOrigin[client][1];
	p[2] = g_IonOrigin[client][2] + 20.0;

	IonDebug("ANILLO GRANDE #%d (Tick: %.1fs, Expansión: 30%% más lenta)",
		g_RingCount[client], GetGameTime());

	// OPTIMIZADO: Usar cache en lugar de PrecacheModel cada vez
	// Radio unificado: 350.0 → 1800.0 (igual que todos los demás beams)
	// Duración 5.2s (30% más lenta que antes: 4.0 × 1.3)
	TE_SetupBeamRingPoint(p, 350.0, 1800.0, g_iCachedBeamSprite, g_iCachedHaloSprite,
		0, 30, 5.2, 80.0, 5.0, {160, 145, 255, 155}, 0, 0);
	TE_SendToAll();

	// NUEVO: Explosión visual + sonido mejorado
	CreateExplosion(p, false);  // Explosión pequeña
	PlayExplosionSound(p, false);

	// NUEVO: Quemar infectados en el área del anillo
	IgniteInfectedInRadius(p, 500.0, 4.0);

	// NUEVO: Terminar automáticamente después del 3er anillo
	if (g_RingCount[client] >= 3)
	{
		IonDebug("3 anillos completados - Finalizando Ion Cannon");
		CreateTimer(0.5, Timer_ForceCleanup, PackCell(client, token), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
			ScreenShakeSimple(i, 8.0);  // AUMENTADO: de 2.0 a 8.0
	}

	return Plugin_Continue;
}

public Action Timer_CreateIonBlast(Handle timer, any data)
{
	int client, token;
	UnpackCell(data, client, token);
	if (AbortIfStale(client, token)) return Plugin_Stop;

	float flarePos[3];
	int flare = g_IonEnts[client][1];
	if (flare > MaxClients && IsValidEntity(flare))
		GetEntPropVector(flare, Prop_Send, "m_vecOrigin", flarePos);
	else
		flarePos = g_IonOrigin[client];

	float endUp[3];
	endUp = flarePos;
	endUp[2] += 8192.0;
	
	TR_TraceRayFilter(flarePos, endUp, MASK_VISIBLE, RayType_EndPoint, TraceFilter_NoPlayers, 0);
	float sky[3];
	if (TR_DidHit()) {
		TR_GetEndPosition(sky);
		sky[2] += 8.0;
	} else {
		sky = endUp;
	}

	SmashIonFlare(client);

	IonDebug("IMPACTO PRINCIPAL (1.0s) - Explosión GRANDE + Ceguera");

	// OPTIMIZADO: Emitir sonido principal UNA VEZ
	if (flare > MaxClients && IsValidEntity(flare))
	{
		EmitSoundToAll(g_sSoundIon, flare, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8);
	}

	// NUEVO: Explosión GIGANTE al impacto principal
	CreateExplosion(flarePos, true);  // bigExplosion = true
	PlayExplosionSound(flarePos, true);

	// NUEVO: Quemar masivamente infectados en el impacto principal
	IgniteInfectedInRadius(flarePos, 1000.0, 10.0);  // Radio grande, duración larga

	// NUEVO: Efecto de ceguera SOLO en la primera explosión principal (aumenta percepción)
	FlashSurvivors(2.5, 220);  // 2.5 segundos de ceguera, alpha 220 (semi-intensa)
	IonDebug("Ceguera aplicada a sobrevivientes (2.5s)");

	// OPTIMIZADO: Usar cache
	TE_SetupBeamPoints(sky, flarePos, g_iCachedBeamSprite, g_iCachedHaloSprite,
		0, 10, 6.0, 400.0, 450.0, 10, 4.0, {160,145,255,200}, 0);
	TE_SendToAll();

	int rings = g_cvBlastRings.IntValue;
	float gap = g_cvBlastGap.FloatValue * g_cvVisualScale.FloatValue;
	for (int k = 0; k < rings; k++)
		CreateTimer(k * gap, Timer_BlastExtraRing, data, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Stop;
}

public Action Timer_BlastExtraRing(Handle timer, any data)
{
	int client, token;
	UnpackCell(data, client, token);
	if (AbortIfStale(client, token) || !WindowTick(client)) return Plugin_Stop;

	float flarePos[3];
	int flare = g_IonEnts[client][1];
	if (flare > MaxClients && IsValidEntity(flare))
		GetEntPropVector(flare, Prop_Send, "m_vecOrigin", flarePos);
	else
		flarePos = g_IonOrigin[client];

	float p[3];
	p = flarePos;
	p[2] += 20.0;

	// Radio unificado: 350.0 → 1800.0 (igual que todos los demás beams)
	// Duración 7.8s (30% más lenta que antes: 6.0 × 1.3)
	TE_SetupBeamRingPoint(p, 350.0, 1800.0, g_iCachedBeamSprite, g_iCachedHaloSprite,
		0, 30, 7.8, 70.0, 5.0, {160, 145, 255, 180}, 0, 0);
	TE_SendToAll();

	// NUEVO: Explosión en cada anillo extra
	CreateExplosion(p, false);
	PlayExplosionSound(p, false);

	// NUEVO: Quemar infectados en cada anillo extra
	IgniteInfectedInRadius(p, 600.0, 4.0);

	return Plugin_Stop;
}

public Action Timer_IonCenterBeamLoop(Handle timer, any data)
{
	int client, token;
	UnpackCell(data, client, token);
	if (AbortIfStale(client, token) || !WindowTick(client)) return Plugin_Stop;

	float flarePos[3];
	int flare = g_IonEnts[client][1];
	if (flare > MaxClients && IsValidEntity(flare))
		GetEntPropVector(flare, Prop_Send, "m_vecOrigin", flarePos);
	else
		flarePos = g_IonOrigin[client];

	float endUp[3];
	endUp = flarePos;
	endUp[2] += 8192.0;

	TR_TraceRayFilter(flarePos, endUp, MASK_VISIBLE, RayType_EndPoint, TraceFilter_NoPlayers, 0);
	float sky[3];
	if (TR_DidHit()) {
		TR_GetEndPosition(sky);
		sky[2] += 8.0;
	} else {
		sky = endUp;
	}

	TE_SetupBeamPoints(sky, flarePos, g_iCachedBeamSprite, g_iCachedHaloSprite,
		0, 10, 3.0, 350.0, 420.0, 10, 4.0, {160, 145, 255, 160}, 50);
	TE_SendToAll();

	// NUEVO: Sonido de láser central (beam grande del cielo al suelo)
	if (GetRandomInt(0, 100) < 30)  // 30% probabilidad de sonido
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				EmitSoundToClient(i, "ambient/energy/weld1.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO,
					SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8, SNDPITCH_NORMAL, -1, flarePos, NULL_VECTOR, true, 0.0);
			}
		}
	}

	// NUEVO: Explosión ocasional en el punto de impacto del beam central
	if (GetRandomInt(0, 100) < 20)  // 20% probabilidad
	{
		CreateExplosion(flarePos, false);
		PlayExplosionSound(flarePos, false);

		// NUEVO: Quemar infectados en el punto de impacto del beam
		IgniteInfectedInRadius(flarePos, 200.0, 3.0);
	}

	return Plugin_Continue;
}

public Action Timer_LaserRotate(Handle timer, any data)
{
	int client, token;
	UnpackCell(data, client, token);
	if (AbortIfStale(client, token) || !WindowTick(client)) return Plugin_Stop;

	float dist = 250.0;
	for (int i = 0; i < 6; i++)
	{
		g_BeamDeg[client][i] += 1.5;
		if (g_BeamDeg[client][i] > 360.0) g_BeamDeg[client][i] -= 360.0;

		g_BeamOrigin[client][i][0] = g_IonOrigin[client][0] + Sine(DegToRad(g_BeamDeg[client][i])) * dist;
		g_BeamOrigin[client][i][1] = g_IonOrigin[client][1] + Cosine(DegToRad(g_BeamDeg[client][i])) * dist;
		g_BeamOrigin[client][i][2] = g_IonOrigin[client][2];
	}

	// NUEVO: Sonido de láser orbital (beams pequeños rotatorios) - solo ocasionalmente
	if (GetRandomInt(0, 100) < 25)  // 25% probabilidad cada tick
	{
		// Seleccionar un sonido de láser aleatorio
		char laserSounds[3][PLATFORM_MAX_PATH] = {
			"ambient/energy/zap5.wav",
			"ambient/energy/zap7.wav",
			"ambient/energy/spark1.wav"
		};
		int randomIdx = GetRandomInt(0, 2);
		int randomPitch = GetRandomInt(95, 105);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				EmitSoundToClient(i, laserSounds[randomIdx], SOUND_FROM_WORLD, SNDCHAN_AUTO,
					SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6, randomPitch, -1, g_IonOrigin[client], NULL_VECTOR, true, 0.0);
			}
		}
	}

	for (int i = 0; i < 6; i++)
	{
		float start[3];
		start[0] = g_BeamOrigin[client][i][0];
		start[1] = g_BeamOrigin[client][i][1];
		start[2] = g_IonOrigin[client][2] + GetRandomFloat(300.0, 1200.0);

		TE_SetupBeamPoints(start, g_BeamOrigin[client][i], g_iCachedBeamSprite, g_iCachedHaloSprite,
			0, 0, 1.2, 25.0, 25.0, 0, 0.0, {160, 145, 255, 120}, 10);
		TE_SendToAll();

		// NUEVO: Mini-explosión en cada punto de contacto del beam (aleatorio para no saturar)
		if (GetRandomInt(0, 100) < 15)  // 15% de probabilidad cada tick
		{
			CreateExplosion(g_BeamOrigin[client][i], false);
			PlayExplosionSound(g_BeamOrigin[client][i], false);

			// NUEVO: Quemar infectados en el punto de impacto del beam
			IgniteInfectedInRadius(g_BeamOrigin[client][i], 150.0, 3.0);
		}
	}

	return Plugin_Continue;
}

public Action Timer_IonPulse(Handle timer, any data)
{
	int client, token;
	UnpackCell(data, client, token);
	if (AbortIfStale(client, token) || !WindowTick(client)) return Plugin_Stop;

	int dmgCommon = g_cvDamageCommon.IntValue;
	int dmgSI = g_cvDamageSI.IntValue;

	// NUEVO: Quemar infectados en el área del Ion Cannon
	IgniteInfectedInRadius(g_IonOrigin[client], 800.0, 5.0);

	// Damage infected comunes (SOLO infectados, sin sobrevivientes)
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "infected")) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(ent))
		{
			// DMG_BURN = daño por fuego
			SDKHooks_TakeDamage(ent, 0, client, float(dmgCommon), DMG_BURN);
		}
	}

	// Damage witches
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "witch")) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(ent))
		{
			SDKHooks_TakeDamage(ent, 0, client, float(dmgCommon), DMG_BURN);
		}
	}

	// Damage SI (SOLO team 3 - infectados, NO sobrevivientes)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;

		// CRÍTICO: Solo team 3 (infectados), NUNCA team 2 (sobrevivientes)
		if (GetClientTeam(i) != 3) continue;
		if (GetEntProp(i, Prop_Send, "m_isGhost") != 0) continue;

		SDKHooks_TakeDamage(i, 0, client, float(dmgSI), DMG_BURN);
	}

	// Screen shake
	float r1 = g_cvShakeNear.FloatValue;
	float r2 = g_cvShakeMid.FloatValue;
	float r3 = g_cvShakeFar.FloatValue;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		int team = GetClientTeam(i);
		if (team != 2 && team != 3) continue;

		float pos[3];
		GetClientAbsOrigin(i, pos);
		float d = GetVectorDistance(g_IonOrigin[client], pos);
		
		// AUMENTADO: Shakes más fuertes
		if (d <= r1) ScreenShakeSimple(i, 15.0);  // Era 5.0
		else if (d <= r2) ScreenShakeSimple(i, 10.0);  // Era 3.0
		else if (d <= r3) ScreenShakeSimple(i, 5.0);  // Era 1.0
	}

	return Plugin_Continue;
}

// ===================== Cleanup =====================
bool WindowTick(int client)
{
	if (GetGameTime() >= g_EndTime[client])
	{
		CleanupClientIon(client);
		return false;
	}
	return true;
}

// NUEVO: Timer para forzar limpieza después del 3er anillo
public Action Timer_ForceCleanup(Handle timer, any data)
{
	int client, token;
	UnpackCell(data, client, token);

	// Verificar que el token siga siendo válido
	if (IsValidClient(client) && g_IonToken[client] == token)
	{
		CleanupClientIon(client);
	}

	return Plugin_Stop;
}

void SmashIonFlare(int client)
{
	int ent = g_IonEnts[client][1];
	if (ent > MaxClients && IsValidEntity(ent))
	{
		StopSound(ent, SNDCHAN_AUTO, g_sSoundCrackle);
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
		SetEntityRenderColor(ent, 100, 100, 100, 0);
	}

	// Apagar particles/luz/steam
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

// OPTIMIZADO: Limpieza completa y centralizada
void CleanupClientIon(int client)
{
	IonDebug("FASE FINAL: Limpieza del Ion Cannon (Total anillos: %d)", g_RingCount[client]);

	// Stop ALL sounds
	int flare = g_IonEnts[client][1];
	if (flare > MaxClients && IsValidEntity(flare))
	{
		StopSound(flare, SNDCHAN_AUTO, g_sSoundCrackle);
		StopSound(flare, SNDCHAN_AUTO, g_sSoundIon);
		AcceptEntityInput(flare, "Kill");
	}

	// Kill all entities
	for (int i = 1; i <= 5; i++)
	{
		int ent = g_IonEnts[client][i];
		if (ent > MaxClients && IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "Kill");
		}
		g_IonEnts[client][i] = 0;
	}

	// Fallback: stop sounds for all players
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			StopSound(i, SNDCHAN_AUTO, g_sSoundIon);
			StopSound(i, SNDCHAN_AUTO, g_sSoundCrackle);
		}
	}

	// Reset state
	g_IonActive[client] = false;
	g_IonOrigin[client][0] = 0.0;
	g_IonOrigin[client][1] = 0.0;
	g_IonOrigin[client][2] = 0.0;
	g_RingCount[client] = 0;  // Reset contador de anillos

	IonLog("CleanupClientIon: client=%d fully cleaned", client);
}

// ===================== Helpers =====================
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
	base = g_IonOrigin[client];
	
	float offs[6][2] = {
		{200.0, 150.0},
		{200.0, -150.0},
		{-200.0, -150.0},
		{-200.0, 150.0},
		{150.0, 200.0},
		{150.0, -200.0}
	};
	
	float degs[6] = {0.0, 45.0, 90.0, 135.0, 180.0, 225.0};

	for (int i = 0; i < 6; i++)
	{
		g_BeamOrigin[client][i][0] = base[0] + offs[i][0];
		g_BeamOrigin[client][i][1] = base[1] + offs[i][1];
		g_BeamOrigin[client][i][2] = base[2];
		g_BeamDeg[client][i] = degs[i];
	}
}

void ScreenShakeSimple(int client, float amp)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return;

	float pos[3];
	GetClientAbsOrigin(client, pos);

	int shake = CreateEntityByName("env_shake");
	if (shake != -1 && IsValidEntity(shake))
	{
		char sAmp[16], sFreq[16], sDur[16];
		FloatToString(amp, sAmp, sizeof(sAmp));
		FloatToString(10.0, sFreq, sizeof(sFreq));  // AUMENTADO: de 1.0 a 10.0 Hz (más intenso)
		FloatToString(2.0, sDur, sizeof(sDur));  // AUMENTADO: de 1.0 a 2.0s (más duración)

		DispatchKeyValue(shake, "amplitude", sAmp);
		DispatchKeyValue(shake, "frequency", sFreq);
		DispatchKeyValue(shake, "duration", sDur);
		DispatchKeyValue(shake, "radius", "3000");
		DispatchKeyValue(shake, "spawnflags", "8");

		DispatchSpawn(shake);
		TeleportEntity(shake, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(shake, "StartShake");
		AcceptEntityInput(shake, "Kill");
	}
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

public bool TraceFilter_NoPlayers(int entity, int contentsMask, any data)
{
	return (entity <= 0 || entity > MaxClients);
}

public void Event_Cleanup(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		CleanupClientIon(i);
	}
	IonLog("Event_Cleanup: all ions destroyed");
}

// ===================== Packing Utilities =====================
stock int PackCell(int client, int token)
{
	return (token << 16) | (client & 0xFFFF);
}

stock void UnpackCell(any packed, int &client, int &token)
{
	client = (packed & 0xFFFF);
	token = (packed >> 16) & 0xFFFF;
}

stock bool AbortIfStale(int client, int token)
{
	return !IsValidClient(client) 
		|| !g_IonActive[client] 
		|| token != g_IonToken[client];
}

// ===================== Particle & Explosion Helpers =====================
public Action Timer_DeleteParticle(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
	return Plugin_Stop;
}

void PrecacheParticle(const char[] particleName)
{
	// Simple precache mediante tabla de strings
	int table = FindStringTable("ParticleEffectNames");
	if (table != INVALID_STRING_TABLE)
	{
		int index = FindStringIndex(table, particleName);
		if (index == INVALID_STRING_INDEX)
		{
			IonLog("WARNING: Particle '%s' not found in table", particleName);
		}
		else
		{
			IonLog("Precached particle: %s (index=%d)", particleName, index);
		}
	}
}

void CreateExplosion(const float pos[3], bool bigExplosion = false)
{
	// OPCIÓN 1: env_explosion (SOLO efectos visuales, SIN daño)
	int explosion = CreateEntityByName("env_explosion");
	if (explosion > MaxClients && IsValidEntity(explosion))
	{
		if (bigExplosion)
		{
			DispatchKeyValue(explosion, "iMagnitude", "500");  // Explosión grande
			DispatchKeyValue(explosion, "iRadiusOverride", "600");
		}
		else
		{
			DispatchKeyValue(explosion, "iMagnitude", "300");
			DispatchKeyValue(explosion, "iRadiusOverride", "400");
		}
		// spawnflags: 1=No Damage + 4=Repeatable + 8=No Fireball + 16=No Smoke + 2048=No Sound
		// Para SOLO efectos visuales sin daño: 1 (No Damage) solamente
		DispatchKeyValue(explosion, "spawnflags", "1");  // 1 = SIN DAÑO A NADIE
		DispatchSpawn(explosion);
		TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode");

		CreateTimer(0.1, Timer_DeleteParticle, EntIndexToEntRef(explosion), TIMER_FLAG_NO_MAPCHANGE);
	}

	// OPCIÓN 2: Partículas nativas de L4D2
	float angles[3];
	angles[0] = -90.0; // Apuntar hacia abajo
	angles[1] = GetRandomFloat(0.0, 360.0);
	angles[2] = 0.0;

	// Partículas: SOLO weapon_pipebomb (la única 100% confiable en L4D2)
	DisplayParticle("weapon_pipebomb", pos, angles);

	if (bigExplosion)
	{
		// Explosión grande: múltiples capas de pipebomb
		float posOffset[3];
		posOffset = pos;
		posOffset[2] += 50.0;
		DisplayParticle("weapon_pipebomb", posOffset, angles);

		posOffset = pos;
		posOffset[2] += 100.0;
		DisplayParticle("weapon_pipebomb", posOffset, angles);
	}

	// OPCIÓN 3: Sprite visual (flash naranja brillante)
	int sprite = CreateEntityByName("env_sprite");
	if (sprite > MaxClients && IsValidEntity(sprite))
	{
		DispatchKeyValue(sprite, "model", "sprites/muzzleflash4.vmt");
		DispatchKeyValue(sprite, "scale", bigExplosion ? "8.0" : "4.0");
		DispatchKeyValue(sprite, "rendermode", "5");
		DispatchKeyValue(sprite, "rendercolor", "255 150 50");
		DispatchKeyValue(sprite, "renderamt", "255");
		DispatchSpawn(sprite);
		TeleportEntity(sprite, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(sprite, "ShowSprite");

		CreateTimer(0.5, Timer_DeleteParticle, EntIndexToEntRef(sprite), TIMER_FLAG_NO_MAPCHANGE);
	}

	IonLog("CreateExplosion: big=%d at (%.1f,%.1f,%.1f)", bigExplosion, pos[0], pos[1], pos[2]);
}

void PlayExplosionSound(const float pos[3], bool bigExplosion = false)
{
	// Array de sonidos de explosión disponibles
	char explosionSounds[7][PLATFORM_MAX_PATH] = {
		"weapons/grenade_launcher/grenade_launcher_explode.wav",
		"weapons/hegrenade/explode3.wav",
		"weapons/hegrenade/explode4.wav",
		"weapons/hegrenade/explode5.wav",
		"ambient/explosions/explode_1.wav",
		"ambient/explosions/explode_2.wav",
		"ambient/explosions/explode_3.wav"
	};

	// Seleccionar sonido aleatorio
	int randomIndex = GetRandomInt(0, 6);
	char selectedSound[PLATFORM_MAX_PATH];
	strcopy(selectedSound, sizeof(selectedSound), explosionSounds[randomIndex]);

	// Volumen más alto para explosiones grandes
	float volume = bigExplosion ? 1.0 : 0.8;
	int pitch = bigExplosion ? SNDPITCH_NORMAL : GetRandomInt(95, 105);

	// Emitir sonido a TODOS los jugadores con origen en la posición
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			EmitSoundToClient(i, selectedSound, SOUND_FROM_WORLD, SNDCHAN_AUTO,
				SNDLEVEL_RAIDSIREN, SND_NOFLAGS, volume, pitch, -1,
				pos, NULL_VECTOR, true, 0.0);
		}
	}
}

// NUEVO: Efecto de ceguera (flashbang) para sobrevivientes
void FlashSurvivors(float duration, int alpha = 255)
{
	// Solo afecta a sobrevivientes (team 2)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;

		// SOLO team 2 (sobrevivientes)
		if (GetClientTeam(i) != 2) continue;

		// Crear efecto de fade blanco (ceguera)
		int fade = CreateEntityByName("env_fade");
		if (fade > MaxClients && IsValidEntity(fade))
		{
			char targetName[32];
			Format(targetName, sizeof(targetName), "ion_flash_%d", i);

			// Configurar el fade
			DispatchKeyValue(fade, "targetname", "ion_fade_temp");
			DispatchKeyValue(fade, "rendercolor", "255 255 255");  // Blanco
			DispatchKeyValueFloat(fade, "duration", duration);
			DispatchKeyValueFloat(fade, "holdtime", duration * 0.5);

			char sAlpha[8];
			IntToString(alpha, sAlpha, sizeof(sAlpha));
			DispatchKeyValue(fade, "renderamt", sAlpha);

			DispatchKeyValue(fade, "spawnflags", "1");  // Fade In
			DispatchSpawn(fade);

			// Asignar al jugador específico
			SetVariantString(targetName);
			AcceptEntityInput(i, "SetName");

			SetVariantString(targetName);
			AcceptEntityInput(fade, "SetTarget");

			AcceptEntityInput(fade, "Fade");

			// Eliminar después de usar
			CreateTimer(duration + 1.0, Timer_DeleteParticle, EntIndexToEntRef(fade), TIMER_FLAG_NO_MAPCHANGE);

			IonLog("FlashSurvivors: applied to client=%d, duration=%.1f", i, duration);
		}
	}
}

// NUEVO: Aplicar fuego a infectados en un radio (EXCLUYE sobrevivientes)
void IgniteInfectedInRadius(const float pos[3], float radius, float duration)
{
	// Quemar infectados comunes
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "infected")) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(ent))
		{
			float entPos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", entPos);

			if (GetVectorDistance(pos, entPos) <= radius)
			{
				IgniteEntity(ent, duration);
			}
		}
	}

	// Quemar witches
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "witch")) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(ent))
		{
			float entPos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", entPos);

			if (GetVectorDistance(pos, entPos) <= radius)
			{
				IgniteEntity(ent, duration);
			}
		}
	}

	// Quemar Infectados Especiales (SOLO team 3, NO sobrevivientes)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;

		// CRÍTICO: Solo team 3 (infectados), NUNCA team 2 (sobrevivientes)
		if (GetClientTeam(i) != 3) continue;
		if (GetEntProp(i, Prop_Send, "m_isGhost") != 0) continue;

		float playerPos[3];
		GetClientAbsOrigin(i, playerPos);

		if (GetVectorDistance(pos, playerPos) <= radius)
		{
			IgniteEntity(i, duration);
		}
	}
}