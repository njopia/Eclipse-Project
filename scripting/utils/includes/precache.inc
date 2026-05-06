/**
 * modules/utils/precache.inc
 * Módulo de Precache para EMS (single-plugin).
 *
 * - Mantiene listas internas (editables aquí) de Sonidos, Partículas, Modelos,
 *   Genéricos y archivos a Descargar.
 * - API para el MAIN:
 *      EMS_Precache_Init();
 *      EMS_Precache_SetDebug(bool enable);
 *      EMS_Precache_OnMapStart();
 *      EMS_Precache_DoAll();
 *      EMS_Precache_ClearAll();
 *      (Opcional) EMS_Precache_AddSound/Particle/Model/Generic/Download
 *
 * - Precaching de partículas con string tables (compatible con todas las versiones).
 */

#if defined _EMS_PRECACHE_MODULE_
	#endinput
#endif
#define _EMS_PRECACHE_MODULE_

// ---------- Includes requeridos ----------
#if !defined _sourcemod_included
	#include <sourcemod>
#endif
#if !defined _sdktools_included
	#include <sdktools>
#endif
#if !defined _sdktools_stringtables_included
	#include <sdktools_stringtables>
#endif

// ======================================================================
// --------------------------- CONFIG INTERNA ----------------------------
// ======================================================================

// Flag local de debug (controla EMS_DLog). Arranca en false.
static bool		  g_bEMSPrecacheDebug = true;

// Sonidos por defecto (rutas relativas al directorio "sound/")
static const char g_DefaultSounds[][] = {
	"weapons/upgrade/explosive_ammo_pickup.wav",
	"weapons/upgrade/incendiary_ammo_pickup.wav",
	"player/survivor/voice/mechanic/taunt02.wav",
	"player/survivor/voice/gambler/battlecry04.wav",
	"player/survivor/voice/gambler/battlecry01.wav",
	"player/survivor/voice/gambler/battlecry02.wav",
	"weapons/grenade_launcher/grenade_launcher_explode.wav",
	"weapons/grenade_launcher/grenade_launcher_reload.wav",
	"vehicles/airboat/fan_blade_fullthrottle_loop1.wav",
	"ambient/energy/zap5.wav",
	"ambient/energy/zap6.wav",
	"ambient/energy/zap7.wav",
	"ambient/energy/zap8.wav",
	"ambient/energy/zap9.wav",
	// Nuclear Strike sounds
	"ambient/fire/fire_small_loop2.wav",
	"ambient/levels/caves/rumble3.wav",
	"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav",
	"ambient/alarms/klaxon1.wav",
	"ambient/wind/wind_hit1.wav",
	// Sonido de shoulderCannon
	"weapons/machinegun_m60/gunfire/machinegun_fire_1.wav"
	// agrega más si quieres…
};

// Partículas por defecto (nombres de sistema – no rutas .pcf)
static const char g_DefaultParticles[][] = {
	"inferno_grow",
	"electrical_arc_01_system",
	"weapon_pipebomb_child_sparks2",
	"weapon_pipebomb_child_sparks3",
	"apc_wheel_smoke1",
	"aircraft_destroy_fastFireTrail",
	"spitter_areaofdenial_glow2",
	"spitter_projectile",
	"electrical_arc_01_parent",
	"boomer_explode_D",
	"boomer_explode",
	"smoke_medium_01",
	"blood_impact_red_01",
	"weapon_tracers_50cal",
	"weapon_muzzle_flash_assaultrifle",
	"weapon_muzzle_flash_autoshotgun",
	"storm_lightning_01_thin",
	"sparks_generic_random",
	"weapon_pipebomb_child_firesmoke",
	"impact_explosive_ammo_large",
	"flare_burning",
	"smoke_campfire",
	// Nuclear Strike particles
	"gen_hit_up",
	"gas_explosion_ground_wave",
	"gas_explosion_firesmoke",
	"gen_hit1_edynamicBillow",
	"gas_explosion_debris_parents",
	"gen_hit1_b",
	"gas_fireball",
	"gas_explosion_fireball",
	"gas_explosion_fireball2",
	"explosion_huge",
	"fire_large_01",
	"smoke_large_01",
	"fire_small_smoke",
	// agrega más si quieres…
};

// Modelos por defecto
static const char g_DefaultModels[][] = {
	"models/props_unique/spawn_apartment/coffeeammo.mdl",
	// Nuclear Strike model
	"models/props_lighting/light_flares.mdl"
	// agrega más si quieres…
};

// Si no tienes genéricos o downloads aún, define arrays “placeholder” de 1 elemento
// para que sizeof(...) sea válido en compilación.
static const char g_DefaultGenericFiles[][PLATFORM_MAX_PATH] = {
	""	  // placeholder (evita “indeterminate array size in sizeof”)
};
static const char g_DefaultDownloads[][PLATFORM_MAX_PATH] = {
	""	  // placeholder
};

// ======================================================================
// ------------------------------ ESTADO --------------------------------
// ======================================================================

static ArrayList g_Sounds	 = null;
static ArrayList g_Particles = null;
static ArrayList g_Models	 = null;
static ArrayList g_Generic	 = null;
static ArrayList g_Downloads = null;

// ======================================================================
// ------------------------------ LOGGING -------------------------------
// ======================================================================

static void		 EMS_DLog(const char[] fmt, any...)
{
	if (!g_bEMSPrecacheDebug) return;
	char msg[256];
	VFormat(msg, sizeof msg, fmt, 2);
	LogMessage("[EMS-PC] %s", msg);
}
/* static void EMS_ELog(const char[] fmt, any ...)
{
	char msg[256]; VFormat(msg, sizeof msg, fmt, 2);
	LogError("[EMS-PC] %s", msg);
}
 */
// Cambiar debug en runtime (desde el MAIN)
stock void EMS_Precache_SetDebug(bool enable)
{
	g_bEMSPrecacheDebug = enable;
	EMS_DLog("Debug %s", enable ? "ON" : "OFF");
}

// ======================================================================
//  Fallback universal de partículas (string tables) — compatible con SM
// ======================================================================

stock bool EMS_PrecacheParticleSystem(const char[] name)
{
	int tbl = FindStringTable("ParticleEffectNames");
	if (tbl == INVALID_STRING_TABLE)
		return false;

	if (FindStringIndex(tbl, name) != INVALID_STRING_INDEX)
		return true;	// ya estaba

	bool wasLocked = LockStringTables(false);
	AddToStringTable(tbl, name);	// puede retornar void según headers
	LockStringTables(wasLocked);

	return (FindStringIndex(tbl, name) != INVALID_STRING_INDEX);
}

stock int EMS_GetParticleSystemIndex(const char[] name)
{
	int tbl = FindStringTable("ParticleEffectNames");
	if (tbl == INVALID_STRING_TABLE)
		return -1;

	return FindStringIndex(tbl, name);	  // -1 si no existe
}

// ======================================================================
// ------------------------------- API ----------------------------------
// ======================================================================

/** Inicializa estructuras y siembra listas por defecto de este include. */
stock void EMS_Precache_Init()
{
	if (g_Sounds == null) g_Sounds = new ArrayList(PLATFORM_MAX_PATH);
	if (g_Particles == null) g_Particles = new ArrayList(128);
	if (g_Models == null) g_Models = new ArrayList(PLATFORM_MAX_PATH);
	if (g_Generic == null) g_Generic = new ArrayList(PLATFORM_MAX_PATH);
	if (g_Downloads == null) g_Downloads = new ArrayList(PLATFORM_MAX_PATH);

	if (g_Sounds.Length == 0)
		for (int i = 0; i < sizeof(g_DefaultSounds); i++)
			if (g_DefaultSounds[i][0]) g_Sounds.PushString(g_DefaultSounds[i]);

	if (g_Particles.Length == 0)
		for (int i = 0; i < sizeof(g_DefaultParticles); i++)
			if (g_DefaultParticles[i][0]) g_Particles.PushString(g_DefaultParticles[i]);

	if (g_Models.Length == 0)
		for (int i = 0; i < sizeof(g_DefaultModels); i++)
			if (g_DefaultModels[i][0]) g_Models.PushString(g_DefaultModels[i]);

	if (g_Generic.Length == 0)
		for (int i = 0; i < sizeof(g_DefaultGenericFiles); i++)
			if (g_DefaultGenericFiles[i][0]) g_Generic.PushString(g_DefaultGenericFiles[i]);

	if (g_Downloads.Length == 0)
		for (int i = 0; i < sizeof(g_DefaultDownloads); i++)
			if (g_DefaultDownloads[i][0]) g_Downloads.PushString(g_DefaultDownloads[i]);

	EMS_DLog("---[ Módulo Precache EMS Inicializado ]---");
	EMS_DLog("Listas por defecto cargadas: S=%d P=%d M=%d G=%d D=%d",
			 g_Sounds.Length, g_Particles.Length, g_Models.Length, g_Generic.Length, g_Downloads.Length);
}

/** Llama esto desde OnMapStart del MAIN (o donde prefieras). */
stock void EMS_Precache_OnMapStart()
{
	EMS_Precache_DoAll();
}

/** Ejecuta todo el precache (imprime resumen con OK/FAIL). */
stock void EMS_Precache_DoAll()
{
	int okS, failS, okM, failM, okP, failP, okG, failG, cntD;

	cntD = EMS_AddDownloads_();
	EMS_PrecacheGeneric_(okG, failG);
	EMS_PrecacheModels_(okM, failM);
	EMS_PrecacheSounds_(okS, failS);
	EMS_PrecacheParticles_(okP, failP);

	EMS_DLog("=== PRECACHE SUMMARY ===");
	EMS_DLog("  Sounds:   OK=%d  FAIL=%d  (Total=%d)", okS, failS, okS + failS);
	EMS_DLog("  Models:   OK=%d  FAIL=%d  (Total=%d)", okM, failM, okM + failM);
	EMS_DLog("  Particles:OK=%d  FAIL=%d  (Total=%d)", okP, failP, okP + failP);
	EMS_DLog("  Generic:  OK=%d  FAIL=%d  (Total=%d)", okG, failG, okG + failG);
	EMS_DLog("  Downloads added: %d", cntD);
	EMS_DLog("=========================");
}

/** Limpia todas las listas (por si quieres rearmarlas en runtime). */
stock void EMS_Precache_ClearAll()
{
	if (g_Sounds != null) g_Sounds.Clear();
	if (g_Particles != null) g_Particles.Clear();
	if (g_Models != null) g_Models.Clear();
	if (g_Generic != null) g_Generic.Clear();
	if (g_Downloads != null) g_Downloads.Clear();
	EMS_DLog("Listas limpiadas.");
}

// ---- (Opcionales) añadir recursos extra en runtime --------------------
stock void EMS_Precache_AddSound(const char[] path)
{
	if (!path[0]) return;
	if (g_Sounds == null) EMS_Precache_Init();
	g_Sounds.PushString(path);
	EMS_DLog("Add Sound: %s", path);
}
stock void EMS_Precache_AddParticle(const char[] sysName)
{
	if (!sysName[0]) return;
	if (g_Particles == null) EMS_Precache_Init();
	g_Particles.PushString(sysName);
	EMS_DLog("Add Particle: %s", sysName);
}
stock void EMS_Precache_AddModel(const char[] model)
{
	if (!model[0]) return;
	if (g_Models == null) EMS_Precache_Init();
	g_Models.PushString(model);
	EMS_DLog("Add Model: %s", model);
}
stock void EMS_Precache_AddGeneric(const char[] file)
{
	if (!file[0]) return;
	if (g_Generic == null) EMS_Precache_Init();
	g_Generic.PushString(file);
	EMS_DLog("Add Generic: %s", file);
}
stock void EMS_Precache_AddDownload(const char[] file)
{
	if (!file[0]) return;
	if (g_Downloads == null) EMS_Precache_Init();
	g_Downloads.PushString(file);
	EMS_DLog("Add Download: %s", file);
}

// ======================================================================
// --------------------------- IMPLEMENTACIÓN ---------------------------
// ======================================================================

static int EMS_AddDownloads_()
{
	if (g_Downloads == null) return 0;

	int	 added = 0;
	char file[PLATFORM_MAX_PATH];
	for (int i = 0; i < g_Downloads.Length; i++)
	{
		g_Downloads.GetString(i, file, sizeof file);
		if (!file[0]) continue;
		AddFileToDownloadsTable(file);
		added++;
		EMS_DLog("Download table: %s", file);
	}
	return added;
}

static void EMS_PrecacheGeneric_(int &ok, int &fail)
{
	ok	 = 0;
	fail = 0;
	if (g_Generic == null) return;

	char f[PLATFORM_MAX_PATH];
	for (int i = 0; i < g_Generic.Length; i++)
	{
		g_Generic.GetString(i, f, sizeof f);
		if (!f[0]) continue;

		/* bool res = PrecacheGeneric(f, true);
		if (res) ok++; else fail++;
		EMS_DLog("Generic: %s -> %d", f, res ? 1 : 0); */
	}
}

static void EMS_PrecacheModels_(int &ok, int &fail)
{
	ok	 = 0;
	fail = 0;
	if (g_Models == null) return;

	char mdl[PLATFORM_MAX_PATH];
	for (int i = 0; i < g_Models.Length; i++)
	{
		g_Models.GetString(i, mdl, sizeof mdl);
		if (!mdl[0]) continue;

		int idx = PrecacheModel(mdl, true);
		if (idx > 0) ok++;
		else fail++;
		EMS_DLog("Model: %s -> idx=%d", mdl, idx);
	}
}

static void EMS_PrecacheSounds_(int &ok, int &fail)
{
	ok	 = 0;
	fail = 0;
	if (g_Sounds == null) return;

	char s[PLATFORM_MAX_PATH];
	for (int i = 0; i < g_Sounds.Length; i++)
	{
		g_Sounds.GetString(i, s, sizeof s);
		if (!s[0]) continue;

		bool res = PrecacheSound(s, true);	  // true => también cliente
		if (res) ok++;
		else fail++;
		EMS_DLog("Sound: %s -> %d", s, res ? 1 : 0);
	}
}

static void EMS_PrecacheParticles_(int &ok, int &fail)
{
	ok	 = 0;
	fail = 0;
	if (g_Particles == null) return;

	char p[128];
	for (int i = 0; i < g_Particles.Length; i++)
	{
		g_Particles.GetString(i, p, sizeof p);
		if (!p[0]) continue;

		bool res = EMS_PrecacheParticleSystem(p);
		int	 idx = EMS_GetParticleSystemIndex(p);	 // -1 si no existe
		if (res && idx != -1) ok++;
		else fail++;

		EMS_DLog("Particle: %s -> ok=%d idx=%d", p, res ? 1 : 0, idx);
	}
}
