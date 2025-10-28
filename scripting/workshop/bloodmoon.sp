/**
 * Bloodmoon Manual for L4D2 (SM 1.11+)
 * ------------------------------------
 * - Solo comandos admin (sin auto/horario).
 * - Left4DHooks REQUERIDO.
 * - Fade ROJO persistente (FFADE_STAYOUT) durante el modo; PURGE al desactivar.
 * - Cambia a EXPERTO al activar y restaura dificultad original al desactivar.
 * - Pack mínimo de ambientación: LightStyle, Fog, Partícula ambiental y Sonidos.
 * - Comandos: on/off/toggle/status/testmob.
 * - Debug por chat configurable.
 *
 * Requisitos: sdktools, sdkhooks, left4dhooks
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.5.0"

public Plugin myinfo =
{
	name		= "Bloodmoon Manual (L4D2) + L4DH + Minimal Atmos Pack",
	author		= "NJO • ChatGPT",
	description = "Bloodmoon manual con fade persistente, experto, light, fog, partículas y sonidos.",
	version		= PLUGIN_VERSION,
	url			= "https://sourcemod.net"
};

// ===== Fade flags =====
#define FFADE_OUT	   0x0001
#define FFADE_IN	   0x0002
#define FFADE_STAYOUT  0x0008
#define FFADE_PURGE	   0x0010

#define TEAM_SURVIVORS 2
#define TEAM_INFECTED  3

// ==============================
// ConVars del plugin
// ==============================
ConVar gCvarEnable;		   // 1 = sistema habilitado
ConVar gCvarDmgMult;	   // multiplicador daño a survivors
ConVar gCvarAnnounce;	   // 1 = mensajes a todos
ConVar gCvarFade;		   // 1 = fade persistente ON
ConVar gCvarChangeDiff;	   // 1 = cambiar a Experto

// Director
ConVar gCvarCommonLimit;
ConVar gCvarMobMin;
ConVar gCvarMobMax;
ConVar gCvarMegaMob;

// Ambientación
ConVar gCvarLightStyle;			  // estilo a aplicar (ej. "b")
ConVar gCvarLightStyleRestore;	  // estilo a restaurar (ej. "m")
ConVar gCvarFogEnable;			  // 1 = crear fog
ConVar gCvarFogColor;			  // "r g b"
ConVar gCvarFogStart;			  // unidades
ConVar gCvarFogEnd;				  // unidades
ConVar gCvarFogDensity;			  // 0.0..1.0
ConVar gCvarParticleName;		  // nombre de partícula (debe existir en el mapa/mod)
ConVar gCvarSoundStart;			  // sonido al activar
ConVar gCvarSoundLoop;			  // sonido loop durante el modo

ConVar gCvarFadeAlpha;		 // 0..255, opacidad del rojo
ConVar gCvarFadeDuration;	 // ms, duración de la transición al activar

ConVar gCvarParticleCount;	  // cantidad de emisores

// Debug
ConVar gCvarDebug;			// debug general
ConVar gCvarDebugDamage;	// debug por golpe

// ConVars del juego
ConVar z_common_limit;
ConVar z_mob_spawn_min_size;
ConVar z_mob_spawn_max_size;
ConVar z_mega_mob_size;
ConVar z_difficulty;

// Forzar aplicacion de fog
Handle gFogTimer = null;	// timer de enforcement del fog
ConVar gCvarFogTick;		// intervalo en segundos del enforcer

// Backups
int	   gOrigCommonLimit = -1;
int	   gOrigMobMin		= -1;
int	   gOrigMobMax		= -1;
int	   gOrigMegaMob		= -1;
char   gOrigDifficulty[16];	   // Easy | Normal | Hard | Impossible

// Estado
bool   gBloodmoonActive = false;
int	   gParticleRefs[16];	 // hasta 16 emisores
int	   gParticleTotal = 0;

// Entidades ambiente
int	   gFogRef		  = -1;	   // entref de env_fog_controller
int	   gParticleRef	  = -1;	   // entref de info_particle_system

// ==============================
// Helpers de chat/debug
// ==============================

void   PrintAnnounce(const char[] fmt, any...)
{
	if (!GetConVarBool(gCvarAnnounce)) return;
	char buffer[256];
	VFormat(buffer, sizeof(buffer), fmt, 2);
	PrintToChatAll("\x04[Bloodmoon]\x01 %s", buffer);
}

void PrintDebugAll(const char[] fmt, any...)
{
	if (!GetConVarBool(gCvarDebug)) return;
	char buffer[256];
	VFormat(buffer, sizeof(buffer), fmt, 2);
	PrintToChatAll("\x05[BM:DBG]\x01 %s", buffer);
}

void PrintDebugCmd(int client, const char[] fmt, any...)
{
	char buffer[256];
	VFormat(buffer, sizeof(buffer), fmt, 3);
	if (client > 0 && IsClientInGame(client))
		PrintToChat(client, "\x05[BM:CMD]\x01 %s", buffer);
	if (GetConVarBool(gCvarDebug))
	{
		for (int i = 1; i <= MaxClients; i++)
			if (i != client && IsClientInGame(i))
				PrintToChat(i, "\x05[BM:CMD]\x01 %s", buffer);
	}
}

// ==============================
// Fade persistente
// ==============================
void DoScreenFadeAll(bool activate)
{
	if (!GetConVarBool(gCvarFade)) return;

	int	   r = 120, g = 0, b = 0;
	int	   alpha	= gCvarFadeAlpha.IntValue;		 // p. ej., 120
	int	   duration = gCvarFadeDuration.IntValue;	 // p. ej., 1500 ms
	int	   hold		= 0;

	// Limpia cualquier fade previo para evitar estados raros
	Handle hPurge	= StartMessageAll("Fade");
	if (hPurge != null)
	{
		BfWriteShort(hPurge, 0);
		BfWriteShort(hPurge, 0);
		BfWriteShort(hPurge, FFADE_PURGE);
		BfWriteByte(hPurge, 0);
		BfWriteByte(hPurge, 0);
		BfWriteByte(hPurge, 0);
		BfWriteByte(hPurge, 0);
		EndMessage();
	}

	// Activar => transparente -> rojo y SE QUEDA (STAYOUT)
	// Desactivar => rojo -> transparente (fade out, sin STAYOUT)
	int	   flags = activate ? (FFADE_IN | FFADE_STAYOUT) : FFADE_OUT;

	Handle hFade = StartMessageAll("Fade");
	if (hFade != null)
	{
		BfWriteShort(hFade, duration);
		BfWriteShort(hFade, hold);
		BfWriteShort(hFade, flags);
		BfWriteByte(hFade, r);
		BfWriteByte(hFade, g);
		BfWriteByte(hFade, b);
		BfWriteByte(hFade, alpha);
		EndMessage();
	}

	// (Opcional) garantizar limpieza total tras el fade de salida
	if (!activate)
	{
		CreateTimer(float(duration) / 1000.0 + 0.05, Timer_PurgeFadeOnce);
	}

	PrintDebugAll("Fade %s (flags=0x%X, dur=%d, rgba=%d,%d,%d,%d).",
				  activate ? "IN+STAYOUT (transp->rojo)" : "OUT (rojo->transp)",
				  flags, duration, r, g, b, alpha);
}

public Action Timer_PurgeFadeOnce(Handle t, any data)
{
	Handle h = StartMessageAll("Fade");
	if (h != null)
	{
		BfWriteShort(h, 0);
		BfWriteShort(h, 0);
		BfWriteShort(h, FFADE_PURGE);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		EndMessage();
	}
	return Plugin_Stop;
}

// ==============================
// LightStyle
// ==============================
void ApplyLightStyle()
{
	char ls[8];
	gCvarLightStyle.GetString(ls, sizeof ls);
	if (ls[0])
	{
		SetLightStyle(0, ls);
		PrintDebugAll("LightStyle aplicado: '%s'.", ls);
	}
}

void RestoreLightStyle()
{
	char ls[8];
	gCvarLightStyleRestore.GetString(ls, sizeof ls);
	if (ls[0])
	{
		SetLightStyle(0, ls);
		PrintDebugAll("LightStyle restaurado: '%s'.", ls);
	}
}

// ==============================
// Fog controller
// ==============================
int SpawnFogController()
{
	int ent = CreateEntityByName("env_fog_controller");
	if (ent == -1) return -1;

	char color[32];
	gCvarFogColor.GetString(color, sizeof color);
	char density[16];
	gCvarFogDensity.GetString(density, sizeof density);
	char sStart[16];
	IntToString(gCvarFogStart.IntValue, sStart, sizeof sStart);
	char sEnd[16];
	IntToString(gCvarFogEnd.IntValue, sEnd, sizeof sEnd);

	DispatchKeyValue(ent, "fogcolor", color);
	DispatchKeyValue(ent, "fogstart", sStart);
	DispatchKeyValue(ent, "fogend", sEnd);
	DispatchKeyValue(ent, "fogmaxdensity", density);
	DispatchKeyValue(ent, "fogenable", "1");
	DispatchSpawn(ent);
	AcceptEntityInput(ent, "TurnOn");

	PrintDebugAll("Fog creado (color='%s', start=%s, end=%s, density=%s).", color, sStart, sEnd, density);
	return ent;
}

void RemoveFogController()
{
	int ent = EntRefToEntIndex(gFogRef);
	if (ent != -1 && IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "TurnOff");
		RemoveEntity(ent);
		PrintDebugAll("Fog removido.");
	}
	gFogRef = -1;
}

// ==============================
// Partícula ambiental (info_particle_system)
// ==============================
int SpawnAmbientParticle()
{
	char pname[64];
	gCvarParticleName.GetString(pname, sizeof pname);
	if (!pname[0]) return -1;

	// Precarga “suave”: si no existe, no falla el plugin, solo se loguea.
	bool ok = view_as<bool>(PrecacheGeneric(pname, true));
	PrintDebugAll("Intento precache partícula '%s' (ok=%d).", pname, ok);

	int ent = CreateEntityByName("info_particle_system");
	if (ent == -1) return -1;

	DispatchKeyValue(ent, "effect_name", pname);
	DispatchKeyValue(ent, "start_active", "1");
	// Lo dejamos en el origen del mapa; muchos efectos son globales.
	float pos[3] = { 0.0, 0.0, 64.0 };
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent);
	ActivateEntity(ent);
	AcceptEntityInput(ent, "Start");

	PrintDebugAll("Partícula ambiental creada '%s' (ent=%d).", pname, ent);
	return ent;
}

void RemoveAmbientParticle()
{
	int ent = EntRefToEntIndex(gParticleRef);
	if (ent != -1 && IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "Stop");
		RemoveEntity(ent);
		PrintDebugAll("Partícula ambiental removida.");
	}
	gParticleRef = -1;
}

// ==============================
// Sonidos
// ==============================
void PrecacheSoundIfSet(const char[] sample)
{
	if (sample[0])
		PrecacheSound(sample, true);
}

void PlaySoundToAll(const char[] sample)
{
	if (!sample[0]) return;
	PrecacheSoundIfSet(sample);
	// canal estático para minimizar conflictos
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			EmitSoundToClient(i, sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN, _, 1.0);
	PrintDebugAll("Reproduciendo sonido: '%s'.", sample);
}

void StopSoundToAll(const char[] sample)
{
	if (!sample[0]) return;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			StopSound(i, SNDCHAN_STATIC, sample);
	PrintDebugAll("Sonido detenido: '%s'.", sample);
}

// ==============================
// Director (backup/apply/restore)
// ==============================
void CacheOriginalDirector()
{
	if (gOrigCommonLimit == -1 && z_common_limit != null)
		gOrigCommonLimit = z_common_limit.IntValue;
	if (gOrigMobMin == -1 && z_mob_spawn_min_size != null)
		gOrigMobMin = z_mob_spawn_min_size.IntValue;
	if (gOrigMobMax == -1 && z_mob_spawn_max_size != null)
		gOrigMobMax = z_mob_spawn_max_size.IntValue;
	if (gOrigMegaMob == -1 && z_mega_mob_size != null)
		gOrigMegaMob = z_mega_mob_size.IntValue;

	if (gOrigDifficulty[0] == '\0' && z_difficulty != null)
		GetConVarString(z_difficulty, gOrigDifficulty, sizeof gOrigDifficulty);

	PrintDebugAll("Backup director -> common=%d, mobMin=%d, mobMax=%d, mega=%d, diff='%s'",
				  gOrigCommonLimit, gOrigMobMin, gOrigMobMax, gOrigMegaMob,
				  gOrigDifficulty[0] ? gOrigDifficulty : "n/a");
}

void ApplyDirector()
{
	int cl = gCvarCommonLimit.IntValue;
	int mn = gCvarMobMin.IntValue;
	int mx = gCvarMobMax.IntValue;
	int mg = gCvarMegaMob.IntValue;

	if (z_common_limit) z_common_limit.IntValue = cl;
	if (z_mob_spawn_min_size) z_mob_spawn_min_size.IntValue = mn;
	if (z_mob_spawn_max_size) z_mob_spawn_max_size.IntValue = mx;
	if (z_mega_mob_size) z_mega_mob_size.IntValue = mg;

	PrintDebugAll("Apply director -> common=%d, mobMin=%d, mobMax=%d, mega=%d",
				  cl, mn, mx, mg);
}

void RestoreDirector()
{
	if (z_common_limit && gOrigCommonLimit != -1) z_common_limit.IntValue = gOrigCommonLimit;
	if (z_mob_spawn_min_size && gOrigMobMin != -1) z_mob_spawn_min_size.IntValue = gOrigMobMin;
	if (z_mob_spawn_max_size && gOrigMobMax != -1) z_mob_spawn_max_size.IntValue = gOrigMobMax;
	if (z_mega_mob_size && gOrigMegaMob != -1) z_mega_mob_size.IntValue = gOrigMegaMob;

	PrintDebugAll("Restore director -> common=%d, mobMin=%d, mobMax=%d, mega=%d",
				  gOrigCommonLimit, gOrigMobMin, gOrigMobMax, gOrigMegaMob);
}

// ==============================
// Activar / Desactivar (comandos)
// ==============================
void ActivateBloodmoon(const char[] reason)
{
	if (gBloodmoonActive) return;

	CacheOriginalDirector();
	ApplyDirector();

	gBloodmoonActive = true;

	// Ambientación
	ApplyLightStyle();

	if (gCvarFogEnable.BoolValue)
	{
		int ent = SpawnFogController();
		gFogRef = (ent != -1) ? EntIndexToEntRef(ent) : -1;
		// Enforcer ON
		StartFogEnforcerTimer();
	}

	// crear múltiples partículas ambientales
	CreateAmbientParticles();

	char sStart[128], sLoop[128];
	gCvarSoundStart.GetString(sStart, sizeof sStart);
	gCvarSoundLoop.GetString(sLoop, sizeof sLoop);
	if (sStart[0]) PlaySoundToAll(sStart);
	if (sLoop[0]) PlaySoundToAll(sLoop);

	// Feedback / cambios de juego
	DoScreenFadeAll(true);
	PrintAnnounce("¡Luna de Sangre ACTIVADA! (%s) Hordas y daño incrementados. (mult=%.2f)",
				  reason, gCvarDmgMult.FloatValue);

	if (gCvarChangeDiff.BoolValue)
	{
		ServerCommand("z_difficulty Impossible");
		PrintDebugAll("Dificultad cambiada a EXPERTO (Impossible).");
	}
}

void DeactivateBloodmoon(const char[] reason)
{
	if (!gBloodmoonActive) return;

	RestoreDirector();
	gBloodmoonActive = false;

	// Limpieza de ambientación
	RemoveAmbientParticles();
	// Enforcer OFF
	StopFogEnforcerTimer();
	RemoveFogController();
	RestoreLightStyle();

	char sLoop[128];
	gCvarSoundLoop.GetString(sLoop, sizeof sLoop);
	if (sLoop[0]) StopSoundToAll(sLoop);

	if (gCvarChangeDiff.BoolValue && gOrigDifficulty[0] != '\0')
	{
		ServerCommand("z_difficulty %s", gOrigDifficulty);
		PrintDebugAll("Dificultad restaurada a '%s'.", gOrigDifficulty);
	}

	DoScreenFadeAll(false);
	PrintAnnounce("Luna de Sangre DESACTIVADA. (%s) Director/dificultad restaurados.", reason);
}

// ==============================
// Hooks / Lifecycle
// ==============================
public void OnPluginStart()
{
	// ConVars
	gCvarEnable			   = CreateConVar("sm_bloodmoon_enable", "1", "Habilita el sistema (0/1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gCvarDmgMult		   = CreateConVar("sm_bloodmoon_damage_mult", "1.35", "Multiplicador de daño a Survivors", FCVAR_NOTIFY, true, 1.00, true, 5.00);
	gCvarAnnounce		   = CreateConVar("sm_bloodmoon_announce", "1", "Anunciar en chat (0/1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gCvarFade			   = CreateConVar("sm_bloodmoon_fade", "1", "Fade ROJO persistente durante Bloodmoon (0/1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gCvarChangeDiff		   = CreateConVar("sm_bloodmoon_change_difficulty", "1", "Cambiar a EXPERTO al activar y restaurar al desactivar (0/1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	gCvarCommonLimit	   = CreateConVar("sm_bloodmoon_common_limit", "45", "z_common_limit durante Bloodmoon", FCVAR_NOTIFY, true, 10.0, true, 100.0);
	gCvarMobMin			   = CreateConVar("sm_bloodmoon_mob_min", "25", "z_mob_spawn_min_size durante Bloodmoon", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	gCvarMobMax			   = CreateConVar("sm_bloodmoon_mob_max", "35", "z_mob_spawn_max_size durante Bloodmoon", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	gCvarMegaMob		   = CreateConVar("sm_bloodmoon_mega_mob", "60", "z_mega_mob_size durante Bloodmoon", FCVAR_NOTIFY, true, 0.0, true, 150.0);

	gCvarLightStyle		   = CreateConVar("sm_bloodmoon_lightstyle", "b", "LightStyle a aplicar durante Bloodmoon (string)", FCVAR_NOTIFY);
	gCvarLightStyleRestore = CreateConVar("sm_bloodmoon_lightstyle_restore", "m", "LightStyle a restaurar al desactivar (string)", FCVAR_NOTIFY);

	gCvarFogEnable		   = CreateConVar("sm_bloodmoon_fog_enable", "1", "Crear Fog durante Bloodmoon (0/1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gCvarFogColor		   = CreateConVar("sm_bloodmoon_fog_color", "200 40 40", "Color Fog 'r g b'", FCVAR_NOTIFY);
	gCvarFogStart		   = CreateConVar("sm_bloodmoon_fog_start", "50", "Fog start distance", FCVAR_NOTIFY);
	gCvarFogEnd			   = CreateConVar("sm_bloodmoon_fog_end", "1200", "Fog end distance", FCVAR_NOTIFY);
	gCvarFogDensity		   = CreateConVar("sm_bloodmoon_fog_density", "0.7", "Fog max density 0..1", FCVAR_NOTIFY);

	gCvarParticleName	   = CreateConVar("sm_bloodmoon_particle", "env_ash", "Nombre de partícula ambiental (vacío=off). Debe existir en el mapa/mod.", FCVAR_NOTIFY);
	gCvarParticleCount	   = CreateConVar("sm_bloodmoon_particle_count", "3", "Cantidad de emisores de la partícula ambiental", FCVAR_NOTIFY, true, 0.0, true, 16.0);

	gCvarSoundStart		   = CreateConVar("sm_bloodmoon_sound_start", "", "Sonido al activar (vacío=off). Ej: ambient/atmosphere/cave_hit5.wav", FCVAR_NOTIFY);
	gCvarSoundLoop		   = CreateConVar("sm_bloodmoon_sound_loop", "", "Sonido loop durante el modo (vacío=off).", FCVAR_NOTIFY);

	gCvarDebug			   = CreateConVar("sm_bloodmoon_debug", "1", "Debug general por chat (0/1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gCvarDebugDamage	   = CreateConVar("sm_bloodmoon_debug_damage", "0", "Debug por cada impacto (0/1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	gCvarFade			   = CreateConVar("sm_bloodmoon_fade", "1", "Fade ROJO persistente durante Bloodmoon (0/1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gCvarFadeAlpha		   = CreateConVar("sm_bloodmoon_fade_alpha", "120", "Alpha del overlay rojo 0..255", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	gCvarFadeDuration	   = CreateConVar("sm_bloodmoon_fade_duration", "1500", "Duración ms de transición al activar", FCVAR_NOTIFY, true, 0.0, true, 10000.0);

	/* partícula por defecto -> nativa */
	gCvarParticleName	   = CreateConVar("sm_bloodmoon_particle", "env_snow_128", "Partícula ambiental (vacío=off).", FCVAR_NOTIFY);
	gCvarFogTick		   = CreateConVar("sm_bloodmoon_fog_tick", "3.0",
										  "Intervalo (s) para re-aplicar el fog y recrearlo si falta", FCVAR_NOTIFY, true, 1.0, true, 60.0);

	// ConVars del juego
	z_common_limit		   = FindConVar("z_common_limit");
	z_mob_spawn_min_size   = FindConVar("z_mob_spawn_min_size");
	z_mob_spawn_max_size   = FindConVar("z_mob_spawn_max_size");
	z_mega_mob_size		   = FindConVar("z_mega_mob_size");
	z_difficulty		   = FindConVar("z_difficulty");

	// Hooks de daño
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);

	HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);

	// Comandos admin
	RegAdminCmd("sm_bloodmoon_on", Cmd_BloodmoonOn, ADMFLAG_GENERIC, "Activa Bloodmoon.");
	RegAdminCmd("sm_bloodmoon_off", Cmd_BloodmoonOff, ADMFLAG_GENERIC, "Desactiva Bloodmoon.");
	RegAdminCmd("sm_bloodmoon_toggle", Cmd_BloodmoonToggle, ADMFLAG_GENERIC, "Alterna Bloodmoon.");
	RegAdminCmd("sm_bloodmoon_status", Cmd_BloodmoonStatus, ADMFLAG_GENERIC, "Estado Bloodmoon.");
	RegAdminCmd("sm_bloodmoon_testmob", Cmd_BloodmoonTestMob, ADMFLAG_GENERIC, "Fuerza una horda (z_spawn mob).");

	CreateConVar("sm_bloodmoon_version", PLUGIN_VERSION, "Bloodmoon version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	gOrigDifficulty[0] = '\0';
	gFogRef = gParticleRef = -1;

	PrintToServer("[Bloodmoon] v%s cargado (L4DH req.).", PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	if (gBloodmoonActive)
	{
		RestoreDirector();
		if (gCvarChangeDiff.BoolValue && gOrigDifficulty[0] != '\0')
			ServerCommand("z_difficulty %s", gOrigDifficulty);
		DoScreenFadeAll(false);
		RemoveAmbientParticle();
		RemoveFogController();
		RestoreLightStyle();
		StopFogEnforcerTimer();
	}
}

public void OnMapStart()
{
	gOrigCommonLimit = gOrigMobMin = gOrigMobMax = gOrigMegaMob = -1;
	// No forzamos reset de dificultad backup.
}

// Hook de daño
public void OnClientPutInServer(int client) { SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage); }

public void OnClientDisconnect(int client) { SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage); }

public Action Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	if (gBloodmoonActive)
	{
		RestoreDirector();
		if (gCvarChangeDiff.BoolValue && gOrigDifficulty[0] != '\0')
			ServerCommand("z_difficulty %s", gOrigDifficulty);
		DoScreenFadeAll(false);
		RemoveAmbientParticle();
		RemoveFogController();
		RestoreLightStyle();
		StopFogEnforcerTimer();
		PrintDebugAll("MapTransition: ambiente/director/dificultad restaurados.");
	}
	return Plugin_Continue;
}

// ==============================
// Daño a Survivors: multiplicador + debug
// ==============================
public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!gBloodmoonActive) return Plugin_Continue;
	if (!IsValidClient(victim) || GetClientTeam(victim) != TEAM_SURVIVORS) return Plugin_Continue;

	float mult = gCvarDmgMult.FloatValue;
	if (mult <= 1.0) return Plugin_Continue;

	bool fromSpecial = (IsValidClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED);
	bool fromCommon	 = false;
	char aCls[32];
	aCls[0] = '\0';
	char iCls[32];
	iCls[0] = '\0';

	if (!fromSpecial)
	{
		if (IsValidEdict(attacker) && attacker > MaxClients)
		{
			GetEdictClassname(attacker, aCls, sizeof(aCls));
			if (StrEqual(aCls, "infected", false)) fromCommon = true;
		}
		else if (IsValidEdict(inflictor) && inflictor > MaxClients)
		{
			GetEdictClassname(inflictor, iCls, sizeof(iCls));
			if (StrEqual(iCls, "infected", false)) fromCommon = true;
		}
	}

	if (fromSpecial || fromCommon)
	{
		float orig = damage;
		damage *= mult;

		if (gCvarDebugDamage.BoolValue)
		{
			char vName[64];
			vName[0] = '\0';
			if (IsValidClient(victim)) GetClientName(victim, vName, sizeof(vName));
			if (fromSpecial)
			{
				char aName[64];
				aName[0] = '\0';
				if (IsValidClient(attacker)) GetClientName(attacker, aName, sizeof(aName));
				PrintToChatAll("\x05[BM:DMG]\x01 %s %.1f -> %.1f por ESPECIAL (%s) (mult=%.2f).",
							   (vName[0] ? vName : "Victim"), orig, damage, (aName[0] ? aName : "unknown"), mult);
			}
			else
			{
				PrintToChatAll("\x05[BM:DMG]\x01 %s %.1f -> %.1f por COMÚN (att=%s inf=%s) (mult=%.2f).",
							   (vName[0] ? vName : "Victim"), orig, damage,
							   (aCls[0] ? aCls : "n/a"), (iCls[0] ? iCls : "n/a"), mult);
			}
		}
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

// ==============================
// Comandos admin
// ==============================
public Action Cmd_BloodmoonOn(int client, int args)
{
	if (!gCvarEnable.BoolValue)
	{
		ReplyToCommand(client, "[Bloodmoon] sm_bloodmoon_enable=0.");
		return Plugin_Handled;
	}
	ActivateBloodmoon("comando admin");
	ReplyToCommand(client, "[Bloodmoon] ACTIVADO.");
	PrintDebugCmd(client, "ON (mult=%.2f, expert=%d).", gCvarDmgMult.FloatValue, gCvarChangeDiff.BoolValue);
	return Plugin_Handled;
}

public Action Cmd_BloodmoonOff(int client, int args)
{
	DeactivateBloodmoon("comando admin");
	ReplyToCommand(client, "[Bloodmoon] DESACTIVADO.");
	PrintDebugCmd(client, "OFF.");
	return Plugin_Handled;
}

public Action Cmd_BloodmoonToggle(int client, int args)
{
	if (gBloodmoonActive)
	{
		PrintDebugCmd(client, "TOGGLE -> OFF");
		return Cmd_BloodmoonOff(client, args);
	}
	PrintDebugCmd(client, "TOGGLE -> ON");
	return Cmd_BloodmoonOn(client, args);
}

public Action Cmd_BloodmoonStatus(int client, int args)
{
	char diff[16];
	if (z_difficulty) z_difficulty.GetString(diff, sizeof diff);

	ReplyToCommand(client,
				   "[Bloodmoon] active=%d | dmg_mult=%.2f | z_common_limit=%d | mob=(%d-%d; mega=%d) | diff='%s'",
				   gBloodmoonActive, gCvarDmgMult.FloatValue,
				   z_common_limit ? z_common_limit.IntValue : -1,
				   z_mob_spawn_min_size ? z_mob_spawn_min_size.IntValue : -1,
				   z_mob_spawn_max_size ? z_mob_spawn_max_size.IntValue : -1,
				   z_mega_mob_size ? z_mega_mob_size.IntValue : -1,
				   diff[0] ? diff : "n/a");

	return Plugin_Handled;
}

public Action Cmd_BloodmoonTestMob(int client, int args)
{
	// Lanza una horda (servidor): en muchos servers funciona "z_spawn mob"
	ServerCommand("z_spawn mob");
	ReplyToCommand(client, "[Bloodmoon] z_spawn mob enviado.");
	return Plugin_Handled;
}
void CreateAmbientParticles()
{
	gParticleTotal = 0;
	char pname[64];
	gCvarParticleName.GetString(pname, sizeof pname);
	if (!pname[0]) return;

	int count = gCvarParticleCount.IntValue;
	if (count < 1) return;
	if (count > 16) count = 16;

	// Precarga “suave”
	PrecacheGeneric(pname, true);

	// Distribuye emisores cerca del origen con ligeros offsets
	for (int i = 0; i < count; i++)
	{
		int ent = CreateEntityByName("info_particle_system");
		if (ent == -1) continue;

		DispatchKeyValue(ent, "effect_name", pname);
		DispatchKeyValue(ent, "start_active", "1");

		float pos[3];
		pos[0] = float(i * 64);
		pos[1] = float((i % 3) * 96);
		pos[2] = 72.0;
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "Start");

		gParticleRefs[gParticleTotal++] = EntIndexToEntRef(ent);
	}
	PrintDebugAll("Partículas '%s' creadas: %d emisores.", pname, gParticleTotal);
}

void RemoveAmbientParticles()
{
	for (int i = 0; i < gParticleTotal; i++)
	{
		int ent = EntRefToEntIndex(gParticleRefs[i]);
		if (ent != -1 && IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "Stop");
			RemoveEntity(ent);
		}
	}
	gParticleTotal = 0;
	PrintDebugAll("Partículas ambientales removidas.");
}

// ==============================
// Utils
// ==============================
bool IsValidClient(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client));
}
// Aplica los CVARs actuales al fog dado (color/start/end/density + TurnOn)
void ApplyFogSettingsToEnt(int ent)
{
	if (ent == -1 || !IsValidEntity(ent)) return;

	char color[32];
	gCvarFogColor.GetString(color, sizeof color);
	SetVariantString(color);
	AcceptEntityInput(ent, "SetColor");

	int	  s = gCvarFogStart.IntValue;
	int	  e = gCvarFogEnd.IntValue;
	float d = gCvarFogDensity.FloatValue;

	SetVariantInt(s);
	AcceptEntityInput(ent, "SetStartDist");

	SetVariantInt(e);
	AcceptEntityInput(ent, "SetEndDist");

	SetVariantFloat(d);
	AcceptEntityInput(ent, "SetMaxDensity");

	AcceptEntityInput(ent, "TurnOn");
}

// Crea (o reusa) el fog controller y aplica CVARs
int EnsureFogController()
{
	int ent = EntRefToEntIndex(gFogRef);
	if (ent == -1 || !IsValidEntity(ent))
	{
		ent		= SpawnFogController();
		gFogRef = (ent != -1) ? EntIndexToEntRef(ent) : -1;
	}
	if (ent != -1 && IsValidEntity(ent))
	{
		ApplyFogSettingsToEnt(ent);
	}
	return ent;
}

public Action Timer_FogEnforcer(Handle timer, any data)
{
	// Si el modo está apagado o el fog está deshabilitado por CVAR, no hagas nada
	if (!gBloodmoonActive || !gCvarFogEnable.BoolValue)
		return Plugin_Continue;

	int ent = EnsureFogController();
	if (ent != -1)
	{
		// Reaplica por si alguien tocó valores entre ticks
		ApplyFogSettingsToEnt(ent);
		PrintDebugAll("Fog enforcer: aplicado/asegurado (ent=%d).", ent);
	}
	else
	{
		PrintDebugAll("Fog enforcer: no se pudo crear/asegurar fog.");
	}
	return Plugin_Continue;
}

void StartFogEnforcerTimer()
{
	if (gFogTimer == null)
	{
		float tick = gCvarFogTick.FloatValue;
		if (tick < 1.0) tick = 1.0;
		gFogTimer = CreateTimer(tick, Timer_FogEnforcer, _, TIMER_REPEAT);
		PrintDebugAll("Fog enforcer iniciado (tick=%.2fs).", tick);
	}
}

void StopFogEnforcerTimer()
{
	if (gFogTimer != null)
	{
		KillTimer(gFogTimer);
		gFogTimer = null;
		PrintDebugAll("Fog enforcer detenido.");
	}
}
