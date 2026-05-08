#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === ION CANNON MODULE (INTEGRATED) ===
// Sistema de Ion Cannon integrado en Eclipse
// Version simplificada sin comandos ni API externa
//==================================================

// ===================== Configuracion ======================
#define ION_DELAY 10.0              // Delay hasta el impacto (segundos)
#define ION_DURATION 26.0           // Duracion total del efecto
#define ION_COOLDOWN 45.0           // Cooldown entre usos (segundos)
#define ION_MAX_CHARGES 3           // Maximo de cargas por jugador
#define ION_CHARGES_PER_ROUND 1     // Cargas restauradas por ronda
#define ION_DAMAGE_COMMON 10        // Dano a infectados comunes
#define ION_DAMAGE_SI 10            // Dano a infectados especiales
#define ION_BEAM_RADIUS 1800.0      // Radio de los beams
#define ION_SHAKE_NEAR 900.0        // Radio de shake cercano
#define ION_SHAKE_MID 1800.0        // Radio de shake medio
#define ION_SHAKE_FAR 2600.0        // Radio de shake lejano
#define ION_PULSE_INTERVAL 3.0      // Intervalo de pulsos de dano
#define ION_TICK_ROTATE 0.5         // Tick de rotacion de beams
#define ION_TICK_RING 5.0           // Tick de anillos grandes
#define ION_TICK_CENTER 1.5         // Tick de beam central
#define ION_BLAST_RINGS 3           // Cantidad de anillos en blast
#define ION_BLAST_GAP 0.3           // Gap entre anillos del blast
#define ION_DAMAGE_RADIUS 800.0     // Radio de aplicacion de dano por tick

// === OPTIMIZACION: Limites de muertes por tick ===
#define ION_MAX_COMMON_KILLS_PER_TICK   10  // Maximo zombies comunes a matar por tick
#define ION_MAX_WITCH_KILLS_PER_TICK    2   // Maximo witches a matar por tick
#define ION_MAX_SPECIAL_KILLS_PER_TICK  3   // Maximo especiales a danar por tick

// ===================== ESTADO DEL JUGADOR ======================
bool   g_bIonActive[MAXPLAYERS + 1];
int    g_iIonToken[MAXPLAYERS + 1];
float  g_fIonCooldown[MAXPLAYERS + 1];
int    g_iIonCharges[MAXPLAYERS + 1];
int    g_iIonKillCount[MAXPLAYERS + 1];
int    g_iRingCount[MAXPLAYERS + 1];

// ===================== ENTIDADES Y POSICIONES ======================
float  g_vIonOrigin[MAXPLAYERS + 1][3];
float  g_vBeamOrigin[MAXPLAYERS + 1][6][3];
float  g_fBeamDeg[MAXPLAYERS + 1][6];
int    g_iIonEnts[MAXPLAYERS + 1][6];
float  g_fEndTime[MAXPLAYERS + 1];

// ===================== ASSETS CACHEADOS ======================
int    g_iCachedBeamSprite = -1;
int    g_iCachedHaloSprite = -1;

// ===================== RECURSOS ======================
char   SOUND_CRACKLE[] = "ambient/spacial_loops/lights_flicker.wav";
char   SOUND_ION[] = "ambient/energy/zap5.wav";
char   MODEL_FLARE[] = "models/props_lighting/light_flares.mdl";
char   SPRITE_BEAM[] = "materials/sprites/laserbeam.vmt";
char   SPRITE_HALO[] = "materials/sprites/halo01.vmt";

/**
 * Inicializa el modulo de Ion Cannon
 */
public void IonCannon_OnPluginStart()
{
	// Inicializar estados
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bIonActive[i] = false;
		g_iIonToken[i] = 0;
		g_fEndTime[i] = 0.0;
		g_iRingCount[i] = 0;
		g_iIonKillCount[i] = 0;
		g_fIonCooldown[i] = 0.0;
		g_iIonCharges[i] = 0;
	}
}

/**
 * Al inicio del mapa - Precachear recursos
 */
public void IonCannon_OnMapStart()
{
	// Precache modelo
	PrecacheModel(MODEL_FLARE, true);

	// Precache sonidos
	PrecacheSound(SOUND_CRACKLE, true);
	PrecacheSound(SOUND_ION, true);
	PrecacheSound("weapons/grenade_launcher/grenade_launcher_explode.wav", true);
	PrecacheSound("weapons/hegrenade/explode3.wav", true);
	PrecacheSound("weapons/hegrenade/explode4.wav", true);
	PrecacheSound("weapons/hegrenade/explode5.wav", true);
	PrecacheSound("ambient/explosions/explode_1.wav", true);
	PrecacheSound("ambient/explosions/explode_2.wav", true);
	PrecacheSound("ambient/energy/zap7.wav", true);
	PrecacheSound("ambient/energy/spark1.wav", true);
	PrecacheSound("ambient/energy/weld1.wav", true);
	PrecacheSound("items/suitchargeok1.wav", true);
	PrecacheSound("buttons/button14.wav", true);

	// Cache sprites
	g_iCachedBeamSprite = PrecacheModel(SPRITE_BEAM, true);
	g_iCachedHaloSprite = PrecacheModel(SPRITE_HALO, true);
}

/**
 * Al final del mapa
 */
public void IonCannon_OnMapEnd()
{
	g_iCachedBeamSprite = -1;
	g_iCachedHaloSprite = -1;
}

/**
 * Cuando un jugador se conecta
 */
public void IonCannon_OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		g_iIonCharges[client] = ION_MAX_CHARGES;
		g_fIonCooldown[client] = 0.0;
		g_iIonKillCount[client] = 0;
	}
}

/**
 * Cuando un jugador se desconecta
 */
public void IonCannon_OnClientDisconnect(int client)
{
	IonCannon_CleanupClient(client);
	g_iIonCharges[client] = 0;
	g_fIonCooldown[client] = 0.0;
}

/**
 * Al inicio de ronda - Restaurar cargas
 */
public void IonCannon_OnRoundStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			int newCharges = g_iIonCharges[i] + ION_CHARGES_PER_ROUND;
			if (newCharges > ION_MAX_CHARGES)
				newCharges = ION_MAX_CHARGES;
			g_iIonCharges[i] = newCharges;
		}
	}
}

/**
 * Verifica si el jugador puede usar Ion Cannon
 */
public bool IonCannon_CanUse(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return false;

	if (GetClientTeam(client) != 2)
		return false;

	if (g_bIonActive[client] && GetGameTime() < g_fEndTime[client])
		return false;

	if (GetGameTime() < g_fIonCooldown[client])
		return false;

	if (g_iIonCharges[client] <= 0)
		return false;

	return true;
}

/**
 * Obtiene el cooldown restante
 */
public float IonCannon_GetCooldown(int client)
{
	if (!IsClientInGame(client))
		return 0.0;

	float remaining = g_fIonCooldown[client] - GetGameTime();
	return (remaining > 0.0) ? remaining : 0.0;
}

/**
 * Obtiene las cargas disponibles
 */
public int IonCannon_GetCharges(int client)
{
	if (!IsClientInGame(client))
		return 0;

	return g_iIonCharges[client];
}

/**
 * Resetea el cooldown de Ion Cannon para un jugador
 */
stock void IonCannon_ResetCooldown(int client)
{
	g_fIonCooldown[client] = 0.0;
}

/**
 * Activa el Ion Cannon
 */
public bool IonCannon_Activate(int client)
{
	if (!IonCannon_CanUse(client))
		return false;

	// CONTROL GLOBAL: Verificar si hay algun bombardeo activo (Nuclear Strike u otro Ion Cannon)
	if (NuclearStrike_IsAnyActive())
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Ya hay un bombardeo activo (Nuclear Strike). Espera a que termine.");
		return false;
	}

	if (IonCannon_IsAnyActive())
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Ya hay un Ion Cannon activo. Espera a que termine.");
		return false;
	}

	// Limpiar cualquier Ion previo
	IonCannon_CleanupClient(client);

	// Marcar como activo
	g_bIonActive[client] = true;
	g_iIonToken[client]++;
	int token = g_iIonToken[client];

	// Establecer tiempo de fin
	g_fEndTime[client] = GetGameTime() + ION_DURATION;

	// Aplicar cooldown y consumir carga
	g_fIonCooldown[client] = GetGameTime() + ION_COOLDOWN;
	g_iIonCharges[client]--;

	// Reset contadores
	g_iIonKillCount[client] = 0;
	g_iRingCount[client] = 0;

	// Crear flare inicial
	IonCannon_CreateFlare(client);

	// Programar inicio del Ion
	CreateTimer(ION_DELAY, IonCannon_Timer_Start, IonCannon_PackData(client, token), TIMER_FLAG_NO_MAPCHANGE);

	// Feedback visual
	EmitSoundToClient(client, "items/suitchargeok1.wav");
	PrintToChat(client, "\x04[Ion Cannon]\x01 ⚡ Activado! Cargas: \x05%d\x01/\x05%d", g_iIonCharges[client], ION_MAX_CHARGES);

	return true;
}

/**
 * Crea el flare inicial (marcador visual)
 */
void IonCannon_CreateFlare(int client)
{
	float org[3], ang[3];
	GetClientAbsOrigin(client, org);
	GetClientAbsAngles(client, ang);

	// Guardar origen
	g_vIonOrigin[client] = org;

	// Crear prop del flare
	int prop = CreateEntityByName("prop_dynamic");
	if (prop > MaxClients && IsValidEntity(prop))
	{
		SetEntityModel(prop, MODEL_FLARE);
		DispatchSpawn(prop);
		TeleportEntity(prop, org, ang, NULL_VECTOR);
		g_iIonEnts[client][1] = prop;
		EmitSoundToAll(SOUND_CRACKLE, prop, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER, SND_NOFLAGS, 0.8);
	}

	// Crear spotlight
	int spot = CreateEntityByName("point_spotlight");
	if (spot > MaxClients && IsValidEntity(spot))
	{
		DispatchKeyValue(spot, "rendercolor", "200 20 15");
		DispatchKeyValue(spot, "spotlightwidth", "1");
		DispatchKeyValue(spot, "spotlightlength", "3");
		DispatchKeyValue(spot, "renderamt", "255");
		DispatchKeyValue(spot, "angles", "90 0 0");
		DispatchSpawn(spot);
		AcceptEntityInput(spot, "TurnOn");
		TeleportEntity(spot, org, NULL_VECTOR, NULL_VECTOR);
		g_iIonEnts[client][2] = spot;
	}

	// Crear steam effect
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
		g_iIonEnts[client][5] = steam;
	}
}

/**
 * Timer: Inicia el Ion Cannon (despues del delay)
 */
public Action IonCannon_Timer_Start(Handle timer, any data)
{
	int client, token;
	IonCannon_UnpackData(data, client, token);

	if (IonCannon_IsStale(client, token))
		return Plugin_Stop;

	// Setup beams orbitales
	IonCannon_SetupOrbitBeams(client);

	// Crear impacto inicial
	CreateTimer(1.0, IonCannon_Timer_CreateBlast, data, TIMER_FLAG_NO_MAPCHANGE);

	// Timers repetitivos
	CreateTimer(ION_TICK_ROTATE, IonCannon_Timer_LaserRotate, data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(ION_TICK_RING, IonCannon_Timer_RingTick, data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(ION_TICK_CENTER, IonCannon_Timer_CenterBeam, data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(ION_PULSE_INTERVAL, IonCannon_Timer_DamagePulse, data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Stop;
}

/**
 * Timer: Crea el blast principal
 */
public Action IonCannon_Timer_CreateBlast(Handle timer, any data)
{
	int client, token;
	IonCannon_UnpackData(data, client, token);

	if (IonCannon_IsStale(client, token))
		return Plugin_Stop;

	float flarePos[3];
	int flare = g_iIonEnts[client][1];
	if (flare > MaxClients && IsValidEntity(flare))
		GetEntPropVector(flare, Prop_Send, "m_vecOrigin", flarePos);
	else
		flarePos = g_vIonOrigin[client];

	// Ocultar flare
	IonCannon_SmashFlare(client);

	// Beam del cielo
	float sky[3];
	sky = flarePos;
	sky[2] += 8192.0;

	TE_SetupBeamPoints(sky, flarePos, g_iCachedBeamSprite, g_iCachedHaloSprite,
		0, 10, 6.0, 400.0, 450.0, 10, 4.0, {160,145,255,200}, 0);
	TE_SendToAll();

	// Explosion grande
	IonCannon_CreateExplosion(flarePos, true);
	IonCannon_PlayExplosionSound(flarePos);
	IonCannon_IgniteInfectedInRadius(flarePos, 1000.0, 10.0);

	// Anillos extra
	for (int k = 0; k < ION_BLAST_RINGS; k++)
		CreateTimer(k * ION_BLAST_GAP, IonCannon_Timer_BlastRing, data, TIMER_FLAG_NO_MAPCHANGE);

	// Sonido principal
	if (flare > MaxClients && IsValidEntity(flare))
		EmitSoundToAll(SOUND_ION, flare, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8);

	return Plugin_Stop;
}

/**
 * Timer: Anillos extra del blast
 */
public Action IonCannon_Timer_BlastRing(Handle timer, any data)
{
	int client, token;
	IonCannon_UnpackData(data, client, token);

	if (IonCannon_IsStale(client, token) || !IonCannon_WindowTick(client))
		return Plugin_Stop;

	float p[3];
	p = g_vIonOrigin[client];
	p[2] += 20.0;

	TE_SetupBeamRingPoint(p, 350.0, ION_BEAM_RADIUS, g_iCachedBeamSprite, g_iCachedHaloSprite,
		0, 30, 7.8, 70.0, 5.0, {160, 145, 255, 180}, 0, 0);
	TE_SendToAll();

	IonCannon_CreateExplosion(p, false);
	IonCannon_IgniteInfectedInRadius(p, 600.0, 4.0);

	return Plugin_Stop;
}

/**
 * Timer: Anillos grandes periodicos
 */
public Action IonCannon_Timer_RingTick(Handle timer, any data)
{
	int client, token;
	IonCannon_UnpackData(data, client, token);

	if (IonCannon_IsStale(client, token) || !IonCannon_WindowTick(client))
		return Plugin_Stop;

	g_iRingCount[client]++;

	float p[3];
	p = g_vIonOrigin[client];
	p[2] += 20.0;

	TE_SetupBeamRingPoint(p, 350.0, ION_BEAM_RADIUS, g_iCachedBeamSprite, g_iCachedHaloSprite,
		0, 30, 5.2, 80.0, 5.0, {160, 145, 255, 155}, 0, 0);
	TE_SendToAll();

	IonCannon_CreateExplosion(p, false);
	IonCannon_PlayExplosionSound(p);
	IonCannon_IgniteInfectedInRadius(p, 500.0, 4.0);

	// Terminar despues del 3er anillo
	if (g_iRingCount[client] >= 3)
	{
		CreateTimer(0.5, IonCannon_Timer_ForceCleanup, data, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}

	// Screen shake
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
			IonCannon_ScreenShake(i, 8.0);
	}

	return Plugin_Continue;
}

/**
 * Timer: Beam central del cielo (loop)
 */
public Action IonCannon_Timer_CenterBeam(Handle timer, any data)
{
	int client, token;
	IonCannon_UnpackData(data, client, token);

	if (IonCannon_IsStale(client, token) || !IonCannon_WindowTick(client))
		return Plugin_Stop;

	float flarePos[3];
	flarePos = g_vIonOrigin[client];

	float sky[3];
	sky = flarePos;
	sky[2] += 8192.0;

	TE_SetupBeamPoints(sky, flarePos, g_iCachedBeamSprite, g_iCachedHaloSprite,
		0, 10, 3.0, 350.0, 420.0, 10, 4.0, {160, 145, 255, 160}, 50);
	TE_SendToAll();

	// Explosion ocasional
	if (GetRandomInt(0, 100) < 20)
	{
		IonCannon_CreateExplosion(flarePos, false);
		IonCannon_IgniteInfectedInRadius(flarePos, 200.0, 3.0);
	}

	return Plugin_Continue;
}

/**
 * Timer: Beams orbitales rotativos
 */
public Action IonCannon_Timer_LaserRotate(Handle timer, any data)
{
	int client, token;
	IonCannon_UnpackData(data, client, token);

	if (IonCannon_IsStale(client, token) || !IonCannon_WindowTick(client))
		return Plugin_Stop;

	float dist = 250.0;
	for (int i = 0; i < 6; i++)
	{
		g_fBeamDeg[client][i] += 1.5;
		if (g_fBeamDeg[client][i] > 360.0)
			g_fBeamDeg[client][i] -= 360.0;

		g_vBeamOrigin[client][i][0] = g_vIonOrigin[client][0] + Sine(DegToRad(g_fBeamDeg[client][i])) * dist;
		g_vBeamOrigin[client][i][1] = g_vIonOrigin[client][1] + Cosine(DegToRad(g_fBeamDeg[client][i])) * dist;
		g_vBeamOrigin[client][i][2] = g_vIonOrigin[client][2];
	}

	for (int i = 0; i < 6; i++)
	{
		float start[3];
		start[0] = g_vBeamOrigin[client][i][0];
		start[1] = g_vBeamOrigin[client][i][1];
		start[2] = g_vIonOrigin[client][2] + GetRandomFloat(300.0, 1200.0);

		TE_SetupBeamPoints(start, g_vBeamOrigin[client][i], g_iCachedBeamSprite, g_iCachedHaloSprite,
			0, 0, 1.2, 25.0, 25.0, 0, 0.0, {160, 145, 255, 120}, 10);
		TE_SendToAll();

		// Mini explosion ocasional
		if (GetRandomInt(0, 100) < 15)
		{
			IonCannon_CreateExplosion(g_vBeamOrigin[client][i], false);
			IonCannon_IgniteInfectedInRadius(g_vBeamOrigin[client][i], 150.0, 3.0);
		}
	}

	return Plugin_Continue;
}

/**
 * Timer: Pulso de dano a infectados
 */
public Action IonCannon_Timer_DamagePulse(Handle timer, any data)
{
	int client, token;
	IonCannon_UnpackData(data, client, token);

	if (IonCannon_IsStale(client, token) || !IonCannon_WindowTick(client))
		return Plugin_Stop;

	// Quemar infectados en el area
	IonCannon_IgniteInfectedInRadius(g_vIonOrigin[client], 800.0, 5.0);

	// Dano a infectados comunes (LIMITADO a N por tick para evitar sobrecarga)
	int ent = -1;
	int commonProcessedThisTick = 0;
	while ((ent = FindEntityByClassname(ent, "infected")) != INVALID_ENT_REFERENCE)
	{
		if (!IsValidEntity(ent))
			continue;

		if (commonProcessedThisTick >= ION_MAX_COMMON_KILLS_PER_TICK)
			break;

		float entPos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", entPos);
		if (GetVectorDistance(g_vIonOrigin[client], entPos) > ION_DAMAGE_RADIUS)
			continue;

		SDKHooks_TakeDamage(ent, 0, client, float(ION_DAMAGE_COMMON), DMG_BURN);
		commonProcessedThisTick++;
	}

	// Dano a witches (LIMITADO a N por tick)
	ent = -1;
	int witchProcessedThisTick = 0;
	while ((ent = FindEntityByClassname(ent, "witch")) != INVALID_ENT_REFERENCE)
	{
		if (!IsValidEntity(ent))
			continue;

		if (witchProcessedThisTick >= ION_MAX_WITCH_KILLS_PER_TICK)
			break;

		float witchPos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", witchPos);
		if (GetVectorDistance(g_vIonOrigin[client], witchPos) > ION_DAMAGE_RADIUS)
			continue;

		SDKHooks_TakeDamage(ent, 0, client, float(ION_DAMAGE_COMMON), DMG_BURN);
		witchProcessedThisTick++;
	}

	// Dano a infectados especiales (LIMITADO a N por tick)
	int specialProcessedThisTick = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if (GetClientTeam(i) != 3)
			continue;

		if (GetEntProp(i, Prop_Send, "m_isGhost") != 0)
			continue;

		if (specialProcessedThisTick >= ION_MAX_SPECIAL_KILLS_PER_TICK)
			break;

		float siPos[3];
		GetClientAbsOrigin(i, siPos);
		if (GetVectorDistance(g_vIonOrigin[client], siPos) > ION_DAMAGE_RADIUS)
			continue;

		SDKHooks_TakeDamage(i, 0, client, float(ION_DAMAGE_SI), DMG_BURN);
		specialProcessedThisTick++;
	}

	// Screen shake
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		int team = GetClientTeam(i);
		if (team != 2 && team != 3)
			continue;

		float pos[3];
		GetClientAbsOrigin(i, pos);
		float d = GetVectorDistance(g_vIonOrigin[client], pos);

		if (d <= ION_SHAKE_NEAR)
			IonCannon_ScreenShake(i, 15.0);
		else if (d <= ION_SHAKE_MID)
			IonCannon_ScreenShake(i, 10.0);
		else if (d <= ION_SHAKE_FAR)
			IonCannon_ScreenShake(i, 5.0);
	}

	return Plugin_Continue;
}

/**
 * Timer: Forzar cleanup despues del 3er anillo
 */
public Action IonCannon_Timer_ForceCleanup(Handle timer, any data)
{
	int client, token;
	IonCannon_UnpackData(data, client, token);

	if (IsClientInGame(client) && g_iIonToken[client] == token)
		IonCannon_CleanupClient(client);

	return Plugin_Stop;
}

// ===================== FUNCIONES DE SOPORTE ======================

/**
 * Verifica si el timer debe continuar
 */
bool IonCannon_WindowTick(int client)
{
	if (GetGameTime() >= g_fEndTime[client])
	{
		IonCannon_CleanupClient(client);
		return false;
	}
	return true;
}

/**
 * Verifica si el token es valido
 */
bool IonCannon_IsStale(int client, int token)
{
	return !IsClientInGame(client) || !g_bIonActive[client] || token != g_iIonToken[client];
}

/**
 * Oculta el flare
 */
void IonCannon_SmashFlare(int client)
{
	int ent = g_iIonEnts[client][1];
	if (ent > MaxClients && IsValidEntity(ent))
	{
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
		SetEntityRenderColor(ent, 100, 100, 100, 0);
	}

	// Apagar spotlight y steam
	for (int i = 2; i <= 5; i++)
	{
		ent = g_iIonEnts[client][i];
		if (ent > MaxClients && IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "TurnOff");
			SetVariantString("OnUser1 !self:Kill::1.0:-1");
			AcceptEntityInput(ent, "AddOutput");
			AcceptEntityInput(ent, "FireUser1");
			g_iIonEnts[client][i] = 0;
		}
	}
}

/**
 * Limpia todas las entidades del Ion Cannon
 */
void IonCannon_CleanupClient(int client)
{
	// Stop sounds
	int flare = g_iIonEnts[client][1];
	if (flare > MaxClients && IsValidEntity(flare))
	{
		StopSound(flare, SNDCHAN_AUTO, SOUND_CRACKLE);
		StopSound(flare, SNDCHAN_AUTO, SOUND_ION);
		AcceptEntityInput(flare, "Kill");
	}

	// Kill all entities
	for (int i = 1; i <= 5; i++)
	{
		int ent = g_iIonEnts[client][i];
		if (ent > MaxClients && IsValidEntity(ent))
			AcceptEntityInput(ent, "Kill");
		g_iIonEnts[client][i] = 0;
	}

	// Reportar kills
	if (g_bIonActive[client] && g_iIonKillCount[client] > 0)
	{
		if (IsClientInGame(client))
		{
			PrintToChat(client, "\x04[Ion Cannon]\x01 Completado - Kills: \x05%d", g_iIonKillCount[client]);
		}
	}

	// Reset state
	g_bIonActive[client] = false;
	g_vIonOrigin[client][0] = 0.0;
	g_vIonOrigin[client][1] = 0.0;
	g_vIonOrigin[client][2] = 0.0;
	g_iRingCount[client] = 0;
	g_iIonKillCount[client] = 0;
}

/**
 * Setup de beams orbitales
 */
void IonCannon_SetupOrbitBeams(int client)
{
	float base[3];
	base = g_vIonOrigin[client];

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
		g_vBeamOrigin[client][i][0] = base[0] + offs[i][0];
		g_vBeamOrigin[client][i][1] = base[1] + offs[i][1];
		g_vBeamOrigin[client][i][2] = base[2];
		g_fBeamDeg[client][i] = degs[i];
	}
}

/**
 * Crea una explosion visual
 */
void IonCannon_CreateExplosion(const float pos[3], bool bigExplosion = false)
{
	// env_explosion (sin dano)
	int explosion = CreateEntityByName("env_explosion");
	if (explosion > MaxClients && IsValidEntity(explosion))
	{
		DispatchKeyValue(explosion, "iMagnitude", bigExplosion ? "500" : "300");
		DispatchKeyValue(explosion, "iRadiusOverride", bigExplosion ? "600" : "400");
		DispatchKeyValue(explosion, "spawnflags", "1");  // Sin dano
		DispatchSpawn(explosion);
		TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode");
		CreateTimer(0.1, IonCannon_Timer_DeleteEnt, EntIndexToEntRef(explosion), TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * Reproduce sonido de explosion
 */
void IonCannon_PlayExplosionSound(const float pos[3])
{
	char sounds[4][PLATFORM_MAX_PATH] = {
		"weapons/grenade_launcher/grenade_launcher_explode.wav",
		"weapons/hegrenade/explode3.wav",
		"ambient/explosions/explode_1.wav",
		"ambient/explosions/explode_2.wav"
	};

	int idx = GetRandomInt(0, 3);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			EmitSoundToClient(i, sounds[idx], SOUND_FROM_WORLD, SNDCHAN_AUTO,
				SNDLEVEL_RAIDSIREN, SND_NOFLAGS, 0.8, SNDPITCH_NORMAL, -1,
				pos, NULL_VECTOR, true, 0.0);
		}
	}
}

/**
 * Enciende infectados en un radio
 */
void IonCannon_IgniteInfectedInRadius(const float pos[3], float radius, float duration)
{
	// Infectados comunes
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "infected")) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(ent))
		{
			float entPos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", entPos);

			if (GetVectorDistance(pos, entPos) <= radius)
				IgniteEntity(ent, duration);
		}
	}

	// Witches
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "witch")) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(ent))
		{
			float entPos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", entPos);

			if (GetVectorDistance(pos, entPos) <= radius)
				IgniteEntity(ent, duration);
		}
	}

	// Infectados especiales
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if (GetClientTeam(i) != 3)
			continue;

		if (GetEntProp(i, Prop_Send, "m_isGhost") != 0)
			continue;

		float playerPos[3];
		GetClientAbsOrigin(i, playerPos);

		if (GetVectorDistance(pos, playerPos) <= radius)
			IgniteEntity(i, duration);
	}
}

/**
 * Screen shake simple
 */
void IonCannon_ScreenShake(int client, float amp)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	float pos[3];
	GetClientAbsOrigin(client, pos);

	int shake = CreateEntityByName("env_shake");
	if (shake != -1 && IsValidEntity(shake))
	{
		char sAmp[16], sFreq[16], sDur[16];
		FloatToString(amp, sAmp, sizeof(sAmp));
		FloatToString(10.0, sFreq, sizeof(sFreq));
		FloatToString(2.0, sDur, sizeof(sDur));

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

/**
 * Timer para eliminar entidades
 */
public Action IonCannon_Timer_DeleteEnt(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
		AcceptEntityInput(entity, "Kill");
	return Plugin_Stop;
}

/**
 * Empaqueta client y token en un int
 */
int IonCannon_PackData(int client, int token)
{
	return (token << 16) | (client & 0xFFFF);
}

/**
 * Desempaqueta client y token
 */
void IonCannon_UnpackData(any packed, int &client, int &token)
{
	client = (packed & 0xFFFF);
	token = (packed >> 16) & 0xFFFF;
}

/**
 * Verifica si hay algun Ion Cannon activo
 * Usado por el sistema de control global de bombardeos
 */
stock bool IonCannon_IsAnyActive()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bIonActive[i])
			return true;
	}
	return false;
}
