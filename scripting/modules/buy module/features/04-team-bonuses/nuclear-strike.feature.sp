#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//////////////////////////////////////////
// TEAM BONUSES: Nuclear Strike         //
//     *** OPTIMIZED EDITION ***         //
//////////////////////////////////////////

// --- Defines ---
#define NUKE_COUNTDOWN_TIME			5.0			// Tiempo de countdown antes de explosión (segundos)
#define NUKE_EFFECT_DURATION		20.0		// Duración total de efectos de daño (segundos)
#define NUKE_DAMAGE_TICK_INTERVAL	0.3			// Intervalo entre ticks de daño (segundos)
#define NUKE_DAMAGE_PER_TICK		300			// Daño por tick
#define NUKE_RADIUS					2500.0		// Radio de efecto (unidades)
#define NUKE_SHAKE_RADIUS_1			1200.0		// Radio para shake intenso
#define NUKE_SHAKE_RADIUS_2			2500.0		// Radio para shake medio
#define NUKE_SHAKE_RADIUS_3			4000.0		// Radio para shake suave
#define NUKE_PUSH_FORCE				800.0		// Fuerza de empuje a infectados
#define NUKE_MUSHROOM_HEIGHT		1500.0		// Altura del hongo atómico
#define NUKE_SMOKE_COLUMN_HEIGHT	2000.0		// Altura de la columna de humo persistente
#define NUKE_SMOKE_COLUMN_DURATION	30.0		// Duración de la columna de humo (segundos)

// === OPTIMIZACIÓN ULTRA: Mínimas partículas ===
#define NUKE_MAX_PARTICLES_PER_WAVE		1		// MÍNIMO: 1 partícula por onda
#define NUKE_MAX_FIREBALLS				1		// MÍNIMO: 1 bola de fuego
#define NUKE_MAX_DEBRIS					1		// MÍNIMO: 1 escombro
#define NUKE_VISUAL_TICK_RATE			1.0		// MÍNIMO: 1 segundo (muy lento)
#define NUKE_SECONDARY_EXPLOSION_RATE	5.0		// MÍNIMO: 5 segundos (muy espaciado)
#define NUKE_LOG_FILE					"logs/nuclear_strike.log"	// Archivo de logs

// === OPTIMIZACIÓN: Límites de muertes por tick ===
#define NUKE_MAX_COMMON_KILLS_PER_TICK	5		// Máximo zombies comunes a matar por tick
#define NUKE_MAX_WITCH_KILLS_PER_TICK	1		// Máximo witches a matar por tick
#define NUKE_MAX_SPECIAL_KILLS_PER_TICK	2		// Máximo especiales a dañar por tick

// Colores para efectos
#define GLOW_COLOR_RED				RGB_TO_INT(255, 50, 50)
#define GLOW_COLOR_ORANGE			RGB_TO_INT(255, 150, 0)
#define GLOW_COLOR_WHITE			RGB_TO_INT(255, 255, 255)
#define FLARE_COLOR					"200 20 15"	// Color rojo intenso para bengala

// --- Variables ---
static bool   g_bNukeActive[MAXPLAYERS + 1];		// Si el jugador tiene un nuke activo
static float  g_fNukeOrigin[MAXPLAYERS + 1][3];	// Origen de la explosión
static int    g_iNukeFlareEntity[MAXPLAYERS + 1];	// Entidad de bengala visual
static Handle g_hNukeDamageTimer[MAXPLAYERS + 1];	// Timer de daño continuo
static Handle g_hNukeEffectsTimer[MAXPLAYERS + 1];	// Timer de efectos visuales
static Handle g_hNukeSirenTimer[MAXPLAYERS + 1];	// Timer de sirena de alerta
static float  g_fNukeEndTime[MAXPLAYERS + 1];		// Tiempo cuando termina el nuke
static int    g_iNukeUsedThisMap[MAXPLAYERS + 1];	// Contador de usos por mapa
static int    g_iNukeCountdown[MAXPLAYERS + 1];	// Contador de countdown
static float  g_fNukeExplosionTime[MAXPLAYERS + 1]; // Tiempo de la explosión

// Modelos y sonidos
static const char NUKE_MODEL_FLARE[] = "models/props_lighting/light_flares.mdl";
static const char NUKE_SOUND_CRACKLE[] = "ambient/fire/fire_small_loop2.wav";
static const char NUKE_SOUND_RUMBLE[] = "ambient/levels/caves/rumble3.wav";
static const char NUKE_SOUND_EXPLODE[] = "weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav";
static const char NUKE_SOUND_ALARM[] = "ambient/alarms/klaxon1.wav";
static const char NUKE_SOUND_WIND[] = "ambient/wind/wind_hit1.wav";

// Partículas de nuclear strike (EXPANDIDAS)
static const char PARTICLE_NUKE_HIT[] = "gen_hit_up";
static const char PARTICLE_NUKE_WAVE[] = "gas_explosion_ground_wave";
static const char PARTICLE_NUKE_SMOKE_A[] = "gas_explosion_firesmoke";
static const char PARTICLE_NUKE_SMOKE_B[] = "gen_hit1_edynamicBillow";
static const char PARTICLE_NUKE_DEBRIS_A[] = "gas_explosion_debris_parents";
static const char PARTICLE_NUKE_DEBRIS_B[] = "gen_hit1_b";
static const char PARTICLE_NUKE_FIRE_A[] = "gas_fireball";
static const char PARTICLE_NUKE_FIRE_B[] = "gas_explosion_fireball";
static const char PARTICLE_NUKE_FIRE_C[] = "gas_explosion_fireball2";
static const char PARTICLE_FLARE[] = "flare_burning";
static const char PARTICLE_NUKE_EXPLOSION[] = "explosion_huge";
static const char PARTICLE_NUKE_FIRE_LARGE[] = "fire_large_01";
static const char PARTICLE_NUKE_SMOKE_LARGE[] = "smoke_large_01";
static const char PARTICLE_NUKE_EMBERS[] = "fire_small_smoke";
static const char PARTICLE_NUKE_SHOCKWAVE[] = "weapon_pipebomb_child_sparks2";

// === SISTEMA DE LOGGING ===
/**
 * Escribe un log detallado en el archivo de Nuclear Strike
 */
stock void NukeLog(const char[] format, any ...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);

	char logPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, logPath, sizeof(logPath), NUKE_LOG_FILE);

	LogToFileEx(logPath, "[NUKE] %s", buffer);
}

/**
 * Activa Nuclear Strike para un jugador.
 * Crea una bengala en el suelo, countdown de 5 segundos, y explosión masiva.
 *
 * @param client  Índice del jugador que activa la habilidad.
 */
stock void Activate_NuclearStrike(int client)
{
	NukeLog("=== INICIO NUCLEAR STRIKE - Cliente: %N (%d) ===", client, client);

	// 1. Verificar si es survivor
	if (!IsSurvivor(client))
	{
		NukeLog("ABORTADO: Cliente %N no es survivor", client);
		PrintToChat(client, "\x05[Eclipse]\x01 Solo los sobrevivientes pueden usar esta habilidad.");
		return;
	}

	// 2. Verificar si está vivo
	if (!IsPlayerAlive(client))
	{
		NukeLog("ABORTADO: Cliente %N no está vivo", client);
		PrintToChat(client, "\x05[Eclipse]\x01 Debes estar vivo para usar Nuclear Strike.");
		return;
	}

	// 3. Verificar si está en el suelo
	int flags = GetEntityFlags(client);
	if (!(flags & FL_ONGROUND))
	{
		NukeLog("ABORTADO: Cliente %N no está en el suelo (flags: %d)", client, flags);
		PrintToChat(client, "\x05[Eclipse]\x01 Debes estar en el suelo para lanzar Nuclear Strike.");
		return;
	}

	// 4. Verificar límite de usos (1 por mapa)
	if (g_iNukeUsedThisMap[client] > 0)
	{
		NukeLog("ABORTADO: Cliente %N ya usó Nuclear Strike este mapa", client);
		PrintToChat(client, "\x05[Eclipse]\x01 Solo puedes usar Nuclear Strike \x04una vez por mapa\x01.");
		return;
	}

	// 5. Verificar si hay bombardeo activo
	if (IsAnyBombardmentActive())
	{
		NukeLog("ABORTADO: Ya hay un bombardeo activo");
		PrintToChat(client, "\x05[Eclipse]\x01 Ya hay un bombardeo activo. Espera a que termine.");
		return;
	}

	// 6. Obtener posición del jugador
	GetClientAbsOrigin(client, g_fNukeOrigin[client]);
	NukeLog("Posición de origen: [%.1f, %.1f, %.1f]", g_fNukeOrigin[client][0], g_fNukeOrigin[client][1], g_fNukeOrigin[client][2]);

	// 7. Marcar como usado
	g_iNukeUsedThisMap[client] = 1;
	g_bNukeActive[client] = true;
	g_iNukeCountdown[client] = 5;
	NukeLog("Nuclear Strike activado - Countdown iniciado");

	// 8. Crear bengala de señal
	NukeLog("Creando bengala de señal...");
	CreateNukeFlare(client);

	// 9. Iniciar sistema de alerta (sirena y efectos)
	StartNukeAlertSystem(client);

	// 10. Anuncios épicos
	PrintToChatAll("\x05[Eclipse]\x01 \x04⚠ ALERTA NUCLEAR ⚠");
	PrintToChatAll("\x05[Eclipse]\x01 \x04%N\x01 ha iniciado \x03NUCLEAR STRIKE\x01!", client);
	PrintToChatAll("\x05[Eclipse]\x01 \x03¡¡¡EVACÚEN EL ÁREA INMEDIATAMENTE!!!");

	// 11. Countdown visual
	CreateTimer(1.0, Timer_NukeCountdown, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.0, Timer_NukeCountdown, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(3.0, Timer_NukeCountdown, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(4.0, Timer_NukeCountdown, client, TIMER_FLAG_NO_MAPCHANGE);

	// 12. Lanzar nuke después de 5 segundos
	CreateTimer(NUKE_COUNTDOWN_TIME, Timer_LaunchNuke, client, TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Sistema de alerta pre-explosión (sirenas, luces parpadeantes, etc.)
 */
static void StartNukeAlertSystem(int client)
{
	// Sirena de alerta
	EmitSoundToAll(NUKE_SOUND_ALARM, client, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, SND_NOFLAGS, 1.0);

	// Glow rojo parpadeante para todos los sobrevivientes
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i))
		{
			SetEntProp(i, Prop_Send, "m_glowColorOverride", GLOW_COLOR_RED);
			SetEntProp(i, Prop_Send, "m_iGlowType", 3);
		}
	}

	// Timer de efectos pulsantes
	g_hNukeSirenTimer[client] = CreateTimer(0.5, Timer_AlertPulse, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Timer de pulso de alerta (efectos visuales pulsantes)
 */
public Action Timer_AlertPulse(Handle timer, int client)
{
	if (!g_bNukeActive[client] || g_iNukeCountdown[client] <= 0)
	{
		g_hNukeSirenTimer[client] = INVALID_HANDLE;
		// Remover glow de alerta
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsSurvivor(i) && IsPlayerAlive(i))
			{
				SetEntProp(i, Prop_Send, "m_iGlowType", 0);
			}
		}
		return Plugin_Stop;
	}

	// Fade rojo pulsante
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			L4D_ScreenFade(i, 255, 0, 0, 80, 0.5, FADE_IN);
		}
	}

	return Plugin_Continue;
}

/**
 * Timer de countdown (anuncios)
 */
public Action Timer_NukeCountdown(Handle timer, int client)
{
	if (!g_bNukeActive[client])
		return Plugin_Stop;

	g_iNukeCountdown[client]--;

	// Anuncio en chat
	if (g_iNukeCountdown[client] > 0)
	{
		PrintToChatAll("\x05[Eclipse]\x01 \x04IMPACTO EN %d...", g_iNukeCountdown[client]);
	}

	// Sonido de rumble intenso
	EmitSoundToAll(NUKE_SOUND_RUMBLE, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8);

	// Shake creciente
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			float amplitude = (6.0 - g_iNukeCountdown[client]) * 0.5;
			ScreenShake(i, amplitude);
		}
	}

	return Plugin_Stop;
}

/**
 * Timer que lanza el nuke (después de 5 segundos)
 */
public Action Timer_LaunchNuke(Handle timer, int client)
{
	NukeLog("=== TIMER_LAUNCHNUKE - Cliente: %N ===", client);

	if (!g_bNukeActive[client])
	{
		NukeLog("ABORTADO: Nuclear Strike no activo para cliente %N", client);
		return Plugin_Stop;
	}

	g_fNukeExplosionTime[client] = GetGameTime();
	NukeLog("Tiempo de explosión: %.2f", g_fNukeExplosionTime[client]);

	// === FASE 1: FLASH CEGADOR ===
	NukeLog("FASE 1: Aplicando flash cegador a todos los clientes...");
	int flashCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			// Flash blanco masivo (2 segundos)
			L4D_ScreenFade(i, 255, 255, 255, 255, 2.0, FADE_IN);
			flashCount++;
		}
	}
	NukeLog("Flash aplicado a %d clientes", flashCount);

	// === FASE 2: SONIDOS APOCALÍPTICOS ===
	NukeLog("FASE 2: Reproduciendo sonidos de explosión...");
	EmitSoundToAll(NUKE_SOUND_EXPLODE, client, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, SND_NOFLAGS, 1.0);
	CreateTimer(0.3, Timer_PlayWindSound, client, TIMER_FLAG_NO_MAPCHANGE);

	// === FASE 3: DESTRUIR BENGALA ===
	NukeLog("FASE 3: Destruyendo bengala...");
	DestroyNukeFlare(client);

	// === FASE 4: EFECTOS VISUALES CATACLÍSMICOS ===
	NukeLog("FASE 4: Creando efectos visuales de explosión...");
	CreateNukeExplosionEffects(client);

	// === FASE 4B: HUMO DENSO ADICIONAL ESCALONADO (para máxima altura) ===
	CreateTimer(0.5, Timer_CreateDenseSmoke, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, Timer_CreateDenseSmoke, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.5, Timer_CreateDenseSmoke, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.0, Timer_CreateDenseSmoke, client, TIMER_FLAG_NO_MAPCHANGE);

	// === FASE 5: EMPUJE INICIAL (SHOCKWAVE) ===
	CreateTimer(0.2, Timer_InitialShockwave, client, TIMER_FLAG_NO_MAPCHANGE);

	// === FASE 6: INICIAR DAÑO CONTINUO ===
	g_fNukeEndTime[client] = GetGameTime() + NUKE_EFFECT_DURATION;
	g_hNukeDamageTimer[client] = CreateTimer(
		NUKE_DAMAGE_TICK_INTERVAL,
		Timer_NukeDamage,
		client,
		TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE
	);

	// === FASE 7: INICIAR EFECTOS VISUALES CONTINUOS (OPTIMIZADO: 0.25s en vez de 0.15s) ===
	g_hNukeEffectsTimer[client] = CreateTimer(
		NUKE_VISUAL_TICK_RATE,
		Timer_NukeVisualEffects,
		client,
		TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE
	);

	// === FASE 8: LLAMARADAS SECUNDARIAS (OPTIMIZADO: 2.0s en vez de 1.0s) ===
	CreateTimer(NUKE_SECONDARY_EXPLOSION_RATE, Timer_SecondaryExplosions, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	PrintToChatAll("\x05[Eclipse]\x01 \x04💀 ¡¡¡NUCLEAR STRIKE IMPACTADO!!! 💀");
	PrintToChatAll("\x05[Eclipse]\x01 \x03¡¡¡ZONA DE DEVASTACIÓN TOTAL!!!");

	return Plugin_Stop;
}

/**
 * Timer para sonido de viento post-explosión
 */
public Action Timer_PlayWindSound(Handle timer, int client)
{
	EmitSoundToAll(NUKE_SOUND_WIND, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.7);
	return Plugin_Stop;
}

/**
 * Timer de shockwave inicial (empuja a infectados)
 */
public Action Timer_InitialShockwave(Handle timer, int client)
{
	float nukeOrigin[3];
	nukeOrigin[0] = g_fNukeOrigin[client][0];
	nukeOrigin[1] = g_fNukeOrigin[client][1];
	nukeOrigin[2] = g_fNukeOrigin[client][2];

	// Empujar a todos los infectados cercanos
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if (GetClientTeam(i) != 3)
			continue;

		float playerOrigin[3];
		GetClientAbsOrigin(i, playerOrigin);
		float distance = GetVectorDistance(nukeOrigin, playerOrigin);

		if (distance <= NUKE_RADIUS)
		{
			// Calcular dirección de empuje
			float pushVec[3];
			MakeVectorFromPoints(nukeOrigin, playerOrigin, pushVec);
			NormalizeVector(pushVec, pushVec);

			// Aplicar fuerza inversamente proporcional a la distancia
			float force = NUKE_PUSH_FORCE * (1.0 - (distance / NUKE_RADIUS));
			ScaleVector(pushVec, force);

			// Empujar hacia arriba también
			pushVec[2] += force * 0.5;

			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, pushVec);

			// Glow naranja temporal
			SetEntProp(i, Prop_Send, "m_glowColorOverride", GLOW_COLOR_ORANGE);
			SetEntProp(i, Prop_Send, "m_iGlowType", 3);
			CreateTimer(3.0, Timer_NukeRemoveGlow, i, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	// Partícula de shockwave
	CreateParticleAtPos(nukeOrigin, PARTICLE_NUKE_SHOCKWAVE, 2.0);

	return Plugin_Stop;
}

/**
 * Crea la bengala de señal antes de la explosión
 */
static void CreateNukeFlare(int client)
{
	int flare = CreateEntityByName("prop_dynamic");
	if (flare == -1)
		return;

	SetEntityModel(flare, NUKE_MODEL_FLARE);
	DispatchSpawn(flare);

	float origin[3], angles[3];
	GetClientAbsOrigin(client, origin);
	GetClientAbsAngles(client, angles);

	TeleportEntity(flare, origin, angles, NULL_VECTOR);

	g_iNukeFlareEntity[client] = flare;

	// Sonido de bengala
	EmitSoundToAll(NUKE_SOUND_CRACKLE, flare, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.7);

	// Crear múltiples luces de colores
	CreateFlareLight(origin, "200 20 15", 90.0);		// Roja principal
	CreateFlareLight(origin, "255 150 0", 85.0);		// Naranja
	CreateFlareLight(origin, "255 255 200", 95.0);	// Blanca caliente

	// Partícula de llamas en la bengala
	CreateParticle(flare, PARTICLE_FLARE, 5.0);
	CreateParticle(flare, PARTICLE_NUKE_EMBERS, 5.0);
}

/**
 * Crea una luz para la bengala
 */
static void CreateFlareLight(const float origin[3], const char[] color, float angle)
{
	int light = CreateEntityByName("point_spotlight");
	if (light == -1)
		return;

	DispatchKeyValue(light, "rendercolor", color);
	DispatchKeyValue(light, "rendermode", "9");
	DispatchKeyValue(light, "spotlightwidth", "15");
	DispatchKeyValue(light, "spotlightlength", "150");
	DispatchKeyValue(light, "renderamt", "255");
	DispatchKeyValue(light, "spawnflags", "1");
	DispatchSpawn(light);
	AcceptEntityInput(light, "TurnOn");

	float lightAngles[3];
	lightAngles[0] = angle;
	TeleportEntity(light, origin, lightAngles, NULL_VECTOR);

	// Destruir luz después de 5 segundos
	SetVariantString("OnUser1 !self:Kill::5.0:-1");
	AcceptEntityInput(light, "AddOutput");
	AcceptEntityInput(light, "FireUser1");
}

/**
 * Destruye la bengala
 */
static void DestroyNukeFlare(int client)
{
	if (g_iNukeFlareEntity[client] > 0 && IsValidEntity(g_iNukeFlareEntity[client]))
	{
		AcceptEntityInput(g_iNukeFlareEntity[client], "Kill");
		g_iNukeFlareEntity[client] = 0;
	}
}

/**
 * Crea los efectos visuales de la explosión nuclear (MEJORADOS)
 */
static void CreateNukeExplosionEffects(int client)
{
	NukeLog("CreateNukeExplosionEffects INICIADO para cliente %N", client);
	int particleCount = 0;

	float origin[3];
	origin[0] = g_fNukeOrigin[client][0];
	origin[1] = g_fNukeOrigin[client][1];
	origin[2] = g_fNukeOrigin[client][2];

	// === IMPACTO CENTRAL (OPTIMIZADO: 2 partículas) ===
	CreateParticleAtPos(origin, PARTICLE_NUKE_HIT, 5.0);
	CreateParticleAtPos(origin, PARTICLE_NUKE_EXPLOSION, 4.0);
	particleCount += 2;
	NukeLog("  -> Partículas impacto central: 2");

	// === ONDAS EXPANSIVAS (OPTIMIZADO: 3 ondas en vez de 6) ===
	CreateTimer(0.0, Timer_CreateNukeWave, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.3, Timer_CreateNukeWave, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.6, Timer_CreateNukeWave, client, TIMER_FLAG_NO_MAPCHANGE);

	// === BOLA DE FUEGO MASIVA - SIN HUMO PIXELADO (25 segundos de duración) ===
	CreateParticleAtPos(origin, PARTICLE_NUKE_FIRE_LARGE, 25.0);
	CreateParticleAtPos(origin, PARTICLE_NUKE_FIRE_LARGE, 25.0);
	CreateParticleAtPos(origin, PARTICLE_NUKE_FIRE_A, 25.0);
	CreateParticleAtPos(origin, PARTICLE_NUKE_FIRE_B, 25.0);
	particleCount += 4;
	NukeLog("  -> Bola de fuego masiva: 4 partículas");

	// === BOLAS DE FUEGO (OPTIMIZADO: %d bolas) ===
	for (int i = 0; i < NUKE_MAX_FIREBALLS; i++)
	{
		float angle = (360.0 / float(NUKE_MAX_FIREBALLS)) * float(i);
		float offsetOrigin[3];
		offsetOrigin[0] = origin[0] + (Cosine(DegToRad(angle)) * GetRandomFloat(80.0, 120.0));
		offsetOrigin[1] = origin[1] + (Sine(DegToRad(angle)) * GetRandomFloat(80.0, 120.0));
		offsetOrigin[2] = origin[2] + GetRandomFloat(-10.0, 30.0);

		// Solo UNA partícula por bola de fuego
		int particleType = i % 3;
		if (particleType == 0)
			CreateParticleAtPos(offsetOrigin, PARTICLE_NUKE_FIRE_A, 8.0);
		else if (particleType == 1)
			CreateParticleAtPos(offsetOrigin, PARTICLE_NUKE_FIRE_B, 7.0);
		else
			CreateParticleAtPos(offsetOrigin, PARTICLE_NUKE_FIRE_C, 7.0);
		particleCount++;
	}
	NukeLog("  -> Bolas de fuego secundarias: %d", NUKE_MAX_FIREBALLS);

	// === FUEGO CENTRAL ===
	CreateParticleAtPos(origin, PARTICLE_NUKE_FIRE_LARGE, 12.0);
	particleCount++;

	// === ESCOMBROS (OPTIMIZADO: %d escombros) ===
	for (int i = 0; i < NUKE_MAX_DEBRIS; i++)
	{
		float debrisOrigin[3];
		debrisOrigin[0] = origin[0] + GetRandomFloat(-100.0, 100.0);
		debrisOrigin[1] = origin[1] + GetRandomFloat(-100.0, 100.0);
		debrisOrigin[2] = origin[2];

		// Solo UNA partícula de escombros (alternando tipo)
		if (i % 2 == 0)
			CreateParticleAtPos(debrisOrigin, PARTICLE_NUKE_DEBRIS_A, 10.0);
		else
			CreateParticleAtPos(debrisOrigin, PARTICLE_NUKE_DEBRIS_B, 10.0);
		particleCount++;
	}
	NukeLog("  -> Escombros: %d", NUKE_MAX_DEBRIS);
	NukeLog("CreateNukeExplosionEffects FINALIZADO - Total partículas iniciales: %d", particleCount);
}

/**
 * Timer para crear capas adicionales de FUEGO (sin humo pixelado)
 */
public Action Timer_CreateDenseSmoke(Handle timer, int client)
{
	if (!g_bNukeActive[client])
		return Plugin_Stop;

	float origin[3];
	origin[0] = g_fNukeOrigin[client][0];
	origin[1] = g_fNukeOrigin[client][1];
	origin[2] = g_fNukeOrigin[client][2];

	// Crear capas de FUEGO masivo (sin humo)
	CreateParticleAtPos(origin, PARTICLE_NUKE_FIRE_LARGE, 20.0);
	CreateParticleAtPos(origin, PARTICLE_NUKE_FIRE_B, 20.0);

	float offsetOrigin[3];
	offsetOrigin[0] = origin[0] + GetRandomFloat(-30.0, 30.0);
	offsetOrigin[1] = origin[1] + GetRandomFloat(-30.0, 30.0);
	offsetOrigin[2] = origin[2];
	CreateParticleAtPos(offsetOrigin, PARTICLE_NUKE_FIRE_A, 20.0);

	return Plugin_Stop;
}

/**
 * Timer para crear hongo atómico
 */
public Action Timer_CreateMushroomCloud(Handle timer, int client)
{
	if (!g_bNukeActive[client])
		return Plugin_Stop;

	float origin[3];
	origin[0] = g_fNukeOrigin[client][0];
	origin[1] = g_fNukeOrigin[client][1];
	origin[2] = g_fNukeOrigin[client][2] + NUKE_MUSHROOM_HEIGHT;

	// Hongo de humo en altura
	CreateParticleAtPos(origin, PARTICLE_NUKE_SMOKE_B, 20.0);
	CreateParticleAtPos(origin, PARTICLE_NUKE_SMOKE_LARGE, 20.0);

	// Fuego en la base del hongo
	float baseOrigin[3];
	baseOrigin[0] = origin[0];
	baseOrigin[1] = origin[1];
	baseOrigin[2] = g_fNukeOrigin[client][2] + (NUKE_MUSHROOM_HEIGHT * 0.3);
	CreateParticleAtPos(baseOrigin, PARTICLE_NUKE_FIRE_B, 15.0);

	return Plugin_Stop;
}

/**
 * Timer para crear columna de humo persistente en las alturas
 * Usa solo el humo bueno (SMOKE_A) en múltiples capas verticales
 */
public Action Timer_CreateSmokeColumn(Handle timer, int client)
{
	if (!g_bNukeActive[client])
		return Plugin_Stop;

	float baseOrigin[3];
	baseOrigin[0] = g_fNukeOrigin[client][0];
	baseOrigin[1] = g_fNukeOrigin[client][1];
	baseOrigin[2] = g_fNukeOrigin[client][2];

	// Crear columna de humo usando solo el humo bueno en 6 capas verticales
	// Cada capa está separada verticalmente para crear efecto de columna
	float heightStep = NUKE_SMOKE_COLUMN_HEIGHT / 6.0;

	for (int i = 0; i < 6; i++)
	{
		float layerOrigin[3];
		layerOrigin[0] = baseOrigin[0] + GetRandomFloat(-30.0, 30.0);  // Ligera variación horizontal
		layerOrigin[1] = baseOrigin[1] + GetRandomFloat(-30.0, 30.0);
		layerOrigin[2] = baseOrigin[2] + (heightStep * float(i));

		CreateParticleAtPos(layerOrigin, PARTICLE_NUKE_SMOKE_A, NUKE_SMOKE_COLUMN_DURATION);
	}

	return Plugin_Stop;
}

/**
 * Timer para explosiones secundarias
 */
public Action Timer_SecondaryExplosions(Handle timer, int client)
{
	float currentTime = GetGameTime();

	if (currentTime >= g_fNukeEndTime[client])
	{
		return Plugin_Stop;
	}

	// Crear explosiones aleatorias en el área
	float origin[3];
	origin[0] = g_fNukeOrigin[client][0] + GetRandomFloat(-NUKE_RADIUS * 0.5, NUKE_RADIUS * 0.5);
	origin[1] = g_fNukeOrigin[client][1] + GetRandomFloat(-NUKE_RADIUS * 0.5, NUKE_RADIUS * 0.5);
	origin[2] = g_fNukeOrigin[client][2];

	CreateParticleAtPos(origin, PARTICLE_NUKE_FIRE_C, 3.0);
	CreateParticleAtPos(origin, PARTICLE_NUKE_EXPLOSION, 2.0);

	// Sonido de explosión lejana
	EmitSoundToAll(NUKE_SOUND_EXPLODE, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3);

	return Plugin_Continue;
}

/**
 * Timer para crear ondas expansivas
 */
public Action Timer_CreateNukeWave(Handle timer, int client)
{
	if (!g_bNukeActive[client])
		return Plugin_Stop;

	CreateParticleAtPos(g_fNukeOrigin[client], PARTICLE_NUKE_WAVE, 1.5);
	return Plugin_Stop;
}

/**
 * Timer de efectos visuales continuos (MEJORADO)
 */
public Action Timer_NukeVisualEffects(Handle timer, int client)
{
	float currentTime = GetGameTime();

	if (currentTime >= g_fNukeEndTime[client])
	{
		g_hNukeEffectsTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	// Screen shake para jugadores cercanos (INTENSO)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		float playerOrigin[3];
		GetClientAbsOrigin(i, playerOrigin);
		float distance = GetVectorDistance(g_fNukeOrigin[client], playerOrigin);

		// Shake variable por distancia
		if (distance <= NUKE_SHAKE_RADIUS_1)
		{
			ScreenShake(i, GetRandomFloat(7.0, 10.0));

			// Glow naranja intenso para sobrevivientes muy cerca
			if (IsSurvivor(i))
			{
				SetEntProp(i, Prop_Send, "m_glowColorOverride", GLOW_COLOR_ORANGE);
				SetEntProp(i, Prop_Send, "m_iGlowType", 3);
			}
		}
		else if (distance <= NUKE_SHAKE_RADIUS_2)
		{
			ScreenShake(i, GetRandomFloat(4.0, 7.0));
		}
		else if (distance <= NUKE_SHAKE_RADIUS_3)
		{
			ScreenShake(i, GetRandomFloat(2.0, 4.0));
		}

		// Fade naranja-rojo pulsante para los que están en el radio
		if (distance <= NUKE_RADIUS)
		{
			int red = GetRandomInt(200, 255);
			int green = GetRandomInt(50, 150);
			L4D_ScreenFade(i, red, green, 0, 60, 0.15, FADE_IN);
		}

		// === FLASHES DE LUZ PARA SOBREVIVIENTES ===
		if (IsSurvivor(i) && distance <= NUKE_RADIUS)
		{
			// Flash blanco intenso aleatorio (20% probabilidad)
			if (GetRandomInt(1, 5) == 1)
			{
				L4D_ScreenFade(i, 255, 255, 255, 180, 0.2, FADE_IN);
			}
			// Flash naranja explosivo (25% probabilidad)
			else if (GetRandomInt(1, 4) == 1)
			{
				L4D_ScreenFade(i, 255, 180, 50, 150, 0.15, FADE_IN);
			}
		}
	}

	// Efectos de fuego/humo aleatorios (OPTIMIZADO: 30% probabilidad en vez de 50%)
	if (GetRandomInt(1, 10) <= 3)
	{
		float randomOrigin[3];
		randomOrigin[0] = g_fNukeOrigin[client][0] + GetRandomFloat(-200.0, 200.0);
		randomOrigin[1] = g_fNukeOrigin[client][1] + GetRandomFloat(-200.0, 200.0);
		randomOrigin[2] = g_fNukeOrigin[client][2] + GetRandomFloat(0.0, 100.0);

		int particleChoice = GetRandomInt(1, 4);
		switch(particleChoice)
		{
			case 1: CreateParticleAtPos(randomOrigin, PARTICLE_NUKE_FIRE_C, 2.0);
			case 2: CreateParticleAtPos(randomOrigin, PARTICLE_NUKE_FIRE_LARGE, 2.0);
			case 3: CreateParticleAtPos(randomOrigin, PARTICLE_NUKE_EMBERS, 2.0);
			case 4: CreateParticleAtPos(randomOrigin, PARTICLE_NUKE_SMOKE_LARGE, 3.0);
		}
	}

	// Ondas de calor adicionales (OPTIMIZADO: 15% probabilidad en vez de 20%)
	if (GetRandomInt(1, 20) <= 3)
	{
		CreateParticleAtPos(g_fNukeOrigin[client], PARTICLE_NUKE_SHOCKWAVE, 1.0);
	}

	return Plugin_Continue;
}

/**
 * Timer de daño continuo (AUMENTADO)
 */
public Action Timer_NukeDamage(Handle timer, int client)
{
	float currentTime = GetGameTime();
	NukeLog("TIMER_NUKEDAMAGE - Cliente: %N, Tiempo actual: %.2f, Tiempo fin: %.2f", client, currentTime, g_fNukeEndTime[client]);

	if (currentTime >= g_fNukeEndTime[client])
	{
		NukeLog("Nuclear Strike FINALIZADO para cliente %N", client);
		// Terminar efectos
		g_bNukeActive[client] = false;
		g_hNukeDamageTimer[client] = INVALID_HANDLE;

		// Remover glows
		int glowsRemoved = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsSurvivor(i))
			{
				SetEntProp(i, Prop_Send, "m_iGlowType", 0);
				glowsRemoved++;
			}
		}
		NukeLog("Glows removidos: %d", glowsRemoved);

		PrintToChatAll("\x05[Eclipse]\x01 \x04Nuclear Strike\x01 ha terminado. \x03Zona devastada.");
		NukeLog("=== FIN NUCLEAR STRIKE - Cliente: %N ===", client);
		return Plugin_Stop;
	}

	// Aplicar daño a todos los infectados en el radio
	NukeLog("Aplicando daño en tick (tiempo restante: %.2f segundos)", g_fNukeEndTime[client] - currentTime);
	ApplyNukeDamage(client);

	return Plugin_Continue;
}

/**
 * Aplica daño a todos los infectados dentro del radio (MEJORADO)
 */
static void ApplyNukeDamage(int client)
{
	float nukeOrigin[3];
	nukeOrigin[0] = g_fNukeOrigin[client][0];
	nukeOrigin[1] = g_fNukeOrigin[client][1];
	nukeOrigin[2] = g_fNukeOrigin[client][2];

	int commonKilled = 0;
	int witchesKilled = 0;
	int specialsKilled = 0;

	// Daño a zombies comunes (LIMITADO a N por tick para evitar sobrecarga)
	int entity = -1;
	int commonProcessedThisTick = 0;
	while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
	{
		if (!IsValidEntity(entity))
			continue;

		// LÍMITE: Solo procesar X zombies comunes por tick
		if (commonProcessedThisTick >= NUKE_MAX_COMMON_KILLS_PER_TICK)
			break;

		float entityOrigin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityOrigin);
		float distance = GetVectorDistance(nukeOrigin, entityOrigin);

		if (distance <= NUKE_RADIUS)
		{
			// Daño escalado por distancia
			int damage = RoundToFloor(NUKE_DAMAGE_PER_TICK * (1.0 - (distance / NUKE_RADIUS) * 0.3));
			DealDamageEntity(entity, client, DMG_BURN | DMG_RADIATION, damage, "nuclear_strike");
			commonKilled++;
			commonProcessedThisTick++;
		}
	}
	if (commonKilled > 0)
		NukeLog("  -> Zombies comunes dañados: %d (límite: %d)", commonKilled, NUKE_MAX_COMMON_KILLS_PER_TICK);

	// Daño a witches (LIMITADO a N por tick)
	entity = -1;
	int witchProcessedThisTick = 0;
	while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
	{
		if (!IsValidEntity(entity))
			continue;

		// LÍMITE: Solo procesar X witches por tick
		if (witchProcessedThisTick >= NUKE_MAX_WITCH_KILLS_PER_TICK)
			break;

		float entityOrigin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityOrigin);
		float distance = GetVectorDistance(nukeOrigin, entityOrigin);

		if (distance <= NUKE_RADIUS)
		{
			int damage = RoundToFloor(NUKE_DAMAGE_PER_TICK * (1.0 - (distance / NUKE_RADIUS) * 0.3));
			DealDamageEntity(entity, client, DMG_BURN | DMG_RADIATION, damage, "nuclear_strike");
			witchesKilled++;
			witchProcessedThisTick++;
		}
	}
	if (witchesKilled > 0)
		NukeLog("  -> Witches dañadas: %d (límite: %d)", witchesKilled, NUKE_MAX_WITCH_KILLS_PER_TICK);

	// Daño a infectados especiales (LIMITADO a N por tick)
	int specialProcessedThisTick = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if (GetClientTeam(i) != 3)
			continue;

		if (IsPlayerGhost(i))
			continue;

		// LÍMITE: Solo procesar X especiales por tick
		if (specialProcessedThisTick >= NUKE_MAX_SPECIAL_KILLS_PER_TICK)
			break;

		float playerOrigin[3];
		GetClientAbsOrigin(i, playerOrigin);
		float distance = GetVectorDistance(nukeOrigin, playerOrigin);

		if (distance <= NUKE_RADIUS)
		{
			int damage = RoundToFloor(NUKE_DAMAGE_PER_TICK * (1.0 - (distance / NUKE_RADIUS) * 0.3));
			NukeLog("  -> Dañando infectado especial: %N (cliente %d) - Daño: %d, Distancia: %.1f", i, i, damage, distance);
			SDKHooks_TakeDamage(i, client, client, float(damage), DMG_BURN | DMG_RADIATION);
			specialsKilled++;
			specialProcessedThisTick++;
		}
	}
	if (specialsKilled > 0)
		NukeLog("  -> Total infectados especiales dañados: %d (límite: %d)", specialsKilled, NUKE_MAX_SPECIAL_KILLS_PER_TICK);
}

/**
 * Helper: Crea una partícula en una posición específica
 */
static void CreateParticleAtPos(const float origin[3], const char[] particleName, float lifetime)
{
	int particle = CreateEntityByName("info_particle_system");
	if (particle == -1)
		return;

	DispatchKeyValue(particle, "effect_name", particleName);
	TeleportEntity(particle, origin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");

	// Auto-destruir
	char destroyTime[16];
	Format(destroyTime, sizeof(destroyTime), "OnUser1 !self:Kill::%.1f:-1", lifetime);
	SetVariantString(destroyTime);
	AcceptEntityInput(particle, "AddOutput");
	AcceptEntityInput(particle, "FireUser1");
}

/**
 * Helper: Crea una partícula adjunta a una entidad
 */
static void CreateParticle(int entity, const char[] particleName, float lifetime)
{
	int particle = CreateEntityByName("info_particle_system");
	if (particle == -1)
		return;

	float origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);

	DispatchKeyValue(particle, "effect_name", particleName);
	TeleportEntity(particle, origin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");

	// Auto-destruir
	char destroyTime[16];
	Format(destroyTime, sizeof(destroyTime), "OnUser1 !self:Kill::%.1f:-1", lifetime);
	SetVariantString(destroyTime);
	AcceptEntityInput(particle, "AddOutput");
	AcceptEntityInput(particle, "FireUser1");
}

/**
 * Helper: Screen shake effect
 */
static void ScreenShake(int client, float amplitude)
{
	Handle hBf = StartMessageOne("Shake", client);
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, 0);
		BfWriteFloat(hBf, amplitude);
		BfWriteFloat(hBf, 3.0);
		BfWriteFloat(hBf, 1.0);
		EndMessage();
	}
}

/**
 * Timer para remover glow de Nuclear Strike
 */
public Action Timer_NukeRemoveGlow(Handle timer, int client)
{
	if (!IsClientInGame(client))
		return Plugin_Stop;

	SetEntProp(client, Prop_Send, "m_iGlowType", 0);
	return Plugin_Stop;
}

/**
 * Verifica si hay algún bombardeo activo
 */
static bool IsAnyBombardmentActive()
{
	// Verificar si hay Nuclear Strike activo
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bNukeActive[i])
			return true;
	}

	// Verificar si hay Ion Cannon activo
	if (IonCannon_IsAnyActive())
		return true;

	return false;
}

/**
 * Resetea el uso de Nuclear Strike al cambiar de mapa
 */
stock void NuclearStrike_OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iNukeUsedThisMap[i] = 0;
		g_bNukeActive[i] = false;
		g_iNukeFlareEntity[i] = 0;
		g_fNukeEndTime[i] = 0.0;
		g_iNukeCountdown[i] = 0;
		g_fNukeExplosionTime[i] = 0.0;
	}
}

/**
 * Limpieza al desconectar cliente
 */
stock void NuclearStrike_OnClientDisconnect(int client)
{
	// Limpiar timers
	if (g_hNukeDamageTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hNukeDamageTimer[client]);
		g_hNukeDamageTimer[client] = INVALID_HANDLE;
	}

	if (g_hNukeEffectsTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hNukeEffectsTimer[client]);
		g_hNukeEffectsTimer[client] = INVALID_HANDLE;
	}

	if (g_hNukeSirenTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hNukeSirenTimer[client]);
		g_hNukeSirenTimer[client] = INVALID_HANDLE;
	}

	// Limpiar bengala
	DestroyNukeFlare(client);

	// Resetear variables
	g_bNukeActive[client] = false;
	g_iNukeUsedThisMap[client] = 0;
	g_fNukeEndTime[client] = 0.0;
	g_iNukeCountdown[client] = 0;
	g_fNukeExplosionTime[client] = 0.0;
}

/**
 * Limpieza de todos los timers de Nuclear Strike al cambiar de mapa
 */
stock void CleanupNuclearStrikeTimers()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_hNukeDamageTimer[i] != INVALID_HANDLE)
		{
			KillTimer(g_hNukeDamageTimer[i]);
			g_hNukeDamageTimer[i] = INVALID_HANDLE;
		}

		if (g_hNukeEffectsTimer[i] != INVALID_HANDLE)
		{
			KillTimer(g_hNukeEffectsTimer[i]);
			g_hNukeEffectsTimer[i] = INVALID_HANDLE;
		}

		if (g_hNukeSirenTimer[i] != INVALID_HANDLE)
		{
			KillTimer(g_hNukeSirenTimer[i]);
			g_hNukeSirenTimer[i] = INVALID_HANDLE;
		}

		DestroyNukeFlare(i);
		g_bNukeActive[i] = false;
		g_iNukeUsedThisMap[i] = 0;
		g_fNukeEndTime[i] = 0.0;
		g_iNukeCountdown[i] = 0;
		g_fNukeExplosionTime[i] = 0.0;
	}
}

/**
 * Obtiene si el jugador ya usó Nuclear Strike este mapa
 */
stock bool NuclearStrike_HasUsedThisMap(int client)
{
	return g_iNukeUsedThisMap[client] > 0;
}

/**
 * Verifica si hay algún Nuclear Strike activo
 * Usado por el sistema de control global de bombardeos
 */
stock bool NuclearStrike_IsAnyActive()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bNukeActive[i])
			return true;
	}
	return false;
}
