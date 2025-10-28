#pragma semicolon 1
#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <sdkhooks>
#include <left4downtown>
#include <smlib>
#include <l4d_stocks>

#define PLUGIN_TITLE "Pico pal que lee"
#define PLUGIN_NAME "!rank"
#define PLUGIN_VERSION "1.4B105"
#define PLUGIN_DESCRIPTION "Player Stats and Ranking for Left 4 Dead and Left 4 Dead 2."

#define GLOW_HEALTH_SHIELD_TYPE L4D2Glow_OnUse
#define GLOW_HEALTH_SHIELD_RANGE 96
#define GLOW_HEALTH_SHIELD_MINRANGE 22
#define GLOW_HEALTH_SHIELD_COLOR_R 10
#define GLOW_HEALTH_SHIELD_COLOR_G 34
#define GLOW_HEALTH_SHIELD_COLOR_B 64
#define GLOW_HEALTH_SHIELD_FLASHING false

#define MODEL_SHIELD "models/weapons/melee/w_riotshield.mdl"
#define MODEL_SPRITE			"models/sprites/glow01.spr"

#define PARTICLE_SPIT_PROJ1		"spitter_projectile_explode"
#define PARTICLE_SPIT_PROJ2		"spitter_projectile_explode_2"
#define PARTICLE_TESLA			"electrical_arc_01"
#define PARTICLE_TESLA2			"electrical_arc_01_system"
#define PARTICLE_TESLA3			"st_elmos_fire"
#define PARTICLE_TESLA4			"storm_lightning_02"
#define PARTICLE_TESLA5			"storm_lightning_01"
#define MAX_NAME_LENGTH			255

new TankSpawnCount = 0;

static	bool:g_bLateLoad;

new LastVictimID = 0;
new TankChaosEvent = 0;
new MapStart = 0;
new bool: IsMuteProcess = false;
new bool: IsRegProcess = false;

new bool: RoundStarted = false;
new bool: WitchAllow;

new L4D2GlowType:type;
new DeathCloudNum = 0;
new bool:HulkAllow = true;
new Float:chaospos[3];

new Handle: toMute;
new Handle: toReg;
new Handle:g_aPlayers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... }; //scp

new Float:InfGlobalDamage = 0.0;
new Float:InfGlobalActivateDamage = 100.0;

new hostport;

static          bool:   g_bIsGlowing[MAXPLAYERS + 1];

static	VictimRenderEnt[MAXPLAYERS+1];

new iHurt[MAXPLAYERS+1];

static RenderBot[MAXPLAYERS+1];
new g_iAbilityO			= -1;
new g_iEffect[MAXPLAYERS+1]; //client effect entity id
new g_iFrustrationO		= -1;

new TeamBonusDelayTimeLeftI = 0;
new TeamBonusDelayTimeLeftS = 0;

new String:g_sBossNames[10][10]={"","smoker","boomer","hunter","spitter","jockey","charger","witch","tank","survivor"};

new LastUpgrade[MAXPLAYERS+1] = 0;

new IsPounced[MAXPLAYERS+1];
new PounceTime[MAXPLAYERS+1];
new IsInc[MAXPLAYERS+1];
new IncTime[MAXPLAYERS+1];

new Float:GLDmg[MAXPLAYERS+1];

new ShowDistance[MAXPLAYERS+1];
new MinDistance[MAXPLAYERS+1];

//new SummonCount[MAXPLAYERS+1];
//new String:Summon[MAXPLAYERS+1][255];

new Shields[MAXPLAYERS+1];
new String:SkinClassname[MAXPLAYERS+1][255];
new String:SteamIDBonus[MAXPLAYERS+1][255];
new MaxSteamIDBonus = MAXPLAYERS+1;

new MinigunStartCount = 0;
new MinigunTimeout = 0;
new TurrelCount = 0;

new bool:fVL = false;
new bool:ShowTankDamage = false;

static const	ASSAULT_RIFLE_OFFSET_IAMMO		= 12;
static const	SMG_OFFSET_IAMMO				= 20;
static const	PUMPSHOTGUN_OFFSET_IAMMO		= 28;
static const	AUTO_SHOTGUN_OFFSET_IAMMO		= 32;
static const	HUNTING_RIFLE_OFFSET_IAMMO		= 36;
static const	MILITARY_SNIPER_OFFSET_IAMMO	= 40;
static const	GRENADE_LAUNCHER_OFFSET_IAMMO	= 68;

new Handle:Timer1 = INVALID_HANDLE;
new Handle:Timer2 = INVALID_HANDLE;
new Handle:Timer3 = INVALID_HANDLE;
new Handle:Timer4 = INVALID_HANDLE;
new Handle:Timer5 = INVALID_HANDLE;
new Handle:Timer6 = INVALID_HANDLE;
new Handle:Timer7 = INVALID_HANDLE;
new Handle:Timer8 = INVALID_HANDLE;
new Handle:Timer9 = INVALID_HANDLE;
new Handle:Timer10 = INVALID_HANDLE;

new Handle:Timer20 = INVALID_HANDLE;
new Handle:Timer21 = INVALID_HANDLE;
new Handle:Timer22 = INVALID_HANDLE;
new Handle:Timer23 = INVALID_HANDLE;
new Handle:Timer24 = INVALID_HANDLE;
new Handle:Timer25 = INVALID_HANDLE;

new Handle:HulkResetTimer = INVALID_HANDLE;

static Handle:fhZombieAbortControl = INVALID_HANDLE;
static Handle:sdkReplaceWithBot = INVALID_HANDLE;
static Handle:sdkTakeOverZombieBot = INVALID_HANDLE;
new Handle:SoundPath = INVALID_HANDLE;
new Handle:sdkShove = INVALID_HANDLE;
new Handle:g_hGameConf = INVALID_HANDLE; //Game file path for signatures, adresses and offsets.
new Handle:sdkCallVomitPlayer = INVALID_HANDLE; //SDKCall, vomit or puke players.
new Handle:sdkSetBuffer = INVALID_HANDLE;
new Handle:Forward1 = INVALID_HANDLE;
new Handle:Forward2 = INVALID_HANDLE;
new Handle:Enable = INVALID_HANDLE;
new Handle:Modes = INVALID_HANDLE;
new Handle:Notifications = INVALID_HANDLE;
new Handle:PointsPistol = INVALID_HANDLE;
new Handle:PointsMagnum = INVALID_HANDLE;
new Handle:PointsSMG = INVALID_HANDLE;
new Handle:PointsSSMG = INVALID_HANDLE;
new Handle:PointsMP5 = INVALID_HANDLE;
new Handle:PointsM16 = INVALID_HANDLE;
new Handle:PointsAK = INVALID_HANDLE;
new Handle:PointsSCAR = INVALID_HANDLE;
new Handle:PointsSG = INVALID_HANDLE;
new Handle:PointsHunting = INVALID_HANDLE;
new Handle:PointsMilitary = INVALID_HANDLE;
new Handle:PointsAWP = INVALID_HANDLE;
new Handle:PointsScout = INVALID_HANDLE;
new Handle:PointsAuto = INVALID_HANDLE;
new Handle:PointsSpas = INVALID_HANDLE;
new Handle:PointsChrome = INVALID_HANDLE;
new Handle:PointsPump = INVALID_HANDLE;
new Handle:PointsGL = INVALID_HANDLE;
new Handle:PointsM60 = INVALID_HANDLE;
new Handle:PointsGasCan = INVALID_HANDLE;
new Handle:PointsOxy = INVALID_HANDLE;
new Handle:PointsPropane = INVALID_HANDLE;
new Handle:PointsGnome = INVALID_HANDLE;
new Handle:PointsCola = INVALID_HANDLE;
new Handle:PointsFireWorks = INVALID_HANDLE;
new Handle:PointsBat = INVALID_HANDLE;
new Handle:PointsMachete = INVALID_HANDLE;
new Handle:PointsKatana = INVALID_HANDLE;
new Handle:PointsTonfa = INVALID_HANDLE;
new Handle:PointsFireaxe = INVALID_HANDLE;
new Handle:PointsGuitar = INVALID_HANDLE;
new Handle:PointsPan = INVALID_HANDLE;
new Handle:PointsCBat = INVALID_HANDLE;
new Handle:PointsCrow = INVALID_HANDLE;
new Handle:PointsClub = INVALID_HANDLE;
new Handle:PointsSaw = INVALID_HANDLE;
new Handle:PointsPipe = INVALID_HANDLE;
new Handle:PointsMolly = INVALID_HANDLE;
new Handle:PointsBile = INVALID_HANDLE;
new Handle:PointsKit = INVALID_HANDLE;
new Handle:PointsDefib = INVALID_HANDLE;
new Handle:PointsAdren = INVALID_HANDLE;
new Handle:PointsPills = INVALID_HANDLE;
new Handle:PointsEAmmo = INVALID_HANDLE;
new Handle:PointsIAmmo = INVALID_HANDLE;
new Handle:PointsEAmmoPack = INVALID_HANDLE;
new Handle:PointsIAmmoPack = INVALID_HANDLE;
new Handle:PointsLSight = INVALID_HANDLE;
new Handle:PointsRefill = INVALID_HANDLE;
new Handle:PointsHeal = INVALID_HANDLE;
new Handle:SValueKillingSpree = INVALID_HANDLE;
new Handle:SNumberKill = INVALID_HANDLE;
new Handle:SValueHeadSpree = INVALID_HANDLE;
new Handle:SNumberHead = INVALID_HANDLE;
new Handle:SSIKill = INVALID_HANDLE;
new Handle:STankKill = INVALID_HANDLE;
new Handle:SWitchKill = INVALID_HANDLE;
new Handle:SWitchCrown = INVALID_HANDLE;
new Handle:SHeal = INVALID_HANDLE;
new Handle:SProtect = INVALID_HANDLE;
new Handle:SRevive = INVALID_HANDLE;
new Handle:SLedge = INVALID_HANDLE;
new Handle:SDefib = INVALID_HANDLE;
new Handle:STBurn = INVALID_HANDLE;
new Handle:STSolo = INVALID_HANDLE;
new Handle:SWBurn = INVALID_HANDLE;
new Handle:STag = INVALID_HANDLE;
new Handle:IChoke = INVALID_HANDLE;
new Handle:IPounce = INVALID_HANDLE;
new Handle:ICarry = INVALID_HANDLE;
new Handle:IImpact = INVALID_HANDLE;
new Handle:IRide = INVALID_HANDLE;
new Handle:ITag = INVALID_HANDLE;
new Handle:IIncap = INVALID_HANDLE;
new Handle:IHurt = INVALID_HANDLE;
new Handle:IKill = INVALID_HANDLE;
new Handle:PointsSuicide = INVALID_HANDLE;
new Handle:PointsHunter = INVALID_HANDLE;
new Handle:PointsJockey = INVALID_HANDLE;
new Handle:PointsSmoker = INVALID_HANDLE;
new Handle:PointsCharger = INVALID_HANDLE;
new Handle:PointsBoomer = INVALID_HANDLE;
new Handle:PointsSpitter = INVALID_HANDLE;
new Handle:PointsIHeal = INVALID_HANDLE;
new Handle:PointsWitch = INVALID_HANDLE;
new Handle:PointsTank = INVALID_HANDLE;
new Handle:PointsTankHealMult = INVALID_HANDLE;
new Handle:PointsHorde = INVALID_HANDLE;
new Handle:PointsMob = INVALID_HANDLE;
new Handle:PointsUMob = INVALID_HANDLE;
new Handle:CatRifles = INVALID_HANDLE;
new Handle:CatSMG = INVALID_HANDLE;
new Handle:CatSnipers = INVALID_HANDLE;
new Handle:CatShotguns = INVALID_HANDLE;
new Handle:CatHealth = INVALID_HANDLE;
new Handle:CatUpgrades = INVALID_HANDLE;
new Handle:CatThrowables = INVALID_HANDLE;
new Handle:CatMisc = INVALID_HANDLE;
new Handle:CatMelee = INVALID_HANDLE;
new Handle:CatWeapons = INVALID_HANDLE;
new Handle:TankLimit = INVALID_HANDLE;
new Handle:WitchLimit = INVALID_HANDLE;
new Handle:ResetPoints = INVALID_HANDLE;
new Handle:StartPoints = INVALID_HANDLE;
new Handle:db = INVALID_HANDLE;
new Handle:UpdateTimer = INVALID_HANDLE;
new Handle:cvar_Difficulty = INVALID_HANDLE;
new Handle:cvar_Gamemode = INVALID_HANDLE;
new Handle:cvar_Cheats = INVALID_HANDLE;
new Handle:cvar_SurvivorLimit = INVALID_HANDLE;
new Handle:cvar_InfectedLimit = INVALID_HANDLE;
new Handle:cvar_EnableRankVote = INVALID_HANDLE;
new Handle:cvar_HumansNeeded = INVALID_HANDLE;
new Handle:cvar_UpdateRate = INVALID_HANDLE;
new Handle:cvar_AnnounceRankChange = INVALID_HANDLE;
new Handle:cvar_AnnounceMode = INVALID_HANDLE;
new Handle:cvar_AnnounceRankChangeIVal = INVALID_HANDLE;
new Handle:cvar_AnnounceToTeam = INVALID_HANDLE;
new Handle:cvar_MedkitMode = INVALID_HANDLE;
new Handle:cvar_SiteURL = INVALID_HANDLE;
new Handle:cvar_RankOnJoin = INVALID_HANDLE;
new Handle:cvar_SilenceChat = INVALID_HANDLE;
new Handle:cvar_DisabledMessages = INVALID_HANDLE;
new Handle:cvar_DbPrefix = INVALID_HANDLE;
new Handle:cvar_EnableNegativeScore = INVALID_HANDLE;
new Handle:cvar_FriendlyFireMode = INVALID_HANDLE;
new Handle:cvar_FriendlyFireMultiplier = INVALID_HANDLE;
new Handle:cvar_FriendlyFireCooldown = INVALID_HANDLE;
new Handle:cvar_FriendlyFireCooldownMode = INVALID_HANDLE;
new Handle:FriendlyFireTimer[MAXPLAYERS + 1][MAXPLAYERS + 1];
new Handle:FriendlyFireDamageTrie = INVALID_HANDLE;
new Handle:cvar_Enable = INVALID_HANDLE;
new Handle:cvar_EnableCoop = INVALID_HANDLE;
new Handle:cvar_EnableSv = INVALID_HANDLE;
new Handle:cvar_EnableVersus = INVALID_HANDLE;
new Handle:cvar_EnableTeamVersus = INVALID_HANDLE;
new Handle:cvar_EnableRealism = INVALID_HANDLE;
new Handle:cvar_EnableScavenge = INVALID_HANDLE;
new Handle:cvar_EnableTeamScavenge = INVALID_HANDLE;
new Handle:cvar_EnableRealismVersus = INVALID_HANDLE;
new Handle:cvar_EnableTeamRealismVersus = INVALID_HANDLE;
new Handle:cvar_EnableMutations = INVALID_HANDLE;
new Handle:cvar_RealismMultiplier = INVALID_HANDLE;
new Handle:cvar_RealismVersusSurMultiplier = INVALID_HANDLE;
new Handle:cvar_RealismVersusInfMultiplier = INVALID_HANDLE;
new Handle:cvar_EnableSvMedicPoints = INVALID_HANDLE;
new Handle:cvar_Infected = INVALID_HANDLE;
new Handle:cvar_Hunter = INVALID_HANDLE;
new Handle:cvar_Smoker = INVALID_HANDLE;
new Handle:cvar_Boomer = INVALID_HANDLE;
new Handle:cvar_Spitter = INVALID_HANDLE;
new Handle:cvar_Jockey = INVALID_HANDLE;
new Handle:cvar_Charger = INVALID_HANDLE;
new Handle:cvar_Pills = INVALID_HANDLE;
new Handle:cvar_Adrenaline = INVALID_HANDLE;
new Handle:cvar_Medkit = INVALID_HANDLE;
new Handle:cvar_Defib = INVALID_HANDLE;
new Handle:cvar_SmokerDrag = INVALID_HANDLE;
new Handle:cvar_ChokePounce = INVALID_HANDLE;
new Handle:cvar_JockeyRide = INVALID_HANDLE;
new Handle:cvar_ChargerPlummel = INVALID_HANDLE;
new Handle:cvar_ChargerCarry = INVALID_HANDLE;
new Handle:cvar_Revive = INVALID_HANDLE;
new Handle:cvar_Rescue = INVALID_HANDLE;
new Handle:cvar_Protect = INVALID_HANDLE;
new Handle:cvar_Tank = INVALID_HANDLE;
new Handle:cvar_Panic = INVALID_HANDLE;
new Handle:cvar_BoomerMob = INVALID_HANDLE;
new Handle:cvar_SafeHouse = INVALID_HANDLE;
new Handle:cvar_Witch = INVALID_HANDLE;
new Handle:cvar_WitchCrowned = INVALID_HANDLE;
new Handle:cvar_VictorySurvivors = INVALID_HANDLE;
new Handle:cvar_VictoryInfected = INVALID_HANDLE;
new Handle:cvar_FFire = INVALID_HANDLE;
new Handle:cvar_FIncap = INVALID_HANDLE;
new Handle:cvar_FKill = INVALID_HANDLE;
new Handle:cvar_InSafeRoom = INVALID_HANDLE;
new Handle:cvar_Restart = INVALID_HANDLE;
new Handle:cvar_CarAlarm = INVALID_HANDLE;
new Handle:cvar_BotScoreMultiplier = INVALID_HANDLE;
new Handle:cvar_SurvivorDeath = INVALID_HANDLE;
new Handle:cvar_SurvivorIncap = INVALID_HANDLE;
new Handle:cvar_AmmoUpgradeAdded = INVALID_HANDLE;
new Handle:cvar_GascanPoured = INVALID_HANDLE;
new Handle:cvar_HunterDamageCap = INVALID_HANDLE;
new Handle:cvar_HunterPerfectPounceDamage = INVALID_HANDLE;
new Handle:cvar_HunterPerfectPounceSuccess = INVALID_HANDLE;
new Handle:cvar_HunterNicePounceDamage = INVALID_HANDLE;
new Handle:cvar_HunterNicePounceSuccess = INVALID_HANDLE;
new Handle:cvar_BoomerSuccess = INVALID_HANDLE;
new Handle:cvar_BoomerPerfectHits = INVALID_HANDLE;
new Handle:cvar_BoomerPerfectSuccess = INVALID_HANDLE;
new Handle:TimerBoomerPerfectCheck[MAXPLAYERS + 1];
new Handle:cvar_InfectedDamage = INVALID_HANDLE;
new Handle:TimerInfectedDamageCheck[MAXPLAYERS + 1];
new Handle:cvar_TankDamageCap = INVALID_HANDLE;
new Handle:cvar_TankDamageTotal = INVALID_HANDLE;
new Handle:cvar_TankDamageTotalSuccess = INVALID_HANDLE;
new Handle:ChargerImpactCounterTimer[MAXPLAYERS + 1];
new Handle:cvar_ChargerRamHits = INVALID_HANDLE;
new Handle:cvar_ChargerRamSuccess = INVALID_HANDLE;
new Handle:cvar_TankThrowRockSuccess = INVALID_HANDLE;
new Handle:cvar_PlayerLedgeSuccess = INVALID_HANDLE;
new Handle:cvar_Matador = INVALID_HANDLE;
new Handle:cvar_MedkitUsedPointPenalty = INVALID_HANDLE;
new Handle:cvar_MedkitUsedPointPenaltyMax = INVALID_HANDLE;
new Handle:cvar_MedkitUsedFree = INVALID_HANDLE;
new Handle:cvar_MedkitUsedRealismFree = INVALID_HANDLE;
new Handle:cvar_MedkitBotMode = INVALID_HANDLE;
new Handle:TimerProtectedFriendly[MAXPLAYERS + 1];
new Handle:TimerRankChangeCheck[MAXPLAYERS + 1];
new Handle:MapTimingSurvivors = INVALID_HANDLE; // Survivors at the beginning of the map
new Handle:MapTimingInfected = INVALID_HANDLE; // Survivors at the beginning of the map
new Handle:ClearDatabaseTimer = INVALID_HANDLE;
new Handle:RankAdminMenu = INVALID_HANDLE;
new Handle:cvar_AdminPlayerCleanLastOnTime = INVALID_HANDLE;
new Handle:cvar_AdminPlayerCleanPlatime = INVALID_HANDLE;
new Handle:RankVoteTimer = INVALID_HANDLE;
new Handle:PlayerRankVoteTrie = INVALID_HANDLE; // Survivors at the beginning of the map
new Handle:cvar_RankVoteTime = INVALID_HANDLE;
new Handle:cvar_Top10PPMMin = INVALID_HANDLE;
new Handle:L4DStatsConf = INVALID_HANDLE;
new Handle:L4DStatsSHS = INVALID_HANDLE;
new Handle:L4DStatsTOB = INVALID_HANDLE;
new Handle:cvar_Lan = INVALID_HANDLE;
new Handle:cvar_SoundsEnabled = INVALID_HANDLE;
new Handle:MeleeKillTimer[MAXPLAYERS + 1];

new Handle:NormalGlowTimer[MAXPLAYERS + 1];

new HumanChaosTank = 0;

static const String:GAMEDATA_FILENAME[]				= "l4d2addresses";

new MapEnd = 0;

static const Float:TRACE_TOLERANCE 			= 25.0;

new bool:isincloud[MAXPLAYERS+1];
new AllowActivateBuyClient[MAXPLAYERS+1] = 1;
new RoundStartTime = 0;
new gHordeType = 1;

new ResetShieldAllow[MAXPLAYERS+1] = 1;

new TankChaosAllow[MAXPLAYERS+1];

static bool:reswapInfected[MAXPLAYERS+1];
static bool:reghostInfected[MAXPLAYERS+1];
static bool:respawnInfected[MAXPLAYERS+1];
static infectedClass[MAXPLAYERS+1];
static infectedHealth[MAXPLAYERS+1];
static Float:vectors[MAXPLAYERS+1][3];
static Float:infangles[MAXPLAYERS+1][3];
static Float:velocity[MAXPLAYERS+1][3];
static const Float:nullorigin[3];

#define EFFECT_PARTICLE_SURVIVOR "fire_small_01" //Particle to show in a berserker player
#define EFFECT_PARTICLE_INFECTED "fire_small_03"

#define PARTICLE_SPAWN		"smoker_smokecloud"
#define PARTICLE_FIRE		"aircraft_destroy_fastFireTrail"
#define PARTICLE_WARP		"electrical_arc_01_system"
#define PARTICLE_ICE		"steam_manhole"
#define PARTICLE_SPIT		"spitter_slime_trail"
#define PARTICLE_SPITPROJ	"spitter_projectile"
#define PARTICLE_ELEC		"electrical_arc_01_parent"
#define PARTICLE_BLOOD		"boomer_explode_D"
#define PARTICLE_EXPLODE	"boomer_explode"
#define PARTICLE_METEOR		"smoke_medium_01"
#define PARTICLE_FIRE2		"env_fire_small_smoke"

#define SHIELDSOUND "weapons/bat/bat_impact_world1.wav"
#define YELLNICK_1 "player/survivor/voice/gambler/battlecry04.wav"
#define YELLNICK_2 "player/survivor/voice/gambler/battlecry01.wav"
#define YELLNICK_2 "player/survivor/voice/gambler/battlecry01.wav"
#define YELLNICK_3 "player/survivor/voice/gambler/battlecry02.wav"
#define YELLRO_1 "player/survivor/voice/producer/battlecry01.wav"
#define YELLRO_2 "player/survivor/voice/producer/battlecry02.wav"
#define YELLRO_3 "player/survivor/voice/producer/hurrah11.wav"
#define YELLELLIS_1 "player/survivor/voice/mechanic/battlecry01.wav"
#define YELLELLIS_2 "player/survivor/voice/mechanic/battlecry03.wav"
#define YELLELLIS_3 "player/survivor/voice/mechanic/battlecry02.wav"
#define YELLCOACH_1 "player/survivor/voice/coach/battlecry09.wav"
#define YELLCOACH_2 "player/survivor/voice/coach/battlecry06.wav"
#define YELLCOACH_3 "player/survivor/voice/coach/battlecry04.wav"
#define YELLHUNTER_1 "player/hunter/voice/warn/hunter_warn_10.wav"
#define YELLHUNTER_2 "player/hunter/voice/warn/hunter_warn_14.wav"
#define YELLHUNTER_3 "player/hunter/voice/warn/hunter_warn_18.wav"
#define YELLSMOKER_1 "player/smoker/voice/warn/smoker_warn_01.wav"
#define YELLSMOKER_2 "player/smoker/voice/warn/smoker_warn_04.wav"
#define YELLSMOKER_3 "player/smoker/voice/warn/smoker_warn_05.wav"
#define YELLJOCKEY_1 "player/jockey/voice/warn/jockey_06.wav"
#define YELLJOCKEY_2 "player/jockey/voice/idle/jockey_lurk06.wav"
#define YELLJOCKEY_3 "player/jockey/voice/idle/jockey_lurk09"
#define YELLSPITTER_1 "player/spitter/voice/warn/spitter_warn_01.wav"
#define YELLSPITTER_2 "player/spitter/voice/warn/spitter_warn_02.wav"
#define YELLSPITTER_3 "player/spitter/voice/warn/spitter_warn_03.wav"
#define YELLBOOMER_1 "player/boomer/voice/action/male_zombie10_growl5.wav"
#define YELLBOOMER_2 "player/boomer/voice/action/male_zombie10_growl6.wav"
#define YELLBOOMER_3 "player/boomer/voice/alert/male_boomer_alert_05.wav"
#define YELLCHARGER_1 "player/charger/voice/warn/charger_warn_01.wav"
#define YELLCHARGER_2 "player/charger/voice/warn/charger_warn_02.wav"
#define YELLCHARGER_3 "player/charger/voice/warn/charger_warn_03.wav"
#define YELLBOOMETTE_1 "player/boomer/voice/action/female_zombie10_growl4.wav"
#define YELLBOOMETTE_2 "player/boomer/voice/action/female_zombie10_growl5.wav"
#define YELLBOOMETTE_3 "player/boomer/voice/action/female_zombie10_growl3.wav"
#define YELLTANK_1 "player/tank/voice/pain/tank_fire_01.wav"
#define YELLTANK_2 "player/tank/voice/pain/tank_fire_03.wav"
#define YELLTANK_3 "player/tank/voice/yell/tank_throw_04.wav"
#define TANKSPAWN1 "player/tank/voice/pain/tank_breathe_05.wav"
#define TANKSPAWN2 "player/tank/voice/pain/tank_growl_03.wav"
#define TANKSPAWN3 "player/tank/voice/pain/tank_fire_08.wav"
#define TANKSPAWN4 "player/tank/voice/pain/tank_fire_06.wav"
#define TANKSPAWN5 "player/tank/voice/pain/tank_fire_05.wav"
#define HORDE "npc/mega_mob/mega_mob_incoming.wav"
#define VIPJOIN "player/orch_hit_csharp_short.wav"
#define SOUNDUNK "player/hunter/voice/pain/lunge_attack_3.wav"


#define MAX_LINE_WIDTH 64
#define MAX_MESSAGE_WIDTH 256
#define MAX_QUERY_COUNTER 256
#define DB_CONF_NAME "l4dstats2"

#define GAMEMODE_UNKNOWN -1
#define GAMEMODE_COOP 0
#define GAMEMODE_VERSUS 1
#define GAMEMODE_REALISM 2
#define GAMEMODE_SURVIVAL 3
#define GAMEMODE_SCAVENGE 4
#define GAMEMODE_REALISMVERSUS 5
#define GAMEMODE_MUTATIONS 6
#define GAMEMODES 7

#define INF_ID_SMOKER 1
#define INF_ID_BOOMER 2
#define INF_ID_HUNTER 3
#define INF_ID_SPITTER_L4D2 4
#define INF_ID_JOCKEY_L4D2 5
#define INF_ID_CHARGER_L4D2 6
#define INF_ID_WITCH_L4D1 4
#define INF_ID_WITCH_L4D2 7
#define INF_ID_TANK_L4D1 5
#define INF_ID_TANK_L4D2 8

#define TEAM_UNDEFINED 0
#define TEAM_SPECTATORS 1
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

#define INF_WEAROFF_TIME 0.5

#define SERVER_VERSION_L4D1 40
#define SERVER_VERSION_L4D2 50

#define CLEAR_DATABASE_CONFIRMTIME 10.0

#define CM_UNKNOWN -1
#define CM_RANK 0
#define CM_TOP10 1
#define CM_NEXTRANK 2
#define CM_NEXTRANKFULL 3

#define SOUND_RANKVOTE "items/suitchargeok1.wav"
#define SOUND_MAPTIME_START_L4D1 "UI/Beep23.wav"
#define SOUND_MAPTIME_START_L4D2 "level/countdown.wav"
#define SOUND_MAPTIME_IMPROVE_L4D1 "UI/Pickup_Secret01.wav"
#define SOUND_MAPTIME_IMPROVE_L4D2 "level/bell_normal.wav"
#define SOUND_RANKMENU_SHOW_L4D1 "UI/Menu_Horror01.wav"
#define SOUND_RANKMENU_SHOW_L4D2 "ui/menu_horror01.wav"
#define SOUND_BOOMER_VOMIT_L4D1 "player/Boomer/fall/boomer_dive_01.wav"
#define SOUND_BOOMER_VOMIT_L4D2 "player/Boomer/fall/boomer_dive_01.wav"
#define SOUND_HUNTER_PERFECT_L4D1 "player/hunter/voice/pain/lunge_attack_3.wav"
#define SOUND_HUNTER_PERFECT_L4D2 "player/hunter/voice/pain/lunge_attack_3.wav"
#define SOUND_TANK_BULLDOZER_L4D1 "player/tank/voice/yell/hulk_yell_8.wav"
#define SOUND_TANK_BULLDOZER_L4D2 "player/tank/voice/yell/tank_throw_11.wav"
#define SOUND_CHARGER_RAM "player/charger/voice/alert/charger_alert_02.wav"

#define RANKVOTE_NOVOTE -1
#define RANKVOTE_NO 0
#define RANKVOTE_YES 1

//points start

static g_flLagMovement = 0;
static g_iShovePenalty = 0;


new g_iNextActO = 1104;
new g_iAttackTimerO = 5436;

//new g_iNextActO = 1092;
//new g_iAttackTimerO = 5448;
//new g_iNextActO = 1068;
//new g_iAttackTimerO = 5436;

//these are for L4D2, Linux
//new g_iNextActO_linux = 1088;
//new g_iAttackTimerO_linux = 5444;


new FrustrationReset[MAXPLAYERS+1];

new g_iTeam[MAXPLAYERS+1]; //Player team index
new bool:g_bIsVomited[MAXPLAYERS+1] = false; //Is the player vomited?
new g_iWhoVomited[MAXPLAYERS+1]; //Who was the last who vomited a player
new Float:g_flMANextTime[64] = -1.0;
new g_iMAEntid[64] = -1;
new g_iMAEntid_notmelee[64] = -1;
new g_iMAAttCount[64] = -1;
new g_iNextPAttO		= -1;
new g_iNextSAttO		= -1;
new g_iMARegisterIndex[64] = -1;
new g_iMARegisterCount = 0;

new g_iTank_MainId = 0;

new g_iHPBuffO = -1;
new bool:g_bIsLoading;
new g_ActiveWeaponOffset;

new RoundEnd = 0;
new propinfoburn = -1;
new Float:OriginSpeed[MAXPLAYERS + 1];
new propinfoghost;
new OriginHealth[MAXPLAYERS + 1];
new LastHP[MAXPLAYERS + 1];
new AcidDamage[MAXPLAYERS + 1];

new ToClient[MAXPLAYERS + 1];
new PointsValue[MAXPLAYERS + 1];

#define MaxBonus 30
new VipStatus[MAXPLAYERS + 1];
new VipStatusWas[MAXPLAYERS + 1];
new VipStatusDisabled[MAXPLAYERS + 1];
new VipBonus[MAXPLAYERS + 1][MaxBonus];

new SurvUpgradeExplosive[MAXPLAYERS + 1];
new SurvUpgradeIncendiary[MAXPLAYERS + 1];
new SurvSpeedUp[MAXPLAYERS + 1];
new SurvSpecialShield[MAXPLAYERS + 1];
new SurvVampire[MAXPLAYERS + 1];
new SurvShoving[MAXPLAYERS + 1];
new SurvLaser[MAXPLAYERS + 1];
new SurvMeleeMaster[MAXPLAYERS + 1];
new SurvRevenge[MAXPLAYERS + 1];
new SurvYell[MAXPLAYERS + 1];
new SurvHealthConvert[MAXPLAYERS + 1];
new SurvIncSpecialShield[MAXPLAYERS + 1];
new SurvGift[MAXPLAYERS + 1];
new SurvBerserker[MAXPLAYERS + 1];
new SurvFirearmsMaster[MAXPLAYERS + 1];
new SurvAWP;
new SurvM60;
new SurvGL;

new SurvGasCan_Cost = 100;

new SurvFirearmsMaster_Value = 20;

new SurvSpeedUp_Value = 1.35;
new InfSpeedUp_Value = 1.4;

new SurvAllowMass = 1;
new InfAllowMass = 1;

new SurvMassSpeedUp = 0;
new SurvMassSpeedUp_Sum = 0;
new SurvMassSpeedUp_Cost = 100;
new SurvMassSpeedUp_Value = 1.5;
new Float:SurvMassSpeedUp_Time = 60.0;

new SurvMassRegen = 0;
new SurvMassRegen_Sum = 0;
new SurvMassRegen_Cost = 110;
new Float:SurvMassRegen_Time = 60.0;

new SurvAutoMiniGun = 0;
new SurvAutoMiniGun_Sum = 0;
new SurvAutoMiniGun_Cost = 120;
new SurvAutoMiniGun_Limit = 1;

new SurvZombieSurprize = 0;
new SurvZombieSurprize_Sum = 0;
new SurvZombieSurprize_Cost = 130;
new Float:SurvZombieSurprize_Time = 60.0;

new SurvUntouchable = 0;
new SurvUntouchable_Sum = 0;
new SurvUntouchable_Cost = 150;
new Float:SurvUntouchable_Time = 300.0;

new SurvPhysPower = 0;
new SurvPhysPower_Sum = 0;
new SurvPhysPower_Cost = 130;
new Float:SurvPhysPower_Time = 180.0;

new SurvVictimShield = 0;
new SurvVictimShield_Sum = 0;
new SurvVictimShield_Cost = 100;

new InfMassSlow = 0;
new InfMassSlow_Sum = 0;
new InfMassSlow_Cost = 100;
new InfMassSlow_Value = 0.6;
new Float:InfMassSlow_Time = 60.0;

new InfTankChaos = 0;
new InfTankChaos_Sum = 0;
new InfTankChaos_Cost = 130;
new InfTankChaos_HP = 1500;
//new Float:InfTankChaos_Range = 1500.0;

new InfMassArmor = 0;
new InfMassArmor_Sum = 0;
new InfMassArmor_Cost = 130;
new Float:InfMassArmor_Mult = 0.5;

new InfDeathCloud = 0;
new InfDeathCloud_Sum = 0;
new InfDeathCloud_Cost = 100;
new Float:InfDeathCloud_Time = 60.0;

new InfZombieApoc = 0;
new InfZombieApoc_Sum = 0;
new InfZombieApoc_Cost = 140;

new InfPoison = 0;
new InfPoison_Sum = 0;
new InfPoison_Cost = 100;
new Float:InfPoison_Time = 60.0;

new InfBummerRain = 0;
new InfBummerRain_Sum = 0;
new InfBummerRain_Cost = 100;


new SurvFirearmsMaster_Cost = 200;
new SurvSpeedUp_Cost = 100;
new SurvSpecialShield_Cost = 100;
new SurvVampire_Cost = 250;
new SurvShoving_Cost = 100;
new SurvLaser_Cost = 50;
new SurvMeleeMaster_Cost = 150;
new SurvRevenge_Cost = 80;
new SurvYell_Cost = 300;
new SurvHealthConvert_Cost = 50;
new SurvIncSpecialShield_Cost = 100;
new SurvGift_Cost = 110;
new SurvAWP_Cost = 90;
new SurvM60_Cost = 140;
new SurvGL_Cost = 150;
new SurvFireYell_Cost = 60;
new SurvPowerYell_Cost = 90;
new SurvBerserker_Cost = 130;

new SurvUpgradeExplosive_Cost = 70;
new SurvUpgradeIncendiary_Cost = 60;
new SurvExplosiveAmmo_Cost = 150;
new SurvIncendiaryAmmo_Cost = 100;

new HulkHP = 7000;
new Float:HulkSpeedUP = 1.6;

new bool:VictimTimerStarted = false;

new InfSpeedUp[MAXPLAYERS + 1];
new InfBonusDamage[MAXPLAYERS + 1];
new InfSpecialShield[MAXPLAYERS + 1];
new InfBonusHealth[MAXPLAYERS + 1];
new InfAcidClaws[MAXPLAYERS + 1];
new InfFireShield[MAXPLAYERS + 1];
new InfMask[MAXPLAYERS + 1];
new InfMeeleShield[MAXPLAYERS + 1];
new InfRegen[MAXPLAYERS + 1];
new InfHulk[MAXPLAYERS + 1];
new InfHobbits[MAXPLAYERS + 1];
new InfAntiYell[MAXPLAYERS + 1];

new TankChaos[MAXPLAYERS + 1];

new InfSpeedUp_Cost = 30;
new InfBonusDamage_Cost = 25;
new InfSpecialShield_Cost = 30;
new InfBonusHealth_Cost = 25;
new InfAcidClaws_Cost = 30;
new InfFireShield_Cost = 22;
new InfMask_Cost = 25;
new InfMeeleShield_Cost = 20;
new InfRegen_Cost = 20;
new InfAntiYell_Cost = 50;

new InfHulk_Cost = 400;
new InfHobbits_Cost = 180;
new InfRiot_Cost = 140;
new InfCeda_Cost = 120;
new InfClown_Cost = 120;
new InfMudman_Cost = 130;
new InfRoadcrew_Cost = 110;
new InfJimmy_Cost = 150;
new InfFallen_Cost = 130;

new InfOneCommon_Cost = 50;
new InfOneRiot_Cost = 70;
new InfOneCeda_Cost = 40;
new InfOneClown_Cost = 40;
new InfOneMudman_Cost = 45;
new InfOneRoadcrew_Cost = 40;
new InfOneJimmy_Cost = 100;
new InfOneFallen_Cost = 55;

new InfMutantBomb_Cost = 75;
new InfMutantFire_Cost = 70;
new InfMutantGhost_Cost = 65;
new InfMutantMind_Cost = 80;
new InfMutantSmoke_Cost = 60;
new InfMutantSpit_Cost = 65;
new InfMutantTesla_Cost = 80;

new Float:version = 1.0;
new String:modules[100][100];
new registeredmodules = 0;

new VictimID = 0;
new bool:AllowHealth;
new bool:AllowBuy[MAXPLAYERS];
new String:MapName[30];
new String:item[MAXPLAYERS+1][255];
new String:bought[MAXPLAYERS+1][64];
new boughtcost[MAXPLAYERS] = 0;
new hurtcount[MAXPLAYERS] = 0;
new protectcount[MAXPLAYERS] = 0;
new cost[MAXPLAYERS] = 0;
new tankburning[MAXPLAYERS] = 0;
new tankbiled[MAXPLAYERS] = 0;
new witchburning[MAXPLAYERS] = 0;
new points[MAXPLAYERS] = 0;
new killcount[MAXPLAYERS] = 0;
new headshotcount[MAXPLAYERS] = 0;
new wassmoker[MAXPLAYERS] = 0;
new tanksspawned = 0;
new witchsspawned = 0;
new ucommonleft = 0;

//Definitions to save space
#define ATTACKER new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
#define CLIENT new client = GetClientOfUserId(GetEventInt(event, "userid"));
#define ACHECK2 if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2 &&  GetConVarInt(Enable) == 1)
#define CCHECK2 if(client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 2 && GetConVarInt(Enable) == 1)
#define ACHECK3 if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 3 && GetConVarInt(Enable) == 1)
#define CCHECK3 if(client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 3 && GetConVarInt(Enable) == 1)
//Other

//points end

new String:TM_MENU_CURRENT[4] = " <<";

new String:DB_PLAYERS_TOTALPOINTS[1024] = "points + points_survivors + points_infected + points_realism + points_survival + points_scavenge_survivors + points_scavenge_infected + points_realism_survivors + points_realism_infected + points_mutations";
new String:DB_PLAYERS_TOTALPLAYTIME[1024] = "playtime + playtime_versus + playtime_realism + playtime_survival + playtime_scavenge + playtime_realismversus + playtime_mutations";

new String:RANKVOTE_QUESTION[128] = "Do you want to shuffle teams by player PPM?";

// Set to false when stats seem to work properly
new bool:DEBUG = true;

new bool:CommandsRegistered = false;

// Sounds
new bool:EnableSounds_Rankvote = true;
new bool:EnableSounds_Maptime_Start = true;
new bool:EnableSounds_Maptime_Improve = true;
new bool:EnableSounds_Rankmenu_Show = true;
new bool:EnableSounds_Boomer_Vomit = true;
new bool:EnableSounds_Hunter_Perfect = true;
new bool:EnableSounds_Tank_Bulldozer = true;
new bool:EnableSounds_Charger_Ram = true;
new String:StatsSound_MapTime_Start[32];
new String:StatsSound_MapTime_Improve[32];
new String:StatsSound_Rankmenu_Show[32];
new String:StatsSound_Boomer_Vomit[32];
new String:StatsSound_Hunter_Perfect[32];
new String:StatsSound_Tank_Bulldozer[32];

// Server version
new ServerVersion = SERVER_VERSION_L4D1;

new String:DbPrefix[MAX_LINE_WIDTH] = "";

// Gamemode
new String:CurrentGamemode[MAX_LINE_WIDTH];
new String:CurrentGamemodeLabel[MAX_LINE_WIDTH];
new CurrentGamemodeID = GAMEMODE_UNKNOWN;
new String:CurrentMutation[MAX_LINE_WIDTH];


// Game event booleans
new bool:PlayerVomited = false;
new bool:PlayerVomitedIncap = false;
new bool:PanicEvent = false;
new bool:PanicEventIncap = false;
new bool:CampaignOver = false;
new bool:WitchExists = false;
new bool:WitchDisturb = false;

// Anti-Stat Whoring vars
new CurrentPoints[MAXPLAYERS + 1];
new TankCount = 0;
new ChaosTankCount = 0;

new bool:ClientRankMute[MAXPLAYERS + 1];

new bool:FriendlyFireCooldown[MAXPLAYERS + 1][MAXPLAYERS + 1];
new FriendlyFirePrm[MAXPLAYERS][2];
new FriendlyFirePrmCounter = 0;



new MaxPounceDistance;
new MinPounceDistance;
new MaxPounceDamage;
new Float:HunterPosition[MAXPLAYERS + 1][3];

new BoomerHitCounter[MAXPLAYERS + 1];
new bool:BoomerVomitUpdated[MAXPLAYERS + 1];

new InfectedDamageCounter[MAXPLAYERS + 1];

new ChargerCarryVictim[MAXPLAYERS + 1];
new ChargerPlummelVictim[MAXPLAYERS + 1];
new JockeyVictim[MAXPLAYERS + 1];
new JockeyRideStartTime[MAXPLAYERS + 1];

new SmokerDamageCounter[MAXPLAYERS + 1];
new SpitterDamageCounter[MAXPLAYERS + 1];
new JockeyDamageCounter[MAXPLAYERS + 1];
new ChargerDamageCounter[MAXPLAYERS + 1];
new ChargerImpactCounter[MAXPLAYERS + 1];
new TankDamageCounter[MAXPLAYERS + 1];
new TankDamageTotalCounter[MAXPLAYERS + 1];
new TankPointsCounter[MAXPLAYERS + 1];
new TankSurvivorKillCounter[MAXPLAYERS + 1];

new ClientInfectedType[MAXPLAYERS + 1];

new PlayerBlinded[MAXPLAYERS + 1][2];
new PlayerParalyzed[MAXPLAYERS + 1][2];
new PlayerLunged[MAXPLAYERS + 1][2];
new PlayerPlummeled[MAXPLAYERS + 1][2];
new PlayerCarried[MAXPLAYERS + 1][2];
new PlayerJockied[MAXPLAYERS + 1][2];

// Rank panel vars
new RankTotal = 0;
new ClientRank[MAXPLAYERS + 1];
new ClientNextRank[MAXPLAYERS + 1];
new ClientPoints[MAXPLAYERS + 1];
new GameModeRankTotal = 0;
new ClientGameModeRank[MAXPLAYERS + 1];
new ClientGameModePoints[MAXPLAYERS + 1][GAMEMODES];

// Misc arrays
new TimerPoints[MAXPLAYERS + 1];
new TimerKills[MAXPLAYERS + 1];
new TimerHeadshots[MAXPLAYERS + 1];
new Pills[4096];
new Adrenaline[4096];

new String:QueryBuffer[MAX_QUERY_COUNTER][MAX_QUERY_COUNTER];
new QueryCounter = 0;

new AnnounceCounter[MAXPLAYERS + 1];
new PostAdminCheckRetryCounter[MAXPLAYERS + 1];

// For every medkit used the points earned by the Survivor team is calculated with this formula:
// NormalPointsEarned * (1 - MedkitsUsedCounter * cvar_MedkitUsedPointPenalty)
// Minimum formula result = 0 (Cannot be negative)
new MedkitsUsedCounter = 0;

new ProtectedFriendlyCounter[MAXPLAYERS + 1];
new RankChangeLastRank[MAXPLAYERS + 1];
new bool:RankChangeFirstCheck[MAXPLAYERS + 1];

// MapTiming
new Float:MapTimingStartTime = -1.0;
new String:MapTimingMenuInfo[MAXPLAYERS + 1][MAX_LINE_WIDTH];

// When an admin calls for clear database, the client id is stored here for a period of time.
// The admin must then call the clear command again to confirm the call. After the second call
// the database is cleared. The confirm must be done in the time set by CLEAR_DATABASE_CONFIRMTIME.
new ClearDatabaseCaller = -1;
//new Handle:ClearPlayerMenu = INVALID_HANDLE;

// Create handle for the admin menu
new TopMenuObject:MenuClear = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuClearPlayers = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuClearMaps = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuClearAll = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuRemoveCustomMaps = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuCleanPlayers = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuClearTimedMaps = INVALID_TOPMENUOBJECT;

// Administrative Cvars

// Players can request a vote for team shuffle based on the player ranks ONCE PER MAP
new PlayerRankVote[MAXPLAYERS + 1];

new bool:SurvivalStarted = false;

new Float:ClientMapTime[MAXPLAYERS + 1];
new MeleeKillCounter[MAXPLAYERS + 1];

#define LOG_PATH						"logs\\l4d_puntos.log"
#define LOG_PATH_TANK						"logs\\l4d_puntos_tank.log"
static String:	logfilepath[256];
static String:	logfilepath_tank[256];

// Plugin Info
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "McFlurry, Muukis and Woonan",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.com/"
};

// Here we go!
public OnPluginStart()
{

	BuildPath(Path_SM, logfilepath, sizeof(logfilepath), LOG_PATH);
	BuildPath(Path_SM, logfilepath_tank, sizeof(logfilepath), LOG_PATH_TANK);
	LogToFile(logfilepath, "l4d_puntos |               PLUGIN START                |");
    LogToFile(logfilepath_tank, "l4d_puntos |               PLUGIN START                |");	
	
//Initialize SDK Stuff
	LogToFile(logfilepath, "l4d_puntos 1");
	
	if (fhZombieAbortControl == INVALID_HANDLE)
	{
		new Handle:gConf = INVALID_HANDLE;
		gConf = LoadGameConfigFile("InfectedAPI");
		//CTerrorPlayer::PlayerZombieAbortControl(client,float=0)
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "ZombieAbortControl");
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		fhZombieAbortControl = EndPrepSDKCall();
		CloseHandle(gConf);
		if (fhZombieAbortControl == INVALID_HANDLE)
		{
			SetFailState("Infected API can't get ZombieAbortControl SDKCall!");
		}
	}
	
	LogToFile(logfilepath, "l4d_puntos 2");

	toReg = CreateArray();
	toMute = CreateArray();
	
	g_iFrustrationO = FindSendPropInfo("Tank","m_frustration");
		
	LogToFile(logfilepath, "l4d_puntos 3");
	
	CommandsRegistered = false;
	
	hostport = GetConVarInt(FindConVar("hostport"));
	
	// Require Left 4 Dead (2)
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));

	LogToFile(logfilepath, "l4d_puntos 4");
	
	if (!StrEqual(game_name, "left4dead", false) &&
			!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead and Left 4 Dead 2 only.");
		return;
	}
	
	LogToFile(logfilepath, "l4d_puntos 5");
	
	ResetAllShields();
	
	LogToFile(logfilepath, "l4d_puntos 6");
	
	ServerVersion = GuessSDKVersion();

	LogToFile(logfilepath, "l4d_puntos 7");
	
	if (ServerVersion == SERVER_VERSION_L4D1)
	{
		strcopy(StatsSound_MapTime_Start, sizeof(StatsSound_MapTime_Start), SOUND_MAPTIME_START_L4D1);
		strcopy(StatsSound_MapTime_Improve, sizeof(StatsSound_MapTime_Improve), SOUND_MAPTIME_IMPROVE_L4D1);
		strcopy(StatsSound_Rankmenu_Show, sizeof(StatsSound_Rankmenu_Show), SOUND_RANKMENU_SHOW_L4D1);
		strcopy(StatsSound_Boomer_Vomit, sizeof(StatsSound_Boomer_Vomit), SOUND_BOOMER_VOMIT_L4D1);
		strcopy(StatsSound_Hunter_Perfect, sizeof(StatsSound_Hunter_Perfect), SOUND_HUNTER_PERFECT_L4D1);
		strcopy(StatsSound_Tank_Bulldozer, sizeof(StatsSound_Tank_Bulldozer), SOUND_TANK_BULLDOZER_L4D1);
		LogToFile(logfilepath, "l4d_puntos 8 1");
	}
	else
	{
		strcopy(StatsSound_MapTime_Start, sizeof(StatsSound_MapTime_Start), SOUND_MAPTIME_START_L4D2);
		strcopy(StatsSound_MapTime_Improve, sizeof(StatsSound_MapTime_Improve), SOUND_MAPTIME_IMPROVE_L4D2);
		strcopy(StatsSound_Rankmenu_Show, sizeof(StatsSound_Rankmenu_Show), SOUND_RANKMENU_SHOW_L4D2);
		strcopy(StatsSound_Boomer_Vomit, sizeof(StatsSound_Boomer_Vomit), SOUND_BOOMER_VOMIT_L4D2);
		strcopy(StatsSound_Hunter_Perfect, sizeof(StatsSound_Hunter_Perfect), SOUND_HUNTER_PERFECT_L4D2);
		strcopy(StatsSound_Tank_Bulldozer, sizeof(StatsSound_Tank_Bulldozer), SOUND_TANK_BULLDOZER_L4D2);
		LogToFile(logfilepath, "l4d_puntos 8 2");
	}
	
		
	LogToFile(logfilepath, "l4d_puntos 9");
	
	g_iAbilityO			=	FindSendPropInfo("CTerrorPlayer","m_customAbility");
	// Plugin version public Cvar
	CreateConVar("l4d_puntos_version", PLUGIN_VERSION, "Custom Player Stats Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	LogToFile(logfilepath, "l4d_puntos 10");
	
	// Disable setting Cvars
	cvar_Difficulty = FindConVar("z_difficulty");
	cvar_Gamemode = FindConVar("mp_gamemode");
	cvar_Cheats = FindConVar("sv_cheats");

	LogToFile(logfilepath, "l4d_puntos 11");
	
	cvar_Lan = FindConVar("sv_lan");
	if (GetConVarInt(cvar_Lan))
		LogMessage("ATTENTION! %s in LAN environment is based on IP address rather than Steam ID. The statistics are not reliable when they are base on IP!", PLUGIN_NAME);

	HookConVarChange(cvar_Lan, action_LanChanged);

	cvar_SurvivorLimit = FindConVar("survivor_limit");
	cvar_InfectedLimit = FindConVar("z_max_player_zombies");

	// Administrative Cvars
	cvar_AdminPlayerCleanLastOnTime = CreateConVar("l4d_puntos_adm_cleanoldplayers", "2", "How many months old players (last online time) will be cleaned. 0 = Disabled", FCVAR_PLUGIN, true, 0.0);
	cvar_AdminPlayerCleanPlatime = CreateConVar("l4d_puntos_adm_cleanplaytime", "30", "How many minutes of playtime to not get cleaned from stats. 0 = Disabled", FCVAR_PLUGIN, true, 0.0);

	LogToFile(logfilepath, "l4d_puntos 12");
	
	// Config/control Cvars
	cvar_EnableRankVote = CreateConVar("l4d_puntos_enablerankvote", "1", "Enable voting of team shuffle by player PPM (Points Per Minute)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_HumansNeeded = CreateConVar("l4d_puntos_minhumans", "2", "Minimum Human players before stats will be enabled", FCVAR_PLUGIN, true, 1.0, true, 4.0);
	cvar_UpdateRate = CreateConVar("l4d_puntos_updaterate", "90", "Number of seconds between Common Infected point earn announcement/update", FCVAR_PLUGIN, true, 30.0);
	//cvar_AnnounceRankMinChange = CreateConVar("l4d_puntos_announcerankminpoint", "500", "Minimum change to points before rank change announcement", FCVAR_PLUGIN, true, 0.0);
	cvar_AnnounceRankChange = CreateConVar("l4d_puntos_announcerank", "1", "Chat announcment for rank change", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_AnnounceRankChangeIVal = CreateConVar("l4d_puntos_announcerankinterval", "60", "Rank change check interval", FCVAR_PLUGIN, true, 10.0);
	cvar_AnnounceMode = CreateConVar("l4d_puntos_announcemode", "1", "Chat announcment mode. 0 = Off, 1 = Player Only, 2 = Player Only w/ Public Headshots, 3 = All Public", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	cvar_AnnounceToTeam = CreateConVar("l4d_puntos_announceteam", "2", "Chat announcment team messages to the team only mode. 0 = Print messages to all teams, 1 = Print messages to own team only, 2 = Print messages to own team and spectators only", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	//cvar_AnnounceSpecial = CreateConVar("l4d_puntos_announcespecial", "1", "Chat announcment mode for special events. 0 = Off, 1 = Player Only, 2 = Print messages to all teams, 3 = Print messages to own team only, 4 = Print messages to own team and spectators only", FCVAR_PLUGIN, true, 0.0, true, 4.0);
	cvar_MedkitMode = CreateConVar("l4d_puntos_medkitmode", "0", "Medkit point award mode. 0 = Based on amount healed, 1 = Static amount", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_SiteURL = CreateConVar("l4d_puntos_siteurl", "", "Community site URL, for rank panel display", FCVAR_PLUGIN);
	cvar_RankOnJoin = CreateConVar("l4d_puntos_rankonjoin", "1", "Display player's rank when they connect. 0 = Disable, 1 = Enable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_SilenceChat = CreateConVar("l4d_puntos_silencechat", "0", "Silence chat triggers. 0 = Show chat triggers, 1 = Silence chat triggers", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_DisabledMessages = CreateConVar("l4d_puntos_disabledmessages", "1", "Show 'Stats Disabled' messages, allow chat commands to work when stats disabled. 0 = Hide messages/disable chat, 1 = Show messages/allow chat", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	//cvar_MaxPoints = CreateConVar("l4d_puntos_maxpoints", "500", "Maximum number of points that can be earned in a single map. Normal = x1, Adv = x2, Expert = x3", FCVAR_PLUGIN, true, 500.0);
	cvar_DbPrefix = CreateConVar("l4d_puntos_dbprefix", "", "Prefix for your stats tables", FCVAR_PLUGIN);
	//cvar_LeaderboardTime = CreateConVar("l4d_puntos_leaderboardtime", "14", "Time in days to show Survival Leaderboard times", FCVAR_PLUGIN, true, 1.0);
	cvar_EnableNegativeScore = CreateConVar("l4d_puntos_enablenegativescore", "1", "Enable point losses (negative score)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_FriendlyFireMode = CreateConVar("l4d_puntos_ffire_mode", "2", "Friendly fire mode. 0 = Normal, 1 = Cooldown, 2 = Damage based", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvar_FriendlyFireMultiplier = CreateConVar("l4d_puntos_ffire_multiplier", "1.5", "Friendly fire damage multiplier (Formula: Score = Damage * Multiplier)", FCVAR_PLUGIN, true, 0.0);
	cvar_FriendlyFireCooldown = CreateConVar("l4d_puntos_ffire_cooldown", "10.0", "Time in seconds for friendly fire cooldown", FCVAR_PLUGIN, true, 1.0);
	cvar_FriendlyFireCooldownMode = CreateConVar("l4d_puntos_ffire_cooldownmode", "1", "Friendly fire cooldown mode. 0 = Disable, 1 = Player specific, 2 = General", FCVAR_PLUGIN, true, 0.0, true, 2.0);

	LogToFile(logfilepath, "l4d_puntos 13");
	
	// Game mode Cvars
	cvar_Enable = CreateConVar("l4d_puntos_enable", "1", "Enable/Disable all stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableCoop = CreateConVar("l4d_puntos_enablecoop", "1", "Enable/Disable coop stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableSv = CreateConVar("l4d_puntos_enablesv", "1", "Enable/Disable survival stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableVersus = CreateConVar("l4d_puntos_enableversus", "1", "Enable/Disable versus stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableTeamVersus = CreateConVar("l4d_puntos_enableteamversus", "1", "[L4D2] Enable/Disable team versus stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableRealism = CreateConVar("l4d_puntos_enablerealism", "1", "[L4D2] Enable/Disable realism stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableScavenge = CreateConVar("l4d_puntos_enablescavenge", "1", "[L4D2] Enable/Disable scavenge stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableTeamScavenge = CreateConVar("l4d_puntos_enableteamscavenge", "1", "[L4D2] Enable/Disable team scavenge stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableRealismVersus = CreateConVar("l4d_puntos_enablerealismvs", "1", "[L4D2] Enable/Disable realism versus stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableTeamRealismVersus = CreateConVar("l4d_puntos_enableteamrealismvs", "1", "[L4D2] Enable/Disable team realism versus stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableMutations = CreateConVar("l4d_puntos_enablemutations", "1", "[L4D2] Enable/Disable mutations stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Game mode depended Cvars
	cvar_RealismMultiplier = CreateConVar("l4d_puntos_realismmultiplier", "1.4", "[L4D2] Realism score multiplier for coop score", FCVAR_PLUGIN, true, 1.0);
	cvar_RealismVersusSurMultiplier = CreateConVar("l4d_puntos_realismvsmultiplier_s", "1.4", "[L4D2] Realism score multiplier for survivors versus score", FCVAR_PLUGIN, true, 1.0);
	cvar_RealismVersusInfMultiplier = CreateConVar("l4d_puntos_realismvsmultiplier_i", "0.6", "[L4D2] Realism score multiplier for infected versus score", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableSvMedicPoints = CreateConVar("l4d_puntos_medicpointssv", "0", "Survival medic points enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Infected point Cvars
	cvar_Infected = CreateConVar("l4d_puntos_infected", "1", "Base score for killing a Common Infected", FCVAR_PLUGIN, true, 1.0);
	cvar_Hunter = CreateConVar("l4d_puntos_hunter", "2", "Base score for killing a Hunter", FCVAR_PLUGIN, true, 1.0);
	cvar_Smoker = CreateConVar("l4d_puntos_smoker", "3", "Base score for killing a Smoker", FCVAR_PLUGIN, true, 1.0);
	cvar_Boomer = CreateConVar("l4d_puntos_boomer", "5", "Base score for killing a Boomer", FCVAR_PLUGIN, true, 1.0);
	cvar_Spitter = CreateConVar("l4d_puntos_spitter", "5", "[L4D2] Base score for killing a Spitter", FCVAR_PLUGIN, true, 1.0);
	cvar_Jockey = CreateConVar("l4d_puntos_jockey", "5", "[L4D2] Base score for killing a Jockey", FCVAR_PLUGIN, true, 1.0);
	cvar_Charger = CreateConVar("l4d_puntos_charger", "5", "[L4D2] Base score for killing a Charger", FCVAR_PLUGIN, true, 1.0);
	cvar_InfectedDamage = CreateConVar("l4d_puntos_infected_damage", "2", "The amount of damage inflicted to Survivors to earn 1 point", FCVAR_PLUGIN, true, 1.0);

	LogToFile(logfilepath, "l4d_puntos 14");
	
	// Misc personal gain Cvars
	cvar_Pills = CreateConVar("l4d_puntos_pills", "15", "Base score for giving Pills to a friendly", FCVAR_PLUGIN, true, 1.0);
	cvar_Adrenaline = CreateConVar("l4d_puntos_adrenaline", "15", "[L4D2] Base score for giving Adrenaline to a friendly", FCVAR_PLUGIN, true, 1.0);
	cvar_Medkit = CreateConVar("l4d_puntos_medkit", "20", "Base score for using a Medkit on a friendly", FCVAR_PLUGIN, true, 1.0);
	cvar_Defib = CreateConVar("l4d_puntos_defib", "20", "[L4D2] Base score for using a Defibrillator on a friendly", FCVAR_PLUGIN, true, 1.0);
	cvar_SmokerDrag = CreateConVar("l4d_puntos_smokerdrag", "5", "Base score for saving a friendly from a Smoker Tongue Drag", FCVAR_PLUGIN, true, 1.0);
	cvar_JockeyRide = CreateConVar("l4d_puntos_jockeyride", "10", "[L4D2] Base score for saving a friendly from a Jockey Ride", FCVAR_PLUGIN, true, 1.0);
	cvar_ChargerPlummel = CreateConVar("l4d_puntos_chargerplummel", "10", "[L4D2] Base score for saving a friendly from a Charger Plummel", FCVAR_PLUGIN, true, 1.0);
	cvar_ChargerCarry = CreateConVar("l4d_puntos_chargercarry", "15", "[L4D2] Base score for saving a friendly from a Charger Carry", FCVAR_PLUGIN, true, 1.0);
	cvar_ChokePounce = CreateConVar("l4d_puntos_chokepounce", "10", "Base score for saving a friendly from a Hunter Pounce / Smoker Choke", FCVAR_PLUGIN, true, 1.0);
	cvar_Revive = CreateConVar("l4d_puntos_revive", "15", "Base score for Revive a friendly from Incapacitated state", FCVAR_PLUGIN, true, 1.0);
	cvar_Rescue = CreateConVar("l4d_puntos_rescue", "10", "Base score for Rescue a friendly from a closet", FCVAR_PLUGIN, true, 1.0);
	cvar_Protect = CreateConVar("l4d_puntos_protect", "3", "Base score for Protect a friendly in combat", FCVAR_PLUGIN, true, 1.0);
	cvar_PlayerLedgeSuccess = CreateConVar("l4d_puntos_ledgegrap", "15", "Base score for causing a survivor to grap a ledge", FCVAR_PLUGIN, true, 1.0);
	cvar_Matador = CreateConVar("l4d_puntos_matador", "30", "[L4D2] Base score for killing a charging Charger with a melee weapon", FCVAR_PLUGIN, true, 1.0);
	cvar_WitchCrowned = CreateConVar("l4d_puntos_witchcrowned", "30", "Base score for Crowning a Witch", FCVAR_PLUGIN, true, 1.0);

	// Team gain Cvars
	cvar_Tank = CreateConVar("l4d_puntos_tank", "25", "Base team score for killing a Tank", FCVAR_PLUGIN, true, 1.0);
	cvar_Panic = CreateConVar("l4d_puntos_panic", "25", "Base team score for surviving a Panic Event with no Incapacitations", FCVAR_PLUGIN, true, 1.0);
	cvar_BoomerMob = CreateConVar("l4d_puntos_boomermob", "10", "Base team score for surviving a Boomer Mob with no Incapacitations", FCVAR_PLUGIN, true, 1.0);
	cvar_SafeHouse = CreateConVar("l4d_puntos_safehouse", "10", "Base score for reaching a Safe House", FCVAR_PLUGIN, true, 1.0);
	cvar_Witch = CreateConVar("l4d_puntos_witch", "10", "Base score for Not Disturbing a Witch", FCVAR_PLUGIN, true, 1.0);
	cvar_VictorySurvivors = CreateConVar("l4d_puntos_campaign", "5", "Base score for Completing a Campaign", FCVAR_PLUGIN, true, 1.0);
	cvar_VictoryInfected = CreateConVar("l4d_puntos_infected_win", "30", "Base victory score for Infected Team", FCVAR_PLUGIN, true, 1.0);

	// Point loss Cvars
	cvar_FFire = CreateConVar("l4d_puntos_ffire", "25", "Base score for Friendly Fire", FCVAR_PLUGIN, true, 1.0);
	cvar_FIncap = CreateConVar("l4d_puntos_fincap", "75", "Base score for a Friendly Incap", FCVAR_PLUGIN, true, 1.0);
	cvar_FKill = CreateConVar("l4d_puntos_fkill", "250", "Base score for a Friendly Kill", FCVAR_PLUGIN, true, 1.0);
	cvar_InSafeRoom = CreateConVar("l4d_puntos_insaferoom", "5", "Base score for letting Infected in the Safe Room", FCVAR_PLUGIN, true, 1.0);
	cvar_Restart = CreateConVar("l4d_puntos_restart", "100", "Base score for a Round Restart", FCVAR_PLUGIN, true, 1.0);
	cvar_MedkitUsedPointPenalty = CreateConVar("l4d_puntos_medkitpenalty", "0.1", "Score reduction for all Survivor earned points for each used Medkit (Formula: Score = NormalPoints * (1 - MedkitsUsed * MedkitPenalty))", FCVAR_PLUGIN, true, 0.0, true, 0.5);
	cvar_MedkitUsedPointPenaltyMax = CreateConVar("l4d_puntos_medkitpenaltymax", "1.0", "Maximum score reduction (the score reduction will not go over this value when a Medkit is used)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MedkitUsedFree = CreateConVar("l4d_puntos_medkitpenaltyfree", "0", "Team Survivors can use this many Medkits for free without any reduction to the score", FCVAR_PLUGIN, true, 0.0);
	cvar_MedkitUsedRealismFree = CreateConVar("l4d_puntos_medkitpenaltyfree_r", "4", "Team Survivors can use this many Medkits for free without any reduction to the score when playing in Realism gamemodes (-1 = use the value in l4d_puntos_medkitpenaltyfree)", FCVAR_PLUGIN, true, -1.0);
	cvar_MedkitBotMode = CreateConVar("l4d_puntos_medkitbotmode", "1", "Add score reduction when bot uses a medkit. 0 = No, 1 = Bot uses a Medkit to a human player, 2 = Bot uses a Medkit to other than itself, 3 = Yes", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvar_CarAlarm = CreateConVar("l4d_puntos_caralarm", "50", "[L4D2] Base score for a Triggering Car Alarm", FCVAR_PLUGIN, true, 1.0);
	cvar_BotScoreMultiplier = CreateConVar("l4d_puntos_botscoremultiplier", "1.0", "Multiplier to use when receiving bot related score penalty. 0 = Disable", FCVAR_PLUGIN, true, 0.0);

	LogToFile(logfilepath, "l4d_puntos 15");
	
	// Survivor point Cvars
	cvar_SurvivorDeath = CreateConVar("l4d_puntos_survivor_death", "40", "Base score for killing a Survivor", FCVAR_PLUGIN, true, 1.0);
	cvar_SurvivorIncap = CreateConVar("l4d_puntos_survivor_incap", "15", "Base score for incapacitating a Survivor", FCVAR_PLUGIN, true, 1.0);

	// Hunter point Cvars
	cvar_HunterPerfectPounceDamage = CreateConVar("l4d_puntos_perfectpouncedamage", "25", "The amount of damage from a pounce to earn Perfect Pounce (Death From Above) success points", FCVAR_PLUGIN, true, 1.0);
	cvar_HunterPerfectPounceSuccess = CreateConVar("l4d_puntos_perfectpouncesuccess", "25", "Base score for a successful Perfect Pounce", FCVAR_PLUGIN, true, 1.0);
	cvar_HunterNicePounceDamage = CreateConVar("l4d_puntos_nicepouncedamage", "15", "The amount of damage from a pounce to earn Nice Pounce (Pain From Above) success points", FCVAR_PLUGIN, true, 1.0);
	cvar_HunterNicePounceSuccess = CreateConVar("l4d_puntos_nicepouncesuccess", "10", "Base score for a successful Nice Pounce", FCVAR_PLUGIN, true, 1.0);
	cvar_HunterDamageCap = CreateConVar("l4d_puntos_hunterdamagecap", "25", "Hunter stored damage cap", FCVAR_PLUGIN, true, 25.0);

	LogToFile(logfilepath, "l4d_puntos 16");
	
	if (ServerVersion == SERVER_VERSION_L4D1)
	{
		MaxPounceDistance = GetConVarInt(FindConVar("z_pounce_damage_range_max"));
		MinPounceDistance = GetConVarInt(FindConVar("z_pounce_damage_range_min"));
	}
	else
	{
		MaxPounceDistance = 1024;
		MinPounceDistance = 300;
	}
	MaxPounceDamage = GetConVarInt(FindConVar("z_hunter_max_pounce_bonus_damage"));
		
	// Boomer point Cvars
	cvar_BoomerSuccess = CreateConVar("l4d_puntos_boomersuccess", "5", "Base score for a successfully vomiting on survivor", FCVAR_PLUGIN, true, 1.0);
	cvar_BoomerPerfectHits = CreateConVar("l4d_puntos_boomerperfecthits", "4", "The number of survivors that needs to get blinded to earn Boomer Perfect Vomit Award and success points", FCVAR_PLUGIN, true, 4.0);
	cvar_BoomerPerfectSuccess = CreateConVar("l4d_puntos_boomerperfectsuccess", "30", "Base score for a successful Boomer Perfect Vomit", FCVAR_PLUGIN, true, 1.0);

	// Tank point Cvars
	cvar_TankDamageCap = CreateConVar("l4d_puntos_tankdmgcap", "500", "Maximum inflicted damage done by Tank to earn Infected damagepoints", FCVAR_PLUGIN, true, 150.0);
	cvar_TankDamageTotal = CreateConVar("l4d_puntos_bulldozer", "200", "Damage inflicted by Tank to earn Bulldozer Award and success points", FCVAR_PLUGIN, true, 200.0);
	cvar_TankDamageTotalSuccess = CreateConVar("l4d_puntos_bulldozersuccess", "50", "Base score for Bulldozer Award", FCVAR_PLUGIN, true, 1.0);
	cvar_TankThrowRockSuccess = CreateConVar("l4d_puntos_tankthrowrocksuccess", "5", "Base score for a Tank thrown rock hit", FCVAR_PLUGIN, true, 0.0);

	// Charger point Cvars
	cvar_ChargerRamSuccess = CreateConVar("l4d_puntos_chargerramsuccess", "40", "Base score for a successful Charger Scattering Ram", FCVAR_PLUGIN, true, 1.0);
	cvar_ChargerRamHits = CreateConVar("l4d_puntos_chargerramhits", "4", "The number of impacts on survivors to earn Scattering Ram Award and success points", FCVAR_PLUGIN, true, 2.0);

	// Misc L4D2 Cvars
	cvar_AmmoUpgradeAdded = CreateConVar("l4d_puntos_deployammoupgrade", "10", "[L4D2] Base score for deploying ammo upgrade pack", FCVAR_PLUGIN, true, 0.0);
	cvar_GascanPoured = CreateConVar("l4d_puntos_gascanpoured", "5", "[L4D2] Base score for successfully pouring a gascan", FCVAR_PLUGIN, true, 0.0);

	LogToFile(logfilepath, "l4d_puntos 17");
	
	// Other Cvars
	cvar_Top10PPMMin = CreateConVar("l4d_puntos_top10ppmplaytime", "30", "Minimum playtime (minutes) to show in top10 ppm list", FCVAR_PLUGIN, true, 1.0);
	cvar_RankVoteTime = CreateConVar("l4d_puntos_rankvotetime", "20", "Time to wait people to vote", FCVAR_PLUGIN, true, 10.0);

	cvar_SoundsEnabled = CreateConVar("l4d_puntos_soundsenabled", "1", "Play sounds on certain events", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Make that config!
	AutoExecConfig(true, "l4d_puntos");

	// Personal Gain Events
		// Startup the plugin's timers
		
	UpdateTimer = CreateTimer(GetConVarFloat(cvar_UpdateRate), timer_ShowTimerScore, INVALID_HANDLE, TIMER_REPEAT);
	HookConVarChange(cvar_UpdateRate, action_TimerChanged);
	HookConVarChange(cvar_DbPrefix, action_DbPrefixChanged);

	LogToFile(logfilepath, "l4d_puntos 18");
	
	// Gamemode
	GetConVarString(cvar_Gamemode, CurrentGamemode, sizeof(CurrentGamemode));
	CurrentGamemodeID = GetCurrentGamemodeID();
	SetCurrentGamemodeName();
	HookConVarChange(cvar_Gamemode, action_GamemodeChanged);
	HookConVarChange(cvar_Difficulty, action_DifficultyChanged);

	//RegConsoleCmd("l4d_puntos_test", cmd_StatsTest);
		
	MapTimingSurvivors = CreateTrie();
	MapTimingInfected = CreateTrie();
	FriendlyFireDamageTrie = CreateTrie();
	PlayerRankVoteTrie = CreateTrie();

	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);

	LogToFile(logfilepath, "l4d_puntos 19");
		
	if (FileExists("addons/sourcemod/gamedata/l4d_puntos.txt"))
	{
		// SDK handles for team shuffle
		L4DStatsConf = LoadGameConfigFile("l4d_puntos");
		if (L4DStatsConf == INVALID_HANDLE)
			LogError("Could not load gamedata/l4d_puntos.txt");
		else
		{
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(L4DStatsConf, SDKConf_Signature, "SetHumanSpec");
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			L4DStatsSHS = EndPrepSDKCall();

			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(L4DStatsConf, SDKConf_Signature, "TakeOverBot");
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			L4DStatsTOB = EndPrepSDKCall();
		}
	}
	else
		LogMessage("Rank Vote is disabled because could not load gamedata/l4d_puntos.txt");

	LogToFile(logfilepath, "l4d_puntos 20");
		
	// Sounds
	if (!IsSoundPrecached(SOUND_RANKVOTE))
		EnableSounds_Rankvote = PrecacheSound(SOUND_RANKVOTE); // Sound from rankvote team switch
	else
		EnableSounds_Rankvote = true;

	PrecacheSound(HORDE); // Sound map timer start
		
	if (!IsSoundPrecached(StatsSound_MapTime_Start))
		EnableSounds_Maptime_Start = PrecacheSound(StatsSound_MapTime_Start); // Sound map timer start
	else
		EnableSounds_Maptime_Start = true;

	if (!IsSoundPrecached(StatsSound_MapTime_Improve))
		EnableSounds_Maptime_Improve = PrecacheSound(StatsSound_MapTime_Improve); // Sound from improving personal map timing
	else
		EnableSounds_Maptime_Improve = true;

	if (!IsSoundPrecached(StatsSound_Rankmenu_Show))
		EnableSounds_Rankmenu_Show = PrecacheSound(StatsSound_Rankmenu_Show); // Sound from showing the rankmenu
	else
		EnableSounds_Rankmenu_Show = true;

	if (!IsSoundPrecached(StatsSound_Boomer_Vomit))
		EnableSounds_Boomer_Vomit = PrecacheSound(StatsSound_Boomer_Vomit); // Sound from a successful boomer vomit (Perfect Blindness)
	else
		EnableSounds_Boomer_Vomit = true;

	if (!IsSoundPrecached(StatsSound_Hunter_Perfect))
		EnableSounds_Hunter_Perfect = PrecacheSound(StatsSound_Hunter_Perfect); // Sound from a hunter perfect pounce (Death From Above)
	else
		EnableSounds_Hunter_Perfect = true;

	if (!IsSoundPrecached(StatsSound_Tank_Bulldozer))
		EnableSounds_Tank_Bulldozer = PrecacheSound(StatsSound_Tank_Bulldozer); // Sound from a tank bulldozer
	else
		EnableSounds_Tank_Bulldozer = true;

	LogToFile(logfilepath, "l4d_puntos 21");
		
	if (ServerVersion != SERVER_VERSION_L4D1)
	{
		if (!IsSoundPrecached(SOUND_CHARGER_RAM))
			EnableSounds_Charger_Ram = PrecacheSound(SOUND_CHARGER_RAM); // Sound from a charger scattering ram
		else
			EnableSounds_Charger_Ram = true;
	}
	else
		EnableSounds_Charger_Ram = false;
		
	//points start
	
	LogToFile(logfilepath, "l4d_puntos 22");
	
	//new String:game_name[128];
	GetGameFolderName(game_name, sizeof(game_name));
	if(!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("This plugin only supports Left 4 Dead 2");
	}	
	
	//LoadTranslations("common.phrases");
	LoadTranslations("l4d_puntos");
	
	LogToFile(logfilepath, "l4d_stats 23");
	
	CreateConVar("l4d2_points_sys_version", PLUGIN_TITLE, "Version of Points System on this server.", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	StartPoints = CreateConVar("l4d2_points_start", "0", "Points to start each round/map with.", FCVAR_PLUGIN);
	Notifications = CreateConVar("l4d2_points_notify", "1", "Show messages when points are earned?", FCVAR_PLUGIN);
	Enable = CreateConVar("l4d2_points_enable", "1", "Enable Point System?", FCVAR_PLUGIN);
	Modes = CreateConVar("l4d2_points_modes", "coop,realism,versus,teamversus", "Which game modes to use Point System", FCVAR_PLUGIN);
	ResetPoints = CreateConVar("l4d2_points_reset_mapchange", "versus,teamversus", "Which game modes to reset point count on round end and round start", FCVAR_PLUGIN);
	TankLimit = CreateConVar("l4d2_points_tank_limit", "2", "How many tanks to be allowed spawned per team", FCVAR_PLUGIN);
	WitchLimit = CreateConVar("l4d2_points_witch_limit", "3", "How many witchs' to be allwed spawned per team", FCVAR_PLUGIN);
	PointsPistol = CreateConVar("l4d2_points_pistol", "4", "How many points the pistol costs", FCVAR_PLUGIN);
	PointsSMG = CreateConVar("l4d2_points_smg", "7", "How many points the smg costs", FCVAR_PLUGIN);
	PointsM16 = CreateConVar("l4d2_points_m16", "12", "How many points the m16 costs", FCVAR_PLUGIN);
	PointsHunting = CreateConVar("l4d2_points_hunting_rifle", "10", "How many points the hunting rifle costs", FCVAR_PLUGIN);
	PointsAuto = CreateConVar("l4d2_points_autoshotgun", "10", "How many points the autoshotgun costs", FCVAR_PLUGIN);
	PointsPump = CreateConVar("l4d2_points_pump", "7", "How many points the pump shotgun costs", FCVAR_PLUGIN);
	PointsGasCan = CreateConVar("l4d2_points_gascan", "5", "How many points the gas can costs", FCVAR_PLUGIN);
	PointsPropane = CreateConVar("l4d2_points_propane", "2", "How many points the propane tank costs", FCVAR_PLUGIN);
	PointsMagnum = CreateConVar("l4d2_points_magnum", "6", "How many points the magnum costs", FCVAR_PLUGIN);
	PointsSSMG = CreateConVar("l4d2_points_ssmg", "7", "How many points the silenced smg costs", FCVAR_PLUGIN);
	PointsMP5 = CreateConVar("l4d2_points_mp5", "7", "How many points the mp5 costs", FCVAR_PLUGIN);
	PointsAK = CreateConVar("l4d2_points_ak", "12", "How many points the ak47 costs", FCVAR_PLUGIN);
	PointsSCAR = CreateConVar("l4d2_points_scar", "12", "How many points the scar costs", FCVAR_PLUGIN);
	PointsSG = CreateConVar("l4d2_points_sg", "12", "How many points the sg552 costs", FCVAR_PLUGIN);
	PointsMilitary = CreateConVar("l4d2_points_military_sniper", "14", "How many points the military sniper costs", FCVAR_PLUGIN);
	PointsAWP = CreateConVar("l4d2_points_awp", "15", "How many points the awp costs", FCVAR_PLUGIN);
	PointsScout = CreateConVar("l4d2_points_scout", "10", "How many points the scout sniper costs", FCVAR_PLUGIN);
	PointsSpas = CreateConVar("l4d2_points_spas", "10", "How many points the spas shotgun costs", FCVAR_PLUGIN);
	PointsChrome = CreateConVar("l4d2_points_chrome", "7", "How many points the chrome shotgun costs", FCVAR_PLUGIN);
	PointsGL = CreateConVar("l4d2_points_grenade", "15", "How many points the grenade launcher costs", FCVAR_PLUGIN);
	PointsM60 = CreateConVar("l4d2_points_m60", "50", "How many points the m60 costs", FCVAR_PLUGIN);
	PointsOxy = CreateConVar("l4d2_points_oxygen", "2", "How many points the oxgen tank costs", FCVAR_PLUGIN);
	PointsGnome = CreateConVar("l4d2_points_gnome", "8", "How many points the gnome costs", FCVAR_PLUGIN);
	PointsCola = CreateConVar("l4d2_points_cola", "8", "How many points cola bottles costs", FCVAR_PLUGIN);
	PointsFireWorks = CreateConVar("l4d2_points_fireworks", "2", "How many points the fireworks crate costs", FCVAR_PLUGIN);
	PointsBat = CreateConVar("l4d2_points_bat", "4", "How many points the baseball bat costs", FCVAR_PLUGIN);
	PointsMachete = CreateConVar("l4d2_points_machete", "6", "How many points the machete costs", FCVAR_PLUGIN);
	PointsKatana = CreateConVar("l4d2_points_katana", "6", "How many points the katana costs", FCVAR_PLUGIN);
	PointsTonfa = CreateConVar("l4d2_points_tonfa", "4", "How many points the tonfa costs", FCVAR_PLUGIN);
	PointsFireaxe = CreateConVar("l4d2_points_fireaxe", "4", "How many points the fireaxe costs", FCVAR_PLUGIN);
	PointsGuitar = CreateConVar("l4d2_points_guitar", "4", "How many points the guitar costs", FCVAR_PLUGIN);
	PointsPan = CreateConVar("l4d2_points_pan", "4", "How many points the frying pan costs", FCVAR_PLUGIN);
	PointsCBat = CreateConVar("l4d2_points_cricketbat", "4", "How many points the cricket bat costs", FCVAR_PLUGIN);
	PointsCrow = CreateConVar("l4d2_points_crowbar", "4", "How many points the crowbar costs", FCVAR_PLUGIN);
	PointsClub = CreateConVar("l4d2_points_golfclub", "6", "How many points the golf club costs", FCVAR_PLUGIN);
	PointsSaw = CreateConVar("l4d2_points_chainsaw", "10", "How many points the chainsaw costs", FCVAR_PLUGIN);
	PointsPipe = CreateConVar("l4d2_points_pipe", "8", "How many points the pipe bomb costs", FCVAR_PLUGIN);
	PointsMolly = CreateConVar("l4d2_points_molotov", "8", "How many points the molotov costs", FCVAR_PLUGIN);
	PointsBile = CreateConVar("l4d2_points_bile", "8", "How many points the bile jar costs", FCVAR_PLUGIN);
	PointsKit = CreateConVar("l4d2_points_kit", "20", "How many points the health kit costs", FCVAR_PLUGIN);
	PointsDefib = CreateConVar("l4d2_points_defib", "20", "How many points the defib costs", FCVAR_PLUGIN);
	PointsAdren = CreateConVar("l4d2_points_adrenaline", "10", "How many points the adrenaline costs", FCVAR_PLUGIN);
	PointsPills = CreateConVar("l4d2_points_pills", "10", "How many points the pills costs", FCVAR_PLUGIN);
	PointsEAmmo = CreateConVar("l4d2_points_explosive_ammo", "10", "How many points the explosive ammo costs", FCVAR_PLUGIN);
	PointsIAmmo = CreateConVar("l4d2_points_incendiary_ammo", "10", "How many points the incendiary ammo costs", FCVAR_PLUGIN);
	PointsEAmmoPack = CreateConVar("l4d2_points_explosive_ammo_pack", "15", "How many points the explosive ammo pack costs", FCVAR_PLUGIN);
	PointsIAmmoPack = CreateConVar("l4d2_points_incendiary_ammo_pack", "15", "How many points the incendiary ammo pack costs", FCVAR_PLUGIN);
	PointsLSight = CreateConVar("l4d2_points_laser", "10", "How many points the laser sight costs", FCVAR_PLUGIN);
	PointsHeal = CreateConVar("l4d2_points_survivor_heal", "25", "How many points a complete heal costs", FCVAR_PLUGIN);
	PointsRefill = CreateConVar("l4d2_points_refill", "8", "How many points an ammo refill costs", FCVAR_PLUGIN);
	SValueKillingSpree = CreateConVar("l4d2_points_cikill_value", "2", "How many points does killing a certain amount of infected earn", FCVAR_PLUGIN);
	SNumberKill = CreateConVar("l4d2_points_cikills", "25", "How many kills you need to earn a killing spree bounty", FCVAR_PLUGIN);
	SValueHeadSpree = CreateConVar("l4d2_points_headshots_value", "4", "How many points does killing a certain amount of infected with headshots earn", FCVAR_PLUGIN);
	SNumberHead = CreateConVar("l4d2_points_headshots", "20", "How many kills you need to earn a killing spree bounty", FCVAR_PLUGIN);
	SSIKill = CreateConVar("l4d2_points_sikill", "1", "How many points does killing a special infected earn", FCVAR_PLUGIN);
	STankKill = CreateConVar("l4d2_points_tankkill", "2", "How many points does killing a tank earn", FCVAR_PLUGIN);
	SWitchKill = CreateConVar("l4d2_points_witchkill", "4", "How many points does killing a witch earn", FCVAR_PLUGIN);
	SWitchCrown = CreateConVar("l4d2_points_witchcrown", "2", "How many points does crowning a witch earn", FCVAR_PLUGIN);
	SHeal = CreateConVar("l4d2_points_heal", "5", "How many points does healing a team mate earn", FCVAR_PLUGIN);
	SProtect = CreateConVar("l4d2_points_protect", "1", "How many points does protecting a team mate earn", FCVAR_PLUGIN);
	SRevive = CreateConVar("l4d2_points_revive", "3", "How many points does reviving a team mate earn", FCVAR_PLUGIN);
	SLedge = CreateConVar("l4d2_points_ledge", "1", "How many points does reviving a hanging team mate earn", FCVAR_PLUGIN);
	SDefib = CreateConVar("l4d2_points_defib_action", "5", "How many points does defibbing a team mate earn", FCVAR_PLUGIN);
	STBurn = CreateConVar("l4d2_points_tankburn", "2", "How many points does burning a tank earn", FCVAR_PLUGIN);
	STSolo = CreateConVar("l4d2_points_tanksolo", "8", "How many points does killing a tank single-handedly earn", FCVAR_PLUGIN);
	SWBurn = CreateConVar("l4d2_points_witchburn", "1", "How many points does burning a witch earn", FCVAR_PLUGIN);
	STag = CreateConVar("l4d2_points_bile_tank", "2", "How many points does biling a tank earn", FCVAR_PLUGIN);
	IChoke = CreateConVar("l4d2_points_smoke", "2", "How many points does smoking a survivor earn", FCVAR_PLUGIN);
	IPounce = CreateConVar("l4d2_points_pounce", "1", "How many points does pouncing a survivor earn", FCVAR_PLUGIN);
	ICarry = CreateConVar("l4d2_points_charge", "2", "How many points does charging a survivor earn", FCVAR_PLUGIN);
	IImpact = CreateConVar("l4d2_points_impact", "1", "How many points does impacting a survivor earn", FCVAR_PLUGIN);
	IRide = CreateConVar("l4d2_points_ride", "2", "How many points does riding a survivor earn", FCVAR_PLUGIN);
	ITag = CreateConVar("l4d2_points_boom", "1", "How many points does booming a survivor earn", FCVAR_PLUGIN);
	IIncap = CreateConVar("l4d2_points_incap", "3", "How many points does incapping a survivor earn", FCVAR_PLUGIN);
	IHurt = CreateConVar("l4d2_points_damage", "2", "How many points does doing damage earn", FCVAR_PLUGIN);
	IKill = CreateConVar("l4d2_points_kill", "5", "How many points does killing a survivor earn", FCVAR_PLUGIN);
	PointsSuicide = CreateConVar("l4d2_points_suicide", "4", "How many points does suicide cost", FCVAR_PLUGIN);
	PointsHunter = CreateConVar("l4d2_points_hunter", "4", "How many points does a hunter cost", FCVAR_PLUGIN);
	PointsJockey = CreateConVar("l4d2_points_jockey", "6", "How many points does a jockey cost", FCVAR_PLUGIN);
	PointsSmoker = CreateConVar("l4d2_points_smoker", "4", "How many points does a smoker cost", FCVAR_PLUGIN);
	PointsCharger = CreateConVar("l4d2_points_charger", "6", "How many points does a charger cost", FCVAR_PLUGIN);
	PointsBoomer = CreateConVar("l4d2_points_boomer", "5", "How many points does a boomer cost", FCVAR_PLUGIN);
	PointsSpitter = CreateConVar("l4d2_points_spitter", "6", "How many points does a spitter cost", FCVAR_PLUGIN);
	PointsIHeal = CreateConVar("l4d2_points_infected_heal", "6", "How many points does healing yourself as an infected cost", FCVAR_PLUGIN);
	PointsWitch = CreateConVar("l4d2_points_witch", "20", "How many points does a witch cost", FCVAR_PLUGIN);
	PointsTank = CreateConVar("l4d2_points_tank", "30", "How many points does a tank cost", FCVAR_PLUGIN);
	PointsTankHealMult = CreateConVar("l4d2_points_tank_heal_mult", "3", "How much l4d2_points_infected_heal should be multiplied for tank players", FCVAR_PLUGIN);
	PointsHorde = CreateConVar("l4d2_points_horde", "15", "How many points does a horde cost", FCVAR_PLUGIN);
	PointsMob = CreateConVar("l4d2_points_mob", "10", "How many points does a mob cost", FCVAR_PLUGIN);
	PointsUMob = CreateConVar("l4d2_points_umob", "12", "How many points does an uncommon mob cost", FCVAR_PLUGIN);
	CatRifles = CreateConVar("l4d2_points_cat_rifles", "1", "Enable rifles catergory", FCVAR_PLUGIN);
	CatSMG = CreateConVar("l4d2_points_cat_smg", "1", "Enable smg catergory", FCVAR_PLUGIN);
	CatSnipers = CreateConVar("l4d2_points_cat_snipers", "1", "Enable snipers catergory", FCVAR_PLUGIN);
	CatShotguns = CreateConVar("l4d2_points_cat_shotguns", "1", "Enable shotguns catergory", FCVAR_PLUGIN);
	CatHealth = CreateConVar("l4d2_points_cat_health", "1", "Enable health catergory", FCVAR_PLUGIN);
	CatUpgrades = CreateConVar("l4d2_points_cat_upgrades", "1", "Enable upgrades catergory", FCVAR_PLUGIN);
	CatThrowables = CreateConVar("l4d2_points_cat_throwables", "1", "Enable throwables catergory", FCVAR_PLUGIN);
	CatMisc = CreateConVar("l4d2_points_cat_misc", "1", "Enable misc catergory", FCVAR_PLUGIN);
	CatMelee = CreateConVar("l4d2_points_cat_melee", "1", "Enable melee catergory", FCVAR_PLUGIN);
	CatWeapons = CreateConVar("l4d2_points_cat_weapons", "1", "Enable weapons catergory", FCVAR_PLUGIN);
	
	LogToFile(logfilepath, "l4d_puntos 24");
	
	RegConsoleCmd("upgrade_add", UpgradeAdd_Handler);
	
	RegConsoleCmd("sm_gameframe", cmd_gameframe);
	
	RegConsoleCmd("sm_regframe", cmd_regframe);
	RegConsoleCmd("sm_showpoints", cmd_ShowPoints);
	RegConsoleCmd("sm_showfvl", cmd_ShowfVL);
	// Volas del skin
	RegConsoleCmd("sm_skins", cmd_skins);
	RegConsoleCmd("sm_lmc", cmd_skins);
	RegConsoleCmd("sm_csm", cmd_skins);
	
	RegConsoleCmd("sm_buystuff", BuyMenu);
	RegConsoleCmd("sm_listmodules", ListModules);
	RegConsoleCmd("sm_buy", BuyMenu);
	RegConsoleCmd("sm_usepoints", BuyMenu);
	RegConsoleCmd("sm_points", ShowPoints);
	RegAdminCmd("sm_heal", Command_Heal, ADMFLAG_SLAY, "sm_heal <target>");
	
	RegAdminCmd("sm_show_vars", cmd_show_vars, ADMFLAG_SLAY, "");
	RegAdminCmd("sm_showmass", cmd_showmass, ADMFLAG_SLAY, "");
	RegAdminCmd("sm_skins", cmd_skins, ADMFLAG_SLAY, "");
	
	RegAdminCmd("sm_givepoints", Command_Points, ADMFLAG_SLAY, "sm_givepoints <target> [amount]");
	RegAdminCmd("sm_setpoints", Command_SPoints, ADMFLAG_SLAY, "sm_setpoints <target> [amount]");
	RegConsoleCmd("sm_repeatbuy", Command_RBuy);
	LogToFile(logfilepath, "l4d_puntos 25");
	
	//hoooks
	HookEvent("upgrade_pack_added", Event_SpecialAmmo);
	HookEvent("upgrade_explosive_ammo", Event_ExplAmmo);
	HookEvent("upgrade_incendiary_ammo", Event_IncAmmo);
	
	HookEvent("player_use", Event_Player_Use, EventHookMode_Pre);	
		
	HookEvent("infected_death", Event_Kill);
	HookEvent("infected_death", event_InfectedDeath);
	
	HookEvent("infected_hurt", event_InfectedHurt);
	
	HookEvent("player_incapacitated", event_PlayerIncap2, EventHookMode_Pre);	
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("player_incapacitated", event_PlayerIncap);
		
	HookEvent("tank_killed", Event_TankDeath, EventHookMode_Pre);
	HookEvent("tank_killed", event_TankKilled);
	
	HookEvent("witch_killed", Event_WitchDeath);
	HookEvent("witch_killed", event_WitchCrowned);
	
	HookEvent("heal_success", Event_Heal);
	HookEvent("heal_success", event_HealPlayer);
	
	HookEvent("award_earned", Event_Protect);
	HookEvent("award_earned", event_Award_L4D2);
	
	HookEvent("revive_success", Event_Revive);
	HookEvent("revive_success", event_RevivePlayer);
	
	HookEvent("defibrillator_used", Event_Shock);
	HookEvent("defibrillator_used", event_DefibPlayer);
	
	HookEvent("player_now_it", OnVomited); //When a players gets vomited by boomer or hit by boomer's explosion
	HookEvent("player_now_it", Event_Boom);
	HookEvent("player_now_it", event_PlayerBlind);
	
	HookEvent("lunge_pounce", Event_Pounce);
	HookEvent("lunge_pounce", Event_lunge_pounce, EventHookMode_Pre);
	HookEvent("lunge_pounce", event_PlayerPounced);
	
	HookEvent("jockey_ride", Event_Ride);
	HookEvent("jockey_ride", Event_jockey_ride, EventHookMode_Pre);
	HookEvent("jockey_ride", event_JockeyStart);
		
	HookEvent("charger_carry_start", Event_Carry);
	HookEvent("charger_carry_start", event_ChargerCarryStart);
	
	HookEvent("charger_impact", Event_Impact);
	HookEvent("charger_impact", event_ChargerImpact);
	
	HookEvent("player_hurt", Event_Hurt);
	HookEvent("player_hurt", Event_PlayerHurt_Pre, EventHookMode_Pre);
	HookEvent("player_hurt", Event_PlayerHurt);
	
	HookEvent("zombie_ignited", Event_Burn);
	
	HookEvent("round_end", event_RoundEnd, EventHookMode_Pre);
	HookEvent("round_start", event_RoundStart, EventHookMode_Post);
	HookEvent("round_freeze_end", 	Event_RoundFreezeEnd, 	EventHookMode_Post);

	HookEvent("player_team", event_PlayerTeam2, EventHookMode_Pre);
	HookEvent("player_team", event_PlayerTeam, EventHookMode_Pre); // When a survivor changes team...
		
	HookEvent("pounce_end", Event_pounce_end);
	HookEvent("pounce_end", event_HunterRelease);
	
	HookEvent("jockey_ride_end", Event_jockey_ride_end);
	HookEvent("jockey_ride_end", event_JockeyRelease);
	
	HookEvent("tongue_grab", Event_tongue_grab, EventHookMode_Pre);
	HookEvent("tongue_grab", event_SmokerGrap);
	
	HookEvent("tongue_release", Event_tongue_release);
	HookEvent("tongue_release", event_SmokerRelease);
	
	HookEvent("charger_pummel_start", Event_charger_pummel_start, EventHookMode_Pre);
	HookEvent("charger_pummel_start", event_ChargerPummelStart);
	
	HookEvent("charger_pummel_end", Event_charger_pummel_end);
	HookEvent("charger_pummel_end", event_ChargerPummelRelease);

	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
	HookEvent("finale_vehicle_leaving", event_CampaignWin);
	
	HookEvent("choke_start", Event_Choke);	
	
	HookEvent("finale_win", Event_Finale);
	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("player_class", Event_Player_Class, EventHookMode_Post);
	HookEvent("player_bot_replace", player_bot_replace );	  
	HookEvent("bot_player_replace", bot_player_replace );	
	HookEvent("tank_frustrated", Event_TankFrustrated, EventHookMode_Pre);
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("heal_end", event_heal_end, EventHookMode_Post);
	HookEvent("tongue_pull_stopped", event_TongueSave);
	HookEvent("choke_stopped", event_ChokeSave);
	HookEvent("pounce_stopped", event_PounceSave);
	HookEvent("player_ledge_grab", event_PlayerLedge);
	HookEvent("player_falldamage", event_PlayerFallDamage);
	HookEvent("melee_kill", event_MeleeKill);
	HookEvent("friendly_fire", event_FriendlyFire);
	HookEvent("map_transition", event_MapTransition);
	HookEvent("create_panic_event", event_PanicEvent);
	HookEvent("player_no_longer_it", event_PlayerBlindEnd);
	HookEvent("player_shoved", Event_PlayerShoved);
	HookEvent("entity_shoved", Event_EntityShoved);
	HookEvent("witch_spawn", event_WitchSpawn);
	HookEvent("witch_harasser_set", event_WitchDisturb);
	HookEvent("ability_use", event_AbilityUse);
	HookEvent("choke_end", event_SmokerRelease);
	HookEvent("tongue_broke_bent", event_SmokerRelease);
	HookEvent("jockey_killed", event_JockeyKilled);
	HookEvent("charger_killed", event_ChargerKilled);
	HookEvent("charger_carry_end", event_ChargerCarryRelease);
	HookEvent("upgrade_pack_used", event_UpgradePackAdded);
	HookEvent("gascan_pour_completed", event_GascanPoured);
	HookEvent("triggered_car_alarm", event_CarAlarm);
	HookEvent("survival_round_start", event_SurvivalStart); // Timed Maps event
	HookEvent("scavenge_round_halftime", event_ScavengeHalftime);
	HookEvent("scavenge_round_start", event_ScavengeRoundStart);
	HookEvent("achievement_earned", event_Achievement);
	HookEvent("door_open", event_DoorOpen, EventHookMode_Post); // When the saferoom door opens...
	HookEvent("player_left_start_area", event_StartArea, EventHookMode_Post); // When a survivor leaves the start area...
	
	HookEvent("weapon_reload", event_Weapon_Reload, EventHookMode_Post);
	
	LogToFile(logfilepath, "l4d_puntos 26");
	
	AutoExecConfig(true, "l4d2_points_system");
	
	g_iHPBuffO	= FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsNormalPlayer(i)) {
			AllowBuy[i] = true;
			IsPounced[i] = 0;
			PounceTime[i] = 0;
			IsInc[i] = 0;
			IncTime[i] = 0;
			g_bIsGlowing[i] == false;
			//SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	AllowHealth = true;

	LogToFile(logfilepath, "l4d_puntos 27");
	
	g_iShovePenalty = FindSendPropInfo("CTerrorPlayer", "m_iShovePenalty");	
	g_flLagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");	
	propinfoburn = FindSendPropInfo("CTerrorPlayer", "m_burnPercent");
	
	ResetInfAbilities();
	ResetSurvAbilities();
	
	LogToFile(logfilepath, "l4d_puntos 28");
	
	g_hGameConf = LoadGameConfigFile("l4d2_bm_sig");
	if(g_hGameConf == INVALID_HANDLE)
	{
		SetFailState("Couldn't find the offsets file. Please, check that it is installed correctly.");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkCallVomitPlayer = EndPrepSDKCall();

	LogToFile(logfilepath, "l4d_puntos 29");
	
	//StartPrepSDKCall(SDKCall_Player);
	//PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnShovedBySurvivor");
	//PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	//PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	//sdkShove = EndPrepSDKCall();
	//if(sdkShove == INVALID_HANDLE)
	//{
//		SetFailState("Unable to find the 'shove' signature, check the file version!");
//	}
	
	if(sdkCallVomitPlayer == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_OnHitByVomitJar' signature, check the file version!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_SetHealthBuffer");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkSetBuffer = EndPrepSDKCall();
	if(sdkSetBuffer == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'setbuffer' signature, check the file version!");
	}
	
	g_bIsLoading = true;
	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	g_iNextSAttO = FindSendPropInfo("CBaseCombatWeapon","m_flNextSecondaryAttack");
	g_iNextPAttO = FindSendPropInfo("CBaseCombatWeapon","m_flNextPrimaryAttack");
	
	RegAdminCmd("sm_yell", cmd_yell, ADMFLAG_SLAY, "sm_yell");
	RegAdminCmd("sm_check", cmd_check, ADMFLAG_SLAY, "sm_check");
	CreateTimer(3.0, SetIsLoadingFalse, INVALID_HANDLE);
	
	LogToFile(logfilepath, "l4d_puntos 30");
	
	
	//for( new i = 1; i <= GetMaxClients(); i++ )
	//		if( IsClientInGame(i) )
	//			SDKHook(i, SDKHook_PreThink, OnPreThink);
	
	//points end
	
	new Handle:ConfigFile = LoadGameConfigFile(GAMEDATA_FILENAME);
	new Handle:MySDKCall = INVALID_HANDLE;
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "TakeOverZombieBot");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	MySDKCall = EndPrepSDKCall();
	
	if (MySDKCall == INVALID_HANDLE)
	{
		SetFailState("Cant initialize TakeOverZombieBot SDKCall");
	}
			
	LogToFile(logfilepath, "l4d_puntos 31");
	
	sdkTakeOverZombieBot = CloneHandle(MySDKCall, sdkTakeOverZombieBot);
	
	if (Timer1 == INVALID_HANDLE) Timer1 = CreateTimer(60.0, timer_UpdatePlayers, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer2 == INVALID_HANDLE) Timer2 = CreateTimer(1.0, YellTimer, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer3 == INVALID_HANDLE) Timer3 = CreateTimer(60.0, SetVictim, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer4 == INVALID_HANDLE) Timer4 = CreateTimer(1.0, CheckTanksTimer, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer5 == INVALID_HANDLE) Timer5 = CreateTimer(1.0, VictimRegen, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer6 == INVALID_HANDLE) Timer6 = CreateTimer(3.5, VictimRender, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer7 == INVALID_HANDLE) Timer7 = CreateTimer(10.0, CheckBankTimer, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer8 == INVALID_HANDLE) Timer8 = CreateTimer(2.0, ApplyAcidDamage, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer9 == INVALID_HANDLE) Timer9 = CreateTimer(1.0, SpeedLogicTimer, 0, TIMER_REPEAT);
	
	if (Timer25 == INVALID_HANDLE) Timer25 = CreateTimer(1.0, CheckRegArrayTimer, 0, TIMER_REPEAT);
	
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		AllowActivateBuyClient[i] = 1;
	}
	
	LogToFile(logfilepath, "l4d_puntos 32 end");
}

public OnConfigsExecuted()
{
	GetConVarString(cvar_DbPrefix, DbPrefix, sizeof(DbPrefix));

	// Init MySQL connections
	if (!ConnectDB())
	{
		SetFailState("Connecting to database failed. Read error log for further details.");
		return;
	}
	
	if (CommandsRegistered)
		return;

	CommandsRegistered = true;

	// Register chat commands for rank panels
	RegConsoleCmd("say", cmd_Say);
	RegConsoleCmd("say_team", cmd_Say);

	// Register console commands for rank panels
	//RegConsoleCmd("sm_rank", cmd_myrank); //Showranking
	//RegConsoleCmd("sm_nextrank", cmd_next); //Show next rank
	//RegConsoleCmd("sm_top10", cmd_t10);
//	RegConsoleCmd("sm_top10", cmd_ShowTop10);
//	RegConsoleCmd("sm_top10ppm", cmd_ShowTop10PPM);
//	RegConsoleCmd("sm_nextrank", cmd_ShowNextRank);
//	RegConsoleCmd("sm_showtimer", cmd_ShowTimedMapsTimer);
//	RegConsoleCmd("sm_showrank", cmd_ShowRanks);
//	RegConsoleCmd("sm_showppm", cmd_ShowPPMs);
//	RegConsoleCmd("sm_rankvote", cmd_RankVote);
//	RegConsoleCmd("sm_timedmaps", cmd_TimedMaps);
//	RegConsoleCmd("sm_maptimes", cmd_MapTimes);
//	RegConsoleCmd("sm_showmaptimes", cmd_ShowMapTimes);
//	RegConsoleCmd("sm_rankmenu", cmd_ShowRankMenu);
	//RegConsoleCmd("sm_rankmutetoggle", cmd_ToggleClientRankMute);
	//RegConsoleCmd("sm_rankmute", cmd_ClientRankMute);
	RegConsoleCmd("sm_victim", cmd_whovictim);
	RegConsoleCmd("sm_vip", cmd_vip);
	RegConsoleCmd("sm_coord", cmd_coord);
	
	RegConsoleCmd("sm_vipswitch", cmd_vipswitch);
	RegConsoleCmd("sm_viplist", cmd_viplist);
	
	RegConsoleCmd("sm_resetshield", cmd_resetshield);
	
	// Register administrator command for clearing all stats (BE CAREFUL)
	//RegAdminCmd("sm_rank_admin", cmd_RankAdmin, ADMFLAG_ROOT, "Display admin panel for Rank");
	//RegAdminCmd("sm_rank_clear", cmd_ClearRank, ADMFLAG_ROOT, "Clear all stats from database (asks a confirmation before clearing the database)");
	//RegAdminCmd("sm_rank_shuffle", cmd_ShuffleTeams, ADMFLAG_KICK, "Shuffle teams by player PPM (Points Per Minute)");
	//RegAdminCmd("sm_rank_motd", cmd_SetMotd, ADMFLAG_GENERIC, "Set Message Of The Day");
	RegAdminCmd("sm_setvictim", cmd_setvictim, ADMFLAG_GENERIC, "Chose the Victim");
	RegAdminCmd("sm_showdamage", cmd_showtankdamage, ADMFLAG_GENERIC, "");
	
	RegAdminCmd("sm_spawnshield", cmd_spawnshield, ADMFLAG_GENERIC, "");
	RegAdminCmd("sm_killshield", cmd_killshield, ADMFLAG_GENERIC, "");
	RegAdminCmd("sm_pointhurt", cmd_point_hurt, ADMFLAG_GENERIC, "");
	RegAdminCmd("sm_pointpush", cmd_point_push, ADMFLAG_GENERIC, "");
	RegAdminCmd("sm_explode", cmd_explode, ADMFLAG_GENERIC, "");
	
	RegAdminCmd("sm_isnormalalt", cmd_isnormalalt, ADMFLAG_GENERIC, "");
	
		
	ResetPoisonEff();
}

// Load our categories and menus
/*
public OnAdminMenuReady(Handle:TopMenu)
{
	// Block us from being called twice
	if (TopMenu == RankAdminMenu)
		return;

	RankAdminMenu = TopMenu;

	// Add a category to the SourceMod menu called "Player Stats"
	AddToTopMenu(RankAdminMenu, "Player Stats", TopMenuObject_Category, ClearRankCategoryHandler, INVALID_TOPMENUOBJECT);

	// Get a handle for the catagory we just added so we can add items to it
	new TopMenuObject:statscommands = FindTopMenuCategory(RankAdminMenu, "Player Stats");

	// Don't attempt to add items to the catagory if for some reason the catagory doesn't exist
	if (statscommands == INVALID_TOPMENUOBJECT)
		return;

	// The order that items are added to menus has no relation to the order that they appear. Items are sorted alphabetically automatically
	// Assign the menus to global values so we can easily check what a menu is when it is chosen
	MenuClearPlayers = AddToTopMenu(RankAdminMenu, "sm_rank_admin_clearplayers", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_clearplayers", ADMFLAG_ROOT);
	MenuClearMaps = AddToTopMenu(RankAdminMenu, "sm_rank_admin_clearallmaps", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_clearallmaps", ADMFLAG_ROOT);
	MenuClearAll = AddToTopMenu(RankAdminMenu, "sm_rank_admin_clearall", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_clearall", ADMFLAG_ROOT);
	MenuClearTimedMaps = AddToTopMenu(RankAdminMenu, "sm_rank_admin_cleartimedmaps", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_cleartimedmaps", ADMFLAG_ROOT);
	MenuRemoveCustomMaps = AddToTopMenu(RankAdminMenu, "sm_rank_admin_removecustom", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_removecustom", ADMFLAG_ROOT);
	MenuCleanPlayers = AddToTopMenu(RankAdminMenu, "sm_rank_admin_removeplayers", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_removeplayers", ADMFLAG_ROOT);
	MenuClear = AddToTopMenu(RankAdminMenu, "sm_rank_admin_clear", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_clear", ADMFLAG_ROOT);
}
*/
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		RankAdminMenu = INVALID_HANDLE;
}

// This handles the top level "Player Stats" category and how it is displayed on the core admin menu

public ClearRankCategoryHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Player Stats");
	else if (action == TopMenuAction_DisplayTitle)
		Format(buffer, maxlength, "Player Stats:");
	
	
}

public Action:Menu_CreateClearMenu(client, args)
{
	new Handle:menu = CreateMenu(Menu_CreateClearMenuHandler);

	SetMenuTitle(menu, "Clear:");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	AddMenuItem(menu, "cps", "Clear stats from currently playing player...");
	AddMenuItem(menu, "ctm", "Clear timed maps...");

	DisplayMenu(menu, client, 30);

	return Plugin_Handled;
}

public Menu_CreateClearMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					DisplayClearPanel(param1);
				}
				case 1:
				{
					Menu_CreateClearTMMenu(param1, 0);
				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && RankAdminMenu != INVALID_HANDLE)
				DisplayTopMenu(RankAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
			
}

public Action:Menu_CreateClearTMMenu(client, args)
{
	new Handle:menu = CreateMenu(Menu_CreateClearTMMenuHandler);

	SetMenuTitle(menu, "Clear Timed Maps:");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	AddMenuItem(menu, "ctma",  "All");
	AddMenuItem(menu, "ctmc",  "Coop");
	AddMenuItem(menu, "ctmsu", "Survival");
	AddMenuItem(menu, "ctmr",  "Realism");
	AddMenuItem(menu, "ctmm",  "Mutations");

	DisplayMenu(menu, client, 30);

	return Plugin_Handled;
}

public Menu_CreateClearTMMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					DisplayYesNoPanel(param1, "Do you really want to clear all map timings?", ClearTMAllPanelHandler);
				}
				case 1:
				{
					DisplayYesNoPanel(param1, "Do you really want to clear all Coop map timings?", ClearTMCoopPanelHandler);
				}
				case 2:
				{
					DisplayYesNoPanel(param1, "Do you really want to clear all Survival map timings?", ClearTMSurvivalPanelHandler);
				}
				case 3:
				{
					DisplayYesNoPanel(param1, "Do you really want to clear all Realism map timings?", ClearTMRealismPanelHandler);
				}
				case 4:
				{
					DisplayYesNoPanel(param1, "Do you really want to clear all Mutations map timings?", ClearTMMutationsPanelHandler);
				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && RankAdminMenu != INVALID_HANDLE)
				DisplayTopMenu(RankAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	
	
}

// This deals with what happens someone opens the "Player Stats" category from the menu
public ClearRankTopItemHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	// When an item is displayed to a player tell the menu to format the item
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == MenuClearPlayers)
			Format(buffer, maxlength, "Clear players");
		else if (object_id == MenuClearMaps)
			Format(buffer, maxlength, "Clear maps");
		else if (object_id == MenuClearAll)
			Format(buffer, maxlength, "Clear all");
		else if (object_id == MenuClearTimedMaps)
			Format(buffer, maxlength, "Clear timed maps");
		else if (object_id == MenuRemoveCustomMaps)
			Format(buffer, maxlength, "Remove custom maps");
		else if (object_id == MenuCleanPlayers)
			Format(buffer, maxlength, "Clean players");
		else if (object_id == MenuClear)
			Format(buffer, maxlength, "Clear...");
	}

	// When an item is selected do the following
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == MenuClearPlayers)
			DisplayYesNoPanel(client, "Do you really want to clear the player stats?", ClearPlayersPanelHandler);
		else if (object_id == MenuClearMaps)
			DisplayYesNoPanel(client, "Do you really want to clear the map stats?", ClearMapsPanelHandler);
		else if (object_id == MenuClearAll)
			DisplayYesNoPanel(client, "Do you really want to clear all stats?", ClearAllPanelHandler);
		else if (object_id == MenuClearTimedMaps)
			DisplayYesNoPanel(client, "Do you really want to clear all map timings?", ClearTMAllPanelHandler);
		else if (object_id == MenuRemoveCustomMaps)
			DisplayYesNoPanel(client, "Do you really want to remove the custom maps?", RemoveCustomMapsPanelHandler);
		else if (object_id == MenuCleanPlayers)
			DisplayYesNoPanel(client, "Do you really want to clean the player stats?", CleanPlayersPanelHandler);
		else if (object_id == MenuClear)
			Menu_CreateClearMenu(client, 0);
	}

	
}

// Reset all boolean variables when a map changes.

public OnMapStart()
{
	if (MapStart > 0) return;
	
	LogToFile(logfilepath, "l4d_puntos OnMapStart 1");
	
	MapEnd = 0;
	MapStart++;
		
	SetConVarInt(FindConVar("precache_all_survivors"), 1);

	if (!IsModelPrecached("models/w_models/weapons/w_m60.mdl")) PrecacheModel("models/w_models/weapons/w_m60.mdl");
	if (!IsModelPrecached("models/v_models/v_m60.mdl")) PrecacheModel("models/v_models/v_m60.mdl");
	
	if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl"))	PrecacheModel("models/survivors/survivor_teenangst.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_biker.mdl"))		PrecacheModel("models/survivors/survivor_biker.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_manager.mdl"))	PrecacheModel("models/survivors/survivor_manager.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_namvet.mdl"))		PrecacheModel("models/survivors/survivor_namvet.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_gambler.mdl"))	PrecacheModel("models/survivors/survivor_gambler.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_coach.mdl"))		PrecacheModel("models/survivors/survivor_coach.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_mechanic.mdl"))	PrecacheModel("models/survivors/survivor_mechanic.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_producer.mdl"))		PrecacheModel("models/survivors/survivor_producer.mdl", false);
	
	if (!IsModelPrecached("models/infected/witch.mdl")) PrecacheModel("models/infected/witch.mdl", false);
	
	if (!IsModelPrecached("models/infected/boomette.mdl")) PrecacheModel("models/infected/boomette.mdl", false);
	
	if (!IsModelPrecached("models/infected/common_male_ceda.mdl"))	PrecacheModel("models/infected/common_male_ceda.mdl", false);
	if (!IsModelPrecached("models/infected/common_male_clown.mdl")) 	PrecacheModel("models/infected/common_male_clown.mdl", false);
	if (!IsModelPrecached("models/infected/common_male_mud.mdl")) 	PrecacheModel("models/infected/common_male_mud.mdl", false);
	if (!IsModelPrecached("models/infected/common_male_roadcrew.mdl")) 	PrecacheModel("models/infected/common_male_roadcrew.mdl", false);
	if (!IsModelPrecached("models/infected/common_male_riot.mdl")) 	PrecacheModel("models/infected/common_male_riot.mdl", false);
	if (!IsModelPrecached("models/infected/common_male_fallen_survivor.mdl")) 	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", false);
	if (!IsModelPrecached("models/infected/common_male_jimmy.mdl.mdl")) 	PrecacheModel("models/infected/common_male_jimmy.mdl.mdl", false);	
	
	PrecacheSound(VIPJOIN, false);
	PrecacheSound(SOUNDUNK, false);
		
	GetConVarString(cvar_Gamemode, CurrentGamemode, sizeof(CurrentGamemode));
	CurrentGamemodeID = GetCurrentGamemodeID();
	SetCurrentGamemodeName();
	//ResetVars();
	
	LogToFile(logfilepath, "l4d_puntos OnMapStart 2");
	
	//ResetInfAbilities();
	//ResetSurvAbilities();
	//ResetMassAbilites();
	//UpdateMassCosts();
	//VictimTimerStarted = false;	
		
	/*if (g_bLateLoad)
	{
		for (new i = 1; i <= GetMaxClients(); i++) {
			if (IsNormalPlayer(i)) {
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		g_bLateLoad = false;
	}
	*/
		
	PrecacheModel("models/v_models/v_rif_sg552.mdl", true);
	PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl", true);
	PrecacheModel("models/v_models/v_snip_awp.mdl", true);
	PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl", true);
	PrecacheModel("models/v_models/v_snip_scout.mdl", true);
	PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl", true);
	PrecacheModel("models/v_models/v_smg_mp5.mdl", true);
	PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl", true);
	PrecacheModel("models/w_models/weapons/50cal.mdl", true);
	PrecacheModel("models/w_models/v_rif_m60.mdl", true);
	PrecacheModel("models/w_models/weapons/w_m60.mdl", true);
	PrecacheModel("models/v_models/v_m60.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);
	PrecacheModel("models/infected/witch.mdl", true);
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
	
	PrecacheParticle(PARTICLE_SPIT_PROJ1);
	PrecacheParticle(PARTICLE_SPIT_PROJ2);	
	PrecacheModel(MODEL_SHIELD);
	PrecacheParticle(PARTICLE_TESLA);
	PrecacheParticle(PARTICLE_TESLA2);
	PrecacheParticle(PARTICLE_TESLA3);
	PrecacheParticle(PARTICLE_TESLA4);
	PrecacheParticle(PARTICLE_TESLA5);
	
	GetCurrentMap(MapName, sizeof(MapName));
	
	LogToFile(logfilepath, "l4d_puntos OnMapStart 3");
	
	//Precache Sounds
	//PrecacheSoundSmart(SOUND_START);
	//PrecacheSoundSmart(SOUND_END);
	//PrecacheSoundSmart(g_sBerserkMusic);
	PrecacheSoundSmart(SHIELDSOUND);
	PrecacheSoundSmart(YELLNICK_1);
	PrecacheSoundSmart(YELLNICK_2);
	PrecacheSoundSmart(YELLNICK_3);
	PrecacheSoundSmart(YELLRO_1);
	PrecacheSoundSmart(YELLRO_2);
	PrecacheSoundSmart(YELLRO_3);
	PrecacheSoundSmart(YELLELLIS_1);
	PrecacheSoundSmart(YELLELLIS_2);
	PrecacheSoundSmart(YELLELLIS_3);
	PrecacheSoundSmart(YELLCOACH_1);
	PrecacheSoundSmart(YELLCOACH_2);
	PrecacheSoundSmart(YELLCOACH_3);
	PrecacheSoundSmart(YELLHUNTER_1);
	PrecacheSoundSmart(YELLHUNTER_2);
	PrecacheSoundSmart(YELLHUNTER_3);
	PrecacheSoundSmart(YELLSMOKER_1);
	PrecacheSoundSmart(YELLSMOKER_2);
	PrecacheSoundSmart(YELLSMOKER_3);
	PrecacheSoundSmart(YELLJOCKEY_1);
	PrecacheSoundSmart(YELLJOCKEY_2);
	PrecacheSoundSmart(YELLJOCKEY_3);
	PrecacheSoundSmart(YELLSPITTER_1);
	PrecacheSoundSmart(YELLSPITTER_2);
	PrecacheSoundSmart(YELLSPITTER_3);
	PrecacheSoundSmart(YELLBOOMER_1);
	PrecacheSoundSmart(YELLBOOMER_2);
	PrecacheSoundSmart(YELLBOOMER_3);
	PrecacheSoundSmart(YELLCHARGER_1);
	PrecacheSoundSmart(YELLCHARGER_2);
	PrecacheSoundSmart(YELLCHARGER_3);
	PrecacheSoundSmart(YELLBOOMETTE_1);
	PrecacheSoundSmart(YELLBOOMETTE_2);
	PrecacheSoundSmart(YELLBOOMETTE_3);
	PrecacheSoundSmart(YELLTANK_1);
	PrecacheSoundSmart(YELLTANK_2);
	PrecacheSoundSmart(YELLTANK_3);
	PrecacheSoundSmart(VIPJOIN);
	
	PrecacheSoundSmart(SOUND_RANKVOTE);
	PrecacheSoundSmart(SOUND_MAPTIME_START_L4D1);
	PrecacheSoundSmart(SOUND_MAPTIME_START_L4D2);
	PrecacheSoundSmart(SOUND_MAPTIME_IMPROVE_L4D1);
	PrecacheSoundSmart(SOUND_MAPTIME_IMPROVE_L4D2);
	PrecacheSoundSmart(SOUND_RANKMENU_SHOW_L4D1);
	PrecacheSoundSmart(SOUND_RANKMENU_SHOW_L4D2);
	PrecacheSoundSmart(SOUND_BOOMER_VOMIT_L4D1);
	PrecacheSoundSmart(SOUND_BOOMER_VOMIT_L4D2);
	PrecacheSoundSmart(SOUND_HUNTER_PERFECT_L4D1);
	PrecacheSoundSmart(SOUND_HUNTER_PERFECT_L4D2);
	PrecacheSoundSmart(SOUND_TANK_BULLDOZER_L4D1);
	PrecacheSoundSmart(SOUND_TANK_BULLDOZER_L4D2);
	PrecacheSoundSmart(SOUND_CHARGER_RAM);
		
	PrecacheParticle(PARTICLE_FIRE2);		
	PrecacheParticle(PARTICLE_SPAWN);
	PrecacheParticle(PARTICLE_FIRE);
	PrecacheParticle(PARTICLE_WARP);
	PrecacheParticle(PARTICLE_ICE);
	PrecacheParticle(PARTICLE_SPIT);
	PrecacheParticle(PARTICLE_SPITPROJ);
	PrecacheParticle(PARTICLE_ELEC);
	PrecacheParticle(PARTICLE_BLOOD);
	PrecacheParticle(PARTICLE_EXPLODE);
	PrecacheParticle(PARTICLE_METEOR);
	
	PrecacheParticle(EFFECT_PARTICLE_SURVIVOR);
	PrecacheParticle(EFFECT_PARTICLE_INFECTED);
	
	
	PrecacheModel("models/props_junk/gascan001a.mdl");
	PrecacheModel("models/props_junk/propanecanister001a.mdl");
	
	//RoundStartInit();
	
	g_bIsLoading = false;
	
	LogToFile(logfilepath, "l4d_puntos OnMapStart 4 end");
	
	
}

stock PrecacheSoundSmart(String:sSound[])
{
	PrecacheSound(sSound);
}

// Init player on connect, and update total rank and client rank.

public OnClientPostAdminCheck(client)
{
	//if ( (db == INVALID_HANDLE) || (MapEnd > 0) ) return;
	InitializeClientInf(client);
	PostAdminCheckRetryCounter[client] = 0;
	ResetShieldAllow[client] = 1;

	AllowBuy[client] = true;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		
	CreateTimer(1.0, ClientPostAdminCheck, client);
	
}

public Action:ClientPostAdminCheck(Handle:timer, any:client)
{
	if (!IsValidPlayer(client)) return;
	
	/*if (!IsClientInGame(client))
	{
		if (PostAdminCheckRetryCounter[client]++ < 10)
			CreateTimer(1.0, ClientPostAdminCheck, client);
		return;
	}*/

	//StartRankChangeCheck(client);
	
	/*decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));*/

	AllowActivateBuyClient[client] = 1;
		
	new Float:ct;
	ct = GetClientTime(client);
	if (FloatCompare(ct, 120.0) == -1) {
	  VipStatusDisabled[client] = 0;
	}
		
	PushIntoArray(toReg, client);
	PushIntoArray(toMute, client);
	//ReadClientRankMuteSteamID(client, SteamID);
	//GetClientVipStatus(client);
	
	
	//CheckPlayerDB(client);

	TimerPoints[client] = 0;
	TimerKills[client] = 0;
	TimerHeadshots[client] = 0;
	IsPounced[client] = 0;
	PounceTime[client] = 0;
	IsInc[client] = 0;
	IncTime[client] = 0;
	g_bIsGlowing[client] == false;
	iHurt[client] = 0;
	GLDmg[client] = 0;
	
	CreateTimer(10.0, RankConnect, client);
	CreateTimer(15.0, AnnounceConnect, client);
	/*if (VipStatus[client] == 4) {
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 190, 190, 255, 120);
	}
	new bid = GetBizonID();
	if (bid > 0) 
	PrintToChat(bid, "\x04 [\x05DEBUG\x04]\x03 glow cambiado");
	L4D2_SetEntityGlow(bid, L4D2Glow_Constant, 100000, 0, {0, 0, 255}, false); // glow para el jopia */
}

public OnPluginEnd()
{
	
	UnHookDamage();
	
	if (db == INVALID_HANDLE)
		return;

	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			switch (GetClientTeam(i))
			{
				case TEAM_SURVIVORS:
					InterstitialPlayerUpdate(i);
				case TEAM_INFECTED:
					DoInfectedFinalChecks(i);
			}
		}
	}

	CloseHandle(db);
	db = INVALID_HANDLE;

	CommandsRegistered = false;

	//if (ClearPlayerMenu != INVALID_HANDLE)
	//{
	//	CloseHandle(ClearPlayerMenu);
	//	ClearPlayerMenu = INVALID_HANDLE;
	//}
	
	new Action:result;
	Call_StartForward(Forward2);
	Call_Finish(_:result);
}

// Show rank on connect.

public Action:RankConnect(Handle:timer, any:value)
{
	if (GetConVarBool(cvar_RankOnJoin) && !InvalidGameMode())
		cmd_ShowRank(value, 0);
}

// Announce on player connect!

public Action:AnnounceConnect(Handle:timer, any:client)
{
	if (!GetConVarBool(cvar_AnnounceMode))
		return;

	if (!IsClientConnected(client) || !IsClientInGame(client))
	{
		if (AnnounceCounter[client] > 10)
		{
			AnnounceCounter[client] = 0;
		}
		else
		{
			AnnounceCounter[client]++;
			CreateTimer(5.0, AnnounceConnect, client);
		}

		return;
	}

	AnnounceCounter[client]++;

	StatsPrintToChat2(client, true, "\x05[Rank]\x01 Puedes acceder al menu de ranking, escribiendo: \x04!rankmenu\x01!");
}

// Update the player's interstitial stats, since they may have
// gotten points between the last update and when they disconnect.

public OnClientDisconnect(client)
{
	
	if (IsClientInGame(client)) {
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	
	
	if (client == VictimID) {
		PrintToChatAll("\x04[XI] \x05%t \x01%t", "Victimran1", "Victimran2");
		PrintToChatAll("\x04[XI] \x05%t", "Victimsel1");
		VictimID = 0;
		//if (!VictimTimerStarted) {
			//VictimTimerStarted = true;
			//CreateTimer(60.0, SetVictim);
		//}
	
	}
	
	if (IsValidEntRef(RenderBot[client])) {
			AcceptEntityInput(RenderBot[client], "Kill");
			RenderBot[client] = 0;
		}
	
	for (new i=1; i<=MaxBonus-1; i++) VipBonus[client][i] = 0;
	
	VipStatus[client] = 0;
	IsPounced[client] = 0;
	PounceTime[client] = 0;
	IsInc[client] = 0;
	IncTime[client] = 0;
	g_bIsGlowing[client] == false;
	GLDmg[client] = 0;
	
	if ( (MapEnd > 0) || CampaignOver) return;
		
	if (client == InfPoison) {
		ResetPoisonClient();
		PrintToChatAll("\x04[Xtreme]\x05%t", "poisonleft1");
		new pid = ChosePoisonClient();
		if (IsNormalPlayer(pid)) PrintToChatAll("\x04[Xtreme] \x03%t \x05%s \x03%t", "eljugador", GetName(pid), "poison2");
		L4D2_SetEntityGlow(pid, L4D2Glow_Constant, 100000, 0, {0, 0, 0}, false); // glow para envenenado
	}
		
	InitializeClientInf(client);
	PlayerRankVote[client] = RANKVOTE_NOVOTE;
	ClientRankMute[client] = false;

	//if (TimerRankChangeCheck[client] != INVALID_HANDLE)
	//	CloseHandle(TimerRankChangeCheck[client]);

	//TimerRankChangeCheck[client] = INVALID_HANDLE;

	if (IsClientBot(client))
		return;

	/*	
	if (MapTimingStartTime >= 0.0)
	{
		decl String:ClientID[MAX_LINE_WIDTH];
		GetClientRankAuthString(client, ClientID, sizeof(ClientID));

		RemoveFromTrie(MapTimingSurvivors, ClientID);
		RemoveFromTrie(MapTimingInfected, ClientID);
	}

	if (IsClientInGame(client))
	{
		switch (GetClientTeam(client))
		{
			case TEAM_SURVIVORS:
				InterstitialPlayerUpdate(client);
			case TEAM_INFECTED:
				DoInfectedFinalChecks(client);
		}
	}
*/
	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
	{
		if (i != client && IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			return;
	}

	// If we get this far, ALL HUMAN PLAYERS LEFT THE SERVER
	//CampaignOver = true;

	/*if (RankVoteTimer != INVALID_HANDLE)
	{
		CloseHandle(RankVoteTimer);
		RankVoteTimer = INVALID_HANDLE;
	}
	*/
	
	//points start
	
	if(IsFakeClient(client)) return;
	CreateTimer(3.0, Check, client);
	if(points[client] > GetConVarInt(StartPoints)) return;
	points[client] = GetConVarInt(StartPoints);
	killcount[client] = 0;
	wassmoker[client] = 0;
	hurtcount[client] = 0;
	protectcount[client] = 0;
	headshotcount[client] = 0;
	
	TankChaos[client] = 0;
	
	ResetClientInfAbilites(client);
	ResetClientSurvAbilites(client);
	
	MA_Rebuild();
	
	//points end
//scp	
	if (g_aPlayers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_aPlayers[client]);
	}
	g_aPlayers[client] = INVALID_HANDLE;
}

public action_LanChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarInt(cvar_Lan))
		LogMessage("ATTENTION! %s in LAN environment is based on IP address rather than Steam ID. The statistics are not reliable when they are base on IP!", PLUGIN_NAME);
}

// Update the Database prefix when the Cvar is changed.

public action_DbPrefixChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_DbPrefix)
	{
		if (StrEqual(DbPrefix, newValue))
			return;

		if (db != INVALID_HANDLE && !CheckDatabaseValidity(DbPrefix))
		{
			strcopy(DbPrefix, sizeof(DbPrefix), oldValue);
			SetConVarString(cvar_DbPrefix, DbPrefix);
		}
		else
			strcopy(DbPrefix, sizeof(DbPrefix), newValue);
	}
}

// Update the Update Timer when the Cvar is changed.

public action_TimerChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_UpdateRate)
	{
		CloseHandle(UpdateTimer);

		new NewTime = StringToInt(newValue);
		UpdateTimer = CreateTimer(float(NewTime), timer_ShowTimerScore, INVALID_HANDLE, TIMER_REPEAT);
	}
}

// Update the CurrentGamemode when the Cvar is changed.

public action_DifficultyChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_Difficulty)
		MapTimingStartTime = -1.0;
}

// Update the CurrentGamemode when the Cvar is changed.

public action_GamemodeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_Gamemode)
	{
		GetConVarString(cvar_Gamemode, CurrentGamemode, sizeof(CurrentGamemode));
		CurrentGamemodeID = GetCurrentGamemodeID();
		SetCurrentGamemodeName();
	}
}

public SetCurrentGamemodeName()
{
	switch (CurrentGamemodeID)
	{
		case GAMEMODE_COOP:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Coop");
		}
		case GAMEMODE_VERSUS:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Versus");
		}
		case GAMEMODE_REALISM:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Scavenge");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Realism Versus");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Mutations");
		}
		default:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Unknown");
		}
	}

	if (CurrentGamemodeID == GAMEMODE_MUTATIONS)
		GetConVarString(cvar_Gamemode, CurrentMutation, sizeof(CurrentMutation));
	else
		CurrentMutation[0] = 0;
}

// Scavenge round start event (occurs when door opens or players leave the start area)

public Action:event_ScavengeRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	event_RoundStart(event, name, dontBroadcast);

	StartMapTiming();
}

// Called after the connection to the database is established

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundStartInit();
}

public Action:UpdateCostsTimer(Handle:timer)
{
	UpdateMassCosts();
	if (RoundStartTime < 60) {
		RoundStartTime++;
		CreateTimer(1.0, UpdateCostsTimer);
	}
}

// Make connection to database.

bool:ConnectDB()
{
	if (db != INVALID_HANDLE)
		return true;

	if (SQL_CheckConfig(DB_CONF_NAME))
	{
		new String:Error[256];
		db = SQL_Connect(DB_CONF_NAME, true, Error, sizeof(Error));

		if (db == INVALID_HANDLE)
		{
			LogError("Failed to connect to database: %s", Error);
			return false;
		}
		else if (!SQL_FastQuery(db, "SET NAMES 'utf8'"))
		{
			if (SQL_GetError(db, Error, sizeof(Error)))
				LogError("Failed to update encoding to UTF8: %s", Error);
			else
				LogError("Failed to update encoding to UTF8: unknown");
		}

		//if (!CheckDatabaseValidity(DbPrefix))
		//{
		//	LogError("Database is missing required table or tables.");
		//	return false;
		//}
	}
	else
	{
		LogError("Databases.cfg missing '%s' entry!", DB_CONF_NAME);
		return false;
	}

	return true;
}

bool:CheckDatabaseValidity(const String:Prefix[])
{
	return true;
	if (!DoFastQuery(0, "SELECT * FROM %splayers WHERE 1 = 2", Prefix) ||
			!DoFastQuery(0, "SELECT * FROM %smaps WHERE 1 = 2", Prefix) ||
			!DoFastQuery(0, "SELECT * FROM %stimedmaps WHERE 1 = 2", Prefix) ||
			!DoFastQuery(0, "SELECT * FROM %ssettings WHERE 1 = 2", Prefix))
	{
		return false;
	}

	return true;
}

public Action:timer_ProtectedFriendly(Handle:timer, any:data)
{
	TimerProtectedFriendly[data] = INVALID_HANDLE;
	new ProtectedFriendlies = ProtectedFriendlyCounter[data];
	ProtectedFriendlyCounter[data] = 0;

	if (data == 0 || !IsClientConnected(data) || !IsClientInGame(data) || IsClientBot(data))
		return;
	
	if (!IsValidPlayer(data)) return;
		
	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Protect) * ProtectedFriendlies, 2, 3, TEAM_SURVIVORS);
	AddScore(data, Score);

	UpdateMapStat("points", Score);

	decl String:UpdatePoints[32];
	decl String:UserID[MAX_LINE_WIDTH];
	GetClientRankAuthString(data, UserID, sizeof(UserID));
	decl String:UserName[MAX_LINE_WIDTH];
	GetClientName(data, UserName, sizeof(UserName));

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_protect = award_protect + %i WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, ProtectedFriendlies, UserID);
	SendSQLUpdate(query);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(data, "%t \x04 %i \x01 %t %t \x05%i %t \x01!", "hasganado", Score, "puntospor", "proteger", ProtectedFriendlies, "companeros");
		else if (Mode == 3)
			StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for Protecting \x05%i friendlies\x01!", UserName, Score, ProtectedFriendlies);
	}
}
// Team infected damage score

public Action:timer_InfectedDamageCheck(Handle:timer, any:data)
{
	TimerInfectedDamageCheck[data] = INVALID_HANDLE;

	if (!IsValidPlayer(data)) return;

	new InfectedDamage = GetConVarInt(cvar_InfectedDamage);

	new Score = 0;
	new DamageCounter = 0;

	if (InfectedDamage > 1)
	{
		if (InfectedDamageCounter[data] < InfectedDamage)
			return;

		new TotalDamage = InfectedDamageCounter[data];

		while (TotalDamage >= InfectedDamage)
		{
			DamageCounter += InfectedDamage;
			TotalDamage -= InfectedDamage;
			Score++;
		}
	}
	else
	{
		DamageCounter = InfectedDamageCounter[data];
		Score = InfectedDamageCounter[data];
	}

	Score = ModifyScoreDifficultyFloat(Score, 0.75, 0.5, TEAM_INFECTED);

	if (Score > 0)
	{
		InfectedDamageCounter[data] -= DamageCounter;

		new Mode = GetConVarInt(cvar_AnnounceMode);

		decl String:query[1024];
		decl String:iID[MAX_LINE_WIDTH];

		GetClientRankAuthString(data, iID, sizeof(iID));

		if (CurrentGamemodeID == GAMEMODE_VERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i WHERE steamid = '%s'", DbPrefix, Score, iID);
		else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i WHERE steamid = '%s'", DbPrefix, Score, iID);
		else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
			Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i WHERE steamid = '%s'", DbPrefix, Score, iID);
		else
			Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i WHERE steamid = '%s'", DbPrefix, Score, iID);

		SendSQLUpdate(query);
		
		AddScore(data, Score);

		UpdateMapStat("points_infected", Score);

		if (Mode == 1 || Mode == 2)
		{
			if (InfectedDamage > 1)
				StatsPrintToChat(data, "%t \x04%i \x01%t %t \x04%i \x01 %t!", "hasganado", Score, "puntospor", "realizar", DamageCounter, "dañoasurv");
			else
				StatsPrintToChat(data, "You have earned \x04%i \x01points for doing damage to the Survivors!", Score, DamageCounter);
		}
		else if (Mode == 3)
		{
			decl String:Name[MAX_LINE_WIDTH];
			GetClientName(data, Name, sizeof(Name));
			if (InfectedDamage > 1)
				StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for doing \x04%i \x01points of damage to the Survivors!", "hasganado", Name, Score, DamageCounter);
			else
				StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for doing damage to the Survivors!", Name, Score, DamageCounter);
		}
	}
}

// Get Boomer points

GetBoomerPoints(VictimCount)
{
	if (VictimCount <= 0)
		return 0;

	return GetConVarInt(cvar_BoomerSuccess) * VictimCount;
}

// Calculate Boomer vomit hits and check Boomer Perfect Blindness award

public Action:timer_BoomerBlindnessCheck(Handle:timer, any:data)
{
	TimerBoomerPerfectCheck[data] = INVALID_HANDLE;

	if ((IsValidPlayer(data)) && !IsClientBot(data) && GetClientTeam(data) == TEAM_INFECTED && BoomerHitCounter[data] > 0)
	{
		new HitCounter = BoomerHitCounter[data];
		BoomerHitCounter[data] = 0;
		new OriginalHitCounter = HitCounter;
		new BoomerPerfectHits = GetConVarInt(cvar_BoomerPerfectHits);
		new BoomerPerfectSuccess = GetConVarInt(cvar_BoomerPerfectSuccess);
		new Score = 0;
		new AwardCounter = 0;

		//PrintToConsole(0, "timer_BoomerBlindnessCheck -> HitCounter = %i / BoomerPerfectHits = %i", HitCounter, BoomerPerfectHits);

		while (HitCounter >= BoomerPerfectHits)
		{
			HitCounter -= BoomerPerfectHits;
			Score += BoomerPerfectSuccess;
			AwardCounter++;
			//PrintToConsole(0, "timer_BoomerBlindnessCheck -> Score = %i", Score);
		}

		Score += GetBoomerPoints(HitCounter);
		//PrintToConsole(0, "timer_BoomerBlindnessCheck -> Total Score = %i", Score);
		Score = ModifyScoreDifficultyFloat(Score, 0.75, 0.5, TEAM_INFECTED);

		decl String:query[1024];
		decl String:iID[MAX_LINE_WIDTH];
		GetClientRankAuthString(data, iID, sizeof(iID));

		if (CurrentGamemodeID == GAMEMODE_VERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", DbPrefix, Score, AwardCounter, OriginalHitCounter, (BoomerVomitUpdated[data] ? 0 : 1), iID);
		else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", DbPrefix, Score, AwardCounter, OriginalHitCounter, (BoomerVomitUpdated[data] ? 0 : 1), iID);
		else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
			Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", DbPrefix, Score, AwardCounter, OriginalHitCounter, (BoomerVomitUpdated[data] ? 0 : 1), iID);
		else
			Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", DbPrefix, Score, AwardCounter, OriginalHitCounter, (BoomerVomitUpdated[data] ? 0 : 1), iID);

		SendSQLUpdate(query);
		AddScore(data,Score);

		if (!BoomerVomitUpdated[data])
			UpdateMapStat("infected_boomer_vomits", 1);
		UpdateMapStat("infected_boomer_blinded", HitCounter);

		BoomerVomitUpdated[data] = false;

		if (Score > 0)
		{
			UpdateMapStat("points_infected", Score);

			new Mode = GetConVarInt(cvar_AnnounceMode);

			if (Mode == 1 || Mode == 2)
			{
				if (AwardCounter > 0)
					StatsPrintToChat(data, "%t \x04%i \x01 %t \x05%t\x01!", "hasganado", Score, "puntospor", "vomitoperfecto");
				else
					StatsPrintToChat(data, "You have earned \x04%i \x01points for blinding \x05%i Survivors\x01!", Score, OriginalHitCounter);
			}
			else if (Mode == 3)
			{
				decl String:Name[MAX_LINE_WIDTH];
				GetClientName(data, Name, sizeof(Name));
				if (AwardCounter > 0)
					StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points from \x05Perfect Blindness\x01!", Name, Score);
				else
					StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for blinding \x05%i Survivors\x01!", Name, Score, OriginalHitCounter);
			}
		}

		if (AwardCounter > 0 && EnableSounds_Boomer_Vomit && GetConVarBool(cvar_SoundsEnabled))
			EmitSoundToAll(StatsSound_Boomer_Vomit);
	}
}


// Perform player init.

public Action:InitPlayers(Handle:timer)
{
	if (db == INVALID_HANDLE)
		return;

	decl String:query[64];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", DbPrefix);
	SQL_TQuery(db, GetRankTotal, query);

	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			CheckPlayerDB(i);

			QueryClientPoints(i);

			TimerPoints[i] = 0;
			TimerKills[i] = 0;
		}
	}
}

QueryClientPoints(Client, SQLTCallback:callback=INVALID_FUNCTION)
{
	decl String:SteamID[MAX_LINE_WIDTH];

	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	QueryClientPointsSteamID(Client, SteamID, callback);
}

QueryClientPointsSteamID(Client, const String:SteamID[], SQLTCallback:callback=INVALID_FUNCTION)
{
	if (callback == INVALID_FUNCTION)
		callback = GetClientPoints;

	decl String:query[512];

	Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, DbPrefix, SteamID);

	SQL_TQuery(db, callback, query, Client);
}

QueryClientPointsDP(Handle:dp, SQLTCallback:callback)
{
	decl String:query[1024], String:SteamID[MAX_LINE_WIDTH];

	ResetPack(dp);

	ReadPackCell(dp);
	ReadPackString(dp, SteamID, sizeof(SteamID));
	if (strlen(SteamID) > 25) return;
	
	Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, DbPrefix, SteamID);

	SQL_TQuery(db, callback, query, dp);
}

QueryClientRank(Client, SQLTCallback:callback=INVALID_FUNCTION)
{
	return;
	if (callback == INVALID_FUNCTION)
		callback = GetClientRank;

	decl String:query[256];

	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE %s >= %i", DbPrefix, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client]);

	SQL_TQuery(db, callback, query, Client);
}

QueryClientRankDP(Handle:dp, SQLTCallback:callback)
{
	decl String:query[256];

	ResetPack(dp);

	new Client = ReadPackCell(dp);

	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE %s >= %i", DbPrefix, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client]);

	SQL_TQuery(db, callback, query, dp);
}
/*
QueryClientGameModeRank(Client, SQLTCallback:callback=INVALID_FUNCTION)
{
	if (!InvalidGameMode())
	{
		if (callback == INVALID_FUNCTION)
			callback = GetClientGameModeRank;

		decl String:query[256];

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_versus > 0 AND points_survivors + points_infected >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_VERSUS]);
			}
			case GAMEMODE_REALISM:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realism > 0 AND points_realism >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_REALISM]);
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_survival > 0 AND points_survival >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_SURVIVAL]);
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_scavenge > 0 AND points_scavenge_survivors + points_scavenge_infected >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_SCAVENGE]);
			}
			case GAMEMODE_REALISMVERSUS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realismversus > 0 AND points_realism_survivors + points_realism_infected >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_REALISMVERSUS]);
			}
			case GAMEMODE_MUTATIONS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_mutations > 0 AND points_mutations >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_MUTATIONS]);
			}
			default:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime > 0 AND points >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_COOP]);
			}
		}

		SQL_TQuery(db, callback, query, Client);
	}
}
*/
QueryClientGameModeRankDP(Handle:dp, SQLTCallback:callback)
{
	if (!InvalidGameMode())
	{
		decl String:query[1024];

		ResetPack(dp);

		new Client = ReadPackCell(dp);

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_versus > 0 AND points_survivors + points_infected >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_VERSUS]);
			}
			case GAMEMODE_REALISM:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realism > 0 AND points_realism >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_REALISM]);
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_survival > 0 AND points_survival >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_SURVIVAL]);
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_scavenge > 0 AND points_scavenge_survivors + points_scavenge_infected >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_SCAVENGE]);
			}
			case GAMEMODE_REALISMVERSUS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realismversus > 0 AND points_realism_survivors + points_realism_infected >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_REALISMVERSUS]);
			}
			case GAMEMODE_MUTATIONS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_mutations > 0 AND points_mutations >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_MUTATIONS]);
			}
			default:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime > 0 AND points >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_COOP]);
			}
		}

		SQL_TQuery(db, callback, query, dp);
	}
}
/*
QueryClientGameModePoints(Client, SQLTCallback:callback=INVALID_FUNCTION)
{
	decl String:SteamID[MAX_LINE_WIDTH];

	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	QueryClientGameModePointsStmID(Client, SteamID, callback);
}

QueryClientGameModePointsStmID(Client, const String:SteamID[], SQLTCallback:callback=INVALID_FUNCTION)
{
	if (cbGetRankTotal == INVALID_HANDLE)
		callback = GetClientGameModePoints;

	decl String:query[1024];

	Format(query, sizeof(query), "SELECT points, points_survivors + points_infected, points_realism, points_survival, points_scavenge_survivors + points_scavenge_infected + points_realism_survivors + points_realism_infected, points_mutations FROM %splayers WHERE steamid = '%s'", DbPrefix, SteamID);

	SQL_TQuery(db, callback, query, Client);
}
*/
QueryClientGameModePointsDP(Handle:dp, SQLTCallback:callback)
{
	decl String:query[1024], String:SteamID[MAX_LINE_WIDTH];

	ResetPack(dp);

	ReadPackCell(dp);
	ReadPackString(dp, SteamID, sizeof(SteamID));
	if (strlen(SteamID) > 25) return;

	Format(query, sizeof(query), "SELECT points, points_survivors + points_infected, points_realism, points_survival, points_scavenge_survivors + points_scavenge_infected, points_realism_survivors + points_realism_infected, points_mutations FROM %splayers WHERE steamid = '%s'", DbPrefix, SteamID);

	SQL_TQuery(db, callback, query, dp);
}
/*
QueryRanks()
{
	QueryRank_1();
	QueryRank_2();
}
*/
QueryRank_1(Handle:dp=INVALID_HANDLE, SQLTCallback:callback=INVALID_FUNCTION)
{
	if (callback == INVALID_FUNCTION)
		callback = GetRankTotal;

	decl String:query[1024];

	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", DbPrefix);

	SQL_TQuery(db, callback, query, dp);
}

QueryRank_2(Handle:dp=INVALID_HANDLE, SQLTCallback:callback=INVALID_FUNCTION)
{
	if (callback == INVALID_FUNCTION)
		callback = GetGameModeRankTotal;

	decl String:query[1024];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_versus > 0", DbPrefix);
		}
		case GAMEMODE_REALISM:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realism > 0", DbPrefix);
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_survival > 0", DbPrefix);
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_scavenge > 0", DbPrefix);
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realismversus > 0", DbPrefix);
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_mutations > 0", DbPrefix);
		}
		default:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime > 0", DbPrefix);
		}
	}

	SQL_TQuery(db, callback, query, dp);
}

QueryClientStats(Client, CallingMethod=CM_UNKNOWN)
{
	return;
	decl String:SteamID[MAX_LINE_WIDTH];

	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	QueryClientStatsSteamID(Client, SteamID, CallingMethod);
}

QueryClientStatsSteamID(Client, const String:SteamID[], CallingMethod=CM_UNKNOWN)
{
	return;
	new Handle:dp = CreateDataPack();
	
	if (!IsValidPlayer(Client)) return;
	
	WritePackCell(dp, Client);
	WritePackString(dp, SteamID);
	WritePackCell(dp, CallingMethod);
	if (strlen(SteamID) > 25) return;

	QueryClientStatsDP(dp);
}

QueryClientStatsDP(Handle:dp)
{
	QueryClientGameModePointsDP(dp, QueryClientStatsDP_1);
}

public QueryClientStatsDP_1(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_1 Query failed: %s", error);
		return;
	}

	ResetPack(dp);
	GetClientGameModePoints(owner, hndl, error, ReadPackCell(dp));

	QueryClientPointsDP(dp, QueryClientStatsDP_2);
}

public QueryClientStatsDP_2(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_2 Query failed: %s", error);
		return;
	}

	ResetPack(dp);
	GetClientPoints(owner, hndl, error, ReadPackCell(dp));

	QueryClientGameModeRankDP(dp, QueryClientStatsDP_3);
}

public QueryClientStatsDP_3(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_3 Query failed: %s", error);
		return;
	}

	ResetPack(dp);
	GetClientGameModeRank(owner, hndl, error, ReadPackCell(dp));

	QueryClientRankDP(dp, QueryClientStatsDP_4);
}

public QueryClientStatsDP_4(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_4 Query failed: %s", error);
		return;
	}

	ResetPack(dp);
	GetClientRank(owner, hndl, error, ReadPackCell(dp));

	QueryRank_1(dp, QueryClientStatsDP_5);
}

public QueryClientStatsDP_5(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_5 Query failed: %s", error);
		return;
	}

	ResetPack(dp);
	GetRankTotal(owner, hndl, error, ReadPackCell(dp));

	QueryRank_2(dp, QueryClientStatsDP_6);
}

public QueryClientStatsDP_6(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		if (dp != INVALID_HANDLE)
			CloseHandle(dp);

		LogError("QueryClientStatsDP_6 Query failed: %s", error);
		return;
	}

	decl String:SteamID[MAX_LINE_WIDTH];

	ResetPack(dp);

	new Client = ReadPackCell(dp);
	ReadPackString(dp, SteamID, sizeof(SteamID));
	new CallingMethod = ReadPackCell(dp);

	GetGameModeRankTotal(owner, hndl, error, Client);

	// Callback
	if (CallingMethod == CM_RANK)
	{
		QueryClientStatsDP_Rank(Client, SteamID);
	}
	else if (CallingMethod == CM_TOP10)
	{
		QueryClientStatsDP_Top10(Client, SteamID);
	}
	else if (CallingMethod == CM_NEXTRANK)
	{
		QueryClientStatsDP_NextRank(Client, SteamID);
	}
	else if (CallingMethod == CM_NEXTRANKFULL)
	{
		QueryClientStatsDP_NextRankFull(Client, SteamID);
	}

	// Clean your mess up
	CloseHandle(dp);
	dp = INVALID_HANDLE;
}

QueryClientStatsDP_Rank(Client, const String:SteamID[])
{
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT name, %s, %s, kills, versus_kills_survivors + scavenge_kills_survivors + realism_kills_survivors + mutations_kills_survivors, headshots FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, DB_PLAYERS_TOTALPOINTS, DbPrefix, SteamID);
	SQL_TQuery(db, DisplayRank, query, Client);
}

QueryClientStatsDP_Top10(Client, const String:SteamID[])
{
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT name, %s, %s, kills, versus_kills_survivors + scavenge_kills_survivors + realism_kills_survivors + mutations_kills_survivors, headshots FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, DB_PLAYERS_TOTALPOINTS, DbPrefix, SteamID);
	SQL_TQuery(db, DisplayRank, query, Client);
}

QueryClientStatsDP_NextRank(Client, const String:SteamID[])
{
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT (%s + 1) - %i FROM %splayers WHERE (%s) >= %i AND steamid <> '%s' ORDER BY (%s) ASC LIMIT 1", DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], DbPrefix, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], SteamID, DB_PLAYERS_TOTALPOINTS);
	SQL_TQuery(db, DisplayClientNextRank, query, Client);

	//if (TimerRankChangeCheck[Client] != INVALID_HANDLE)
	//	TriggerTimer(TimerRankChangeCheck[Client], true);
}

QueryClientStatsDP_NextRankFull(Client, const String:SteamID[])
{
	decl String:query[2048];
	Format(query, sizeof(query), "SELECT (%s + 1) - %i FROM %splayers WHERE (%s) >= %i AND steamid <> '%s' ORDER BY (%s) ASC LIMIT 1", DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], DbPrefix, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], SteamID, DB_PLAYERS_TOTALPOINTS);
	SQL_TQuery(db, GetClientNextRank, query, Client);

	decl String:query1[1024], String:query2[256], String:query3[1024];
	Format(query1, sizeof(query1), "SELECT name, (%s) AS totalpoints FROM %splayers WHERE (%s) >= %i AND steamid <> '%s' ORDER BY totalpoints ASC LIMIT 3", DB_PLAYERS_TOTALPOINTS, DbPrefix, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], SteamID);
	Format(query2, sizeof(query2), "SELECT name, %i AS totalpoints FROM %splayers WHERE steamid = '%s'", ClientPoints[Client], DbPrefix, SteamID);
	Format(query3, sizeof(query3), "SELECT name, (%s) as totalpoints FROM %splayers WHERE (%s) < %i ORDER BY totalpoints DESC LIMIT 3", DB_PLAYERS_TOTALPOINTS, DbPrefix, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client]);
	Format(query, sizeof(query), "(%s) UNION (%s) UNION (%s) ORDER BY totalpoints DESC", query1, query2, query3);
	SQL_TQuery(db, DisplayNextRankFull, query, Client);

	//if (TimerRankChangeCheck[Client] != INVALID_HANDLE)
	//	TriggerTimer(TimerRankChangeCheck[Client], true);
}

// Check if a map is already in the DB.

CheckCurrentMapDB()
{
	if (StatsDisabled(true))
		return;

	decl String:MapName[MAX_LINE_WIDTH];
	GetCurrentMap(MapName, sizeof(MapName));

	decl String:query[512];
	Format(query, sizeof(query), "SELECT name FROM %smaps WHERE name = '%s' AND gamemode = %i AND mutation = '%s'", DbPrefix, MapName, GetCurrentGamemodeID(), CurrentMutation);

	SQL_TQuery(db, InsertMapDB, query);
}

// Insert a map into the database if they do not already exist.

public InsertMapDB(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (db == INVALID_HANDLE)
		return;

	if (StatsDisabled(true))
		return;

	if (!SQL_GetRowCount(hndl))
	{
		decl String:MapName[MAX_LINE_WIDTH];
		GetCurrentMap(MapName, sizeof(MapName));

		decl String:query[512];
		Format(query, sizeof(query), "INSERT IGNORE INTO %smaps SET name = '%s', custom = 1, gamemode = %i", DbPrefix, MapName, GetCurrentGamemodeID());

		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}
}

// Check if a player is already in the DB, and update their timestamp and playtime.

CheckPlayerDB(client)
{
	if (!IsValidPlayer(client)) return;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	decl String:query[512];
	Format(query, sizeof(query), "SELECT steamid FROM %splayers WHERE steamid = '%s'", DbPrefix, SteamID);
	SQL_TQuery(db, InsertPlayerDB, query, client);
	
}

// Insert a player into the database if they do not already exist.
public InsertPlayerDB(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (db == INVALID_HANDLE || IsClientBot(client))
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("InsertPlayerDB failed! Reason: %s", error);
		return;
	}

	if (StatsDisabled())
		return;

	if (!SQL_GetRowCount(hndl))
	{
		new String:SteamID[MAX_LINE_WIDTH];
		GetClientRankAuthString(client, SteamID, sizeof(SteamID));

		new String:query[512];
		Format(query, sizeof(query), "INSERT IGNORE INTO %splayers SET steamid = '%s'", DbPrefix, SteamID);
		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}

	//UpdatePlayer(client);
	//ReadClientRankMuteSteamID(client, SteamID);
}

ReadClientRankMuteSteamID(Client, const String:SteamID[] = "")
{
	if ( (!IsValidPlayer(Client)) || (MapEnd > 0) ) return;

	//LogToFile(logfilepath, "ReadClientRankMuteSteamID: %i %s", Client, GetName(Client));
	
	if (IsMuteProcess) return;
	IsMuteProcess = true;
	
	//decl String:SteamID[MAX_LINE_WIDTH];
	//GetClientAuthString(Client, SteamID, sizeof(SteamID));
	
	decl String:query[512];
	Format(query, sizeof(query), "SELECT mute FROM settings WHERE steamid = '%s'", SteamID);
	SQL_TQuery(db, GetClientRankMute, query, Client);
}


public GetClientRankMute(Handle:owner, Handle:hndl, const String:error[], any:client)
{
		
	if ( (hndl == INVALID_HANDLE) || (db == INVALID_HANDLE) || (!IsValidPlayer(client)) || (MapEnd > 0) ) {
		IsMuteProcess = false;
		//LogToFile(logfilepath, "GetClientRankMute failed: %i %s", client, GetName(client));	
		return;
	}
	if (!SQL_HasResultSet(hndl)) {
		//LogToFile(logfilepath, "GetClientRankMute failed2: %i %s", client, GetName(client));	
		IsMuteProcess = false;
		return;
	}
		
	//LogToFile(logfilepath, "GetClientRankMute: %i %s", client, GetName(client));	
		
	if (!SQL_GetRowCount(hndl))
	{
		new String:SteamID[MAX_LINE_WIDTH];
		GetClientAuthString(client, SteamID, sizeof(SteamID));

		new String:query[512];
		Format(query, sizeof(query), "INSERT IGNORE INTO settings SET steamid = '%s'", SteamID);
		SQL_TQuery(db, SetClientRankMute, query, client);
	}
	else
	{
		while (SQL_FetchRow(hndl))
			ClientRankMute[client] = (SQL_FetchInt(hndl, 0) != 0);
			
		CreateTimer(1.0, DelayedMuteFinish, client);	
	}
	
	
}

public SetClientRankMute(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if ( (db == INVALID_HANDLE) || (hndl == INVALID_HANDLE) || (!IsValidPlayer(client)) || (MapEnd > 0) ) {
		IsMuteProcess = false;
		//LogToFile(logfilepath, "SetClientRankMute failed: %i %s", client, GetName(client));	
		return;
	}

	//LogToFile(logfilepath, "SetClientRankMute: %i %s", client, GetName(client));	
	
	if (SQL_GetAffectedRows(owner) == 0)
	{		
		ClientRankMute[client] = false;
	}

	
	CreateTimer(1.0, DelayedMuteFinish, client);
	//ReadClientRankMute(client);
}

public Action:DelayedMuteFinish(Handle:timer, any:client)
{
	IsMuteProcess = false;
		
	new toDel = FindValueInArray(toMute, client);
	if (toDel != -1) RemoveFromArray(toMute, toDel);

	if (GetArraySize(toMute) > 0)
		ReadClientRankMute(GetArrayCell(toMute, 0));
}

ReadClientRankMute(Client)
{
	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));

	ReadClientRankMuteSteamID(Client, SteamID);
}

SendSQLUpdate(const String:query[], SQLTCallback:callback=INVALID_FUNCTION)
{
	return; //вырубаем
	
	if (db == INVALID_HANDLE)
		return;

	if (callback == INVALID_FUNCTION)
		callback = SQLErrorCheckCallback;

	if (DEBUG)
	{
		if (QueryCounter >= 256)
			QueryCounter = 0;

		new queryid = QueryCounter++;

		Format(QueryBuffer[queryid], MAX_QUERY_COUNTER, query);

		SQL_TQuery(db, callback, query, queryid);
	}
	else
		SQL_TQuery(db, callback, query);
}

// Report error on sql query;

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:queryid)
{
	if (db == INVALID_HANDLE)
		return;

	if(!StrEqual("", error))
	{
		if (DEBUG)
			LogError("SQL Error: %s (Query: \"%s\")", error, QueryBuffer[queryid]);
		else
			LogError("SQL Error: %s", error);
	}
}

// Perform player update of name, playtime, and timestamp.

public UpdatePlayer(client)
{
	if (!IsClientConnected(client))
		return;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	decl String:Name[MAX_LINE_WIDTH];
	GetClientName(client, Name, sizeof(Name));

	ReplaceString(Name, sizeof(Name), "<?php", "");
	ReplaceString(Name, sizeof(Name), "<?PHP", "");
	ReplaceString(Name, sizeof(Name), "?>", "");
	ReplaceString(Name, sizeof(Name), "\\", "");
	//ReplaceString(Name, sizeof(Name), "\"", "");
	ReplaceString(Name, sizeof(Name), "'", "");
	ReplaceString(Name, sizeof(Name), ";", "");
	ReplaceString(Name, sizeof(Name), "ґ", "");
	ReplaceString(Name, sizeof(Name), "`", "");

	UpdatePlayerFull(client, SteamID, Name);
}

// Perform player update of name, playtime, and timestamp.

public UpdatePlayerFull(Client, const String:SteamID[], const String:Name[])
{
	// Client can be ZERO! Look at UpdatePlayerCallback.
	return;
	decl String:Playtime[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(Playtime, sizeof(Playtime), "playtime_versus");
		}
		case GAMEMODE_REALISM:
		{
			Format(Playtime, sizeof(Playtime), "playtime_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(Playtime, sizeof(Playtime), "playtime_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(Playtime, sizeof(Playtime), "playtime_scavenge");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(Playtime, sizeof(Playtime), "playtime_realismversus");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(Playtime, sizeof(Playtime), "playtime_mutations");
		}
		default:
		{
			Format(Playtime, sizeof(Playtime), "playtime");
		}
	}

	decl String:IP[16];
	GetClientIP(Client, IP, sizeof(IP));

	decl String:query[512];
	Format(query, sizeof(query), "UPDATE %splayers SET lastontime = UNIX_TIMESTAMP(), %s = %s + 1, lastgamemode = %i, name = '%s', ip = '%s' WHERE steamid = '%s'", DbPrefix, Playtime, Playtime, CurrentGamemodeID, Name, IP, SteamID);
	SQL_TQuery(db, UpdatePlayerCallback, query, Client);
}

// Report error on sql query;

public UpdatePlayerCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (db == INVALID_HANDLE)
		return;

	if (!StrEqual("", error))
	{
		if (client > 0)
		{
			decl String:SteamID[MAX_LINE_WIDTH];
			GetClientRankAuthString(client, SteamID, sizeof(SteamID));

			UpdatePlayerFull(0, SteamID, "INVALID_CHARACTERS");

			return;
		}

		LogError("SQL Error: %s", error);
	}
}

// Perform a map stat update.
public UpdateMapStat(const String:Field[], Score)
{
	return;
	if (Score <= 0)
		return;

	decl String:MapName[64];
	GetCurrentMap(MapName, sizeof(MapName));

	decl String:DiffSQL[MAX_LINE_WIDTH];
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "normal", false)) Format(DiffSQL, sizeof(DiffSQL), "nor");
	else if (StrEqual(Difficulty, "hard", false)) Format(DiffSQL, sizeof(DiffSQL), "adv");
	else if (StrEqual(Difficulty, "impossible", false)) Format(DiffSQL, sizeof(DiffSQL), "exp");
	else return;

	decl String:FieldSQL[MAX_LINE_WIDTH];
	Format(FieldSQL, sizeof(FieldSQL), "%s_%s", Field, DiffSQL);

	decl String:query[512];
	Format(query, sizeof(query), "UPDATE %smaps SET %s = %s + %i WHERE name = '%s' and gamemode = %i", DbPrefix, FieldSQL, FieldSQL, Score, MapName, GetCurrentGamemodeID());
	SendSQLUpdate(query);
}

// Perform a map stat update.
public UpdateMapStatFloat(const String:Field[], Float:Value)
{
	return;
	if (Value <= 0)
		return;

	decl String:MapName[64];
	GetCurrentMap(MapName, sizeof(MapName));

	decl String:DiffSQL[MAX_LINE_WIDTH];
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "normal", false)) Format(DiffSQL, sizeof(DiffSQL), "nor");
	else if (StrEqual(Difficulty, "hard", false)) Format(DiffSQL, sizeof(DiffSQL), "adv");
	else if (StrEqual(Difficulty, "impossible", false)) Format(DiffSQL, sizeof(DiffSQL), "exp");
	else return;

	decl String:FieldSQL[MAX_LINE_WIDTH];
	Format(FieldSQL, sizeof(FieldSQL), "%s_%s", Field, DiffSQL);

	decl String:query[512];
	Format(query, sizeof(query), "UPDATE %smaps SET %s = %s + %f WHERE name = '%s' and gamemode = %i", DbPrefix, FieldSQL, FieldSQL, Value, MapName, GetCurrentGamemodeID());
	SendSQLUpdate(query);
}

// End blinded state.

public Action:timer_EndBoomerBlinded(Handle:timer, any:data)
{
	PlayerBlinded[data][0] = 0;
	PlayerBlinded[data][1] = 0;
}

// End blinded state.

public Action:timer_EndSmokerParalyzed(Handle:timer, any:data)
{
	PlayerParalyzed[data][0] = 0;
	PlayerParalyzed[data][1] = 0;
}

// End lunging state.

public Action:timer_EndHunterLunged(Handle:timer, any:data)
{
	PlayerLunged[data][0] = 0;
	PlayerLunged[data][1] = 0;
}

// End plummel state.

public Action:timer_EndChargerPlummel(Handle:timer, any:data)
{
	ChargerPlummelVictim[PlayerPlummeled[data][1]] = 0;
	PlayerPlummeled[data][0] = 0;
	PlayerPlummeled[data][1] = 0;
}

// End charge impact counter state.

public Action:timer_EndCharge(Handle:timer, any:data)
{
	ChargerImpactCounterTimer[data] = INVALID_HANDLE;
	new Counter = ChargerImpactCounter[data];
	ChargerImpactCounter[data] = 0;

	new Score = 0;
	new String:ScoreSet[256] = "";

	if (Counter >= GetConVarInt(cvar_ChargerRamHits))
	{
		Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_ChargerRamSuccess), 0.9, 0.8, TEAM_INFECTED);

		if (CurrentGamemodeID == GAMEMODE_VERSUS)
			Format(ScoreSet, sizeof(ScoreSet), "points_infected = points_infected + %i", Score);
		else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
			Format(ScoreSet, sizeof(ScoreSet), "points_realism_infected = points_realism_infected + %i", Score);
		else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
			Format(ScoreSet, sizeof(ScoreSet), "points_scavenge_infected = points_scavenge_infected + %i", Score);
		else
			Format(ScoreSet, sizeof(ScoreSet), "points_mutations = points_mutations + %i", Score);

		StrCat(ScoreSet, sizeof(ScoreSet), ", award_scatteringram = award_scatteringram + 1, ");

		if (EnableSounds_Charger_Ram && GetConVarBool(cvar_SoundsEnabled))
			EmitSoundToAll(SOUND_CHARGER_RAM);
	}
	//UPDATE players SET points_infected = points_infected + 40, award_scatteringram = acharger_impacts = charger_impacts + 4 WHERE steamid = 'STEAM_1:1:12345678'

	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(data, AttackerID, sizeof(AttackerID));

	decl String:query[512];
	Format(query, sizeof(query), "UPDATE %splayers SET %scharger_impacts = charger_impacts + %i WHERE steamid = '%s'", DbPrefix, ScoreSet, Counter, AttackerID);
	SendSQLUpdate(query);
	AddScore(data, Score);
	
	if (Score > 0)
		UpdateMapStat("points_infected", Score);

	if (Counter > 0)
		UpdateMapStat("charger_impacts", Counter);

	new Mode = 0;
	if (Score > 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if ((Mode == 1 || Mode == 2) && IsClientConnected(data) && IsClientInGame(data))
		StatsPrintToChat(data, "%t \x04%i \x01 %t \x05%t  \x03%i \x01%t!","hasganado", Score, "puntospor", "mandaravolar", Counter, "victimas");
	else if (Mode == 3)
	{
		decl String:AttackerName[MAX_LINE_WIDTH];
		GetClientName(data, AttackerName, sizeof(AttackerName));
		StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for charging a \x05Scattering Ram \x01on \x03%i \x01victims!", AttackerName, Score, Counter);
	}
}

// End carried state.

public Action:timer_EndChargerCarry(Handle:timer, any:data)
{
	ChargerCarryVictim[PlayerCarried[data][1]] = 0;
	PlayerCarried[data][0] = 0;
	PlayerCarried[data][1] = 0;
}

// End jockey ride state.

public Action:timer_EndJockeyRide(Handle:timer, any:data)
{
	JockeyVictim[PlayerCarried[data][1]] = 0;
	PlayerJockied[data][0] = 0;
	PlayerJockied[data][1] = 0;
}

// End friendly fire damage counter.

public Action:timer_FriendlyFireDamageEnd(Handle:timer, any:dp)
{
	ResetPack(dp);

	new HumanDamage = ReadPackCell(dp);
	new BotDamage = ReadPackCell(dp);
	new Attacker = ReadPackCell(dp);

	// This may fail! What happens when a player skips and another joins with the same Client ID (is this even possible in such short time?)
	FriendlyFireTimer[Attacker][0] = INVALID_HANDLE;

	decl String:AttackerID[MAX_LINE_WIDTH];
	ReadPackString(dp, AttackerID, sizeof(AttackerID));
	decl String:AttackerName[MAX_LINE_WIDTH];
	ReadPackString(dp, AttackerName, sizeof(AttackerName));

	// The damage is read and turned into lost points...
	//ResetPack(dp);
	//WritePackCell(dp, 0); // Human damage
	//WritePackCell(dp, 0); // Bot damage
	if (dp != INVALID_HANDLE) CloseHandle(dp);

	
	
	if (HumanDamage <= 0 && BotDamage <= 0)
		return;

	new Score = 0;
	
	if (GetConVarBool(cvar_EnableNegativeScore))
	{
		if (HumanDamage > 0)
			Score += ModifyScoreDifficultyNR(RoundToNearest(GetConVarFloat(cvar_FriendlyFireMultiplier) * HumanDamage), 2, 4, TEAM_SURVIVORS);

		if (BotDamage > 0)
		{
			new Float:BotScoreMultiplier = GetConVarFloat(cvar_BotScoreMultiplier);

			if (BotScoreMultiplier > 0.0)
				Score += ModifyScoreDifficultyNR(RoundToNearest(GetConVarFloat(cvar_FriendlyFireMultiplier) * BotDamage), 2, 4, TEAM_SURVIVORS);
		}
	}

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i, award_friendlyfire = award_friendlyfire + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, AttackerID);
	SendSQLUpdate(query);
	AddScore(Attacker, -Score);

	new Mode = 0;
	if (Score > 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if ((Mode == 1 || Mode == 2) && IsClientConnected(Attacker) && IsClientInGame(Attacker))
		StatsPrintToChat(Attacker, "%t \x03%t \x04%i \x01%t %t \x03%t \x05(%i HP)\x01!", "youhave", "perdido", Score, "puntospor", "realizar", "fuegoamigo", HumanDamage + BotDamage);
	else if (Mode == 3)
		StatsPrintToChatAll("\x05%s \x01has \x03LOST \x04%i \x01points for inflicting \x03Friendly Fire Damage \x05(%i HP)\x01!", AttackerName, Score, HumanDamage + BotDamage);
}

// Start team shuffle.

public Action:timer_ShuffleTeams(Handle:timer, any:data)
{
	if (CheckHumans())
		return;

	decl String:query[1024];
	Format(query, sizeof(query), "SELECT steamid FROM %splayers WHERE ", DbPrefix);

	new maxplayers = GetMaxClients();
	decl String:SteamID[MAX_LINE_WIDTH], String:where[512];
	new counter = 0, team;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		team = GetClientTeam(i);

		if (team != TEAM_SURVIVORS && team != TEAM_INFECTED)
			continue;

		if (counter++ > 0)
			StrCat(query, sizeof(query), "OR ");

		GetClientRankAuthString(i, SteamID, sizeof(SteamID));
		Format(where, sizeof(where), "steamid = '%s' ", SteamID);
		StrCat(query, sizeof(query), where);
	}

	if (counter <= 1)
	{
		StatsPrintToChatAllPreFormatted("Team shuffle by player PPM failed because there was \x03not enough players\x01!");
		return;
	}

	Format(where, sizeof(where), "ORDER BY (%s) / (%s) DESC", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME);
	StrCat(query, sizeof(query), where);

	SQL_TQuery(db, ExecuteTeamShuffle, query);
}

// End of RANKVOTE.

public Action:timer_RankVote(Handle:timer, any:data)
{
	RankVoteTimer = INVALID_HANDLE;

	if (!CheckHumans())
	{
		new humans = 0, votes = 0, yesvotes = 0, novotes = 0, WinningVoteCount = 0;

		CheckRankVotes(humans, votes, yesvotes, novotes, WinningVoteCount);

		StatsPrintToChatAll("Vote to shuffle teams by player PPM \x03%s \x01with \x04%i (yes) against %i (no)\x01.", (yesvotes > novotes ? "PASSED" : "DID NOT PASS"), yesvotes, novotes);

		if (yesvotes > novotes)
			CreateTimer(3.0, timer_ShuffleTeams);
	}
}

// End friendly fire cooldown.

public Action:timer_FriendlyFireCooldownEnd(Handle:timer, any:data)
{
	FriendlyFireCooldown[FriendlyFirePrm[data][0]][FriendlyFirePrm[data][1]] = false;
	FriendlyFireTimer[FriendlyFirePrm[data][0]][FriendlyFirePrm[data][1]] = INVALID_HANDLE;
}

// End friendly fire cooldown.

public Action:timer_MeleeKill(Handle:timer, any:data)
{
	MeleeKillTimer[data] = INVALID_HANDLE;
	new Counter = MeleeKillCounter[data];
	MeleeKillCounter[data] = 0;

	if (Counter <= 0 || IsClientBot(data) || !IsClientConnected(data) || !IsClientInGame(data) || GetClientTeam(data) != TEAM_SURVIVORS)
		return;
	if (!IsValidPlayer(data)) return;
	
	decl String:query[512], String:clientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(data, clientID, sizeof(clientID));
	Format(query, sizeof(query), "UPDATE %splayers SET melee_kills = melee_kills + %i WHERE steamid = '%s'", DbPrefix, Counter, clientID);
	SendSQLUpdate(query);

}

// Perform minutely updates of player database.
// Reports Disabled message if in Versus, Easy mode, not enough Human players, and if cheats are active.

public Action:timer_UpdatePlayers(Handle:timer, Handle:hndl)
{
	if (IsEnd()) return;
			
	UpdateMassCosts();
	
	//ServerCommand("sm_dump_handles handles");
	
	return;
	
	if (CheckHumans())
	{
		if (GetConVarBool(cvar_DisabledMessages))
			StatsPrintToChatAllPreFormatted("Left 4 Dead Stats are \x04DISABLED\x01, not enough Human players!");

		return;
	}

	if (StatsDisabled())
		return;

	//UpdateMapStat("playtime", 1);

	//new maxplayers = GetMaxClients();
	//for (new i = 1; i <= maxplayers; i++)
	//{
//		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			//CheckPlayerDB(i);
	//}
}

// Display rank change.

public Action:timer_ShowRankChange(Handle:timer, any:client)
{
	return;
	DoShowRankChange(client);
}

public DoShowRankChange(Client)
{
	return;
	if (StatsDisabled())
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	QueryClientPointsSteamID(Client, ClientID, GetClientPointsRankChange);
}

// Display common Infected scores to each player.

public Action:timer_ShowTimerScore(Handle:timer, Handle:hndl)
{
	if (StatsDisabled())
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:Name[MAX_LINE_WIDTH];

	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			// if (CurrentPoints[i] > GetConVarInt(cvar_MaxPoints))
			//     continue;

			TimerPoints[i] = GetMedkitPointReductionScore(TimerPoints[i]);

			if (TimerPoints[i] > 0 && TimerKills[i] > 0)
			{
				if (Mode == 1 || Mode == 2)
				{
					StatsPrintToChat(i, "%t \x04%i \x01%t %t \x05%i \x01%t!", "hasganado", TimerPoints[i], "puntospor", "matar", TimerKills[i], "Infected");
				}
				else if (Mode == 3)
				{
					GetClientName(i, Name, sizeof(Name));
					StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for killing \x05%i \x01Infected!", Name, TimerPoints[i], TimerKills[i]);
				}
			}

			InterstitialPlayerUpdate(i);
		}

		TimerPoints[i] = 0;
		TimerKills[i] = 0;
		TimerHeadshots[i] = 0;
	}

}

// Update a player's stats, used for interstitial updating.

public InterstitialPlayerUpdate(client)
{
	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, ClientID, sizeof(ClientID));

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	//new len = 0;
	//decl String:query[1024];
	//len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET %s = %s + %i, ", DbPrefix, UpdatePoints, UpdatePoints, TimerPoints[client]);
	//len += Format(query[len], sizeof(query)-len, "kills = kills + %i, kill_infected = kill_infected + %i, ", TimerKills[client], TimerKills[client]);
	//len += Format(query[len], sizeof(query)-len, "headshots = headshots + %i ", TimerHeadshots[client]);
	//len += Format(query[len], sizeof(query)-len, "WHERE steamid = '%s'", ClientID);
	//SendSQLUpdate(query);

	UpdateMapStat("kills", TimerKills[client]);
	UpdateMapStat("points", TimerPoints[client]);

	AddScore(client, TimerPoints[client]);
}

// Player Death event. Used for killing AI Infected. +2 on headshot, and global announcement.
// Team Kill code is in the awards section. Tank Kill code is in Tank section.

public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver || IsEnd()) return;
			
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:AttackerIsBot = GetEventBool(event, "attackerisbot");
	new bool:VictimIsBot = GetEventBool(event, "victimisbot");
	new bool:blast = GetEventBool(event, "blast");
	new wID = GetEventInt(event, "weapon_id");
		
	new VictimTeam = -1;
	new AttackerTeam = -1;
			
			
	if (IsNormalPlayer(Victim))	{
		VictimTeam = GetClientTeam(Victim);
		killshield(Victim);
		
		if (IsValidEntRef(RenderBot[Victim])) {
			AcceptEntityInput(RenderBot[Victim], "Kill");
			RenderBot[Victim] = 0;
		}
	}
	if (IsNormalPlayer(Attacker)) AttackerTeam = GetClientTeam(Attacker);

	//tank awards
	if (IsTank(Victim))
	{
		
		new String:class[40];
		if ((IsValidPlayer(Attacker)) && (GetClientTeam(Attacker) == 2) && (CurrentGamemodeID != 1)) {
			PrintToChatAll("\x04[TANK]\x05%s \x01%t.", GetName(Attacker), "tankkill1");
			AddScore(Attacker, 100);
			
			new hp = GetClientHealth(Attacker);
			new wep = GetPlayerWeaponSlot(Attacker, 0);
			
			if (hp < 150) {
				if (hp+50 >= 150) hp = 150; else hp = hp + 50;
				SetEntityHealth(Attacker, hp);
			}
			
			if (wep != -1) {
				GetEdictClassname(wep, class, sizeof(class));
				if ( (!StrEqual(class, "weapon_grenade_launcher", false)) && (StrContains(class, "sniper") == -1) ) {
					if (StrEqual(class, "weapon_rifle_m60", false)) {
						new ammo = GetEntProp(GetPlayerWeaponSlot(Attacker, 0), Prop_Send, "m_iClip1");
						if ((ammo+100) >= 250) SetEntProp(GetPlayerWeaponSlot(Attacker, 0), Prop_Send, "m_iClip1", 250);
						else SetEntProp(GetPlayerWeaponSlot(Attacker, 0), Prop_Send, "m_iClip1", ammo+100);
					}
					else AddWeaponAmmo(Attacker, 100);
					
				}
			}
			
		}
		
		if (InfHulk[Victim] == 1) {
			InfHulk[Victim] = 0;
			PrintToChatAll("\x05[TANK] \x04%t!", "hulkdead");
			ResetClientInfAbilites(Victim);
		}
		
		if (TankChaos[Victim] > 0) {
			TankChaos[Victim] = 0;
			ResetClientInfAbilites(Victim);
		}
		
		if ((InfHulk[Victim] == 0) && (TankChaos[Victim] == 0)) {
			HulkAllow = false;
			if (HulkResetTimer != INVALID_HANDLE) KillTimer(HulkResetTimer);
			HulkResetTimer = CreateTimer(300.0, HulkAllowResetTimer);
		}
	}
	//////
	
	new String:class[40];
				
	if (IsValidPlayer(Attacker) && (IsNormalPlayer(Victim))) {
		if (AttackerTeam == 2) {
			if (SurvVampire[Attacker] > 0) {
				new health = GetClientHealth(Attacker);
				if (health < 150) {
					if (health + 3 >= 150) health = 150;  else health = health + 3;
					SetEntityHealth(Attacker, health);
				}
				PrintToChat(Attacker, "\x05+3 HP \x03%t.", "Vampire1");
			}
			if ((SurvGift[Attacker] > 0) && (!blast)) {
				new wep = GetPlayerWeaponSlot(Attacker, 0);
				if (wep != -1) {
					GetEdictClassname(wep, class, sizeof(class));
					if (!StrEqual(class, "weapon_grenade_launcher", false)) {
						new ammo = GetEntProp(GetPlayerWeaponSlot(Attacker, 0), Prop_Send, "m_iClip1");
						
						if ((StrEqual(class, "weapon_rifle_m60", false)) && ((ammo+10) >= 250)) SetEntProp(GetPlayerWeaponSlot(Attacker, 0), Prop_Send, "m_iClip1", 250);
						else SetEntProp(GetPlayerWeaponSlot(Attacker, 0), Prop_Send, "m_iClip1", ammo+10);
						
						PrintToChat(Attacker, "\x05+10 %t \x03t", "municion", "ZombiePresents");
					}
				}
			}
		}	
	}
	
	if ((IsNormalPlayer(Victim)) && (VictimTeam == 3)) {
			AllowBuy[Victim] = false;
			CreateTimer(5.0, AllowBuyTimer, Victim);
			
			InfSpeedUp[Victim] = 0;
			SetEntDataFloat(Victim, g_flLagMovement, 1.0, true);
			
			InfBonusDamage[Victim] = 0;
			InfSpecialShield[Victim] = 0;
			InfBonusHealth[Victim] = 0;
			InfAcidClaws[Victim] = 0;
			InfFireShield[Victim] = 0;
			InfMask[Victim] = 0;
			InfMeeleShield[Victim] = 0;
			InfRegen[Victim] = 0;
			InfHulk[Victim] = 0;
			InfHobbits[Victim] = 0;
			InfAntiYell[Victim] = 0;
	}
	
	MA_Rebuild();
	//aaaa
	
	 
	// Self inflicted death does not count
	if (Attacker == Victim)
		return;
	
	if ( (Victim == VictimID) && (IsNormalPlayer(Victim)) && (IsValidPlayer(Attacker)) && (VictimTeam == 2) && (AttackerTeam == 3) ) {
		
			PrintToChatAll("\x05%s \x01%t \x04%t\x01! %t\x03+300 \x04%t", GetName(Attacker), "vickill1", "Victimran1", "vickill2", "vickill5");
			points[Attacker] += 300;
			
	}
	
	if ( (Victim == VictimID) && (IsNormalPlayer(Victim)) && (VictimTeam == 2) && (CurrentGamemodeID != 1) ) {
		InfMassSlow_Sum = InfMassSlow_Cost;
		InfDeathCloud_Sum = InfDeathCloud_Cost;
		InfZombieApoc_Sum = InfZombieApoc_Cost;
		InfPoison_Sum = InfPoison_Cost;
		PrintToChatAll("\x05%t \x04%t.", "vickill3", "vickill4");
	}
		
			
		
	//if (!VictimIsBot)
	//	DoInfectedFinalChecks(Victim, ClientInfectedType[Victim]);


	if (Attacker == 0 || AttackerIsBot)
	{
		// Attacker is normal indected but the Victim was infected by blinding and/or paralysation.
		if (Attacker == 0
				&& VictimTeam == TEAM_SURVIVORS
				&& (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1]
					|| PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1]
					|| PlayerLunged[Victim][0] && PlayerLunged[Victim][1]
					|| PlayerCarried[Victim][0] && PlayerCarried[Victim][1]
					|| PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1]
					|| PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
				&& IsGamemodeVersus())
			PlayerDeathExternal(Victim);

		if (CurrentGamemodeID == GAMEMODE_SURVIVAL && Victim > 0 && VictimTeam == TEAM_SURVIVORS)
			CheckSurvivorsAllDown();

		return;
	}

	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:AttackerName[MAX_LINE_WIDTH];
	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
	decl String:VictimName[MAX_LINE_WIDTH];
	new VictimInfType = -1;

	if (Victim > 0)
	{
		GetClientName(Victim, VictimName, sizeof(VictimName));

		if (VictimTeam == TEAM_INFECTED)
			VictimInfType = GetInfType(Victim);
		if ((VictimInfType == INF_ID_TANK_L4D2)) {
			ResetClientInfAbilites(Victim);
		}
		if (InfHulk[Victim] > 0) {
			InfHulk[Victim] = 0;
			PrintToChatAll("\x05%t", "hulkdead");
		}
	}
	else
	{
		GetEventString(event, "victimname", VictimName, sizeof(VictimName));

		if (StrEqual(VictimName, "hunter", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_HUNTER;
		}
		else if (StrEqual(VictimName, "smoker", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_SMOKER;
		}
		else if (StrEqual(VictimName, "boomer", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_BOOMER;
		}
		if (StrEqual(VictimName, "spitter", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_SPITTER_L4D2;
		}
		else if (StrEqual(VictimName, "jockey", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_JOCKEY_L4D2;
		}
		else if (StrEqual(VictimName, "charger", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_CHARGER_L4D2;
		}
		else if (StrEqual(VictimName, "tank", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_TANK_L4D2;
		}
		else
			return;
	}

	// The wearoff should now work properly! Don't initialize
	//if (Victim > 0 && (VictimInfType == INF_ID_HUNTER || VictimInfType == INF_ID_SMOKER))
	//	InitializeClientInf(Victim);

	if (VictimTeam == TEAM_SURVIVORS)
		CheckSurvivorsAllDown();

	// Team Kill: Attacker is a Survivor and Victim is Survivor
	if (AttackerTeam == TEAM_SURVIVORS && VictimTeam == TEAM_SURVIVORS)
	{
		new Score = 0;
		if (GetConVarBool(cvar_EnableNegativeScore))
		{
			if (!IsClientBot(Victim))
				Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FKill), 2, 4, TEAM_SURVIVORS);
			else
			{
				new Float:BotScoreMultiplier = GetConVarFloat(cvar_BotScoreMultiplier);

				if (BotScoreMultiplier > 0.0)
					Score = RoundToNearest(ModifyScoreDifficultyNR(GetConVarInt(cvar_FKill), 2, 4, TEAM_SURVIVORS) * BotScoreMultiplier);
			}
		}
		else
			Mode = 0;

		decl String:UpdatePoints[32];

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			}
			case GAMEMODE_REALISM:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
			}
			case GAMEMODE_REALISMVERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
			}
			case GAMEMODE_MUTATIONS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
			}
			default:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points");
			}
		}

		decl String:query[1024];
		Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i, award_teamkill = award_teamkill + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, AttackerID);
		SendSQLUpdate(query);
		AddScore(Attacker, -Score);

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Attacker, "%t \x03%t\x04%i \x01%t \x03%t\x05%s\x01!", "youhave", "perdido", Score, "puntospor", "matar1", VictimName);
		else if (Mode == 3)
			StatsPrintToChatAll("\x05%s \x01has \x03LOST \x04%i \x01points for \x03Team Killing \x05%s\x01!", AttackerName, Score, VictimName);
	}

	// Attacker is a Survivor
	else if (AttackerTeam == TEAM_SURVIVORS && VictimTeam == TEAM_INFECTED)
	{
		new Score = 0;
		decl String:InfectedType[8];

		if (VictimInfType == INF_ID_HUNTER)
		{
			Format(InfectedType, sizeof(InfectedType), "hunter");
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Hunter), 2, 3, TEAM_SURVIVORS);
		}
		else if (VictimInfType == INF_ID_SMOKER)
		{
			Format(InfectedType, sizeof(InfectedType), "smoker");
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Smoker), 2, 3, TEAM_SURVIVORS);
		}
		else if (VictimInfType == INF_ID_BOOMER)
		{
			Format(InfectedType, sizeof(InfectedType), "boomer");
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Boomer), 2, 3, TEAM_SURVIVORS);
		}
		else if (VictimInfType == INF_ID_SPITTER_L4D2)
		{
			Format(InfectedType, sizeof(InfectedType), "spitter");
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Spitter), 2, 3, TEAM_SURVIVORS);
		}
		else if (VictimInfType == INF_ID_JOCKEY_L4D2)
		{
			Format(InfectedType, sizeof(InfectedType), "jockey");
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Jockey), 2, 3, TEAM_SURVIVORS);
		}
		else if (VictimInfType == INF_ID_CHARGER_L4D2)
		{
			Format(InfectedType, sizeof(InfectedType), "charger");
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Charger), 2, 3, TEAM_SURVIVORS);
		}
		else
			return;

		new String:Headshot[32];
		if (GetEventBool(event, "headshot"))
		{
			Format(Headshot, sizeof(Headshot), ", headshots = headshots + 1");
			Score = Score + 2;
		}

		Score = GetMedkitPointReductionScore(Score);

		decl String:UpdatePoints[32];

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			}
			case GAMEMODE_REALISM:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
			}
			case GAMEMODE_REALISMVERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
			}
			case GAMEMODE_MUTATIONS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
			}
			default:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points");
			}
		}

		new len = 0;
		decl String:query[1024];
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET %s = %s + %i, ", DbPrefix, UpdatePoints, UpdatePoints, Score);
		len += Format(query[len], sizeof(query)-len, "kills = kills + 1, kill_%s = kill_%s + 1", InfectedType, InfectedType);
		len += Format(query[len], sizeof(query)-len, "%s WHERE steamid = '%s'", Headshot, AttackerID);
		SendSQLUpdate(query);

		if (Mode && Score > 0)
		{
			if (GetEventBool(event, "headshot"))
			{
				if (Mode > 1)
				{
					GetClientName(Attacker, AttackerName, sizeof(AttackerName));
					if (!ClientRankMute[Attacker]) StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for killing%s \x05%s \x01with a \x04HEAD SHOT\x01!", AttackerName, Score, (VictimIsBot ? " a" : ""), VictimName);
				}
				else
					if (!ClientRankMute[Attacker]) StatsPrintToChat(Attacker, "You have earned \x04%i \x01points for killing%s \x05%s \x01with a \x04HEAD SHOT\x01!", Score, (VictimIsBot ? " a" : ""), VictimName);
			}
			else
			{
				if (Mode > 2)
				{
					GetClientName(Attacker, AttackerName, sizeof(AttackerName));
					StatsPrintToChatAll("\x05%s \x01%t \x04%i \x01%t %t %s \x05%s\x01!", AttackerName, "haganado", Score, "puntospor", "matar", (VictimIsBot ? " a" : ""), VictimName);
				}
				else
					StatsPrintToChat(Attacker, "%t \x04%i \x01%t %t %s \x05%s\x01!", "hasganado", Score, "puntospor", "matar", (VictimIsBot ? " a" : ""), VictimName);
			}
		}

		UpdateMapStat("kills", 1);
		UpdateMapStat("points", Score);
		AddScore(Attacker, Score);
	}

	// Attacker is an Infected
	else if (AttackerTeam == TEAM_INFECTED && VictimTeam == TEAM_SURVIVORS)
		SurvivorDiedNamed(Attacker, Victim, VictimName, AttackerID, -1, Mode);

	if (VictimTeam == TEAM_SURVIVORS)
	{
		if (PanicEvent)
			PanicEventIncap = true;

		if (PlayerVomited)
			PlayerVomitedIncap = true;
	}
}

// Common Infected death code. +1 on headshot.

public Action:event_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetEventInt(event, "infected_id");
	
	if (!Attacker || IsClientBot(Attacker) || GetClientTeam(Attacker) == TEAM_INFECTED)
		return;

	new Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Infected), 2, 3, TEAM_SURVIVORS);
	
	if (GetEventBool(event, "headshot"))
	{
		Score = Score + 1;
		TimerHeadshots[Attacker] = TimerHeadshots[Attacker] + 1;
	}

	TimerPoints[Attacker] = TimerPoints[Attacker] + Score;
	TimerKills[Attacker] = TimerKills[Attacker] + 1;

	// Melee?
	if (ServerVersion != SERVER_VERSION_L4D1)
	{
		new WeaponID = GetEventInt(event, "weapon_id");

		if (WeaponID == 19)
			IncrementMeleeKills(Attacker);
	}

	//decl String:AttackerName[MAX_LINE_WIDTH];
	//GetClientName(Attacker, AttackerName, sizeof(AttackerName));

	//LogMessage("[DEBUG] %s killed an infected (Weapon ID: %i)", AttackerName, WeaponID);
	//PrintToConsoleAll("[DEBUG] %s killed an infected (Weapon ID: %i)", AttackerName, WeaponID);
}

// Check player validity before calling this method!
IncrementMeleeKills(client)
{
	if (MeleeKillTimer[client] != INVALID_HANDLE)
		CloseHandle(MeleeKillTimer[client]);

	MeleeKillCounter[client]++;
	MeleeKillTimer[client] = CreateTimer(5.0, timer_MeleeKill, client);
}

// Tank death code. Points are given to all players.

public Action:event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	
	new VictimInfType = -1;
	
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:AttackerIsBot = GetEventBool(event, "attackerisbot");
	new bool:VictimIsBot = GetEventBool(event, "victimisbot");
		
    //if (TankCount >= 3)
	//	return;

	new Score;
	Score = 20;
	//Score = ModifyScoreDifficulty(GetConVarInt(cvar_Tank), 2, 4, TEAM_SURVIVORS);
	
	new Mode = GetConVarInt(cvar_AnnounceMode);
	new Deaths = 0;
	new Modifier = 0;

	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			if (IsPlayerAlive(i))
				Modifier++;
			else
				Deaths++;
		}
	}

	//if (TankChaos[Victim] > 0) Score = 20;
	//else Score = Score * Modifier;
	
	TankChaos[Victim] = 0;

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:iID[MAX_LINE_WIDTH];
	decl String:query[512];

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			GetClientRankAuthString(i, iID, sizeof(iID));
			Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_tankkill = award_tankkill + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, iID);
			SendSQLUpdate(query);

			AddScore(i, Score);
		}
	}

	if (Mode && Score > 0)
		StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03%t \x01%t \x04%i \x01%t %t Tank %t \x05%i %t\x01!", "allsurv", "hanganado", Score, "puntospor", "matar", "con", Deaths, "muertes");

	UpdateMapStat("kills", 1);
	UpdateMapStat("points", Score);
	TankCount = TankCount + 1;
}

// Adrenaline give code. Special note, Adrenalines can only be given once. (Even if it's initially given by a bot!)

GiveAdrenaline(Giver, Recipient, AdrenalineID = -1)
{
	// Stats enabled is checked by the caller

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !SurvivalStarted)
		return;

	if (AdrenalineID < 0)
		AdrenalineID = GetPlayerWeaponSlot(Recipient, 4);

	if (AdrenalineID < 0 || Adrenaline[AdrenalineID] == 1)
		return;
	else
		Adrenaline[AdrenalineID] = 1;

	if (IsClientBot(Giver))
		return;

	decl String:RecipientName[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientName, sizeof(RecipientName));
	decl String:RecipientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Recipient, RecipientID, sizeof(RecipientID));

	decl String:GiverName[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverName, sizeof(GiverName));
	decl String:GiverID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Giver, GiverID, sizeof(GiverID));

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Adrenaline), 2, 4, TEAM_SURVIVORS);
	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_adrenaline = award_adrenaline + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, GiverID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	AddScore(Giver, Score);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Giver, "%t \x04%i \x01%t %t \x05%s\x01!", "hasganado", Score, "puntospor", "daradrenalinaa", RecipientName);
		else if (Mode == 3)
			StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for giving adrenaline to \x05%s\x01!", GiverName, Score, RecipientName);
	}
}

// Pill give event. (From give a weapon)

public Action:event_GivePills(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	
	if (StatsDisabled())
		return;

	// If given weapon != 12 (Pain Pills) then return
	if (GetEventInt(event, "weapon") != 12)
		return;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !GetConVarBool(cvar_EnableSvMedicPoints))
		return;

	new Recipient = GetClientOfUserId(GetEventInt(event, "userid"));
	new Giver = GetClientOfUserId(GetEventInt(event, "giver"));
	new PillsID = GetEventInt(event, "weaponentid");

	GivePills(Giver, Recipient, PillsID);
}

// Pill give code. Special note, Pills can only be given once. (Even if it's initially given by a bot!)

GivePills(Giver, Recipient, PillsID = -1)
{
	// Stats enabled is checked by the caller

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !SurvivalStarted)
		return;

	if (PillsID < 0)
		PillsID = GetPlayerWeaponSlot(Recipient, 4);

	if (PillsID < 0 || Pills[PillsID] == 1)
		return;
	else
		Pills[PillsID] = 1;

	if (IsClientBot(Giver))
		return;

	decl String:RecipientName[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientName, sizeof(RecipientName));
	decl String:RecipientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Recipient, RecipientID, sizeof(RecipientID));

	decl String:GiverName[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverName, sizeof(GiverName));
	decl String:GiverID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Giver, GiverID, sizeof(GiverID));

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Pills), 2, 4, TEAM_SURVIVORS);
	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_pills = award_pills + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, GiverID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	AddScore(Giver, Score);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Giver, "%t \x04 %i \x01 %t %t \x05 %s \x01!", "hasganado", Score, "puntospor", "darpildorasa", RecipientName);
		else if (Mode == 3)
			StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for giving pills to \x05%s\x01!", GiverName, Score, RecipientName);
	}
}

// Defibrillator used code.

public Action:event_DefibPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && (!SurvivalStarted || !GetConVarBool(cvar_EnableSvMedicPoints)))
		return;

	new Recipient = GetClientOfUserId(GetEventInt(event, "subject"));
	new Giver = GetClientOfUserId(GetEventInt(event, "userid"));

	new bool:GiverIsBot = IsClientBot(Giver);
	new bool:RecipientIsBot = IsClientBot(Recipient);

	if (CurrentGamemodeID != GAMEMODE_SURVIVAL && (!GiverIsBot || (GiverIsBot && (GetConVarInt(cvar_MedkitBotMode) >= 2 || (!RecipientIsBot && GetConVarInt(cvar_MedkitBotMode) >= 1)))))
	{
		MedkitsUsedCounter++;
		AnnounceMedkitPenalty();
	}

	if (IsClientBot(Giver))
		return;

	// How is this possible?
	if (Recipient == Giver)
		return;

	decl String:RecipientName[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientName, sizeof(RecipientName));
	decl String:RecipientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Recipient, RecipientID, sizeof(RecipientID));

	decl String:GiverName[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverName, sizeof(GiverName));
	decl String:GiverID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Giver, GiverID, sizeof(GiverID));

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Defib), 2, 4, TEAM_SURVIVORS);

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_defib = award_defib + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, GiverID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	AddScore(Giver, Score);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);
		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Giver, "%t \x04 %i \x01 %t %t \x05 %s\x01 %t!", "hasganado",  Score, "puntospor", "revivira", RecipientName, "usingdef");
		else if (Mode == 3)
			StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for Reviving \x05%s\x01 using a Defibrillator!", GiverName, Score, RecipientName);
	}
}

// Medkit give code.

public Action:event_HealPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && (!SurvivalStarted || !GetConVarBool(cvar_EnableSvMedicPoints)))
		return;

	new Recipient = GetClientOfUserId(GetEventInt(event, "subject"));
	new Giver = GetClientOfUserId(GetEventInt(event, "userid"));
	new Amount = GetEventInt(event, "health_restored");
	
	new bool:GiverIsBot = IsClientBot(Giver);
	new bool:RecipientIsBot = IsClientBot(Recipient);

	CreateTimer(0.5, CheckClientHPTimer, Recipient);
	
	if (CurrentGamemodeID != GAMEMODE_SURVIVAL && (!GiverIsBot || (GiverIsBot && (GetConVarInt(cvar_MedkitBotMode) >= 2 || (!RecipientIsBot && GetConVarInt(cvar_MedkitBotMode) >= 1)))))
	{
		MedkitsUsedCounter++;
		AnnounceMedkitPenalty();
	}

	if (GiverIsBot)
		return;

	if (Recipient == Giver)
		return;

	decl String:RecipientName[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientName, sizeof(RecipientName));
	decl String:RecipientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Recipient, RecipientID, sizeof(RecipientID));

	decl String:GiverName[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverName, sizeof(GiverName));
	decl String:GiverID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Giver, GiverID, sizeof(GiverID));

	new Score = (Amount + 1) / 2;
	if (GetConVarInt(cvar_MedkitMode))
		Score = ModifyScoreDifficulty(GetConVarInt(cvar_Medkit), 2, 4, TEAM_SURVIVORS);
	else
		Score = ModifyScoreDifficulty(Score, 2, 3, TEAM_SURVIVORS);

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_medkit = award_medkit + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, GiverID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	AddScore(Giver, Score);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);
		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Giver, "%t \x04%i \x01%t %t \x05%s\x01!", "hasganado", Score, "puntospor", "curar", RecipientName);
		else if (Mode == 3)
			StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for healing \x05%s\x01!", GiverName, Score, RecipientName);
	}
}

// Friendly fire code.

public Action:event_FriendlyFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!Attacker || !Victim)
		return;

//	if (IsClientBot(Victim))
//		return;

	new FFMode = GetConVarInt(cvar_FriendlyFireMode);

	if (FFMode == 1)
	{
		new CooldownMode = GetConVarInt(cvar_FriendlyFireCooldownMode);

		if (CooldownMode == 1 || CooldownMode == 2)
		{
			new Target = 0;

			// Player specific : CooldownMode = 1
			// General : CooldownMode = 2
			if (CooldownMode == 1)
				Target = Victim;

			if (FriendlyFireCooldown[Attacker][Target])
				return;

			FriendlyFireCooldown[Attacker][Target] = true;

			if (FriendlyFirePrmCounter >= MAXPLAYERS)
				FriendlyFirePrmCounter = 0;

			FriendlyFirePrm[FriendlyFirePrmCounter][0] = Attacker;
			FriendlyFirePrm[FriendlyFirePrmCounter][1] = Target;
			FriendlyFireTimer[Attacker][Target] = CreateTimer(GetConVarFloat(cvar_FriendlyFireCooldown), timer_FriendlyFireCooldownEnd, FriendlyFirePrmCounter++);
		}
	}
	else if (FFMode == 2)
	{
		// Friendly fire is calculated in player_hurt event (Damage based)
		return;
	}

	UpdateFriendlyFire(Attacker, Victim);
}

// Campaign win code.

public Action:event_CampaignWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	return;
	if (CampaignOver || StatsDisabled())
		return;

	CampaignOver = true;

	StopMapTiming();

	if (CurrentGamemodeID == GAMEMODE_SCAVENGE ||
			CurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_VictorySurvivors), 4, 12, TEAM_SURVIVORS);
	new Mode = GetConVarInt(cvar_AnnounceMode);
	new SurvivorCount = GetEventInt(event, "survivorcount");
	new ClientTeam, bool:NegativeScore = GetConVarBool(cvar_EnableNegativeScore);

	Score *= SurvivorCount;

	decl String:query[1024];
	decl String:iID[MAX_LINE_WIDTH];
	decl String:UpdatePoints[32], String:UpdatePointsPenalty[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			Format(UpdatePointsPenalty, sizeof(UpdatePointsPenalty), "points_infected");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
			Format(UpdatePointsPenalty, sizeof(UpdatePointsPenalty), "points_realism_infected");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, iID, sizeof(iID));
				if (strlen(iID) > 25) return;
				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_campaigns = award_campaigns + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, iID);
				SendSQLUpdate(query);

				if (Score > 0)
				{
					UpdateMapStat("points", Score);
					AddScore(i, Score);
				}
			}
			else if (ClientTeam == TEAM_INFECTED && NegativeScore)
			{
				GetClientRankAuthString(i, iID, sizeof(iID));
				if (strlen(iID) > 25) return;
				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i WHERE steamid = '%s'", DbPrefix, UpdatePointsPenalty, UpdatePointsPenalty, Score, iID);
				SendSQLUpdate(query);

				if (Score < 0)
					AddScore(i, Score * (-1));
			}
		}
	}

	if (Mode && Score > 0)
	{
		StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03ALL SURVIVORS \x01have earned \x04%i \x01points for winning the \x04Campaign Finale \x01with \x05%i survivors\x01!", Score, SurvivorCount);

		if (NegativeScore)
			StatsPrintToChatTeam(TEAM_INFECTED, "\x03ALL INFECTED \x01have \x03LOST \x04%i \x01points for loosing the \x04Campaign Finale \x01to \x05%i survivors\x01!", Score, SurvivorCount);
	}
}

// Safe House reached code. Points are given to all players.
// Also, Witch Not Disturbed code, points also given to all players.

public Action:event_MapTransition(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundEndProc();
}

// Begin panic event.

public Action:event_PanicEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	
	if (StatsDisabled())
		return;

	if (CampaignOver || PanicEvent)
		return;

	PanicEvent = true;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL)
	{
		SurvivalStart();
		return;
	}

	CreateTimer(75.0, timer_PanicEventEnd);
}

// Panic Event with no Incaps code. Points given to all players.

public Action:timer_PanicEventEnd(Handle:timer, Handle:hndl)
{
	if (StatsDisabled())
		return;

	if (CampaignOver || CurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (PanicEvent && !PanicEventIncap)
	{
		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Panic), 2, 4, TEAM_SURVIVORS);

		if (Score > 0)
		{
			decl String:query[1024];
			decl String:iID[MAX_LINE_WIDTH];
			decl String:UpdatePoints[32];

			switch (CurrentGamemodeID)
			{
				case GAMEMODE_VERSUS:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
				}
				case GAMEMODE_REALISM:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
				}
				case GAMEMODE_SCAVENGE:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
				}
				case GAMEMODE_REALISMVERSUS:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
				}
				case GAMEMODE_MUTATIONS:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
				}
				default:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points");
				}
			}

			new maxplayers = GetMaxClients();
			for (new i = 1; i <= maxplayers; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
				{
					GetClientRankAuthString(i, iID, sizeof(iID));
					if (strlen(iID) > 25) return;
					Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i WHERE steamid = '%s' ", DbPrefix, UpdatePoints, UpdatePoints, Score, iID);
					SendSQLUpdate(query);
					UpdateMapStat("points", Score);
					AddScore(i, Score);
				}
			}

			if (Mode)
				StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03%t \x01%t \x04%i \x01%t \x05%t\x01!", "allsurv", "hanganado", Score, "puntospor", "afterpanic");
		}
	}

	PanicEvent = false;
	PanicEventIncap = false;
}

// Begin Boomer blind.

public Action:event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (StatsGetClientTeam(Attacker) != TEAM_INFECTED)
		return;

	PlayerVomited = true;

//	new bool:Infected = GetEventBool(event, "infected");
//
//	if (!Infected)
//		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsClientBot(Attacker))
		return;

	PlayerBlinded[Victim][0] = 1;
	PlayerBlinded[Victim][1] = Attacker;

	BoomerHitCounter[Attacker]++;

	if (TimerBoomerPerfectCheck[Attacker] != INVALID_HANDLE)
	{
		CloseHandle(TimerBoomerPerfectCheck[Attacker]);
		TimerBoomerPerfectCheck[Attacker] = INVALID_HANDLE;
	}

	TimerBoomerPerfectCheck[Attacker] = CreateTimer(6.0, timer_BoomerBlindnessCheck, Attacker);
}

// Boomer Mob Survival with no Incaps code. Points are given to all players.

public Action:event_PlayerBlindEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (StatsGetClientTeam(Player) != TEAM_SURVIVORS)
		return;

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndBoomerBlinded, Player);

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (PlayerVomited && !PlayerVomitedIncap)
	{
		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_BoomerMob), 2, 5, TEAM_SURVIVORS);

		if (Score > 0)
		{
			decl String:query[1024];
			decl String:iID[MAX_LINE_WIDTH];
			decl String:UpdatePoints[32];

			switch (CurrentGamemodeID)
			{
				case GAMEMODE_VERSUS:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
				}
				case GAMEMODE_REALISM:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
				}
				case GAMEMODE_SURVIVAL:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
				}
				case GAMEMODE_SCAVENGE:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
				}
				case GAMEMODE_REALISMVERSUS:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
				}
				case GAMEMODE_MUTATIONS:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
				}
				default:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points");
				}
			}

			new maxplayers = GetMaxClients();
			for (new i = 1; i <= maxplayers; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
				{
					GetClientRankAuthString(i, iID, sizeof(iID));
					if (strlen(iID) > 25) return;
					Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i WHERE steamid = '%s' ", DbPrefix, UpdatePoints, UpdatePoints, Score, iID);
					SendSQLUpdate(query);
					UpdateMapStat("points", Score);
					AddScore(i, Score);
				}
			}

			if (Mode)
				StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03%t \x01%t \x04%i \x01%t \x05%t\x01!", "allsurv", "hanganado", Score, "puntospor", "afterboomer");
		}
	}

	PlayerVomited = false;
	PlayerVomitedIncap = false;
}

// Friendly Incapicitate code. Also handles if players should be awarded
// points for surviving a Panic Event or Boomer Mob without incaps.

PlayerIncap(Attacker, Victim)
{
	// Stats enabled and CampaignOver is checked by the caller

	if (PanicEvent)
		PanicEventIncap = true;

	if (PlayerVomited)
		PlayerVomitedIncap = true;

	if (Victim <= 0)
		return;

	if (!Attacker || IsClientBot(Attacker))
	{
		// Attacker is normal indected but the Victim was infected by blinding and/or paralysation.
		if (Attacker == 0
				&& Victim > 0
				&& (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1]
					|| PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1]
					|| PlayerLunged[Victim][0] && PlayerLunged[Victim][1]
					|| PlayerCarried[Victim][0] && PlayerCarried[Victim][1]
					|| PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1]
					|| PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
				&& IsGamemodeVersus())
			PlayerIncapExternal(Victim);

		if (CurrentGamemodeID == GAMEMODE_SURVIVAL && Victim > 0)
			CheckSurvivorsAllDown();

		return;
	}

	new AttackerTeam = GetClientTeam(Attacker);
	new VictimTeam = GetClientTeam(Victim);
	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (VictimTeam == TEAM_SURVIVORS)
		CheckSurvivorsAllDown();

	if (Attacker == Victim) return;
		
	// Attacker is a Survivor
	if (AttackerTeam == TEAM_SURVIVORS && VictimTeam == TEAM_SURVIVORS)
	{
		decl String:AttackerID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
		if (strlen(AttackerID) > 25) return;
		
		decl String:AttackerName[MAX_LINE_WIDTH];
		GetClientName(Attacker, AttackerName, sizeof(AttackerName));

		decl String:VictimName[MAX_LINE_WIDTH];
		GetClientName(Victim, VictimName, sizeof(VictimName));

		new Score = 0;
		if (GetConVarBool(cvar_EnableNegativeScore))
		{
			if (!IsClientBot(Victim))
				Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FIncap), 2, 4, TEAM_SURVIVORS);
			else
			{
				new Float:BotScoreMultiplier = GetConVarFloat(cvar_BotScoreMultiplier);

				if (BotScoreMultiplier > 0.0)
					Score = RoundToNearest(ModifyScoreDifficultyNR(GetConVarInt(cvar_FIncap), 2, 4, TEAM_SURVIVORS) * BotScoreMultiplier);
			}
		}
		else
			Mode = 0;

		decl String:UpdatePoints[32];

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			}
			case GAMEMODE_REALISM:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
			}
			case GAMEMODE_REALISMVERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
			}
			case GAMEMODE_MUTATIONS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
			}
			default:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points");
			}
		}

		decl String:query[512];
		Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i, award_fincap = award_fincap + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, AttackerID);
		SendSQLUpdate(query);
		AddScore(Attacker, -Score);

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Attacker, "You have \x03LOST \x04%i \x01points for \x03Incapicitating \x05%s\x01!", Score, VictimName);
		else if (Mode == 3)
			StatsPrintToChatAll("\x05%s \x01has \x03LOST \x04%i \x01points for \x03Incapicitating \x05%s\x01!", AttackerName, Score, VictimName);
	}

	// Attacker is an Infected
	else if (AttackerTeam == TEAM_INFECTED && VictimTeam == TEAM_SURVIVORS)
	{
		SurvivorIncappedByInfected(Attacker, Victim, Mode);
	}
}

// Friendly Incapacitate event.

public Action:event_PlayerIncap(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((IsValidPlayer(Attacker)) && (IsValidPlayer(Victim)) && (Victim == VictimID) && (Victim != Attacker) && (GetClientTeam(Attacker) != GetClientTeam(Victim))) {
		PrintToChatAll("\x04%s \x01%t %t \x04%s, \x01%t \x04+100 %t", GetName(Attacker), "VictimIncap1", "Victimran1", GetName(VictimID), "VictimIncap2", "points");
		points[Attacker] += 100;
	}
	
	PlayerIncap(Attacker, Victim);
}

// Save friendly from being dragged by Smoker.

public Action:event_TongueSave(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	
	HunterSmokerSave(GetEventInt(event, "userid"), GetEventInt(event, "victim"), GetConVarInt(cvar_SmokerDrag), 2, 3, "Smoker", "award_smoker");
}

// Save friendly from being choked by Smoker.

public Action:event_ChokeSave(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	HunterSmokerSave(GetEventInt(event, "userid"), GetEventInt(event, "victim"), GetConVarInt(cvar_ChokePounce), 2, 3, "Smoker", "award_smoker");
}

// Save friendly from being pounced by Hunter.

public Action:event_PounceSave(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "Victim"));

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndHunterLunged, Victim);

	HunterSmokerSave(GetEventInt(event, "userid"), Victim, GetConVarInt(cvar_ChokePounce), 2, 3, "Hunter", "award_hunter");
}

// Player is hanging from a ledge.

public Action:event_PlayerFallDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver || !IsGamemodeVersus())
		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(event, "causer"));
	new Damage = RoundToNearest(GetEventFloat(event, "damage"));

	if (Attacker == 0 && PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
		Attacker = PlayerJockied[Victim][1];

	if (Attacker == 0 || IsClientBot(Attacker) || GetClientTeam(Attacker) != TEAM_INFECTED || GetClientTeam(Victim) != TEAM_SURVIVORS || Damage <= 0)
		return;

	new VictimHealth = GetClientHealth(Victim);
	new VictimIsIncap = GetEntProp(Victim, Prop_Send, "m_isIncapacitated");

	// If the victim health is zero or below zero or is incapacitated don't count the damage from the fall
	if (VictimHealth <= 0 || VictimIsIncap != 0)
		return;

	// Damage should never exceed the amount of healt the fallen survivor had before falling down.
	if (VictimHealth < Damage)
		Damage = VictimHealth;

	if (Damage <= 0)
		return;

	SurvivorHurt(Attacker, Victim, Damage);
}

// Player melee killed an infected

public Action:event_MeleeKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	//new EntityID = GetEventInt(event, "entityid");
	//new bool:Ambushed = GetEventBool(event, "ambush");

	if (Attacker == 0 || IsClientBot(Attacker) || GetClientTeam(Attacker) != TEAM_SURVIVORS || !IsClientConnected(Attacker) || !IsClientInGame(Attacker))
		return;

	IncrementMeleeKills(Attacker);
}

// Player is hanging from a ledge.

public Action:event_PlayerLedge(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || !IsGamemodeVersus())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "causer"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Attacker == 0 && PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
		Attacker = PlayerJockied[Victim][1];

	if (Attacker == 0 || IsClientBot(Attacker) || GetClientTeam(Attacker) != TEAM_INFECTED)
		return;

	new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_PlayerLedgeSuccess), 0.9, 0.8, TEAM_INFECTED);

	if ((Score > 0) && (IsValidPlayer(Attacker)))
	{
		decl String:VictimName[MAX_LINE_WIDTH];
		GetClientName(Victim, VictimName, sizeof(VictimName));

		new Mode = GetConVarInt(cvar_AnnounceMode);

		decl String:ClientID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Attacker, ClientID, sizeof(ClientID));

		decl String:query[1024];
		if (CurrentGamemodeID == GAMEMODE_VERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_ledgegrab = award_ledgegrab + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
		else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_ledgegrab = award_ledgegrab + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
		else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
			Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_ledgegrab = award_ledgegrab + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
		else
			Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_ledgegrab = award_ledgegrab + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);

		SendSQLUpdate(query);
		AddScore(Attacker, Score);
		
		UpdateMapStat("points_infected", Score);

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Attacker, "You have earned \x04%i \x01points for causing player \x05%s\x01 to grab a ledge!", Score, VictimName);
		else if (Mode == 3)
		{
			decl String:AttackerName[MAX_LINE_WIDTH];
			GetClientName(Attacker, AttackerName, sizeof(AttackerName));
			StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for causing player \x05%s\x01 to grab a ledge!", AttackerName, Score, VictimName);
		}
	}
}

// Player spawned in game.

public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsNormalPlayer(Player)) return;
		
	if (IsEnd()) return;
	if (CampaignOver) return;
	if (MapEnd > 0) return;
	
	killshield(Player);
	
	//if ((InfTankChaos > 0) && (GetClientTeam(Player) == 3)) TankChaos[Player] = 1;
	TankChaos[Player] = 0;
	
	InitializeClientInf(Player);
	
	

	ClientInfectedType[Player] = 0;
	BoomerHitCounter[Player] = 0;
	BoomerVomitUpdated[Player] = false;
	SmokerDamageCounter[Player] = 0;
	SpitterDamageCounter[Player] = 0;
	JockeyDamageCounter[Player] = 0;
	ChargerDamageCounter[Player] = 0;
	ChargerImpactCounter[Player] = 0;
	TankPointsCounter[Player] = 0;
	TankDamageCounter[Player] = 0;
	TankDamageTotalCounter[Player] = 0;
	TankSurvivorKillCounter[Player] = 0;
	ChargerCarryVictim[Player] = 0;
	ChargerPlummelVictim[Player] = 0;
	JockeyVictim[Player] = 0;
	JockeyRideStartTime[Player] = 0;

	PlayerBlinded[Player][0] = 0;
	PlayerBlinded[Player][1] = 0;
	PlayerParalyzed[Player][0] = 0;
	PlayerParalyzed[Player][1] = 0;
	PlayerLunged[Player][0] = 0;
	PlayerLunged[Player][1] = 0;
	PlayerPlummeled[Player][0] = 0;
	PlayerPlummeled[Player][1] = 0;
	PlayerCarried[Player][0] = 0;
	PlayerCarried[Player][1] = 0;
	PlayerJockied[Player][0] = 0;
	PlayerJockied[Player][1] = 0;

	if (!IsClientBot(Player))
		SetClientInfectedType(Player);

	if (ChargerImpactCounterTimer[Player] != INVALID_HANDLE)
		CloseHandle(ChargerImpactCounterTimer[Player]);

	ChargerImpactCounterTimer[Player] = INVALID_HANDLE;
	
	//new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	
	if ( (IsValidPlayer(Player)) && (GetClientTeam(Player) == 3) && (!IsTank(Player)) ) {
		if (VipBonus[Player][18] > 0) {
			InfSpecialShield[Player] = 5;
			PrintToChat(Player, "\x01%t: \x04%t 2  \x01%t: %i", "Activated", "SpecialShield", "Left", VipBonus[18]);
			VipBonus[Player][18] -= 1;
		}
		if (VipBonus[Player][22] > 0) {
			InfAcidClaws[Player] = 1;
			InfBonusDamage[Player] = 1;
			PrintToChat(Player, "\x01%t: \x04%t  \x01%t: %i", "Activated", "AcidClaws", "Left", VipBonus[22]);
			PrintToChat(Player, "\x01%t: \x04%t  \x01%t: %i", "Activated", "AcidClaws", "Left", VipBonus[22]);
			VipBonus[Player][22] -= 1;
		}
	}
	
	if ( (IsNormalPlayer(Player)) && (GetClientTeam(Player) == 3) && (IsFakeClient(Player)) && (CurrentGamemodeID == 0) ) {
		new chance = 0;
		new bool: doColor = false;
		new bool: pTank;
		 if (IsTank(Player)) pTank = true; else pTank = false;
		
		chance = GetRandomInt(1,100);
		if ( (chance <= 20) && (!pTank) ) { InfSpeedUp[Player] = 1; doColor = true; }
		chance = GetRandomInt(1,100);
		if (chance <= 20) { InfBonusDamage[Player] = 1; doColor = true; }
		chance = GetRandomInt(1,100);
		if ( (chance <= 20) && (!pTank) ) { InfSpecialShield[Player] = 1; doColor = true; }
		chance = GetRandomInt(1,100);
		if ( (chance <= 20) && (!pTank) ) { InfBonusHealth[Player] = 1; doColor = true; }
		chance = GetRandomInt(1,100);
		if (chance <= 20) { InfAcidClaws[Player] = 1; doColor = true; }
		chance = GetRandomInt(1,100);
		if ( (chance <= 20) && (!pTank) ) { InfFireShield[Player] = 1; doColor = true; }
		chance = GetRandomInt(1,100);
		if (chance <= 20) { InfMeeleShield[Player] = 1; doColor = true; }
		chance = GetRandomInt(1,100);
		if (chance <= 20) { InfRegen[Player] = 1; doColor = true; }
		chance = GetRandomInt(1,100);
		if ( (chance <= 20) && (!pTank) ) { InfAntiYell[Player] = 1; doColor = true; }
		
		if (doColor)  {
			CreateTimer(0.5, DoColorTimer, Player);
		}
	}
	
	decl String:s_ModelName[255];
	GetEntPropString(Player, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName));
	decl Bool:IsTank;
	if (StrContains(s_ModelName, "hulk") > -1) IsTank = true; else IsTank = false;
	
	if (IsNormalPlayer(Player))
	if (GetClientTeam(Player) == 3) {
	
		if (!IsTank) {
			if (InfBonusHealth[Player] == 1) {
				CreateTimer(0.5, SetBonusHealth, Player);
			}
			if (InfMask[Player] == 1) {
				SetEntityRenderMode(Player, RENDER_TRANSCOLOR);
				SetEntityRenderColor(Player, 190, 190, 255, 120);
			}
		}
		
		if (IsTank) OriginHealth[Player] = 7000;
		else
		OriginHealth[Player] = GetClientHealth(Player);
		
		if ((GetClientTeam(Player) == 3) && (SurvZombieSurprize > 0) && (GetRandomInt(1,100) <= 50)) {
			SDKCall(sdkCallVomitPlayer, Player, Player, true);
		}
	}
}

public Action:DoColorTimer(Handle:timer, int:client)
{
	if (!IsNormalPlayer(client)) return;
	
	new scalei = 0;
	if (InfSpeedUp[client] == 1) scalei++;
	if (InfBonusDamage[client] == 1) scalei++;
	if (InfSpecialShield[client] == 1) scalei++;
	if (InfBonusHealth[client] == 1) scalei++;
	if (InfAcidClaws[client] == 1) scalei++;
	if (InfFireShield[client] == 1) scalei++;
	if (InfMeeleShield[client] == 1) scalei++;
	if (InfRegen[client] == 1) scalei++;
	if (InfAntiYell[client] == 1) scalei++;
		
	if (scalei == 1) RenderBot[client] = CreateEnvSprite2(client, "0 255 255", "0.2");
	else if (scalei == 2) RenderBot[client] = CreateEnvSprite2(client, "0 255 255", "0.4");
	else if (scalei == 3) RenderBot[client] = CreateEnvSprite2(client, "0 255 255", "0.6");
	else if (scalei == 4) RenderBot[client] = CreateEnvSprite2(client, "0 255 255", "0.8");
	else if (scalei == 5) RenderBot[client] = CreateEnvSprite2(client, "0 255 255", "1.0");
	else if (scalei == 6) RenderBot[client] = CreateEnvSprite2(client, "0 255 255", "1.2");
	else if (scalei == 7) RenderBot[client] = CreateEnvSprite2(client, "0 255 255", "1.4");
	else if (scalei == 8) RenderBot[client] = CreateEnvSprite2(client, "0 255 255", "1.6");
	else if (scalei == 9) RenderBot[client] = CreateEnvSprite2(client, "0 255 255", "1.8");
		
}
			
// Player hurt. Used for calculating damage points for the Infected players and also
// the friendly fire damage when Friendly Fire Mode is set to Damage Based.

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (IsEnd()) return;
	
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new Damage = GetEventInt(event, "dmg_health");

	if ((Attacker == 0 || IsClientBot(Attacker)) && (IsNormalPlayer(Victim)))
	{
		// Attacker is normal indected but the Victim was infected by blinding and/or paralysation.
		if (Attacker == 0
		&& Victim > 0
		&& (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1]
		|| PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1]
		|| PlayerLunged[Victim][0] && PlayerLunged[Victim][1]
		|| PlayerCarried[Victim][0] && PlayerCarried[Victim][1]
		|| PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1]
		|| PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
		&& IsGamemodeVersus())
		SurvivorHurtExternal(event, Victim);
		
		return;
	}
	
	if ((!IsNormalPlayer(Victim)) || (!IsNormalPlayer(Attacker))) return;
	
	if (IsTank(Victim) && (InfHulk[Victim] != 1))
    {
	    decl String: i_Type;
	    i_Type = GetEventInt(event, "type");
                
        if (i_Type == 8 || i_Type == 2056 || i_Type == 268435464)
        {
            //new health = GetClientHealth(Victim);
			//new plusdamage = 5;
			//if (health-plusdamage < 0) SetEntityHealth(Victim, 0);
			//else SetEntityHealth(Victim, health-plusdamage);
        }
		
    }
	
	// Self inflicted damage does not count
	if (Attacker == Victim)
		return;

	if ((IsValidPlayer(Attacker)) && (IsValidPlayer(Victim)) && (Victim == VictimID) && (Damage > 0) && (GetClientTeam(Attacker) != GetClientTeam(Victim))) {
		new Dmg = Damage + Damage + Damage;
		if (Dmg >= 200) Dmg = 200;
		PrintHintTextToAll("%s %t (%s), %t: +%i %t", GetName(Attacker), "hintdamage1", GetName(VictimID), "VictimIncap2", Dmg, "points");
		points[Attacker] += Dmg;
	}
		

	new AttackerTeam = GetClientTeam(Attacker);
	new AttackerInfType = -1;

	new VictimTeam = GetClientTeam(Victim);
	if (AttackerTeam == VictimTeam && AttackerTeam == TEAM_INFECTED)
		return;

	if (IsNormalPlayer(Attacker))
	{
		if (AttackerTeam == TEAM_INFECTED)
			AttackerInfType = ClientInfectedType[Attacker];
		else if (AttackerTeam == TEAM_SURVIVORS && GetConVarInt(cvar_FriendlyFireMode) == 2)
		{
			if (VictimTeam == TEAM_SURVIVORS)
			{
				if (FriendlyFireTimer[Attacker][0] != INVALID_HANDLE)
				{
					CloseHandle(FriendlyFireTimer[Attacker][0]);
					FriendlyFireTimer[Attacker][0] = INVALID_HANDLE;
				}

				decl String:AttackerID[MAX_LINE_WIDTH];
				GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
				if (strlen(AttackerID) > 25) return;
				decl String:AttackerName[MAX_LINE_WIDTH];
				GetClientName(Attacker, AttackerName, sizeof(AttackerName));

				// Using datapack to deliver the needed info so that the attacker can't escape the penalty by disconnecting

				//new Handle:dp = INVALID_HANDLE;
				//dp = CreateDataPack();
				new OldHumanDamage = 0;
				new OldBotDamage = 0;
				//WritePackCell(dp, OldHumanDamage);
				//WritePackCell(dp, OldBotDamage);

				//if (!GetTrieValue(FriendlyFireDamageTrie, AttackerID, dp))
				//{
//					SetTrieValue(FriendlyFireDamageTrie, AttackerID, dp);
				//}
				//else
				//{
					// Read old damage value
//					ResetPack(dp);
					//OldHumanDamage = ReadPackCell(dp);
					//OldBotDamage = ReadPackCell(dp);
	
				//}

				if (IsClientBot(Victim))
					OldBotDamage += Damage;
				else
					OldHumanDamage += Damage;

				//ResetPack(dp, true);

				//WritePackCell(dp, OldHumanDamage);
				//WritePackCell(dp, OldBotDamage);
				//WritePackCell(dp, Attacker);
				//WritePackString(dp, AttackerID);
				//WritePackString(dp, AttackerName);

				// This may fail! What happens when a player skips and another joins with the same Client ID (is this even possible in such short time?)
				//FriendlyFireTimer[Attacker][0] = CreateTimer(5.0, timer_FriendlyFireDamageEnd, dp);
				
				return;
			}
		}
	}
	if (AttackerInfType < 0)
		return;

	SurvivorHurt(Attacker, Victim, Damage, AttackerInfType, event);
}

// Smoker events.

public Action:event_SmokerGrap(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || !IsGamemodeVersus() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerParalyzed[Victim][0] = 1;
	PlayerParalyzed[Victim][1] = Attacker;
}

// Jockey events.

public Action:event_JockeyStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerJockied[Victim][0] = 1;
	PlayerJockied[Victim][1] = Attacker;

	JockeyVictim[Attacker] = Victim;
	JockeyRideStartTime[Attacker] = 0;

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientConnected(Attacker) || !IsClientInGame(Attacker))
		return;

	JockeyRideStartTime[Attacker] = GetTime();

	decl String:query[1024];
	decl String:iID[MAX_LINE_WIDTH];
	if (!IsValidPlayer(Attacker)) return;
	GetClientRankAuthString(Attacker, iID, sizeof(iID));
	if (strlen(iID) > 25) return;
	Format(query, sizeof(query), "UPDATE %splayers SET jockey_rides = jockey_rides + 1 WHERE steamid = '%s'", DbPrefix, iID);
	SendSQLUpdate(query);
	UpdateMapStat("jockey_rides", 1);
}

public Action:event_JockeyRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new Rescuer = GetClientOfUserId(GetEventInt(event, "rescuer"));
	new Float:RideLength = GetEventFloat(event, "ride_length");

	if ((IsValidPlayer(Rescuer)) && !IsClientBot(Rescuer))
	{
		decl String:query[1024], String:JockeyName[MAX_LINE_WIDTH], String:VictimName[MAX_LINE_WIDTH], String:RescuerName[MAX_LINE_WIDTH], String:RescuerID[MAX_LINE_WIDTH], String:UpdatePoints[32];
		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_JockeyRide), 2, 3, TEAM_SURVIVORS);

		GetClientRankAuthString(Rescuer, RescuerID, sizeof(RescuerID));

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			}
			case GAMEMODE_REALISM:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
			}
			case GAMEMODE_REALISMVERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
			}
			case GAMEMODE_MUTATIONS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
			}
			default:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points");
			}
		}

		Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_jockey = award_jockey + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, RescuerID);
		SendSQLUpdate(query);

		if (Score > 0)
		{
			UpdateMapStat("points", Score);
			AddScore(Rescuer, Score);
		}

		GetClientName(Jockey, JockeyName, sizeof(JockeyName));
		GetClientName(Victim, VictimName, sizeof(VictimName));

		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (Score > 0)
		{
			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(Rescuer, "You have earned \x04%i \x01points for saving \x05%s \x01from \x04%s\x01!", Score, VictimName, JockeyName);
			else if (Mode == 3)
			{
				GetClientName(Rescuer, RescuerName, sizeof(RescuerName));
				StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for saving \x05%s \x01from \x04%s\x01!", RescuerName, Score, VictimName, JockeyName);
			}
		}
	}

	JockeyVictim[Jockey] = 0;

	if (Jockey == 0 || IsClientBot(Jockey) || !IsClientInGame(Jockey))
	{
		PlayerJockied[Victim][0] = 0;
		PlayerJockied[Victim][1] = 0;
		JockeyRideStartTime[Victim] = 0;
		return;
	}

	UpdateJockeyRideLength(Jockey, RideLength);

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndJockeyRide, Victim);
}

public Action:event_JockeyKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndJockeyRide, Victim);
}

// Charger events.

public Action:event_ChargerKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Killer = GetClientOfUserId(GetEventInt(event, "attacker"));

	//if (Killer == 0 || IsClientBot(Killer) || !IsClientInGame(Killer))
	if (!IsValidPlayer(Killer)) return;

	new Charger = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:query[1024], String:KillerName[MAX_LINE_WIDTH], String:KillerID[MAX_LINE_WIDTH], String:UpdatePoints[32];
	new Score = 0;
	new bool:IsMatador = GetEventBool(event, "melee") && GetEventBool(event, "charging");

	GetClientRankAuthString(Killer, KillerID, sizeof(KillerID));
	if (strlen(KillerID) > 25) return;
	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	if (ChargerCarryVictim[Charger])
	{
		Score += ModifyScoreDifficulty(GetConVarInt(cvar_ChargerCarry), 2, 3, TEAM_SURVIVORS);
	}
	else if (ChargerPlummelVictim[Charger])
	{
		Score += ModifyScoreDifficulty(GetConVarInt(cvar_ChargerPlummel), 2, 3, TEAM_SURVIVORS);
	}

	if (IsMatador)
	{
		// Give a Matador award
		Score += ModifyScoreDifficulty(GetConVarInt(cvar_Matador), 2, 3, TEAM_SURVIVORS);
	}

	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_charger = award_charger + 1%s WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, (IsMatador ? ", award_matador = award_matador + 1" : ""), KillerID);
	SendSQLUpdate(query);

	if (Score <= 0)
		return;

	UpdateMapStat("points", Score);
	AddScore(Killer, Score);

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode)
	{
		if (!IsValidPlayer(Killer)) return;
		GetClientName(Killer, KillerName, sizeof(KillerName));

		if (IsMatador)
		{
			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(Killer, "You have earned \x04%i \x01points for \x04Leveling a Charge\x01!", Score);
			else if (Mode == 3)
				StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for \x04Leveling a Charge\x01!", KillerName, Score);
		}
		else
		{
			decl String:VictimName[MAX_LINE_WIDTH], String:ChargerName[MAX_LINE_WIDTH];

			GetClientName(Charger, ChargerName, sizeof(ChargerName));

			//if (ChargerCarryVictim[Charger] > 0 && (IsClientBot(ChargerCarryVictim[Charger]) || (IsClientConnected(ChargerCarryVictim[Charger]) && IsClientInGame(ChargerCarryVictim[Charger]))))
			if (IsNormalPlayer(ChargerCarryVictim[Charger]))
			{
				GetClientName(ChargerCarryVictim[Charger], VictimName, sizeof(VictimName));
				Format(VictimName, sizeof(VictimName), "\x05%s\x01", VictimName);
			}
			else
				Format(VictimName, sizeof(VictimName), "a survivor");

			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(Killer, "You have earned \x04%i \x01points for saving %s from \x04%s\x01!", Score, VictimName, ChargerName);
			else if (Mode == 3)
				StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for saving %s from \x04%s\x01!", KillerName, Score, VictimName, ChargerName);
		}
	}
}

public Action:event_ChargerCarryStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerCarried[Victim][0] = 1;
	PlayerCarried[Victim][1] = Attacker;

	ChargerCarryVictim[Attacker] = Victim;

	if (IsClientBot(Attacker) || !IsClientConnected(Attacker) || !IsClientInGame(Attacker))
		return;

	IncrementImpactCounter(Attacker);
}

public Action:event_ChargerCarryRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	//new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	//if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	//{
	//	ChargerCarryVictim[Attacker] = 0;
	//	PlayerCarried[Victim][0] = 0;
	//	PlayerCarried[Victim][1] = 0;
	//	return;
	//}

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndChargerCarry, Victim);
}

public Action:event_ChargerImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientConnected(Attacker) || !IsClientInGame(Attacker))
		return;

	//new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	IncrementImpactCounter(Attacker);
}

IncrementImpactCounter(client)
{
	if (ChargerImpactCounterTimer[client] != INVALID_HANDLE)
		CloseHandle(ChargerImpactCounterTimer[client]);

	ChargerImpactCounterTimer[client] = CreateTimer(3.0, timer_EndCharge, client);

	ChargerImpactCounter[client]++;
}

public Action:event_ChargerPummelStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	// There is no delay on charger carry once the plummel starts
	ChargerCarryVictim[Attacker] = 0;

	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerPlummeled[Victim][0] = 1;
	PlayerPlummeled[Victim][1] = Attacker;

	ChargerPlummelVictim[Attacker] = Victim;

	//if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	//	return;
}

public Action:event_ChargerPummelRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	{
		PlayerPlummeled[Victim][0] = 0;
		PlayerPlummeled[Victim][1] = 0;
		ChargerPlummelVictim[Attacker] = 0;
		return;
	}

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndChargerPlummel, Victim);
}

// Hunter events.

public Action:event_HunterRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndHunterLunged, Player);
}

// Smoker events.

public Action:event_SmokerRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndSmokerParalyzed, Player);
}

// L4D2 ammo upgrade deployed event.

public Action:event_UpgradePackAdded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !SurvivalStarted)
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Player == 0 || IsClientBot(Player))
		return;

	new Score = GetConVarInt(cvar_AmmoUpgradeAdded);

	if (Score > 0)
		Score = ModifyScoreDifficulty(Score, 2, 3, TEAM_SURVIVORS);

	decl String:PlayerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Player, PlayerID, sizeof(PlayerID));
	if (strlen(PlayerID) > 25) return;
	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_upgrades_added = award_upgrades_added + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, PlayerID);

	SendSQLUpdate(query);
	AddScore(Player, Score);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (!Mode)
			return;

		new EntityID = GetEventInt(event, "upgradeid");
		decl String:ModelName[128];
		GetEntPropString(EntityID, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));

		if (StrContains(ModelName, "incendiary_ammo", false) >= 0)
			strcopy(ModelName, sizeof(ModelName), "Incendiary Ammo");
		else if (StrContains(ModelName, "exploding_ammo", false) >= 0)
			strcopy(ModelName, sizeof(ModelName), "Exploding Ammo");
		else
			strcopy(ModelName, sizeof(ModelName), "UNKNOWN");

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Player, "You have earned \x04%i \x01points for deploying \x05%s\x01!", Score, ModelName);
		else if (Mode == 3)
		{
			decl String:PlayerName[MAX_LINE_WIDTH];
			GetClientName(Player, PlayerName, sizeof(PlayerName));
			StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for deploying \x05%s\x01!", PlayerName, Score, ModelName);
		}
	}
}

// L4D2 gascan pour completed event.

public Action:event_GascanPoured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Player == 0 || IsClientBot(Player))
		return;

	new Score = GetConVarInt(cvar_GascanPoured);

	if (Score > 0)
		Score = ModifyScoreDifficulty(Score, 2, 3, TEAM_SURVIVORS);

	decl String:PlayerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Player, PlayerID, sizeof(PlayerID));
	if (strlen(PlayerID) > 25) return;
	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_gascans_poured = award_gascans_poured + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, PlayerID);

	SendSQLUpdate(query);
	AddScore(Player, Score);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Player, "You have earned \x04%i \x01points for successfully \x05Pouring a Gascan\x01!", Score);
		else if (Mode == 3)
		{
			decl String:PlayerName[MAX_LINE_WIDTH];
			GetClientName(Player, PlayerName, sizeof(PlayerName));
			StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for successfully \x05Pouring a Gascan\x01!", PlayerName, Score);
		}
	}
}

// Achievement earned.

/*
56 - Helping Hand
57 - Field Medic
58 - Pharm-Assist
59 - My Bodyguard
60 - Dead Stop
61 - Crownd
62 - Untouchables
63 -
64 - Drag and Drop
65 - Blind Luck
66 - Akimbo Assassin
67 -
68 - Hero Closet
69 - Hunter Punter
70 - Tongue Twister
71 - No Smoking Section
72 -
73 - 101 Cremations
74 - Do Not Disturb
75 - Man Vs Tank
76 - TankBusters
77 - Safety First
78 - No-one Left Behind
79 -
80 -
81 - Unbreakable
82 - Witch Hunter
83 - Red Mist
84 - Pyrotechnician
85 - Zombie Genocidest
86 - Dead Giveaway
87 - Stand Tall
88 -
89 -
90 - Zombicidal Maniac
91 - What are you trying to Prove?
92 -
93 - Nothing Special
94 - Burn the Witch
95 - Towering Inferno
96 - Spinal Tap
97 - Stomach Upset
98 - Brain Salad
99 - Jump Shot
100 - Mercy Killer
101 - Back 2 Help
102 - Toll Collector
103 - Dead Baron
104 - Grim Reaper
105 - Ground Cover
106 - Clean Kill
107 - Big Drag
108 - Chain Smoker
109 - Barf Bagged
110 - Double Jump
111 - All 4 Dead
112 - Dead Wreckening
113 - Lamb 2 Slaughter
114 - Outbreak
*/

public Action:event_Achievement(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "player"));
	new Achievement = GetEventInt(event, "achievement");

	if (IsClientBot(Player))
		return;

	if (DEBUG)
		LogMessage("Achievement earned: %i", Achievement);
}

// Saferoom door opens.

public Action:event_DoorOpen(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(MapTimingStartTime != 0.0 || !GetEventBool(event, "checkpoint") || !GetEventBool(event, "closed") || CurrentGamemodeID == GAMEMODE_SURVIVAL || StatsDisabled())
		return Plugin_Continue;

	StartMapTiming();

	return Plugin_Continue;
}

public Action:event_StartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(MapTimingStartTime != 0.0 || CurrentGamemodeID == GAMEMODE_SURVIVAL || StatsDisabled())
		return Plugin_Continue;

	StartMapTiming();

	return Plugin_Continue;
}



public Action:event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return Plugin_Continue;
	
	new Player = GetClientOfUserId(GetEventInt(event, "userid"));
	new NewTeam = GetEventInt(event, "team");
	new OldTeam = GetEventInt(event, "oldteam");
	
	if ( (NewTeam == OldTeam) || (OldTeam == 0) ) return Plugin_Continue;
			
	if ((IsNormalPlayer(Player)) && (Player == InfPoison) && (OldTeam == 2)) {
		ResetPoisonClient();
		PrintToChatAll("\x04[POISON]\x01%t", "Poisonedvs1");
		new pid = ChosePoisonClient();
		if (IsNormalPlayer(pid)) PrintToChatAll("\x04[POISON] \x05%s \x01%t", GetName(pid), "Poisoned1");
	}			

	if(MapTimingStartTime != 0.0 || GetEventBool(event, "isbot"))
		return Plugin_Continue;	
	
	if ((OldTeam == 3) && ((InfHulk[Player] > 0) || (TankChaos[Player] > 0))) {
		if (NewTeam == 1) PrintToChatAll("\x03Танк \x01перешел в зрители - \x04за что был убит.");
		else if (NewTeam != 1) PrintToChatAll("\x02Танк \x01перешел в другую команду - \x04за что был убит.");
		if (IsValidEntity(Player)) SetEntityHealth(Player, 0);
		InfHulk[Player] = 0;
	    TankChaos[Player] = 0;
	}
	
	if ( (Player == VictimID) && (OldTeam == 2) ) {
		if (NewTeam == 1) {
			PrintToChatAll("\x04[VICTIM] \x05%t\x01, %t", "Victimran1", "vicspec");
			VictimID = 0;
		}
		else if (NewTeam == 3) {
			PrintToChatAll("\x04[VICTIM] \x05%t\x01, %t", "Victimran1", "vicinf");
			PrintToChatAll("\x04[VICTIM] \x01%t", "victim2");
					
			VictimID = 0;
		}
		
		PrintToChatAll("\x04[VICTIM] \x05%t", "vicpenalty");
		for (new i = 1; i <= GetMaxClients(); i++) {
			if ((IsValidPlayer(i)) && (GetClientTeam(i) == 2) )
			points[i] -= 100;
		}
		
		
	}
		
	if (NewTeam != 1) UpdateMassCosts();
	
	if (!IsValidPlayer(Player))	return Plugin_Continue;
	
	decl String:PlayerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Player, PlayerID, sizeof(PlayerID));
	if (strlen(PlayerID) > 25) return Plugin_Continue;
	RemoveFromTrie(MapTimingSurvivors, PlayerID);
	RemoveFromTrie(MapTimingInfected, PlayerID);

	return Plugin_Continue;
}

// AbilityUse.

public Action:event_AbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidPlayer(Player)) return;
	GetClientAbsOrigin(Player, HunterPosition[Player]);

	if (!IsClientBot(Player) && GetClientInfectedType(Player) == INF_ID_BOOMER)
	{
		decl String:query[1024];
		decl String:iID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Player, iID, sizeof(iID));
		if (strlen(iID) > 25) return;
		Format(query, sizeof(query), "UPDATE %splayers SET infected_boomer_vomits = infected_boomer_vomits + 1 WHERE steamid = '%s'", DbPrefix, iID);
		SendSQLUpdate(query);
		UpdateMapStat("infected_boomer_vomits", 1);
		BoomerVomitUpdated[Player] = true;
	}
}

// Player got pounced.

public Action:event_PlayerPounced(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerLunged[Victim][0] = 1;
	PlayerLunged[Victim][1] = Attacker;

	if (IsClientBot(Attacker))
		return;

	new Float:PouncePosition[3];

	GetClientAbsOrigin(Attacker, PouncePosition);
	new PounceDistance = RoundToNearest(GetVectorDistance(HunterPosition[Attacker], PouncePosition));

	if (PounceDistance < MinPounceDistance)
		return;

	new Dmg = RoundToNearest((((PounceDistance - float(MinPounceDistance)) / float(MaxPounceDistance - MinPounceDistance)) * float(MaxPounceDamage)) + 1);
	new DmgCap = GetConVarInt(cvar_HunterDamageCap);

	if (Dmg > DmgCap)
		Dmg = DmgCap;

	new PerfectDmgLimit = GetConVarInt(cvar_HunterPerfectPounceDamage);
	new NiceDmgLimit = GetConVarInt(cvar_HunterNicePounceDamage);

	UpdateHunterDamage(Attacker, Dmg);

	if (Dmg < NiceDmgLimit && Dmg < PerfectDmgLimit)
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);

	decl String:AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));
	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
	if (strlen(AttackerID) > 25) return;
	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	new Score = 0;
	decl String:Label[32];
	decl String:query[1024];

	if (Dmg >= PerfectDmgLimit)
	{
		Score = GetConVarInt(cvar_HunterPerfectPounceSuccess);
		if (CurrentGamemodeID == GAMEMODE_VERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_pounce_perfect = award_pounce_perfect + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
		else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_pounce_perfect = award_pounce_perfect + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
		else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
			Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_pounce_perfect = award_pounce_perfect + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
		else
			Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_pounce_perfect = award_pounce_perfect + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
		Format(Label, sizeof(Label), "Death From Above");

		if (EnableSounds_Hunter_Perfect && GetConVarBool(cvar_SoundsEnabled))
			EmitSoundToAll(StatsSound_Hunter_Perfect);
	}
	else
	{
		Score = GetConVarInt(cvar_HunterNicePounceSuccess);
		if (CurrentGamemodeID == GAMEMODE_VERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_pounce_nice = award_pounce_nice + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
		else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_pounce_nice = award_pounce_nice + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
		else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
			Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_pounce_nice = award_pounce_nice + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
		else
			Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_pounce_nice = award_pounce_nice + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
		Format(Label, sizeof(Label), "Pain From Above");
	}

	SendSQLUpdate(query);
	AddScore(Attacker,Score);
	UpdateMapStat("points_infected", Score);

	if (Mode == 1 || Mode == 2)
		StatsPrintToChat(Attacker, "You have earned \x04%i \x01points for landing a \x05%s \x01Pounce on \x05%s\x01!", Score, Label, VictimName);
	else if (Mode == 3)
		StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for landing a \x05%s \x01Pounce on \x05%s\x01!", AttackerName, Score, Label, VictimName);
}

// Revive friendly code.

public Action:event_RevivePlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !SurvivalStarted)
		return;

	if (GetEventBool(event, "ledge_hang"))
		return;

	new Savior = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "subject"));
	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (IsClientBot(Savior) || IsClientBot(Victim))
		return;

	decl String:SaviorName[MAX_LINE_WIDTH];
	GetClientName(Savior, SaviorName, sizeof(SaviorName));
	decl String:SaviorID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Savior, SaviorID, sizeof(SaviorID));
	if (strlen(SaviorID) > 25) return;
	
	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));
	decl String:VID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Victim, VID, sizeof(VID));
	if (strlen(VID) > 25) return;

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Revive), 2, 3, TEAM_SURVIVORS);

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_revive = award_revive + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, SaviorID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	AddScore(Savior, Score);

	if (Score > 0)
	{
		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Savior, "You have earned \x04%i \x01points for Reviving \x05%s\x01!", Score, VictimName);
		else if (Mode == 3)
			StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for Reviving \x05%s\x01!", SaviorName, Score, VictimName);
	}
}

/*
L4D1:

56 - Helping Hand
57 - Field Medic
58 - Pharm-Assist
59 - My Bodyguard
60 - Dead Stop
61 - Crownd
62 - Untouchables
63 -
64 - Drag and Drop
65 - Blind Luck
66 - Akimbo Assassin
67 -
68 - Hero Closet
69 - Hunter Punter
70 - Tongue Twister
71 - No Smoking Section
72 -
73 - 101 Cremations
74 - Do Not Disturb
75 - Man Vs Tank
76 - TankBusters
77 - Safety First
78 - No-one Left Behind
79 -
80 -
81 - Unbreakable
82 - Witch Hunter
83 - Red Mist
84 - Pyrotechnician
85 - Zombie Genocidest
86 - Dead Giveaway
87 - Stand Tall
88 -
89 -
90 - Zombicidal Maniac
91 - What are you trying to Prove?
92 -
93 - Nothing Special
94 - Burn the Witch
95 - Towering Inferno
96 - Spinal Tap
97 - Stomach Upset
98 - Brain Salad
99 - Jump Shot
100 - Mercy Killer
101 - Back 2 Help
102 - Toll Collector
103 - Dead Baron
104 - Grim Reaper
105 - Ground Cover
106 - Clean Kill
107 - Big Drag
108 - Chain Smoker
109 - Barf Bagged
110 - Double Jump
111 - All 4 Dead
112 - Dead Wreckening
113 - Lamb 2 Slaughter
114 - Outbreak
*/

// Miscellaneous events and awards. See specific award for info.

public Action:event_Award_L4D1(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	new PlayerID = GetEventInt(event, "userid");

	if (!PlayerID)
		return;

	new User = GetClientOfUserId(PlayerID);

	if (IsClientBot(User))
		return;

	new SubjectID = GetEventInt(event, "subjectentid");
	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:UserName[MAX_LINE_WIDTH];
	GetClientName(User, UserName, sizeof(UserName));

	new Recipient;
	decl String:RecipientName[MAX_LINE_WIDTH];

	new Score = 0;
	new String:AwardSQL[128];
	new AwardID = GetEventInt(event, "award");

	if (AwardID == 67) // Protect friendly
	{
		if (!SubjectID)
			return;

		ProtectedFriendlyCounter[User]++;

		if (TimerProtectedFriendly[User] != INVALID_HANDLE)
		{
			CloseHandle(TimerProtectedFriendly[User]);
			TimerProtectedFriendly[User] = INVALID_HANDLE;
		}

		TimerProtectedFriendly[User] = CreateTimer(3.0, timer_ProtectedFriendly, User);

		return;
	}
	else if (AwardID == 79) // Respawn friendly
	{
		if (!SubjectID)
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));

		if (IsClientBot(Recipient))
			return;

		Score = ModifyScoreDifficulty(GetConVarInt(cvar_Rescue), 2, 3, TEAM_SURVIVORS);
		GetClientName(Recipient, RecipientName, sizeof(RecipientName));
		Format(AwardSQL, sizeof(AwardSQL), ", award_rescue = award_rescue + 1");
		UpdateMapStat("points", Score);
		AddScore(User, Score);

		if (Score > 0)
		{
			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(User, "You have earned \x04%i \x01points for Rescuing \x05%s\x01!", Score, RecipientName);
			else if (Mode == 3)
				StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for Rescuing \x05%s\x01!", UserName, Score, RecipientName);
		}
	}
	else if (AwardID == 80) // Kill Tank with no deaths
	{
		Score = ModifyScoreDifficulty(0, 1, 1, TEAM_SURVIVORS);
		Format(AwardSQL, sizeof(AwardSQL), ", award_tankkillnodeaths = award_tankkillnodeaths + 1");
	}
// Moved to event_PlayerDeath
//	else if (AwardID == 83 && !CampaignOver) // Team kill
//	{
//		if (!SubjectID)
//			return;
//
//		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));
//
//		Format(AwardSQL, sizeof(AwardSQL), ", award_teamkill = award_teamkill + 1");
//		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FKill), 2, 4, TEAM_SURVIVORS);
//		Score = Score * -1;
//
//		if (Mode == 1 || Mode == 2)
//			StatsPrintToChat(User, "You have \x03LOST \x04%i \x01points for \x03Team Killing!", Score);
//		else if (Mode == 3)
//			StatsPrintToChatAll("\x05%s \x01has \x03LOST \x04%i \x01points for \x03Team Killing!", UserName, Score);
//	}
	else if (AwardID == 85) // Left friendly for dead
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_left4dead = award_left4dead + 1");
		Score = ModifyScoreDifficulty(0, 1, 1, TEAM_SURVIVORS);
	}
	else if (AwardID == 94) // Let infected in safe room
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_letinsafehouse = award_letinsafehouse + 1");

		Score = 0;
		if (GetConVarBool(cvar_EnableNegativeScore))
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_InSafeRoom), 2, 4, TEAM_SURVIVORS);
		else
			Mode = 0;

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(User, "You have \x03LOST \x04%i \x01points for letting \x03Infected In The Safe Room!", Score);
		else if (Mode == 3)
			StatsPrintToChatAll("\x05%s \x01has \x03LOST \x04%i \x01points for letting \x03Infected In The Safe Room!", UserName, Score);

		Score = Score * -1;
	}
	else if (AwardID == 98) // Round restart
	{
		UpdateMapStat("restarts", 1);

		if (!GetConVarBool(cvar_EnableNegativeScore))
			return;

		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Restart), 2, 3, TEAM_SURVIVORS);
		Score = 400 - Score;

		if (Mode)
			StatsPrintToChat(User, "\x03ALL SURVIVORS \x01have \x03LOST \x04%i \x01points for \x03All Survivors Dying!", Score);

		Score = Score * -1;
	}
	else
	{
//		if (DEBUG)
//			LogError("event_Award => %i", AwardID);
//StatsPrintToChat(User, "[DEBUG] event_Award => %i", AwardID);
		return;
	}

	decl String:UpdatePoints[32];
	decl String:UserID[MAX_LINE_WIDTH];
	GetClientRankAuthString(User, UserID, sizeof(UserID));
	if (strlen(UserID) > 25) return;

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i%s WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, AwardSQL, UserID);
	SendSQLUpdate(query);
	AddScore(User, Score);
}

/*
L4D2:
0 - End of Campaign (Not 100% Sure)
7 - End of Level (Not 100% Sure)
8 - End of Level (Not 100% Sure)
17 - Kill Tank
22 - Random Director Mob
23 - End of Level (Not 100% Sure)
40 - End of Campaign (Not 100% Sure)
67 - Protect Friendly
68 - Give Pain Pills
69 - Give Adrenaline
70 - Give Heatlh (Heal using Med Pack)
71 - End of Level (Not 100% Sure)
72 - End of Campaign (Not 100% Sure)
75 - Save Friendly from Ledge Grasp
76 - Save Friendly from Special Infected
80 - Hero Closet Rescue Survivor
81 - Kill Tank with no deaths
84 - Team Kill
85 - Incap Friendly
86 - Left Friendly for Dead
87 - Friendly Fire
89 - Incap Friendly
95 - Let infected in safe room
99 - Round Restart (All Dead)
*/

// Miscellaneous events and awards. See specific award for info.

public Action:event_Award_L4D2(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	new PlayerID = GetEventInt(event, "userid");

	if (!PlayerID)
		return;

	new User = GetClientOfUserId(PlayerID);

	if (IsClientBot(User))
		return;

	new SubjectID = GetEventInt(event, "subjectentid");
	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:UserName[MAX_LINE_WIDTH];
	GetClientName(User, UserName, sizeof(UserName));

	new Recipient;
	decl String:RecipientName[MAX_LINE_WIDTH];

	new Score = 0;
	new String:AwardSQL[128];
	new AwardID = GetEventInt(event, "award");

	//StatsPrintToChat(User, "[TEST] Your actions gave you award (ID = %i)", AwardID);

	if (AwardID == 67) // Protect friendly
	{
		if (!SubjectID)
			return;

		ProtectedFriendlyCounter[User]++;

		if (TimerProtectedFriendly[User] != INVALID_HANDLE)
		{
			CloseHandle(TimerProtectedFriendly[User]);
			TimerProtectedFriendly[User] = INVALID_HANDLE;
		}

		TimerProtectedFriendly[User] = CreateTimer(3.0, timer_ProtectedFriendly, User);

		return;
	}

	if (AwardID == 68) // Pills given
	{
		if (!SubjectID)
			return;

		if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !GetConVarBool(cvar_EnableSvMedicPoints))
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));

		GivePills(User, Recipient);

		return;
	}

	if (AwardID == 69) // Adrenaline given
	{
		if (!SubjectID)
			return;

		if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !GetConVarBool(cvar_EnableSvMedicPoints))
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));

		GiveAdrenaline(User, Recipient);

		return;
	}

	if (AwardID == 85) // Incap friendly
	{
		if (!SubjectID)
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));

		PlayerIncap(User, Recipient);

		return;
	}

	if (AwardID == 80) // Respawn friendly
	{
		if (!SubjectID)
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));

		if (IsClientBot(Recipient))
			return;

		Score = ModifyScoreDifficulty(GetConVarInt(cvar_Rescue), 2, 3, TEAM_SURVIVORS);
		GetClientName(Recipient, RecipientName, sizeof(RecipientName));
		Format(AwardSQL, sizeof(AwardSQL), ", award_rescue = award_rescue + 1");
		UpdateMapStat("points", Score);
		AddScore(User, Score);

		if (Score > 0)
		{
			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(User, "You have earned \x04%i \x01points for Rescuing \x05%s\x01!", Score, RecipientName);
			else if (Mode == 3)
				StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for Rescuing \x05%s\x01!", UserName, Score, RecipientName);
		}
	}
	else if (AwardID == 81) // Kill Tank with no deaths
	{
		Score = ModifyScoreDifficulty(0, 1, 1, TEAM_SURVIVORS);
		Format(AwardSQL, sizeof(AwardSQL), ", award_tankkillnodeaths = award_tankkillnodeaths + 1");
	}
// Moved to event_PlayerDeath
//	else if (AwardID == 84 && !CampaignOver) // Team kill
//	{
//		if (!SubjectID)
//			return;
//
//		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));
//
//		Format(AwardSQL, sizeof(AwardSQL), ", award_teamkill = award_teamkill + 1");
//		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FKill), 2, 4, TEAM_SURVIVORS);
//		Score = Score * -1;
//
//		if (Mode == 1 || Mode == 2)
//			StatsPrintToChat(User, "You have \x03LOST \x04%i \x01points for \x03Team Killing!", Score);
//		else if (Mode == 3)
//			StatsPrintToChatAll("\x05%s \x01has \x03LOST \x04%i \x01points for \x03Team Killing!", UserName, Score);
//	}
	else if (AwardID == 86) // Left friendly for dead
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_left4dead = award_left4dead + 1");
		Score = ModifyScoreDifficulty(0, 1, 1, TEAM_SURVIVORS);
	}
	else if (AwardID == 95) // Let infected in safe room
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_letinsafehouse = award_letinsafehouse + 1");

		Score = 0;
		if (GetConVarBool(cvar_EnableNegativeScore))
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_InSafeRoom), 2, 4, TEAM_SURVIVORS);
		else
			Mode = 0;

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(User, "You have \x03LOST \x04%i \x01points for letting \x03Infected In The Safe Room!", Score);
		else if (Mode == 3)
			StatsPrintToChatAll("\x05%s \x01has \x03LOST \x04%i \x01points for letting \x03Infected In The Safe Room!", UserName, Score);

		Score = Score * -1;
	}
	else if (AwardID == 99) // Round restart
	{
		UpdateMapStat("restarts", 1);

		if (!GetConVarBool(cvar_EnableNegativeScore))
			return;

		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Restart), 2, 3, TEAM_SURVIVORS);
		Score = 400 - Score;

		if (Mode)
			StatsPrintToChat(User, "\x03ALL SURVIVORS \x01have \x03LOST \x04%i \x01points for \x03All Survivors Dying!", Score);

		Score = Score * -1;
	}
	else
	{
//StatsPrintToChat(User, "[DEBUG] event_Award => %i", AwardID);
		return;
	}

	decl String:UpdatePoints[32];
	decl String:UserID[MAX_LINE_WIDTH];
	GetClientRankAuthString(User, UserID, sizeof(UserID));
	if (strlen(UserID) > 25) return;

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i%s WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, AwardSQL, UserID);
	SendSQLUpdate(query);
	
}

// Scavenge halftime code.

public Action:event_ScavengeHalftime(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	CampaignOver = true;

	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			switch (GetClientTeam(i))
			{
				case TEAM_SURVIVORS:
					InterstitialPlayerUpdate(i);
				case TEAM_INFECTED:
					DoInfectedFinalChecks(i);
			}
		}
	}
}

// Survival started code.

public Action:event_SurvivalStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	SurvivalStart();
	//RoundStartInit();	
}

public SurvivalStart()
{
	UpdateMapStat("restarts", 1);
	SurvivalStarted = true;
	MapTimingStartTime = 0.0;
	StartMapTiming();
}

// Car alarm triggered code.

public Action:event_CarAlarm(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled() || CurrentGamemodeID == GAMEMODE_SURVIVAL || !GetConVarBool(cvar_EnableNegativeScore))
		return;

	new Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_CarAlarm), 2, 3, TEAM_SURVIVORS);
	UpdateMapStat("caralarm", 1);

	if (Score <= 0)
		return;

	decl String:UpdatePoints[32];
	decl String:query[1024];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	new maxplayers = GetMaxClients();
	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:iID[MAX_LINE_WIDTH];

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			GetClientRankAuthString(i, iID, sizeof(iID));
			if (strlen(iID) > 25) return;
			Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, iID);
			SendSQLUpdate(query);
			AddScore(i, -Score);

			if (Mode)
				StatsPrintToChat(i, "\x03ALL SURVIVORS \x01have \x03LOST \x04%i \x01points for \x03Triggering the Car Alarm\x01!", Score);
		}
	}
}

// Reset Witch existence in the world when a new one is created.

public Action:event_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	WitchExists = true;
	new ent = GetEventInt(event, "witchid");
	//CreateTimer(0.5, CheckWitchDistance, ent);	
}

public Action:CheckWitchDistance(Handle:timer, any:ent)
{
	if (!IsValidEntity(ent)) {
	  //PrintToChatAll("ent not valid");
	  return;
	}
	//PrintToChatAll("checking distance ...");
    new distance = GetEntDistance(ent, 700);
	//PrintToChatAll("distance: %i", distance);
	
	//if (FloatCompare(distance, -1.0) != 0) {
	if (distance != -1) {
		AcceptEntityInput(ent, "Kill"); 
		PrintToChatAll("\x05%t. \x01Witch reseted.", "ToClose");
		return;
	}

}
// Witch was crowned!

public Action:event_WitchCrowned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled() || CurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	new Killer = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:Crowned = GetEventBool(event, "oneshot");

	if (Crowned && Killer > 0 && !IsClientBot(Killer) && IsClientConnected(Killer) && IsClientInGame(Killer))
	{
		decl String:SteamID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Killer, SteamID, sizeof(SteamID));
		if (strlen(SteamID) > 25) return;
		
		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_WitchCrowned), 2, 3, TEAM_SURVIVORS);
		decl String:UpdatePoints[32];

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			}
			case GAMEMODE_REALISM:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
			}
			case GAMEMODE_REALISMVERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
			}
			case GAMEMODE_MUTATIONS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
			}
			default:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points");
			}
		}

		decl String:query[1024];
		Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_witchcrowned = award_witchcrowned + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, SteamID);
		SendSQLUpdate(query);
		AddScore(Killer, Score);
		
		if (Score > 0 && GetConVarInt(cvar_AnnounceMode))
		{
			decl String:Name[MAX_LINE_WIDTH];
			GetClientName(Killer, Name, sizeof(Name));

			StatsPrintToChatTeam(TEAM_SURVIVORS, "\x05%s \x01has earned \x04%i \x01points for \x04Crowning the Witch\x01!", Name, Score);
		}
	}
}

// Witch was disturbed!

public Action:event_WitchDisturb(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	if (StatsDisabled())
		return;

	if (WitchExists)
	{
		WitchDisturb = true;

		if (!GetEventInt(event, "userid"))
			return;

		new User = GetClientOfUserId(GetEventInt(event, "userid"));

		if (IsClientBot(User))
			return;

		decl String:UserID[MAX_LINE_WIDTH];
		GetClientRankAuthString(User, UserID, sizeof(UserID));
		if (strlen(UserID) > 25) return;

		decl String:query[1024];
		Format(query, sizeof(query), "UPDATE %splayers SET award_witchdisturb = award_witchdisturb + 1 WHERE steamid = '%s'", DbPrefix, UserID);
		SendSQLUpdate(query);
	}
}

// DEBUG
//public Action:cmd_StatsTest(client, args)
//{
//	new String:CurrentMode[16];
//	GetConVarString(cvar_Gamemode, CurrentMode, sizeof(CurrentMode));
//	PrintToConsole(0, "Gamemode: %s", CurrentMode);
	//UpdateMapStat("playtime", 10);
//	PrintToConsole(0, "Added 10 seconds to maps table current map.");
//	new Float:ReductionFactor = GetMedkitPointReductionFactor();
//
//	StatsPrintToChat(client, "\x03ALL SURVIVORS \x01now earns only \x04%i percent \x01of their normal points after using their \x05%i%s Medkit\x01!", RoundToNearest(ReductionFactor * 100), MedkitsUsedCounter, (MedkitsUsedCounter == 1 ? "st" : (MedkitsUsedCounter == 2 ? "nd" : (MedkitsUsedCounter == 3 ? "rd" : "th"))), GetClientTeam(client));
//}

/*
-----------------------------------------------------------------------------
Chat/command handling and panels for Rank and Top10
-----------------------------------------------------------------------------
*/

public Action:HandleCommands(client, const String:Text[])
{
	/*
	if (strcmp(Text, "rankmenu", false) == 0)
	{
		cmd_ShowRankMenu(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text, "rank", false) == 0)
	{
		cmd_ShowRank(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showrank", false) == 0)
	{
		cmd_ShowRanks(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showppm", false) == 0)
	{
		cmd_ShowPPMs(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text, "top10", false) == 0)
	{
		cmd_ShowTop10(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text, "top10ppm", false) == 0)
	{
		cmd_ShowTop10PPM(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text, "nextrank", false) == 0)
	{
		cmd_ShowNextRank(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showtimer", false) == 0)
	{
		cmd_ShowTimedMapsTimer(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text, "timedmaps", false) == 0)
	{
		cmd_TimedMaps(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showmaptime", false) == 0)
	{
		cmd_ShowMapTimes(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text, "maptimes", false) == 0)
	{
		cmd_MapTimes(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text, "rankvote", false) == 0)
	{
		cmd_RankVote(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text, "rankmutetoggle", false) == 0)
	{
		cmd_ToggleClientRankMute(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}
	*/
	return Plugin_Continue;
}

// Parse chat for RANK and TOP10 triggers.
public Action:cmd_Say(client, args)
{
	/*
	decl String:Text[192];
	new String:Command[64];
	new Start = 0;

	GetCmdArgString(Text, sizeof(Text));

	if (Text[strlen(Text)-1] == '"')
	{
		Text[strlen(Text)-1] = '\0';
		Start = 1;
	}

	if (strcmp(Command, "say2", false) == 0)
		Start += 4;

	return HandleCommands(client, Text[Start]);
	*/
}

// Show current Timed Maps timer.
public Action:cmd_ShowTimedMapsTimer(client, args)
{
	if (client != 0 && !IsClientConnected(client) && !IsClientInGame(client))
		return Plugin_Handled;

	if (client != 0 && IsClientBot(client))
		return Plugin_Handled;

	if (MapTimingStartTime <= 0.0)
	{
		if (client == 0)
			PrintToConsole(0, "[RANK] Map timer has not started");
		else
			StatsPrintToChatPreFormatted(client, "Map timer has not started");

		return Plugin_Handled;
	}

	new Float:CurrentMapTimer = GetEngineTime() - MapTimingStartTime;
	decl String:TimeLabel[32];

	SetTimeLabel(CurrentMapTimer, TimeLabel, sizeof(TimeLabel));

	if (client == 0)
		PrintToConsole(0, "[RANK] Current map timer: %s", TimeLabel);
	else
		StatsPrintToChat(client, "Current map timer: \x04%s", TimeLabel);

	return Plugin_Handled;
}

// Begin generating the NEXTRANK display panel.
public Action:cmd_ShowNextRank(client, args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client))
		return Plugin_Handled;

	if (IsClientBot(client))
		return Plugin_Handled;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));
	if (strlen(SteamID) > 25) return Plugin_Handled;
	
	QueryClientStatsSteamID(client, SteamID, CM_NEXTRANK);

	return Plugin_Handled;
}

// Clear database.
//public Action:cmd_RankAdmin(client, args)
//{
//	if (!client)
//		return Plugin_Handled;
//
//	new Handle:RankAdminPanel = CreatePanel();
//
//	SetPanelTitle(RankAdminPanel, "Rank Admin:");
//
//	DrawPanelItem(RankAdminPanel, "Clear...");
//	DrawPanelItem(RankAdminPanel, "Clear Players");
//	DrawPanelItem(RankAdminPanel, "Clear Maps");
//	DrawPanelItem(RankAdminPanel, "Clear All");
//
//	SendPanelToClient(RankAdminPanel, client, RankAdminPanelHandler, 30);
//	CloseHandle(RankAdminPanel);
//
//	return Plugin_Handled;
//}

DisplayYesNoPanel(client, const String:title[], MenuHandler:handler, delay=30)
{
	if (!client)
		return;

	new Handle:panel = CreatePanel();

	SetPanelTitle(panel, title);

	DrawPanelItem(panel, "Yes");
	DrawPanelItem(panel, "No");

	SendPanelToClient(panel, client, handler, delay);
	CloseHandle(panel);
}

// Run Team Shuffle.
public Action:cmd_ShuffleTeams(client, args)
{
	if (!IsGamemode("versus") && !IsGamemode("realismversus") && !IsGamemode("scavenge"))
	{
		PrintToConsole(client, "[RANK] Team shuffle is not enabled in this gamemode!");
		return Plugin_Handled;
	}

	if (RankVoteTimer != INVALID_HANDLE)
	{
		CloseHandle(RankVoteTimer);
		RankVoteTimer = INVALID_HANDLE;

		StatsPrintToChatAllPreFormatted("Team shuffle executed by administrator.");
	}

	PrintToConsole(client, "[RANK] Executing team shuffle...");
	CreateTimer(1.0, timer_ShuffleTeams);

	return Plugin_Handled;
}

// Set Message Of The Day.
public Action:cmd_SetMotd(client, args)
{
	decl String:arg[1024];

	GetCmdArgString(arg, sizeof(arg));

	UpdateServerSettings(client, "motdmessage", arg, "Message Of The Day");

	return Plugin_Handled;
}

// Clear database.
public Action:cmd_ClearRank(client, args)
{
	if (client == 0)
	{
		PrintToConsole(client, "[RANK] Clear Stats: Database clearing from server console currently disabled because of a bug in it! Run the command from in-game console or from Admin Panel.");
		
		return Plugin_Handled;
	}

	if (ClearDatabaseTimer != INVALID_HANDLE)
		CloseHandle(ClearDatabaseTimer);

	ClearDatabaseTimer = INVALID_HANDLE;

	if (ClearDatabaseCaller == client)
	{
		PrintToConsole(client, "[RANK] Clear Stats: Started clearing the database!");
		ClearDatabaseCaller = -1;

		ClearStatsAll(client);

		return Plugin_Handled;
	}

	PrintToConsole(client, "[RANK] Clear Stats: To clear the database, execute this command again in %.2f seconds!", CLEAR_DATABASE_CONFIRMTIME);
	ClearDatabaseCaller = client;

	ClearDatabaseTimer = CreateTimer(CLEAR_DATABASE_CONFIRMTIME, timer_ClearDatabase);

	return Plugin_Handled;
}

public ClearStatsMaps(client)
{
	return;
	if (!DoFastQuery(client, "START TRANSACTION"))
		return;

	decl String:query[256];
	Format(query, sizeof(query), "SELECT * FROM %smaps WHERE 1 = 2", DbPrefix);

	SQL_TQuery(db, ClearStatsMapsHandler, query, client);
}

public ClearStatsAll(client)
{
	return;
	if (!DoFastQuery(client, "START TRANSACTION"))
		return;

	if (!DoFastQuery(client, "DELETE FROM %stimedmaps", DbPrefix))
	{
		PrintToConsole(client, "[RANK] Clear Stats: Clearing timedmaps table failed. Executing rollback...");
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");

		return;
	}

	if (!DoFastQuery(client, "DELETE FROM %splayers", DbPrefix))
	{
		PrintToConsole(client, "[RANK] Clear Stats: Clearing players table failed. Executing rollback...");
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");

		return;
	}

	decl String:query[256];
	Format(query, sizeof(query), "SELECT * FROM %smaps WHERE 1 = 2", DbPrefix);

	SQL_TQuery(db, ClearStatsMapsHandler, query, client);
}

public ClearStatsPlayers(client)
{
	return;
	if (!DoFastQuery(client, "START TRANSACTION"))
		return;

	if (!DoFastQuery(client, "DELETE FROM %splayers", DbPrefix))
	{
		PrintToConsole(client, "[RANK] Clear Stats: Clearing players table failed. Executing rollback...");
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");
	}
	else
	{
		DoFastQuery(client, "COMMIT");
		PrintToConsole(client, "[RANK] Clear Stats: Ranks succesfully cleared!");
	}
}

public ClearStatsMapsHandler(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	return;
	if (hndl == INVALID_HANDLE)
	{
		PrintToConsole(client, "[RANK] Clear Stats: Query failed! (%s)", error);
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");
		return;
	}

	new FieldCount = SQL_GetFieldCount(hndl);
	decl String:FieldName[MAX_LINE_WIDTH];
	decl String:FieldSet[MAX_LINE_WIDTH];

	new Counter = 0;
	decl String:query[4096];
	Format(query, sizeof(query), "UPDATE %smaps SET", DbPrefix);

	for (new i = 0; i < FieldCount; i++)
	{
		SQL_FieldNumToName(hndl, i, FieldName, sizeof(FieldName));

		if (StrEqual(FieldName, "name", false) ||
				StrEqual(FieldName, "gamemode", false) ||
				StrEqual(FieldName, "custom", false))
			continue;

		if (Counter++ > 0)
			StrCat(query, sizeof(query), ",");

		Format(FieldSet, sizeof(FieldSet), " %s = 0", FieldName);
		StrCat(query, sizeof(query), FieldSet);
	}

	if (!DoFastQuery(client, query))
	{
		PrintToConsole(client, "[RANK] Clear Stats: Clearing maps table failed. Executing rollback...");
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");
	}
	else
	{
		DoFastQuery(client, "COMMIT");
		PrintToConsole(client, "[RANK] Clear Stats: Stats succesfully cleared!", query);
	}
}

bool:DoFastQuery(Client, const String:Query[], any:...)
{
	return false;
	if (db == INVALID_HANDLE) return false;
	
	new String:FormattedQuery[4096];
	VFormat(FormattedQuery, sizeof(FormattedQuery), Query, 3);

	new String:Error[1024];

	if (!SQL_FastQuery(db, FormattedQuery))
	{
		if (SQL_GetError(db, Error, sizeof(Error)))
		{
			PrintToConsole(Client, "[RANK] Fast query failed! (Error = \"%s\") Query = \"%s\"", Error, FormattedQuery);
			LogError("Fast query failed! (Error = \"%s\") Query = \"%s\"", Error, FormattedQuery);
		}
		else
		{
			PrintToConsole(Client, "[RANK] Fast query failed! Query = \"%s\"", FormattedQuery);
			LogError("Fast query failed! Query = \"%s\"", FormattedQuery);
		}

		return false;
	}

	return true;
}

public Action:timer_ClearDatabase(Handle:timer, any:data)
{
	ClearDatabaseTimer = INVALID_HANDLE;
	ClearDatabaseCaller = -1;
}

// Begin generating the RANKMENU display panel.
public Action:cmd_ShowRankMenu(client, args)
{
	if (client <= 0)
	{
		if (client == 0)
			PrintToConsole(0, "[RANK] You must be ingame to operate rankmenu.");

		return Plugin_Handled;
	}

	if (!IsClientConnected(client) && !IsClientInGame(client))
		return Plugin_Handled;

	if (IsClientBot(client))
		return Plugin_Handled;

	DisplayRankMenu(client);

	return Plugin_Handled;
}

public DisplayRankMenu(client)
{
	decl String:Title[MAX_LINE_WIDTH];

	Format(Title, sizeof(Title), "%s:", PLUGIN_NAME);

	new Handle:menu = CreateMenu(Menu_CreateRankMenuHandler);

	SetMenuTitle(menu, Title);
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);

	AddMenuItem(menu, "rank", "Show my rank");
	AddMenuItem(menu, "top10", "Show top 10");
	AddMenuItem(menu, "top10ppm", "Show top 10 PPM");
	AddMenuItem(menu, "nextrank", "Show my next rank");
	AddMenuItem(menu, "showtimer", "Show current timer");
	AddMenuItem(menu, "showrank", "Show others rank");
	AddMenuItem(menu, "showppm", "Show others PPM");
	if (GetConVarBool(cvar_EnableRankVote) && (
				CurrentGamemodeID == GAMEMODE_REALISMVERSUS ||
				CurrentGamemodeID == GAMEMODE_VERSUS && !IsGamemode("teamversus") ||
				CurrentGamemodeID == GAMEMODE_SCAVENGE && !IsGamemode("teamscavenge")
			))
		AddMenuItem(menu, "rankvote", "Vote for team shuffle by PPM");
	AddMenuItem(menu, "timedmaps", "Show all map timings");
	if (IsSingleTeamGamemode())
		AddMenuItem(menu, "maptimes", "Show current map timings");
	if (GetConVarInt(cvar_AnnounceMode))
		AddMenuItem(menu, "showsettings", "Modify rank settings");
	//AddMenuItem(menu, "showmaptimes", "Show others current map timings");

	Format(Title, sizeof(Title), "About %s", PLUGIN_NAME);
	AddMenuItem(menu, "rankabout", Title);

	DisplayMenu(menu, client, 30);

	if (EnableSounds_Rankmenu_Show && GetConVarBool(cvar_SoundsEnabled))
		EmitSoundToClient(client, StatsSound_Rankmenu_Show);
}

NotServerConsoleCommand()
{
	PrintToConsole(0, "[RANK] Error: Most of the rank commands including this one are not available from server console.");
}

// Begin generating the RANK display panel.
public Action:cmd_ShowRank(client, args)
{
	if (client == 0)
	{
		NotServerConsoleCommand();
		return Plugin_Handled;
	}

	if (!IsClientConnected(client) && !IsClientInGame(client))
		return Plugin_Handled;

	if (IsClientBot(client))
		return Plugin_Handled;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));
	if (strlen(SteamID) > 25) return Plugin_Handled;

	QueryClientStatsSteamID(client, SteamID, CM_RANK);

	return Plugin_Handled;
}

// Generate client's point total.
public GetClientPointsRankChange(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	return;
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientPointsRankChange Query failed: %s", error);
		return;
	}

	GetClientPoints(owner, hndl, error, client);
	QueryClientRank(client, GetClientRankRankChange);
}

// Generate client's point total.
public GetClientPoints(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	return;
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientPoints Query failed: %s", error);
		return;
	}

	while (SQL_FetchRow(hndl))
	{
		ClientPoints[client] = SQL_FetchInt(hndl, 0);
	}
}

// Generate client's gamemode point total.
public GetClientGameModePoints(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientGameModePoints Query failed: %s", error);
		return;
	}
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		ClientGameModePoints[client][GAMEMODE_COOP] = SQL_FetchInt(hndl, GAMEMODE_COOP);
		ClientGameModePoints[client][GAMEMODE_VERSUS] = SQL_FetchInt(hndl, GAMEMODE_VERSUS);
		ClientGameModePoints[client][GAMEMODE_REALISM] = SQL_FetchInt(hndl, GAMEMODE_REALISM);
		ClientGameModePoints[client][GAMEMODE_SURVIVAL] = SQL_FetchInt(hndl, GAMEMODE_SURVIVAL);
		ClientGameModePoints[client][GAMEMODE_SCAVENGE] = SQL_FetchInt(hndl, GAMEMODE_SCAVENGE);
		ClientGameModePoints[client][GAMEMODE_REALISMVERSUS] = SQL_FetchInt(hndl, GAMEMODE_REALISMVERSUS);
		ClientGameModePoints[client][GAMEMODE_MUTATIONS] = SQL_FetchInt(hndl, GAMEMODE_MUTATIONS);
	}
}

// Generate client's next rank.
public DisplayClientNextRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientRankRankChange Query failed: %s", error);
		return;
	}

	GetClientNextRank(owner, hndl, error, client);

	DisplayNextRank(client);
}

// Generate client's next rank.
public GetClientNextRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientRankRankChange Query failed: %s", error);
		return;
	}
if (!SQL_HasResultSet(hndl)) return;
	if (SQL_FetchRow(hndl))
		ClientNextRank[client] = SQL_FetchInt(hndl, 0);
	else
		ClientNextRank[client] = 0;
}

// Generate client's rank.
public GetClientRankRankChange(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientRankRankChange Query failed: %s", error);
		return;
	}

	GetClientRank(owner, hndl, error, client);

	if (RankChangeLastRank[client] != ClientRank[client])
	{
		new RankChange = RankChangeLastRank[client] - ClientRank[client];

		if (!RankChangeFirstCheck[client] && RankChange == 0)
			return;

		RankChangeLastRank[client] = ClientRank[client];

		if (RankChangeFirstCheck[client])
		{
			RankChangeFirstCheck[client] = false;
			return;
		}

		if (!GetConVarInt(cvar_AnnounceMode) || !GetConVarBool(cvar_AnnounceRankChange))
			return;

		decl String:Label[16];
		if (RankChange > 0)
			Format(Label, sizeof(Label), "GAINED");
		else
		{
			RankChange *= -1;
			Format(Label, sizeof(Label), "DROPPED");
		}

		if (!IsClientBot(client) && IsClientConnected(client) && IsClientInGame(client))
			StatsPrintToChat(client, "You've \x04%s \x01rank for \x04%i position%s\x01! \x05(Rank: %i)", Label, RankChange, (RankChange > 1 ? "s" : ""), RankChangeLastRank[client]);
	}
}

// Generate client's rank.
public GetClientRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientRank Query failed: %s", error);
		return;
	}
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
		ClientRank[client] = SQL_FetchInt(hndl, 0);
}

// Generate client's rank.
public GetClientGameModeRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientGameModeRank Query failed: %s", error);
		return;
	}
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
		ClientGameModeRank[client] = SQL_FetchInt(hndl, 0);
}

// Generate total rank amount.
public GetRankTotal(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("GetRankTotal Query failed: %s", error);
		return;
	}
	
	if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
		RankTotal = SQL_FetchInt(hndl, 0);
}

// Generate total gamemode rank amount.
public GetGameModeRankTotal(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("GetGameModeRankTotal Query failed: %s", error);
		return;
	}
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
		GameModeRankTotal = SQL_FetchInt(hndl, 0);
}

// Send the NEXTRANK panel to the client's display.
public DisplayNextRank(client)
{
	if (!client)
		return;

	new Handle:NextRankPanel = CreatePanel();
	new String:Value[MAX_LINE_WIDTH];

	SetPanelTitle(NextRankPanel, "Next Rank:");

	if (ClientNextRank[client])
	{
		Format(Value, sizeof(Value), "Points required: %i", ClientNextRank[client]);
		DrawPanelText(NextRankPanel, Value);

		Format(Value, sizeof(Value), "Current rank: %i", ClientRank[client]);
		DrawPanelText(NextRankPanel, Value);
	}
	else
		DrawPanelText(NextRankPanel, "You are 1st");

	DrawPanelItem(NextRankPanel, "More...");
	DrawPanelItem(NextRankPanel, "Close");
	SendPanelToClient(NextRankPanel, client, NextRankPanelHandler, 30);
	CloseHandle(NextRankPanel);
}

// Send the NEXTRANK panel to the client's display.
public DisplayNextRankFull(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("DisplayNextRankFull Query failed: %s", error);
		return;
	}

	if(SQL_GetRowCount(hndl) <= 1)
		return;

	new Points;
	decl String:Name[32];

	new Handle:NextRankPanel = CreatePanel();
	new String:Value[MAX_LINE_WIDTH];

	SetPanelTitle(NextRankPanel, "Next Rank:");

	if (ClientNextRank[client])
	{
		Format(Value, sizeof(Value), "Points required: %i", ClientNextRank[client]);
		DrawPanelText(NextRankPanel, Value);

		Format(Value, sizeof(Value), "Current rank: %i", ClientRank[client]);
		DrawPanelText(NextRankPanel, Value);
	}
	else
		DrawPanelText(NextRankPanel, "You are 1st");
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));
		Points = SQL_FetchInt(hndl, 1);

		Format(Value, sizeof(Value), "%i points: %s", Points, Name);
		DrawPanelText(NextRankPanel, Value);
	}

	DrawPanelItem(NextRankPanel, "Close");
	SendPanelToClient(NextRankPanel, client, NextRankFullPanelHandler, 30);
	CloseHandle(NextRankPanel);
}

// Send the RANK panel to the client's display.
public DisplayRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("DisplayRank Query failed: %s", error);
		return;
	}

	new Float:PPM;
	new Playtime, Points, InfectedKilled, SurvivorsKilled, Headshots;
	new String:Name[32];
if (!SQL_HasResultSet(hndl)) return;
	if (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));
		Playtime = SQL_FetchInt(hndl, 1);
		Points = SQL_FetchInt(hndl, 2);
		InfectedKilled = SQL_FetchInt(hndl, 3);
		SurvivorsKilled = SQL_FetchInt(hndl, 4);
		Headshots = SQL_FetchInt(hndl, 5);
		PPM = float(Points) / float(Playtime);
	}
	else
	{
		GetClientName(client, Name, sizeof(Name));
		Playtime = 0;
		Points = 0;
		InfectedKilled = 0;
		SurvivorsKilled = 0;
		Headshots = 0;
		PPM = 0.0;
	}

	new Handle:RankPanel = CreatePanel();
	new String:Value[MAX_LINE_WIDTH];
	new String:URL[MAX_LINE_WIDTH];

	GetConVarString(cvar_SiteURL, URL, sizeof(URL));
	new Float:HeadshotRatio = Headshots == 0 ? 0.00 : FloatDiv(float(Headshots), float(InfectedKilled))*100;

	Format(Value, sizeof(Value), "Ranking of %s" , Name);
	SetPanelTitle(RankPanel, Value);

	Format(Value, sizeof(Value), "Rank: %i of %i" , ClientRank[client], RankTotal);
	DrawPanelText(RankPanel, Value);

	if (!InvalidGameMode())
	{
		Format(Value, sizeof(Value), "%s Rank: %i of %i" ,CurrentGamemodeLabel , ClientGameModeRank[client], GameModeRankTotal);
		DrawPanelText(RankPanel, Value);
	}

	if (Playtime > 60)
	{
		Format(Value, sizeof(Value), "Playtime: %.2f hours" , FloatDiv(float(Playtime), 60.0));
		DrawPanelText(RankPanel, Value);
	}
	else
	{
		Format(Value, sizeof(Value), "Playtime: %i min" , Playtime);
		DrawPanelText(RankPanel, Value);
	}

	Format(Value, sizeof(Value), "Points: %i" , Points);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "PPM: %.2f" , PPM);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "Infected Killed: %i" , InfectedKilled);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "Survivors Killed: %i" , SurvivorsKilled);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "Headshots: %i" , Headshots);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "Headshot Ratio: %.2f \%" , HeadshotRatio);
	DrawPanelText(RankPanel, Value);

	if (!StrEqual(URL, "", false))
	{
		Format(Value, sizeof(Value), "For full stats visit %s", URL);
		DrawPanelText(RankPanel, Value);
	}

	//DrawPanelItem(RankPanel, "Next Rank");
	DrawPanelItem(RankPanel, "Close");
	SendPanelToClient(RankPanel, client, RankPanelHandler, 30);
	CloseHandle(RankPanel);
}

public StartRankVote(client)
{
	if (L4DStatsConf == INVALID_HANDLE)
	{
		if (client > 0)
			StatsPrintToChatPreFormatted(client, "The \x04Rank Vote \x01is \x03DISABLED\x01. \x05Plugin configurations failed.");
		else
			PrintToConsole(0, "[RANK] The Rank Vote is DISABLED! Could not load gamedata/l4d_puntos.txt.");
	}

	else if (!GetConVarBool(cvar_EnableRankVote))
	{
		if (client > 0)
			StatsPrintToChatPreFormatted(client, "The \x04Rank Vote \x01is \x03DISABLED\x01.");
		else
			PrintToConsole(0, "[RANK] The Rank Vote is DISABLED.");
	}

	else
		InitializeRankVote(client);
}

// Toggle client rank mute.
public Action:cmd_ToggleClientRankMute(client, args)
{
	if (client == 0)
		return Plugin_Handled;

	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	new String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));
	if (strlen(SteamID) > 25) return Plugin_Handled;

	ClientRankMute[client] = !ClientRankMute[client];

	decl String:query[256];
	Format(query, sizeof(query), "UPDATE %ssettings SET mute = %i WHERE steamid = '%s'", DbPrefix, (ClientRankMute[client] ? 1 : 0), SteamID);
	SQL_TQuery(db, SQLErrorCheckCallback, query);
	//SendSQLUpdate(query);

	AnnounceClientRankMute(client);

	return Plugin_Handled;
}

ShowRankMuteUsage(client)
{
	PrintToConsole(client, "[RANK] Command usage: sm_rankmute <0|1>");
}

// Set client rank mute.
public Action:cmd_ClientRankMute(client, args)
{
	if (client == 0)
		return Plugin_Handled;

	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	if (args != 1)
	{
		ShowRankMuteUsage(client);
		return Plugin_Handled;
	}

	decl String:arg[MAX_LINE_WIDTH];
	GetCmdArgString(arg, sizeof(arg));

	if (!StrEqual(arg, "0") && !StrEqual(arg, "1"))
	{
		ShowRankMuteUsage(client);
		return Plugin_Handled;
	}
	
	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));
	if (strlen(SteamID) > 25) return Plugin_Handled;

	ClientRankMute[client] = StrEqual(arg, "1");

	decl String:query[256];
	Format(query, sizeof(query), "UPDATE %ssettings SET mute = %s WHERE steamid = '%s'", DbPrefix, arg, SteamID);
	//SendSQLUpdate(query);

	AnnounceClientRankMute(client);

	return Plugin_Handled;
}

AnnounceClientRankMute(client)
{
	StatsPrintToChat2(client, true, "You %s \x01the \x05%s\x01.", (ClientRankMute[client] ? "\x04MUTED" : "\x03UNMUTED"), PLUGIN_NAME);
}

// Start RANKVOTE.
public Action:cmd_RankVote(client, args)
{
	if (client == 0)
	{
		StartRankVote(client);
		return Plugin_Handled;
	}

	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	new ClientFlags = GetUserFlagBits(client);
	new bool:IsAdmin = ((ClientFlags & ADMFLAG_GENERIC) == ADMFLAG_GENERIC);

	new ClientTeam = GetClientTeam(client);

	if (!IsAdmin && ClientTeam != TEAM_SURVIVORS && ClientTeam != TEAM_INFECTED)
	{
		StatsPrintToChatPreFormatted2(client, true, "The spectators cannot initiate the \x04Rank Vote\x01.");
		return Plugin_Handled;
	}

	StartRankVote(client);

	return Plugin_Handled;
}

// Generate the TIMEDMAPS display menu.
public Action:cmd_TimedMaps(client, args)
{
	if (client == 0 || !IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	decl String:query[256];
	Format(query, sizeof(query), "SELECT DISTINCT tm.gamemode, tm.mutation FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid", DbPrefix, DbPrefix);
	SQL_TQuery(db, CreateTimedMapsMenu, query, client);

	return Plugin_Handled;
}

// Generate the MAPTIME display menu.
public Action:cmd_MapTimes(client, args)
{
	if (client == 0 || !IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	decl String:Info[MAX_LINE_WIDTH], String:CurrentMapName[MAX_LINE_WIDTH];

	GetCurrentMap(CurrentMapName, sizeof(CurrentMapName));
	Format(Info, sizeof(Info), "%i\\%s", CurrentGamemodeID, CurrentMapName);

	DisplayTimedMapsMenu3FromInfo(client, Info);

	return Plugin_Handled;
}

// Generate the SHOWMAPTIME display menu.
public Action:cmd_ShowMapTimes(client, args)
{
	if (client == 0 || !IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	StatsPrintToChatPreFormatted2(client, true, "\x05NOT IMPLEMENTED YET");

	return Plugin_Handled;
}

// Generate the SHOWPPM display menu.
public Action:cmd_ShowPPMs(client, args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	decl String:query[1024];
	//Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", DbPrefix);
	//SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT steamid, name, (%s) / (%s) AS ppm FROM %splayers WHERE ", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME, DbPrefix);

	new maxplayers = GetMaxClients();
	decl String:SteamID[MAX_LINE_WIDTH], String:where[512];
	new counter = 0;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		if (counter++ > 0)
			StrCat(query, sizeof(query), "OR ");

		GetClientRankAuthString(i, SteamID, sizeof(SteamID));
		if (strlen(SteamID) > 25) return Plugin_Handled;
		Format(where, sizeof(where), "steamid = '%s' ", SteamID);
		StrCat(query, sizeof(query), where);
	}

	if (counter == 0)
		return Plugin_Handled;

	if (counter == 1)
	{
		cmd_ShowRank(client, 0);
		return Plugin_Handled;
	}

	StrCat(query, sizeof(query), "ORDER BY ppm DESC");

	SQL_TQuery(db, CreatePPMMenu, query, client);

	return Plugin_Handled;
}

// Generate the SHOWRANK display menu.
public Action:cmd_ShowRanks(client, args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	decl String:query[1024];
	//Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", DbPrefix);
	//SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT steamid, name, %s AS totalpoints FROM %splayers WHERE ", DB_PLAYERS_TOTALPOINTS, DbPrefix);

	new maxplayers = GetMaxClients();
	decl String:SteamID[MAX_LINE_WIDTH], String:where[512];
	new counter = 0;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		if (counter++ > 0)
			StrCat(query, sizeof(query), "OR ");

		GetClientRankAuthString(i, SteamID, sizeof(SteamID));
		if (strlen(SteamID) > 25) return Plugin_Handled;
		Format(where, sizeof(where), "steamid = '%s' ", SteamID);
		StrCat(query, sizeof(query), where);
	}

	if (counter == 0)
		return Plugin_Handled;

	if (counter == 1)
	{
		cmd_ShowRank(client, 0);
		return Plugin_Handled;
	}

	StrCat(query, sizeof(query), "ORDER BY totalpoints DESC");

	SQL_TQuery(db, CreateRanksMenu, query, client);

	return Plugin_Handled;
}

// Generate the TOPPPM display panel.
public Action:cmd_ShowTop10PPM(client, args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	decl String:query[1024];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", DbPrefix);
	SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT name, (%s) / (%s) AS ppm FROM %splayers WHERE (%s) >= %i ORDER BY ppm DESC, (%s) DESC LIMIT 10", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME, DbPrefix, DB_PLAYERS_TOTALPLAYTIME, GetConVarInt(cvar_Top10PPMMin), DB_PLAYERS_TOTALPLAYTIME);
	SQL_TQuery(db, DisplayTop10PPM, query, client);

	return Plugin_Handled;
}

// Generate the TOP10 display panel.
public Action:cmd_ShowTop10(client, args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	decl String:query[512];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", DbPrefix);
	SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT name FROM %splayers ORDER BY %s DESC LIMIT 10", DbPrefix, DB_PLAYERS_TOTALPOINTS);
	SQL_TQuery(db, DisplayTop10, query, client);

	return Plugin_Handled;
}

// Find a player from Top 10 ranking.
public GetClientFromTop10(client, rank)
{
	decl String:query[512];
	Format(query, sizeof(query), "SELECT (%s) as totalpoints, steamid FROM %splayers ORDER BY totalpoints DESC LIMIT %i,1", DB_PLAYERS_TOTALPOINTS, DbPrefix, rank);
	SQL_TQuery(db, GetClientTop10, query, client);
}

// Find a player from Top 10 PPM ranking.
public GetClientFromTop10PPM(client, rank)
{
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT (%s) AS totalpoints, steamid, (%s) AS totalplaytime FROM %splayers WHERE (%s) >= %i ORDER BY (totalpoints / totalplaytime) DESC, totalplaytime DESC LIMIT %i,1", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME, DbPrefix, DB_PLAYERS_TOTALPLAYTIME, GetConVarInt(cvar_Top10PPMMin), rank);
	SQL_TQuery(db, GetClientTop10, query, client);
}

// Send the Top 10 player's info to the client.
public GetClientTop10(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("GetClientTop10 failed! Reason: %s", error);
		return;
	}

	decl String:SteamID[MAX_LINE_WIDTH];
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 1, SteamID, sizeof(SteamID));

		QueryClientStatsSteamID(client, SteamID, CM_TOP10);
	}
}

public ExecuteTeamShuffle(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	return;
	if (hndl == INVALID_HANDLE)
	{
		LogError("ExecuteTeamShuffle failed! Reason: %s", error);
		return;
	}

	decl String:SteamID[MAX_LINE_WIDTH];
	new i, team, maxplayers = GetMaxClients(), client, topteam;
	new SurvivorsLimit = GetConVarInt(cvar_SurvivorLimit), InfectedLimit = GetConVarInt(cvar_InfectedLimit);
	new Handle:PlayersTrie = CreateTrie();
	new Handle:InfectedArray = CreateArray();
	new Handle:SurvivorArray = CreateArray();

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			GetClientRankAuthString(i, SteamID, sizeof(SteamID));
			if (strlen(SteamID) > 25) return;
			
			if (!SetTrieValue(PlayersTrie, SteamID, i, false))
			{
				LogError("ExecuteTeamShuffle failed! Reason: Duplicate SteamID while generating shuffled teams.");
				StatsPrintToChatAllPreFormatted("Team shuffle failed in an error.");

				SetConVarBool(cvar_EnableRankVote, false);

				ClearTrie(PlayersTrie);
				CloseHandle(PlayersTrie);

				CloseHandle(hndl);

				return;
			}

			switch (GetClientTeam(i))
			{
				case TEAM_SURVIVORS:
					PushArrayCell(SurvivorArray, i);
				case TEAM_INFECTED:
					PushArrayCell(InfectedArray, i);
			}
		}
	}

	new SurvivorCounter = GetArraySize(SurvivorArray);
	new InfectedCounter = GetArraySize(InfectedArray);

	i = 0;
	topteam = 0;
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, SteamID, sizeof(SteamID));

		if (GetTrieValue(PlayersTrie, SteamID, client))
		{
			team = GetClientTeam(client);

			if (i == 0)
			{
				if (team == TEAM_SURVIVORS)
					RemoveFromArray(SurvivorArray, FindValueInArray(SurvivorArray, client));
				else
					RemoveFromArray(InfectedArray, FindValueInArray(InfectedArray, client));

				topteam = team;
				i++;

				continue;
			}

			if (i++ % 2)
			{
				if (topteam == TEAM_SURVIVORS && team == TEAM_INFECTED)
					RemoveFromArray(InfectedArray, FindValueInArray(InfectedArray, client));
				else if (topteam == TEAM_INFECTED && team == TEAM_SURVIVORS)
					RemoveFromArray(SurvivorArray, FindValueInArray(SurvivorArray, client));
			}
			else
			{
				if (topteam == TEAM_SURVIVORS && team == TEAM_SURVIVORS)
					RemoveFromArray(SurvivorArray, FindValueInArray(SurvivorArray, client));
				else if (topteam == TEAM_INFECTED && team == TEAM_INFECTED)
					RemoveFromArray(InfectedArray, FindValueInArray(InfectedArray, client));
			}
		}
	}

	if (GetArraySize(SurvivorArray) > 0 || GetArraySize(InfectedArray) > 0)
	{
		new NewSurvivorCounter = SurvivorCounter - GetArraySize(SurvivorArray) + GetArraySize(InfectedArray);
		new NewInfectedCounter = InfectedCounter - GetArraySize(InfectedArray) + GetArraySize(SurvivorArray);

		if (NewSurvivorCounter > SurvivorsLimit || NewInfectedCounter > InfectedLimit)
		{
			LogError("ExecuteTeamShuffle failed! Reason: Team size limits block Rank Vote functionality. (Survivors Limit = %i [%i] / Infected Limit = %i [%i])", SurvivorsLimit, NewSurvivorCounter, InfectedLimit, NewInfectedCounter);
			StatsPrintToChatAllPreFormatted("Team shuffle failed in an error.");

			SetConVarBool(cvar_EnableRankVote, false);
		}
		else
		{
			CampaignOver = true;

			decl String:Name[32];

			// Change Survivors team to Spectators (TEMPORARILY)
			for (i = 0; i < GetArraySize(SurvivorArray); i++)
				ChangeRankPlayerTeam(GetArrayCell(SurvivorArray, i), TEAM_SPECTATORS);

			// Change Infected team to Survivors
			for (i = 0; i < GetArraySize(InfectedArray); i++)
			{
				client = GetArrayCell(InfectedArray, i);
				GetClientName(client, Name, sizeof(Name));

				ChangeRankPlayerTeam(client, TEAM_SURVIVORS);

				StatsPrintToChatAll("\x05%s \x01was swapped to team \x03Survivors\x01!", Name);
			}

			// Change Spectators (TEMPORARILY) team to Infected
			for (i = 0; i < GetArraySize(SurvivorArray); i++)
			{
				client = GetArrayCell(SurvivorArray, i);
				GetClientName(client, Name, sizeof(Name));

				ChangeRankPlayerTeam(client, TEAM_INFECTED);

				StatsPrintToChatAll("\x05%s \x01was swapped to team \x03Infected\x01!", Name);
			}

			StatsPrintToChatAllPreFormatted("Team shuffle by player PPM \x03DONE\x01.");

			if (EnableSounds_Rankvote && GetConVarBool(cvar_SoundsEnabled))
				EmitSoundToAll(SOUND_RANKVOTE);
		}
	}
	else
	{
		StatsPrintToChatAllPreFormatted("Teams are already even by player PPM.");
	}

	ClearArray(SurvivorArray);
	ClearArray(InfectedArray);
	ClearTrie(PlayersTrie);

	CloseHandle(SurvivorArray);
	CloseHandle(InfectedArray);
	CloseHandle(PlayersTrie);

	CloseHandle(hndl);
}

public CreateRanksMenu(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("CreateRanksMenu failed! Reason: %s", error);
		return;
	}

	decl String:SteamID[MAX_LINE_WIDTH];
	new Handle:menu = CreateMenu(Menu_CreateRanksMenuHandler);

	decl String:Name[32], String:DisplayName[MAX_LINE_WIDTH];

	SetMenuTitle(menu, "Player Ranks:");
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, SteamID, sizeof(SteamID));
		SQL_FetchString(hndl, 1, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Format(DisplayName, sizeof(DisplayName), "%s (%i points)", Name, SQL_FetchInt(hndl, 2));

		AddMenuItem(menu, SteamID, DisplayName);
	}

	DisplayMenu(menu, client, 30);
}

public CreateTimedMapsMenu(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("CreateTimedMapsMenu failed! Reason: %s", error);
		return;
	}

	if (SQL_GetRowCount(hndl) <= 0)
	{
		new Handle:TimedMapsPanel = CreatePanel();
		SetPanelTitle(TimedMapsPanel, "Timed Maps:");

		DrawPanelText(TimedMapsPanel, "There are no recorded map timings!");
		DrawPanelItem(TimedMapsPanel, "Close");

		SendPanelToClient(TimedMapsPanel, client, TimedMapsPanelHandler, 30);
		CloseHandle(TimedMapsPanel);

		return;
	}

	new Gamemode;
	new Handle:menu = CreateMenu(Menu_CreateTimedMapsMenuHandler);
	decl String:GamemodeTitle[32], String:GamemodeInfo[2]; //, MutationInfo[MAX_LINE_WIDTH];

	SetMenuTitle(menu, "Timed Maps:");
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		Gamemode = SQL_FetchInt(hndl, 0);
		IntToString(Gamemode, GamemodeInfo, sizeof(GamemodeInfo));

		switch (Gamemode)
		{
			case GAMEMODE_COOP:
				strcopy(GamemodeTitle, sizeof(GamemodeTitle), "Co-op");
			case GAMEMODE_SURVIVAL:
				strcopy(GamemodeTitle, sizeof(GamemodeTitle), "Survival");
			case GAMEMODE_REALISM:
				strcopy(GamemodeTitle, sizeof(GamemodeTitle), "Realism");
			case GAMEMODE_MUTATIONS:
			{
				strcopy(GamemodeTitle, sizeof(GamemodeTitle), "Mutations");
				//SQL_FetchString(hndl, 1, MutationInfo, sizeof(MutationInfo));
				//Format(GamemodeTitle, sizeof(GamemodeTitle), "Mutations (%s)", MutationInfo);
			}
			default:
				continue;
		}

		if (CurrentGamemodeID == Gamemode)
			StrCat(GamemodeTitle, sizeof(GamemodeTitle), TM_MENU_CURRENT);

		AddMenuItem(menu, GamemodeInfo, GamemodeTitle);
	}

	DisplayMenu(menu, client, 30);

	return;
}

public Menu_CreateTimedMapsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End) {
		CloseHandle(menu);
		return;
	}

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1)) {
		
		return;
	}

	decl String:Info[2];
	new bool:found = GetMenuItem(menu, param2, Info, sizeof(Info));
	if (!found)	return;

	DisplayTimedMapsMenu2FromInfo(param1, Info);
	
}

bool:TimedMapsMenuInfoMarker(String:Info[], MenuNumber)
{
	if (Info[0] == '\0' || MenuNumber < 2)
		return false;

	new Position = -1, TempPosition;

	for (new i = 0; i < MenuNumber; i++)
	{
		TempPosition = FindCharInString(Info[Position + 1], '\\');

		if (TempPosition < 0)
		{
			if (i + 2 == MenuNumber)
				return true;
			else
				return false;
		}

		Position += 1 + TempPosition;

		if (i + 2 >= MenuNumber)
		{
			Info[Position] = '\0';
			return true;
		}
	}

	return false;
}

public DisplayTimedMapsMenu2FromInfo(client, String:Info[])
{
	if (!TimedMapsMenuInfoMarker(Info, 2))
	{
		cmd_TimedMaps(client, 0);
		return;
	}

	strcopy(MapTimingMenuInfo[client], MAX_LINE_WIDTH, Info);

	new Gamemode = StringToInt(Info);

	DisplayTimedMapsMenu2(client, Gamemode);
}

public DisplayTimedMapsMenu2(client, Gamemode)
{
	decl String:query[256];
	Format(query, sizeof(query), "SELECT DISTINCT tm.gamemode, tm.map FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid WHERE tm.gamemode = %i ORDER BY tm.map ASC", DbPrefix, DbPrefix, Gamemode);
	SQL_TQuery(db, CreateTimedMapsMenu2, query, client);
}

public CreateTimedMapsMenu2(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("CreateTimedMapsMenu2 failed! Reason: %s", error);
		return;
	}

	if (SQL_GetRowCount(hndl) <= 0)
	{
		new Handle:TimedMapsPanel = CreatePanel();
		SetPanelTitle(TimedMapsPanel, "Timed Maps:");

		DrawPanelText(TimedMapsPanel, "There are no recorded times for this gamemode!");
		DrawPanelItem(TimedMapsPanel, "Close");

		SendPanelToClient(TimedMapsPanel, client, TimedMapsPanelHandler, 30);
		CloseHandle(TimedMapsPanel);

		return;
	}

	new Handle:menu = CreateMenu(Menu_CreateTimedMapsMenu2Hndl), Gamemode;
	decl String:Map[MAX_LINE_WIDTH], String:Info[MAX_LINE_WIDTH], String:CurrentMapName[MAX_LINE_WIDTH];

	GetCurrentMap(CurrentMapName, sizeof(CurrentMapName));

	SetMenuTitle(menu, "Timed Maps:");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		Gamemode = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, Map, sizeof(Map));

		Format(Info, sizeof(Info), "%i\\%s", Gamemode, Map);

		if (CurrentGamemodeID == Gamemode && StrEqual(CurrentMapName, Map))
			StrCat(Map, sizeof(Map), TM_MENU_CURRENT);

		AddMenuItem(menu, Info, Map);
	}

	DisplayMenu(menu, client, 30);
}

public Menu_CreateTimedMapsMenu2Hndl(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End) {
		CloseHandle(menu);
		return;
	}

	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			cmd_TimedMaps(param1, 0);
			
		
		return;
	}

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1)) {
		
		return;
	}

	decl String:Info[MAX_LINE_WIDTH];
	new bool:found = GetMenuItem(menu, param2, Info, sizeof(Info));

	
	if (!found)
		return;

	DisplayTimedMapsMenu3FromInfo(param1, Info);
	
	
}

public DisplayTimedMapsMenu3FromInfo(client, String:Info[])
{
	if (!TimedMapsMenuInfoMarker(Info, 3))
	{
		cmd_TimedMaps(client, 0);
		return;
	}

	strcopy(MapTimingMenuInfo[client], MAX_LINE_WIDTH, Info);

	decl String:GamemodeInfo[2], String:Map[MAX_LINE_WIDTH];

	strcopy(GamemodeInfo, sizeof(GamemodeInfo), Info);
	GamemodeInfo[1] = 0;

	strcopy(Map, sizeof(Map), Info[2]);

	DisplayTimedMapsMenu3(client, StringToInt(GamemodeInfo), Map);
}

public DisplayTimedMapsMenu3(client, Gamemode, const String:Map[])
{
	return;
	new Handle:dp = CreateDataPack();

	WritePackCell(dp, client);
	WritePackCell(dp, Gamemode);
	WritePackString(dp, Map);

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	decl String:query[256];
	Format(query, sizeof(query), "SELECT tm.time FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid WHERE tm.gamemode = %i AND tm.map = '%s' AND p.steamid = '%s'", DbPrefix, DbPrefix, Gamemode, Map, SteamID);
	SQL_TQuery(db, DisplayTimedMapsMenu3_2, query, dp);
}

public DisplayTimedMapsMenu3_2(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		if (dp != INVALID_HANDLE)
			CloseHandle(dp);

		LogError("DisplayTimedMapsMenu3_2 failed! Reason: %s", error);
		return;
	}

	ResetPack(dp);

	new client = ReadPackCell(dp);
	new Gamemode = ReadPackCell(dp);
	decl String:Map[MAX_LINE_WIDTH];
	ReadPackString(dp, Map, sizeof(Map));

	CloseHandle(dp);
if (!SQL_HasResultSet(hndl)) return;
	if (SQL_FetchRow(hndl))
		ClientMapTime[client] = SQL_FetchFloat(hndl, 0);
	else
		ClientMapTime[client] = 0.0;

	decl String:query[256];
	Format(query, sizeof(query), "SELECT DISTINCT tm.gamemode, tm.map, tm.time FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid WHERE tm.gamemode = %i AND tm.map = '%s' ORDER BY tm.time %s", DbPrefix, DbPrefix, Gamemode, Map, (Gamemode == GAMEMODE_SURVIVAL ? "DESC" : "ASC"));
	SQL_TQuery(db, CreateTimedMapsMenu3, query, client);
}

public CreateTimedMapsMenu3(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("CreateTimedMapsMenu3 failed! Reason: %s", error);
		return;
	}

	if (SQL_GetRowCount(hndl) <= 0)
	{
		new Handle:TimedMapsPanel = CreatePanel();
		SetPanelTitle(TimedMapsPanel, "Timed Maps:");

		DrawPanelText(TimedMapsPanel, "There are no recorded times for this map!");
		DrawPanelItem(TimedMapsPanel, "Close");

		SendPanelToClient(TimedMapsPanel, client, TimedMapsPanelHandler, 30);
		CloseHandle(TimedMapsPanel);

		return;
	}

	new Handle:menu = CreateMenu(Menu_CreateTimedMapsMenu3Hndl), Float:MapTime;
	decl String:Map[MAX_LINE_WIDTH], String:Info[MAX_LINE_WIDTH], String:Value[MAX_LINE_WIDTH];

	SetMenuTitle(menu, "Timed Maps:");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 1, Map, sizeof(Map));
		MapTime = SQL_FetchFloat(hndl, 2);

		SetTimeLabel(MapTime, Value, sizeof(Value));

		Format(Info, sizeof(Info), "%i\\%s\\%f", SQL_FetchInt(hndl, 0), Map, MapTime);

		if (ClientMapTime[client] > 0.0 && ClientMapTime[client] == MapTime)
			StrCat(Value, sizeof(Value), TM_MENU_CURRENT);

		AddMenuItem(menu, Info, Value);
	}

	DisplayMenu(menu, client, 30);
}

public Menu_CreateTimedMapsMenu3Hndl(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End) {
		CloseHandle(menu);
		return;
	}

	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			DisplayTimedMapsMenu2FromInfo(param1, MapTimingMenuInfo[param1]);

			
		return;
	}

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return;

	decl String:Info[MAX_LINE_WIDTH];
	new bool:found = GetMenuItem(menu, param2, Info, sizeof(Info));
	
	if (!found)
		return;

	DisplayTimedMapsMenu4FromInfo(param1, Info);
}

public DisplayTimedMapsMenu4FromInfo(client, String:Info[])
{
	if (!TimedMapsMenuInfoMarker(Info, 4))
	{
		cmd_TimedMaps(client, 0);
		return;
	}

	strcopy(MapTimingMenuInfo[client], MAX_LINE_WIDTH, Info);

	decl String:GamemodeInfo[2], String:Map[MAX_LINE_WIDTH];

	strcopy(GamemodeInfo, sizeof(GamemodeInfo), Info);
	GamemodeInfo[1] = 0;

	new Position = FindCharInString(Info[2], '\\');

	if (Position < 0)
	{
		LogError("Timed Maps menu 4 error: Info = \"%s\"", Info);
		return;
	}

	Position += 2;

	strcopy(Map, sizeof(Map), Info[2]);
	Map[Position - 2] = '\0';

	decl String:MapTime[MAX_LINE_WIDTH];
	strcopy(MapTime, sizeof(MapTime), Info[Position + 1]);

	DisplayTimedMapsMenu4(client, StringToInt(GamemodeInfo), Map, StringToFloat(MapTime));
}

public DisplayTimedMapsMenu4(client, Gamemode, const String:Map[], Float:MapTime)
{
	decl String:query[256];
	Format(query, sizeof(query), "SELECT tm.steamid, p.name FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid WHERE tm.gamemode = %i AND tm.map = '%s' AND tm.time = %f ORDER BY p.name ASC", DbPrefix, DbPrefix, Gamemode, Map, MapTime);
	SQL_TQuery(db, CreateTimedMapsMenu4, query, client);
}

public CreateTimedMapsMenu4(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("CreateTimedMapsMenu4 failed! Reason: %s", error);
		return;
	}

	new Handle:menu = CreateMenu(Menu_CreateTimedMapsMenu4Hndl);

	decl String:Name[32], String:SteamID[MAX_LINE_WIDTH];

	SetMenuTitle(menu, "Timed Maps:");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, SteamID, sizeof(SteamID));
		SQL_FetchString(hndl, 1, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		AddMenuItem(menu, SteamID, Name);
	}

	DisplayMenu(menu, client, 30);
}

public Menu_CreateTimedMapsMenu4Hndl(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End) {
		CloseHandle(menu);
		return;
	}

	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			DisplayTimedMapsMenu3FromInfo(param1, MapTimingMenuInfo[param1]);

				
		return;
	}

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
	{
			
		return;
	}

	decl String:SteamID[MAX_LINE_WIDTH];
	new bool:found = GetMenuItem(menu, param2, SteamID, sizeof(SteamID));

		
	
	if (!found)
		return;

	QueryClientStatsSteamID(param1, SteamID, CM_RANK);
}

public CreatePPMMenu(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("CreatePPMMenu failed! Reason: %s", error);
		return;
	}

	decl String:SteamID[MAX_LINE_WIDTH];
	new Handle:menu = CreateMenu(Menu_CreateRanksMenuHandler);

	decl String:Name[32], String:DisplayName[MAX_LINE_WIDTH];

	SetMenuTitle(menu, "Player PPM:");
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, SteamID, sizeof(SteamID));
		SQL_FetchString(hndl, 1, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Format(DisplayName, sizeof(DisplayName), "%s (PPM: %.2f)", Name, SQL_FetchFloat(hndl, 2));

		AddMenuItem(menu, SteamID, DisplayName);
	}

	DisplayMenu(menu, client, 30);
}

public Menu_CreateRanksMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End) {
		CloseHandle(menu);
		return;
	}

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1)) {
		return;
	}

	decl String:SteamID[MAX_LINE_WIDTH];
	new bool:found = GetMenuItem(menu, param2, SteamID, sizeof(SteamID));
		
	if (!found) return;

	QueryClientStatsSteamID(param1, SteamID, CM_RANK);
}

public Menu_CreateRankMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End) {
		CloseHandle(menu);
		return;
	}

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1)) {
			
		return;
	}

	decl String:Info[MAX_LINE_WIDTH];
	new bool:found = GetMenuItem(menu, param2, Info, sizeof(Info));
		
	if (!found)
		return;

	if (strcmp(Info, "rankabout", false) == 0)
	{
		DisplayAboutPanel(param1);
		return;
	}

	else if (strcmp(Info, "showsettings", false) == 0)
	{
		DisplaySettingsPanel(param1);
		return;
	}

	HandleCommands(param1, Info);
}

// Send the RANKABOUT panel to the client's display.
public DisplayAboutPanel(client)
{
	decl String:Value[MAX_LINE_WIDTH];

	new Handle:panel = CreatePanel();

	Format(Value, sizeof(Value), "About %s:", PLUGIN_NAME);
	SetPanelTitle(panel, Value);

	Format(Value, sizeof(Value), "Version: %s", PLUGIN_VERSION);
	DrawPanelText(panel, Value);

	Format(Value, sizeof(Value), "Author: %s", "Mikko Andersson (muukis)");
	DrawPanelText(panel, Value);

	Format(Value, sizeof(Value), "Description: %s", "Record player statistics.");
	DrawPanelText(panel, Value);

	DrawPanelItem(panel, "Back");
	DrawPanelItem(panel, "Close");

	SendPanelToClient(panel, client, AboutPanelHandler, 30);
	CloseHandle(panel);
}

// Send the RANKABOUT panel to the client's display.
public DisplaySettingsPanel(client)
{
	decl String:Value[MAX_LINE_WIDTH];

	new Handle:panel = CreatePanel();

	Format(Value, sizeof(Value), "%s Settings:", PLUGIN_NAME);
	SetPanelTitle(panel, Value);

	DrawPanelItem(panel, (ClientRankMute[client] ? "Unmute (Currently: Muted)" : "Mute (Currently: Not muted)"));

	DrawPanelItem(panel, "Back");
	DrawPanelItem(panel, "Close");

	SendPanelToClient(panel, client, SettingsPanelHandler, 30);
	CloseHandle(panel);
}

// Send the TOP10 panel to the client's display.
public DisplayTop10(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("DisplayTop10 failed! Reason: %s", error);
		return;
	}

	new String:Name[32];

	new Handle:Top10Panel = CreatePanel();
	SetPanelTitle(Top10Panel, "Top 10 Players");
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		DrawPanelItem(Top10Panel, Name);
	}

	SendPanelToClient(Top10Panel, client, Top10PanelHandler, 30);
	CloseHandle(Top10Panel);
}

// Send the TOP10PPM panel to the client's display.
public DisplayTop10PPM(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("DisplayTop10PPM failed! Reason: %s", error);
		return;
	}

	decl String:Name[32], String:Disp[MAX_LINE_WIDTH];

	new Handle:TopPPMPanel = CreatePanel();
	SetPanelTitle(TopPPMPanel, "Top 10 PPM Players");
if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Format(Disp, sizeof(Disp), "%s (PPM: %.2f)", Name, SQL_FetchFloat(hndl, 1));

		DrawPanelItem(TopPPMPanel, Disp);
	}

	SendPanelToClient(TopPPMPanel, client, Top10PPMPanelHandler, 30);
	CloseHandle(TopPPMPanel);
}

// Handler for RANK panel.
public RankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
  	
}

// Handler for NEXTRANK panel.
public NextRankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (param2 == 1)
		QueryClientStats(param1, CM_NEXTRANKFULL);
		
	
}

// Handler for NEXTRANK panel.
public NextRankFullPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	
}

// Handler for TIMEDMAPS panel.
public TimedMapsPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	
}

// Handler for RANKADMIN panel.
//public RankAdminPanelHandler(Handle:menu, MenuAction:action, param1, param2)
//{
//	if (action != MenuAction_Select)
//		return;
//
//	if (param2 == 1)
//		DisplayClearPanel(param1);
//	else if (param2 == 2)
//		DisplayYesNoPanel(param1, "Do you really want to clear the player stats?", ClearPlayersPanelHandler);
//	else if (param2 == 3)
//		DisplayYesNoPanel(param1, "Do you really want to clear the map stats?", ClearMapsPanelHandler);
//	else if (param2 == 4)
//		DisplayYesNoPanel(param1, "Do you really want to clear all stats?", ClearAllPanelHandler);
//}

// Handler for RANKADMIN panel.
public ClearPlayersPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select) {
		
		return;
	}

	if (param2 == 1)
	{
		ClearStatsPlayers(param1);
		StatsPrintToChatPreFormatted(param1, "All player stats cleared!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
	
	
}

// Handler for RANKADMIN panel.
public ClearMapsPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select) {
		
		return;
	}

	if (param2 == 1)
	{
		ClearStatsMaps(param1);
		StatsPrintToChatPreFormatted(param1, "All map stats cleared!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
	
}

// Handler for RANKADMIN panel.
public ClearAllPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select) {
		
		return;
	}

	if (param2 == 1)
	{
		ClearStatsAll(param1);
		StatsPrintToChatPreFormatted(param1, "All stats cleared!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
	
}

// Handler for RANKADMIN panel.
public CleanPlayersPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	return;
	if (action != MenuAction_Select) {
		
		return;
	}

	if (param2 == 1)
	{
		new LastOnTimeMonths = GetConVarInt(cvar_AdminPlayerCleanLastOnTime);
		new PlaytimeMinutes = GetConVarInt(cvar_AdminPlayerCleanPlatime);

		if (LastOnTimeMonths || PlaytimeMinutes)
		{
			new bool:Success = true;

			if (LastOnTimeMonths)
				Success &= DoFastQuery(param1, "DELETE FROM %splayers WHERE lastontime < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL %i MONTH))", DbPrefix, LastOnTimeMonths);

			if (PlaytimeMinutes)
				Success &= DoFastQuery(param1, "DELETE FROM %splayers WHERE %s < %i AND lastontime < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 1 HOUR))", DbPrefix, DB_PLAYERS_TOTALPLAYTIME, PlaytimeMinutes);

			if (Success)
				StatsPrintToChatPreFormatted(param1, "Player cleaning successful!");
			else
				StatsPrintToChatPreFormatted(param1, "Player cleaning failed!");
		}
		else
			StatsPrintToChatPreFormatted(param1, "Player cleaning is disabled by configurations!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
	
}

// Handler for RANKADMIN panel.
public RemoveCustomMapsPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	return;
	if (action != MenuAction_Select) {
		
		return;
	}

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %smaps WHERE custom = 1", DbPrefix))
			StatsPrintToChatPreFormatted(param1, "All custom maps removed!");
		else
			StatsPrintToChatPreFormatted(param1, "Removing custom maps failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
	
	
}

// Handler for RANKADMIN panel.
public ClearTMAllPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	return;
	if (action != MenuAction_Select) {
		
		return;
	}

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps", DbPrefix))
			StatsPrintToChatPreFormatted(param1, "All map timings removed!");
		else
			StatsPrintToChatPreFormatted(param1, "Removing map timings failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
	
}

// Handler for RANKADMIN panel.
public ClearTMCoopPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	return;
	if (action != MenuAction_Select) {
		
		return;
	}

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE gamemode = %i", DbPrefix, GAMEMODE_COOP))
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Coop successful!");
		else
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Coop failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
	
}

// Handler for RANKADMIN panel.
public ClearTMSurvivalPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	return;
	if (action != MenuAction_Select) {
		
		return;
	}

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE gamemode = %i", DbPrefix, GAMEMODE_SURVIVAL))
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Survival successful!");
		else
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Survival failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
	
}

// Handler for RANKADMIN panel.
public ClearTMRealismPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	return;
	if (action != MenuAction_Select) {
		
		return;
	}

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE gamemode = %i", DbPrefix, GAMEMODE_REALISM))
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Realism successful!");
		else
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Realism failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
	
}

// Handler for RANKADMIN panel.
public ClearTMMutationsPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	return;
	if (action != MenuAction_Select) {
		
		return;
	}

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE gamemode = %i", DbPrefix, GAMEMODE_MUTATIONS))
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Mutations successful!");
		else
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Mutations failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
	
}

// Handler for RANKVOTE panel.
public RankVotePanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select || RankVoteTimer == INVALID_HANDLE || param1 <= 0 || IsClientBot(param1)) {
		
		return;
	}

	if (param2 == 1 || param2 == 2)
	{
		new team = GetClientTeam(param1);

		if (team != TEAM_SURVIVORS && team != TEAM_INFECTED) {
			
			return;
		}

		new OldPlayerRankVote = PlayerRankVote[param1];

		if (param2 == 1)
			PlayerRankVote[param1] = RANKVOTE_YES;
		else if (param2 == 2)
			PlayerRankVote[param1] = RANKVOTE_NO;

		new humans = 0, votes = 0, yesvotes = 0, novotes = 0, WinningVoteCount = 0;

		CheckRankVotes(humans, votes, yesvotes, novotes, WinningVoteCount);

		if (yesvotes >= WinningVoteCount || novotes >= WinningVoteCount)
		{
			if (RankVoteTimer != INVALID_HANDLE)
			{
				CloseHandle(RankVoteTimer);
				RankVoteTimer = INVALID_HANDLE;
			}

			StatsPrintToChatAll("Vote to shuffle teams by player PPM \x03%s \x01with \x04%i (yes) against %i (no)\x01.", (yesvotes >= WinningVoteCount ? "PASSED" : "DID NOT PASS"), yesvotes, novotes);

			if (yesvotes >= WinningVoteCount)
				CreateTimer(2.0, timer_ShuffleTeams);
		}

		if (OldPlayerRankVote != RANKVOTE_NOVOTE) {
			
			return;
		}

		decl String:Name[32];
		GetClientName(param1, Name, sizeof(Name));

		StatsPrintToChatAll("\x05%s \x01voted. \x04%i/%i \x01players have voted.", Name, votes, humans);
	}
	
	
}

CheckRankVotes(&Humans, &Votes, &YesVotes, &NoVotes, &WinningVoteCount)
{
	Humans = 0;
	Votes = 0;
	YesVotes = 0;
	NoVotes = 0;
	WinningVoteCount = 0;

	new i, team, maxplayers = GetMaxClients();

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			team = GetClientTeam(i);

			if (team == TEAM_SURVIVORS || team == TEAM_INFECTED)
			{
				Humans++;

				if (PlayerRankVote[i] != RANKVOTE_NOVOTE)
				{
					Votes++;

					if (PlayerRankVote[i] == RANKVOTE_YES)
						YesVotes++;
				}
			}
		}
	}

	// More than half of the players are needed to vot YES for rankvote pass
	WinningVoteCount = RoundToNearest(float(Humans) / 2) + 1 - (Humans % 2);
	NoVotes = Votes - YesVotes;
}

DisplayClearPanel(client, delay=30)
{
	if (!client)
		return;

	//if (ClearPlayerMenu != INVALID_HANDLE)
	//{
	//	CloseHandle(ClearPlayerMenu);
	//	ClearPlayerMenu = INVALID_HANDLE;
	//}

	new Handle:ClearPlayerMenu = CreateMenu(DisplayClearPanelHandler);
	new maxplayers = GetMaxClients();
	decl String:id[3], String:Name[32];

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		GetClientName(i, Name, sizeof(Name));
		IntToString(i, id, sizeof(id));

		AddMenuItem(ClearPlayerMenu, id, Name);
	}

	SetMenuTitle(ClearPlayerMenu, "Clear player stats:");
	DisplayMenu(ClearPlayerMenu, client, delay);
}

// Handler for RANKADMIN panel.
public DisplayClearPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	return;
	if (menu == INVALID_HANDLE) {
		
		return;
	}

	if (action == MenuAction_End)
		CloseHandle(menu);

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return;

	decl String:id[3];
	new bool:found = GetMenuItem(menu, param2, id, sizeof(id));

	if (!found)
		return;

	new client = StringToInt(id);

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	if (DoFastQuery(param1, "DELETE FROM %splayers WHERE steamid = '%s'", DbPrefix, SteamID))
	{
		DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE steamid = '%s'", DbPrefix, SteamID);

		ClientPoints[client] = 0;
		ClientRank[client] = 0;

		decl String:Name[32];
		GetClientName(client, Name, sizeof(Name));

		StatsPrintToChatPreFormatted(client, "Your player stats were cleared!");
		if (client != param1)
			StatsPrintToChat(param1, "Player \x05%s \x01stats cleared!", Name);
	}
	else
		StatsPrintToChatPreFormatted(param1, "Clearing player stats failed!");
}

// Handler for RANKABOUT panel.
public AboutPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
			cmd_ShowRankMenu(param1, 0);
	}
	
	
}

// Handler for RANK SETTINGS panel.
public SettingsPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
			cmd_ToggleClientRankMute(param1, 0);
		if (param2 == 2)
			cmd_ShowRankMenu(param1, 0);
	}
	
}

// Handler for TOP10 panel.
public Top10PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
			param2 = 10;

		GetClientFromTop10(param1, param2 - 1);
	}
	
	
}

// Handler for TOP10PPM panel.
public Top10PPMPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
			param2 = 10;

		GetClientFromTop10PPM(param1, param2 - 1);
	}
	
	
}

/*
-----------------------------------------------------------------------------
Private functions
-----------------------------------------------------------------------------
*/

HunterSmokerSave(Savior, Victim, BasePoints, AdvMult, ExpertMult, String:SaveFrom[], String:SQLField[])
{
	if (StatsDisabled())
		return;

	Savior = GetClientOfUserId(Savior);
	Victim = GetClientOfUserId(Victim);

	if (IsClientBot(Savior) || IsClientBot(Victim))
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);

	decl String:SaviorName[MAX_LINE_WIDTH];
	GetClientName(Savior, SaviorName, sizeof(SaviorName));
	decl String:SaviorID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Savior, SaviorID, sizeof(SaviorID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));
	decl String:VID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Victim, VID, sizeof(VID));

	if (StrEqual(SaviorID, VID))
		return;

	new Score = ModifyScoreDifficulty(BasePoints, AdvMult, ExpertMult, TEAM_SURVIVORS);
	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, %s = %s + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, SQLField, SQLField, SaviorID);
	SendSQLUpdate(query);

	if (Score <= 0)
		return;

	if (Mode)
		StatsPrintToChat(Savior, "You have earned \x04%i \x01points for saving \x05%s\x01 from \x04%s\x01!", Score, VictimName, SaveFrom);

	UpdateMapStat("points", Score);
	AddScore(Savior, Score);
}

bool:IsClientBot(client)
{
	if (client == 0 || !IsClientConnected(client))
		return true;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	if (StrEqual(SteamID, "BOT", false))
		return true;

	return false;
}

ModifyScoreRealism(BaseScore, ClientTeam, bool:ToCeil=true)
{
	if (ServerVersion != SERVER_VERSION_L4D1)
	{
		decl Handle:Multiplier;
		
		if (CurrentGamemodeID == GAMEMODE_REALISM)
			Multiplier = cvar_RealismMultiplier;
		else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		{
			if (ClientTeam == TEAM_SURVIVORS)
				Multiplier = cvar_RealismVersusSurMultiplier;
			else if(ClientTeam == TEAM_INFECTED)
				Multiplier = cvar_RealismVersusInfMultiplier;
			else
				return BaseScore;
		}
		else
			return BaseScore;

		if (ToCeil)
			BaseScore = RoundToCeil(GetConVarFloat(Multiplier) * BaseScore);
		else
			BaseScore = RoundToFloor(GetConVarFloat(Multiplier) * BaseScore);
	}

	return BaseScore;
}

ModifyScoreDifficultyFloatNR(BaseScore, Float:AdvMult, Float:ExpMult, ClientTeam, bool:ToCeil=true)
{
	return ModifyScoreDifficultyFloat(BaseScore, AdvMult, ExpMult, ClientTeam, ToCeil, false);
}

ModifyScoreDifficultyFloat(BaseScore, Float:AdvMult, Float:ExpMult, ClientTeam, bool:ToCeil=true, bool:Reduction = true)
{
	if (BaseScore <= 0)
		return 0;

	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	new Float:ModifiedScore;

	AdvMult = 1.0;
	ExpMult = 1.0;
	
	if (StrEqual(Difficulty, "Hard", false)) ModifiedScore = BaseScore * AdvMult;
	else if (StrEqual(Difficulty, "Impossible", false)) ModifiedScore = BaseScore * ExpMult;
	else return ModifyScoreRealism(BaseScore, ClientTeam);

	new Score = 0;
	if (ToCeil)
		Score = RoundToCeil(ModifiedScore);
	else
		Score = RoundToFloor(ModifiedScore);

	if (ClientTeam == TEAM_SURVIVORS && Reduction)
		Score = GetMedkitPointReductionScore(Score);

	return ModifyScoreRealism(Score, ClientTeam, ToCeil);
}

// Score modifier without point reduction. Usable for minus points.

ModifyScoreDifficultyNR(BaseScore, AdvMult, ExpMult, ClientTeam)
{
	return ModifyScoreDifficulty(BaseScore, AdvMult, ExpMult, ClientTeam, false);
}

ModifyScoreDifficulty(BaseScore, AdvMult, ExpMult, ClientTeam, bool:Reduction = true)
{
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	AdvMult = 1;
	ExpMult = 1;
	
	if (StrEqual(Difficulty, "hard", false)) BaseScore = BaseScore * AdvMult;
	if (StrEqual(Difficulty, "impossible", false)) BaseScore = BaseScore * ExpMult;

	if (ClientTeam == TEAM_SURVIVORS && Reduction)
		BaseScore = GetMedkitPointReductionScore(BaseScore);

	return ModifyScoreRealism(BaseScore, ClientTeam);
}

IsDifficultyEasy()
{
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "easy", false))
		return true;

	return false;
}

InvalidGameMode()
{
	// Currently will always return False in Survival and Versus gamemodes.
	// This will be removed in a future version when stats for those versions work.

	if (CurrentGamemodeID == GAMEMODE_COOP && GetConVarBool(cvar_EnableCoop))
		return false;
	else if (CurrentGamemodeID == GAMEMODE_SURVIVAL && GetConVarBool(cvar_EnableSv))
		return false;
	else if (CurrentGamemodeID == GAMEMODE_VERSUS && GetConVarBool(cvar_EnableVersus))
		return false;
	else if (CurrentGamemodeID == GAMEMODE_SCAVENGE && GetConVarBool(cvar_EnableScavenge))
		return false;
	else if (CurrentGamemodeID == GAMEMODE_REALISM && GetConVarBool(cvar_EnableRealism))
		return false;
	else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS && GetConVarBool(cvar_EnableRealismVersus))
		return false;
	else if (CurrentGamemodeID == GAMEMODE_MUTATIONS && GetConVarBool(cvar_EnableMutations))
		return false;

	return true;
}

bool:CheckHumans()
{
	new MinHumans = GetConVarInt(cvar_HumansNeeded);
	new Humans = 0;
	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			Humans++;
	}

	if (Humans < MinHumans)
		return true;
	else
		return false;
}

ResetInfVars()
{
	new i;

	// Reset all Infected variables
	for (i = 0; i < MAXPLAYERS + 1; i++)
	{
		BoomerHitCounter[i] = 0;
		BoomerVomitUpdated[i] = false;
		InfectedDamageCounter[i] = 0;
		SmokerDamageCounter[i] = 0;
		SpitterDamageCounter[i] = 0;
		JockeyDamageCounter[i] = 0;
		ChargerDamageCounter[i] = 0;
		ChargerImpactCounter[i] = 0;
		TankPointsCounter[i] = 0;
		TankDamageCounter[i] = 0;
		ClientInfectedType[i] = 0;
		TankSurvivorKillCounter[i] = 0;
		TankDamageTotalCounter[i] = 0;
		ChargerCarryVictim[i] = 0;
		ChargerPlummelVictim[i] = 0;
		JockeyVictim[i] = 0;
		JockeyRideStartTime[i] = 0;

		PlayerBlinded[i][0] = 0;
		PlayerBlinded[i][1] = 0;
		PlayerParalyzed[i][0] = 0;
		PlayerParalyzed[i][1] = 0;
		PlayerLunged[i][0] = 0;
		PlayerLunged[i][1] = 0;
		PlayerPlummeled[i][0] = 0;
		PlayerPlummeled[i][1] = 0;
		PlayerCarried[i][0] = 0;
		PlayerCarried[i][1] = 0;
		PlayerJockied[i][0] = 0;
		PlayerJockied[i][1] = 0;

		TimerBoomerPerfectCheck[i] = INVALID_HANDLE;
		TimerInfectedDamageCheck[i] = INVALID_HANDLE;

		TimerProtectedFriendly[i] = INVALID_HANDLE;
		ProtectedFriendlyCounter[i] = 0;

		if (ChargerImpactCounterTimer[i] != INVALID_HANDLE)
			CloseHandle(ChargerImpactCounterTimer[i]);

		ChargerImpactCounterTimer[i] = INVALID_HANDLE;
	}
}

ResetVars()
{
	ClearTrie(FriendlyFireDamageTrie);
	ClearTrie(PlayerRankVoteTrie);

	TankChaosEvent = 0;
	PlayerVomited = false;
	PlayerVomitedIncap = false;
	PanicEvent = false;
	PanicEventIncap = false;
	CampaignOver = false;
	WitchExists = false;
	WitchDisturb = false;
	MedkitsUsedCounter = 0;
	WitchAllow = true;

	// Reset kill/point score timer amount
	CreateTimer(1.0, InitPlayers);

	TankCount = 0;

	new i, j, maxplayers = GetMaxClients();
	for (i = 1; i <= maxplayers; i++)
	{
		AnnounceCounter[i] = 0;
		CurrentPoints[i] = 0;
		points[i] = 0;
		ClientRankMute[i] = false;
		ProtectedFriendlyCounter[i] = 0;
		FrustrationReset[i] = 0;
	}

	for (i = 0; i < MAXPLAYERS + 1; i++)
	{
		//if (TimerRankChangeCheck[i] != INVALID_HANDLE)
		//	CloseHandle(TimerRankChangeCheck[i]);

		//TimerRankChangeCheck[i] = INVALID_HANDLE;

		for (j = 0; j < MAXPLAYERS + 1; j++)
		{
			FriendlyFireCooldown[i][j] = false;
			FriendlyFireTimer[i][j] = INVALID_HANDLE;
		}

		if (MeleeKillTimer[i] != INVALID_HANDLE)
			CloseHandle(MeleeKillTimer[i]);
		MeleeKillTimer[i] = INVALID_HANDLE;
		MeleeKillCounter[i] = 0;

		PostAdminCheckRetryCounter[i] = 0;
	}

	ResetInfVars();
}

public ResetRankChangeCheck()
{
	return;
	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
		StartRankChangeCheck(i);
}

public StartRankChangeCheck(Client)
{
	return;
	
	if (TimerRankChangeCheck[Client] != INVALID_HANDLE)
		CloseHandle(TimerRankChangeCheck[Client]);

	TimerRankChangeCheck[Client] = INVALID_HANDLE;

	if (Client == 0 || IsClientBot(Client))
		return;

	RankChangeFirstCheck[Client] = true;
	DoShowRankChange(Client);
	TimerRankChangeCheck[Client] = CreateTimer(GetConVarFloat(cvar_AnnounceRankChangeIVal), timer_ShowRankChange, Client, TIMER_REPEAT);
}

StatsDisabled(bool:MapCheck = false)
{
	if (!GetConVarBool(cvar_Enable))
		return true;

	if (InvalidGameMode())
		return true;

	if (!MapCheck && IsDifficultyEasy())
		return true;

	if (!MapCheck && CheckHumans())
		return true;

	if (!MapCheck && GetConVarBool(cvar_Cheats))
		return true;

	if (db == INVALID_HANDLE)
		return true;

	return false;
}

// Check that player the score is in the map score limits and return the value that is addable.

public AddScore(Client, Score)
{
	// ToDo: use cvar_MaxPoints to check if the score is within the map limits
	CurrentPoints[Client] += Score;
	points[Client] += Score;

	//if (GetConVarBool(cvar_AnnounceRankChange))
	//{
	//}

	return Score;
}

public UpdateSmokerDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	decl String:iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_smoker_damage = infected_smoker_damage + %i WHERE steamid = '%s'", DbPrefix, Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_smoker_damage", Damage);
}

public UpdateSpitterDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	decl String:iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_spitter_damage = infected_spitter_damage + %i WHERE steamid = '%s'", DbPrefix, Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_spitter_damage", Damage);
}

public UpdateJockeyDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	decl String:iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_jockey_damage = infected_jockey_damage + %i WHERE steamid = '%s'", DbPrefix, Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_jockey_damage", Damage);
}

UpdateJockeyRideLength(Client, Float:RideLength=-1.0)
{
	if (Client <= 0 || RideLength == 0 || IsClientBot(Client) || (RideLength < 0 && JockeyRideStartTime[Client] <= 0))
		return;

	if (RideLength < 0)
		RideLength = float(GetTime() - JockeyRideStartTime[Client]);

	decl String:iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_jockey_ridetime = infected_jockey_ridetime + %f WHERE steamid = '%s'", DbPrefix, RideLength, iID);
	SendSQLUpdate(query);

	UpdateMapStatFloat("infected_jockey_ridetime", RideLength);
}

public UpdateChargerDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	decl String:iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_charger_damage = infected_charger_damage + %i WHERE steamid = '%s'", DbPrefix, Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_charger_damage", Damage);
}

public CheckSurvivorsWin()
{
	if (CampaignOver)
		return;

	CampaignOver = true;

	StopMapTiming();

	// Return if gamemode is Scavenge or Survival
	if (CurrentGamemodeID == GAMEMODE_SCAVENGE ||
			CurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Witch), 5, 10, TEAM_SURVIVORS);
	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:iID[MAX_LINE_WIDTH];
	decl String:query[1024];
	new maxplayers = GetMaxClients();
	decl String:UpdatePoints[32], String:UpdatePointsPenalty[32];
	new ClientTeam, bool:NegativeScore = GetConVarBool(cvar_EnableNegativeScore);

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			Format(UpdatePointsPenalty, sizeof(UpdatePointsPenalty), "points_infected");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
			Format(UpdatePointsPenalty, sizeof(UpdatePointsPenalty), "points_realism_infected");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	if (Score > 0 && WitchExists && !WitchDisturb)
	{
		for (new i = 1; i <= maxplayers; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, iID);
				SendSQLUpdate(query);
				UpdateMapStat("points", Score);
				AddScore(i, Score);
			}
		}

		if (Mode)
			StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03ALL SURVIVORS \x01have earned \x04%i \x01points for \x05Not Disturbing A Witch!", Score);
	}

	Score = 0;
	new Deaths = 0;
	new BaseScore = ModifyScoreDifficulty(GetConVarInt(cvar_SafeHouse), 2, 5, TEAM_SURVIVORS);

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			if (IsPlayerAlive(i))
				Score = Score + BaseScore;
			else
				Deaths++;
		}
	}

	new String:All4Safe[64] = "";
	if (Deaths == 0)
		Format(All4Safe, sizeof(All4Safe), ", award_allinsafehouse = award_allinsafehouse + 1");

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				InterstitialPlayerUpdate(i);

				GetClientRankAuthString(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i%s WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, All4Safe, iID);
				SendSQLUpdate(query);
				UpdateMapStat("points", Score);
				AddScore(i, Score);
			}
			else if (ClientTeam == TEAM_INFECTED && NegativeScore)
			{
				DoInfectedFinalChecks(i);

				GetClientRankAuthString(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, iID);
				SendSQLUpdate(query);
				AddScore(i, Score * (-1));
			}

			//if (TimerRankChangeCheck[i] != INVALID_HANDLE)
//				TriggerTimer(TimerRankChangeCheck[i], true);
		}
	}

	if (Mode && Score > 0)
	{
		StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03ALL SURVIVORS \x01have earned \x04%i \x01points for reaching a Safe House with \x05%i Deaths!", Score, Deaths);

		if (NegativeScore)
			StatsPrintToChatTeam(TEAM_INFECTED, "\x03ALL INFECTED \x01have \x03LOST \x04%i \x01points for letting the survivors reach a Safe House!", Score);
	}

	PlayerVomited = false;
	PanicEvent = false;
}

IsSingleTeamGamemode()
{
	if (CurrentGamemodeID == GAMEMODE_SCAVENGE ||
			CurrentGamemodeID == GAMEMODE_VERSUS ||
			CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		return false;

	return true;
}

CheckSurvivorsAllDown()
{
	return;
	if (CampaignOver ||
				CurrentGamemodeID == GAMEMODE_COOP ||
				CurrentGamemodeID == GAMEMODE_REALISM)
		return;

	new maxplayers = GetMaxClients();
	new ClientTeam;
	new bool:ClientIsAlive, bool:ClientIsBot, bool:ClientIsIncap;
	new KilledSurvivor[MaxClients];
	new AliveInfected[MaxClients];
	new Infected[MaxClients];
	new InfectedCounter = 0, AliveInfectedCounter = 0;
	new i;

	// Add to killing score on all incapacitated surviviors
	new IncapCounter = 0;

	for (i = 1; i <= maxplayers; i++)
	{
		if (!IsClientInGame(i))
			continue;

		ClientIsBot = IsClientBot(i);
		ClientIsIncap = IsClientIncapacitated(i);
		ClientIsAlive = IsClientAlive(i);

		if (ClientIsBot || IsClientInGame(i))
			ClientTeam = GetClientTeam(i);
		else 
			continue;

		// Client is not dead and not incapped -> game continues!
		if (ClientTeam == TEAM_SURVIVORS && ClientIsAlive && !ClientIsIncap)
			return;

		if (ClientTeam == TEAM_INFECTED && !ClientIsBot)
		{
			if (ClientIsAlive)
				AliveInfected[AliveInfectedCounter++] = i;

			Infected[InfectedCounter++] = i;
		}
		else if (ClientTeam == TEAM_SURVIVORS && ClientIsAlive)
			KilledSurvivor[IncapCounter++] = i;
	}

	// If we ever get this far it means the surviviors are all down or dead!

	CampaignOver = true;

	// Stop the timer and return if gamemode is Survival
	if (CurrentGamemodeID == GAMEMODE_SURVIVAL)
	{
		SurvivalStarted = false;
		StopMapTiming();
		return;
	}

	// If we ever get this far it means the current gamemode is NOT Survival

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == TEAM_SURVIVORS)
				InterstitialPlayerUpdate(i);

			//if (TimerRankChangeCheck[i] != INVALID_HANDLE)
//				TriggerTimer(TimerRankChangeCheck[i], true);
		}
	}

	decl String:query[1024];
	decl String:ClientID[MAX_LINE_WIDTH];
	new Mode = GetConVarInt(cvar_AnnounceMode);

	for (i = 0; i < AliveInfectedCounter; i++)
		DoInfectedFinalChecks(AliveInfected[i]);

	new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_VictoryInfected), 0.75, 0.5, TEAM_INFECTED) * IncapCounter;

	if (Score > 0)
		for (i = 0; i < InfectedCounter; i++)
		{
			if (!IsValidPlayer(Infected[i])) continue;
			GetClientRankAuthString(Infected[i], ClientID, sizeof(ClientID));

			if (CurrentGamemodeID == GAMEMODE_VERSUS)
				Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_infected_win = award_infected_win + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
			else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
				Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_infected_win = award_infected_win + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
			else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
				Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_scavenge_infected_win = award_scavenge_infected_win + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
			else
				Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_scavenge_infected_win = award_scavenge_infected_win + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);

			SendSQLUpdate(query);

		}

	UpdateMapStat("infected_win", 1);
	if (IncapCounter > 0)
		UpdateMapStat("survivor_kills", IncapCounter);
	if (Score > 0)
		UpdateMapStat("points_infected", Score);

	if (Score > 0 && Mode)
		StatsPrintToChatTeam(TEAM_INFECTED, "\x03ALL INFECTED \x01have earned \x04%i \x01points for killing all survivors!", Score);

	if (!GetConVarBool(cvar_EnableNegativeScore))
		return;

	if (CurrentGamemodeID == GAMEMODE_VERSUS)
	{
		Score = ModifyScoreDifficultyFloatNR(GetConVarInt(cvar_Restart), 0.75, 0.5, TEAM_SURVIVORS);
	}
	else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
	{
		Score = ModifyScoreDifficultyFloatNR(GetConVarInt(cvar_Restart), 0.6, 0.3, TEAM_SURVIVORS);
	}
	else
	{
		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Restart), 2, 3, TEAM_SURVIVORS);
		Score = 400 - Score;
	}

	for (i = 0; i < IncapCounter; i++)
	{
		if (!IsValidPlayer(KilledSurvivor[i])) continue;
		GetClientRankAuthString(KilledSurvivor[i], ClientID, sizeof(ClientID));

		if (CurrentGamemodeID == GAMEMODE_VERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_survivors = points_survivors - %i WHERE steamid = '%s'", DbPrefix, Score, ClientID);
		else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_realism_survivors = points_realism_survivors - %i WHERE steamid = '%s'", DbPrefix, Score, ClientID);
		else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
			Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_survivors = points_scavenge_survivors - %i WHERE steamid = '%s'", DbPrefix, Score, ClientID);
		else
			Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations - %i WHERE steamid = '%s'", DbPrefix, Score, ClientID);

		SendSQLUpdate(query);
	}

	if (Mode)
		StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03ALL SURVIVORS \x01have \x03LOST \x04%i \x01points for \x03All Survivors Dying\x01!", Score);
}

bool:IsClientIncapacitated(client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0 ||
				 GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}

bool:IsClientAlive(client)
{
	if (!IsClientConnected(client))
		return false;

	if (IsFakeClient(client))
		return GetClientHealth(client) > 0 && GetEntProp(client, Prop_Send, "m_lifeState") == 0;
	else if (!IsClientInGame(client))
			return false;

	return IsPlayerAlive(client);
}

bool:IsGamemode(const String:Gamemode[])
{
	if (StrContains(CurrentGamemode, Gamemode, false) != -1)
		return true;

	return false;
}

GetGamemodeID(const String:Gamemode[])
{
	if (StrEqual(Gamemode, "coop", false))
		return GAMEMODE_COOP;
	else if (StrEqual(Gamemode, "survival", false))
		return GAMEMODE_SURVIVAL;
	else if (StrEqual(Gamemode, "versus", false))
		return GAMEMODE_VERSUS;
	else if (StrEqual(Gamemode, "teamversus", false) && GetConVarInt(cvar_EnableTeamVersus))
		return GAMEMODE_VERSUS;
	else if (StrEqual(Gamemode, "scavenge", false))
		return GAMEMODE_SCAVENGE;
	else if (StrEqual(Gamemode, "teamscavenge", false) && GetConVarInt(cvar_EnableTeamScavenge))
		return GAMEMODE_SCAVENGE;
	else if (StrEqual(Gamemode, "realism", false))
		return GAMEMODE_REALISM;
	else if (StrEqual(Gamemode, "mutation12", false))
		return GAMEMODE_REALISMVERSUS;
	else if (StrEqual(Gamemode, "teamrealismversus", false) && GetConVarInt(cvar_EnableTeamRealismVersus))
		return GAMEMODE_REALISMVERSUS;
	else if (StrContains(Gamemode, "mutation", false) == 0)
		return GAMEMODE_MUTATIONS;

	return GAMEMODE_UNKNOWN;
}

GetCurrentGamemodeID()
{
	new String:CurrentMode[16];
	GetConVarString(cvar_Gamemode, CurrentMode, sizeof(CurrentMode));

	return GetGamemodeID(CurrentMode);
}

IsGamemodeVersus()
{
	return IsGamemode("versus") || (IsGamemode("teamversus") && GetConVarBool(cvar_EnableTeamVersus));
}
/*
IsGamemodeRealism()
{
	return IsGamemode("realism");
}

IsGamemodeRealismVersus()
{
	return IsGamemode("mutation12");
}

IsGamemodeScavenge()
{
	return IsGamemode("scavege") || (IsGamemode("teamscavege") && GetConVarBool(cvar_EnableTeamScavenge));
}

IsGamemodeCoop()
{
	return IsGamemode("coop");
}
*/
GetSurvivorKillScore()
{
	return ModifyScoreDifficultyFloat(GetConVarInt(cvar_SurvivorDeath), 0.75, 0.5, TEAM_INFECTED);
}

DoInfectedFinalChecks(Client, ClientInfType = -1)
{
	if (Client == 0)
		return;

	if (ClientInfType < 0)
		ClientInfType = ClientInfectedType[Client];

	if (ClientInfType == INF_ID_SMOKER)
	{
		new Damage = SmokerDamageCounter[Client];
		SmokerDamageCounter[Client] = 0;
		UpdateSmokerDamage(Client, Damage);
	}
	else if (ServerVersion != SERVER_VERSION_L4D1 && ClientInfType == INF_ID_SPITTER_L4D2)
	{
		new Damage = SpitterDamageCounter[Client];
		SpitterDamageCounter[Client] = 0;
		UpdateSpitterDamage(Client, Damage);
	}
	else if (ServerVersion != SERVER_VERSION_L4D1 && ClientInfType == INF_ID_JOCKEY_L4D2)
	{
		new Damage = JockeyDamageCounter[Client];
		JockeyDamageCounter[Client] = 0;
		UpdateJockeyDamage(Client, Damage);
		UpdateJockeyRideLength(Client);
	}
	else if (ServerVersion != SERVER_VERSION_L4D1 && ClientInfType == INF_ID_CHARGER_L4D2)
	{
		new Damage = ChargerDamageCounter[Client];
		ChargerDamageCounter[Client] = 0;
		UpdateChargerDamage(Client, Damage);
	}
}

GetInfType(Client)
{
	// Client > 0 && ClientTeam == TEAM_INFECTED checks are done by the caller

	new InfType = GetEntProp(Client, Prop_Send, "m_zombieClass");

	// Make the conversion so that everything gets stored in the correct fields
	if (ServerVersion == SERVER_VERSION_L4D1)
	{
		if (InfType == INF_ID_WITCH_L4D1)
			return INF_ID_WITCH_L4D2;

		if (InfType == INF_ID_TANK_L4D1)
			return INF_ID_TANK_L4D2;
	}

	return InfType;
}

SetClientInfectedType(Client)
{
	// Bot check is done by the caller

	if (Client <= 0)
		return;

	new ClientTeam = GetClientTeam(Client);

	if (ClientTeam == TEAM_INFECTED)
	{
		ClientInfectedType[Client] = GetInfType(Client);

		if (ClientInfectedType[Client] != INF_ID_SMOKER
				&& ClientInfectedType[Client] != INF_ID_BOOMER
				&& ClientInfectedType[Client] != INF_ID_HUNTER
				&& ClientInfectedType[Client] != INF_ID_SPITTER_L4D2
				&& ClientInfectedType[Client] != INF_ID_JOCKEY_L4D2
				&& ClientInfectedType[Client] != INF_ID_CHARGER_L4D2
				&& ClientInfectedType[Client] != INF_ID_TANK_L4D2)
			return;

		decl String:ClientID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

		decl String:query[1024];
		Format(query, sizeof(query), "UPDATE %splayers SET infected_spawn_%i = infected_spawn_%i + 1 WHERE steamid = '%s'", DbPrefix, ClientInfectedType[Client], ClientInfectedType[Client], ClientID);
		SendSQLUpdate(query);

		new String:Spawn[32];
		Format(Spawn, sizeof(Spawn), "infected_spawn_%i", ClientInfectedType[Client]);
		UpdateMapStat(Spawn, 1);
	}
	else
		ClientInfectedType[Client] = 0;
}

TankDamage(Client, Damage)
{
	if ((!IsValidPlayer(Client)) || Damage <= 0)
		return 0;

	// Update only the Tank inflicted damage related statistics
	UpdateTankDamage(Client, Damage);

	// If value is negative then client has already received the Bulldozer Award
	if (TankDamageTotalCounter[Client] >= 0)
	{
		TankDamageTotalCounter[Client] += Damage;
		new TankDamageTotal = GetConVarInt(cvar_TankDamageTotal);

		if (TankDamageTotalCounter[Client] >= TankDamageTotal)
		{
			TankDamageTotalCounter[Client] = -1; // Just one award per Tank
			new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_TankDamageTotalSuccess), 0.75, 0.5, TEAM_INFECTED);

			if (Score > 0)
			{
				decl String:ClientID[MAX_LINE_WIDTH];
				GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

				decl String:query[1024];

				if (CurrentGamemodeID == GAMEMODE_VERSUS)
					Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
				else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
					Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
				else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
					Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
				else
					Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);

				SendSQLUpdate(query);
				AddScore(Client, Score);

				UpdateMapStat("points_infected", Score);

				new Mode = GetConVarInt(cvar_AnnounceMode);

				if (Mode == 1 || Mode == 2)
					StatsPrintToChat(Client, "You have earned \x04%i \x01points for Bulldozing the Survivors worth %i points of damage!", Score, TankDamageTotal);
				else if (Mode == 3)
				{
					decl String:Name[MAX_LINE_WIDTH];
					GetClientName(Client, Name, sizeof(Name));
					StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for Bulldozing the Survivors worth %i points of damage!", Name, Score, TankDamageTotal);
				}

				if (EnableSounds_Tank_Bulldozer && GetConVarBool(cvar_SoundsEnabled))
					EmitSoundToAll(StatsSound_Tank_Bulldozer);
			}
		}
	}

	new DamageLimit = GetConVarInt(cvar_TankDamageCap);

	if (TankDamageCounter[Client] >= DamageLimit)
		return 0;

	TankDamageCounter[Client] += Damage;

	if (TankDamageCounter[Client] > DamageLimit)
		Damage -= TankDamageCounter[Client] - DamageLimit;

	return Damage;
}

UpdateFriendlyFire(Attacker, Victim)
{
	decl String:AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));
	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	new Score = 0;
	if (GetConVarBool(cvar_EnableNegativeScore))
	{
		if (!IsClientBot(Victim))
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FFire), 2, 4, TEAM_SURVIVORS);
		else
		{
			new Float:BotScoreMultiplier = GetConVarFloat(cvar_BotScoreMultiplier);

			if (BotScoreMultiplier > 0.0)
				Score = RoundToNearest(ModifyScoreDifficultyNR(GetConVarInt(cvar_FFire), 2, 4, TEAM_SURVIVORS) * BotScoreMultiplier);
		}
	}

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_MUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i, award_friendlyfire = award_friendlyfire + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, AttackerID);
	SendSQLUpdate(query);
	AddScore(Attacker, -Score);

	new Mode = 0;
	if (Score > 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode == 1 || Mode == 2)
		StatsPrintToChat(Attacker, "You have \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s\x01!", Score, VictimName);
	else if (Mode == 3)
		StatsPrintToChatAll("\x05%s \x01has \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s\x01!", AttackerName, Score, VictimName);
}

UpdateHunterDamage(Client, Damage)
{
	if (Damage <= 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));
	if (strlen(ClientID) > 25) return;
	
	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_hunter_pounce_dmg = infected_hunter_pounce_dmg + %i, infected_hunter_pounce_counter = infected_hunter_pounce_counter + 1 WHERE steamid = '%s'", DbPrefix, Damage, ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_hunter_pounce_counter", 1);
	UpdateMapStat("infected_hunter_pounce_damage", Damage);
}

UpdateTankDamage(Client, Damage)
{
	if (Damage <= 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));
	if (strlen(ClientID) > 25) return;
	
	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_tank_damage = infected_tank_damage + %i WHERE steamid = '%s'", DbPrefix, Damage, ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_tank_damage", Damage);
}
/*
UpdatePlayerScore(Client, Score)
{
	if (Score == 0)
		return;

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			UpdatePlayerScoreVersus(Client, GetClientTeam(Client), Score);
		}
		case GAMEMODE_REALISM:
		{
			UpdatePlayerScoreRealismVersus(Client, GetClientTeam(Client), Score);
		}
		case GAMEMODE_SURVIVAL:
		{
			UpdatePlayerScore2(Client, Score, "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			UpdatePlayerScoreScavenge(Client, GetClientTeam(Client), Score);
		}
		case GAMEMODE_MUTATIONS:
		{
			UpdatePlayerScore2(Client, Score, "points_mutations");
		}
		default:
		{
			UpdatePlayerScore2(Client, Score, "points");
		}
	}
}

UpdatePlayerScoreVersus(Client, ClientTeam, Score)
{
	if (Score == 0)
		return;

	if (ClientTeam == TEAM_SURVIVORS)
		UpdatePlayerScore2(Client, Score, "points_survivors");
	else if (ClientTeam == TEAM_INFECTED)
		UpdatePlayerScore2(Client, Score, "points_infected");
}

UpdatePlayerScoreRealismVersus(Client, ClientTeam, Score)
{
	if (Score == 0)
		return;

	if (ClientTeam == TEAM_SURVIVORS)
		UpdatePlayerScore2(Client, Score, "points_realism_survivors");
	else if (ClientTeam == TEAM_INFECTED)
		UpdatePlayerScore2(Client, Score, "points_realism_infected");
}

UpdatePlayerScoreScavenge(Client, ClientTeam, Score)
{
	if (Score == 0)
		return;

	if (ClientTeam == TEAM_SURVIVORS)
		UpdatePlayerScore2(Client, Score, "points_scavenge_survivors");
	else if (ClientTeam == TEAM_INFECTED)
		UpdatePlayerScore2(Client, Score, "points_scavenge_infected");
}
*/
UpdatePlayerScore2(Client, Score, const String:Points[])
{
	if (Score == 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));
	if (strlen(ClientID) > 25) return;
	
	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i WHERE steamid = '%s'", DbPrefix, Points, Points, Score, ClientID);
	SendSQLUpdate(query);

	if (Score > 0)
		UpdateMapStat("points", Score);

	AddScore(Client, Score);
}

UpdateTankSniper(Client)
{
	if (Client <= 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	UpdateTankSniperSteamID(ClientID);
}

UpdateTankSniperSteamID(const String:ClientID[])
{
	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_tanksniper = infected_tanksniper + 1 WHERE steamid = '%s'", DbPrefix, ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_tanksniper", 1);
}

// Survivor died.

SurvivorDied(Attacker, Victim, AttackerInfType = -1, Mode = -1)
{
	if (!Attacker || !Victim || StatsGetClientTeam(Attacker) != TEAM_INFECTED || StatsGetClientTeam(Victim) != TEAM_SURVIVORS)
		return;

	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	SurvivorDiedNamed(Attacker, Victim, VictimName, AttackerID, AttackerInfType, Mode);
}

// An Infected player killed a Survivor.

SurvivorDiedNamed(Attacker, Victim, const String:VictimName[], const String:AttackerID[], AttackerInfType = -1, Mode = -1)
{
	if (!Attacker || !Victim || StatsGetClientTeam(Attacker) != TEAM_INFECTED || StatsGetClientTeam(Victim) != TEAM_SURVIVORS)
		return;

//LogError("SurvivorDiedNamed - VictimName = %s", VictimName);

	if (AttackerInfType < 0)
	{
		if (ClientInfectedType[Attacker] == 0)
			SetClientInfectedType(Attacker);

		AttackerInfType = ClientInfectedType[Attacker];
	}

	if (ServerVersion == SERVER_VERSION_L4D1)
	{
		if (AttackerInfType != INF_ID_SMOKER
				&& AttackerInfType != INF_ID_BOOMER
				&& AttackerInfType != INF_ID_HUNTER
				&& AttackerInfType != INF_ID_TANK_L4D2) // SetClientInfectedType sets tank id to L4D2
			return;
	}
	else
	{
		if (AttackerInfType != INF_ID_SMOKER
				&& AttackerInfType != INF_ID_BOOMER
				&& AttackerInfType != INF_ID_HUNTER
				&& AttackerInfType != INF_ID_SPITTER_L4D2
				&& AttackerInfType != INF_ID_JOCKEY_L4D2
				&& AttackerInfType != INF_ID_CHARGER_L4D2
				&& AttackerInfType != INF_ID_TANK_L4D2)
			return;
	}

	new Score = GetSurvivorKillScore();

	new len = 0;
	decl String:query[1024];

	if (CurrentGamemodeID == GAMEMODE_VERSUS)
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET points_infected = points_infected + %i, versus_kills_survivors = versus_kills_survivors + 1 ", DbPrefix, Score);
	else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, realism_kills_survivors = realism_kills_survivors + 1 ", DbPrefix, Score);
	else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, scavenge_kills_survivors = scavenge_kills_survivors + 1 ", DbPrefix, Score);
	else
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET points_mutations = points_mutations + %i, mutations_kills_survivors = mutations_kills_survivors + 1 ", DbPrefix, Score);
	len += Format(query[len], sizeof(query)-len, "WHERE steamid = '%s'", AttackerID);
	SendSQLUpdate(query);

	if (Mode < 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode)
	{
		if (Mode > 2)
		{
			decl String:AttackerName[MAX_LINE_WIDTH];
			GetClientName(Attacker, AttackerName, sizeof(AttackerName));
			StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for killing \x05%s\x01!", AttackerName, Score, VictimName);
		}
		else
			StatsPrintToChat(Attacker, "You have earned \x04%i \x01points for killing \x05%s\x01!", Score, VictimName);
	}

	UpdateMapStat("survivor_kills", 1);
	UpdateMapStat("points_infected", Score);
	AddScore(Attacker, Score);
}

// Survivor got hurt.

SurvivorHurt(Attacker, Victim, Damage, AttackerInfType = -1, Handle:event = INVALID_HANDLE)
{
	if (!Attacker || !Victim || Damage <= 0 || Attacker == Victim)
		return;

	if (AttackerInfType < 0)
	{
		new AttackerTeam = GetClientTeam(Attacker);

		if (Attacker > 0 && AttackerTeam == TEAM_INFECTED)
			AttackerInfType = GetInfType(Attacker);
	}

	if (AttackerInfType != INF_ID_SMOKER
			&& AttackerInfType != INF_ID_BOOMER
			&& AttackerInfType != INF_ID_HUNTER
			&& AttackerInfType != INF_ID_SPITTER_L4D2
			&& AttackerInfType != INF_ID_JOCKEY_L4D2
			&& AttackerInfType != INF_ID_CHARGER_L4D2
			&& AttackerInfType != INF_ID_TANK_L4D2)
		return;

	if (TimerInfectedDamageCheck[Attacker] != INVALID_HANDLE)
	{
		CloseHandle(TimerInfectedDamageCheck[Attacker]);
		TimerInfectedDamageCheck[Attacker] = INVALID_HANDLE;
	}

	new VictimHealth = GetClientHealth(Victim);

	if (VictimHealth < 0)
		Damage += VictimHealth;

	if (Damage <= 0)
		return;

	if (AttackerInfType == INF_ID_TANK_L4D2 && event != INVALID_HANDLE)
	{
		InfectedDamageCounter[Attacker] += TankDamage(Attacker, Damage);

		decl String:Weapon[16];
		GetEventString(event, "weapon", Weapon, sizeof(Weapon));

		new RockHit = GetConVarInt(cvar_TankThrowRockSuccess);

		if (RockHit > 0 && strcmp(Weapon, "tank_rock", false) == 0)
		{
			if (CurrentGamemodeID == GAMEMODE_VERSUS)
				UpdatePlayerScore2(Attacker, RockHit, "points_infected");
			else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
				UpdatePlayerScore2(Attacker, RockHit, "points_realism_infected");
			else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
				UpdatePlayerScore2(Attacker, RockHit, "points_scavenge_infected");
			else
				UpdatePlayerScore2(Attacker, RockHit, "points_mutations");
			UpdateTankSniper(Attacker);

			decl String:VictimName[MAX_LINE_WIDTH];

			if (Victim > 0)
				GetClientName(Victim, VictimName, sizeof(VictimName));
			else
				Format(VictimName, sizeof(VictimName), "UNKNOWN");

			new Mode = GetConVarInt(cvar_AnnounceMode);

			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(Attacker, "You have earned \x04%i \x01points for throwing a rock at \x05%s\x01!", RockHit, VictimName);
			else if (Mode == 3)
			{
				decl String:AttackerName[MAX_LINE_WIDTH];
				GetClientName(Attacker, AttackerName, sizeof(AttackerName));
				StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for throwing a rock at \x05%s\x01!", AttackerName, RockHit, VictimName);
			}
		}
	}
	else
		InfectedDamageCounter[Attacker] += Damage;

	if (AttackerInfType == INF_ID_SMOKER)
		SmokerDamageCounter[Attacker] += Damage;
	else if (AttackerInfType == INF_ID_SPITTER_L4D2)
		SpitterDamageCounter[Attacker] += Damage;
	else if (AttackerInfType == INF_ID_JOCKEY_L4D2)
		JockeyDamageCounter[Attacker] += Damage;
	else if (AttackerInfType == INF_ID_CHARGER_L4D2)
		ChargerDamageCounter[Attacker] += Damage;

	TimerInfectedDamageCheck[Attacker] = CreateTimer(5.0, timer_InfectedDamageCheck, Attacker);
}

// Survivor was hurt by normal infected while being blinded and/or paralyzed.

SurvivorHurtExternal(Handle:event, Victim)
{
	if (event == INVALID_HANDLE || !Victim)
		return;

	new Damage = GetEventInt(event, "dmg_health");

	new VictimHealth = GetClientHealth(Victim);

	if (VictimHealth < 0)
		Damage += VictimHealth;

	if (Damage <= 0)
		return;

	new Attacker;

	if (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1])
	{
		Attacker = PlayerBlinded[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}

	if (PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1])
	{
		Attacker = PlayerParalyzed[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (PlayerLunged[Victim][0] && PlayerLunged[Victim][1])
	{
		Attacker = PlayerLunged[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1])
	{
		Attacker = PlayerPlummeled[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (PlayerCarried[Victim][0] && PlayerCarried[Victim][1])
	{
		Attacker = PlayerCarried[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
	{
		Attacker = PlayerJockied[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
}

PlayerDeathExternal(Victim)
{
	if (!Victim || StatsGetClientTeam(Victim) != TEAM_SURVIVORS)
		return;

	CheckSurvivorsAllDown();

	new Attacker = 0;

	if (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1])
	{
		Attacker = PlayerBlinded[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_BOOMER);
	}

	if (PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1])
	{
		Attacker = PlayerParalyzed[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_SMOKER);
	}
	else if (PlayerLunged[Victim][0] && PlayerLunged[Victim][1])
	{
		Attacker = PlayerLunged[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
	else if (PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
	{
		Attacker = PlayerJockied[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
	else if (PlayerCarried[Victim][0] && PlayerCarried[Victim][1])
	{
		Attacker = PlayerCarried[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
	else if (PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1])
	{
		Attacker = PlayerPlummeled[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
}

PlayerIncapExternal(Victim)
{
	if (!Victim || StatsGetClientTeam(Victim) != TEAM_SURVIVORS)
		return;

	CheckSurvivorsAllDown();

	new Attacker = 0;

	if (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1])
	{
		Attacker = PlayerBlinded[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}

	if (PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1])
	{
		Attacker = PlayerParalyzed[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (PlayerLunged[Victim][0] && PlayerLunged[Victim][1])
	{
		Attacker = PlayerLunged[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1])
	{
		Attacker = PlayerPlummeled[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (PlayerCarried[Victim][0] && PlayerCarried[Victim][1])
	{
		Attacker = PlayerCarried[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
	{
		Attacker = PlayerJockied[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
}

SurvivorIncappedByInfected(Attacker, Victim, Mode = -1)
{
	//if (Attacker > 0 && !IsClientConnected(Attacker) || Attacker > 0 && IsClientBot(Attacker))
	if (!IsValidPlayer(Attacker)) return;

	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
	decl String:AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_SurvivorIncap), 0.75, 0.5, TEAM_INFECTED);

	if (Score <= 0)
		return;

	decl String:query[512];

	if (CurrentGamemodeID == GAMEMODE_VERSUS)
		Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
	else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
	else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
		Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
	else
		Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
	SendSQLUpdate(query);
	AddScore(Attacker, Score);

	UpdateMapStat("points_infected", Score);

	if (Mode < 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode == 1 || Mode == 2)
		StatsPrintToChat(Attacker, "You have earned \x04%i \x01points for Incapacitating \x05%s\x01!", Score, VictimName);
	else if (Mode == 3)
		StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for Incapacitating \x05%s\x01!", AttackerName, Score, VictimName);
}

Float:GetMedkitPointReductionFactor()
{
	if (MedkitsUsedCounter <= 0)
		return 1.0;

	new Float:Penalty = GetConVarFloat(cvar_MedkitUsedPointPenalty);

	// If Penalty is set to ZERO: There is no reduction.
	if (Penalty <= 0.0)
		return 1.0;

	new PenaltyFree = -1;

	if (CurrentGamemodeID == GAMEMODE_REALISM || CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		PenaltyFree = GetConVarInt(cvar_MedkitUsedRealismFree);

	if (PenaltyFree < 0)
		PenaltyFree = GetConVarInt(cvar_MedkitUsedFree);

	if (PenaltyFree >= MedkitsUsedCounter)
		return 1.0;

	Penalty *= MedkitsUsedCounter - PenaltyFree;

	new Float:PenaltyMax = GetConVarFloat(cvar_MedkitUsedPointPenaltyMax);

	if (Penalty > PenaltyMax)
		return 1.0 - PenaltyMax;

	return 1.0 - Penalty;
}

// Calculate the score with the medkit point reduction

GetMedkitPointReductionScore(Score, bool:ToCeil = false)
{
	new Float:ReductionFactor = GetMedkitPointReductionFactor();

	if (ReductionFactor == 1.0)
		return Score;

	if (ToCeil)
		return RoundToCeil(Score * ReductionFactor);
	else
		return RoundToFloor(Score * ReductionFactor);
}

AnnounceMedkitPenalty(Mode = -1)
{
	new Float:ReductionFactor = GetMedkitPointReductionFactor();

	if (ReductionFactor == 1.0)
		return;

	if (Mode < 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode)
		StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03ALL SURVIVORS \x01now earns only \x04%i percent \x01of their normal points after using their \x05%i%s Medkit%s\x01!", RoundToNearest(ReductionFactor * 100), MedkitsUsedCounter, (MedkitsUsedCounter == 1 ? "st" : (MedkitsUsedCounter == 2 ? "nd" : (MedkitsUsedCounter == 3 ? "rd" : "th"))), (ServerVersion == SERVER_VERSION_L4D1 ? "" : " or Defibrillator"));
}

GetClientInfectedType(Client)
{
	if (Client > 0 && GetClientTeam(Client) == TEAM_INFECTED)
		return GetInfType(Client);

	return 0;
}

InitializeClientInf(Client)
{
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		if (PlayerParalyzed[i][1] == Client)
		{
			PlayerParalyzed[i][0] = 0;
			PlayerParalyzed[i][1] = 0;
		}
		if (PlayerLunged[i][1] == Client)
		{
			PlayerLunged[i][0] = 0;
			PlayerLunged[i][1] = 0;
		}
		if (PlayerCarried[i][1] == Client)
		{
			PlayerCarried[i][0] = 0;
			PlayerCarried[i][1] = 0;
		}
		if (PlayerPlummeled[i][1] == Client)
		{
			PlayerPlummeled[i][0] = 0;
			PlayerPlummeled[i][1] = 0;
		}
		if (PlayerJockied[i][1] == Client)
		{
			PlayerJockied[i][0] = 0;
			PlayerJockied[i][1] = 0;
		}
	}
}

// Print a chat message to a specific team instead of all players

public StatsPrintToChatTeam(Team, const String:Message[], any:...)
{
	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 3);

	new AnnounceToTeam = GetConVarInt(cvar_AnnounceToTeam);

	if (Team > 0 && AnnounceToTeam)
	{
		new maxplayers = GetMaxClients();
		new ClientTeam;

		for (new i = 1; i <= maxplayers; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			{
				ClientTeam = GetClientTeam(i);
				if (ClientTeam == Team || (ClientTeam == TEAM_SPECTATORS && AnnounceToTeam == 2))
				{
					StatsPrintToChatPreFormatted(i, FormattedMessage);
				}
			}
		}
	}
	else
		StatsPrintToChatAllPreFormatted(FormattedMessage);
}

// Debugging...

public PrintToConsoleAll(const String:Message[], any:...)
{
	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 2);

	PrintToConsole(0, FormattedMessage);

	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			PrintToConsole(i, FormattedMessage);
}

// Disable map timings when opposing team has human players. The time is too much depending on opposing team that is is comparable.

MapTimingEnabled()
{
	return CurrentGamemodeID == GAMEMODE_COOP || CurrentGamemodeID == GAMEMODE_SURVIVAL || CurrentGamemodeID == GAMEMODE_REALISM || CurrentGamemodeID == GAMEMODE_MUTATIONS;
}

public StartMapTiming()
{
	if (!MapTimingEnabled() || MapTimingStartTime != 0.0 || StatsDisabled())
		return;

	MapTimingStartTime = GetEngineTime();

	new ClientTeam, maxplayers = GetMaxClients();
	decl String:ClientID[MAX_LINE_WIDTH];

	ClearTrie(MapTimingSurvivors);
	ClearTrie(MapTimingInfected);

	new bool:SoundsEnabled = EnableSounds_Maptime_Start && GetConVarBool(cvar_SoundsEnabled);

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));
				SetTrieValue(MapTimingSurvivors, ClientID, 1, true);

				if (SoundsEnabled)
					EmitSoundToClient(i, StatsSound_MapTime_Start);
			}
			else if (ClientTeam == TEAM_INFECTED)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));
				SetTrieValue(MapTimingInfected, ClientID, 1, true);
			}
		}
	}
}

GetCurrentDifficulty()
{
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "normal", false)) return 1;
	else if (StrEqual(Difficulty, "hard", false)) return 2;
	else if (StrEqual(Difficulty, "impossible", false)) return 3;
	else return 0;
}

public StopMapTiming()
{
	return;
	if (!MapTimingEnabled() || MapTimingStartTime <= 0.0 || StatsDisabled())
		return;

	new Float:TotalTime = GetEngineTime() - MapTimingStartTime;
	MapTimingStartTime = -1.0;

	new Handle:dp = INVALID_HANDLE;
	new ClientTeam, enabled, maxplayers = GetMaxClients();
	decl String:ClientID[MAX_LINE_WIDTH], String:MapName[MAX_LINE_WIDTH], String:query[512];

	GetCurrentMap(MapName, sizeof(MapName));

	new i, PlayerCounter = 0, InfectedCounter = (CurrentGamemodeID == GAMEMODE_VERSUS || CurrentGamemodeID == GAMEMODE_SCAVENGE ? 0 : 1);

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);
			GetClientRankAuthString(i, ClientID, sizeof(ClientID));

			if (ClientTeam == TEAM_SURVIVORS && GetTrieValue(MapTimingSurvivors, ClientID, enabled))
			{
				if (enabled)
					PlayerCounter++;
			}
			else if (ClientTeam == TEAM_INFECTED)
			{
				InfectedCounter++;
				if (GetTrieValue(MapTimingInfected, ClientID, enabled))
				{
					if (enabled)
						PlayerCounter++;
				}
			}
		}
	}

	// Game ended because all of the infected team left the server... don't record the time!
	if (InfectedCounter <= 0)
		return;

	new GameDifficulty = GetCurrentDifficulty();

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));

				if (GetTrieValue(MapTimingSurvivors, ClientID, enabled))
				{
					if (false)//(enabled)
					{ 
					    
						dp = CreateDataPack();

						WritePackString(dp, MapName);
						WritePackCell(dp, CurrentGamemodeID);
						WritePackString(dp, ClientID);
						WritePackFloat(dp, TotalTime);
						WritePackCell(dp, i);
						WritePackCell(dp, PlayerCounter);
						WritePackCell(dp, GameDifficulty);
						WritePackString(dp, CurrentMutation);

						Format(query, sizeof(query), "SELECT time FROM %stimedmaps WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s'", DbPrefix, MapName, CurrentGamemodeID, GameDifficulty, CurrentMutation, ClientID);

						SQL_TQuery(db, UpdateMapTimingStat, query, dp);
					}
				}
 			}
		}
	}

	ClearTrie(MapTimingSurvivors);
}

public UpdateMapTimingStat(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		if (dp != INVALID_HANDLE)
			CloseHandle(dp);

		LogError("UpdateMapTimingStat Query failed: %s", error);
		return;
	}

	ResetPack(dp);

	decl String:MapName[MAX_LINE_WIDTH], String:ClientID[MAX_LINE_WIDTH], String:query[512], String:TimeLabel[32], String:Mutation[MAX_LINE_WIDTH];
	new GamemodeID, Float:TotalTime, Float:OldTime, Client, PlayerCounter, GameDifficulty;

	ReadPackString(dp, MapName, sizeof(MapName));
	GamemodeID = ReadPackCell(dp);
	ReadPackString(dp, ClientID, sizeof(ClientID));
	TotalTime = ReadPackFloat(dp);
	Client = ReadPackCell(dp);
	PlayerCounter = ReadPackCell(dp);
	GameDifficulty = ReadPackCell(dp);
	ReadPackString(dp, Mutation, sizeof(Mutation));

	CloseHandle(dp);

	// Return if client is not a human player
	if (IsClientBot(Client) || !IsClientInGame(Client))
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);
if (!SQL_HasResultSet(hndl)) return;
	if (SQL_GetRowCount(hndl) > 0)
	{
	
		SQL_FetchRow(hndl);
		OldTime = SQL_FetchFloat(hndl, 0);

		if ((CurrentGamemodeID != GAMEMODE_SURVIVAL && OldTime <= TotalTime) || (CurrentGamemodeID == GAMEMODE_SURVIVAL && OldTime >= TotalTime))
		{
			if (Mode)
			{
				SetTimeLabel(OldTime, TimeLabel, sizeof(TimeLabel));
				StatsPrintToChat(Client, "You did not improve your best time \x04%s \x01to finish this map!", TimeLabel);
			}

			Format(query, sizeof(query), "UPDATE %stimedmaps SET plays = plays + 1, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s'", DbPrefix, MapName, GamemodeID, GameDifficulty, Mutation, ClientID);
		}
		else
		{
			if (Mode)
			{
				SetTimeLabel(TotalTime, TimeLabel, sizeof(TimeLabel));
				StatsPrintToChat(Client, "Your new best time to finish this map is \x04%s\x01!", TimeLabel);
			}

			Format(query, sizeof(query), "UPDATE %stimedmaps SET plays = plays + 1, time = %f, players = %i, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s'", DbPrefix, TotalTime, PlayerCounter, MapName, GamemodeID, GameDifficulty, Mutation, ClientID);

			if (EnableSounds_Maptime_Improve && GetConVarBool(cvar_SoundsEnabled))
				EmitSoundToClient(Client, StatsSound_MapTime_Improve);
		}
	}
	else
	{
		if (Mode)
		{
			SetTimeLabel(TotalTime, TimeLabel, sizeof(TimeLabel));
			StatsPrintToChat(Client, "It took \x04%s \x01to finish this map!", TimeLabel);
		}

		Format(query, sizeof(query), "INSERT INTO %stimedmaps (map, gamemode, difficulty, mutation, steamid, plays, time, players, modified, created) VALUES ('%s', %i, %i, '%s', '%s', 1, %f, %i, NOW(), NOW())", DbPrefix, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, TotalTime, PlayerCounter);
	}

	SendSQLUpdate(query);
}

public SetTimeLabel(Float:TheSeconds, String:TimeLabel[], maxsize)
{
	new FlooredSeconds = RoundToFloor(TheSeconds);
	new FlooredSecondsMod = FlooredSeconds % 60;
	new Float:Seconds = TheSeconds - float(FlooredSeconds) + float(FlooredSecondsMod);
	new Minutes = (TheSeconds < 60.0 ? 0 : RoundToNearest(float(FlooredSeconds - FlooredSecondsMod) / 60));
	new MinutesMod = Minutes % 60;
	new Hours = (Minutes < 60 ? 0 : RoundToNearest(float(Minutes - MinutesMod) / 60));
	Minutes = MinutesMod;

	if (Hours > 0)
		Format(TimeLabel, maxsize, "%ih %im %.1fs", Hours, Minutes, Seconds);
	else if (Minutes > 0)
		Format(TimeLabel, maxsize, "%i min %.1f sec", Minutes, Seconds);
	else
		Format(TimeLabel, maxsize, "%.1f seconds", Seconds);
}

public DisplayRankVote(client)
{
	DisplayYesNoPanel(client, RANKVOTE_QUESTION, RankVotePanelHandler, RoundToNearest(GetConVarFloat(cvar_RankVoteTime)));
}

// Initialize RANKVOTE
public InitializeRankVote(client)
{
	return;
	if (StatsDisabled())
	{
		if (client == 0)
			PrintToConsole(0, "[RANK] Cannot initiate vote when the plugin is disabled!");
		else
			StatsPrintToChatPreFormatted(client, "Cannot initiate vote when the plugin is disabled!");

		return;
	}

	// No TEAM gamemodes are allowed
	if (!IsGamemode("versus") && !IsGamemode("scavenge"))
	{
		if (client == 0)
			PrintToConsole(0, "[RANK] The Rank Vote is not enabled in this gamemode!");
		else
		{
			if (ServerVersion == SERVER_VERSION_L4D1)
				StatsPrintToChatPreFormatted(client, "The \x04Rank Vote \x01is enabled in \x03Versus \x01gamemode!");
			else
				StatsPrintToChatPreFormatted(client, "The \x04Rank Vote \x01is enabled in \x03Versus \x01and \x03Scavenge \x01gamemodes!");
		}

		return;
	}

	if (RankVoteTimer != INVALID_HANDLE)
	{
		if (client > 0)
			DisplayRankVote(client);
		else
			PrintToConsole(client, "[RANK] The Rank Vote is already initiated!");

		return;
	}

	new bool:IsAdmin = (client > 0 ? ((GetUserFlagBits(client) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC) : true);

	new team;
	decl String:ClientID[MAX_LINE_WIDTH];

	if (!IsAdmin && client > 0 && GetTrieValue(PlayerRankVoteTrie, ClientID, team))
	{
		StatsPrintToChatPreFormatted(client, "You can initiate a \x04Rank Vote \x01only once per map!");
		return;
	}

	if (!IsAdmin && client > 0)
	{
		GetClientRankAuthString(client, ClientID, sizeof(ClientID));
		SetTrieValue(PlayerRankVoteTrie, ClientID, 1, true);
	}

	RankVoteTimer = CreateTimer(GetConVarFloat(cvar_RankVoteTime), timer_RankVote);

	new i;

	for (i = 0; i <= MAXPLAYERS; i++)
		PlayerRankVote[i] = RANKVOTE_NOVOTE;

	new maxplayers = GetMaxClients();

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			team = GetClientTeam(i);

			if (team == TEAM_SURVIVORS || team == TEAM_INFECTED)
				DisplayRankVote(i);
		}
	}

	if (client > 0)
	{
		decl String:UserName[MAX_LINE_WIDTH];
		GetClientName(client, UserName, sizeof(UserName));

		StatsPrintToChatAll("The \x04Rank Vote \x01was initiated by \x05%s\x01!", UserName);
	}
	else
		StatsPrintToChatAllPreFormatted("The \x04Rank Vote \x01was initiated from Server Console!");
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock bool:ChangeRankPlayerTeam(client, team)
{
	return true;
	if(GetClientTeam(client) == team) return true;

	if(team != TEAM_SURVIVORS)
	{
		//we can always swap to infected or spectator, it has no actual limit
		ChangeClientTeam(client, team);
		return true;
	}

	if(GetRankTeamHumanCount(team) == GetRankTeamMaxHumans(team))
		return false;

	new bot;
	//for survivors its more tricky
	for (bot = 1; bot < MaxClients + 1 && (!IsClientConnected(bot) || !IsFakeClient(bot) || (GetClientTeam(bot) != TEAM_SURVIVORS)); bot++) {}

	if (bot == MaxClients + 1)
	{
		new String:command[] = "sb_add";
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);

		ServerCommand("sb_add");

		SetCommandFlags(command, flags);

		return false;
	}

	//have to do this to give control of a survivor bot
	SDKCall(L4DStatsSHS, bot, client);
	SDKCall(L4DStatsTOB, client, true);

	return true;
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock bool:IsRankClientInGameHuman(client)
{
	if (client > 0) return IsClientInGame(client) && !IsFakeClient(client);
	else return false;
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock GetRankTeamHumanCount(team)
{
	new humans = 0;
	
	for(new i = 1; i < MaxClients + 1; i++)
	{
		if(IsRankClientInGameHuman(i) && GetClientTeam(i) == team)
			humans++;
	}
	
	return humans;
}

stock GetRankTeamMaxHumans(team)
{
	switch (team)
	{
		case TEAM_SURVIVORS:
			return GetConVarInt(cvar_SurvivorLimit);
		case TEAM_INFECTED:
			return GetConVarInt(cvar_InfectedLimit);
		case TEAM_SPECTATORS:
			return MaxClients;
	}
	
	return -1;
}

GetClientRankAuthString(client, String:auth[], maxlength)
{
	if (!IsValidPlayer(client)) {
		Format(auth, maxlength, "");
	}
	else {
		
		if (GetConVarInt(cvar_Lan))
		{
			GetClientAuthString(client, auth, maxlength);
	
			if (!StrEqual(auth, "BOT", false))
				GetClientIP(client, auth, maxlength);
		}
		else
		{
			GetClientAuthString(client, auth, maxlength);
	
			if (StrEqual(auth, "STEAM_ID_LAN", false))
				GetClientIP(client, auth, maxlength);
		}
	
	}
}

public StatsPrintToChatAll(const String:Message[], any:...)
{
	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 2);

	StatsPrintToChatAllPreFormatted(FormattedMessage);
}

public StatsPrintToChatAllPreFormatted(const String:Message[])
{
	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			StatsPrintToChatPreFormatted(i, Message);
}

public StatsPrintToChat(Client, const String:Message[], any:...)
{
	// CHECK IF CLIENT HAS MUTED THE PLUGIN
	if (ClientRankMute[Client])
		return;

	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 3);

	StatsPrintToChatPreFormatted(Client, FormattedMessage);
}

public StatsPrintToChat2(Client, bool:Forced, const String:Message[], any:...)
{
	// CHECK IF CLIENT HAS MUTED THE PLUGIN
	if (!Forced && ClientRankMute[Client])
		return;

	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 4);

	StatsPrintToChatPreFormatted2(Client, Forced, FormattedMessage);
}

public StatsPrintToChatPreFormatted(Client, const String:Message[])
{
	StatsPrintToChatPreFormatted2(Client, false, Message);
}

public StatsPrintToChatPreFormatted2(Client, bool:Forced, const String:Message[])
{
	// CHECK IF CLIENT HAS MUTED THE PLUGIN
	if (!Forced && ClientRankMute[Client])
		return;

	PrintToChat(Client, "\x04[\x03RANK\x04] \x01%s", Message);
}

stock StatsGetClientTeam(client)
{
	if (client <= 0 || !IsClientConnected(client))
		return TEAM_UNDEFINED;

	if (IsFakeClient(client) || IsClientInGame(client))
		return GetClientTeam(client);

	return TEAM_UNDEFINED;
}

bool:UpdateServerSettings(Client, const String:Key[], const String:Value[], const String:Desc[])
{
	return false;
	new Handle:statement = INVALID_HANDLE;
	decl String:error[1024], String:query[2048];

	// Add a row if it does not previously exist
	if (!DoFastQuery(Client, "INSERT IGNORE INTO %sserver_settings SET sname = '%s', svalue = ''", DbPrefix, Key))
	{
		PrintToConsole(Client, "[RANK] %s: Setting a new MOTD value failure!", Desc);
		return false;
	}

	Format(query, sizeof(query), "UPDATE %sserver_settings SET svalue = ? WHERE sname = '%s'", DbPrefix, Key);

	statement = SQL_PrepareQuery(db, query, error, sizeof(error));

	if (statement == INVALID_HANDLE)
	{
		PrintToConsole(Client, "[RANK] %s: Update failed! (Reason: Cannot create SQL statement)");
		return false;
	}

	new bool:retval = true;
	SQL_BindParamString(statement, 0, Value, false);

	if (!SQL_Execute(statement))
	{
		if (SQL_GetError(db, error, sizeof(error)))
		{
			PrintToConsole(Client, "[RANK] %s: Update failed! (Error = \"%s\")", Desc, error);
			LogError("%s: Update failed! (Error = \"%s\")", error, Desc);
		}
		else
		{
			PrintToConsole(Client, "[RANK] %s: Update failed!", Desc);
			LogError("%s: Update failed!", Desc);
		}
		
		retval = false;
	}
	else
	{
		PrintToConsole(Client, "[RANK] %s: Update successful!", Desc);
		ShowMOTDAll();
	}

	CloseHandle(statement);
	
	return retval;
}

stock ShowMOTDAll()
{
	// TODO
}

stock ShowMOTD(Client)
{
	// TODO
}


//points Start

public Action:ListModules(client, args)
{
	return Plugin_Handled;
	if(args > 0) return Plugin_Handled;
	ReplyToCommand(client, "[PS] Current modules for Points System loaded:");
	for(new i=0; i< 99; i++)
	{
		if(!StrEqual(modules[i], "INVALID")) ReplyToCommand(client, modules[i]);
	}
	ReplyToCommand(client, "[PS] End...");
	return Plugin_Handled;
}	

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead2", false) )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	
	/*CreateNative("PS_GetVersion", PS_GetVersion);
	CreateNative("PS_SetPoints", PS_SetPoints);
	CreateNative("PS_SetItem", PS_SetItem);
	CreateNative("PS_SetCost", PS_SetCost);
	CreateNative("PS_SetBought", PS_SetBought);
	CreateNative("PS_SetBoughtCost", PS_SetBoughtCost);
	//CreateNative("PS_SetupUMob", PS_SetupUMob);
	CreateNative("PS_GetPoints", PS_GetPoints);
	CreateNative("PS_GetBoughtCost", PS_GetBoughtCost);
	CreateNative("PS_GetCost", PS_GetCost);
	CreateNative("PS_GetItem", PS_GetItem);
	CreateNative("PS_GetBought", PS_GetBought);
	CreateNative("PS_RegisterModule", PS_RegisterModule);
	CreateNative("PS_UnregisterModule", PS_UnregisterModule);*/
	Forward1 = CreateGlobalForward("OnPSLoaded", ET_Event, Param_Cell);
	Forward2 = CreateGlobalForward("OnPSUnloaded", ET_Event);
	RegPluginLibrary("ps_natives");
	//forward
	new Action:result;
	Call_StartForward(Forward1);
	Call_PushCell(late);
	Call_Finish(_:result);
	return APLRes_Success;
}

public PS_RegisterModule(Handle:plugin, numParams)
{
	new String:test[100], bool:clone = false;
	GetNativeString(1, test, sizeof(test));
	for(new i=1; i<=99; i++)
	{
		if(StrEqual(modules[i], test))
		{
			clone = true;
			return clone;
		}	
	}	
	if(registeredmodules == 0 && !clone)
	{
		GetNativeString(1, modules[0], 100);
		registeredmodules++;
		return clone;
	}	
	else if(!clone)
	{
		GetNativeString(1, modules[registeredmodules], 100);
		registeredmodules++;
		return clone;
	}
	return true;
}	

public PS_UnregisterModule(Handle:plugin, numParams)
{
	new String:container[100];
	new bool:found = false; //might remove later it might not be good with multiple instances of the same module. though hopefully I can avoid that
	for(new i=0; i <= 99; i++)
	{
		if(found) return;
		GetNativeString(1, container, sizeof(container));
		if(StrEqual(modules[i], container))
		{
			found = true;
			Format(modules[i], 100, "INVALID");
		}
	}
}	

public PS_GetVersion(Handle:plugin, numParams)
{
	return _:version;
}	

public PS_SetPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new newval = GetNativeCell(2);
	points[client] = newval;
}	

public PS_SetItem(Handle:plugin, numParams)
{
	new String:newstring[100];
	new client = GetNativeCell(1);
	GetNativeString(2, newstring, sizeof(newstring));
	Format(item[client], sizeof(item), newstring);
}

public PS_SetCost(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new newval = GetNativeCell(2);
	cost[client] = newval;
}

public PS_SetBought(Handle:plugin, numParams)
{
	new String:newstring[100];
	new client = GetNativeCell(1);
	GetNativeString(2, newstring, sizeof(newstring));
	Format(bought[client], sizeof(bought), newstring);
}

public PS_SetBoughtCost(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new newval = GetNativeCell(2);
	boughtcost[client] = newval;
}	

//public PS_SetupUMob(Handle:plugin, numParams)
//{
//	new newval = GetNativeCell(1);
//	ucommonleft = newval;
//}	

public PS_GetPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return points[client];
}	

public PS_GetCost(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return cost[client];
}	

public PS_GetBoughtCost(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return boughtcost[client];
}	

public PS_GetItem(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	SetNativeString(2, item[client], sizeof(item));
}

public PS_GetBought(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	SetNativeString(2, bought[client], sizeof(bought));
}

public OnClientAuthorized(client, const String:auth[])
{
	if(points[client] > GetConVarInt(StartPoints)) return;
	points[client] = GetConVarInt(StartPoints);
	if(killcount[client] > 0) return;
	killcount[client] = 0;
	wassmoker[client] = 0;
	hurtcount[client] = 0;
	protectcount[client] = 0;
	headshotcount[client] = 0;
}	

public Action:Check(Handle:Timer, any:client)
{
	if(!IsClientConnected(client))
	{
		points[client] = GetConVarInt(StartPoints);
		killcount[client] = 0;
		wassmoker[client] = 0;
		hurtcount[client] = 0;
		protectcount[client] = 0;
		headshotcount[client] = 0;
	}
}	

stock bool:IsAllowedGameMode()
{
	decl String:gamemode[24], String:gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(Modes, gamemodeactive, sizeof(gamemodeactive));
	return (StrContains(gamemodeactive, gamemode) != -1);
}

stock bool:IsAllowedReset()
{
	decl String:gamemode[24], String:gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(ResetPoints, gamemodeactive, sizeof(gamemodeactive));
	return (StrContains(gamemodeactive, gamemode) != -1);
}

public Action:Event_Finale(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new String:gamemode[40];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if(StrEqual(gamemode, "versus", false) || StrEqual(gamemode, "teamversus", false)) return;
	for (new i=1; i<=MaxClients; i++)
	{
		points[i] = GetConVarInt(StartPoints);
		killcount[i] = 0;
		hurtcount[i] = 0;
		protectcount[i] = 0;
		headshotcount[i] = 0;
		wassmoker[i] = 0;
	}
}	

public Action:Event_Kill(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	
	new bool:headshot = GetEventBool(event, "headshot");
	new bool:blast = GetEventBool(event, "blast");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	
		if(headshot)
		{
			headshotcount[attacker]++;
		}	
		if(headshotcount[attacker] == GetConVarInt(SValueHeadSpree) && GetConVarInt(SValueHeadSpree) > 0)
		{
			//points[attacker] += GetConVarInt(SValueHeadSpree);
			headshotcount[attacker] -= GetConVarInt(SNumberHead);
			//if(GetConVarBool(Notifications)) PrintToChat(attacker, "[PS] Head Hunter + %d points [%d]", GetConVarInt(SValueHeadSpree), points[attacker]);
		}
		killcount[attacker]++;
		if(killcount[attacker] == GetConVarInt(SNumberKill) && GetConVarInt(SValueKillingSpree) > 0)
		{
			//points[attacker] += GetConVarInt(SValueKillingSpree);
			killcount[attacker] -= GetConVarInt(SNumberKill);
			//if(GetConVarBool(Notifications)) PrintToChat(attacker, "[PS] Killing Spree + %d points [%d]", GetConVarInt(SValueKillingSpree), points[attacker]);
		}
		if (IsValidPlayer(attacker)) {
			if (SurvVampire[attacker] > 0) {
				new health = GetClientHealth(attacker);
				if (health < 150) {
					if (health + 1 >= 150)  health = 150; else health = health + 1;
					SetEntityHealth(attacker, health);
				}
				PrintToChat(attacker, "\x05+1 HP \x03%t", "Vampire1");
			}
			if ((SurvGift[attacker] > 0) && (!blast)) {
				new wep = GetPlayerWeaponSlot(attacker, 0);
				new String:class[40];
				if (wep != -1) {
					GetEdictClassname(wep, class, sizeof(class));
					if (!StrEqual(class, "weapon_grenade_launcher", false)) {
						if (StrEqual(class, "weapon_rifle_m60", false)) {
							new ammo = GetEntProp(GetPlayerWeaponSlot(attacker, 0), Prop_Send, "m_iClip1");
							if ((ammo+4) >= 250) SetEntProp(GetPlayerWeaponSlot(attacker, 0), Prop_Send, "m_iClip1", 250);
							else SetEntProp(GetPlayerWeaponSlot(attacker, 0), Prop_Send, "m_iClip1", ammo+4);
						}
						else AddWeaponAmmo(attacker, 4);
											
						PrintToChat(attacker, "\x05+4 %t \x03%t", "municion", "ZombiePresents");
					}
				}
			}
		}
		
}	

stock AddWeaponAmmo(client, ammo)
{
	new gun = GetPlayerWeaponSlot(client, 0); //get the players primary weapon
	if (!IsValidEdict(gun)) return Plugin_Continue; //check for validity
	
	decl String:ent_name[64];
	GetEdictClassname(gun, ent_name, sizeof(ent_name)); //get the entities name
		
    new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo"); //get the iAmmo Offset
	decl offsettoadd;
	
	if (StrEqual(ent_name, "weapon_rifle", false) || StrEqual(ent_name, "weapon_rifle_ak47", false) || StrEqual(ent_name, "weapon_rifle_desert", false) || StrEqual(ent_name, "weapon_rifle_sg552", false))
	{ //case: Assault rifles
		offsettoadd = ASSAULT_RIFLE_OFFSET_IAMMO; //gun type specific offset
	}
	else if (StrEqual(ent_name, "weapon_smg", false) || StrEqual(ent_name, "weapon_smg_silenced", false) || StrEqual(ent_name, "weapon_smg_mp5", false))
	{ //case: SMGS
		offsettoadd = SMG_OFFSET_IAMMO; //gun type specific offset
	}		
	else if (StrEqual(ent_name, "weapon_pumpshotgun", false) || StrEqual(ent_name, "weapon_shotgun_chrome", false))
	{ //case: Pump Shotguns
		offsettoadd = PUMPSHOTGUN_OFFSET_IAMMO; //gun type specific offset
	}
	else if (StrEqual(ent_name, "weapon_autoshotgun", false) || StrEqual(ent_name, "weapon_shotgun_spas", false))
	{ //case: Auto Shotguns
		offsettoadd = AUTO_SHOTGUN_OFFSET_IAMMO; //gun type specific offset
	}
	else if (StrEqual(ent_name, "weapon_hunting_rifle", false))
	{ //case: Hunting Rifle
		offsettoadd = HUNTING_RIFLE_OFFSET_IAMMO; //gun type specific offset
	}
	else if (StrEqual(ent_name, "weapon_sniper_military", false) || StrEqual(ent_name, "weapon_sniper_awp", false) || StrEqual(ent_name, "weapon_sniper_scout", false))
	{ //case: Military Sniper Rifle or CSS Snipers
		offsettoadd = MILITARY_SNIPER_OFFSET_IAMMO; //gun type specific offset
	}
	else
	{ //case: no gun this plugin recognizes
		return Plugin_Continue;
	}
	
	new currentammo = GetEntData(client, (iAmmoOffset + offsettoadd)); //get current ammo
		
	SetEntData(client, (iAmmoOffset + offsettoadd), (currentammo + ammo), 4, true); //add bullets to your supply
	
	
}

public Action:Event_Incap(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	ATTACKER
	ACHECK3
	{
		if(GetConVarInt(IIncap) == -1) return;
		//points[attacker] += GetConVarInt(IIncap);
		//if(GetConVarBool(Notifications)) PrintToChat(attacker, "[PS] Incapped Survivor + %d points [%d]", GetConVarInt(IIncap),points[attacker]);
	}	
}	

//public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
//{
	
//}	

public Action:Event_TankDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if (CampaignOver) return;
	new solo = GetEventBool(event, "solo");
	ATTACKER
	ACHECK2
	{
		if(solo && GetConVarInt(STSolo) > 0)
		{
			//points[attacker] += GetConVarInt(STSolo);
			//if(GetConVarBool(Notifications)) PrintToChat(attacker, "[PS] TANK SOLO! + %d points [%d]", GetConVarInt(STSolo), points[attacker]);
		}
	}
	for (new i=1; i<=MaxClients; i++)
	{
		if(i && IsClientInGame(i)&& !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && GetConVarInt(STankKill) > 0 && GetConVarInt(Enable) == 1)
		{
			//points[i] += GetConVarInt(STankKill);
			//if(GetConVarBool(Notifications)) PrintToChat(i, "[PS] Killed Tank + %d points [%d]", GetConVarInt(STankKill), points[i]);
		}	
	}
	tankburning[attacker] = 0;
	tankbiled[attacker] = 0;
	AllowHealth = true;
	
}	

public Action:Event_WitchDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	new oneshot = GetEventBool(event, "oneshot");
	CLIENT
	CCHECK2
	{
		if(GetConVarInt(SWitchKill) == -1) return;
		//points[client] += GetConVarInt(SWitchKill);
		//if(GetConVarBool(Notifications)) PrintToChat(client, "[PS] Killed Witch + %d points [%d]", GetConVarInt(SWitchKill), points[client]);
		if(oneshot && GetConVarInt(SWitchCrown) > 0)
		{
			//points[client] += GetConVarInt(SWitchCrown);
			//if(GetConVarBool(Notifications)) PrintToChat(client, "[PS] Cr0wned The Witch + %d points [%d]", GetConVarInt(SWitchCrown), points[client]);
		}	
	}
	witchburning[client] = 0;
}	

public Action:Event_Heal(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	new restored = GetEventInt(event, "health_restored");
	CLIENT
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	if(subject > 0 && client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		if(client == subject) return;
		if(restored > 39)
		{
			if(GetConVarInt(SHeal) == -1) return;
			//points[client] += GetConVarInt(SHeal);
			//if(GetConVarBool(Notifications)) PrintToChat(client, "[PS] Healed Team Mate + %d points [%d]", GetConVarInt(SHeal), points[client]);
		}
		else
		{
			if(GetConVarInt(SHeal) > 1)
			{
				//points[client] += 1;
				//if(GetConVarBool(Notifications)) PrintToChat(client, "[PS] Don't Harvest Heal Points! + 1 points [%d]", points[client]);
			}
		}
	}
}	

public Action:Event_Protect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	CLIENT
	new award = GetEventInt(event, "award");
	if(client > 0 && award == 67 && GetConVarInt(SProtect) > 0 && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) > 1 && !IsFakeClient(client))
	{
		if(GetConVarInt(SProtect) == -1) return;
		protectcount[client]++;
		if(protectcount[client] == 6)
		{
			//points[client] += GetConVarInt(SProtect);
			protectcount[client] = 0;
		}	
		//if(GetConVarBool(Notifications)) PrintToChat(client, "[PS] Protected Teammate + %d points [%d]", GetConVarInt(SProtect), points[client]);
	}
}

public Action:Event_Revive(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	new bool:ledge = GetEventBool(event, "ledge_hang");
	CLIENT
	CCHECK2
	{
		if(!ledge && GetConVarInt(SRevive) > 0)
		{
			//points[client] += GetConVarInt(SRevive);
			//if(GetConVarBool(Notifications)) PrintToChat(client, "[PS] Revived Team Mate + %d points [%d]", GetConVarInt(SRevive), points[client]);
		}
		else if(ledge && GetConVarInt(SLedge) > 0)
		{
			//points[client] += GetConVarInt(SLedge);
			//if(GetConVarBool(Notifications)) PrintToChat(client, "[PS] Revived Survivor From Ledge + %d points [%d]", GetConVarInt(SLedge), points[client]);
		}	
	}
}	

public Action:Event_Shock(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	CLIENT
	CCHECK2
	{
		if(GetConVarInt(SDefib) == -1) return;
		//points[client] += GetConVarInt(SDefib);
		//if(GetConVarBool(Notifications)) PrintToChat(client, "[PS] Defibbed Team Mate + %d points [%d]", GetConVarInt(SDefib), points[client]);
	}
}	

public Action:Event_Choke(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	CLIENT
	CCHECK3
	{
		if(GetConVarInt(IChoke) == -1) return;
		//points[client] += GetConVarInt(IChoke);
		//if(GetConVarBool(Notifications)) PrintToChat(client, "[PS] Choked Survivor + %d points [%d]", GetConVarInt(IChoke), points[client]);
	}
}

public Action:Event_Boom(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	ATTACKER
	CLIENT
	if(attacker > 0 && !IsFakeClient(attacker) && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		if(GetClientTeam(attacker) == 3 && GetConVarInt(ITag) > 0)
		{
			//points[attacker] += GetConVarInt(ITag);
			//if(GetClientTeam(client) == 2 && GetConVarBool(Notifications)) PrintToChat(attacker, "[PS] Boomed Survivor + %d points [%d]", GetConVarInt(ITag), points[attacker]);
		}
		if(GetClientTeam(attacker) == 2 && GetConVarInt(STag) > 0)
		{
			//points[attacker] += GetConVarInt(STag);
			//if(GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && GetConVarBool(Notifications)) PrintToChat(attacker, "[PS] Biled Tank + %d points [%d]", GetConVarInt(STag), points[attacker]);
			tankbiled[attacker] = 1;
		}	
	}
}	

public Action:Event_Pounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	ATTACKER
	ACHECK3
	{
		if(GetConVarInt(IPounce) == -1) return;
		//points[attacker] += GetConVarInt(IPounce);
		//if(GetConVarBool(Notifications)) PrintToChat(attacker, "[PS] Pounced Survivor + %d points [%d]", GetConVarInt(IPounce), points[attacker]);
	}
}	

public Action:Event_Ride(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	ATTACKER
	ACHECK3
	{
		if(GetConVarInt(IRide) == -1) return;
		//points[attacker] += GetConVarInt(IRide);
		//if(GetConVarBool(Notifications)) PrintToChat(attacker, "[PS] Jockeyed Survivor + %d points [%d]", GetConVarInt(IRide), points[attacker]);
	}
}	

public Action:Event_Carry(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	ATTACKER
	ACHECK3
	{
		if(GetConVarInt(ICarry) == -1) return;
		//points[attacker] += GetConVarInt(ICarry);
		//if(GetConVarBool(Notifications)) PrintToChat(attacker, "[PS] Charged Survivor + %d points [%d]", GetConVarInt(ICarry), points[attacker]);
	}
}	

public Action:Event_Impact(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	ATTACKER
	ACHECK3
	{
		if(GetConVarInt(IImpact) == -1) return;
		//points[attacker] += GetConVarInt(IImpact);
		//if(GetConVarBool(Notifications)) PrintToChat(attacker, "[PS] Crashed Into Another Survivor + %d points [%d]", GetConVarInt(IImpact), points[attacker]);
	}
}	

public Action:Event_Burn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	new String:victim[30];
	GetEventString(event, "victimname", victim, sizeof(victim));
	CLIENT
	CCHECK2
	{
		if(StrEqual(victim, "Tank", false) && tankburning[client] == 0 && GetConVarInt(STBurn) > 0)
		{
			//points[client] += GetConVarInt(STBurn);
			//if(GetConVarBool(Notifications)) PrintToChat(client, "[PS] Burned The Tank + %d points [%d]", GetConVarInt(STBurn), points[client]);
			tankburning[client] = 1;
		}
		if(StrEqual(victim, "Witch", false) && witchburning[client] == 0 && GetConVarInt(SWBurn) > 0)
		{
			//points[client] += GetConVarInt(SWBurn);
			//if(GetConVarBool(Notifications)) PrintToChat(client, "[PS] Burned The Witch + %d points [%d]", GetConVarInt(SWBurn), points[client]);
			witchburning[client] = 1;
		}
	}
}

public Action:Event_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	CLIENT
	ATTACKER
	if(attacker > 0 && client > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 3 && GetClientTeam(client) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1 && GetConVarInt(IHurt) > 0)
	{
		hurtcount[attacker]++;
		if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == 4 && GetEntProp(attacker, Prop_Send, "m_isGhost") == 0 && hurtcount[attacker] >= 8)
		{
			//points[attacker] += GetConVarInt(IHurt);
			//if(GetConVarBool(Notifications)) PrintToChat(attacker, "[PS] Spitter Damage + %d points [%d]", GetConVarInt(IHurt), points[attacker]);
			hurtcount[attacker] -= 8;
			if(wassmoker[attacker] == 0) return;
		}    
		else if(GetEntProp(attacker, Prop_Send, "m_zombieClass") == 1 && !IsPlayerAlive(attacker))
		{
			if(FindConVar("l4d_cloud_damage_enabled") != INVALID_HANDLE)
			{
				if(GetConVarInt(FindConVar("l4d_cloud_damage_enabled")) == 1 && hurtcount[attacker] >= 8 && GetEntProp(attacker, Prop_Send, "m_isGhost") != 1)
				{
					//points[attacker] += GetConVarInt(IHurt);
					//if(GetConVarBool(Notifications)) PrintToChat(attacker, "[SM] Smoker Cloud Damage + %d points [%d]",GetConVarInt(IHurt), points[attacker]);
					hurtcount[attacker] -= 10;
					wassmoker[attacker] = 1;
				}
			}	
		}	
		else if(hurtcount[attacker] >= 3 && wassmoker[attacker] != 1)
		{
			//points[attacker] += GetConVarInt(IHurt);
			//if(GetConVarBool(Notifications)) PrintToChat(attacker, "[SM] Multiple Damage + %d points [%d]",GetConVarInt(IHurt), points[attacker]);
			hurtcount[attacker] -= 3;
		}    
	}	
}	

public Action:BuyMenu(client,args)
{
    if ((IsEnd()) || (MapEnd > 0)) return Plugin_Handled;
	if (!IsValidPlayer(client)) return Plugin_Handled;
		
	decl String:Text[192];
	GetCmdArgString(Text, sizeof(Text));
	if (strlen(Text) > 0) {
		//PrintToChat(client, "параметр: %s", Text);
		SetBuyParams(client, Text);
		ActivateBuy(client);
		return Plugin_Handled;
	}
		
	if ((IsValidPlayer(client)) && (args == 0))
		if (GetClientTeam(client) > 1) 
			BuildBuyMenu(client);

	return Plugin_Handled;
}

public Action:ShowPoints(client,args)
{
	if(IsAllowedGameMode() && GetConVarInt(Enable) == 1 && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) > 1 && args == 0)
	{
		PrintToChat(client, "[PS] You have %d points", points[client]);
	}
	return Plugin_Handled;
}

public Action:Command_RBuy(client, args)
{
	return Plugin_Handled;
	if (args > 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_repeatbuy");
		return Plugin_Handled;
	}
	if(client == 0)
	{
		ReplyToCommand(client, "[SM] This command can only be used in-game");
		return Plugin_Handled;
	}	
	if (args == 0 && client > 0 && IsClientInGame(client))
	{
		RemoveFlags();
		if(points[client] < cost[client])
		{
			PrintToChat(client, "[PS] Not Enough Points %d/%d", points[client], cost[client]);
			AddFlags();
			return Plugin_Handled;
		}	
		if(cost[client] == -1)
		{
			PrintToChat(client, "[PS] Item Disabled");
			AddFlags();
			return Plugin_Handled;
		}	
		points[client] -= cost[client];
		if(StrEqual(item[client], "suicide", false))
		{
//			SetEntData(client, propinfoghost, 1);
			ForcePlayerSuicide(client);
		}	
		else FakeClientCommand(client, "%s", item[client]);
		if(StrEqual(item[client], "z_spawn_old mob", false))
		{
			ucommonleft += GetConVarInt(FindConVar("z_common_limit"));
		}
		else if(StrEqual(item[client], "give ammo", false))
		{
			new wep = GetPlayerWeaponSlot(client, 0);
			if(wep == -1)
			{
				if(IsClientInGame(client)) PrintToChat(client, "[PS] You must have a primary weapon to refill ammo!");
				AddFlags();
				return Plugin_Handled;
			}
			new m60ammo = 150;
			new nadeammo = 30;
			new Handle:cvar = FindConVar("l4d2_guncontrol_m60ammo");
			new Handle:cvar2 = FindConVar("l4d2_guncontrol_grenadelauncherammo");
			if(cvar != INVALID_HANDLE)
			{
				m60ammo = GetConVarInt(cvar);
				CloseHandle(cvar);
			}	
			if(cvar2 != INVALID_HANDLE)
			{
				nadeammo = GetConVarInt(cvar2);
				CloseHandle(cvar2);
			}	
			new String:class[40];
			GetEdictClassname(wep, class, sizeof(class));
			if(StrEqual(class, "weapon_rifle_m60", false)) SetEntProp(wep, Prop_Data, "m_iClip1", m60ammo, 1);
			else if(StrEqual(class, "weapon_grenade_launcher", false))
			{
				new offset = FindDataMapOffs(client, "m_iAmmo");
				SetEntData(client, offset + 68, nadeammo);
			}
		}
		AddFlags();
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Command_Heal(client, args)
{
	if (args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_heal <targetsmlib");
		return Plugin_Handled;
	}
	if (args == 0)
	{
		RemoveFlags();
		FakeClientCommand(client, "give health");
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		AddFlags();
		return Plugin_Handled;
	}
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		RemoveFlags();
		new targetclient;
		targetclient = target_list[i];
		if (IsClientInGame(targetclient)) FakeClientCommand(targetclient, "give health");
		if (IsClientInGame(targetclient)) SetEntPropFloat(targetclient, Prop_Send, "m_healthBuffer", 0.0);
		AddFlags();
	}
	return Plugin_Handled;
}

public Action:Command_Points(client, args)
{
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_givepoints <#userid|name> [number of points]");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
	GetCmdArg(1, arg, sizeof(arg));
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	new targetclient;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			points[targetclient] += StringToInt(arg2);
			new String:name[33];
			GetClientName(targetclient, name, sizeof(name)); 
			ReplyToCommand(client, "[PS] %s's points have been increased by: %s", name, arg2);
		}
	}
	else
	{
		//ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_SPoints(client, args)
{
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setpoints <#userid|name> [number of points]");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	new targetclient;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			points[targetclient] = StringToInt(arg2);
			new String:name[33];
			GetClientName(targetclient, name, sizeof(name)); 
			ReplyToCommand(client, "[PS] %s's points have been set to: %s", name, arg2);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

RemoveFlags()
{
	new flagsgive = GetCommandFlags("give");
	new flagszspawn = GetCommandFlags("z_spawn_old");
	new flagsupgradeadd = GetCommandFlags("upgrade_add");
	new flagsupgraderemove = GetCommandFlags("upgrade_remove");
	new flagspanic = GetCommandFlags("director_force_panic_event");
	
	new flagsspawn = GetCommandFlags("sm_spawnuncommon");
	new flags1 = GetCommandFlags("sm_mutantbomb");
	new flags2 = GetCommandFlags("sm_mutantfire");
	new flags3 = GetCommandFlags("sm_mutantghost");
	new flags4 = GetCommandFlags("sm_mutantmind");
	new flags5 = GetCommandFlags("sm_mutantsmoke");
	new flags6 = GetCommandFlags("sm_mutantspit");
	new flags7 = GetCommandFlags("sm_mutanttesla");
	
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	SetCommandFlags("z_spawn_old", flagszspawn & ~FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd & ~FCVAR_CHEAT);
	SetCommandFlags("upgrade_remove", flagsupgraderemove & ~FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic & ~FCVAR_CHEAT);
	
	SetCommandFlags("sm_spawnuncommon", flagsspawn & ~FCVAR_CHEAT);
	SetCommandFlags("sm_mutantbomb", flags1 & ~FCVAR_CHEAT);
	SetCommandFlags("sm_mutantfire", flags2 & ~FCVAR_CHEAT);
	SetCommandFlags("sm_mutantghost", flags3 & ~FCVAR_CHEAT);
	SetCommandFlags("sm_mutantmind", flags4 & ~FCVAR_CHEAT);
	SetCommandFlags("sm_mutantsmoke", flags5 & ~FCVAR_CHEAT);
	SetCommandFlags("sm_mutantspit", flags6 & ~FCVAR_CHEAT);
	SetCommandFlags("sm_mutanttesla", flags7 & ~FCVAR_CHEAT);
		
	
}	

AddFlags()
{
	new flagsgive = GetCommandFlags("give");
	new flagszspawn = GetCommandFlags("z_spawn_old");
	new flagsupgradeadd = GetCommandFlags("upgrade_add");
	new flagsupgraderemove = GetCommandFlags("upgrade_remove");
	new flagspanic = GetCommandFlags("director_force_panic_event");
	new flagsspawn = GetCommandFlags("sm_spawnuncommon");
	
	new flags1 = GetCommandFlags("sm_mutantbomb");
	new flags2 = GetCommandFlags("sm_mutantfire");
	new flags3 = GetCommandFlags("sm_mutantghost");
	new flags4 = GetCommandFlags("sm_mutantmind");
	new flags5 = GetCommandFlags("sm_mutantsmoke");
	new flags6 = GetCommandFlags("sm_mutantspit");
	new flags7 = GetCommandFlags("sm_mutanttesla");
	
	SetCommandFlags("give", flagsgive|FCVAR_CHEAT);
	SetCommandFlags("z_spawn_old", flagszspawn|FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd|FCVAR_CHEAT);
	SetCommandFlags("upgrade_remove", flagsupgraderemove|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic|FCVAR_CHEAT);
	
	SetCommandFlags("sm_spawnuncommon", flagsspawn|FCVAR_CHEAT);
	SetCommandFlags("sm_mutantbomb", flags1|FCVAR_CHEAT);
	SetCommandFlags("sm_mutantfire", flags2|FCVAR_CHEAT);
	SetCommandFlags("sm_mutantghost", flags3|FCVAR_CHEAT);
	SetCommandFlags("sm_mutantmind", flags4|FCVAR_CHEAT);
	SetCommandFlags("sm_mutantsmoke", flags5|FCVAR_CHEAT);
	SetCommandFlags("sm_mutantspit", flags6|FCVAR_CHEAT);
	SetCommandFlags("sm_mutanttesla", flags7|FCVAR_CHEAT);
}	

BuildBuyMenu(client)
{
    if (!IsValidPlayer(client)) return;
	
	SetGlobalTransTarget(client);
	
	if(GetClientTeam(client) == 2)
	{
		decl String:title[40], String:weapons[40], String:upgrades[40], String:health[40], String:text[40];
		
		new Handle:menu = CreateMenu(MenuHandler_Survivors);
		//SetMenuExitBackButton(menu, true);
				
		Format(text, sizeof(text),"%t", "Momental");
		AddMenuItem(menu, "BuildBuyMenu3", text);
		
		Format(text, sizeof(text),"%t", "LongAction");
		AddMenuItem(menu, "BuildBuyMenu2", text);
				
		Format(text, sizeof(text), "%t", "Items");
		AddMenuItem(menu, "BuildBuyMenu4", text);
		
		Format(text, sizeof(text),"%t", "CommandBonuses");
		AddMenuItem(menu, "BuildBuyMenu5", text);
		
		Format(text, sizeof(text),"%t", "SendPoints");
		AddMenuItem(menu, "SurvSendPoints", text);
		
		
		Format(text, sizeof(title), "Xtreme - Buy System");
	
		Format(text, sizeof(title), "Your VIP status:%i", VipStatus[client]);
	
		Format(title, sizeof(title),"%t: %d", "YourPoints", points[client]);
		
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, 30);
	}
	if(GetClientTeam(client) == 3)
	{
		decl String:text[40];
		decl String:title[40], String:boomer[40], String:spitter[40], String:smoker[40], String:hunter[40], String:charger[40], String:jockey[40];
		decl String:tank[40], String:witch[40], String:witch_bride[40], String:heal[40], String:suicide[40], String:horde[40], String:mob[40], String:umob[40];
		new Handle:menu = CreateMenu(InfectedMenu);
				
		Format(text, sizeof(text),"%t", "SpawnBonuses");
		AddMenuItem(menu, "BuildBuyMenu6", text);
		
		Format(text, sizeof(text),"%t", "Summon");
		AddMenuItem(menu, "BuildBuyMenu7", text);
				
		Format(text, sizeof(text), "%t", "Special");
		AddMenuItem(menu, "BuildBuyMenu8", text);
		
		Format(text, sizeof(text),"%t", "CommandBonuses");
		AddMenuItem(menu, "BuildBuyMenu5", text);
		
		Format(text, sizeof(text),"%t", "SendPoints");
		AddMenuItem(menu, "InfSendPoints", text);
				
		Format(title, sizeof(title),"%t: %d", "YourPoints", points[client]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, 30);
	}
}	

BuildWeaponsMenu(client)
{
	decl String:melee[40], String:rifles[40], String:shotguns[40], String:smg[40], String:snipers[40], String:misc[40], String:title[40], String:throwables[40];
	new Handle:menu = CreateMenu(MenuHandler);
	SetMenuExitBackButton(menu, true);
	if(GetConVarInt(CatMelee) == 1)
	{
		Format(melee, sizeof(melee),"Ближний бой");
		AddMenuItem(menu, "g_MeleeMenu", melee);
	}
	if(GetConVarInt(CatSnipers) == 1)
	{
		Format(snipers, sizeof(snipers),"Снайперки");
		AddMenuItem(menu, "g_SnipersMenu", snipers);
	}
	if(GetConVarInt(CatRifles) == 1)
	{
		Format(rifles, sizeof(rifles),"Автоматы");
		AddMenuItem(menu, "g_RiflesMenu", rifles);
	}
	if(GetConVarInt(CatShotguns) == 1)
	{
		Format(shotguns, sizeof(shotguns),"Помповые");
		AddMenuItem(menu, "g_ShotgunsMenu", shotguns);
	}
	if(GetConVarInt(CatSMG) == 1)
	{
		Format(smg, sizeof(smg),"Пистолеты-пулеметы(SMG)");
		AddMenuItem(menu, "g_SMGMenu", smg);
	}
	if(GetConVarInt(CatThrowables) == 1)
	{
		Format(throwables, sizeof(throwables),"Гранаты");
		AddMenuItem(menu, "g_ThrowablesMenu", throwables);
	}
	if(GetConVarInt(CatMisc) == 1)
	{
		Format(misc, sizeof(misc),"Другие");
		AddMenuItem(menu, "g_MiscMenu", misc);
	}	
	Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
	SetMenuTitle(menu, title);
	DisplayMenu(menu, client, 30);
}

/*
public TopMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		CloseHandle(menu);	
	case MenuAction_Select:
		{
			new String:menu1[56];
			GetMenuItem(menu, param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "g_WeaponsMenu", false))
			{
				BuildWeaponsMenu(param1);
			}	
			if(StrEqual(menu1, "g_HealthMenu", false))
			{
				BuildHealthMenu(param1);
			}	
			if(StrEqual(menu1, "g_UpgradesMenu", false))
			{
				BuildUpgradesMenu(param1);
			}	
		}
	}
	
}
*/	

public MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		CloseHandle(menu);	
		
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{	
				BuildBuyMenu(param1);
			}
		}		
	case MenuAction_Select:
		{
			new String:menu1[56];
			GetMenuItem(menu, param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "g_MeleeMenu", false))
			{
				BuildMeleeMenu(param1);
			}
			if(StrEqual(menu1, "g_RiflesMenu", false))
			{
				BuildRiflesMenu(param1);
			}
			if(StrEqual(menu1, "g_SnipersMenu", false))
			{
				BuildSniperMenu(param1);
			}
			if(StrEqual(menu1, "g_ShotgunsMenu", false))
			{
				BuildShotgunMenu(param1);
			}	
			if(StrEqual(menu1, "g_SMGMenu", false))
			{
				BuildSMGMenu(param1);
			}
			if(StrEqual(menu1, "g_ThrowablesMenu", false))
			{
				BuildThrowablesMenu(param1);
			}	
			if(StrEqual(menu1, "g_MiscMenu", false))
			{
				BuildMiscMenu(param1);
			}	
		}
	}
	
}

BuildMeleeMenu(client)
{
	decl String:fireaxe[40], String:crowbar[40], String:tonfa[40], String:baseball_bat[40], String:cricket_bat[40];
	decl String:electric_guitar[40], String:golfclub[40], String:katana[40], String:frying_pan[40];
	decl String:machete[40], String:title[40];
	if ((StrEqual(MapName, "c1m1_hotel", false)) || (StrEqual(MapName, "c1m2_streets", false)) || (StrEqual(MapName, "c1m3_mall", false)) || (StrEqual(MapName, "c1m4_atrium", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		if(GetConVarInt(PointsCBat) > -1)
		{
			Format(cricket_bat, sizeof(cricket_bat),"Крикет бита");
			AddMenuItem(menu, "cricket_bat", cricket_bat);
		}
		if(GetConVarInt(PointsCrow) > -1)
		{
			Format(crowbar, sizeof(crowbar),"Лом");
			AddMenuItem(menu, "crowbar", crowbar);
		}
		if(GetConVarInt(PointsFireaxe) > -1)
		{
			Format(fireaxe, sizeof(fireaxe),"Топор");
			AddMenuItem(menu, "fireaxe", fireaxe);
		}
		if(GetConVarInt(PointsKatana) > -1)
		{
			Format(katana, sizeof(katana),"Катана");
			AddMenuItem(menu, "katana", katana);
		}
		if(GetConVarInt(PointsBat) > -1)
		{
			Format(baseball_bat, sizeof(baseball_bat),"Бейсбольная бита");
			AddMenuItem(menu, "baseball_bat", baseball_bat);
		}
		Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, 30);
	}
	else if ((StrEqual(MapName, "c2m1_highway", false)) || (StrEqual(MapName, "c2m2_fairgrounds", false)) || (StrEqual(MapName, "c2m3_coaster", false)) || (StrEqual(MapName, "c2m4_barns", false)) || (StrEqual(MapName, "c2m5_concert", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		if(GetConVarInt(PointsCrow) > -1)
		{
			Format(crowbar, sizeof(crowbar),"Лом");
			AddMenuItem(menu, "crowbar", crowbar);
		}
		if(GetConVarInt(PointsCrow) > -1)
		{
			Format(electric_guitar, sizeof(electric_guitar),"Гитара");
			AddMenuItem(menu, "electric_guitar", electric_guitar);
		}
		if(GetConVarInt(PointsFireaxe) > -1)
		{
			Format(fireaxe, sizeof(fireaxe),"Топор");
			AddMenuItem(menu, "fireaxe", fireaxe);
		}
		if(GetConVarInt(PointsKatana) > -1)
		{
			Format(katana, sizeof(katana),"Катана");
			AddMenuItem(menu, "katana", katana);
		}
		if(GetConVarInt(PointsBat) > -1)
		{
			Format(baseball_bat, sizeof(baseball_bat),"Бейсбольная бита");
			AddMenuItem(menu, "baseball_bat", baseball_bat);
		}
		Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, 30);
	}
	else if ((StrEqual(MapName, "c3m1_plankcountry", false)) || (StrEqual(MapName, "c3m2_swamp", false)) || (StrEqual(MapName, "c3m3_shantytown", false)) || (StrEqual(MapName, "c3m4_plantation", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		if(GetConVarInt(PointsCBat) > -1)
		{
			Format(cricket_bat, sizeof(cricket_bat),"Крикет бита");
			AddMenuItem(menu, "cricket_bat", cricket_bat);
		}
		if(GetConVarInt(PointsFireaxe) > -1)
		{
			Format(fireaxe, sizeof(fireaxe),"Топор");
			AddMenuItem(menu, "fireaxe", fireaxe);
		}
		if(GetConVarInt(PointsPan) > -1)
		{
			Format(frying_pan, sizeof(frying_pan),"Сковородка");
			AddMenuItem(menu, "frying_pan", frying_pan);
		}
		if(GetConVarInt(PointsMachete) > -1)
		{
			Format(machete, sizeof(machete),"Мачете");
			AddMenuItem(menu, "machete", machete);
		}
		if(GetConVarInt(PointsBat) > -1)
		{
			Format(baseball_bat, sizeof(baseball_bat),"Бейсбольная бита");
			AddMenuItem(menu, "baseball_bat", baseball_bat);
		}
		Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, 30);
	}
	else if ((StrEqual(MapName, "c4m1_milltown_a", false)) || (StrEqual(MapName, "c4m2_sugarmill_a", false)) || (StrEqual(MapName, "c4m3_sugarmill_b", false)) || (StrEqual(MapName, "c4m4_milltown_b", false)) || (StrEqual(MapName, "c4m5_milltown_escape", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		if(GetConVarInt(PointsCrow) > -1)
		{
			Format(crowbar, sizeof(crowbar),"Лом");
			AddMenuItem(menu, "crowbar", crowbar);
		}
		if(GetConVarInt(PointsFireaxe) > -1)
		{
			Format(fireaxe, sizeof(fireaxe),"Топор");
			AddMenuItem(menu, "fireaxe", fireaxe);
		}
		if(GetConVarInt(PointsPan) > -1)
		{
			Format(frying_pan, sizeof(frying_pan),"Сковородка");
			AddMenuItem(menu, "frying_pan", frying_pan);
		}
		if(GetConVarInt(PointsKatana) > -1)
		{
			Format(katana, sizeof(katana),"Катана");
			AddMenuItem(menu, "katana", katana);
		}
		if(GetConVarInt(PointsBat) > -1)
		{
			Format(baseball_bat, sizeof(baseball_bat),"Бейсбольная бита");
			AddMenuItem(menu, "baseball_bat", baseball_bat);
		}
		Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, 30);
	}
	else if ((StrEqual(MapName, "c5m1_waterfront", false)) || (StrEqual(MapName, "c5m1_waterfront_sndscape", false)) || (StrEqual(MapName, "c5m2_park", false)) || (StrEqual(MapName, "c5m3_cemetery", false)) || (StrEqual(MapName, "c5m4_quarter", false)) || (StrEqual(MapName, "c5m5_bridge", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		if(GetConVarInt(PointsGuitar) > -1)
		{
			Format(electric_guitar, sizeof(electric_guitar),"Гитара");
			AddMenuItem(menu, "electric_guitar", electric_guitar);
		}
		if(GetConVarInt(PointsPan) > -1)
		{
			Format(frying_pan, sizeof(frying_pan),"Сковородка");
			AddMenuItem(menu, "frying_pan", frying_pan);
		}
		if(GetConVarInt(PointsMachete) > -1)
		{
			Format(machete, sizeof(machete),"Мачете");
			AddMenuItem(menu, "machete", machete);
		}
		if(GetConVarInt(PointsTonfa) > -1)
		{
			Format(tonfa, sizeof(tonfa),"Тонфа");
			AddMenuItem(menu, "tonfa", tonfa);
		}
		if(GetConVarInt(PointsBat) > -1)
		{
			Format(baseball_bat, sizeof(baseball_bat),"Бейсбольная бита");
			AddMenuItem(menu, "baseball_bat", baseball_bat);
		}
		Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, 30);
	}
	else if ((StrEqual(MapName, "c6m1_riverbank", false)) || (StrEqual(MapName, "c6m2_bedlam", false)) || (StrEqual(MapName, "c6m3_port", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		if(GetConVarInt(PointsCrow) > -1)
		{
			Format(crowbar, sizeof(crowbar),"Лом");
			AddMenuItem(menu, "crowbar", crowbar);	
		}
		if(GetConVarInt(PointsBat) > -1)
		{
			Format(baseball_bat, sizeof(baseball_bat),"Бейсбольная бита");
			AddMenuItem(menu, "baseball_bat", baseball_bat);
		}
		if(GetConVarInt(PointsKatana) > -1)
		{
			Format(katana, sizeof(katana),"Катана");
			AddMenuItem(menu, "katana", katana);
		}
		if(GetConVarInt(PointsFireaxe) > -1)
		{
			Format(fireaxe, sizeof(fireaxe),"Топор");
			AddMenuItem(menu, "fireaxe", fireaxe);
		}
		if(GetConVarInt(PointsClub) > -1)
		{
			Format(golfclub, sizeof(golfclub),"Гольф клюшка");
			AddMenuItem(menu, "golfclub", golfclub);
		}	
		Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, 30);
	}	
	else if ((StrEqual(MapName, "c7m1_docks", false)) || (StrEqual(MapName, "c7m2_barge", false)) || (StrEqual(MapName, "c7m3_port", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		if(GetConVarInt(PointsCrow) > -1)
		{
			Format(crowbar, sizeof(crowbar), "Лом");
			AddMenuItem(menu, "crowbar", crowbar);
		}
		if(GetConVarInt(PointsBat) > -1)
		{
			Format(baseball_bat, sizeof(baseball_bat), "Бейсбольная бита");
			AddMenuItem(menu, "baseball_bat", baseball_bat);
		}
		if(GetConVarInt(PointsCBat) > -1)
		{
			Format(cricket_bat, sizeof(cricket_bat), "Крикет бита");
			AddMenuItem(menu, "cricket_bat", cricket_bat);
		}
		if(GetConVarInt(PointsKatana) > -1)
		{
			Format(katana, sizeof(katana), "Катана");
			AddMenuItem(menu, "katana", katana);
		}
		if(GetConVarInt(PointsFireaxe) > -1)
		{
			Format(fireaxe, sizeof(fireaxe), "Топор");
			AddMenuItem(menu, "fireaxe", fireaxe);
		}
		Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, 30);
	}
	else if ((StrEqual(MapName, "c8m1_apartment", false)) || (StrEqual(MapName, "c8m2_subway", false)) || (StrEqual(MapName, "c8m3_sewers", false)) || (StrEqual(MapName, "c8m4_interior", false)) || (StrEqual(MapName, "c8m5_rooftop", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		if(GetConVarInt(PointsCrow) > -1)
		{
			Format(crowbar, sizeof(crowbar), "Лом");
			AddMenuItem(menu, "crowbar", crowbar);	
		}	
		if(GetConVarInt(PointsBat) > -1)
		{
			Format(baseball_bat, sizeof(baseball_bat), "Бейсбольная бита");
			AddMenuItem(menu, "baseball_bat", baseball_bat);
		}
		if(GetConVarInt(PointsCBat) > -1)
		{
			Format(cricket_bat, sizeof(cricket_bat), "Крикет бита");
			AddMenuItem(menu, "cricket_bat", cricket_bat);
		}
		if(GetConVarInt(PointsKatana) > -1)
		{
			Format(katana, sizeof(katana), "Катана");
			AddMenuItem(menu, "katana", katana);
		}
		if(GetConVarInt(PointsFireaxe) > -1)
		{
			Format(fireaxe, sizeof(fireaxe), "Топор");
			AddMenuItem(menu, "fireaxe", fireaxe);
		}
		Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, 30);
	}	
	else
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		if(GetConVarInt(PointsCBat) > -1)
		{
			Format(cricket_bat, sizeof(cricket_bat),"Крикет бита");
			AddMenuItem(menu, "cricket_bat", cricket_bat);
		}
		if(GetConVarInt(PointsCrow) > -1)
		{
			Format(crowbar, sizeof(crowbar),"Лом");
			AddMenuItem(menu, "crowbar", crowbar);
		}
		if(GetConVarInt(PointsGuitar) > -1)
		{
			Format(electric_guitar, sizeof(electric_guitar),"Гитара");
			AddMenuItem(menu, "electric_guitar", electric_guitar);
		}
		if(GetConVarInt(PointsFireaxe) > -1)
		{
			Format(fireaxe, sizeof(fireaxe),"Топор");
			AddMenuItem(menu, "fireaxe", fireaxe);
		}
		if(GetConVarInt(PointsPan) > -1)
		{
			Format(frying_pan, sizeof(frying_pan),"Сковородка");
			AddMenuItem(menu, "frying_pan", frying_pan);
		}
		if(GetConVarInt(PointsKatana) > -1)
		{
			Format(katana, sizeof(katana),"Катана");
			AddMenuItem(menu, "katana", katana);
		}
		if(GetConVarInt(PointsMachete) > -1)
		{
			Format(machete, sizeof(machete),"Мачете");
			AddMenuItem(menu, "machete", machete);
		}
		if(GetConVarInt(PointsTonfa) > -1)
		{
			Format(tonfa, sizeof(tonfa),"Тонфа");
			AddMenuItem(menu, "tonfa", tonfa);
		}
		if(GetConVarInt(PointsBat) > -1)
		{
			Format(baseball_bat, sizeof(baseball_bat),"Бейсбольная бита");
			AddMenuItem(menu, "baseball_bat", baseball_bat);
		}
		Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, 30);
	}
}

BuildSniperMenu(client)
{
	decl String:hunting_rifle[40], String:title[40], String:sniper_military[40], String:sniper_scout[40], String:sniper_awp[40];
	new Handle:menu = CreateMenu(MenuHandler_Snipers);
	if(GetConVarInt(PointsHunting) > -1)
	{
		Format(hunting_rifle, sizeof(hunting_rifle),"Hunting Rifle");
		AddMenuItem(menu, "weapon_hunting_rifle", hunting_rifle);
	}
	if(GetConVarInt(PointsMilitary) > -1)
	{
		Format(sniper_military, sizeof(sniper_military),"Military Sniper");
		AddMenuItem(menu, "weapon_sniper_military", sniper_military);
	}
	if(GetConVarInt(PointsAWP) > -1)
	{
		Format(sniper_awp, sizeof(sniper_awp),"AWP");
		AddMenuItem(menu, "weapon_sniper_awp", sniper_awp);
	}
	if(GetConVarInt(PointsScout) > -1)
	{
		Format(sniper_scout, sizeof(sniper_scout),"Scout Sniper");
		AddMenuItem(menu, "weapon_sniper_scout", sniper_scout);
	}
	Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

BuildRiflesMenu(client)
{
	decl String:rifle[40], String:title[40], String:rifle_desert[40], String:rifle_ak47[40], String:rifle_sg552[40], String:rifle_m60[40];
	new Handle:menu = CreateMenu(MenuHandler_Rifles);
	if(GetConVarInt(PointsM60) > -1)
	{
		Format(rifle_m60, sizeof(rifle_m60),"M60");
		AddMenuItem(menu, "weapon_rifle_m60", rifle_m60);
	}
	if(GetConVarInt(PointsM16) > -1)
	{
		Format(rifle, sizeof(rifle),"M16");
		AddMenuItem(menu, "weapon_rifle", rifle);
	}
	if(GetConVarInt(PointsSCAR) > -1)
	{
		Format(rifle_desert, sizeof(rifle_desert),"SCAR");
		AddMenuItem(menu, "weapon_rifle_desert", rifle_desert);
	}
	if(GetConVarInt(PointsAK) > -1)
	{
		Format(rifle_ak47, sizeof(rifle_ak47),"AK-47");
		AddMenuItem(menu, "weapon_rifle_ak47", rifle_ak47);
	}
	if(GetConVarInt(PointsSG) > -1)
	{
		Format(rifle_sg552, sizeof(rifle_sg552),"SG 552");
		AddMenuItem(menu, "weapon_rifle_sg552", rifle_sg552);
	}
	Format(title, sizeof(title),"%d Points Left", points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

BuildShotgunMenu(client)
{
	decl String:autoshotgun[40], String:shotgun_chrome[40], String:shotgun_spas[40], String:pumpshotgun[40], String:title[40]; 
	new Handle:menu = CreateMenu(MenuHandler_Shotguns);
	if(GetConVarInt(PointsAuto) > -1)
	{
		Format(autoshotgun, sizeof(autoshotgun),"Autoshotgun");
		AddMenuItem(menu, "weapon_autoshotgun", autoshotgun);
	}
	if(GetConVarInt(PointsChrome) > -1)
	{
		Format(shotgun_chrome, sizeof(shotgun_chrome),"Chrome Shotgun");
		AddMenuItem(menu, "weapon_shotgun_chrome", shotgun_chrome);
	}
	if(GetConVarInt(PointsSpas) > -1)
	{
		Format(shotgun_spas, sizeof(shotgun_spas),"Spas Shotgun");
		AddMenuItem(menu, "weapon_shotgun_spas", shotgun_spas);
	}
	if(GetConVarInt(PointsPump) > -1)
	{
		Format(pumpshotgun, sizeof(pumpshotgun),"Pump Shotgun");
		AddMenuItem(menu, "weapon_pumpshotgun", pumpshotgun);
	}
	Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	DisplayMenu(menu, client, 30);
}

BuildSMGMenu(client)
{
	decl String:smg[40], String:title[40], String:smg_silenced[40], String:smg_mp5[40];
	new Handle:menu = CreateMenu(MenuHandler_SMG);
	if(GetConVarInt(PointsSMG) > -1)
	{
		Format(smg, sizeof(smg),"SMG");
		AddMenuItem(menu, "weapon_smg", smg);
	}
	if(GetConVarInt(PointsSSMG) > -1)
	{
		Format(smg_silenced, sizeof(smg_silenced),"Silenced SMG");
		AddMenuItem(menu, "weapon_smg_silenced", smg_silenced);
	}
	if(GetConVarInt(PointsMP5) > -1)
	{
		Format(smg_mp5, sizeof(smg_mp5),"MP5");
		AddMenuItem(menu, "weapon_smg_mp5", smg_mp5);
	}
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

BuildHealthMenu(client)
{
	decl String:adrenaline[40], String:defibrillator[40], String:first_aid_kit[40], String:pain_pills[40], String:health[40], String:title[40]; 
	new Handle:menu = CreateMenu(MenuHandler_Health);
	if(GetConVarInt(PointsKit) > -1)
	{
		Format(first_aid_kit, sizeof(first_aid_kit),"Аптечка");
		AddMenuItem(menu, "weapon_first_aid_kit", first_aid_kit);
	}
	if(GetConVarInt(PointsDefib) > -1)
	{
		Format(defibrillator, sizeof(defibrillator),"Дефибриллятор");
		AddMenuItem(menu, "weapon_defibrillator", defibrillator);
	}
	if(GetConVarInt(PointsPills) > -1)
	{
		Format(pain_pills, sizeof(pain_pills),"Таблетки");
		AddMenuItem(menu, "weapon_pain_pills", pain_pills);
	}
	if(GetConVarInt(PointsAdren) > -1)
	{
		Format(adrenaline, sizeof(adrenaline),"Адреналин");
		AddMenuItem(menu, "weapon_adrenaline", adrenaline);
	}
	if(GetConVarInt(PointsHeal) > -1)
	{
		Format(health, sizeof(health),"Вылечиться(полное HP)");
		AddMenuItem(menu, "health", health);
	}
	Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

BuildThrowablesMenu(client)
{
	decl String:molotov[40], String:pipe_bomb[40], String:vomitjar[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_Throwables);
	if(GetConVarInt(PointsMolly) > -1)
	{
		Format(molotov, sizeof(molotov),"Молотов");
		AddMenuItem(menu, "weapon_molotov", molotov);
	}
	if(GetConVarInt(PointsPipe) > -1)
	{
		Format(pipe_bomb, sizeof(pipe_bomb),"Динамит");
		AddMenuItem(menu, "weapon_pipe_bomb", pipe_bomb);
	}
	if(GetConVarInt(PointsBile) > -1)
	{
		Format(vomitjar, sizeof(vomitjar),"Блювота");
		AddMenuItem(menu, "weapon_vomitjar", vomitjar);
	}
	Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

BuildMiscMenu(client)
{
	decl String:grenade_launcher[40], String:fireworkcrate[40], String:gascan[40], String:oxygentank[40], String:propanetank[40], String:pistol[40], String:pistol_magnum[40], String:title[40];
	decl String:gnome[40], String:cola_bottles[40], String:chainsaw[40];
	new Handle:menu = CreateMenu(MenuHandler_Misc);
	if(GetConVarInt(PointsGL) > -1)
	{
		Format(grenade_launcher, sizeof(grenade_launcher),"Гранатомет");
		AddMenuItem(menu, "weapon_grenade_launcher", grenade_launcher);
	}
	if(GetConVarInt(PointsPistol) > -1)
	{
		Format(pistol, sizeof(pistol),"Пистолет");
		AddMenuItem(menu, "weapon_pistol", pistol);
	}
	if(GetConVarInt(PointsMagnum) > -1)
	{
		Format(pistol_magnum, sizeof(pistol_magnum),"Магнум");
		AddMenuItem(menu, "weapon_pistol_magnum", pistol_magnum);
	}
	if(GetConVarInt(PointsSaw) > -1)
	{
		Format(chainsaw, sizeof(chainsaw),"Пила Дружба");
		AddMenuItem(menu, "weapon_chainsaw", chainsaw);
	}
	if(GetConVarInt(PointsGnome) > -1)
	{
		Format(gnome, sizeof(gnome),"Гном");
		AddMenuItem(menu, "weapon_gnome", gnome);
	}
	if(!StrEqual(MapName, "c1m2_streets", false) && GetConVarInt(PointsCola) > -1)
	{
		Format(cola_bottles, sizeof(cola_bottles),"Кола");
		AddMenuItem(menu, "weapon_cola_bottles", cola_bottles);
	}
	if(GetConVarInt(PointsFireWorks) > -1)
	{
		Format(fireworkcrate, sizeof(fireworkcrate),"Фейерверки");
		AddMenuItem(menu, "weapon_fireworkcrate", fireworkcrate);
	}
	new String:gamemode[20];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if(!StrEqual(gamemode, "scavenge", false) && GetConVarInt(PointsGasCan) > -1)
	{
		Format(gascan, sizeof(gascan),"Канистра");
		AddMenuItem(menu, "weapon_gascan", gascan);
	}	
	if(GetConVarInt(PointsOxy) > -1)
	{
		Format(oxygentank, sizeof(oxygentank),"Кислородный баллон");
		AddMenuItem(menu, "weapon_oxygentank", oxygentank);
	}
	if(GetConVarInt(PointsPropane) > -1)
	{
		Format(propanetank, sizeof(propanetank),"Пропановый баллон");
		AddMenuItem(menu, "weapon_propanetank", propanetank);
	}
	Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

BuildUpgradesMenu(client)
{
	decl String:upgradepack_explosive[40], String:upgradepack_incendiary[40], String:title[40];
	decl String:laser_sight[40], String:explosive_ammo[40], String:incendiary_ammo[40], String:ammo[40];
	new Handle:menu = CreateMenu(MenuHandler_Upgrades);
	if(GetConVarInt(PointsLSight) > -1)
	{
		Format(laser_sight, sizeof(laser_sight),"Лазерный прицел");
		AddMenuItem(menu, "laser_sight", laser_sight);
	}
	if(GetConVarInt(PointsEAmmo) > -1)
	{
		Format(explosive_ammo, sizeof(explosive_ammo),"Разрывные пули");
		AddMenuItem(menu, "explosive_ammo", explosive_ammo);
	}
	if(GetConVarInt(PointsIAmmo) > -1)
	{
		Format(incendiary_ammo, sizeof(incendiary_ammo),"Зажигательные пули");
		AddMenuItem(menu, "incendiary_ammo", incendiary_ammo);
	}
	if(GetConVarInt(PointsEAmmoPack) > -1)
	{
		Format(upgradepack_explosive, sizeof(upgradepack_explosive),"Разрывной боеприпас");
		AddMenuItem(menu, "upgradepack_explosive", upgradepack_explosive);
	}
	if(GetConVarInt(PointsIAmmoPack) > -1)
	{
		Format(upgradepack_incendiary, sizeof(upgradepack_incendiary),"Зажигательный боеприпас");
		AddMenuItem(menu, "upgradepack_incendiary", upgradepack_incendiary);
	}
	if(GetConVarInt(PointsRefill) > -1)
	{
		Format(ammo, sizeof(ammo),"Пополнить патроны");
		AddMenuItem(menu, "ammo", ammo);
	}
	Format(title, sizeof(title),"Ваши поинты: %d", points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

public MenuHandler_Melee(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "crowbar", false))
			{
				item[param1] = "give crowbar";
				cost[param1] = GetConVarInt(PointsCrow);
			}
			else if(StrEqual(item1, "cricket_bat", false))
			{
				item[param1] = "give cricket_bat";
				cost[param1] = GetConVarInt(PointsCBat);
			}		
			else if(StrEqual(item1, "baseball_bat", false))
			{
				item[param1] = "give baseball_bat";
				cost[param1] = GetConVarInt(PointsBat);
			}
			else if(StrEqual(item1, "machete", false))
			{
				item[param1] = "give machete";
				cost[param1] = GetConVarInt(PointsMachete);
			}
			else if(StrEqual(item1, "tonfa", false))
			{
				item[param1] = "give tonfa";
				cost[param1] = GetConVarInt(PointsTonfa);
			}
			else if(StrEqual(item1, "katana", false))
			{
				item[param1] = "give katana";
				cost[param1] = GetConVarInt(PointsKatana);
			}
			else if(StrEqual(item1, "fireaxe", false))
			{
				item[param1] = "give fireaxe";
				cost[param1] = GetConVarInt(PointsFireaxe);
			}
			else if(StrEqual(item1, "electric_guitar", false))
			{
				item[param1] = "give electric_guitar";
				cost[param1] = GetConVarInt(PointsGuitar);
			}
			else if(StrEqual(item1, "frying_pan", false))
			{
				item[param1] = "give frying_pan";
				cost[param1] = GetConVarInt(PointsPan);
			}
			else if(StrEqual(item1, "golfclub", false))
			{
				item[param1] = "give golfclub";
				cost[param1] = GetConVarInt(PointsClub);
			}
			DisplayConfirmMenuMelee(param1);
		}
	}
	
}	

public MenuHandler_SMG(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));			
			if(StrEqual(item1, "weapon_smg", false))
			{
				item[param1] = "give smg";
				cost[param1] = GetConVarInt(PointsSMG);
			}
			else if(StrEqual(item1, "weapon_smg_silenced", false))
			{
				item[param1] = "give smg_silenced";
				cost[param1] = GetConVarInt(PointsSSMG);
			}
			else if(StrEqual(item1, "weapon_smg_mp5", false))
			{
				item[param1] = "give smg_mp5";
				cost[param1] = GetConVarInt(PointsMP5);
			}
			DisplayConfirmMenuSMG(param1);
		}
	}
	
}	
			
public MenuHandler_Rifles(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));			
			if(StrEqual(item1, "weapon_rifle", false))
			{
				item[param1] = "give rifle";
				cost[param1] = GetConVarInt(PointsM16);
			}
			else if(StrEqual(item1, "weapon_rifle_desert", false))
			{
				item[param1] = "give rifle_desert";
				cost[param1] = GetConVarInt(PointsSCAR);
			}
			else if(StrEqual(item1, "weapon_rifle_ak47", false))
			{
				item[param1] = "give rifle_ak47";
				cost[param1] = GetConVarInt(PointsAK);
			}
			else if(StrEqual(item1, "weapon_rifle_sg552", false))
			{
				item[param1] = "give rifle_sg552";
				cost[param1] = GetConVarInt(PointsSG);
			}
			else if(StrEqual(item1, "weapon_rifle_m60", false))
			{
				item[param1] = "give rifle_m60";
				cost[param1] = GetConVarInt(PointsM60);
			}
			DisplayConfirmMenuRifles(param1);
		}
	}
	
}	
			
public MenuHandler_Snipers(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));			
			if(StrEqual(item1, "weapon_hunting_rifle", false))
			{
				item[param1] = "give hunting_rifle";
				cost[param1] = GetConVarInt(PointsHunting);
			}
			else if(StrEqual(item1, "weapon_sniper_scout", false))
			{
				item[param1] = "give sniper_scout";
				cost[param1] = GetConVarInt(PointsScout);
			}
			else if(StrEqual(item1, "weapon_sniper_awp", false))
			{
				item[param1] = "give sniper_awp";
				cost[param1] = GetConVarInt(PointsAWP);
			}
			else if(StrEqual(item1, "weapon_sniper_military", false))
			{
				item[param1] = "give sniper_military";
				cost[param1] = GetConVarInt(PointsMilitary);
			}
			DisplayConfirmMenuSnipers(param1);
		}
	}
	
}	
			
public MenuHandler_Shotguns(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));			
			if(StrEqual(item1, "weapon_shotgun_chrome", false))
			{
				item[param1] = "give shotgun_chrome";
				cost[param1] = GetConVarInt(PointsChrome);
			}
			else if(StrEqual(item1, "weapon_pumpshotgun", false))
			{
				item[param1] = "give pumpshotgun";
				cost[param1] = GetConVarInt(PointsPump);
			}
			else if(StrEqual(item1, "weapon_autoshotgun", false))
			{
				item[param1] = "give autoshotgun";
				cost[param1] = GetConVarInt(PointsAuto);
			}
			else if(StrEqual(item1, "weapon_shotgun_spas", false))
			{
				item[param1] = "give shotgun_spas";
				cost[param1] = GetConVarInt(PointsSpas);
			}
			DisplayConfirmMenuShotguns(param1);
		}
	}
	
}	
			
public MenuHandler_Throwables(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));			
			if(StrEqual(item1, "weapon_molotov", false))
			{
				item[param1] = "give molotov";
				cost[param1] = GetConVarInt(PointsMolly);
			}
			else if(StrEqual(item1, "weapon_pipe_bomb", false))
			{
				item[param1] = "give pipe_bomb";
				cost[param1] = GetConVarInt(PointsPipe);
			}
			else if(StrEqual(item1, "weapon_vomitjar", false))
			{
				item[param1] = "give vomitjar";
				cost[param1] = GetConVarInt(PointsBile);
			}
			DisplayConfirmMenuThrow(param1);
		}
	}
	
}	
			
public MenuHandler_Misc(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "weapon_pistol", false))
			{
				item[param1] = "give pistol";
				cost[param1] = GetConVarInt(PointsPistol);
			}
			else if(StrEqual(item1, "weapon_pistol_magnum", false))
			{
				item[param1] = "give pistol_magnum";
				cost[param1] = GetConVarInt(PointsMagnum);
			}
			else if(StrEqual(item1, "weapon_grenade_launcher", false))
			{
				item[param1] = "give grenade_launcher";
				cost[param1] = GetConVarInt(PointsGL);
			}
			else if(StrEqual(item1, "weapon_chainsaw", false))
			{
				item[param1] = "give chainsaw";
				cost[param1] = GetConVarInt(PointsSaw);
			}
			else if(StrEqual(item1, "weapon_gnome", false))
			{
				item[param1] = "give gnome";
				cost[param1] = GetConVarInt(PointsGnome);
			}
			else if(StrEqual(item1, "weapon_cola_bottles", false))
			{
				item[param1] = "give cola_bottles";
				cost[param1] = GetConVarInt(PointsCola);
			}
			else if(StrEqual(item1, "weapon_gascan", false))
			{
				item[param1] = "give gascan";
				cost[param1] = GetConVarInt(PointsGasCan);
			}
			else if(StrEqual(item1, "weapon_propanetank", false))
			{
				item[param1] = "give propanetank";
				cost[param1] = GetConVarInt(PointsPropane);
			}
			else if(StrEqual(item1, "weapon_fireworkcrate", false))
			{
				item[param1] = "give fireworkcrate";
				cost[param1] = GetConVarInt(PointsFireWorks);
			}
			else if(StrEqual(item1, "weapon_oxygentank", false))
			{
				item[param1] = "give oxygentank";
				cost[param1] = GetConVarInt(PointsOxy);
			}
			DisplayConfirmMenuMisc(param1);
		}
	}
	
}

public MenuHandler_Health(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildBuyMenu(param1);
			}
		}
	case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "weapon_first_aid_kit", false))
			{
				item[param1] = "give first_aid_kit";
				cost[param1] = GetConVarInt(PointsKit);
			}
			else if(StrEqual(item1, "weapon_defibrillator", false))
			{
				item[param1] = "give defibrillator";
				cost[param1] = GetConVarInt(PointsDefib);
			}
			else if(StrEqual(item1, "weapon_pain_pills", false))
			{
				item[param1] = "give pain_pills";
				cost[param1] = GetConVarInt(PointsPills);
			}
			else if(StrEqual(item1, "weapon_adrenaline", false))
			{
				item[param1] = "give adrenaline";
				cost[param1] = GetConVarInt(PointsAdren);
			}
			else if(StrEqual(item1, "health", false))
			{
				item[param1] = "give health";
				cost[param1] = GetConVarInt(PointsHeal);
			}
			DisplayConfirmMenuHealth(param1);
		}
	}
	
}

public MenuHandler_Upgrades(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildBuyMenu(param1);
			}
		}	
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "upgradepack_explosive", false))
			{
				item[param1] = "give upgradepack_explosive";
				cost[param1] = GetConVarInt(PointsEAmmoPack);
			}
			else if(StrEqual(item1, "upgradepack_incendiary", false))
			{
				item[param1] = "give upgradepack_incendiary";
				cost[param1] = GetConVarInt(PointsIAmmoPack);
			}
			else if(StrEqual(item1, "explosive_ammo", false))
			{
				item[param1] = "upgrade_add EXPLOSIVE_AMMO";
				cost[param1] = GetConVarInt(PointsEAmmo);
			}
			else if(StrEqual(item1, "incendiary_ammo", false))
			{
				item[param1] = "upgrade_add INCENDIARY_AMMO";
				cost[param1] = GetConVarInt(PointsIAmmo);
			}
			else if(StrEqual(item1, "laser_sight", false))
			{
				item[param1] = "upgrade_add LASER_SIGHT";
				cost[param1] = GetConVarInt(PointsLSight);
			}
			else if(StrEqual(item1, "ammo", false))
			{
				item[param1] = "give ammo";
				cost[param1] = GetConVarInt(PointsRefill);
			}
			DisplayConfirmMenuUpgrades(param1);
		}
	}
	
}	

public InfectedMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (IsValidPlayer(param1))	ShowDistance[param1] = 0;
	
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Select:
		{
			if (!IsValidPlayer(param1)) return;
			SetGlobalTransTarget(param1);
			
			new String:item1[192];
			GetMenuItem(menu, param2, item1, sizeof(item1));
						
			if(StrEqual(item1, "BuildBuyMenu10", false))
			{
				BuildBuyMenu10(param1);
				return;
			}
			if(StrEqual(item1, "BuildBuyMenu11", false))
			{
				BuildBuyMenu11(param1);
				return;
			}
			if(StrEqual(item1, "BuildBuyMenu6", false))
			{
				BuildBuyMenu6(param1);
				return;
			}
			else if(StrEqual(item1, "BuildBuyMenu7", false))
			{
				BuildBuyMenu7(param1);
				return;
			}
			else if(StrEqual(item1, "BuildBuyMenu8", false))
			{
				BuildBuyMenu8(param1);
				return;
			}
			else if(StrEqual(item1, "BuildBuyMenu5", false))
			{
				BuildBuyMenu5(param1);
				return;
			}
			else if(StrEqual(item1, "BuildBuyMenu12", false))
			{
				BuildBuyMenu12(param1);
				return;
			}
			else if(StrEqual(item1, "InfSendPoints", false))
			{
				SetBuyParams(param1, item1);
				return;
			}
			else SetBuyParams(param1, item1);
								
			if ((StrContains(item1, "one ") != -1) || (StrContains(item1, "mutant") != -1))	{ 
				ActivateBuy(param1); 
				return;
			}
			DisplayConfirmMenuI(param1);
		}
	}
	
}

public OnEntityCreated(entity, const String:classname[])
{	
//	if(!StrEqual(classname, "infected", false)) return;
//	new number = 0;
//	if(ucommonleft > 0)
//	{
//		if(GetRandomInt(1, 6) == 1) SetEntityModel(entity, //"models/infected/common_male_riot.mdl");
		//if(GetRandomInt(1, 6) == 2) SetEntityModel(entity, //"models/infected/common_male_ceda.mdl");
		//if(GetRandomInt(1, 6) == 3) SetEntityModel(entity, //"models/infected/common_male_clown.mdl");
		//if(GetRandomInt(1, 6) == 4) SetEntityModel(entity, //"models/infected/common_male_mud.mdl");
		//if(GetRandomInt(1, 6) == 5) SetEntityModel(entity, //"models/infected/common_male_roadcrew.mdl");
		//if(GetRandomInt(1, 6) == 6) SetEntityModel(entity, //"models/infected/common_male_fallen_survivor.mdl");
		//ucommonleft--;
		//if(ucommonleft == number) return;
	//}	
}

DisplayConfirmMenuMelee(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmMelee);
	Format(yes, sizeof(yes),"Да");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"Нет");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Стоимость: %d", cost[param1]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, 30);
}

DisplayConfirmMenuSMG(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmSMG);
	Format(yes, sizeof(yes),"Да");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"Нет");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Стоимость: %d", cost[param1]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, 30);
}

DisplayConfirmMenuRifles(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmRifles);
	Format(yes, sizeof(yes),"Да");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"Нет");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Стоимость: %d", cost[param1]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, 30);
}

DisplayConfirmMenuSnipers(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmSniper);
	Format(yes, sizeof(yes),"Да");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"Нет");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Стоимость: %d", cost[param1]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, 30);
}

DisplayConfirmMenuShotguns(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmShotguns);
	Format(yes, sizeof(yes),"Да");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"Нет");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Стоимость: %d", cost[param1]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, 30);
}

DisplayConfirmMenuThrow(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmThrow);
	Format(yes, sizeof(yes),"Да");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"Нет");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Стоимость: %d", cost[param1]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, 30);
}

DisplayConfirmMenuMisc(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmMisc);
	Format(yes, sizeof(yes),"Да");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"Нет");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Стоимость: %d", cost[param1]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, 30);
}

DisplayConfirmMenuHealth(param1)
{
	decl String:yes[40], String:no[40], String:title[40], String:descr[255], String:text[255];
	new Handle:menu = CreatePanel();
	
	SetGlobalTransTarget(param1);
	
	if (cost[param1] <= 0) Format(title, sizeof(title),"%t", "PutTeamBouns");
	else Format(title, sizeof(title),"%t %d", "Cost", cost[param1]);
	
	SetPanelTitle(menu, title);
	Format(text, sizeof(text), "%t", "Yes");
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%t", "No");
	DrawPanelItem(menu, text);
		
	if (StrEqual(item[param1],"SurvSpeedUp")) {
		Format(text, sizeof(text), "%t", "SurvSpeedUp1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t", "SurvSpeedUp2");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvSpecialShield")) { 
		Format(text, sizeof(text), "%t","SurvSpecialShield1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvSpecialShield2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvSpecialShield3");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvIncSpecialShield")) {
		Format(text, sizeof(text), "%t","SurvIncSpecialShield1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvIncSpecialShield2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t", "SurvIncSpecialShield3");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvVampire")) {
		Format(text, sizeof(text), "%t","SurvVampire1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t", "SurvVampire2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvVampire3");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvShoving")) {
		Format(text, sizeof(text), "%t","SurvShoving1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvShoving2");
		DrawPanelText(menu, text);
	}	
	else if (StrEqual(item[param1],"SurvLaser")) {
		Format(text, sizeof(text), "%t","SurvLaser1");
		DrawPanelText(menu, text);
	}	
	else if (StrEqual(item[param1], "SurvMeleeMaster")) {
		Format(text, sizeof(text), "%t", "SurvMeleeMaster1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvMeleeMaster2");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvRevenge")) {
		Format(text, sizeof(text), "%t","SurvRevenge1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvRevenge2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvRevenge3");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvHealthConvert")) {
		Format(text, sizeof(text), "%t","SurvHealthConvert1");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvGift")) {
		Format(text, sizeof(text), "%t","SurvGift1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvGift2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvGift3");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"GasCan")) {
		Format(text, sizeof(text), "%t","GasCan2");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvAWP")) {
		Format(text, sizeof(text), "%t","SurvAWP1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvAWP2");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvM60")) {
		Format(text, sizeof(text), "%t","SurvM601");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvM602");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvGL")) {
		Format(text, sizeof(text), "%t","SurvGL1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvGL2");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvFireYell")) {
		Format(text, sizeof(text), "%t","SurvFireYell1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvFireYell2");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvPowerYell")) {
		Format(text, sizeof(text), "%t","SurvPowerYell1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvPowerYell2");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvBerserker")) {
		Format(text, sizeof(text), "%t","SurvBerserker1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvBerserker2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvBerserker3");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvMassSpeedUp")) {
		Format(text, sizeof(text), "%t","SurvMassSpeedUp1");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvMassRegen")) {
		Format(text, sizeof(text), "%t","SurvMassRegen1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvMassRegen2");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvAutoMiniGun")) {
		Format(text, sizeof(text), "%t","SurvAutoMiniGun1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvAutoMiniGun2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvAutoMiniGun3");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvAutoMiniGun4");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvZombieSurprize")) {
		Format(text, sizeof(text), "%t","SurvZombieSurprize1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvZombieSurprize2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvZombieSurprize3");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvUntouchable")) {
		Format(text, sizeof(text), "%t","SurvUntouchable1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvUntouchable2");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvPhysPower")) {
		Format(text, sizeof(text), "%t","SurvPhysPower1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvPhysPower2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvPhysPower3");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"SurvFirearmsMaster")) {
		Format(text, sizeof(text), "%t","SurvBulletDamage1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvBulletDamage2");
		DrawPanelText(menu, text);

	}
	else if (StrEqual(item[param1],"SurvVictimShield")) {
		Format(text, sizeof(text), "%t","SurvVictimShield1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%t","SurvVictimShield2");
		DrawPanelText(menu, text);
		
	}
	
	
	//SetMenuExitBackButton(menu, true);
	//DisplayMenu(menu, param1, 30);
	SendPanelToClient(menu, param1,MenuHandler_ConfirmHealth, 30);
	CloseHandle(menu);
}

DisplayConfirmMenuUpgrades(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmUpgrades);
	Format(yes, sizeof(yes),"Да");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"Нет");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Стоимость %d", cost[param1]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, 30);
}	

DisplayConfirmMenuI(param1)
{
	decl String:yes[40], String:no[40], String:title[255], String:descr[255], String:text[255];
	new Handle:menu = CreatePanel();
	
	SetGlobalTransTarget(param1);
	
	if (cost[param1] <= 0) Format(title, sizeof(title),"%t", "PutTeamBouns");
	else Format(title, sizeof(title),"%t %d", "Cost", cost[param1]);
	
	
	SetPanelTitle(menu, title);
	Format(text, sizeof(text),"%t", "Yes");
	DrawPanelItem(menu, text);
	Format(text, sizeof(text),"%t", "No");
	DrawPanelItem(menu, text);
	//Format(descr, sizeof(descr),"%s",GetDescr(item[param1]));
	
	if (StrContains(item[param1], "witch") != -1) {
		ShowDistance[param1] = 1;
		MinDistance[param1] = 800;
		CreateTimer(0.1, ShowDistanceTimer, param1);
	}
	else
	if (StrContains(item[param1], "hulk") != -1) {
		ShowDistance[param1] = 1;
		MinDistance[param1] = 1000;
		CreateTimer(0.1, ShowDistanceTimer, param1);
	}
	
	if (StrEqual(item[param1],"InfSpeedUp")) {
		Format(text, sizeof(text),"%t","InfSpeedUp1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfSpeedUp2");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"InfBonusDamage")) {
		Format(text, sizeof(text),"%t","InfBonusDamage1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfBonusDamage2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfBonusDamage3");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"InfSpecialShield")) {
		Format(text, sizeof(text),"%t","InfSpecialShield1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfSpecialShield2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfSpecialShield3");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"InfBonusHealth")) {
		Format(text, sizeof(text),"%t","InfBonusHealth1");
		DrawPanelText(menu, text); 
		Format(text, sizeof(text),"%t","InfBonusHealth2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfBonusHealth3");
		DrawPanelText(menu, text);
	}	
	else if (StrEqual(item[param1],"InfAcidClaws")) {
		Format(text, sizeof(text),"%t","InfAcidClaws1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfAcidClaws2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfAcidClaws3");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfAcidClaws4");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfAcidClaws5");
		DrawPanelText(menu, text);
	}	
	else if (StrEqual(item[param1],"InfFireShield")) {
		Format(text, sizeof(text),"%t","InfFireShield1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfFireShield2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfFireShield3");
		DrawPanelText(menu, text);
	}	
	else if (StrEqual(item[param1],"InfMask")) {
		Format(text, sizeof(text),"%t","InfMask1");
		DrawPanelText(menu, text);
	}	
	else if (StrEqual(item[param1],"InfMeeleShield")) {
		Format(text, sizeof(text),"%t","InfMeeleShield1");
		DrawPanelText(menu, text);
	}	
	else if (StrEqual(item[param1],"InfRegen")) {
	Format(text, sizeof(text),"%t","InfRegen1");
		DrawPanelText(menu, text);
	}	
	else if (StrEqual(item[param1],"hulk")) {
		Format(text, sizeof(text),"%t","hulk1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","hulk2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","hulk3");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","hulk4");
		DrawPanelText(menu, text);
		
	}
	else if (StrEqual(item[param1],"InfMassSlow")) {
		Format(text, sizeof(text),"%t","InfMassSlow1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfMassSlow2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfMassSlow3");
		DrawPanelText(menu, text);
		
	}
	else if (StrEqual(item[param1],"InfMassArmor")) {
		Format(text, sizeof(text),"%t","InfMassArmor1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfMassArmor2");
		DrawPanelText(menu, text);
}
	else if (StrEqual(item[param1],"InfTankChaos")) {
		Format(text, sizeof(text),"%t","InfTankChaos1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfTankChaos2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfTankChaos3");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfTankChaos4");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"InfDeathCloud")) {
		Format(text, sizeof(text),"%t","InfDeathCloud1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfDeathCloud2");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfDeathCloud3");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"InfZombieApoc")) {
		Format(text, sizeof(text),"%t","InfZombieApoc1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfZombieApoc2");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"InfPoison")) {
		Format(text, sizeof(text),"%t","InfPoison1");
		DrawPanelText(menu, text);
		Format(text, sizeof(text),"%t","InfPoison2");
		DrawPanelText(menu, text);
	}
	else if (StrEqual(item[param1],"InfBummerRain")) {
	//Format(text, sizeof(text),"%t","InfBummerRain1");
		DrawPanelText(menu, "Призывает авиаудары на всех выжившых.");
	}
	else if (StrEqual(item[param1],"InfAntiYell")) {
		Format(text, sizeof(text), "Вас не отбросит/подожгет при крике Живого");
		DrawPanelText(menu, text);
	}
	
	
	//DrawPanelText(menu, descr);
	
	//SetMenuExitBackButton(menu, true);
	
	SendPanelToClient(menu, param1,MenuHandler_ConfirmI, 30);
	CloseHandle(menu);
}	

public MenuHandler_ConfirmMelee(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildMeleeMenu(param1);
			}
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildMeleeMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "Недостаточно поинтов %d/%d", points[param1], cost[param1]);
				}
				else
				{
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
		
				}	
			}	
		}
	}
	
	
}	

public MenuHandler_ConfirmRifles(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildRiflesMenu(param1);
			}
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildRiflesMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "Недостаточно поинтов %d/%d", points[param1], cost[param1]);
				}
				else
				{
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
				}	
			}
		}
	}
	
}	

public MenuHandler_ConfirmSniper(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildSniperMenu(param1);
			}
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildSniperMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "Недостаточно поинтов %d/%d", points[param1], cost[param1]);
				}
				else
				{
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
				}	
			}
		}
	}
	
}	

public MenuHandler_ConfirmSMG(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildSMGMenu(param1);
			}
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildSMGMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "Недостаточно поинтов %d/%d", points[param1], cost[param1]);
				}
				else
				{
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
				}	
			}
		}
	}
	
}	

public MenuHandler_ConfirmShotguns(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildShotgunMenu(param1);
			}
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildShotgunMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "Недостаточно поинтов %d/%d", points[param1], cost[param1]);
				}
				else
				{
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
				}	
			}
		}
	}
	
}	

public MenuHandler_ConfirmThrow(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildThrowablesMenu(param1);
			}
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildThrowablesMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "Недостаточно поинтов %d/%d", points[param1], cost[param1]);
				}
				else
				{
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
				}	
			}
		}
	}
	
}	

public MenuHandler_ConfirmMisc(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildMiscMenu(param1);
			}
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildMiscMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "Недостаточно поинтов %d/%d", points[param1], cost[param1]);
				}
				else
				{
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
				}	
			}
		}
	}
	
}	

public MenuHandler_ConfirmHealth(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildBuyMenu(param1);
			}
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			//decl String:choice[40];
			//GetMenuItem(menu, param2, choice, sizeof(choice));
			//if (StrEqual(choice, "no", false))
			if (param2 == 2)
			{
				BuildBuyMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			//else if (StrEqual(choice, "yes", false))
			if (param2 == 1)
			{
				ActivateBuy(param1);
			}
		}
	}
	
}	

public MenuHandler_ConfirmUpgrades(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildUpgradesMenu(param1);
			}
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildUpgradesMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "Недостаточно поинтов %d/%d", points[param1], cost[param1]);
				}
				else if(StrEqual(item[param1], "give ammo", false))
				{
					new wep = GetPlayerWeaponSlot(param1, 0);
					if(wep == -1)
					{
						if(IsClientInGame(param1)) PrintToChat(param1, "[PS] You must have a primary weapon to refill ammo!");
						return;
					}	
					points[param1] -= cost[param1];
					new m60ammo = 150;
					new nadeammo = 30;
					new Handle:cvar = FindConVar("l4d2_guncontrol_m60ammo");
					new Handle:cvar2 = FindConVar("l4d2_guncontrol_grenadelauncherammo");
					if(cvar != INVALID_HANDLE)
					{
						m60ammo = GetConVarInt(cvar);
						CloseHandle(cvar);
					}	
					if(cvar2 != INVALID_HANDLE)
					{
						nadeammo = GetConVarInt(cvar2);
						CloseHandle(cvar2);
					}	
					new String:class[40];
					GetEdictClassname(wep, class, sizeof(class));
					RemoveFlags();
					if(StrEqual(class, "weapon_rifle_m60", false)) SetEntProp(wep, Prop_Data, "m_iClip1", m60ammo, 1);
					else if(StrEqual(class, "weapon_grenade_launcher", false))
					{
						new offset = FindDataMapOffs(param1, "m_iAmmo");
						SetEntData(param1, offset + 68, nadeammo);
					}	
					else FakeClientCommand(param1, item[param1]);
					AddFlags();
				}	
				else
				{
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
				}	
			}
		}
	}
	
}	

public MenuHandler_ConfirmI(Handle:menu, MenuAction:action, param1, param2)
{
	if (IsValidPlayer(param1)) ShowDistance[param1] = 0;
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			//decl String:choice[40];
			//GetMenuItem(menu, param2, choice, sizeof(choice));
			//if (StrEqual(choice, "no", false))
						
			if (param2 == 2)
			{
				BuildBuyMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			//else if (StrEqual(choice, "yes", false))
			else if (param2 == 1)
			{
				ActivateBuy(param1);
				
				return;
			}
		}
	}
	
}	

public Action:AllowBuyTimer(Handle:timer, any:client)
{
	AllowBuy[client] = true;
}

public Action:AllowHealthTimer(Handle:timer, any:client)
{
	AllowHealth = true;
}

public Action:Event_PlayerHurt_Pre(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return Plugin_Continue;
	if (IsEnd()) return Plugin_Continue;
	
	new iAtt=GetClientOfUserId(GetEventInt(event,"attacker"));
	new iVic=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iVic==0) return Plugin_Continue;
	new iType=GetEventInt(event,"type");
	new iEnt = GetEventInt(event,"attackerentid");
	new iDmgOrig=GetEventInt(event,"dmg_health");

	if ((IsNormalPlayer(iVic)) && (iAtt != iVic) && (SurvUntouchable > 0) && (GetClientTeam(iVic) == 2)) {
	
		decl String:class[32];
		
		if (IsNormalPlayer(iAtt)) {
			IgniteEntity(iAtt, 10.0, true);
		}
		else if (IsValidEntity(iEnt) && IsValidEdict(iEnt))
		{
			GetEdictClassname(iEnt, class,sizeof(class));
			if(StrEqual(class, "infected") || StrEqual(class, "witch"))
			IgniteEntity(iEnt, 5.0, true);
			AcceptEntityInput(iEnt, "Ignite");
		}	
	
	}

	//decl String:s_ModelName[64], s_Weapon[64], plusdamagetext[64];
           
    //GetEntPropString(iAtt, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName));
	//GetEventString(event, "weapon", s_Weapon, sizeof(s_Weapon));
	
	if (IsNormalPlayer(iVic))
	if (GetClientTeam(iVic) == 3) {
		if ((InfFireShield[iVic] == 1) && (IsPlayerBurning(iVic))) {
				//PrintToChat(iVic, "\x04Огненный Щит активирован.");
				ExtinguishEntity(iVic);
				//SetEventInt(event,"dmg_health", 0);
				//return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

InfToSurDamageAdd (any:iVic, any:iDmgAdd, any:iDmgOrig)
{
	if (iVic==0 || iDmgAdd<=0) return;

	new iHP=GetEntProp(iVic,Prop_Data,"m_iHealth");
	new health = GetClientHealth(iVic);
	
	if (iHP>iDmgAdd)
	{
		SetEntProp(iVic,Prop_Data,"m_iHealth", iHP-iDmgAdd );
		return;
	}
	else
	{
		new Float:flHPBuff=GetEntDataFloat(iVic,g_iHPBuffO);
		//PrintToChatAll("%s  flHPBuff = %d, iHP = %d, health = %d", GetName(iVic), flHPBuff, iHP, health);
		if (flHPBuff>0)
		{
			new iDmgCount=iHP-1;
			iDmgAdd-=iDmgCount;
			SetEntProp(iVic,Prop_Data,"m_iHealth", iHP-iDmgCount );
	
			new iHPBuff=RoundToFloor(flHPBuff);
			if (iHPBuff<iDmgAdd) iDmgAdd=iHPBuff;
			SetEntDataFloat(iVic,g_iHPBuffO, flHPBuff-iDmgAdd ,true);
			return;
		}
		else
		{
			if (iDmgOrig>=iHP) return;
			if (iDmgAdd>=iHP) iDmgAdd=iHP-1;
			if (iDmgAdd<0) return;
			SetEntProp(iVic,Prop_Data,"m_iHealth", iHP-iDmgAdd );
			return;
		}
	}
}

EfficientKiller_DamageAdd (iAtt,iVic,iTA,iType,String:stWpn[],iDmgOrig)
{
	new iDmgAdd = 7;
	InfToSurDamageAdd(iVic, iDmgAdd ,iDmgOrig);
	return 1;
	
}

//string:GetName(client)
//{
//	decl String:name[MAX_NAME_LENGTH];
//	Format(name,sizeof(name),"noname");
//	if (!IsValidPlayer(client)) return name;
//
//	GetClientName(client, name, MAX_NAME_LENGTH);
//	return name;
//}

public IsValidPlayer (client)
{
	if (client <= 0) return false;
	if (client > GetMaxClients()) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	if (!IsClientConnected(client))	return false;
	
	return true;
}

public Action:Event_lunge_pounce(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	
	new iVic=GetClientOfUserId(GetEventInt(event,"victim"));
	new iAtt=GetClientOfUserId(GetEventInt(event,"userid"));	
	
	if ((!IsNormalPlayer(iAtt)) || (!IsNormalPlayer(iVic))) return;
	if (IsEnd()) return;
	
	/*if (InfSpecialShield[iAtt] > 0) {
		if (GetEntProp(iAtt, Prop_Data, "m_takedamage") != 0) {
			SetEntProp(iAtt, Prop_Data, "m_takedamage", 0, 1);
			CreateTimer(5.0, RemoveSpecialShield, iAtt);
			PrintToChat(iAtt, "\04Активирован Щит на 5 секунд");
			EmitSoundToAll(SHIELDSOUND, iVic);
			ShowEffect(iAtt);
		}
	}
	
	if (SurvSpecialShield[iVic] > 0) {
		if (GetEntProp(iVic, Prop_Data, "m_takedamage") != 0) {
			SetEntProp(iVic, Prop_Data, "m_takedamage", 0, 1);
			CreateTimer(5.0, RemoveSurvSpecialShield, iVic);
			PrintToChat(iVic, "\x01Активирован \x03Специальный Щит \x01на \x04 5 \x01секунд");
			ShowEffect(iVic);
		}
	}
	*/
	
	IsPounced[iAtt] = 1;
	IsPounced[iVic] = 1;
	PounceTime[iAtt] = 0;
	PounceTime[iVic] = 0;
	CreateTimer(1.0, PounceTimer, iAtt);
	CreateTimer(1.0, PounceTimer, iVic);
}


public Action:Event_pounce_end(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
		
	new iVic=GetClientOfUserId(GetEventInt(event,"victim"));
	new iAtt=GetClientOfUserId(GetEventInt(event,"userid"));	

	
	/*if ((InfSpecialShield[iAtt] > 0) && (GetEntProp(iAtt, Prop_Data, "m_takedamage") != 2)) {
		SetEntProp(iAtt, Prop_Data, "m_takedamage", 2, 1);
		PrintToChat(iAtt,"\x04Щит деактивирован");
		//CreateTimer(1.0, timerEndEffect, iAtt);
	}
	
	if ((SurvSpecialShield[iVic] > 0) && (GetEntProp(iVic, Prop_Data, "m_takedamage") != 2)) {
		SetEntProp(iVic, Prop_Data, "m_takedamage", 2, 1);
		SurvSpecialShield[iVic] -= 1;		
		PrintToChat(iVic,"\x04Щит деактивирован, осталось %i", SurvSpecialShield[iVic]);
		//CreateTimer(1.0, timerEndEffect, iVic);
	}
	*/
	IsPounced[iAtt] = 0;
	IsPounced[iVic] = 0;
	
}

public Action:Event_jockey_ride(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	new iVic=GetClientOfUserId(GetEventInt(event,"victim"));
	new iAtt=GetClientOfUserId(GetEventInt(event,"userid"));	
	if ((!IsNormalPlayer(iAtt)) || (!IsNormalPlayer(iVic))) return;
	if (IsEnd()) return;
	
	/*if (InfSpecialShield[iAtt] > 0) {
		if (GetEntProp(iAtt, Prop_Data, "m_takedamage") != 0) {
			SetEntProp(iAtt, Prop_Data, "m_takedamage", 0, 1);
			CreateTimer(5.0, RemoveSpecialShield, iAtt);
			PrintToChat(iAtt, "\04Активирован Щит на 5 секунд");
			EmitSoundToAll(SHIELDSOUND, iVic);
			ShowEffect(iAtt);
		}
	}
	
	if (SurvSpecialShield[iVic] > 0) {
		if (GetEntProp(iVic, Prop_Data, "m_takedamage") != 0) {
			SetEntProp(iVic, Prop_Data, "m_takedamage", 0, 1);
			CreateTimer(5.0, RemoveSurvSpecialShield, iVic);
			PrintToChat(iVic, "\x01Активирован \x03Специальный Щит \x01на \x04 5 \x01секунд");
			ShowEffect(iVic);
		}
	}
	*/
	
	IsPounced[iAtt] = 1;
	IsPounced[iVic] = 1;
	PounceTime[iAtt] = 0;
	PounceTime[iVic] = 0;
	CreateTimer(1.0, PounceTimer, iAtt);
	CreateTimer(1.0, PounceTimer, iVic);
}


public Action:Event_jockey_ride_end(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	new iVic=GetClientOfUserId(GetEventInt(event,"victim"));
	new iAtt=GetClientOfUserId(GetEventInt(event,"userid"));	

	/*if ((InfSpecialShield[iAtt] > 0) && (GetEntProp(iAtt, Prop_Data, "m_takedamage") != 2)) {
		SetEntProp(iAtt, Prop_Data, "m_takedamage", 2, 1);
		PrintToChat(iAtt,"\x04Щит деактивирован");
		//CreateTimer(1.0, timerEndEffect, iAtt);
	}
	
	if ((SurvSpecialShield[iVic] > 0) && (GetEntProp(iVic, Prop_Data, "m_takedamage") != 2)) {
		SetEntProp(iVic, Prop_Data, "m_takedamage", 2, 1);
		SurvSpecialShield[iVic] -= 1;
		PrintToChat(iVic,"\x04Щит деактивирован, осталось %i", SurvSpecialShield[iVic]);
		//CreateTimer(1.0, timerEndEffect, iVic);
	}
	*/

	IsPounced[iAtt] = 0;
	IsPounced[iVic] = 0;

}

public Action:Event_tongue_grab(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
		
	new iVic=GetClientOfUserId(GetEventInt(event,"victim"));
	new iAtt=GetClientOfUserId(GetEventInt(event,"userid"));	
	
	if ((!IsNormalPlayer(iAtt)) || (!IsNormalPlayer(iVic))) return;
	if (IsEnd()) return;
	
	/*if (InfSpecialShield[iAtt] > 0) {
		if (GetEntProp(iAtt, Prop_Data, "m_takedamage") != 0) {
			SetEntProp(iAtt, Prop_Data, "m_takedamage", 0, 1);
			CreateTimer(5.0, RemoveSpecialShield, iAtt);
			PrintToChat(iAtt, "\x01Активирован \x04Специальный Щит \x01на \x05 5 \x01секунд");
			EmitSoundToAll(SHIELDSOUND, iVic);
			ShowEffect(iAtt);
		}
	}
	
	if (SurvSpecialShield[iVic] > 0) {
		if (GetEntProp(iVic, Prop_Data, "m_takedamage") != 0) {
			SetEntProp(iVic, Prop_Data, "m_takedamage", 0, 1);
			CreateTimer(5.0, RemoveSurvSpecialShield, iVic);
			PrintToChat(iVic, "\x01Активирован \x04Специальный Щит \x01на \x03 5 \x01секунд");
			ShowEffect(iVic);
		}
	}
	*/

	IsPounced[iAtt] = 1;
	IsPounced[iVic] = 1;
	PounceTime[iAtt] = 0;
	PounceTime[iVic] = 0;
	
	new Float:smoke_speed = 0.2;
	smoke_speed = GetConVarFloat(FindConVar("l4d_perkmod_smokeit_speed"));
	
	SetEntDataFloat(iAtt, g_flLagMovement, smoke_speed, true);
	
	CreateTimer(1.0, PounceTimer, iAtt);
	CreateTimer(1.0, PounceTimer, iVic);
}


public Action:Event_tongue_release(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	
	new iVic=GetClientOfUserId(GetEventInt(event,"victim"));
	new iAtt=GetClientOfUserId(GetEventInt(event,"userid"));	

	/*if ((InfSpecialShield[iAtt] > 0) && (GetEntProp(iAtt, Prop_Data, "m_takedamage") != 2)) {
		SetEntProp(iAtt, Prop_Data, "m_takedamage", 2, 1);
		PrintToChat(iAtt,"\x04Щит деактивирован");
		//CreateTimer(1.0, timerEndEffect, iAtt);
	}
	
	if ((SurvSpecialShield[iVic] > 0) && (GetEntProp(iAtt, Prop_Data, "m_takedamage") != 2)) {
		SetEntProp(iVic, Prop_Data, "m_takedamage", 2, 1);
		SurvSpecialShield[iVic] -= 1;
		PrintToChat(iVic,"\x04Щит деактивирован, осталось %i", SurvSpecialShield[iVic]);
		//CreateTimer(1.0, timerEndEffect, iVic);
	}
	*/
	IsPounced[iAtt] = 0;
	IsPounced[iVic] = 0;
}

public Action:Event_charger_pummel_start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	new iVic=GetClientOfUserId(GetEventInt(event,"victim"));
	new iAtt=GetClientOfUserId(GetEventInt(event,"userid"));	
	
	if ((!IsNormalPlayer(iAtt)) || (!IsNormalPlayer(iVic))) return;
	if (IsEnd()) return;
	
	/*if (InfSpecialShield[iAtt] > 0) {
		if (GetEntProp(iAtt, Prop_Data, "m_takedamage") != 0) {
			SetEntProp(iAtt, Prop_Data, "m_takedamage", 0, 1);
			CreateTimer(5.0, RemoveSpecialShield, iAtt);
			PrintToChat(iAtt, "\x01Активирован \x04Специальный Щит \x01на \x03 5 \x01секунд");
			EmitSoundToAll(SHIELDSOUND, iVic);
			ShowEffect(iAtt);
		}
	}
	
	if (SurvSpecialShield[iVic] > 0) {
		if (GetEntProp(iVic, Prop_Data, "m_takedamage") != 0) {
			SetEntProp(iVic, Prop_Data, "m_takedamage", 0, 1);
			CreateTimer(5.0, RemoveSurvSpecialShield, iVic);
			PrintToChat(iVic, "\x01Активирован \x04Специальный Щит \x01на \x03 5 \x01секунд");
			ShowEffect(iVic);
		}
	}
	*/
	
	IsPounced[iAtt] = 1;
	IsPounced[iVic] = 1;
	PounceTime[iAtt] = 0;
	PounceTime[iVic] = 0;
	CreateTimer(1.0, PounceTimer, iAtt);
	CreateTimer(1.0, PounceTimer, iVic);
}


public Action:Event_charger_pummel_end(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	new iVic=GetClientOfUserId(GetEventInt(event,"victim"));
	new iAtt=GetClientOfUserId(GetEventInt(event,"userid"));	

	/*if ((InfSpecialShield[iAtt] > 0) && (GetEntProp(iAtt, Prop_Data, "m_takedamage") != 2)) {
		SetEntProp(iAtt, Prop_Data, "m_takedamage", 2, 1);
		PrintToChat(iAtt,"\x04Щит деактивирован");
		//CreateTimer(1.0, timerEndEffect, iAtt);
	}
	
	if ((SurvSpecialShield[iVic] > 0) && (GetEntProp(iAtt, Prop_Data, "m_takedamage") != 2)) {
		SetEntProp(iVic, Prop_Data, "m_takedamage", 2, 1);
		SurvSpecialShield[iVic] -= 1;
		PrintToChat(iVic,"\x04Щит деактивирован, осталось %i", SurvSpecialShield[iVic]);
		//CreateTimer(1.0, timerEndEffect, iVic);
	}
	*/
	IsPounced[iAtt] = 0;
	IsPounced[iVic] = 0;
}



public Action:RemoveSpecialShield(Handle:timer, any:client)
{
	if (IsEnd()) return;
	if ((IsNormalPlayer(client)) && (InfSpecialShield[client] > 0) && (GetEntProp(client, Prop_Data, "m_takedamage") != 2)) {
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		PrintToChat(client,"\x04Щит деактивирован");
		//CreateTimer(1.0, timerEndEffect, client);
	}
}

public Action:RemoveIncSpecialShield(Handle:timer, any:client)
{
	if (IsEnd()) return;
	if ((IsNormalPlayer(client)) && (SurvIncSpecialShield[client] > 0) && (GetEntProp(client, Prop_Data, "m_takedamage") != 2)) {
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		SurvIncSpecialShield[client] -= 1;
		PrintToChat(client,"\x04Щит деактивирован, осталось %i", SurvIncSpecialShield[client]);
		//CreateTimer(1.0, timerEndEffect, client);
	}
}

bool:IsPlayerSpawnGhost(client)
{
	if (!IsNormalPlayer(client)) return false;
	if(GetEntData(client, propinfoghost, 1)) return true;
	else return false;
}

public Action:ApplyAcidDamage(Handle:timer, any:client)
{
	if (IsEnd()) return;
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsNormalPlayer(i)) {
			new Health, FinalHealth;
			if ((GetClientTeam(i) == 3) && (InfRegen[i] == 1) && (!IsPlayerSpawnGhost(i)) && (IsPlayerAlive(i))) {
				Health = GetClientHealth(i);
				if ((InfHulk[i] == 1) || (TankChaos[i] == 1)) FinalHealth = Health + 10;
				else FinalHealth = Health + 40;
				if (FinalHealth < OriginHealth[i]) SetEntityHealth(i, FinalHealth);
			}
			
			if ((GetClientTeam(i) == 2) && (AcidDamage[i] > 0) && (!IsPlayerIncapped(i))) {
				Health = GetClientHealth(i);
				FinalHealth = Health - 3;
				if (FinalHealth > 0) {
					SetEntityHealth(i, FinalHealth);
					//DoAcidDamage(i,1);
					AcidDamage[i] -= 3;
					
					//PrintToChat(i, "\x03-1 HP \x01Кислотой + эффект замедления \x05%s", GetName(i));
					if (IsValidPlayer(i)) {
						PrintCenterText(i, "-1 HP Кислотой + эффект замедления");
						
						OriginSpeed[i] = GetEntDataFloat(i,g_flLagMovement);
						SetEntDataFloat(i, g_flLagMovement, FloatSub(OriginSpeed[i], 0.3), true);
						CreateTimer(2.0, ResetSlowDown, i);
					}
					
					if ( ( GetRandomInt(0, 2) == 0 ) && (IsValidPlayer(i)) )
					{
						new particle = CreateEntityByName("info_particle_system");
						if( GetRandomInt(0, 1) == 0 )
						DispatchKeyValue(particle, "effect_name", PARTICLE_SPIT_PROJ1);
						else
						DispatchKeyValue(particle, "effect_name", PARTICLE_SPIT_PROJ2);
						
						DispatchSpawn(particle);
						ActivateEntity(particle);
						AcceptEntityInput(particle, "Start");
						
						SetVariantString("!activator"); 
						AcceptEntityInput(particle, "SetParent", i);
						SetVariantString("forward");
						AcceptEntityInput(particle, "SetParentAttachment");
					}
				}
				else {
					SetEntityHealth(i, 1);
					AcidDamage[i] = 0;
				}
			}
		}
	}
}

GetFirstInfected()
{
	for (new i = 1; i <= GetMaxClients(); i++) 
		if (IsNormalPlayer(i) && (GetClientTeam(i) == 3)) return i;
}

stock bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

public event_PlayerIncap2(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (RoundEnd > 0) return;
	
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	AcidDamage[Victim] = 0;
	
	/*if (SurvIncSpecialShield[Victim] > 0)
	if (GetEntProp(Victim, Prop_Data, "m_takedamage") != 0) {
		SetEntProp(Victim, Prop_Data, "m_takedamage", 0, 1);
		CreateTimer(30.0, RemoveIncSpecialShield, Victim);
		PrintToChat(Victim, "\04Активирован Щит на 30 секунд");
	}
	*/
	
	IsInc[Victim] = 1;
	IncTime[Victim] = 0;
	CreateTimer(1.0, IncTimer, Victim);
	
}

String:GetName(client)
{
	decl String:name[MAX_NAME_LENGTH] = "noname";
	if (IsNormalPlayer(client)) 
		GetClientName(client, name, MAX_NAME_LENGTH);

	return name;
}

public IsNormalPlayer(client)
{
	if (client <= 0)
		return false;
		
	if (client > GetMaxClients())	
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	return true;
}

public DoAcidDamage(damage, victim, attacker)
{
	decl Float:victimPos[3], String:strDamage[16], String:strDamageTarget[16];
	
	if (!IsClientInGame(victim)) return;
	GetClientEyePosition(victim, victimPos);
	IntToString(damage, strDamage, sizeof(strDamage));
	Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
	
	new entPointHurt = CreateEntityByName("point_hurt");
	if(!entPointHurt) return;
	
	new bool:reviveblock = true;

	// Config, create point_hurt
	DispatchKeyValue(victim, "targetname", strDamageTarget);
	DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
	DispatchKeyValue(entPointHurt, "Damage", strDamage);
	DispatchKeyValue(entPointHurt, "DamageType", reviveblock ? "65536" : "263168");
	DispatchSpawn(entPointHurt);
	
	// Teleport, activate point_hurt
	TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entPointHurt, "Hurt", (attacker > 0 && attacker < MaxClients && IsClientInGame(attacker)) ? attacker : -1);
	
	// Config, delete point_hurt
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	//RemoveEdict(entPointHurt);
	AcceptEntityInput(entPointHurt, "Kill");
}

public Action:ResetSlowDown(Handle:timer, any:client)
{
	if ((IsEnd()) || (!IsValidPlayer(client))) return;
	SetEntDataFloat(client, g_flLagMovement, 1.0, true);
}

bool:IsPlayerBurning(client)
{
	if (!IsNormalPlayer(client)) return false;
	new Float:isburning = GetEntDataFloat(client, propinfoburn);
	if (isburning>0) return true;
	else return false;
}




public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{

	if (IsEnd()) return Plugin_Continue;
	
	if ( !IsNormalPlayer(victim) || !IsPlayerAlive(victim) ) return Plugin_Continue;
		
	decl String:name[64];
	decl String:dtype[64];
	if (!IsValidEdict(inflictor)) return Plugin_Continue;
	GetEdictClassname(inflictor, name, sizeof(name));
				
	if (IsValidEdict(damagetype)) GetEdictClassname(damagetype, dtype, sizeof(dtype));

	decl String:SDamage[255];
	new Float: FDamage, WasDamage;
		 
	if ( (IsInc[victim] == 1) && (IncTime[victim] <= 20) && (SurvIncSpecialShield[victim] > 0) )	{
		PrintHintText(victim, "Щит2 активирован, урон %2.0f заблокирован", damage);
		//damage = FloatMul(damage,0.05);
		AnimateBlock(victim, 255, 0, 130);
		damage = 0.0;
		
		return Plugin_Changed;
	}
	
	new VictimTeam, AttackerTeam;
	VictimTeam = GetClientTeam(victim);
	if ( (VictimTeam < 2) || (VictimTeam > 3) ) return Plugin_Continue;
	
	if ( (IsPounced[victim] == 1) && (PounceTime[victim] <= 5) 
	&& (((VictimTeam == 2) && (SurvSpecialShield[victim] > 0)) || ((VictimTeam == 3) && (InfSpecialShield[victim] > 0))) )	{
		new Float:wasdamage = damage;
		if (VictimTeam == 2) {
			damage = FloatMul(damage,0.2);
			AnimateBlock(victim, 255, 0, 130);
			PrintHintText(victim, "Щит активирован, урон %2.0f из %2.0f заблокирован", FloatSub(wasdamage, damage), wasdamage);
		}
		else {
			AnimateBlock(victim, 255, 0, 130);
			damage = 0.0;
			PrintHintText(victim, "Щит активирован, урон %2.0f заблокирован", wasdamage);
		}	
		
		return Plugin_Changed;
	}

	
	if 	(InfPoison == victim) {
		WasDamage = damage;
		FDamage = FloatMul(damage,0.2);
		damage = FDamage;
		
		return Plugin_Changed;
	}
		
	new bool:ivTank;
	if (IsTank(victim)) ivTank = true;	else ivTank = false;
		
	new wep;
	new String:class[40];
	decl String:wep_name[40];
	Format(class, sizeof(class), "");
	
	
	// if valid attacker
	if ( (IsNormalPlayer(attacker)) && (IsPlayerAlive(attacker)) ) { 
	
	AttackerTeam = GetClientTeam(attacker);
	if ( (AttackerTeam < 2) || (AttackerTeam > 3) ) return Plugin_Continue;
			
	wep = GetPlayerWeaponSlot(attacker, 0);
	if (IsValidEdict(wep)) GetEdictClassname(wep, class, sizeof(class));
	GetClientWeapon(attacker, wep_name, sizeof(wep_name));
		
	new Float: plusdamage = 0.0;
	
		decl String:Difficulty[MAX_LINE_WIDTH];
		GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));
		
		/*
		if ( (IsValidPlayer(attacker)) && (IsNormalPlayer(victim)) && (GetClientTeam(victim) == 3) ) {
			
			new bid = GetBizonID();
						
			decl Float:pos[3], Float:tpos[3];
			new Float:distance;
			GetEntPropVector(inflictor, Prop_Send, "m_vecOrigin", pos);
			GetClientAbsOrigin(victim, tpos);
			distance = GetVectorDistance(pos, tpos);
			LogToFile(logfilepath, "victim_name: %s HP: %i damage: %2.2f inflictor_name: %s wep_name: %s difficulty: %s", GetName(victim), GetClientHealth(victim), damage, name, wep_name, Difficulty);
			LogToFile(logfilepath, "inflictor_pos: x: %2.2f y: %2.2f z: %2.2f", pos[0], pos[1], pos[2]);
			LogToFile(logfilepath, "victim_pos: x: %2.2f y: %2.2f z: %2.2f", tpos[0], tpos[1], tpos[2]); 
			LogToFile(logfilepath, "distance: %2.2f damage_type: %s", distance, dtype);	
			
			if ( (bid > 0) && (bid = attacker) ) {
			
			new ual = GetEntProp(wep, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
			PrintToChat(bid, "wep_name: %s  distance: %2.2f  damage_type: %s (%2.2f) ual: %i", wep_name, distance, dtype, damagetype, ual);
			}
			
			
		} */
			
			
		if ( (IsNormalPlayer(victim)) && (IsNormalPlayer(attacker)) && (GetClientTeam(victim) == 2) && (GetClientTeam(attacker) == 2)
		&& (StrContains(name, "grenade_launcher_projectile", false) != -1) && (StrContains(wep_name, "grenade_launcher", false) != -1) ) {
			
			new bid = 0;
			//if (ShowTankDamage) {
				//decl Float:pos[3], Float:tpos[3];
				//new Float:distance;
				//GetClientAbsOrigin(inflictor, pos);
				//GetEntPropVector(inflictor, Prop_Send, "m_vecOrigin", pos);
				//GetClientAbsOrigin(victim, tpos);
				//distance = GetVectorDistance(pos, tpos);
				//if ((FloatCompare(distance, flMaxDistance) == -1)
				
				//bid = GetBizonID();			
				//if (IsValidPlayer(bid)) {
//					PrintToChat(bid, "name: %s HP: %i damage: %2.2f inflictor_name: %s wep_name: %s difficulty: %s", GetName(victim), GetClientHealth(victim), damage, name, wep_name, Difficulty);
					//PrintToChat(bid, "distance: %2.2f x: %2.2f y: %2.2f z: %2.2f", distance, pos[0], pos[1], pos[2]);
//					
				//}
				
			//}		
			/*
			new Float: gl_radius = GetConVarFloat(FindConVar("grenadelauncher_radius_kill"));
			if (FloatCompare(100.0, gl_radius) == 1) gl_radius  = 100.0;
			new Float: gl_dmg = 0.0;
			if (FloatCompare(gl_radius, distance) == 1) {
				
				gl_dmg = FloatMul(FloatSub(1.0, FloatDiv(distance, gl_radius)), 5.0);
											
				if (StrEqual(Difficulty, "Easy", false)) damage = gl_dmg;
				if (FloatCompare(damage, 0.0) == 1) 
					PrintToChatAll("\x05%s \x01нанес урон(%2.2f) \x03гранатометом \x01по \x04%s", GetName(attacker), damage, GetName(victim));
			}
			
				LogToFile(logfilepath, "victim_name: %s HP: %i damage: %2.2f inflictor_name: %s wep_name: %s difficulty: %s", GetName(victim), GetClientHealth(victim), damage, name, wep_name, Difficulty);
				LogToFile(logfilepath, "gl_radius: %2.2f gl_dmg: %2.2f", gl_radius, gl_dmg);			
				LogToFile(logfilepath, "inflictor_pos: x: %2.2f y: %2.2f z: %2.2f", pos[0], pos[1], pos[2]);
				LogToFile(logfilepath, "victim_pos: x: %2.2f y: %2.2f z: %2.2f", tpos[0], tpos[1], tpos[2]); 
				LogToFile(logfilepath, "distance: %2.2f", distance);	
			*/
			
		}
	
	if ((ivTank) && (FloatCompare(damage,500.0) == 1))	damage = 500.0;
	
	
		if (AttackerTeam == 3) {
			if ((InfAcidClaws[attacker] == 1) && (StrContains(class, "claw", false) != -1)) {
				if ((VictimTeam == 2) && (!IsPlayerIncapped(victim))) {
					if (AcidDamage[victim] < 30) AcidDamage[victim] += 3;
					PrintToChat(attacker,"\x04+3 \x05Урон кислотой \x03%s", GetName(victim));
				}
			}
			if (InfBonusDamage[attacker] == 1) {
				if (StrContains(class, "claw", false) != -1) {
					
					if (IsTank(attacker)) plusdamage = 5.0;
					else if (StrContains(name, "insect_swarm", false) != -1) plusdamage = 1.0;
					else plusdamage = 7.0;
					new bid = GetBizonID();
					if ((bid > 0) && (bid == attacker)) PrintToChat(attacker, "\x04Добавлен урон(%s): \x03%2.0f \x01(%2.0f +%2.0f)", name, FloatAdd(damage, plusdamage), damage, plusdamage);
					else
					PrintToChat(attacker, "\x04Добавлен урон: \x03%2.0f \x01(%2.0f +%2.0f)", FloatAdd(damage, plusdamage), damage, plusdamage);
					damage = FloatAdd(damage, plusdamage);
					
					TeslaShock(attacker, victim);
						
				}
			}
		}
	
	
	if ( (StrContains(name, "player", false) != -1) && (!ivTank) ) {
		if (VictimTeam == 2) {
			//надо подумать
		}
		else {
						
			if (CurrentGamemodeID == 0) {
				if (StrContains(wep_name, "sniper_awp", false) != -1) damage = 500.0;
				if (StrContains(wep_name, "sniper_scout", false) != -1) damage = 300.0;
				if (StrContains(wep_name, "m60", false) != -1) damage = FloatAdd(damage, 20.0);
			
			}
			else {
				if (StrContains(wep_name, "sniper_awp", false) != -1) damage = 325.0;
				if (StrContains(wep_name, "sniper_scout", false) != -1) damage = 200.0;
				if (StrContains(wep_name, "m60", false) != -1) damage = FloatAdd(damage, 20.0);
				
			}
			if ( (SurvFirearmsMaster[attacker] > 0) && (StrContains(wep_name, "melee", false) == -1) ) damage = FloatAdd(damage, damage);
			
			if (AttackerTeam == 2) {
				if ( ( (StrContains(wep_name, "rifle", false) != -1) || (StrContains(wep_name, "grenade", false) != -1) || (StrContains(wep_name, "sniper", false) != -1) ) )
				{
					new ual = GetEntProp(wep, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
					new Float: WasDmg = damage;
					if (ual > 0) {
						if ( (VipStatus[attacker] < 4) && (LastUpgrade[attacker] == 2) ) {
							damage = FloatDiv(damage, 2.0);
							if (FloatCompare(damage, 150.0) == 1) damage = 150.0;
						}
						else if (LastUpgrade[attacker] == 1) damage = FloatMul(damage, 1.2);
					
						//new bid = GetBizonID();
						//if ( (bid > 0) && (attacker == bid) ) 
						//PrintToChat(bid, "wep_name: %s damage: %2.2f wasdmg: %2.2f ual: %i", wep_name, damage, WasDmg, ual);
					}
				}
			}
	
		}
	}
	
		if (StrContains(name, "weapon_melee", false) != -1) {		
			
			if ( (InfMeeleShield[victim] > 0) && (VictimTeam == 3) ) {
				if (ivTank) {
					if (SurvMeleeMaster[attacker] > 0) damage = FloatMul(damage, 0.4);
					else damage = FloatMul(damage, 0.2);
				}
				else {
					if (SurvMeleeMaster[attacker] > 0) FloatMul(damage, 0.2);
					else damage = 0.0;
				}
				AnimateBlock(victim, 255, 0, 130);
				PrintHintText(victim, "%t: %2.0f", "Meleeshield1", damage);
			}
		}	
	
	
	
	if (ivTank) {
				
		if (StrContains(name, "point_hurt", false) != -1) {
			
		} 
				
		if (StrContains(name, "player", false) != -1) {
			if (StrContains(wep_name, "sniper_awp", false) != -1) 
				damage = 250.0;
			else if (StrContains(wep_name, "sniper_scout", false) != -1)
				damage = 200.0;			
			else if (FloatCompare(damage, 80.0) == 1)
				damage = 80.0;	
		}
		
		if ( ((StrEqual(name, "entityflame")) || (StrEqual(name, "inferno"))) && (CurrentGamemodeID != 0) ) {
			//damage = 10.0;
			new hp = GetClientHealth(victim);
			if (hp > 3) SetEntityHealth(victim, hp - 3);
		}
				
		if (InfMassArmor > 0) {
			damage = FloatMul(damage, InfMassArmor_Mult);
			AnimateBlock(victim, 220, 220, 95);
		}
		
		//decl String:query[255];		
		decl String:hostname[255];
		GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));		
		//Format(query, sizeof(query), "INSERT INTO tank_log (tank_name, attacker_name, tank_health, damage, inflictor_name, damage_type, weapon_name, status, hostname, class) values ('%s', '%s', %i, %2.0f, '%s', '%s', '%s', 2, '%s', '%s')", GetName(victim), GetName(attacker), GetClientHealth(victim), damage, SafeString(name), SafeString(damagetype), SafeString(wep_name), SafeString(hostname), SafeString(class));
		//SQL_TQuery(db, SQLErrorCheckCallback, query);
		
		//LogToFile(logfilepath_tank, "tank_name: %s attacker_name: %s tank_health: %i damage: %2.0f inflictor_name: %s damage_type: %s weapon_name: %s class: %s hostname: %s", GetName(victim), GetName(attacker), GetClientHealth(victim), damage, name, damagetype, wep_name, class, hostname);
		
		return Plugin_Changed;
	}
	
	} // valid attacker end
			
	//new bid = GetBizonID();
	
	if ( (InfMassArmor > 0) && (VictimTeam == 3) ) {
		damage = FloatMul(damage, InfMassArmor_Mult);
		AnimateBlock(victim, 220, 220, 95);
	}
		
	if ( ((SurvPhysPower > 0) || (victim == VictimID)) && (VictimTeam == 2) ) {
				
		WasDamage = damage;
		FDamage = FloatMul(damage,0.5);
		//FloatToString(FDamage, SDamage, sizeof(SDamage));
		//damage = StringToInt(SDamage);
		damage = FDamage;
		//if (bid > 0) PrintToChat(bid, "урон жертве: %2.2f итоговый: %2.2f", WasDamage, FDamage);
	}
	
	if ( (AttackerTeam != 2) && (VictimTeam == 2) && (victim == VictimID) && (CurrentGamemodeID != 1) ) {
		InfGlobalDamage = FloatAdd(InfGlobalDamage, damage);
		PrintHintTextToAll("%t(%s): %2.0f (%2.0f / %2.0f)", "hintdamage3", GetName(VictimID), damage, InfGlobalDamage, InfGlobalActivateDamage);
	}
	
	
	if ((VictimTeam == 3) && (InfFireShield[victim] > 0) && ((StrEqual(name, "entityflame")) || (StrEqual(name, "inferno")))) {
		AnimateBlock(victim, 255, 0, 130);
		damage = 0.0;
	}

			
	return Plugin_Changed;
}

public ResetInfAbilities()
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		ResetClientInfAbilites(i);
	}
}

public ResetSurvAbilities()
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		ResetClientSurvAbilites(i);
	}
}

public Action:event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundEndProc();
}


public RoundEndProc()
{
	RoundEnd++;
	CampaignOver = true;
	
	if (RoundEnd == 1) {
		
		PrintToChatAll("RoundEnd");
		RoundStarted = false;
			
		if (MapEnd == 0) {
			for (new i=1; i<=MaxClients; i++)
			{
				points[i] = GetConVarInt(StartPoints);
				hurtcount[i] = 0;
				protectcount[i] = 0;
				headshotcount[i] = 0;
				killcount[i] = 0;
				wassmoker[i] = 0;
				iHurt[i] = 0;
			}    
		}
		
		InfPoison = 0;
		
		tanksspawned = 0;
		witchsspawned = 0;
		
		ResetInfAbilities();
		ResetSurvAbilities();
		ResetMassAbilites();
		SurvAWP = 0;
		SurvM60 = 0;
		SurvGL = 0;
		
		//kill apocalyps
		new common = -1;
		decl String:sTemp[64];
		while( (common = FindEntityByClassname(common, "infected")) != INVALID_ENT_REFERENCE ) {
			if (IsValidEntity(common)) {
				GetEntPropString(common, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));
		
				if( strcmp(sTemp, "models/infected/common_male_ceda.mdl") == 0 || strcmp(sTemp, "models/infected/common_male_clown.mdl") == 0 ||
				strcmp(sTemp, "models/infected/common_male_fallen_survivor.mdl") == 0 || strcmp(sTemp, "models/infected/common_male_jimmy.mdl") == 0 ||
				strcmp(sTemp, "models/infected/common_male_mud.mdl") == 0 || strcmp(sTemp, "models/infected/common_male_riot.mdl") == 0 ||
				strcmp(sTemp, "models/infected/common_male_roadcrew.mdl") == 0 )
				{
					AcceptEntityInput(common, "Kill");
				}
				
			}
		}	
		////////
		
		/*ResetAllShields();
			
			for (new i = 1; i <= GetMaxClients(); i++) {		
			if ((IsNormalPlayer(i)) && (GetClientTeam(i) != 1)) {
			SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			}
		}*/
		
		if (Timer1 != INVALID_HANDLE) {
			KillTimer(Timer1);
			Timer1 = INVALID_HANDLE;
		}
		if (Timer2 != INVALID_HANDLE) {
			KillTimer(Timer2);
			Timer2 = INVALID_HANDLE;
		}
		if (Timer3 != INVALID_HANDLE) {
			KillTimer(Timer3);
			Timer3 = INVALID_HANDLE;
		}
		if (Timer4 != INVALID_HANDLE) {
			KillTimer(Timer4);
			Timer4 = INVALID_HANDLE;
		}
		if (Timer5 != INVALID_HANDLE) {
			KillTimer(Timer5);
			Timer5 = INVALID_HANDLE;
		}
		if (Timer6 != INVALID_HANDLE) {
			KillTimer(Timer6);
			Timer6 = INVALID_HANDLE;
		}
		if (Timer7 != INVALID_HANDLE) {
			KillTimer(Timer7);
			Timer7 = INVALID_HANDLE;
		}
		if (Timer8  != INVALID_HANDLE) {
			KillTimer(Timer8);
			Timer8 = INVALID_HANDLE;
		}
		if (Timer9  != INVALID_HANDLE) {
			KillTimer(Timer9);
			Timer9 = INVALID_HANDLE;
		}
		
		if (Timer25  != INVALID_HANDLE) {
			KillTimer(Timer25);
			Timer25 = INVALID_HANDLE;
		}
		
		if (Timer20  != INVALID_HANDLE) {
			KillTimer(Timer20);
			Timer20 = INVALID_HANDLE;
		}
		if (Timer21	!= INVALID_HANDLE) {
			KillTimer(Timer21);
			Timer21 = INVALID_HANDLE;
		}
		if (Timer22  != INVALID_HANDLE) {
			KillTimer(Timer22);
			Timer22 = INVALID_HANDLE;
		}
		if (Timer23  != INVALID_HANDLE) {
			KillTimer(Timer23);
			Timer23 = INVALID_HANDLE;
		}
		if (Timer24  != INVALID_HANDLE) {
			KillTimer(Timer24);
			Timer24 = INVALID_HANDLE;
		}
		
		if (HulkResetTimer != INVALID_HANDLE) {
			KillTimer(HulkResetTimer);
			HulkResetTimer = INVALID_HANDLE;
		}
		
	}
}

public ResetClientInfAbilites(any:client)
{
    InfSpeedUp[client] = 0;
	InfBonusDamage[client] = 0;
	InfSpecialShield[client] = 0;
	InfBonusHealth[client] = 0;
	InfAcidClaws[client] = 0;
	InfFireShield[client] = 0;
	InfMask[client] = 0;
	InfMeeleShield[client] = 0;
	InfRegen[client] = 0;
	InfHulk[client] = 0;
	InfHobbits[client] = 0;	
	InfAntiYell[client] = 0;
}

public ResetClientSurvAbilites(any:client)
{
	SurvUpgradeExplosive[client] = 0;
	SurvUpgradeIncendiary[client] = 0;
	SurvFirearmsMaster[client] = 0;
	SurvSpeedUp[client] = 0;
	SurvSpecialShield[client] = 0;
	SurvVampire[client] = 0;
	SurvShoving[client] = 0;
	SurvLaser[client] = 0;
	SurvMeleeMaster[client] = 0;
	SurvRevenge[client] = 0;
	SurvYell[client] = 0;
	SurvHealthConvert[client] = 0;
	SurvIncSpecialShield[client] = 0;
	SurvGift[client] = 0;
	SurvBerserker[client] = 0;
	AcidDamage[client] = 0;
}

public Action:event_PlayerTeam2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new NewTeam = GetEventInt(event, "team");
	new OldTeam = GetEventInt(event, "oldteam");
	new bool:IsDisconnect = GetEventBool(event, "disconnect");
	
	if (OldTeam == 0) return Plugin_Continue;
	
	ResetClientInfAbilites(client);
	ResetClientSurvAbilites(client);
	
	killshield(client);

}

public MenuHandler_Survivors(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Select:
		{
			if (!IsValidPlayer(param1)) return;
			
			new String:item1[192];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			
			if(StrEqual(item1, "BuildBuyMenu2", false))
			{
				BuildBuyMenu2(param1);
				return;
			}
			else if(StrEqual(item1, "BuildBuyMenu3", false))
			{
				BuildBuyMenu3(param1);
				return;
			}
			else if(StrEqual(item1, "BuildBuyMenu4", false))
			{
				BuildBuyMenu4(param1);
				return;
			}
			else if(StrEqual(item1, "BuildBuyMenu5", false))
			{
				//if ((StrEqual(GetName(param1),"Woonan")) || StrEqual(GetName(param1),"ARMAGEDDON")) BuildBuyMenu5(param1);
				//else PrintToChat(param1, "пока не работает, в процессе разработки");
				BuildBuyMenu5(param1);
				return;
			}
			else if(StrEqual(item1, "SurvSendPoints", false))
			{
				SetBuyParams(param1, item1);
				return;
			}
			else SetBuyParams(param1, item1);
		
			DisplayConfirmMenuHealth(param1);
		}
	}
	
}

/*
public Action:ResetSpeedUp(Handle:Timer, any:client)
{
    if (!IsValidPlayer(client)) return;
	if (SurvSpeedUp[client] <= 0) return;
	SurvSpeedUp[client] -= 1;
	SetEntDataFloat(client, g_flLagMovement, 1.0, true);
	PrintToChat(client, "\x05Эффект ускорения прошел.");
	
	Timer20 = INVALID_HANDLE;
}
*/

public Action:UpdateSpeedUp(Handle:Timer, any:client)
{
    if (!IsNormalPlayer(client)) return;
	if (SurvSpeedUp[client] > 0) {
		if (InfPoison == client) SetEntDataFloat(client, g_flLagMovement, 0.3, true);
		else SetEntDataFloat(client, g_flLagMovement, 1.4, true);
		CreateTimer(0.5, UpdateSpeedUp, client);
	}
}

public Action:UpdateInfSpeedUp(Handle:Timer, any:client)
{
    if (!IsNormalPlayer(client)) return;
	
	if (IsTank(client) && (InfHulk[client] == 1)) {
		SetEntDataFloat(client, g_flLagMovement, HulkSpeedUP, true);
		CreateTimer(0.5, UpdateInfSpeedUp, client);
	}
	else if (InfSpeedUp[client] > 0) {
		SetEntDataFloat(client, g_flLagMovement, 1.5, true);
		CreateTimer(0.5, UpdateInfSpeedUp, client);
	}
	
}

public Action:RemoveSurvSpecialShield(Handle:timer, any:client)
{
	if ((SurvSpecialShield[client] > 0) && (GetEntProp(client, Prop_Data, "m_takedamage") != 2)) {
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		SurvSpecialShield[client] -= 1;
		PrintToChat(client,"\x04Щит деактивирован, осталось \x03%i", SurvSpecialShield[client]);
		//CreateTimer(1.0, timerEndEffect, client);
	}
}

public Action:CheckSurvSpecialShield(Handle:timer, any:client)
{
	if (!IsPlayerIncapped(client)) {
		if ((SurvIncSpecialShield[client] > 0) && (GetEntProp(client, Prop_Data, "m_takedamage") != 2)) {
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			SurvSpecialShield[client] -= 1;
			PrintToChat(client,"\x04Щит деактивирован, осталось \x03%i", SurvSpecialShield[client]);
			//CreateTimer(1.0, timerEndEffect, client);
		}
		return;
	}
	else CreateTimer(1.0, CheckSurvSpecialShield, client);
}

/*
public Action:SurvVampireStop(Handle:timer, any:client) {
	if (SurvVampire[client] <= 0) return;
	SurvVampire[client] -= 1;
	PrintToChat(client, "\x05Эффект Вампир прошел.");
	
	Timer21 = INVALID_HANDLE;
}

public Action:SurvShovingStop(Handle:timer, any:client) {
	if (SurvShoving[client] <= 0) return;
	SurvShoving[client] -= 1;
	PrintToChat(client, "\x05Эффект Выносливость прошел.");
	MA_Rebuild();
	
	Timer22 = INVALID_HANDLE;
}

public Action:SurvMeleeMasterStop(Handle:timer, any:client) {
	if (SurvMeleeMaster[client] <= 0) return;
	SurvMeleeMaster[client] -= 1;
	PrintToChat(client, "\x05Эффект Мастер рукопашного прошел.");
	MA_Rebuild();
	
	Timer23 = INVALID_HANDLE;
}

public Action:SurvGiftStop(Handle:timer, any:client) {
	if (!IsValidPlayer(client)) return;
	if (SurvGift[client] > 0) {
		SurvGift[client] --;
		PrintToChat(client, "\x05Эффект Подарок от зомби закончился.");
	}
	
	Timer24 = INVALID_HANDLE;
	
}
*/

public OnGameFrame()
{
	
	if (!IsServerProcessing() || g_bIsLoading)
	{
		return;
	}
	else
	{
		MA_OnGameFrame();
		//	DT_OnGameFrame();
	}
	
	//for(new i=1; i<=MaxClients; i++)
	//{
	//	if (SurvShoving[i] == 1) {
	//	
	//		if (i > 0 && IsValidEntity(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && IsClientInGame(i))
	//		{
	//			if(GetClientButtons(i) & IN_ATTACK2)
	//			{
	//				SetEntData(i, g_iShovePenalty, 0, 4);
	//			}
	//		}
	//	}
	//}
	

}

MA_OnGameFrame()
{
	if (IsEnd()) return 0;
	
	if (g_iMARegisterCount==0)
		return 0;

	decl iCid;
	decl iEntid;
	decl Float:flNextTime_calc;
	decl Float:flNextTime_ret;
	new Float:flGameTime=GetGameTime();

	for (new iI=1; iI<=g_iMARegisterCount; iI++)
	{
		iCid = g_iMARegisterIndex[iI];
		
		if (iCid <= 0) continue;
		if(!IsClientInGame(iCid)) continue;
		if(!IsClientConnected(iCid)) continue; 
		if (!IsPlayerAlive(iCid)) continue;
		if(GetClientTeam(iCid) != 2) continue;
		
		if (SurvShoving[iCid] > 0) {
			if(GetClientButtons(iCid) & IN_ATTACK2)
			{
				SetEntData(iCid, g_iShovePenalty, 0, 4);
			}
			
		}
		
		if (SurvMeleeMaster[iCid] <= 0) continue;
		
		iEntid = GetEntDataEnt2(iCid,g_ActiveWeaponOffset);
		if (iEntid == -1) continue;
		

		flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);

		if (iEntid == g_iMAEntid_notmelee[iCid])
		{
			continue;
		}

		if (g_iMAEntid[iCid] == iEntid
				&& g_iMAAttCount[iCid]!=0
				&& (flGameTime - flNextTime_ret) > 1.0)
		{
			g_iMAAttCount[iCid]=0;
		}

		if (g_iMAEntid[iCid] == iEntid
				&& g_flMANextTime[iCid]>=flNextTime_ret)
		{
			continue;
		}
		
		if (g_iMAEntid[iCid] == iEntid
				&& g_flMANextTime[iCid] < flNextTime_ret)
		{
			flNextTime_calc = flGameTime + 0.5;
			g_flMANextTime[iCid] = flNextTime_calc;
			SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);
			continue;
		}

		decl String:stName[32];
		GetEntityNetClass(iEntid,stName,32);
		if (StrEqual(stName,"CTerrorMeleeWeapon",false)==true)
		{
			g_iMAEntid[iCid]=iEntid;
			g_flMANextTime[iCid]=flNextTime_ret;
			continue;
		}
		else
		{
			g_iMAEntid_notmelee[iCid]=iEntid;
			continue;
		}
		
	}
	return 0;
}

MA_Rebuild()
{
	MA_Clear();
	
	if (IsEnd()) return;
	if (IsServerProcessing()==false)
		return;
		
	for (new iI=1 ; iI<=GetMaxClients() ; iI++)
	{
		if (IsClientInGame(iI)==true && IsPlayerAlive(iI)==true && GetClientTeam(iI)==2 && ((SurvMeleeMaster[iI] > 0) || (SurvShoving[iI]) > 0))
		{
			g_iMARegisterCount++;
			g_iMARegisterIndex[g_iMARegisterCount]=iI;
		}
	}
}

MA_Clear()
{
	g_iMARegisterCount=0;
	for (new iI=1 ; iI<=GetMaxClients() ; iI++)
	{
		g_iMARegisterIndex[iI]= -1;
	}
}

public OnClientPutInServer(client)
{
	if (MapEnd > 0) return;
	if (CampaignOver) return;
	
	MA_Rebuild();
	//SDKHook(client, SDKHook_PreThink, OnPreThink);
}

//On vomited by boomer or hit by boomer's explosion
public Action:OnVomited(Handle:hEvent, String:event_name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
		
	g_iWhoVomited[client] = attacker;
	if(!g_bIsVomited[client])
	{
		g_bIsVomited[client] = true;
		g_iTeam[client] = GetClientTeam(client);
		if((SurvRevenge[client] > 0) && (g_iTeam[client] == 2))
		{
			DoNastyRevenge();
			SurvRevenge[client] -= 1;
			PrintToChat(client, "\x01Сработало \x04Месть Бумеру\x01, осталось %i", SurvRevenge[client]);
			if (SurvRevenge[client] <=0) PrintToChat(client, "\x01Действие \x04Месть Бумеру \x01окончено.");
		}
	}
	//if(g_bHasBerserker[attacker] && GetConVarBool(g_cvarBlindVomit))
	//{
	//	ToggleBlackScreen(client);
	//}
}

DoNastyRevenge()
{
	PrintToChatAll("\x01Эффект \x04Месть Бумера \x01активирован.");
	new vcount = 0;
	for(new i=1; i<=MaxClients; i++)
	{
		if(i==0 || !IsClientInGame(i))	continue;
		
		g_iTeam[i] = GetClientTeam(i);
		
		if(g_iTeam[i] == 3 && IsPlayerAlive(i) && IsClientInGame(i))
		{
			switch(GetRandomInt(1, 2))
			{
				case 1:
				{
					PrintToChat(i, "\x01На Вас сработал эффект \x04Месть Бумера");
					SDKCall(sdkCallVomitPlayer, i, i, true);
					vcount++;
				}
			}
		}
	}
	vcount = 0;
}

stock Yell(client, type, power, radius)
{
	new Float:flMaxDistance = float(radius);
	new Float:power = power;
	new tcount = 0;
	
	if (!IsNormalPlayer(client)) return;
		
	EmitYell(client);
			
	decl Float:pos[3], Float:tpos[3], Float:traceVec[3], Float:resultingFling[3], Float:currentVelVec[3];
	
	GetClientAbsOrigin(client, pos);
	//PrintToChat(client, "%s позиция: %i %i %i", GetName(client), pos[0], pos[1], pos[2]);
	//PrintToChat(client, "активируем крик \x04%s", GetName(client));
	
	new Float:distance;
	
	if (GetClientTeam(client) == 2)
	{
				
		power+=300.0;
		//Find any possible colliding clients.
		for(new i=1; i<=GetMaxClients(); i++)
		{
			if (i == 0 || !IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || (IsPlayerGhost(i))) {
				continue;
			}
			if (GetClientTeam(client) == GetClientTeam(i)) {
				continue;
			}
											
			GetClientAbsOrigin(i, tpos);
			//distance = RoundToNearest(GetVectorDistance(pos, tpos));
			distance = GetVectorDistance(pos, tpos);
			
			//GetEntPropVector(i, Prop_Data, "m_vecOrigin", tpos);
			
			//PrintToChat(client, "клиент: \x04%s расстояние %f < %f", GetName(i), distance, flMaxDistance);
						
			//if (FloatCompare(distance, flMaxDistance) == -1) PrintToChat(client, "%s: distance ok (%i)", GetName(i), FloatCompare(distance, flMaxDistance)); else PrintToChat(client, "%s: distance false (%i)", GetName(i), FloatCompare(distance, flMaxDistance));
			//if (distance <= flMaxDistance) PrintToChat(client, "2 %s: distance ok (%i)", GetName(i), FloatCompare(distance, flMaxDistance)); else PrintToChat(client, "2 %s: distance false (%i)", GetName(i), FloatCompare(distance, flMaxDistance));
			//if (!IsTank(i))  PrintToChat(client, "%s: not tank", GetName(i)); else  PrintToChat(client, "%s: is tank", GetName(i));
					
			if ((FloatCompare(distance, flMaxDistance) == -1) && (!IsTank(i)))
			{
				//PrintToChat(client, "\x04%s \x01в зоне действия", GetName(i));
				if ( (InfAntiYell[i] > 0) && ( ((CurrentGamemodeID != 1) && (VipStatus[client] <= 2)) || (CurrentGamemodeID == 1) ) )  {
						AttachParticle(i, PARTICLE_ELEC, 2.0, 0.0);
						PrintToChat(client, "\x04%s: \x01защита от крика силы", GetName(i));
						continue;
				
				}
				
				if ((type == 2) || (type == 3))  {
					MakeVectorFromPoints(pos, tpos, traceVec);				
					GetVectorAngles(traceVec, resultingFling);
				
					resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;	// use trigonometric magic
					resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
					resultingFling[2] = power;
				
					GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
					resultingFling[0] += currentVelVec[0];
					resultingFling[1] += currentVelVec[1];
					resultingFling[2] += currentVelVec[2];
				
					//PrintToChat(client, "\x04%s \x01оглушен криком силы", GetName(i));
					
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resultingFling);
					//SDKCall(sdkShove, i, client, resultingFling);
					L4D_StaggerPlayer(i, client, resultingFling);//NULL_VECTOR);
				}
				
				if (type == 1) { //|| (type == 3)) {
					IgniteEntity(i, 30.0, false, 3.0);
					//HurtPoint(client, i, 1, 9, 50);
				}
			}
			//PrintToChat(client, "");
		}
		
		
		
		decl String:class[32];
		GetClientAbsOrigin(client, pos);
		
		//PrintToChat(client, "кол ентити: %i", GetMaxEntities());
		//new j;
		
		//if (type == 2) makeexplosion(client, -1, pos, "", 800);
		//else if (type == 3) makeexplosion(client, -1, pos, "", 200);
		
		for(new i = GetMaxClients()+1; i < GetMaxEntities(); i++)
		{
			if(IsValidEntity(i) && IsValidEdict(i))
			{
				GetEdictClassname(i, class,sizeof(class));
				//PrintToChat(client, "class %i: %s", i, class);
				//if(StrEqual(class, "infected") || StrEqual(class, "witch"))
				if ( (StrEqual(class, "infected")) || (StrEqual(class, "&infected")) )
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", tpos);
					//GetClientAbsOrigin(i, tpos);
					
					//distance = RoundToNearest(GetVectorDistance(pos, tpos));
					distance = GetVectorDistance(pos, tpos);
					
					//PrintToChat(client, "ентити infected or witch %i, distance %d < %d", i, distance, flMaxDistance);
					
					//if(GetVectorDistance(pos, tpos) <= flMaxDistance)
					if (FloatCompare(distance, flMaxDistance) == -1)
					{
						if ((type == 2) || (type == 3)) {
							//MakeVectorFromPoints(pos, tpos, traceVec);				
							//GetVectorAngles(traceVec, resultingFling);
							
							//resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;	// use trigonometric magic
							//resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
							//resultingFling[2] = power;
							
							//GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had //before
							//resultingFling[0] += currentVelVec[0];
							//resultingFling[1] += currentVelVec[1];
							//resultingFling[2] += currentVelVec[2];
							
							//PrintToChat(client, "\x04%s \x01отбиваем", GetName(i));
							
							//TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resultingFling);
//							SDKCall(sdkShove, i, client, resultingFling);
						//	L4D_StaggerPlayer(i, client, resultingFling);
							HurtPoint(client, i, 0, 536870912, 100);
						}	
						
						//PrintToChat(client, "поджигаем infected %i", i);
						if (type == 1) {// || (type == 3)) {
							//IgniteEntity(i, 5.0, true);
							//AcceptEntityInput(i, "Ignite");
							AttachParticle(i, PARTICLE_FIRE2, 3.0, 0.0);
							HurtPoint(client, i, 1, 9, 10);
						}
					}
				}
			}
		}
		//PrintToChat(client, "последний ентити: %i", j);
	}
	
	tcount = 0;
}

public Action:cmd_yell(client, args)
{
    PrintToChat(client, "\x05Крииииик!!!!");
	Yell(client, 3, 500, 1000);
}

public ConvertHealth(any:client)
{
	new TempHealth = GetClientTempHealth(client);
	if(TempHealth > 0)
	{
		new PermHealth = GetClientHealth(client);
		new total = PermHealth + TempHealth;
		
		RemoveTempHealth(client);
		SetEntityHealth(client, total);
	}
}	

stock GetClientTempHealth(client)
{
	//First filter -> Must be a valid client, successfully in-game and not an spectator (The dont have health).
    if(!client
    || !IsValidEntity(client)
    || !IsClientInGame(client)
	|| !IsPlayerAlive(client)
    || IsClientObserver(client)
	|| GetClientTeam(client) != 2)
    {
        return -1;
    }
    
    //First, we get the amount of temporal health the client has
    new Float:buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    
    //We declare the permanent and temporal health variables
    new Float:TempHealth;
    
    //In case the buffer is 0 or less, we set the temporal health as 0, because the client has not used any pills or adrenaline yet
    if(buffer <= 0.0)
    {
        TempHealth = 0.0;
    }
    
    //In case it is higher than 0, we proceed to calculate the temporl health
    else
    {
        //This is the difference between the time we used the temporal item, and the current time
        new Float:difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
        
        //We get the decay rate from this convar (Note: Adrenaline uses this value)
        new Float:decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
        
        //This is a constant we create to determine the amount of health. This is the amount of time it has to pass
        //before 1 Temporal HP is consumed.
        new Float:constant = 1.0/decay;
        
        //Then we do the calcs
        TempHealth = buffer - (difference / constant);
    }
    
    //If the temporal health resulted less than 0, then it is just 0.
    if(TempHealth < 0.0)
    {
        TempHealth = 0.0;
    }
    
    //Return the value
    return RoundToFloor(TempHealth);
}		
		
stock RemoveTempHealth(client)
{
	if(!client
    || !IsValidEntity(client)
    || !IsClientInGame(client)
	|| !IsPlayerAlive(client)
    || IsClientObserver(client)
	|| GetClientTeam(client) != 2)
    {
        return;
    }
	SDKCall(sdkSetBuffer, client, 0.0);
}

String:GetDescr(String:id[255])
{
	decl String:result[255];
	
	if (StrEqual(id,"InfSpeedUp")) Format(result, sizeof(result), "Ваша скорость будет увеличина на 50% в течении одного респа.");
	else if (StrEqual(id,"SurvSpecialShield")) Format(result, sizeof(result), "Щит активируется в момент спец. атаки зомби(Хантер напрыгнул ...), на 5 сек.");
	else if (StrEqual(id,"SurvIncSpecialShield")) Format(result, sizeof(result), "Щит активируется при отключке на 20 сек. Деактивируется если встали.");
	else if (StrEqual(id,"SurvVampire")) Format(result, sizeof(result), "За каждого убитого обычного зомби Вы получаете +1 HP за спец. зомби +3 HP в течении 15 сек.");
	else if (StrEqual(id,"SurvShoving")) Format(result, sizeof(result), "Вы не устаете в течении 20 сек.(то-есть можете отбивать зомби скока хотите)");
	else if (StrEqual(id,"SurvLaser")) Format(result, sizeof(result), "Устанавливается лазерный прицел на текущее оружие.");
	else if (StrEqual(id,"SurvMeleeMaster")) Format(result, sizeof(result), "Нет задержки после удара рукопашным оружием в течении 20 сек.");
	else if (StrEqual(id,"SurvRevenge")) Format(result, sizeof(result), "Если Вас облювали есть шанс 50% облювать в ответ спец. зомби.");
	else if (StrEqual(id,"SurvHealthConvert")) Format(result, sizeof(result), "Конвертация времменных HP(от пилюл или адреналина) в постоянные.");
	else if (StrEqual(id,"InfSpeedUp")) Format(result, sizeof(result), "Скорость движения повышается на 50%, не применимо к танку.");
	else if (StrEqual(id,"InfBonusDamage")) Format(result, sizeof(result), "+7 к урону когтями, повреждение повышено так же для всех спец ударов, удушение курилой, удар громилы в движение и когда об стенку долбит, язык курилы душит ...");
	else if (StrEqual(id,"InfSpecialShield;")) Format(result, sizeof(result), "Щит активируется в момент применения спец. приемов (хантер напал на жертву) щит действует 5 секунд, если зомби был сбит щит деактивируется.");
	else if (StrEqual(id,"InfBonusHealth")) Format(result, sizeof(result), "Зобми появляется с удвоенными жизнями, купить можно только в режиме призрака, не применимо к танку.");
	else if (StrEqual(id,"InfAcidClaws")) Format(result, sizeof(result), "Когти зомби наносят доп. +3 урона кислотой растянутые на 6 секунд, тоесть 1 урон в 2 секунды, также добавляется эффект замедления на 30% на время действия кислоты, урон и эффект распространяется на спец атаки(то есть язык курилы так же нанесет доп 3 урона и эффект замедления).");
	else if (StrEqual(id,"InfFireShield")) Format(result, sizeof(result), "Полный иммунитет к огню, если куплено горящим, зомби потушиться. Не применимо к танку.");
	else if (StrEqual(id,"InfMask")) Format(result, sizeof(result), "60% невидимости, не применимо к танку.");
	else if (StrEqual(id,"InfMeeleShield")) Format(result, sizeof(result), "Полный иммунитет к рукопашному урону, включая бензопилу.");
	else if (StrEqual(id,"InfRegen")) Format(result, sizeof(result), "+10 ХП каждые 2 секунды.");
	
	return result;

}

public Action:SetIsLoadingFalse(Handle:timer, any:client) 
{
	g_bIsLoading = false;
}

public Action:cmd_check(client, args)
{
    PrintToChat(client, "\x05Проверка:");
	PrintToChat(client, "isserverprocessing: %i isloading: %i", IsServerProcessing(), g_bIsLoading);
	for (new iI=1; iI<=g_iMARegisterCount; iI++)  {
		PrintToChat(client, "%s", GetName(g_iMARegisterIndex[iI]));
	}
	
}

public Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundStartInit();	
}

//points end


public Action:cmd_ShowPoints(client, args)
{
	if (!IsValidPlayer(client)) return Plugin_Handled;

	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Поинты игроков");
	
	decl String:text[255];
	decl String:pName[255];
	
	DrawPanelText(panel, "Живые:");
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsValidPlayer(i))
			if (GetClientTeam(i) == 2) {
				pName = GetName(i);
				ReplaceString(pName, sizeof(pName), "[", "|");
				ReplaceString(pName, sizeof(pName), "]", "|");
				Format(text, sizeof(text), "%s [%i]", pName, points[i]);
				DrawPanelText(panel, text);
			}
	}
	DrawPanelText(panel, " \n");
	DrawPanelText(panel, "Трупы:");
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsValidPlayer(i))
			if (GetClientTeam(i) == 3) {
				pName = GetName(i);
				ReplaceString(pName, sizeof(pName), "[", "|");
				ReplaceString(pName, sizeof(pName), "]", "|");
				Format(text, sizeof(text), "%s [%i]", pName, points[i]);
				DrawPanelText(panel, text);
			}
	}
	
	DrawPanelText(panel, " \n");
	DrawPanelText(panel, "1. Close");
	
	SendPanelToClient(panel, client, JustHandler, 60);
	CloseHandle(panel);
}

public JustHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		
	}

		
}

public SendPointsHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE) return;
	if (action == MenuAction_End) {
		
		CloseHandle(menu);
	}
	if (action != MenuAction_Select || param1 <= 0 || (!IsValidPlayer(param1))) {
		
		return;
	}

	decl String:Info[255];
	new bool:found = GetMenuItem(menu, param2, Info, sizeof(Info));
	
	if (!found) return;
	
	//new fromclient = param1;
	ToClient[param1] = StringToInt(Info);

	decl String:Title[MAX_LINE_WIDTH];
	Format(Title, sizeof(Title), "Сколько поинтов:");
	new Handle:menu2 = CreateMenu(SendPointsFinaleHandler);

	SetMenuTitle(menu2, Title);
	SetMenuExitBackButton(menu2, false);
	SetMenuExitButton(menu2, true);

	decl String:text[255], id[10];
	new step;
	
	step = RoundToFloor(FloatDiv(float(points[param1]),6.0));
	new value = step;
	Format(text, sizeof(text), "%d", value);
	AddMenuItem(menu2, text, text);
	
	value = value + step;
	Format(text, sizeof(text), "%d", value);
	AddMenuItem(menu2, text, text);
	
	value = value + step;
	Format(text, sizeof(text), "%d", value);
	AddMenuItem(menu2, text, text);
	
	value = value + step;
	Format(text, sizeof(text), "%d", value);
	AddMenuItem(menu2, text, text);
	
	value = value + step;
	Format(text, sizeof(text), "%d", value);
	AddMenuItem(menu2, text, text);
	
	value = points[param1];
	Format(text, sizeof(text), "%d", value);
	AddMenuItem(menu2, text, text);
				
	DisplayMenu(menu2, param1, 60);	
	
}

public Action:SetBonusHealth(Handle:timer, any:client) 
{
	if (!IsNormalPlayer(client)) return;
	
	decl String:s_ModelName[255];
	GetEntPropString(client, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName));
	if (StrContains(s_ModelName, "hulk") > -1) return;
	
	new Health = GetClientHealth(client);
	SetEntityHealth(client, Health+Health);
	PrintToChat(client, "\x04Ваши жизни повышены до \x05%i", Health+Health);
	OriginHealth[client] = Health+Health;
}	

public Action:SetHulkHealth(Handle:timer, any:client) 
{
	new Health;
	Health = GetClientHealth(client);
	if (Health > HulkHP) CreateTimer(0.5, SetHulkHealth, client);
	else return;
	
    SetEntityHealth(client, HulkHP);
	Health = GetClientHealth(client);
	PrintToChat(client, "\x04Ваши жизни: \x05%i", Health);
	OriginHealth[client] = Health;
}	

public Action:SetTankChaosHealth(Handle:timer, any:client) 
{
	new Health;
	Health = GetClientHealth(client);
	if (Health > InfTankChaos_HP) CreateTimer(0.5, SetTankChaosHealth, client);
	else return;
	
    SetEntityHealth(client, InfTankChaos_HP);
	Health = GetClientHealth(client);
	PrintToChat(client, "\x04Ваши жизни: \x05%i", Health);
	OriginHealth[client] = Health;
}	


public BuildBuyMenu2(any:client)
{
		if (!IsValidPlayer(client)) return;
		
		new Handle:menu = CreateMenu(MenuHandler_Survivors);
		//SetMenuExitBackButton(menu, true);
		
		SetGlobalTransTarget(client);
		
		decl String:text[255];
		decl String:title[255];
	
		if (SurvSpeedUp[client] > 0) Format(text, sizeof(text),"[%i]%t (%i)", SurvSpeedUp[client], "SpeedUp", SurvSpeedUp_Cost);
		else Format(text, sizeof(text),"%t (%i)", "SpeedUp", SurvSpeedUp_Cost);
		AddMenuItem(menu, "SurvSpeedUp", text);
		
		if (VictimID != client) {
			if (SurvSpecialShield[client] > 0) Format(text, sizeof(text),"[%i]%t (%i)", SurvSpecialShield[client], "SpecialShield", SurvSpecialShield_Cost);
			else Format(text, sizeof(text),"%t (%i)", "SpecialShield", cost);
			AddMenuItem(menu, "SurvSpecialShield", text);
				
			if (SurvIncSpecialShield[client] > 0) Format(text, sizeof(text),"[%i]%t 2 (%i)", SurvIncSpecialShield[client], "SpecialShield", SurvIncSpecialShield_Cost);
			else Format(text, sizeof(text),"%t 2 (%i)", "SpecialShield", SurvIncSpecialShield_Cost);
			AddMenuItem(menu, "SurvIncSpecialShield", text);
		}
		
		if (SurvVampire[client] > 0) Format(text, sizeof(text),"[%i]%t (%i)", SurvVampire[client], "Vampire", SurvVampire_Cost);
		else Format(text, sizeof(text),"%t (%i)", "Vampire", SurvVampire_Cost); 
		AddMenuItem(menu, "SurvVampire", text);
		
		if (SurvShoving[client] > 0) Format(text, sizeof(text),"[%i]%t (%i)", SurvShoving[client], "Stamina", SurvShoving_Cost);
		else Format(text, sizeof(text),"%t (%i)", "Stamina", SurvShoving_Cost);
		AddMenuItem(menu, "SurvShoving", text);
		
		if (SurvMeleeMaster[client] > 0) Format(text, sizeof(text),"[%i]%t (%i)", SurvMeleeMaster[client], "MeleeMaster", SurvMeleeMaster_Cost);
		else Format(text, sizeof(text),"%t (%i)", "MeleeMaster", SurvMeleeMaster_Cost);
		AddMenuItem(menu, "SurvMeleeMaster", text);
		
		if (SurvRevenge[client] > 0) Format(text, sizeof(text),"[%i]%t (%i)", SurvRevenge[client], "RevengeBoomer", SurvRevenge_Cost);
		else Format(text, sizeof(text),"%t (%i)", "RevengeBoomer", SurvRevenge_Cost);
		AddMenuItem(menu, "SurvRevenge", text);
						
		if (SurvGift[client] > 0) Format(text, sizeof(text),"[%i]%t (%i)", SurvGift[client], "ZombiePresents", SurvGift_Cost);
		else Format(text, sizeof(text),"%t (%i)", "ZombiePresents", SurvGift_Cost);
		AddMenuItem(menu, "SurvGift", text);
			
		if (SurvFirearmsMaster[client] > 0) Format(text, sizeof(text),"[%i]%t (%i)", SurvFirearmsMaster[client], "SurvBulletDamage", SurvFirearmsMaster_Cost);
		else Format(text, sizeof(text),"%t (%i)", "SurvBulletDamage", SurvFirearmsMaster_Cost);
		AddMenuItem(menu, "SurvFirearmsMaster", text);
				
		Format(title, sizeof(title),"%t: %d", "YourPoints", points[client]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, 30);
} 

public BuildBuyMenu3(any:client)
{
		if (!IsValidPlayer(client)) return;
		
		new Handle:menu = CreateMenu(MenuHandler_Survivors);
		//SetMenuExitBackButton(menu, true);
	
		SetGlobalTransTarget(client);
	
		decl String:text[255];
		decl String:title[255];
	
		Format(text, sizeof(text),"%t (%i)", "ConvertHP", SurvHealthConvert_Cost);
		AddMenuItem(menu, "SurvHealthConvert", text);
		
		Format(text, sizeof(text),"%t (%i)", "FireYell", SurvFireYell_Cost);
		AddMenuItem(menu, "SurvFireYell", text);
		
		Format(text, sizeof(text),"%t (%i)", "PowerYell", SurvPowerYell_Cost);
		AddMenuItem(menu, "SurvPowerYell", text);
		
		Format(text, sizeof(text),"%t (%i)", "LeapDesperation", SurvBerserker_Cost);
		AddMenuItem(menu, "SurvBerserker", text);		
		
		Format(text, sizeof(text),"%t (%i)", "IncapSelfKill", 0);
		AddMenuItem(menu, "SurvSelfKill", text);		
	
		Format(title, sizeof(title),"%t: %d", "YourPoints", points[client]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, 30);
} 

public BuildBuyMenu4(any:client)
{
	if (!IsValidPlayer(client)) return;
		new Handle:menu = CreateMenu(MenuHandler_Survivors);
		//SetMenuExitBackButton(menu, true);
		
		SetGlobalTransTarget(client);
		
		decl String:text[255];
		decl String:title[255];
		
		Format(text, sizeof(text),"%t (%i)", "LaserAim", SurvLaser_Cost);
		AddMenuItem(menu, "SurvLaser", text);
		
		Format(text, sizeof(text),"%t (%i)", "AWP", SurvAWP_Cost);
		AddMenuItem(menu, "SurvAWP", text);

		Format(text, sizeof(text),"%t (%i)", "M60", SurvM60_Cost);
		AddMenuItem(menu, "SurvM60", text);
		
		Format(text, sizeof(text),"%t (%i)", "GrenadeLauncher", SurvGL_Cost);
		AddMenuItem(menu, "SurvGL", text);
	
		if (SurvFirearmsMaster[client] > 0) Format(text, sizeof(text),"%t (%i)", "ExplosiveAmmo", SurvUpgradeExplosive_Cost - 20);
		else Format(text, sizeof(text),"%t (%i)", "ExplosiveAmmo", SurvUpgradeExplosive_Cost);
		//if (SurvUpgradeExplosive[client] > 0) Format(text, sizeof(text),"[%i]%s", text);
		AddMenuItem(menu, "explosive_ammo", text);
		
		if (SurvFirearmsMaster[client] > 0) Format(text, sizeof(text),"%t (%i)", "IncendiaryAmmo", SurvUpgradeIncendiary_Cost - 20);
		else Format(text, sizeof(text),"%t (%i)", "IncendiaryAmmo", SurvUpgradeIncendiary_Cost);
		AddMenuItem(menu, "incendiary_ammo", text);
		
		if (SurvFirearmsMaster[client] > 0) Format(text, sizeof(text),"%t (%i)", "UpgradepackExplosive", SurvExplosiveAmmo_Cost - 20);
		else Format(text, sizeof(text),"%t (%i)", "UpgradepackExplosive", SurvExplosiveAmmo_Cost);
		AddMenuItem(menu, "upgradepack_explosive", text);
	
		if (SurvFirearmsMaster[client] > 0) Format(text, sizeof(text),"%t (%i)", "UpgradepackIncendiary", SurvIncendiaryAmmo_Cost - 20);
		else Format(text, sizeof(text),"%t (%i)", "UpgradepackIncendiary", SurvIncendiaryAmmo_Cost);
		AddMenuItem(menu, "upgradepack_incendiary", text);
		
		Format(text, sizeof(text),"%t (%i)", "GasCan", SurvGasCan_Cost);
		AddMenuItem(menu, "GasCan", text);
		
		Format(title, sizeof(title),"%t: %d", "YourPoints", points[client]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, 30);
} 

public Action:YellTimerStop(Handle:timer, any:client) 
{
	
	SetGlobalTransTarget(client);
	if (SurvBerserker[client] > 0) {
		PrintToChat(client, "\x01%t \x05%t \x01%t", "Action", "LeapDesperation", "Finished");
		SurvBerserker[client] -= 1;
		ServerCommand("sm_colour #%i 255 255 255 255", GetClientUserId(client));
	}
}

public Action:YellTimer(Handle:timer, any:client) 
{
	//PrintToChatAll("\x05Эффект ярости 1");
	if (IsEnd()) return;
	
	new entity;
	
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsValidPlayer(i)) {
			
			if (SurvBerserker[i] > 0) {
				if ((GetClientTeam(i) == 2) && (IsPlayerAlive(i))) {
					//PrintToChat(i, "\x05Эффект ярости");
					AttachParticle(i, PARTICLE_ELEC, 0.9, 0.0);
					new Health = GetClientHealth(i);
					new FinalHealth = Health - 1;
					if (FinalHealth > 0) SetEntityHealth(i, FinalHealth);
					Yell(i, 3, 400, 200);
				}
			}
			
			if (SurvSpeedUp[i] > 0) {
				SurvSpeedUp[i] --;
				if (SurvSpeedUp[i] <= 0) {
					SetEntDataFloat(i, g_flLagMovement, 1.0, true);
					PrintToChat(i, "\x01Эффект \x03Ускорения \x01прошел.");	
				}
			}
			
			if (SurvVampire[i] > 0) {
				SurvVampire[i] --;
				if (SurvVampire[i] <= 0) {
					SetEntDataFloat(i, g_flLagMovement, 1.0, true);
					PrintToChat(i, "\x01Эффект \x03Вампир \x01прошел.");
				}
			}
				

			if (SurvShoving[i] > 0) {
				SurvShoving[i] --;
				if (SurvShoving[i] <= 0) {
					PrintToChat(i, "\x01Эффект \x03Выносливость \x01прошел.");
					MA_Rebuild();
				}
			}
			
			if (SurvMeleeMaster[i] > 0) {
				SurvMeleeMaster[i] --;
				if (SurvMeleeMaster[i] <= 0) {
					PrintToChat(i, "\x01Эффект \x03Мастер рукопашного \x01прошел.");
					MA_Rebuild();
				}
			}
			
			if (SurvGift[i] > 0) {
				SurvGift[i] --;
				if (SurvGift[i] <= 0) {
					PrintToChat(i, "\x01Эффект \x03Подарок от зомби \x01закончился.");
				}
			}
			
			if (SurvFirearmsMaster[i] > 0) {
				SurvFirearmsMaster[i] --;
				if (SurvFirearmsMaster[i] <= 0) {
					PrintToChat(i, "\x01Эффект \x03Мастер огнестрельного оружия \x01закончился.");
				}
			}
			
		}
		
		if ((IsNormalPlayer(i)) && (GetClientTeam(i) == 2))  {
			if (IsPlayerIncapped(i)) IsInc[i] = 1; else IsInc[i] = 0;
		/*
			new String:CurClassname[255];
			GetClientModel(i, CurClassname, sizeof(CurClassname));
			if ( (!StrEqual(CurClassname, SkinClassname[i])) && ((Shields[i] > 0) && (IsValidEdict(Shields[i])) && (IsValidEntity(Shields[i]))) )
				AcceptEntityInput(Shields[i], "Kill");
			
			SkinClassname[i] = CurClassname;
			
			
			if (InfPoison == i) {
				SetEntDataFloat(i, g_flLagMovement, 0.2, true);
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, 0, 255, 0, 255);
				AttachParticle(i, PARTICLE_SPIT, 1.0, 0.0);
			}
			else if (SurvSpecialShield[i] > 0) {
					
				//if (g_bIsGlowing[i] == false) {
					//if ( !IsValidEntRef(VictimRenderEnt[i]) )
				//		VictimRenderEnt[i] = CreateEnvSprite(i, "100 100 255");	
					//g_bIsGlowing[i] = true;
					//SetEntityRenderMode(i, RENDER_TRANSCOLOR);
					//SetEntityRenderColor(i, 50, 50, 50, 255);
				//}
				if (!((Shields[i] > 0) && (IsValidEdict(Shields[i])) && (IsValidEntity(Shields[i])))) 
					Shields[i] = CreateShield(i, 180.0, 0.0, 90.0);
			}
			else {
				
				//if (g_bIsGlowing[i] == true) {
					//entity = VictimRenderEnt[i];
					//if ( IsValidEntRef(entity) )	AcceptEntityInput(entity, "Kill");
					//g_bIsGlowing[i] = false;
					//SetEntityRenderMode(i, RENDER_TRANSCOLOR);
					//SetEntityRenderColor(i, 255, 255, 255, 255);
				//}
				if ((Shields[i] > 0) && (IsValidEdict(Shields[i])) && (IsValidEntity(Shields[i]))) 
					AcceptEntityInput(Shields[i], "Kill");
			}
			*/
		}
	}	
}

public ActivateBuy(any:param1)
{
	if ((IsEnd()) || (MapEnd > 0)) return;
	if (!IsValidPlayer(param1)) return;
	if (AllowActivateBuyClient[param1] == 0) {
		PrintToChat(param1, "Подождите пол секунды.");
		return;
	}
		
	AllowActivateBuyClient[param1] = 0;
	CreateTimer(0.5, AllowActivateBuyClientResetTimer, param1);
	SetGlobalTransTarget(param1);
	
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "%t %d/%d", "NotEnoughPoints", points[param1], cost[param1]);
					return;
				}
				
				if ((GetClientTeam(param1) == 2) && (!IsPlayerAlive(param1))) {
					PrintToChat(param1, "\x05%t.", "DeadRefuse");
					return;
				}
				
			if (GetClientTeam(param1) == 2) {	
			
				new String:class[40];
				new wep = GetPlayerWeaponSlot(param1, 0);
				if (IsValidEdict(wep)) GetEdictClassname(wep, class, sizeof(class));
			
				if(StrEqual(item[param1], "SurvFirearmsMaster", false))
				{
					if ((GetClientTeam(param1) == 2) && (IsClientInGame(param1)) && (IsPlayerAlive(param1))) 
					{				
					
						PrintToChat(param1, "\x01%t \x04%t", "Activated", "SurvBulletDamage");
						SurvFirearmsMaster[param1] = SurvFirearmsMaster[param1] + 300;
																	
						points[param1] -= cost[param1];
					
					}
										
				} 
				else if(StrEqual(item[param1], "SurvSpeedUp", false))
				{
					if ((GetClientTeam(param1) == 2) && (IsClientInGame(param1)) && (IsPlayerAlive(param1))) 
					{
												
						//if (SurvSpeedUp[param1] > 0) {
							//PrintToChat(param1, "\x05%t.", "AlreadyActive");
							//return;
							
						//}
						PrintToChat(param1,"\x01%t \x04%t \x05+40 %t \x01%t \x05 5 %t.", "Activated", "SpeedUp", "Percents", "Duration", "Minutes");
						SurvSpeedUp[param1] = SurvSpeedUp[param1] + 300;
						
						SetEntDataFloat(param1, g_flLagMovement, 1.4, true);
						//CreateTimer(0.5, UpdateSpeedUp, param1);
						//if (Timer20 == INVALID_HANDLE) Timer20 = CreateTimer(300.0, ResetSpeedUp, param1);
						points[param1] -= cost[param1];
						
					}
					else PrintToChat(param1, "%t.", "UnableSpeedUp");
					
				}	
				else if(StrEqual(item[param1], "SurvSpecialShield", false))
				{	
					if (VictimID == param1) {
						PrintToChat(param1, "\x05Жертве \x01запрещено покупать щиты.");
						return;
					}
					//if (SurvSpecialShield[param1] > 0) {
					//	PrintToChat(param1, "\x05%t.", "AlreadyActive");
					//	return;
					//}
					points[param1] -= cost[param1];
					PrintToChat(param1, "\x01%t: \x04%t.", "Activated", "SpecialShield");
					SurvSpecialShield[param1] = SurvSpecialShield[param1] + 5;
				}	
				else if(StrEqual(item[param1], "SurvVampire", false))
				{	
					//if (SurvVampire[param1] > 0) {
					//	PrintToChat(param1, "\x05%t.", "AlreadyActive");
					//	return;
					//}
					points[param1] -= cost[param1];
					PrintToChat(param1, "\x01%t: \x04%t \x01%t 5 %t.", "Activated", "Vampire", "Duration", "Minutes");
					SurvVampire[param1] = SurvVampire[param1] + 300;
					//if (Timer21 == INVALID_HANDLE) Timer21 = CreateTimer(300.0, SurvVampireStop, param1);
				}	
				else if(StrEqual(item[param1], "SurvShoving", false))
				{	
					//if (SurvShoving[param1] > 0) {
					//	PrintToChat(param1, "\x05%t.", "AlreadyActive");
					//	return;
					//}
					points[param1] -= cost[param1];
					PrintToChat(param1, "\x01%t: \x04%t \x01%t 5 %t.", "Activated", "Stamina", "Duration", "Minutes");
					SurvShoving[param1] = SurvShoving[param1] + 300;
					MA_Rebuild();
					//if (Timer22 = INVALID_HANDLE) Timer22 = CreateTimer(300.0, SurvShovingStop, param1);
				}
				else if(StrEqual(item[param1], "SurvLaser", false))
				{	
					points[param1] -= cost[param1];
					PrintToChat(param1, "\x05%t \x01%t.", "LaserAim", "Installed");
					SurvLaser[param1] += 1;
					
					RemoveFlags();
					FakeClientCommand(param1, "upgrade_add LASER_SIGHT");
					AddFlags();
				}
				else if(StrEqual(item[param1], "SurvMeleeMaster", false))
				{	
					//if (SurvMeleeMaster[param1] > 0) {
					//	PrintToChat(param1, "\x05%t.", "AlreadyActive");
					//	return;
					//}
					points[param1] -= cost[param1];
					PrintToChat(param1, "\x01%t: \x03%t \x01%t 5 %t.", "Activated", "MeleeMaster", "Duration", "Minutes");
					SurvMeleeMaster[param1] = SurvMeleeMaster[param1] + 300;
					MA_Rebuild();
					//if (Timer23 = INVALID_HANDLE) Timer23 = CreateTimer(300.0, SurvMeleeMasterStop, param1);
				}
				else if(StrEqual(item[param1], "SurvRevenge", false))
				{	
					//if (SurvRevenge[param1] > 0) {
					//	PrintToChat(param1, "\x05%t.", "AlreadyActive");
					//	return;
					//}
					points[param1] -= cost[param1];
					PrintToChat(param1, "\x01%t: \x03%t \x01%t 20 %t.", "Activated", "RevengeBoomer", "Duration", "Activations");
					SurvRevenge[param1] = SurvRevenge[param1] + 20;
				}
				else if(StrEqual(item[param1], "SurvHealthConvert", false))
				{	
					points[param1] -= cost[param1];
					PrintToChat(param1, "\x01%t: \x03%t.", "Activated", "ConvertHP");
					ConvertHealth(param1);
				}
				else if(StrEqual(item[param1], "SurvIncSpecialShield", false))
				{	
					if (VictimID == param1) {
						PrintToChat(param1, "\x05Жертве \x01запрещено покупать щиты.");
						return;
					}
					if (IsPlayerIncapped(param1)) {
						PrintToChat(param1, "Запрещено покупать щиты в отключке.");
						return;
					}
					//if (SurvIncSpecialShield[param1] > 0) {
					//	PrintToChat(param1, "\x05%t.", "AlreadyActive");
					//	return;
					//}
					points[param1] -= cost[param1];
					SurvIncSpecialShield[param1] = SurvIncSpecialShield[param1] + 3;
					PrintToChat(param1, "\x01%t: \x03%t 2.", "Activated", "SpecialShield");
					/*
					if (IsPlayerIncapped(param1)) {
						if (GetEntProp(param1, Prop_Data, "m_takedamage") != 0) {
							SetEntProp(param1, Prop_Data, "m_takedamage", 0, 1);
							CreateTimer(30.0, RemoveIncSpecialShield, param1);
							PrintToChat(param1, "\x01%t \x04%t 2 \x01%t 30 %t", "Activated", "SpecialShield", "Duration", "Seconds");
						}
					}
					*/
				}
				else if(StrEqual(item[param1], "SurvGift", false))
				{	
					//if (SurvGift[param1] > 0) {
					//	PrintToChat(param1, "\x05%t.", "AlreadyActive");
					//	return;
					//}
					points[param1] -= cost[param1];
					SurvGift[param1] = SurvGift[param1] + 300;
					//if (Timer24 = INVALID_HANDLE) Timer24 = CreateTimer(300.0, SurvGiftStop, param1);
					PrintToChat(param1, "\x01%t: \x03%t.", "Activated", "ZombiePresents");
				}
				else if(StrEqual(item[param1], "GasCan", false))
				{	
					points[param1] -= cost[param1];
					PrintToChat(param1, "\x05%t \x01%t.", "GasCan", "Bought");
										
					RemoveFlags();
					FakeClientCommand(param1, "give gascan");
					AddFlags();
				}
				else if(StrEqual(item[param1], "SurvAWP", false))
				{	
					new awp_limit;
					if (CurrentGamemodeID != 1) awp_limit = 4; else awp_limit = 2;
					if ((SurvAWP >= awp_limit) && (!IsAdmin(param1)) && (VipBonus[param1][5] <= 0)) {
						PrintToChat(param1, "\x05%t.", "AWPLimit");
						return;
					}
					if ((VipBonus[param1][5] > 0) && (SurvAWP >= 2)) VipBonus[param1][5] -= 1;
					
					points[param1] -= cost[param1];
					SurvAWP += 1;
					PrintToChat(param1, "\x01%t: \x03%t.", "Bought", "AWP");
					RemoveFlags();
					FakeClientCommand(param1, "give sniper_awp");
					AddFlags();
					
				}
				else if(StrEqual(item[param1], "SurvM60", false))
				{	
					new m60_limit;
					if (CurrentGamemodeID != 1) m60_limit = 3; else m60_limit = 1;
					
					if (SurvM60 >= m60_limit) {
						if (((CurrentGamemodeID == 0) && (VipBonus[param1][5] <= 0)) || (CurrentGamemodeID != 0)) {
							PrintToChat(param1, "\x05%t.", "M60Limit");
							return;
						}
					}
					points[param1] -= cost[param1];
					SurvM60 += 1;
					PrintToChat(param1, "\x01%t: \x03%t.", "Bought", "M60");
					RemoveFlags();
					FakeClientCommand(param1, "give rifle_m60");
					AddFlags();
					
				}
				else if(StrEqual(item[param1], "SurvFireYell", false))
				{	
					points[param1] -= cost[param1];
					PrintToChatAll("\x04[%s]\x01%t: \x03%t.", GetName(param1), "Activated", "FireYell");
					Yell(param1, 1, 400, 600);
					IgniteEntity(param1, 10.0, false, 3.0);
					//HurtPoint(param1, param1, 1, 8, 50);
							
					//new prop = CreateEntityByName("prop_physics");
					//if (IsValidEntity(prop))
					//{
					//	new Float:Pos[3];
					//	GetEntPropVector(param1, Prop_Send, "m_vecOrigin", Pos);
					//	//Pos[2] += 10.0;
					//	DispatchKeyValue(prop, "model", "models/props_junk/gascan001a.mdl");
					//	DispatchSpawn(prop);
					//	SetEntData(prop, GetEntSendPropOffs(prop, "m_CollisionGroup"), 1, 1, true);
					//	TeleportEntity(prop, Pos, NULL_VECTOR, NULL_VECTOR);
					//	AcceptEntityInput(prop, "break");
					//}
					
					
				}
				else if(StrEqual(item[param1], "SurvPowerYell", false))
				{	
					points[param1] -= cost[param1];
					PrintToChatAll("\x04[%s]\x01%t: \x03%t.", GetName(param1), "Activated", "PowerYell");
					Yell(param1, 2, 600, 800);
					
					AttachParticle(param1, PARTICLE_EXPLODE, 0.8, 0.0);
					new Health = GetClientHealth(param1);
					new FinalHealth = Health - 7;
					if (FinalHealth > 0) SetEntityHealth(param1, FinalHealth);
					
				}
				else if(StrEqual(item[param1], "SurvBerserker", false))
				{	
					points[param1] -= cost[param1];
					PrintToChatAll("\x04[%s]\x01%t: \x03%t.", GetName(param1), "Activated", "LeapDesperation");
					SurvBerserker[param1] += 1;
					
					//ShowEffect(param1);
					//ServerCommand("sm_color #%i 0 0 0 255",GetClientUserId(param1));
					//CreateTimer(0.5, YellTimer, param1);
					CreateTimer(10.0, YellTimerStop, param1);
				}
				else if(StrEqual(item[param1], "SurvGL", false))
				{	
					new gl_limit;
					if (CurrentGamemodeID != 1) gl_limit = 2; else gl_limit = 1;
					if (SurvGL >= gl_limit) {
						PrintToChat(param1, "\x05%t.", "GLLimit");
						return;
					}
					points[param1] -= cost[param1];
					SurvGL += 1;
					PrintToChat(param1, "\x01%t: \x03%t.", "Bought", "GrenadeLauncher");
					RemoveFlags();
					FakeClientCommand(param1, "give grenade_launcher");
					AddFlags();					
				}
				if(StrEqual(item[param1], "give upgradepack_explosive", false))
				{															
					points[param1] -= cost[param1];
					PrintToChat(param1, "\x01%t: \x03%t", "Bought", "UpgradepackExplosive");
					RemoveFlags();
					FakeClientCommand(param1, "give upgradepack_explosive");
					AddFlags();	
				}
				else if(StrEqual(item[param1], "give upgradepack_incendiary", false))
				{
					points[param1] -= cost[param1];
					PrintToChat(param1, "\x01%t: \x03%t", "Bought", "UpgradepackIncendiary");
					RemoveFlags();
					FakeClientCommand(param1, "give upgradepack_incendiary");
					AddFlags();	
					LastUpgrade[param1] = 1;
				}
				else if(StrEqual(item[param1], "upgrade_add EXPLOSIVE_AMMO", false))
				{
					if ( ((StrContains(class, "m60", false) != -1) || (StrContains(class, "grenade_launcher", false) != -1)) && (SurvFirearmsMaster[param1] <= 0) ) {
						PrintToChat(param1, "\x01Разрывные патроны на данный вид оружия доступен только для \x04мастера огнестрельного оружия");
						return;
					}
					
					if (SurvFirearmsMaster[param1] > 0) {
						RemoveFlags();
						FakeClientCommand(param1, "upgrade_add EXPLOSIVE_AMMO");
						AddFlags();	
						LastUpgrade[param1] = 2;
					}
					else {
						SurvUpgradeExplosive[param1]++;					
					}
					
					points[param1] -= cost[param1];
					PrintToChat(param1, "\x01%t: \x03%t", "Bought", "ExplosiveAmmo");
					
					
				}
				else if(StrEqual(item[param1], "upgrade_add INCENDIARY_AMMO", false))
				{
					if ( ((StrContains(class, "m60", false) != -1) || (StrContains(class, "grenade_launcher", false) != -1)) && (SurvFirearmsMaster[param1] <= 0) ) {
							PrintToChat(param1, "\x01Зажигательные патроны на данный вид оружия доступен только для \x04мастера огнестрельного оружия");
							return;
					}
					
					if (SurvFirearmsMaster[param1] > 0) {
						RemoveFlags();
						FakeClientCommand(param1, "upgrade_add INCENDIARY_AMMO");
						AddFlags();	
						LastUpgrade[param1] = 1;
					}
					else {
						SurvUpgradeIncendiary[param1]++;
					}
					
					points[param1] -= cost[param1];
					PrintToChat(param1, "\x01%t: \x03%t", "Bought", "IncendiaryAmmo");
					
				}
				else if(StrEqual(item[param1], "SurvSelfKill", false))
				{
					if ((!IsValidPlayer(param1)) || (GetClientTeam(param1) != 2)) return;
					
					if (IsClientIncapacitated(param1)) {
						PrintToChat(param1, "Вы сунули дуло пистолета в рот и плавно нажали на курок.");
						ForcePlayerSuicide(param1);
					}
					else
						PrintToChat(param1, "И зачем помирать здоровым, бегай давай и зомби пинай!");
				}
				else if (
				   (StrEqual(item[param1], "SurvMassSpeedUp", false)) 
				|| (StrEqual(item[param1], "SurvMassRegen", false))
				|| (StrEqual(item[param1], "SurvAutoMiniGun", false))
				|| (StrEqual(item[param1], "SurvZombieSurprize", false))
				|| (StrEqual(item[param1], "SurvUntouchable", false))
				|| (StrEqual(item[param1], "SurvPhysPower", false))
				|| (StrEqual(item[param1], "SurvVictimShield", false))
				)
				{
					SendPointsToBank(param1);
				}
				
			}
			else if (GetClientTeam(param1) == 3) {
				
				decl String:s_ModelName[64];
				new distance = GetDistance(param1, 800);
				decl Float:pos[3], Float:tpos[3];
				GetEntPropString(param1, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName));
					
				if (StrContains(item[param1], "witch") != -1)
				{
					if (!IsNormalAlt(param1)) {
						PrintToChat(param1, "\x04Вы слишком высоко, спуститесь ниже и попробуйте снова.");
						return;
					}
					//if (FloatCompare(distance, -1.0) != 0) {
					if (distance != -1) {
						PrintToChat(param1, "\x05%t.", "ToClose");
						return;
					}
				}
				
				//if (StrContains(item[param1], "one ") != -1) BuildBuyMenu11(param1);
				if (StrContains(item[param1], "mutant") != -1) BuildBuyMenu12(param1);
								
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "\x05%t %d/%d", "NotEnoughPoints", points[param1],cost[param1]);
					return;
				}
				
				if (AllowBuy[param1] == false) {
					PrintToChat(param1, "\x05%t.", "DeadWait");
					return;
				}
				
				if(StrEqual(item[param1], "suicide", false))
				{
					if(points[param1] < cost[param1]) return;
					if ((!IsValidPlayer(param1)) || (GetClientTeam(param1) != 3)) return;
					//SetEntData(param1, propinfoghost, 1);
					new Float:DeathTime = GetRandomFloat(2.0, 6.0);
					PrintToChat(param1, "Смерть через \x04%2.1f \x01секунд.", DeathTime);
					CreateTimer(DeathTime, ForceSuicideTimer, param1);
				}
				if((StrEqual(item[param1], "give health", false)) && (StrContains(s_ModelName, "hulk") == -1))
				{
					if(points[param1] < cost[param1]) return;
					if (IsPlayerSpawnGhost(param1) || (!IsPlayerAlive(param1))) {
						PrintToChat(param1, "\x05Нельзя вылечить призрака.");
					}
					SetEntityHealth(param1, OriginHealth[param1]);
					return;
				}
				if(StrEqual(item[param1], "z_spawn_old mob", false))
				{
					if(points[param1] < cost[param1]) return;
					ucommonleft += GetConVarInt(FindConVar("z_common_limit"));
				}	
				//if(StrEqual(item[param1], "z_spawn_old tank auto", false))
				//{
				//	if(points[param1] < cost[param1]) return;
				//	if(tanksspawned == GetConVarInt(TankLimit))
				//	{
				//		PrintToChat(param1, "[PS] Tank Limit Reached!");
				//		return;
				//	}	
				//	tanksspawned++;
				//}
				if(StrEqual(item[param1], "z_spawn_old witch", false) || StrEqual(item[param1], "z_spawn_old witch_bride", false))
				{
					if(points[param1] < cost[param1]) return;
					
					if (!WitchAllow) {
						PrintToChat(param1, "Запрещено, лимит 1 ведьма каждые 5 минут.");
						return;
					}
					WitchAllow = false;
					CreateTimer(360.0, WitchAllowReset, 0);
					
					if(witchsspawned == GetConVarInt(WitchLimit))
					{
						PrintToChat(param1, "[PS] Witch Limit Reached!");
						return;
					}
					witchsspawned++;
					
					PrintToChat(param1, "\x05%t: \x03%t", "Summon", "Witch");
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
					points[param1] -= cost[param1];
				}
				
				if (StrEqual(item[param1], "InfSpeedUp", false))
				{
					if ((GetClientTeam(param1) == 3) && (IsClientInGame(param1)) && (IsPlayerAlive(param1))) 
					{
						if (StrContains(s_ModelName, "hulk") != -1) {
							PrintToChat(param1, "\x05%t.", "TankRestrict");
							return;
						}
						
						if (InfSpeedUp[param1] > 0) {
							PrintToChat(param1, "\x05%t.", "AlreadyActive");
							return;
						}
						
						PrintToChat(param1,"\x04%t", "HulkSpeedUp");
						InfSpeedUp[param1] = 1;
						//SetEntDataFloat(param1, g_flLagMovement, 1.5, true);
						//CreateTimer(0.5, UpdateInfSpeedUp, param1);
						points[param1] -= cost[param1];
						
					}
					else PrintToChat(param1, "%t", "UnableSpeedUp");
					return;										
				}
				if (StrEqual(item[param1], "InfBonusDamage", false))
				{
					if (InfBonusDamage[param1] == 1) {
						PrintToChat(param1, "\x05%t.", "AlreadyActive");
						return;
					}
					
					PrintToChat(param1,"\x04%t", "ClawDamageBoost");
					InfBonusDamage[param1] = 1;
					points[param1] -= cost[param1];
										
					return;										
				}
				if (StrEqual(item[param1], "InfSpecialShield", false))
				{
					if (InfSpecialShield[param1] > 0) {
						PrintToChat(param1, "\x05%t.", "AlreadyActive");
						return;
					}
					if (IsPounced[param1] == 1) {
						PrintToChat(param1, "\x04Покупка в момент спец атаки запрещена.");
						return;
					}
					
					PrintToChat(param1,"\x04%t: \x03%t.", "Bought", "SpecialShield");
					InfSpecialShield[param1] = 5;
					points[param1] -= cost[param1];
										
					return;										
				}
				if (StrEqual(item[param1], "InfBonusHealth", false))
				{
					if (StrContains(s_ModelName, "hulk") != -1) {
						PrintToChat(param1, "\x05%t.", "TankRestrict");
						return;
					}
					if (InfBonusHealth[param1] == 1) {
						PrintToChat(param1, "\x05%t.", "AlreadyActive");
						return;
					}
					
					if (!IsPlayerSpawnGhost(param1)) {
						PrintToChat(param1, "%t.", "OnlyGhostHP");
						return;
					}
					
					PrintToChat(param1,"\x04%t: \x03%t.", "Activated", "BoostHP");
					InfBonusHealth[param1] = 1;
					points[param1] -= cost[param1];
										
					return;										
				}
				if (StrEqual(item[param1], "InfAcidClaws", false))
				{
					if (InfAcidClaws[param1] == 1) {
						PrintToChat(param1, "\x05%t.", "AlreadyActive");
						return;
					}
					PrintToChat(param1,"\x04%t: \x03%t.", "Activated", "AcidClaws");
					InfAcidClaws[param1] = 1;
					points[param1] -= cost[param1];
					
					return;										
				}
				if (StrEqual(item[param1], "InfFireShield", false))
				{
					if (StrContains(s_ModelName, "hulk") != -1) {
						PrintToChat(param1, "\x05%t.", "TankRestrict");
						return;
					}
					if (InfFireShield[param1] == 1) {
						PrintToChat(param1, "\x05%t.", "AlreadyActive");
						return;
					}
					PrintToChat(param1, "\x04%t: \x03%t.", "Activated", "FireShield");
					InfFireShield[param1] = 1;
					points[param1] -= cost[param1];
					ExtinguishEntity(param1);
					return;										
				}
				if (StrEqual(item[param1], "InfMask", false))
				{
					if (StrContains(s_ModelName, "hulk") != -1) {
						PrintToChat(param1, "\x05%t.", "TankRestrict");
						return;
					}
					if (InfMask[param1] == 1) {
						PrintToChat(param1, "\x05%t.", "AlreadyActive");
						return;
					}
					PrintToChat(param1,"\x04%t: \x03%t.", "Activated", "Mask");
					InfMask[param1] = 1;
					if ((IsPlayerAlive(param1)) && (!IsPlayerSpawnGhost(param1))) {
						SetEntityRenderMode(param1, RENDER_TRANSCOLOR);
						SetEntityRenderColor(param1, 190, 190, 255, 120);
					}
					
					points[param1] -= cost[param1];
					
					return;										
				}
				if (StrEqual(item[param1], "InfMeeleShield", false))
				{
					if (InfMeeleShield[param1] == 1) {
						PrintToChat(param1, "\x05%t.", "AlreadyActive");
						return;
					}
					PrintToChat(param1,"\x04%t: \x03%t.", "Activated", "MeleeShield");
					InfMeeleShield[param1] = 1;
					points[param1] -= cost[param1];
					return;										
				}
				if (StrEqual(item[param1], "InfRegen", false))
				{
					if (InfRegen[param1] == 1) {
						PrintToChat(param1, "\x05%t.", "AlreadyActive");
						return;
					}
					PrintToChat(param1,"\x04%t: \x03%t.", "Activated", "Regen");
					InfRegen[param1] = 1;
					points[param1] -= cost[param1];
					return;										
				}
				if (StrEqual(item[param1], "director_force_panic_event", false)) {
					PrintToChat(param1, "\x05%t", "Horde");
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
					points[param1] -= cost[param1];
				}
				if (StrEqual(item[param1], "riot", false)) {
					PrintToChat(param1, "\x01%t: \x03Riot Cop", "Horde");
					ServerCommand("sm_spawnuncommonhorde riot");
					points[param1] -= cost[param1];
				}
				if (StrEqual(item[param1], "ceda", false)) {
					PrintToChat(param1, "\x01%t: \x03Ceda", "Horde");
					ServerCommand("sm_spawnuncommonhorde ceda");
					points[param1] -= cost[param1];
				}
				if (StrEqual(item[param1], "clown", false)) {
					PrintToChat(param1, "\x01%t: \x03Clown", "Horde");
					ServerCommand("sm_spawnuncommonhorde clown");
					points[param1] -= cost[param1];
				}
				if (StrEqual(item[param1], "mud", false)) {
					PrintToChat(param1, "\x01%t: \x03Mud", "Horde");
					ServerCommand("sm_spawnuncommonhorde mud");
					points[param1] -= cost[param1];
				}
				if (StrEqual(item[param1], "roadcrew", false)) {
					PrintToChat(param1, "\x01%t: \x03Roadcrew", "Horde");
					ServerCommand("sm_spawnuncommonhorde roadcrew");
					points[param1] -= cost[param1];
				}
				if (StrEqual(item[param1], "jimmy", false)) {
					PrintToChat(param1, "\x01%t: \x03Jimmy", "Horde");
					ServerCommand("sm_spawnuncommonhorde jimmy");
					points[param1] -= cost[param1];
				}
				if (StrEqual(item[param1], "fallen", false)) {
					PrintToChat(param1, "\x01%t \x03Fallen", "Horde");
					ServerCommand("sm_spawnuncommonhorde fallen");
					points[param1] -= cost[param1];
				}
				if (StrEqual(item[param1], "hulk", false)) {
//					decl Float:pos[3], Float:tpos[3];
					
					if (InfHulk[param1] > 0) return;
					
					if (GetTankCount() > 0) {
						PrintToChat(param1, "\x04[sync] \x01%t.", "HulkRestrict");
						return;
					}
					
					if (!IsPlayerGhost(param1)) {
						PrintToChat(param1, "\x04[sync] \x01%t.", "YouMustAlive");
						return;
					}
					
					if (!IsNormalAlt(param1)) {
						PrintToChat(param1, "\x04Вы слишком высоко, спуститесь ниже и попробуйте снова.");
						return;
					}
					
					if (GetDistance(param1, 1000) != -1) {
						PrintToChat(param1,"\x05%t.", "ToClose");
						return;
					}
					/*
					GetClientAbsOrigin(param1, pos);
					new Float:flMaxDistance = 1000;
					
					for(new i=1; i<=GetMaxClients(); i++) {
						if (IsNormalPlayer(i)) {
							if (GetClientTeam(i) == 2) {
								GetClientAbsOrigin(i, tpos);
								distance = GetVectorDistance(pos, tpos);
								if (FloatCompare(distance, flMaxDistance) == -1) {
									PrintToChat(param1,"\x05%t.", "ToClose");
									return;
								}								
							}	
						}
					}
					*/					
					if (!HulkAllow) {
						PrintToChat(param1, "\x01%t \x04%t \x01%t", "hulklimit1", "tank", "hulklimit2");
						return;
					}
					HulkAllow = false;
					if (HulkResetTimer != INVALID_HANDLE) KillTimer(HulkResetTimer);
					HulkResetTimer = CreateTimer(300.0, HulkAllowResetTimer);
					
					PrintToChat(param1, "\x05%t", "HulkSummon");
					
					InfHulk[param1] = 1;
					points[param1] -= cost[param1];
											
					SpawnTank(param1);
										
					new iEntid = GetEntDataEnt2(param1,g_iAbilityO);
					if (iEntid == -1) return;
					SetEntDataFloat(iEntid, g_iNextActO+8, GetGameTime() + 10000.0, true);
								
					PrintToChat(param1,"\x05%t.", "HulkSpeedUp");
					CreateTimer(0.5, UpdateInfSpeedUp, param1);				
					//FrustrationReset[param1] = 2;
					//CreateTimer(0.5, ResetFrustration, param1);				
				}
				if (StrEqual(item[param1], "InfAntiYell", false))
				{
					if (InfAntiYell[param1] >= 1) {
						PrintToChat(param1, "\x05%t.", "AlreadyActive");
						return;
					}
					
					PrintToChat(param1,"\x01%t \x04%t", "Activated", "AntiYell");
					InfAntiYell[param1]++;
					points[param1] -= cost[param1];
					
					return;										
				}
				if (StrEqual(item[param1], "one riot", false)) {
					PrintToChat(param1, "\x01%t: \x03Riot Cop", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_spawnuncommon riot", 10);
					AddFlags();
					//ServerCommand("sm_spawnuncommon riot");
					points[param1] -= cost[param1];
					BuildBuyMenu11(param1);
				}
				if (StrEqual(item[param1], "one ceda", false)) {
					PrintToChat(param1, "\x01%t: \x03Ceda", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_spawnuncommon ceda", 10);
					AddFlags();
					//ServerCommand("sm_spawnuncommon ceda");
					points[param1] -= cost[param1];
					BuildBuyMenu11(param1);
				}
				if (StrEqual(item[param1], "one clown", false)) {
					PrintToChat(param1, "\x01%t: \x03Clown", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_spawnuncommon clown", 10);
					AddFlags();
					//ServerCommand("sm_spawnuncommon clown");
					points[param1] -= cost[param1];
					BuildBuyMenu11(param1);
				}
				if (StrEqual(item[param1], "one mud", false)) {
					PrintToChat(param1, "\x01%t: \x03Mud", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_spawnuncommon mud", 10);
					AddFlags();
					//ServerCommand("sm_spawnuncommon mud");
					points[param1] -= cost[param1];
					BuildBuyMenu11(param1);
				}
				if (StrEqual(item[param1], "one roadcrew", false)) {
					PrintToChat(param1, "\x01%t: \x03Roadcrew", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_spawnuncommon roadcrew", 10);
					AddFlags();
					//ServerCommand("sm_spawnuncommon roadcrew");
					points[param1] -= cost[param1];
					BuildBuyMenu11(param1);
				}
				if (StrEqual(item[param1], "one jimmy", false)) {
					PrintToChat(param1, "\x01%t: \x03Jimmy", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_spawnuncommon jimmy", 10);
					AddFlags();
					//ServerCommand("sm_spawnuncommon jimmy");
					points[param1] -= cost[param1];
					BuildBuyMenu11(param1);
				}
				if (StrEqual(item[param1], "one fallen", false)) {
					PrintToChat(param1, "\x01%t \x03Fallen", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_spawnuncommon fallen", 10);
					AddFlags();
					//ServerCommand("sm_spawnuncommon fallen");
					points[param1] -= cost[param1];
					BuildBuyMenu11(param1);
				}
				if (StrEqual(item[param1], "mutantbomb", false)) {
					PrintToChat(param1, "\x01%t: \x03Mutant-Bomb", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_mutantbomb", 10);
					AddFlags();					
					points[param1] -= cost[param1];
					BuildBuyMenu12(param1);
				}
				if (StrEqual(item[param1], "mutantfire", false)) {
					PrintToChat(param1, "\x01%t: \x03Mutant-Fire", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_mutantfire", 10);
					AddFlags();					
					points[param1] -= cost[param1];
					BuildBuyMenu12(param1);
				}
				if (StrEqual(item[param1], "mutantghost", false)) {
					PrintToChat(param1, "\x01%t: \x03Mutant-Ghost", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_mutantghost", 10);
					AddFlags();					
					points[param1] -= cost[param1];
					BuildBuyMenu12(param1);
				}
				if (StrEqual(item[param1], "mutantmind", false)) {
					PrintToChat(param1, "\x01%t: \x03Mutant-Mind", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_mutantmind", 10);
					AddFlags();					
					points[param1] -= cost[param1];
					BuildBuyMenu12(param1);
				}
				if (StrEqual(item[param1], "mutantsmoke", false)) {
					PrintToChat(param1, "\x01%t: \x03Mutant-Smoke", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_mutantsmoke", 10);
					AddFlags();					
					points[param1] -= cost[param1];
					BuildBuyMenu12(param1);
				}
				if (StrEqual(item[param1], "mutantspit", false)) {
					PrintToChat(param1, "\x01%t: \x03Mutant-Spit", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_mutantspit", 10);
					AddFlags();					
					points[param1] -= cost[param1];
					BuildBuyMenu12(param1);
				}
				if (StrEqual(item[param1], "mutanttesla", false)) {
					PrintToChat(param1, "\x01%t: \x03Mutant-Tesla", "Common");
					RemoveFlags();
					MultiClientCmd(param1, "sm_mutanttesla", 10);
					AddFlags();					
					points[param1] -= cost[param1];
					BuildBuyMenu12(param1);
				}
				if ((StrEqual(item[param1], "InfMassSlow", false))
				|| (StrEqual(item[param1], "InfTankChaos", false))
				|| (StrEqual(item[param1], "InfDeathCloud", false))
				|| (StrEqual(item[param1], "InfZombieApoc", false))
				|| (StrEqual(item[param1], "InfPoison", false))
				|| (StrEqual(item[param1], "InfBummerRain", false))
				|| (StrEqual(item[param1], "InfMassArmor", false))
				)
				{
					SendPointsToBank(param1);
				}
				
			}
}

public SetBuyParams(any:param1, String:CMD[192])
{
	if ((IsEnd()) || (MapEnd > 0)) return Plugin_Handled;
		
		item[param1] = "none";
		cost[param1] = 0;
		
		if (GetClientTeam(param1) == 2) {
			if(StrEqual(CMD, "BuildBuyMenu2", false))
			{
				BuildBuyMenu2(param1);
				return;
			}
			else if(StrEqual(CMD, "BuildBuyMenu3", false))
			{
				BuildBuyMenu3(param1);
				return;
			}
			else if(StrEqual(CMD, "BuildBuyMenu4", false))
			{
				BuildBuyMenu4(param1);
				return;
			}
			else if (StrEqual(CMD, "SurvSendPoints", false))
			{
				if (points[param1] < 10) {
					PrintToChat(param1, "%t.", "NotEnoughPoints");
					return;
				}
				
				decl String:Title[MAX_LINE_WIDTH];
				Format(Title, sizeof(Title), "%t:", "WhomSend");
				new Handle:menu = CreateMenu(SendPointsHandler);

				SetMenuTitle(menu, Title);
				SetMenuExitBackButton(menu, false);
				
				decl String:text[255];
				decl String:id[10];

				for (new i = 1; i <= GetMaxClients(); i++) {
				if (IsValidPlayer(i)) 
					if ((GetClientTeam(i) == 2) && (i != param1)) 					
					{
						Format(text,sizeof(text),"%s", GetName(i));
						Format(id,sizeof(id),"%i",i);
						AddMenuItem(menu, id, text);
					}
				}	

				DisplayMenu(menu, param1, 60);
				return;
			}		
			else if(StrEqual(CMD, "SurvFirearmsMaster", false))
			{
				item[param1] = "SurvFirearmsMaster";
				cost[param1] = SurvFirearmsMaster_Cost;
			}
			else if(StrEqual(CMD, "SurvSpeedUp", false))
			{
				item[param1] = "SurvSpeedUp";
				cost[param1] = SurvSpeedUp_Cost;
			}
			else if(StrEqual(CMD, "SurvSpecialShield", false))
			{
				item[param1] = "SurvSpecialShield";
				cost[param1] = SurvSpecialShield_Cost;
			}
			else if(StrEqual(CMD, "SurvVampire", false))
			{
				item[param1] = "SurvVampire";
				cost[param1] = SurvVampire_Cost;
			}
			else if(StrEqual(CMD, "SurvShoving", false))
			{
				item[param1] = "SurvShoving";
				cost[param1] = SurvShoving_Cost;
			}
			else if(StrEqual(CMD, "SurvLaser", false))
			{
				item[param1] = "SurvLaser";
				cost[param1] = SurvLaser_Cost;
			}
			else if(StrEqual(CMD, "GasCan", false))
			{
				item[param1] = "GasCan";
				cost[param1] = SurvGasCan_Cost;
			}
			else if(StrEqual(CMD, "SurvMeleeMaster", false))
			{
				item[param1] = "SurvMeleeMaster";
				cost[param1] = SurvMeleeMaster_Cost;
			}
			else if(StrEqual(CMD, "SurvRevenge", false))
			{
				item[param1] = "SurvRevenge";
				cost[param1] = SurvRevenge_Cost;
			}
			else if(StrEqual(CMD, "SurvHealthConvert", false))
			{
				item[param1] = "SurvHealthConvert";
				cost[param1] = SurvHealthConvert_Cost;
			}
			else if(StrEqual(CMD, "SurvIncSpecialShield", false))
			{
				item[param1] = "SurvIncSpecialShield";
				cost[param1] = SurvIncSpecialShield_Cost;
			}
			else if(StrEqual(CMD, "SurvGift", false))
			{
				item[param1] = "SurvGift";
				cost[param1] = SurvGift_Cost;
			}
			else if(StrEqual(CMD, "SurvAWP", false))
			{
				item[param1] = "SurvAWP";
				cost[param1] = SurvAWP_Cost;
			}
			else if(StrEqual(CMD, "SurvM60", false))
			{
				item[param1] = "SurvM60";
				cost[param1] = SurvM60_Cost;
			}
			else if(StrEqual(CMD, "SurvGL", false))
			{
				item[param1] = "SurvGL";
				cost[param1] = SurvGL_Cost;
			}
			else if(StrEqual(CMD, "SurvFireYell", false))
			{
				item[param1] = "SurvFireYell";
				cost[param1] = SurvFireYell_Cost;
			}
			else if(StrEqual(CMD, "SurvPowerYell", false))
			{
				item[param1] = "SurvPowerYell";
				cost[param1] = SurvPowerYell_Cost;
			}
			else if(StrEqual(CMD, "SurvBerserker", false))
			{
				item[param1] = "SurvBerserker";
				cost[param1] = SurvBerserker_Cost;
			}
			if(StrEqual(CMD, "upgradepack_explosive", false))
			{
				item[param1] = "give upgradepack_explosive";
				if (SurvFirearmsMaster[param1] > 0) cost[param1] = SurvExplosiveAmmo_Cost - 20;
				else cost[param1] = SurvExplosiveAmmo_Cost;
			}
			else if(StrEqual(CMD, "upgradepack_incendiary", false))
			{
				item[param1] = "give upgradepack_incendiary";
				if (SurvFirearmsMaster[param1] > 0)  cost[param1] = SurvIncendiaryAmmo_Cost - 20;
				else cost[param1] = SurvIncendiaryAmmo_Cost;
			}
			else if(StrEqual(CMD, "explosive_ammo", false))
			{
				item[param1] = "upgrade_add EXPLOSIVE_AMMO";
				if (SurvFirearmsMaster[param1] > 0) cost[param1] = SurvUpgradeExplosive_Cost - 20;
				else cost[param1] = SurvUpgradeExplosive_Cost;
			}
			else if(StrEqual(CMD, "incendiary_ammo", false))
			{
				item[param1] = "upgrade_add INCENDIARY_AMMO";
				if (SurvFirearmsMaster[param1] > 0) cost[param1] = SurvUpgradeIncendiary_Cost - 20;
				else cost[param1] = SurvUpgradeIncendiary_Cost;
			}
			else if(StrEqual(CMD, "SurvMassSpeedUp", false))
			{
				item[param1] = "SurvMassSpeedUp";
				cost[param1] = 0;
			}
			else if(StrEqual(CMD, "SurvMassRegen", false))
			{
				item[param1] = "SurvMassRegen";
				cost[param1] = 0;
			}
			else if(StrEqual(CMD, "SurvAutoMiniGun", false))
			{
				item[param1] = "SurvAutoMiniGun";
				cost[param1] = 0;
			}
			else if(StrEqual(CMD, "SurvZombieSurprize", false))
			{
				item[param1] = "SurvZombieSurprize";
				cost[param1] = 0;
			}
			else if(StrEqual(CMD, "SurvUntouchable", false))
			{
				item[param1] = "SurvUntouchable";
				cost[param1] = 0;
			}
			else if(StrEqual(CMD, "SurvPhysPower", false))
			{
				item[param1] = "SurvPhysPower";
				cost[param1] = 0;
			}
			else if(StrEqual(CMD, "SurvVictimShield", false))
			{
				item[param1] = "SurvVictimShield";
				cost[param1] = 0;
			}
			else if(StrEqual(CMD, "SurvSelfKill", false))
			{
				item[param1] = "SurvSelfKill";
				cost[param1] = 0;
			}
		}
		else if (GetClientTeam(param1) == 3) {
			if(StrEqual(CMD, "BuildBuyMenu10", false))
			{
				BuildBuyMenu10(param1);
				return;
			}
			if(StrEqual(CMD, "BuildBuyMenu11", false))
			{
				BuildBuyMenu11(param1);
				return;
			}
			if(StrEqual(CMD, "BuildBuyMenu6", false))
			{
				BuildBuyMenu6(param1);
				return;
			}
			else if(StrEqual(CMD, "BuildBuyMenu7", false))
			{
				BuildBuyMenu7(param1);
				return;
			}
			else if(StrEqual(CMD, "BuildBuyMenu8", false))
			{
				BuildBuyMenu8(param1);
				return;
			}
			else if(StrEqual(CMD, "BuildBuyMenu9", false))
			{
				PrintToChat(param1, "пока не работает, в процессе разработки");
				return;
			}
			else if (StrEqual(CMD, "InfSendPoints", false))
			{
				if (points[param1] < 10) {
					PrintToChat(param1, "%t.", "NotEnoughPoints");
					return;
				}
			
				decl String:Title[MAX_LINE_WIDTH];
				Format(Title, sizeof(Title), "%t:", "Whom");
				new Handle:menu = CreateMenu(SendPointsHandler);

				SetMenuTitle(menu, Title);
				SetMenuExitBackButton(menu, false);
				SetMenuExitButton(menu, true);

				decl String:text[255];
				decl String:id[10];

				for (new i = 1; i <= GetMaxClients(); i++) {
				if (IsValidPlayer(i)) 
					if ((GetClientTeam(i) == 3) && (i != param1)) 					
					{
						Format(text,sizeof(text),"%s", GetName(i));
						Format(id,sizeof(id),"%i",i);
						AddMenuItem(menu, id, text);
					}
				}	

				DisplayMenu(menu, param1, 60);
				return;
			}		
			else if (StrEqual(CMD, "suicide", false))
			{
				item[param1] = "suicide";
				cost[param1] = 0;
			}		
			else if (StrEqual(CMD, "InfSpeedUp", false))
			{
				item[param1] = "InfSpeedUp";
				cost[param1] = InfSpeedUp_Cost;
			}
			else if (StrEqual(CMD, "InfBonusDamage", false))
			{
				item[param1] = "InfBonusDamage";
				if (IsTank(param1)) cost[param1] = 60; else cost[param1] = InfBonusDamage_Cost;
			}			
			else if (StrEqual(CMD, "InfSpecialShield", false))
			{
				item[param1] = "InfSpecialShield";
				cost[param1] = InfSpecialShield_Cost;
			}			
			else if (StrEqual(CMD, "InfBonusHealth", false))
			{
				item[param1] = "InfBonusHealth";
				cost[param1] = InfBonusHealth_Cost;
			}			
			else if (StrEqual(CMD, "InfAcidClaws", false))
			{
				item[param1] = "InfAcidClaws";
				if (IsTank(param1)) cost[param1] = 60; else cost[param1] = InfAcidClaws_Cost;
			}			
			else if (StrEqual(CMD, "InfFireShield", false))
			{
				item[param1] = "InfFireShield";
				cost[param1] = InfFireShield_Cost;
			}			
			else if (StrEqual(CMD, "InfMask", false))
			{
				item[param1] = "InfMask";
				cost[param1] = InfMask_Cost;
			}			
			else if (StrEqual(CMD, "InfMeeleShield", false))
			{
				item[param1] = "InfMeeleShield";
				if (IsTank(param1)) cost[param1] = 50; else cost[param1] = InfMeeleShield_Cost;
			}			
			else if (StrEqual(CMD, "InfRegen", false))
			{
				item[param1] = "InfRegen";
				if (IsTank(param1)) cost[param1] = 100; else cost[param1] = InfRegen_Cost;
			}			
			else if (StrEqual(CMD, "witch", false))
			{
				item[param1] = "z_spawn_old witch";
				cost[param1] = GetConVarInt(PointsWitch);
			}
			else if (StrEqual(CMD, "witch_bride", false))
			{
				item[param1] = "z_spawn_old witch_bride";
				cost[param1] = GetConVarInt(PointsWitch);
			}
			else if (StrEqual(CMD, "horde", false))
			{
				item[param1] = "director_force_panic_event";
				cost[param1] = GetConVarInt(PointsHorde);
			}
			else if (StrEqual(CMD, "riot", false))
			{
				item[param1] = "riot";
				cost[param1] = InfRiot_Cost;
			}
			else if (StrEqual(CMD, "ceda", false))
			{
				item[param1] = "ceda";
				cost[param1] = InfCeda_Cost;
			}
			else if (StrEqual(CMD, "clown", false))
			{
				item[param1] = "clown";
				cost[param1] = InfClown_Cost;
			}
			else if (StrEqual(CMD, "mud", false))
			{
				item[param1] = "mud";
				cost[param1] = InfMudman_Cost;
			}
			else if (StrEqual(CMD, "roadcrew", false))
			{
				item[param1] = "roadcrew";
				cost[param1] = InfRoadcrew_Cost;
			}
			else if (StrEqual(CMD, "jimmy", false))
			{
				item[param1] = "jimmy";
				cost[param1] = InfJimmy_Cost;
			}
			else if (StrEqual(CMD, "fallen", false))
			{
				item[param1] = "fallen";
				cost[param1] = InfFallen_Cost;
			}
			
			else if (StrEqual(CMD, "hulk", false))
			{
				item[param1] = "hulk";
				cost[param1] = InfHulk_Cost;
			}
			else if (StrEqual(CMD, "hobbits", false))
			{
				item[param1] = "hobbits";
				cost[param1] = InfHobbits_Cost;
			}
			else if (StrEqual(CMD, "InfMassSlow", false))
			{
				item[param1] = "InfMassSlow";
				cost[param1] = 0;
			}
			else if (StrEqual(CMD, "InfMassArmor", false))
			{
				item[param1] = "InfMassArmor";
				cost[param1] = 0;
			}
			else if (StrEqual(CMD, "InfTankChaos", false))
			{
				item[param1] = "InfTankChaos";
				cost[param1] = 0;
			}
			else if (StrEqual(CMD, "InfDeathCloud", false))
			{
				item[param1] = "InfDeathCloud";
				cost[param1] = 0;
			}
			else if (StrEqual(CMD, "InfZombieApoc", false))
			{
				item[param1] = "InfZombieApoc";
				cost[param1] = 0;
			}
			else if (StrEqual(CMD, "InfPoison", false))
			{
				item[param1] = "InfPoison";
				cost[param1] = 0;
			}
			else if (StrEqual(CMD, "InfBummerRain", false))
			{
				item[param1] = "InfBummerRain";
				cost[param1] = 0;
			}
			else if (StrEqual(CMD, "InfAntiYell", false))
			{
				item[param1] = "InfAntiYell";
				cost[param1] = InfAntiYell_Cost;
			}
			else if (StrEqual(CMD, "one riot", false))
			{
				item[param1] = "one riot";
				cost[param1] = InfOneRiot_Cost;
			}
			else if (StrEqual(CMD, "one ceda", false))
			{
				item[param1] = "one ceda";
				cost[param1] = InfOneCeda_Cost;
			}
			else if (StrEqual(CMD, "one clown", false))
			{
				item[param1] = "one clown";
				cost[param1] = InfOneClown_Cost;
			}
			else if (StrEqual(CMD, "one mud", false))
			{
				item[param1] = "one mud";
				cost[param1] = InfOneMudman_Cost;
			}
			else if (StrEqual(CMD, "one roadcrew", false))
			{
				item[param1] = "one roadcrew";
				cost[param1] = InfOneRoadcrew_Cost;
			}
			else if (StrEqual(CMD, "one jimmy", false))
			{
				item[param1] = "one jimmy";
				cost[param1] = InfOneJimmy_Cost;
			}
			else if (StrEqual(CMD, "one fallen", false))
			{
				item[param1] = "one fallen";
				cost[param1] = InfOneFallen_Cost;
			}
			else if (StrEqual(CMD, "mutantbomb", false))
			{
				item[param1] = "mutantbomb";
				cost[param1] = InfMutantBomb_Cost;
			}
			else if (StrEqual(CMD, "mutantfire", false))
			{
				item[param1] = "mutantfire";
				cost[param1] = InfMutantFire_Cost;
			}
			else if (StrEqual(CMD, "mutantghost", false))
			{
				item[param1] = "mutantghost";
				cost[param1] = InfMutantGhost_Cost;
			}
			else if (StrEqual(CMD, "mutantmind", false))
			{
				item[param1] = "mutantmind";
				cost[param1] = InfMutantMind_Cost;
			}
			else if (StrEqual(CMD, "mutantsmoke", false))
			{
				item[param1] = "mutantsmoke";
				cost[param1] = InfMutantSmoke_Cost;
			}
			else if (StrEqual(CMD, "mutantspit", false))
			{
				item[param1] = "mutantspit";
				cost[param1] = InfMutantSpit_Cost;
			}
			else if (StrEqual(CMD, "mutanttesla", false))
			{
				item[param1] = "mutanttesla";
				cost[param1] = InfMutantTesla_Cost;
			}
		}
	
}

stock EmitYell(client)
{
	decl String:model[256];
	GetClientModel(client, model, sizeof(model));
	
	if (!IsValidPlayer(client)) return;
	
	if (GetClientTeam(client) == 2) {
	
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLNICK_1, client);
			case 2:
			EmitSoundToAll(YELLNICK_2, client);
			case 3:
			EmitSoundToAll(YELLNICK_3, client);
		}
	}
	else if (GetClientTeam(client) == 3) {
	  //крики для трупов в будущем	
	}
}

ShowEffect(client)
{
	if (IsEnd()) return;
	if (!IsValidPlayer(client)) return;
	
	//Userid for targetting
	new userid = GetClientUserId(client);
	
	decl Float:pos[3], String:sName[64], String:sTargetName[64];
	if (g_iEffect[client] > 0) return;
	g_iEffect[client] = CreateEntityByName("info_particle_system");
	new Particle = g_iEffect[client];
	
	GetClientAbsOrigin(client, pos);
	TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
	
	Format(sName, sizeof(sName), "%d", userid+25);
	DispatchKeyValue(client, "targetname", sName);
	GetEntPropString(client, Prop_Data, "m_iName", sName, sizeof(sName));
	
	Format(sTargetName, sizeof(sTargetName), "%d", userid+1000);
	
	DispatchKeyValue(Particle, "targetname", sTargetName);
	DispatchKeyValue(Particle, "parentname", sName);
	if(GetClientTeam(client) == 2)
	{
		DispatchKeyValue(Particle, "effect_name", EFFECT_PARTICLE_SURVIVOR);
	}
	else if(GetClientTeam(client) == 3)
	{
		DispatchKeyValue(Particle, "effect_name", EFFECT_PARTICLE_INFECTED);
	}
	
	DispatchSpawn(Particle);

	//Parent:		
	SetVariantString(sName);
	AcceptEntityInput(Particle, "SetParent", Particle, Particle);
	ActivateEntity(Particle);
	AcceptEntityInput(Particle, "start");
	
	//CreateTimer(1.0, timerEndEffect, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, timerEndEffect, client);

}

public Action:timerEndEffect(Handle:timer, any:client)
{
	//new god = 0;
	
    //if (IsValidPlayer(client)) {
	//	if (GetEntProp(client, Prop_Data, "m_takedamage") == 0) 
	//		god = 1;
	//}
	
	//if ((god == 0) || (IsEnd()) || (!IsPlayerAlive(client)) || (GetEntProp(client, Prop_Send, "m_isGhost") == 1))
	//{
		if (IsValidEntity(g_iEffect[client])) {
			AcceptEntityInput(g_iEffect[client], "Stop");
			//RemoveEdict(g_iEffect[client]);
			AcceptEntityInput(g_iEffect[client], "Kill");
		}
		//if (timer != INVALID_HANDLER) CloseHandle(timer);
		g_iEffect[client] = 0;
		return Plugin_Stop;
	//}
	
    //if (IsValidEntity(g_iEffect[client]))
//		AcceptEntityInput(g_iEffect[client], "Start");
		
	//if ((!IsEnd()) && (IsValidPlayer(client))) CreateTimer(1.0, timerEndEffect, client);
	//return Plugin_Continue;
}

public ColorClient(any:client)
{
	ServerCommand("sm_color #%i 0 0 0 255",GetClientUserId(client));
}

public cmd_showadmins()
{
	new AdminsCount = 0;
	decl String:admins[255] = "";
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (IsAdmin(i))) {
			new AdminId:id = GetUserAdmin(i);
			AdminsCount++;
			Format(admins,sizeof(admins),"%s \x05%s\x01(rank:\x03%i \x01lvl:\x03%i\x01)",admins,GetName(i),ClientRank[i],GetAdminImmunityLevel(id));
		}
		
	}
	PrintToChatAll("\x04%t %s", "admins", admins);
}

bool:IsAdmin(client)
{
	// Checks valid player
	if (!IsValidPlayer (client))
		return false;
	
	// Gets the admin id
	new AdminId:id = GetUserAdmin(client);
	
	// If player is not admin ...
	if (id == INVALID_ADMIN_ID)
		return false;
	
	if (GetAdminFlag(id, Admin_Root)||GetAdminFlag(id, Admin_Kick))
		return true;
	else
	return false;
}

public Action:CreateParticle(target, String:particlename[], Float:time, Float:origin)
{
	if (target > 0)
	{
   		new particle = CreateEntityByName("info_particle_system");
    	if (IsValidEntity(particle))
    	{
        	new Float:pos[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
			pos[2] += origin;
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(particle, "effect_name", particlename);
			DispatchKeyValue(particle, "targetname", "particle");
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
		}
    }
}

public Action:AttachParticle(target, String:particlename[], Float:time, Float:origin)
{
	if (target > 0 && IsValidEntity(target))
	{
   		new particle = CreateEntityByName("info_particle_system");
    	if (IsValidEntity(particle)) {
        	new Float:pos[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
			pos[2] += origin;
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			decl String:tName[64];
			Format(tName, sizeof(tName), "Attach%d", target);
			DispatchKeyValue(target, "targetname", tName);
			GetEntPropString(target, Prop_Data, "m_iName", tName, sizeof(tName));
			DispatchKeyValue(particle, "scale", "");
			DispatchKeyValue(particle, "effect_name", particlename);
			DispatchKeyValue(particle, "parentname", tName);
			DispatchKeyValue(particle, "targetname", "particle");
			DispatchSpawn(particle);
			ActivateEntity(particle);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", particle, particle);
			AcceptEntityInput(particle, "Enable");
			AcceptEntityInput(particle, "start");
			CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
		}
    }
}
public Action:PrecacheParticle(String:particlename[])
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.1, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	}  
}
public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
	{				
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
            		AcceptEntityInput(particle, "Kill");
	}
}

stock bool:GetTankCount()
{
	new TCount = 0;
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsNormalPlayer(i))
			if (GetClientTeam(i) == 3)
				if (IsTank(i)) TCount++;
	}
	return TCount;  
}

stock bool:IsTank(i)
{
	if (IsNormalPlayer(i)) {
		if	(GetClientTeam(i) == 3) {
			decl String: classname[32];
			GetClientModel(i, classname, sizeof(classname));
			if (StrContains(classname, "hulk", false) != -1)
				return true;
			return false;
		}
	}
	return false;
}

stock bool:IsWitch(i)
{
	if (IsValidEdict(i)) {
			decl String: classname[32];
			GetClientModel(i, classname, sizeof(classname));
			if (StrContains(classname, "hulk", false) != -1)
				return true;
			return false;
	}
	return false;
}

public SendPointsFinaleHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE) return;
	if (action == MenuAction_End) {
		
		CloseHandle(menu);
	}
	if (action != MenuAction_Select || param1 <= 0 || (!IsValidPlayer(param1))) {
		
		return;
	}

	decl String:Info[255];
	new bool:found = GetMenuItem(menu, param2, Info, sizeof(Info));
	
	if (!found) return;
	
	PointsValue[param1] = StringToInt(Info);
	
	if ( (!IsValidPlayer(param1)) || (!IsValidPlayer(ToClient[param1])) ) return;
	
	PrintToChatAll("\x03%s \x01%t \x05%d \x01%t \x05%s ", GetName(param1), "send1", PointsValue[param1], "send2", GetName(ToClient[param1]));
	
	if (points[param1] >= PointsValue[param1]) {
		points[ToClient[param1]] +=  PointsValue[param1];
		points[param1] -= PointsValue[param1];
		//PrintToChat(ToClient[param1], "\x01%t\x05%d \x01 %t \x03%s", "receive1", PointsValue[param1], "receive2", GetName(param1));
	}
}

		
public BuildBuyMenu6(any:client)
{
	if (!IsValidPlayer(client)) return;
		decl String:text[40];
		decl String:title[40];
		
		SetGlobalTransTarget(client);
		
		new Handle:menu = CreateMenu(InfectedMenu);
		new CCost = 0;
		
		if (InfSpeedUp[client] > 0) Format(text, sizeof(text), "[A]%t (%i)", "SpeedUp", InfSpeedUp_Cost);
		else Format(text, sizeof(text), "%t (%i)", "SpeedUp", InfSpeedUp_Cost);
		
		if (!IsTank(client)) AddMenuItem(menu, "InfSpeedUp", text);
		
		if (IsTank(client)) CCost = 60; else CCost = InfBonusDamage_Cost;
		if (InfBonusDamage[client] > 0) Format(text, sizeof(text), "[A]%t (%i)", "ClawDamageBoost", CCost);
		else Format(text, sizeof(text), "%t (%i)", "ClawDamageBoost", CCost);
		AddMenuItem(menu, "InfBonusDamage", text);
		
		if (InfSpecialShield[client] > 0) Format(text, sizeof(text), "[A]%t (%i)", "SpecialShield", InfSpecialShield_Cost);
		else Format(text, sizeof(text), "%t (%i)", "SpecialShield", InfSpecialShield_Cost);
		if (!IsTank(client)) AddMenuItem(menu, "InfSpecialShield", text);
		
		if (InfBonusHealth[client] > 0) Format(text, sizeof(text), "[A]%t (%i)", "BoostHP", InfBonusHealth_Cost);
		else Format(text, sizeof(text), "%t (%i)", "BoostHP", InfBonusHealth_Cost);
		if (!IsTank(client)) AddMenuItem(menu, "InfBonusHealth", text);
		
		if (IsTank(client)) CCost = 60; else CCost = InfAcidClaws_Cost;
		if (InfAcidClaws[client] > 0) Format(text, sizeof(text), "[A]%t (%i)", "AcidClaws", CCost);
		else Format(text, sizeof(text), "%t (%i)", "AcidClaws", CCost);
		AddMenuItem(menu, "InfAcidClaws", text);
		
		if (InfFireShield[client] > 0) Format(text, sizeof(text), "[A]%t (%i)", "FireShield", InfFireShield_Cost);
		else Format(text, sizeof(text), "%t (%i)", "FireShield", InfFireShield_Cost);
		if (!IsTank(client)) AddMenuItem(menu, "InfFireShield", text);
		
		if (InfMask[client] > 0) Format(text, sizeof(text), "[A]%t (%i)", "Mask", InfMask_Cost);
		else Format(text, sizeof(text), "%t (%i)", "Mask", InfMask_Cost);
		if (!IsTank(client)) AddMenuItem(menu, "InfMask", text);
		
		if (IsTank(client)) CCost = 50; else CCost = InfMeeleShield_Cost;
		if (InfMeeleShield[client] > 0) Format(text, sizeof(text), "[A]%t (%i)", "MeleeShield", CCost);
		else Format(text, sizeof(text), "%t (%i)", "MeleeShield", CCost);
		AddMenuItem(menu, "InfMeeleShield", text);
		
		if (IsTank(client)) CCost = 100; else CCost = InfRegen_Cost;
		if (InfRegen[client] > 0) Format(text, sizeof(text), "[A]%t (%i)", "Regen", CCost);
		else Format(text, sizeof(text), "%t (%i)", "Regen", CCost);
		AddMenuItem(menu, "InfRegen", text);
		
		if (InfAntiYell[client] > 0) Format(text, sizeof(text), "[A]Защита от крика (%i)", InfAntiYell_Cost);
		else Format(text, sizeof(text), "Защита от крика (%i)", InfAntiYell_Cost);
		if (!IsTank(client)) AddMenuItem(menu, "InfAntiYell", text);
		
		
		//Format(text, sizeof(text),"Передать поинты");
		//AddMenuItem(menu, "InfSendPoints", text);
		
		Format(title, sizeof(title),"%t: %d", "YourPoints", points[client]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, 30);
} 

public BuildBuyMenu7(any:client)
{
	if (!IsValidPlayer(client)) return;
		decl String:text[40];
		decl String:title[40];
		
		SetGlobalTransTarget(client);
				
		new Handle:menu = CreateMenu(InfectedMenu);
	
		if(StrEqual(MapName, "c6m1_riverbank", false) && GetConVarInt(PointsWitch) > -1)
		{
			Format(text, sizeof(text),"%t (%i)", "SummonWitch", GetConVarInt(PointsWitch));
			AddMenuItem(menu, "witch_bride", text);
		}
		else 
		{
			Format(text, sizeof(text),"%t (%i)", "SummonWitch", GetConVarInt(PointsWitch));
			AddMenuItem(menu, "witch", text);
		}	
		
		if (!IsTank(client)) {
			Format(text, sizeof(text),"%t (%i)", "HulkSummon", InfHulk_Cost);
			AddMenuItem(menu, "hulk", text);
		}
				
		Format(text, sizeof(text),"%t %t", "Horde", "Common");
		AddMenuItem(menu, "BuildBuyMenu10", text);
		
		//Format(text, sizeof(text),"%t", "Common");
		//AddMenuItem(menu, "BuildBuyMenu11", text);
		
		Format(text, sizeof(text),"%t Mutant %t", "Horde", "Common");
		AddMenuItem(menu, "BuildBuyMenu12", text);
				
				
		// 1 = riot, 2 = ceda, 4 = clown, 8 = mudman, 16 = roadcrew, 32 = jimmy, 64 = fallen); riot + ceda + roadcrew = 19
		
		Format(title, sizeof(title),"%t: %d", "YourPoints", points[client]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, 30);
} 

public BuildBuyMenu8(any:client)
{
	if (!IsValidPlayer(client)) return;
		decl String:text[40];
		decl String:title[40];
		
		SetGlobalTransTarget(client);
		
		new Handle:menu = CreateMenu(InfectedMenu);
	
		Format(text, sizeof(text),"%t (%i)", "Suicide", GetConVarInt(PointsSuicide));
		AddMenuItem(menu, "suicide", text);
			
		Format(title, sizeof(title),"%t: %d", "YourPoints", points[client]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, 30);
} 

PushBack(attacker, victim)
{
	decl Float:victimpos[3];
	decl Float:attackerpos[3];
	decl Float:v[3];
	decl Float:ang[3];
	GetClientAbsOrigin(attacker, attackerpos);
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimpos); 
	SubtractVectors(victimpos, attackerpos, ang);
	GetVectorAngles(ang, ang); 
	
	new flag=GetEntityFlags(attacker);  //FL_ONGROUND
	
	if(flag & FL_ONGROUND )
	{
		ang[0]=GetRandomFloat(2.0, 6.0);
		
	}
	else 
	{
		ang[0]=0.0-GetRandomFloat(10.0, 15.0);
	}
	ang[2]=0.0;
	
	GetAngleVectors(ang, v, NULL_VECTOR,NULL_VECTOR);	
	NormalizeVector(v,v);
	ScaleVector(v, 0.0-340.0);

	attackerpos[2]+=10.0;
	TeleportEntity(attacker, attackerpos, NULL_VECTOR, v); 
}

//public OnPreThink(client)
//{
//	if (InfHulk[client] == 1) {
//	  PrintToChat
//	  new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
//	  SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 10.0);
//	}
//}

public Action:ResetFrustration(Handle:Timer, any:client)
{
	if (!IsValidPlayer(client)) return;

	if (IsTank(client) && ((InfHulk[client] == 1) || (TankChaos[client] == 1))) {
		if ((GetEntData(client, g_iFrustrationO) >= 90) && (FrustrationReset[client] > 0)) {
			FrustrationReset[client] --;
			SetEntData(client, g_iFrustrationO, 0);
		}
		CreateTimer(0.5, ResetFrustration, client);
	}
}


public ResetAll()
{
	SurvAWP = 0;
	SurvM60 = 0;
	SurvGL = 0;
	
	for (new i = 1; i <= GetMaxClients(); i++) {
			
			SurvUpgradeExplosive[i] = 0;
			SurvUpgradeIncendiary[i] = 0;
			SurvFirearmsMaster[i] = 0;
			SurvSpeedUp[i] = 0;
			SurvSpecialShield[i] = 0;
			SurvVampire[i] = 0;
			SurvShoving[i] = 0;
			SurvLaser[i] = 0;
			SurvMeleeMaster[i] = 0;
			SurvRevenge[i] = 0;
			SurvYell[i] = 0;
			SurvHealthConvert[i] = 0;
			SurvIncSpecialShield[i] = 0;
			SurvGift[i] = 0;
			SurvBerserker[i] = 0;
			
			InfSpeedUp[i] = 0;
			InfBonusDamage[i] = 0;
			InfSpecialShield[i] = 0;
			InfBonusHealth[i] = 0;
			InfAcidClaws[i] = 0;
			InfFireShield[i] = 0;
			InfMask[i] = 0;
			InfMeeleShield[i] = 0;
			InfRegen[i] = 0;
			InfHulk[i] = 0;
			InfHobbits[i] = 0;
			InfAntiYell[i] = 0;
		
	}
	
}

static SpawnTank(client)
{
		
	for (new i=1; i<=MaxClients; i++) //now to 'disable' all but the guy who is to be tank
	{
		if (i == client) continue; //dont disable the chosen one
		if (!IsClientInGame(i)) continue; //not ingame? skip
		if (GetClientTeam(i) != 3) continue; //not infected? skip
		if (IsFakeClient(i)) continue; //a bot? skip

		if (IsPlayerAlive(i))
		{
			respawnInfected[i] = true;
			if (IsPlayerSpawnGhost(i)) reghostInfected[i] = true;
			infectedClass[i] = GetEntProp(i, Prop_Send, "m_zombieClass");
			infectedHealth[i] = GetClientHealth(i);
			GetClientAbsOrigin(i, vectors[i]);
			GetClientEyeAngles(i, infangles[i]);
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity[i]);
			
			TeleportEntity(i, nullorigin, NULL_VECTOR, NULL_VECTOR);
			ForcePlayerSuicide(i);
		}
		
		ChangeClientTeam(i, 1);
		reswapInfected[i] = true;
	}
	
	RemoveFlags();
	FakeClientCommand(client, "z_spawn_old tank");
	AddFlags();	
	
	CreateTimer(0.1, RevertPlayerStatus);
}

public Action:RevertPlayerStatus(Handle:timer)
{
	// We restore the player's status
	for (new i=1; i<=MaxClients; i++)
	{
		if (reswapInfected[i])
		{
			ChangeClientTeam(i, 3);
			reswapInfected[i] = false;
		}
		
		if (respawnInfected[i])
		{
			
			SpawnInfectedBoss(i, infectedClass[i], reghostInfected[i], false, ItsFinaleTime(), vectors[i], infangles[i], velocity[i]);
			SetEntityHealth(i, infectedHealth[i]);
			respawnInfected[i] = false;
		}
	}
}

stock SpawnInfectedBoss(any:client, any:Class, bool:bGhost=false, bool:bAuto=true, bool:bGhostFinale=false ,const Float:Origin[3]={0.0,0.0,0.0},const Float:angles[3]={0.0,0.0,0.0},const Float:Velocity[3]={0.0,0.0,0.0})
{
	new bool:resetGhostState[MAXPLAYERS+1];
	new bool:resetIsAlive[MAXPLAYERS+1];
	new bool:resetLifeState[MAXPLAYERS+1];
	decl String:options[30];

	for (new i=1; i<=MaxClients; i++)
	{ 
		if (i == client) continue; //dont disable the chosen one
		if (!IsClientInGame(i)) continue; //not ingame? skip
		if (GetClientTeam(i) != 3) continue; //not infected? skip
		if (IsFakeClient(i)) continue; //a bot? skip
		
		if (IsPlayerGhost(i))
		{
			resetGhostState[i] = true;
			SetPlayerGhostStatus(i, false);
			resetIsAlive[i] = true; 
			SetPlayerIsAlive(i, true);
		}
		else if (!IsPlayerAlive(i))
		{
			resetLifeState[i] = true;
			SetPlayerLifeState(i, false);
		}
	}
	//spawn zombie
	Format(options,30,"%s%s",g_sBossNames[Class],(bAuto?" auto":""));
	CheatCommand(client, "z_spawn_old", options);
	
	// We restore the player's status
	for (new i=1; i<=MaxClients; i++)
	{
		if (resetGhostState[i]) SetPlayerGhostStatus(i, true);
		if (resetIsAlive[i]) SetPlayerIsAlive(i, false);
		if (resetLifeState[i]) SetPlayerLifeState(i, true);
	}
	
	if (Origin[0] != 0.0) TeleportEntity(client, Origin, angles, Velocity);
	if (bGhost) InfectedForceGhost(client, true, bGhostFinale);
}

stock SetPlayerIsAlive(client, bool:alive)
{
	new offset = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	if (alive) SetEntData(client, offset, 1, 1, true);
	else SetEntData(client, offset, 0, 1, true);
}

stock bool:IsPlayerGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	return false;
}

stock SetPlayerGhostStatus(client, bool:ghost)
{
	if(ghost)
	{	
		SetEntProp(client, Prop_Send, "m_isGhost", 1, 1);
		SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
	}
	
	else
	{
		SetEntProp(client, Prop_Send, "m_isGhost", 0, 1);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

stock SetPlayerLifeState(client, bool:ready)
{
	if (ready) SetEntProp(client, Prop_Data, "m_lifeState", 1, 1);
	else SetEntProp(client, Prop_Data, "m_lifeState", 0, 1);
}

stock bool:ItsFinaleTime()
{
	new ent = FindEntityByClassname(-1, "terror_player_manager");

	if (ent > -1)
	{
		new offset = FindSendPropInfo("CTerrorPlayerResource", "m_isFinale");
		if (offset > 0)
		{
			if (GetEntData(ent, offset))
			{
				if (GetEntData(ent, offset) == 1) return true;
			}
		}
	}
	return false;
}

stock CheatCommand(client, const String:command[], const String:arguments[]="")
{
	if (!client || !IsClientInGame(client))
	{
		for (new target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target)) client = target;
		}
	}
	if (!client || !IsClientInGame(client)) return;
	
	new admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}

stock bool:InfectedForceGhost(client, SavePos=false, inFinaleAlso=false)
{
	decl Float:AbsOrigin[3];
	decl Float:EyeAngles[3];
	decl Float:Velocity[3];
	
	if (!IsClientInGame(client)) return false;
	if (GetClientTeam(client) != 3) return false;
	if (!IsPlayerAlive(client)) return false;
	if (IsPlayerGhost(client)) return false;
	if (IsFakeClient(client)) return false;
	
	if (SavePos)
	{
		GetClientAbsOrigin(client, AbsOrigin);
		GetClientEyeAngles(client, EyeAngles);
		Velocity[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
		Velocity[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
		Velocity[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");	
	}
	
	SetEntProp(client,Prop_Send, "m_isCulling", 1, 1);
	SDKCall(fhZombieAbortControl, client, 0.0);	
	if (SavePos) TeleportEntity(client, AbsOrigin, EyeAngles, Velocity);	
	return true;
}

public BuildBuyMenu5(any:client)
{
if (!IsValidPlayer(client)) return;				
	decl String:text[255];
	decl String:title[255];
		
	SetGlobalTransTarget(client);	
	
	decl String:Active[10];	
			
	if (GetClientTeam(client) == 2) {
		new Handle:menu = CreateMenu(MenuHandler_Survivors);
		SetMenuExitBackButton(menu, true);
						
		if (SurvMassSpeedUp > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		Format(text, sizeof(text),"%s%t (%i/%i)", Active, "MassSpeedUp", SurvMassSpeedUp_Sum, SurvMassSpeedUp_Cost);
		AddMenuItem(menu, "SurvMassSpeedUp", text);
		
		if (SurvMassRegen > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		Format(text, sizeof(text),"%s%t (%i/%i)", Active, "MassRegen", SurvMassRegen_Sum, SurvMassRegen_Cost);
		AddMenuItem(menu, "SurvMassRegen", text);
		
		if (SurvAutoMiniGun > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		Format(text, sizeof(text),"%s%t (%i/%i)", Active, "Turret", SurvAutoMiniGun_Sum, SurvAutoMiniGun_Cost);
		AddMenuItem(menu, "SurvAutoMiniGun", text);
		
		if (SurvZombieSurprize > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		Format(text, sizeof(text),"%s%t (%i/%i)", Active, "SurprizeZombies", SurvZombieSurprize_Sum, SurvZombieSurprize_Cost);
		AddMenuItem(menu, "SurvZombieSurprize", text);
		
		if (SurvUntouchable > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		Format(text, sizeof(text),"%s%t (%i/%i)", Active, "Untouchable", SurvUntouchable_Sum, SurvUntouchable_Cost);
		AddMenuItem(menu, "SurvUntouchable", text);
		
		if (SurvPhysPower > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		Format(text, sizeof(text),"%s%t (%i/%i)", Active, "PhysPower", SurvPhysPower_Sum, SurvPhysPower_Cost);
		AddMenuItem(menu, "SurvPhysPower", text);
		
		if (SurvVictimShield > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		Format(text, sizeof(text),"%s%t (%i/%i)", Active, "SurvVictimShield", SurvVictimShield_Sum, SurvVictimShield_Cost);
		AddMenuItem(menu, "SurvVictimShield", text);
		
		Format(title, sizeof(title),"%t: %d, TimeLeft: %i", "YourPoints", points[client],TeamBonusDelayTimeLeftS);
		SetMenuTitle(menu, title);
	
		DisplayMenu(menu, client, 30);		
	}	
	else if (GetClientTeam(client) == 3) {

		new Handle:menu = CreateMenu(InfectedMenu);
		SetMenuExitBackButton(menu, true);
				
		if (InfMassSlow > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		Format(text, sizeof(text),"%s%t (%i/%i)",Active, "SlowDown", InfMassSlow_Sum, InfMassSlow_Cost);
		AddMenuItem(menu, "InfMassSlow", text);
		
		//if (InfTankChaos > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		//Format(text, sizeof(text),"%s%t (%i/%i)", Active, "TankChaos", InfTankChaos_Sum, InfTankChaos_Cost);
		//AddMenuItem(menu, "InfTankChaos", text);
		
		if (InfDeathCloud > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		Format(text, sizeof(text),"%s%t (%i/%i)", Active, "DeathCloud", InfDeathCloud_Sum, InfDeathCloud_Cost);
		AddMenuItem(menu, "InfDeathCloud", text);
		
		if (InfZombieApoc > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		Format(text, sizeof(text),"%s%t (%i/%i)", Active, "ZombieApocalypsis", InfZombieApoc_Sum, InfZombieApoc_Cost);
		AddMenuItem(menu, "InfZombieApoc", text);
		
		if (InfPoison > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		Format(text, sizeof(text),"%s%t (%i/%i)",Active, "Poison", InfPoison_Sum, InfPoison_Cost);
		AddMenuItem(menu, "InfPoison", text);
		
		if (InfMassArmor > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		Format(text, sizeof(text),"%s%t (%i/%i)",Active, "InfMassArmor", InfMassArmor_Sum, InfMassArmor_Cost);
		AddMenuItem(menu, "InfMassArmor", text);
		
		//if (InfBummerRain > 0) Format(Active, sizeof(Active), "[A]"); else Format(Active, sizeof(Active), "");
		//Format(text, sizeof(text),"%sАвиаудар (%i/%i)",Active, InfBummerRain_Sum, InfBummerRain_Cost);
		//AddMenuItem(menu, "InfBummerRain", text);
			
		Format(title, sizeof(title),"%t: %d, TimeLeft: %i", "YourPoints", points[client],TeamBonusDelayTimeLeftI);
		SetMenuTitle(menu, title);
	
		DisplayMenu(menu, client, 30);
	}
	
	
} 

public OnMapEnd()
{
	if (MapEnd > 0) return;
	
	MapEnd++;
	MapStart = 0;
	
	UnHookDamage();
	RoundEndProc();
	
}

public SendPointsToBank(client)
{
	if (!IsValidPlayer(client)) return;
	
	SetGlobalTransTarget(client);
	
	if (points[client] <= 0) {
		PrintToChat(client, "%t.", "NotEnoughPoints");
		return;
	}

	decl String:Title[MAX_LINE_WIDTH];
	Format(Title, sizeof(Title), "%t:", "HowMuchPoints");
	new Handle:menu = CreateMenu(SendPointsToBankHandler);

	SetMenuTitle(menu, Title);
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);

	decl String:text[255], id[10];
	new step;
	
	step = RoundToFloor(FloatDiv(float(points[client]),6.0));
	new value = step;
	Format(text, sizeof(text), "%d", value);
	AddMenuItem(menu, text, text);
	
	value = value + step;
	Format(text, sizeof(text), "%d", value);
	AddMenuItem(menu, text, text);
	
	value = value + step;
	Format(text, sizeof(text), "%d", value);
	AddMenuItem(menu, text, text);
	
	value = value + step;
	Format(text, sizeof(text), "%d", value);
	AddMenuItem(menu, text, text);
	
	value = value + step;
	Format(text, sizeof(text), "%d", value);
	AddMenuItem(menu, text, text);
	
	value = points[client];
	Format(text, sizeof(text), "%d", value);
	AddMenuItem(menu, text, text);
				
	DisplayMenu(menu, client, 60);	
	
}

public SendPointsToBankHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE) return;
	if (action == MenuAction_End) {
		CloseHandle(menu);
		return;
	}
	if (action != MenuAction_Select || param1 <= 0 || (!IsValidPlayer(param1)))  {
		
		return;
	}
	
	//SetGlobalTransTarget(param1);
	
	decl String:Info[255];
	new bool:found = GetMenuItem(menu, param2, Info, sizeof(Info));
	
	if (!found) return;
	
	PointsValue[param1] = StringToInt(Info);

	if (points[param1] < PointsValue[param1]) {
		PrintToChat(param1, "%t", "NotEnoughPoints");
		return;
	}
	
	if(StrEqual(item[param1], "SurvMassSpeedUp", false)) SurvMassSpeedUp_Sum = SurvMassSpeedUp_Sum + PointsValue[param1];
	else if(StrEqual(item[param1], "SurvMassRegen", false)) SurvMassRegen_Sum = SurvMassRegen_Sum + PointsValue[param1];
	else if(StrEqual(item[param1], "SurvAutoMiniGun", false)) {
		if (CurrentGamemodeID != 1) SurvAutoMiniGun_Limit = 2; else SurvAutoMiniGun_Limit = 1;
		if (SurvAutoMiniGun >= SurvAutoMiniGun_Limit) {
			PrintToChatAll("%t", "Turretlimit");
			return;
		}
		SurvAutoMiniGun_Sum = SurvAutoMiniGun_Sum + PointsValue[param1];
	}
	else if(StrEqual(item[param1], "SurvZombieSurprize", false)) SurvZombieSurprize_Sum = SurvZombieSurprize_Sum + PointsValue[param1];
	else if(StrEqual(item[param1], "SurvUntouchable", false)) SurvUntouchable_Sum = SurvUntouchable_Sum + PointsValue[param1];
	else if(StrEqual(item[param1], "SurvPhysPower", false)) SurvPhysPower_Sum = SurvPhysPower_Sum + PointsValue[param1];
	else if(StrEqual(item[param1], "SurvVictimShield", false)) SurvVictimShield_Sum = SurvVictimShield_Sum + PointsValue[param1];
	else if(StrEqual(item[param1], "InfMassSlow", false)) InfMassSlow_Sum = InfMassSlow_Sum + PointsValue[param1];
	else if(StrEqual(item[param1], "InfMassArmor", false)) InfMassArmor_Sum = InfMassArmor_Sum + PointsValue[param1];
	else if(StrEqual(item[param1], "InfTankChaos", false)) { 
		//PrintToChat(param1, "Отключен, на этом месте могла быть ваша реклама.");
		return;
		//InfTankChaos_Sum = InfTankChaos_Sum + PointsValue[param1]; 
	}
	else if(StrEqual(item[param1], "InfDeathCloud", false)) InfDeathCloud_Sum = InfDeathCloud_Sum + PointsValue[param1];
	else if(StrEqual(item[param1], "InfZombieApoc", false)) InfZombieApoc_Sum = InfZombieApoc_Sum + PointsValue[param1];
	else if(StrEqual(item[param1], "InfPoison", false)) InfPoison_Sum = InfPoison_Sum + PointsValue[param1];
	else if(StrEqual(item[param1], "InfBummerRain", false)) InfBummerRain_Sum = InfBummerRain_Sum + PointsValue[param1];
	
	points[param1] -= PointsValue[param1];
	
	new Sum = GetSumById(item[param1]);
	new Cost = GetCostById(item[param1]);
	decl String:result[255];
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			SetGlobalTransTarget(i);
			Format(result, sizeof(result), "none");
			if(StrEqual(item[param1], "SurvMassSpeedUp")) Format(result, sizeof(result), "%t", "MassSpeedUp");
			else if(StrEqual(item[param1], "SurvMassRegen")) Format(result, sizeof(result), "%t", "MassRegen");
			else if(StrEqual(item[param1], "SurvAutoMiniGun")) Format(result, sizeof(result), "%t", "Turret");
			else if(StrEqual(item[param1], "SurvZombieSurprize")) Format(result, sizeof(result), "%t", "SurprizeZombies");
			else if(StrEqual(item[param1], "SurvUntouchable")) Format(result, sizeof(result), "%t", "Untouchable");
			else if(StrEqual(item[param1], "SurvPhysPower")) Format(result, sizeof(result), "%t", "PhysPower");
			else if(StrEqual(item[param1], "SurvVictimShield")) Format(result, sizeof(result), "%t", "SurvVictimShield");
			else if(StrEqual(item[param1], "InfMassSlow")) Format(result, sizeof(result), "%t", "SlowDown");
			else if(StrEqual(item[param1], "InfMassArmor")) Format(result, sizeof(result), "%t", "InfMassArmor");
			else if(StrEqual(item[param1], "InfTankChaos")) Format(result, sizeof(result), "%t", "TankChaos");
			else if(StrEqual(item[param1], "InfDeathCloud")) Format(result, sizeof(result), "%t", "DeathCloud");
			else if(StrEqual(item[param1], "InfZombieApoc")) Format(result, sizeof(result), "%t", "ZombieApocalypsis");
			else if(StrEqual(item[param1], "InfPoison")) Format(result, sizeof(result), "%t", "Poison");
			PrintToChat(i, "\x05%s \x01%t \x05%d\x01(\x05%d\x01/\x04%d \x01%t: \x04%d) \x01%t \x03%t \x05%s ", GetName(param1), "Put", PointsValue[param1], Sum, Cost, "Left", Cost - Sum, "Points", "CommandBonus", result);
		}
	}
	
	CheckBankActivate();
}

public CheckBankActivate()
{
	if ( (GetTeamHumanCount(2) > 0) && (SurvAllowMass != 0) )  {
	
		if (FloatCompare(InfGlobalDamage, InfGlobalActivateDamage) == 1) {
			InfGlobalDamage = 0.0;
			new RandNum = GetRandomInt(1,5);
			if (RandNum == 1) InfMassSlow_Sum = InfMassSlow_Cost;
			if (RandNum == 2) InfDeathCloud_Sum = InfDeathCloud_Cost;
			if (RandNum == 3) InfZombieApoc_Sum = InfZombieApoc_Cost;
			if (RandNum == 4) InfPoison_Sum = InfPoison_Cost;
			if (RandNum == 5) InfMassArmor_Sum = InfMassArmor_Cost;
			PrintToChatAll("\x01В банк командных бонусов \x04Трупов \x01добавлены поинты.");
			
		}
	
		//if (SurvAllowMass == 0) return;
			
		if ((SurvMassSpeedUp_Sum >= SurvMassSpeedUp_Cost) && (SurvMassSpeedUp <= 0)) {
			SurvMassSpeedUp++;
			SurvMassSpeedUp_Sum -= SurvMassSpeedUp_Cost;
			
			PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Survivors", "MassSpeedUp");
			CreateTimer(SurvMassSpeedUp_Time, SurvMassSpeedUpResetTimer);
			
			if (SurvAllowMass != 0) {
				SurvAllowMass = 0;
				TeamBonusDelayTimeLeftS = 120;
				CreateTimer(1.0, ResetSAM);
			}
			
		}
	
		if ((SurvMassRegen_Sum >= SurvMassRegen_Cost) && (SurvMassRegen <= 0)) {
			SurvMassRegen++;
			SurvMassRegen_Sum -= SurvMassRegen_Cost;
			
			PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Survivors", "MassRegen");
			CreateTimer(SurvMassRegen_Time, SurvMassRegenResetTimer);
			
			if (SurvAllowMass != 0) {
				SurvAllowMass = 0;
				TeamBonusDelayTimeLeftS = 120;
				CreateTimer(1.0, ResetSAM);
			}
			
		}
	
		if (CurrentGamemodeID != 1) SurvAutoMiniGun_Limit = 2; else SurvAutoMiniGun_Limit = 1;
		if ((SurvAutoMiniGun_Sum >= SurvAutoMiniGun_Cost) && (SurvAutoMiniGun < SurvAutoMiniGun_Limit)) {
						
			SurvAutoMiniGun++;
			SurvAutoMiniGun_Sum -= SurvAutoMiniGun_Cost;
			
			PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Survivors", "Turret");
			
			if (SurvAllowMass != 0) {
				SurvAllowMass = 0;
				TeamBonusDelayTimeLeftS = 120;
				CreateTimer(1.0, ResetSAM);
			}
			
			for (new i = 1; i <= GetMaxClients(); i++) {
				if (IsNormalPlayer(i)) 
					if ((GetClientTeam(i) == 2) && (IsClientAlive(i))) {
						MinigunStartCount = GetMinigunCount();
						MinigunTimeout = 10;
						ServerCommand("sm_machine #%i", GetClientUserId(i));
						PrintToChatAll("\x05%t \x01%t \x04%s", "Turret", "TurretAppear", GetName(i));
						CreateTimer(1.0, CheckMinigunTimer, INVALID_HANDLE);
						TurrelCount++;
						return;
					}
				}
				
		}
	
		if ((SurvZombieSurprize_Sum >= SurvZombieSurprize_Cost) && (SurvZombieSurprize <= 0)) {
			SurvZombieSurprize++;
			SurvZombieSurprize_Sum -= SurvZombieSurprize_Cost;
			
			PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Survivors", "SurprizeZombies");
			CreateTimer(SurvZombieSurprize_Time, SurvZombieSurprizeResetTimer);
			
			if (SurvAllowMass != 0) {
				SurvAllowMass = 0;
				TeamBonusDelayTimeLeftS = 120;
				CreateTimer(1.0, ResetSAM);
			}
			
		}
		if ((SurvUntouchable_Sum >= SurvUntouchable_Cost) && (SurvUntouchable <= 0)) {
			SurvUntouchable++;
			SurvUntouchable_Sum -= SurvUntouchable_Cost;
			
			PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Survivors", "Untouchable");
			CreateTimer(SurvUntouchable_Time, SurvUntouchableResetTimer);
			
			if (SurvAllowMass != 0) {
				SurvAllowMass = 0;
				TeamBonusDelayTimeLeftS = 120;
				CreateTimer(1.0, ResetSAM);
			}
			
		}
		if ((SurvPhysPower_Sum >= SurvPhysPower_Cost) && (SurvPhysPower <= 0)) {
			SurvPhysPower++;
			SurvPhysPower_Sum -= SurvPhysPower_Cost;
			
			PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Survivors", "PhysPower");
			CreateTimer(SurvPhysPower_Time, SurvPhysPowerResetTimer);
			
			if (SurvAllowMass != 0) {
				SurvAllowMass = 0;
				TeamBonusDelayTimeLeftS = 120;
				CreateTimer(1.0, ResetSAM);
			}
			
		}
		if (SurvVictimShield_Sum >= SurvVictimShield_Cost) {
						
			if ( IsValidPlayer(VictimID) && (GetClientTeam(VictimID) == 2) )
				PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Survivors", "SurvVictimShield");
			else return;
			
			SurvVictimShield_Sum -= SurvVictimShield_Cost;
			
			SurvSpecialShield[VictimID] += 5;
			SurvIncSpecialShield[VictimID] +=3;
					
			if (SurvAllowMass != 0) {
				SurvAllowMass = 0;
				TeamBonusDelayTimeLeftS = 120;
				CreateTimer(1.0, ResetSAM);
			}
			
		}
	}


	if ( ((GetTeamHumanCount(3) > 0) || (CurrentGamemodeID != 1)) && (InfAllowMass != 0) ) {
	
		//if (InfAllowMass == 0) return;
		
		if ((InfMassArmor_Sum >= InfMassArmor_Cost) && (InfMassArmor <= 0)) {
			InfMassArmor++;
			InfMassArmor_Sum -= InfMassArmor_Cost;
			
			PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Infected", "InfMassArmor");
			CreateTimer(60.0, InfMassArmorResetTimer);
			
			if (InfAllowMass != 0) {
				InfAllowMass = 0;
				TeamBonusDelayTimeLeftI = 120;
				CreateTimer(1.0, ResetIAM);
			}
			
		}
		if ((InfMassSlow_Sum >= InfMassSlow_Cost) && (InfMassSlow <= 0)) {
			InfMassSlow++;
			InfMassSlow_Sum -= InfMassSlow_Cost;
			
			PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Infected", "SlowDown");
			CreateTimer(InfMassSlow_Time, InfMassSlowResetTimer);
						
			if (InfAllowMass != 0) {
				InfAllowMass = 0;
				TeamBonusDelayTimeLeftI = 120;
				CreateTimer(1.0, ResetIAM);
			}
			
		}
		if ((InfTankChaos_Sum >= InfTankChaos_Cost) && (InfTankChaos <= 0) && (GetTankCount() == 0)) {
			
			new Handle:il = FindConVar("l4d_infected_limit");
			if (il > 0) InfTankChaos = GetConVarInt(il);
			else InfTankChaos = 4;
			PrintToChatAll("Tank count: %i", InfTankChaos);
			
			InfTankChaos_Sum -= InfTankChaos_Cost;
			
			PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Infected", "TankChaos");
			
			HumanChaosTank = GetTeamHumanCount(3);
						
			for (new i = 1; i <= GetMaxClients(); i++) {
				if (IsNormalPlayer(i)) TankChaosAllow[i] = 0;
			}
				
						
			CreateTimer(1.0, StartTankChaosTimer);
			//CreateTimer(1.0, SpawnTankTimer);
			
			if (InfAllowMass != 0) {
				InfAllowMass = 0;
				TeamBonusDelayTimeLeftI = 120;
				CreateTimer(1.0, ResetIAM);
			}
			
		}
		
		if ((InfDeathCloud_Sum >= InfDeathCloud_Cost) && (InfDeathCloud <= 0)) {
			
			InfDeathCloud++;
			InfDeathCloud_Sum -= InfDeathCloud_Cost;
			
			PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Infected", "DeathCloud");	
			decl Float:g_pos[3];

			InfAllowMass = 0;
			CreateTimer(120.0, ResetIAM);			
			
			for (new i = 1; i <= GetMaxClients(); i++) {
				if (IsNormalPlayer(i)) {
					if ( (GetClientTeam(i) == 2) && (IsPlayerAlive(i)) ) { 
						AttachParticle(i, PARTICLE_SPAWN, 30.0, 0.0);
						/*
						new Handle:hBf = StartMessageOne("Shake", i);
						if (hBf == INVALID_HANDLE) return;
						BfWriteByte(hBf, 0);
						BfWriteFloat(hBf,6.0);
						BfWriteFloat(hBf,1.0);
						BfWriteFloat(hBf,60.0);
						EndMessage();
						CreateTimer(1.0, StopShake, i);	
						*/
					}
				}
			}
			DeathCloudNum = 3;
			CreateTimer(InfDeathCloud_Time, DeathCloudResetTimer);
			CreateTimer(1.0, DeathCloudDamageTimer);
			
			if (InfAllowMass != 0) {
				InfAllowMass = 0;
				TeamBonusDelayTimeLeftI = 120;
				CreateTimer(1.0, ResetIAM);
			}
			
		}
		if (InfZombieApoc_Sum >= InfZombieApoc_Cost)
		{
		decl String:sCapText[64];
		sCapText[0] = 0;
		decl String:sValues[32];
		sValues[0] = 0;
		decl String:sColour[13];
		sColour[0] = 0;
		decl String:sIcon[32];
		sIcon[0] = 0;
			InfZombieApoc = 4;
			InfZombieApoc_Sum -= InfZombieApoc_Cost;
			
			PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Infected", "ZombieApocalypsis");		
			strcopy(sIcon, sizeof(sIcon), "icon_skull");
			strcopy(sCapText, sizeof(sCapText), "Zombie Apocalypse Incomming!\0");
			strcopy(sColour, sizeof(sColour), "255 1 1");
			new Handle:il = INVALID_HANDLE;
			il = FindConVar("l4d_infected_limit");
			if (il != INVALID_HANDLE) InfZombieApoc = GetConVarInt(il) + 3;
			else InfZombieApoc = 6;
					
			gHordeType = 1;		
			CreateTimer(1.0, UncommonHorde, gHordeType);
			
			new tclient = 0;
			for(new i=1; ((i<=GetMaxClients()) && (tclient == 0)); i++) 
				if (IsValidPlayer(i)) //&& (GetClientTeam(i) == 3)) 
					tclient = i;
			
			RemoveFlags();
			MultiClientCmd(tclient, "sm_mutantbomb", 10);
			MultiClientCmd(tclient, "sm_mutantfire", 10);
			MultiClientCmd(tclient, "sm_mutantghost", 10);
			MultiClientCmd(tclient, "sm_mutantmind", 10);
			MultiClientCmd(tclient, "sm_mutantsmoke", 10);
			MultiClientCmd(tclient, "sm_mutantspit", 10);
			MultiClientCmd(tclient, "sm_mutanttesla", 10);
			AddFlags();					
			
			if (InfAllowMass != 0) {
				InfAllowMass = 0;
				TeamBonusDelayTimeLeftI = 120;
				CreateTimer(1.0, ResetIAM);
			}
			
		}
		if ((InfPoison_Sum >= InfPoison_Cost) && (InfPoison <= 0)) {
			InfPoison_Sum -= InfPoison_Cost;
			
			PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Infected", "Poison");		
			
			//CreateTimer(2.0, ShakeTimer);
			new pid = ChosePoisonClient();
			if (IsNormalPlayer(pid)) PrintToChatAll("\x04[Xtreme] \x05%s \x01%t", GetName(pid), "poison2");
			else return;
						
			CreateTimer(InfPoison_Time, InfPoisonResetTimer);
			
			if (InfAllowMass != 0) {
				InfAllowMass = 0;
				TeamBonusDelayTimeLeftI = 120;
				CreateTimer(1.0, ResetIAM);
			}
			
		}
		if ((InfBummerRain_Sum >= InfBummerRain_Cost) && (InfBummerRain <= 0)) {
			//BummerRain++;
			InfBummerRain_Sum -= InfBummerRain_Cost;
			
			//PrintToChatAll("\x04%t \x05%t \x03%t\x01: %t.", "Activated", "CommandBonus", "Infected", "Fear");		
			
			//decl Float:g_pos[3];
			//new victim = GetFirstClientID(2);
			//GetClientEyePosition(victim, g_pos);
			//CheatCommand(victim, "sm_boomer_rain", "8");
			//ServerCommand("sm_boomer_rain_at %i %i %i %i",g_pos[0], g_pos[1], g_pos[2], 8);
			//PrintToChatAll("Призыв бумеров %i %i %i %i",g_pos[0], g_pos[1], g_pos[2], 8);
			new Float:Delay = 2.0;
			new Count = 0;
			for (new i = 1; i <= GetMaxClients(); i++) {
				if (IsNormalPlayer(i)) 
					if (GetClientTeam(i) == 2) {
						if (Count <= 2) CreateTimer(Delay, CreateAirstrike, i);
						Delay = FloatAdd(Delay, 10.0);
						Count++;
						
					}
						//CheatCommand(i, "sm_airstrike #%i", GetClientUserId(i));
			}
			
			if (InfAllowMass != 0) {
				InfAllowMass = 0;
				TeamBonusDelayTimeLeftI = 120;
				CreateTimer(1.0, ResetIAM);
			}
			
		}
	}
}	

GetFirstClientID(any: team)
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsNormalPlayer(i)) 
			if (GetClientTeam(i) == team) return i;
	}
	return 0;
}

GetFirstValidClientID(any: team)
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) 
			if (GetClientTeam(i) == team) return i;
	}
	return 0;
}

public Action:UncommonHorde(Handle:timer, any:HordeType) 
{
	if (InfZombieApoc <= 0) return;
	EmitSoundToAll(HORDE);
	
	new cid = GetFirstValidClientID(2);
	if (!IsValidPlayer(cid)) cid = GetFirstValidClientID(3);
	if (IsValidPlayer(cid)) {
		RemoveFlags();
		FakeClientCommand(cid, "director_force_panic_event");
		AddFlags();
	}
	
	switch(HordeType)
	{
		case 1:
		ServerCommand("sm_spawnuncommonhorde riot");
		case 2:
		ServerCommand("sm_spawnuncommonhorde jimmy");
		case 3:
		ServerCommand("sm_spawnuncommonhorde ceda");
		case 4:
		ServerCommand("sm_spawnuncommonhorde clown");
		case 5:
		ServerCommand("sm_spawnuncommonhorde mud");
		case 6:
		ServerCommand("sm_spawnuncommonhorde roadcrew");
		case 7:
		ServerCommand("sm_spawnuncommonhorde fallen");
	}
	
	if (InfZombieApoc > 0) {
		if (gHordeType >= 6) gHordeType = 0;
		gHordeType++;
		CreateTimer(5.0, UncommonHorde, gHordeType);
		InfZombieApoc--;
	}
}

public Action:CreateAirstrike(Handle:timer, any: client) 
{
	decl String:args[255];
	Format(args, sizeof(args), "#%i", GetClientUserId(client));
  	CheatCommand(client, "sm_airstrike", args);
}

public Action:DeathCloudDamageTimer(Handle:timer) 
{
	new Health;
	decl String:soundFilePath[256];
	Format(soundFilePath, sizeof(soundFilePath), "player/survivor/voice/choke_5.wav");
		
	DeathCloudNum++;
		
	for (new i = 1; i <= GetMaxClients(); i++) {
		
		if (IsNormalPlayer(i)) 
			if (GetClientTeam(i) == 2) {
								
				if (DeathCloudNum >= 3) {
					AttachParticle(i, PARTICLE_SPAWN, 5.0, 0.0);
				}
				
				Health = GetClientHealth(i);
				Health = Health - 1;
				if (Health > 0) SetEntityHealth(i, Health);
						
				EmitSoundToClient(i, soundFilePath);

				PrintCenterText(i, "%t", "smokershake");
							
			}
	}
	
	if (DeathCloudNum >= 3) DeathCloudNum = 0;
	if (InfDeathCloud > 0) CreateTimer(2.0, DeathCloudDamageTimer);
}

public Action:DeathCloudResetTimer(Handle:timer, any:data) 
{
	if (InfDeathCloud > 0) {
		InfDeathCloud--;
		PrintToChatAll("\x01%t \x05%t \x01%t.", "CommandBonus", "DeathCloud", "Finished");
	}
}

public Action:InfPoisonResetTimer(Handle:timer, any:data) 
{
	if (InfPoison > 0) {
		ResetPoisonClient();
		if (IsNormalPlayer(InfPoison)) {
			SurvSpecialShield[InfPoison] = 0;
			SurvIncSpecialShield[InfPoison]	= 0;
		}
		InfPoison = 0;
		PrintToChatAll("\x01%t \x05%t \x01%t.", "CommandBonus", "Poison", "Finished");
	}
}

public Action:ShakeTimer(Handle:timer, any:data) 
{
	return;
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsNormalPlayer(i)) && (GetClientTeam(i) == 2)) 	{
			new Handle:hBf = StartMessageOne("Shake", i);
			BfWriteByte(hBf, 0);
			BfWriteFloat(hBf,6.0);
			BfWriteFloat(hBf,1.0);
			BfWriteFloat(hBf,1.0);
			EndMessage();
			CreateTimer(2.0, StopShake, i);
		}
	}
	//if (InfFear > 0) CreateTimer(2.0, ShakeTimer);
}
	
public Action:SurvPhysPowerResetTimer(Handle:timer, any:data) 
{
	if (SurvPhysPower > 0) {
		SurvPhysPower--;
		PrintToChatAll("\x01%t \x05%t \x01%t.", "CommandBonus", "PhysPower", "Finished");
	}
}

public Action:SurvUntouchableResetTimer(Handle:timer, any:data) 
{
	if (SurvUntouchable > 0) {
		SurvUntouchable--;
		PrintToChatAll("\x01%t \x05%t \x01%t.", "CommandBonus", "Untouchable", "Finished");
	}
}

public Action:SurvZombieSurprizeResetTimer(Handle:timer, any:data) 
{
	if (SurvZombieSurprize > 0) {
		SurvZombieSurprize--;
		PrintToChatAll("\x01%t \x05%t \x01%t.", "CommandBonus", "SurprizeZombies", "Finished");
	}
}

public Action:SurvMassRegenResetTimer(Handle:timer, any:data) 
{
	if (SurvMassRegen > 0) {
		SurvMassRegen--;
		PrintToChatAll("\x01%t \x05%t \x01%t.", "CommandBonus", "MassRegen", "Finished");
	}
}

public Action:SurvMassSpeedUpResetTimer(Handle:timer, any:data) 
{
	if (SurvMassSpeedUp > 0) {
		SurvMassSpeedUp--;
		PrintToChatAll("\x01%t \x05%t \x01%t.", "CommandBonus", "MassSpeedUp", "Finished");
	}
}

public Action:InfMassSlowResetTimer(Handle:timer, any:data) 
{
	if (InfMassSlow > 0) {
		InfMassSlow--;
		for (new i = 1; i <= GetMaxClients(); i++) {
			if (IsNormalPlayer(i))
				if (GetClientTeam(i) == 2)
					SetEntDataFloat(i, g_flLagMovement, 1.0, true);
		}
		PrintToChatAll("\x01%t \x05%t \x01%t.", "CommandBonus", "SlowDown", "Finished");
	}
}

public Action:InfMassArmorResetTimer(Handle:timer, any:data) 
{
	if (InfMassArmor > 0) {
		InfMassArmor--;
		PrintToChatAll("\x01%t \x05%t \x01%t.", "CommandBonus", "InfMassArmor", "Finished");
	}
}


public Action:SpeedLogicTimer(Handle:timer, any:data)
{
	if (IsEnd()) return;
	
	new Float: CurrentSpeed;
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsNormalPlayer(i)) {
			CurrentSpeed = GetEntDataFloat(i, g_flLagMovement);
			if (GetClientTeam(i) == 2) {
				if (InfPoison == i) {
					SetEntDataFloat(i, g_flLagMovement, 0.2, true);
					new pHealth = GetClientHealth(i);
					new fHealth = pHealth - 1;
					if (pHealth > 5) SetEntityHealth(i, fHealth);
				}
				else if ((SurvSpeedUp[i] > 0) && (SurvMassSpeedUp > 0) && (InfMassSlow <= 0)) {
					SetEntDataFloat(i, g_flLagMovement, SurvMassSpeedUp_Value, true);
				}
				else if ((SurvSpeedUp[i] > 0) && (InfMassSlow <= 0)) {
					SetEntDataFloat(i, g_flLagMovement, SurvSpeedUp_Value, true);
				}
				else if ((SurvMassSpeedUp > 0) && (InfMassSlow <= 0)) {
					SetEntDataFloat(i, g_flLagMovement, SurvMassSpeedUp_Value, true);
				}
				else if ((InfMassSlow > 0) && (SurvMassSpeedUp > 0)) {
					SetEntDataFloat(i, g_flLagMovement, 1.1, true);
				}
				else if ((InfMassSlow > 0) && (SurvSpeedUp[i] > 0)){
					SetEntDataFloat(i, g_flLagMovement, 1.1, true);
				}
				else if (InfMassSlow > 0) {
					SetEntDataFloat(i, g_flLagMovement, InfMassSlow_Value, true);
				}
				else if ( (SurvMassSpeedUp <= 0) && (SurvSpeedUp[i] <= 0) && (CurrentSpeed > 1.15) ) {
					SetEntDataFloat(i, g_flLagMovement, 1.0, true);
				}
				
				
				//добавим регенерацию шоб не плодить лишнии таймеры
				if (SurvMassRegen > 0) {
					new Health = GetClientHealth(i);
					new FinalHealth = Health + 1;
					if (FinalHealth < 100) SetEntityHealth(i, FinalHealth);
				}
			}
			else if (GetClientTeam(i) == 3) {
				if (IsTank(i) && (InfHulk[i] == 1)) {
					SetEntDataFloat(i, g_flLagMovement, HulkSpeedUP, true);
				}
				else if ((InfSpeedUp[i] > 0) && (IsPounced[i] == 0)) {
					SetEntDataFloat(i, g_flLagMovement, InfSpeedUp_Value, true);
				}
			}
		}
	}
}

stock GetTeamHumanCount(team)
{
	new humans = 0;
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsValidPlayer(i) && GetClientTeam(i) == team)
		{
			humans++;
		}
	}
	
	return humans;
}

stock GetNotTankHumanCount()
{
	new humans = 0;
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsValidPlayer(i) && (GetClientTeam(i) == 3) && (!IsTank(i)))
		{
			humans++;
		}
	}
	
	return humans;
}

public Action:Event_PlayerShoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if ((!IsNormalPlayer(Attacker)) || (!IsNormalPlayer(Victim)) || (GetClientTeam(Victim) != 3) || (GetClientTeam(Attacker) != 2)) return;
	
	if ((SurvPhysPower > 0) || (Attacker == VictimID)) {
		//new health = GetClientHealth(Victim);
		//new plusdamage = 50;
		//if (health-plusdamage < 0) SetEntityHealth(Victim, 0);
		//else SetEntityHealth(Victim, health-plusdamage);
		//HurtPoint(Attacker, Victim, 100, 64, 50);
		//applyDamage2(100, Victim, Attacker);
		new iHP=GetEntProp(Victim,Prop_Data,"m_iHealth");
		new iDmgAdd = 100;
		if (iHP>iDmgAdd)	{
			SetEntProp(Victim,Prop_Data,"m_iHealth", iHP-iDmgAdd);
		}
		else SetEntProp(Victim,Prop_Data,"m_iHealth", 0);
	}
}

public Action:Event_EntityShoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver) return;
	
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new iEnt = GetEventInt(event, "entityid");
	
	if ((!IsNormalPlayer(Attacker)) || (GetClientTeam(Attacker) != 2)) return;
	
	decl String:class[32];
		
	if ((SurvPhysPower > 0) || (Attacker == VictimID)) {		
		if ((IsValidEntity(iEnt)) && (IsValidEdict(iEnt)))
		{
			GetEdictClassname(iEnt, class,sizeof(class));
			if (StrEqual(class, "infected", false)) {
				//IgniteEntity(iEnt, 5.0, true);
				HurtPoint(Attacker, iEnt, 100, 64, 50);
				//applyDamage2(100, iEnt, Attacker);
				//new iHP=GetEntProp(iEnt,Prop_Data,"m_iHealth");
				//new iDmgAdd = 100;
				//if (iHP>iDmgAdd)	{
//					SetEntProp(iEnt,Prop_Data,"m_iHealth", iHP-iDmgAdd);
				//}
				//else SetEntProp(iEnt,Prop_Data,"m_iHealth", 0);
			}
		}	
	}
}

public Action:StartTankChaosTimer(Handle:timer)
{
	decl Float:pos[3], Float:tpos[3];
	new float: distance, curdistance, InfTankChaos_Range;
	new Bool:FoundInRange = false;
	new VictimInfType;
	curdistance = 0;
	InfTankChaos_Range = 1500;
		
	if (InfTankChaos <= 0) return;
		
	for(new i=1; i<=GetMaxClients(); i++) {
						
		if ((IsValidPlayer(i)) && (GetClientTeam(i) == 3) && (IsPlayerGhost(i))) { //&& (IsPlayerAlive(i))
			
			VictimInfType = GetInfType(i);
			if ((VictimInfType == 3) && (VictimInfType == 5)) continue;
			
			FoundInRange = false;
			GetClientAbsOrigin(i, pos);
					
			SetGlobalTransTarget(i);						
					
			for(new j=1; ((j<=GetMaxClients()) && (!FoundInRange)); j++) {
				//if (InfTankChaos <= 0) return;
				if ((IsNormalPlayer(j)) && (GetClientTeam(j) == 2) && (IsPlayerAlive(j))) {
					GetClientAbsOrigin(j, tpos);
					distance = GetVectorDistance(pos, tpos);
				
					if (FloatCompare(distance, InfTankChaos_Range) == -1) {
						FoundInRange = true;
					} 					
				}
			}
			
			//панелька
			new Handle:TankChaosPanel = CreatePanel();
			SetPanelTitle(TankChaosPanel, "Танковый хаос");	
			
			new String:Value[255];
			PrintHintText(i, "%t [%4.0d / %4.0d]", "TankChaosStart", distance, InfTankChaos_Range);
			
			DrawPanelText(TankChaosPanel, "Отойдите от Живых на достаточное расстояние,");
			DrawPanelText(TankChaosPanel, "выберите просторное место для появления Танка Хаоса");
			DrawPanelText(TankChaosPanel, "и нажмите Готов, иначе Вы рискуете застрять в текстурах");
						
			if (TankChaosAllow[i] == 0) {
				DrawPanelItem(TankChaosPanel, "Готов");
				DrawPanelItem(TankChaosPanel, "[Не появляться]");
			}
			else if (TankChaosAllow[i] == 1) {
				DrawPanelItem(TankChaosPanel, "[Готов]");
				DrawPanelItem(TankChaosPanel, "Не появляться");
			}
			
			SendPanelToClient(TankChaosPanel, i, TankChaosPanelHandler, 2);
			CloseHandle(TankChaosPanel);
			//панелька капец
						
			if (!IsNormalAlt(i)) PrintHintText(i, "[TankChaos] Вы слишком высоко, спуститесь ниже.");
						
			if ((FoundInRange == false) && (InfTankChaos > 0) && (TankChaosAllow[i] == 1) && (IsNormalAlt(i)))  {
					
					
					for(new l=1; l<=GetMaxClients(); l++) {
						if ((IsNormalPlayer(l)) && (GetClientTeam(l) == 3)) {
							TankChaos[l] = 1;
						}
					}
					
					CreateTimer(30.0, ChaosTankResetTimer, 0);
					SpawnTank(i);
					TankChaosEvent = 1;
					CreateTimer(15.0, ResetTankChaosEvent, 0);
					InfTankChaos--;
					PrintToChatAll("\x03[sync] \x01Танковый хаос начался около \x04%s", GetName(i));
					GetClientAbsOrigin(i, chaospos);
							
					return;
										
			}
		}	
	}
	
	CreateTimer(1.0, StartTankChaosTimer);
			
}

public Action:ChaosTankResetTimer(Handle:timer, any: client)
{
	for(new i=1; i<=GetMaxClients(); i++) {
		if ((TankChaos[i] == 1) && (!IsTank(i))) {
			//if (IsValidPlayer(i)) PrintToChat(i, "Ваше время вышло!");
			//if (IsValidEntity(i)) SetEntityHealth(i, 0);
			TankChaos[i] = 0;
		}
		
	}
	
	for(new i=1; i<=GetMaxClients(); i++) {
		if ((IsNormalPlayer(i)) && (IsTank(i))) {
			CreateTimer(1.0, ChaosTankResetTimer, 0);
			return;
		}
	}
}

public Action:SpawnTankTimer(Handle:timer, any: client)
{
	if (InfTankChaos <= 0) return;
	
	if (client == 0) client = GetFirstValidClientID(3);
	if (client > 0) {
		RemoveFlags();
		FakeClientCommand(client, "z_spawn_old tank");
		AddFlags();	
	}
	
	if (InfTankChaos > 0) {
		CreateTimer(1.0, SpawnTankTimer, 0);
		InfTankChaos--;
	}
}

static CreateGasCloud(client, Float:g_pos[3])
{

	new Float:targettime = GetEngineTime() + 10;
	
	new Handle:data = CreateDataPack();
	WritePackCell(data, client);
	WritePackFloat(data, g_pos[0]);
	WritePackFloat(data, g_pos[1]);
	WritePackFloat(data, g_pos[2]);
	WritePackFloat(data, targettime);
	
	CreateTimer(2.0, Point_Hurt, data, TIMER_REPEAT);
}

public Action:Point_Hurt(Handle:timer, Handle:hurt)
{
	ResetPack(hurt);
	new client = ReadPackCell(hurt);
	decl Float:g_pos[3];
	g_pos[0] = ReadPackFloat(hurt);
	g_pos[1] = ReadPackFloat(hurt);
	g_pos[2] = ReadPackFloat(hurt);
	new Float:targettime = ReadPackFloat(hurt);
	
	CloseHandle(hurt);
	if (targettime - GetEngineTime() < 0)
	{
		return Plugin_Stop;
	}
	
	if (!IsClientInGame(client)) client = -1;
	// dummy line to prevent compiling errors. the client data has to be read or the datapack becomes corrupted
	
	decl Float:targetVector[3];
	decl Float:distance;
	new Float:radiussetting = 250;
	decl String:soundFilePath[256];
	Format(soundFilePath, sizeof(soundFilePath), "player/survivor/voice/choke_5.wav");
	new bool:shakeenabled = true;
	new damage = 1;
	new bool:slowenabled = true;
	
	for (new target = 1; target <= MaxClients; target++)
	{
		if (!target
		|| !IsClientInGame(target)
		|| !IsPlayerAlive(target)
		|| GetClientTeam(target) != 2)
		{
			continue;
		}

		GetClientEyePosition(target, targetVector);
		distance = GetVectorDistance(targetVector, g_pos);
		
		if (distance > radiussetting
		|| !IsVisibleTo(g_pos, targetVector)) continue;

		EmitSoundToClient(target, soundFilePath);

		PrintCenterText(target, "%t", "smokershake");

		if (shakeenabled)
		{
			/*
			new Handle:hBf = StartMessageOne("Shake", target);
			BfWriteByte(hBf, 0);
			BfWriteFloat(hBf,6.0);
			BfWriteFloat(hBf,1.0);
			BfWriteFloat(hBf,1.0);
			EndMessage();
			CreateTimer(1.0, StopShake, target);
			*/
		}
		
		if (slowenabled && !IsFakeClient(target))
		{
			isincloud[target] = true;
			CreateTimer(2.0, ClearMeleeBlock, target);
		}
		
		applyDamage(damage, target, client);
	}
	
	return Plugin_Continue;
}

static applyDamage(damage, victim, attacker)
{ 
	new Handle:dataPack = CreateDataPack();
	WritePackCell(dataPack, damage);  
	WritePackCell(dataPack, victim);
	WritePackCell(dataPack, attacker);
	
	CreateTimer(0.10, timer_stock_applyDamage, dataPack);
}

public Action:timer_stock_applyDamage(Handle:timer, Handle:dataPack)
{
	ResetPack(dataPack);
	new damage = ReadPackCell(dataPack);  
	new victim = ReadPackCell(dataPack);
	new attacker = ReadPackCell(dataPack);
	CloseHandle(dataPack);
	
	decl Float:victimPos[3], String:strDamage[16], String:strDamageTarget[16];
	
	if (!IsClientInGame(victim)) return;
	GetClientEyePosition(victim, victimPos);
	IntToString(damage, strDamage, sizeof(strDamage));
	Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
	
	new entPointHurt = CreateEntityByName("point_hurt");
	if(!entPointHurt) return;
	
	new bool:reviveblock = true;

	// Config, create point_hurt
	DispatchKeyValue(victim, "targetname", strDamageTarget);
	DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
	DispatchKeyValue(entPointHurt, "Damage", strDamage);
	DispatchKeyValue(entPointHurt, "DamageType", reviveblock ? "65536" : "263168");
	DispatchSpawn(entPointHurt);
	
	// Teleport, activate point_hurt
	TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entPointHurt, "Hurt", (attacker > 0 && attacker < MaxClients && IsClientInGame(attacker)) ? attacker : -1);
	
	// Config, delete point_hurt
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	//RemoveEdict(entPointHurt);
	AcceptEntityInput(entPointHurt, "Kill");
}

static bool:IsVisibleTo(Float:position[3], Float:targetposition[3])
{
	decl Float:vAngles[3], Float:vLookAt[3];
	
	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
	
	// execute Trace
	new Handle:trace = TR_TraceRayFilterEx(position, vAngles, MASK_SHOT, RayType_Infinite, _TraceFilter);
	
	new bool:isVisible = false;
	if (TR_DidHit(trace))
	{
		decl Float:vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		
		if ((GetVectorDistance(position, vStart, false) + TRACE_TOLERANCE) >= GetVectorDistance(position, targetposition))
		{
			isVisible = true; // if trace ray lenght plus tolerance equal or bigger absolute distance, you hit the target
		}
	}
	else
	{
		LogError("Tracer Bug: Player-Zombie Trace did not hit anything, WTF");
		isVisible = true;
	}
	CloseHandle(trace);
	
	return isVisible;
}

public Action:StopShake(Handle:timer, any:target)
{
	return;
	
	if (!IsNormalPlayer(target)) return;
	
	new Handle:hBf = StartMessageOne("Shake", target);
	BfWriteByte(hBf, 1);
	BfWriteFloat(hBf, 0.0);
	BfWriteFloat(hBf, 0.0);
	BfWriteFloat(hBf, 0.0);
	EndMessage();
}

public Action:ClearMeleeBlock(Handle:timer, Handle:target)
{
	isincloud[target] = false;
}

public Action:TeleportToFirstTank(Handle:timer, any:iCid)
{
	if (!IsNormalPlayer(iCid)) return;
//	|| (!IsNormalPlayer(g_iTank_MainId))) return;
	//decl Float:vecOrigin[3];
	//GetClientAbsOrigin(g_iTank_MainId,vecOrigin);
	//TeleportEntity(iCid,vecOrigin,NULL_VECTOR,NULL_VECTOR);		
	TeleportEntity(iCid,chaospos,NULL_VECTOR,NULL_VECTOR);		
}

public Action:BlockRocks(Handle:timer, any:iCid)
{
	new iEntid = GetEntDataEnt2(iCid,g_iAbilityO);
	if (iEntid == -1) return;
	SetEntDataFloat(iEntid, g_iNextActO+8, GetGameTime() + 10000.0, true);
}

public bool:_TraceFilter(entity, contentsMask)
{
	if (!entity || !IsValidEntity(entity)) // dont let WORLD, or invalid entities be hit
	{
		return false;
	}
	
	return true;
}

public ResetMassAbilites()
{
	PrintToChatAll("\x04[XTREME]\x03%t", "resetbonus");
	ResetPoisonClient();
	SurvMassSpeedUp = 0;
	SurvMassSpeedUp_Sum = 0;
	SurvMassRegen = 0;
	SurvMassRegen_Sum = 0;
	SurvAutoMiniGun = 0;
	SurvAutoMiniGun_Sum = 0;
	SurvZombieSurprize = 0;
	SurvZombieSurprize_Sum = 0;
	SurvUntouchable = 0;
	SurvUntouchable_Sum = 0;
	SurvPhysPower = 0;
	SurvVictimShield = 0;
	SurvPhysPower_Sum = 0;
	InfMassArmor = 0;
	InfMassArmor_Sum = 0;
	InfMassSlow = 0;
	InfMassSlow_Sum = 0;
	InfTankChaos = 0;
	InfTankChaos_Sum = 0;
	InfDeathCloud = 0;
	InfDeathCloud_Sum = 0;
	InfZombieApoc = 0;
	InfZombieApoc_Sum = 0;
	InfPoison = 0;
	InfPoison_Sum = 0;
	InfBummerRain = 0;
	InfBummerRain_Sum = 0;
	
	InfAllowMass = 1;
	SurvAllowMass = 1;
	
}

public UpdateMassCosts()
{
	new sc, ic;
	sc = GetTeamHumanCount(2);
	ic = GetTeamHumanCount(3);
	
	if (sc <= 3) SurvMassSpeedUp_Cost=190; else SurvMassSpeedUp_Cost = (sc*65)-(sc*10);
	if (sc <= 3) SurvMassRegen_Cost=250; else SurvMassRegen_Cost = (sc*80)-(sc*10);
	if (sc <= 3) SurvAutoMiniGun_Cost=200; else SurvAutoMiniGun_Cost = (sc*65)-(sc*10);
	if (sc <= 3) SurvZombieSurprize_Cost=220; else SurvZombieSurprize_Cost = (sc*70)-(sc*10);
	if (sc <= 3) SurvUntouchable_Cost=180; else SurvUntouchable_Cost = (sc*60)-(sc*10);
	if (sc <= 3) SurvPhysPower_Cost=200; else SurvPhysPower_Cost = (sc*75)-(sc*10);
	if (sc <= 3) SurvVictimShield_Cost=180; else SurvVictimShield_Cost = (sc*60)-(sc*10);
	
	
	if (ic <= 3) InfMassArmor_Cost=220; else InfMassArmor_Cost = (ic*70)-(ic*10);
	if (ic <= 3) InfMassSlow_Cost=200; else InfMassSlow_Cost = (ic*65)-(ic*10);
	if (ic <= 3) InfDeathCloud_Cost=180; else InfDeathCloud_Cost = (ic*60)-(ic*10);
	if (ic <= 3) InfZombieApoc_Cost=190; else InfZombieApoc_Cost = (ic*65)-(ic*10);
	if (ic <= 3) InfPoison_Cost=170; else InfPoison_Cost = (ic*50)-(ic*10);
	
	if (ic <= 3) InfBummerRain_Cost=160; else InfBummerRain_Cost = (ic*60)-(ic*10);
	if (ic <= 3) InfTankChaos_Cost=200; else InfTankChaos_Cost = (ic*80)-(ic*10);
}

public Action:SetTankHP(any:client) 
{
	if (!IsNormalPlayer(client)) return;
	if (CurrentGamemodeID != 1) return;
	
	new HumansLimit = GetConVarInt(FindConVar("l4d_survivor_limit"))+GetConVarInt(FindConVar("l4d_infected_limit"));

	new TankHP = 30000;
	
	decl String:CurMap[255];
	GetCurrentMap(CurMap, sizeof(CurMap)) ;
	//PrintToChatAll("Tank HP: %i, HC: %i, CurMap: %s", TankHP, HumansLimit, CurMap);
	
	
	if (StrEqual(CurMap,"c1m1_hotel")) { TankHP = 4000; }
	else { 
		if (HumansLimit == 8) TankHP = 15000;
		else if (HumansLimit == 10) TankHP = 15000; 
		else if (HumansLimit == 12) TankHP = 25000; 
		else if (HumansLimit == 14) TankHP = 30000; 
		else if (HumansLimit == 16) TankHP = 40000;
		//TankHP = 10000;
	}
	
	if (TankChaos[client] > 0) TankHP = 5000;
	if ((IsTank(client)) && (IsNormalPlayer(client))) {
		SetEntityHealth(client, TankHP);
	}
	//PrintToChatAll("Tank HP set: %i", TankHP);
	OriginHealth[client] = TankHP;

}

public Action:SetVictim(Handle:timer, any:client)
{
	if (IsEnd()) return;
	if (GetTeamHumanCount(2) < 4) return;
	
	if ( (IsValidPlayer(VictimID)) && (GetClientTeam(VictimID) == 2) && (IsPlayerAlive(VictimID)) )
			return;
	
	
	//new RandomNum = GetRandomInt(1, GetTeamHumanCount(2));
	new pC = 0;
	new pA[GetTeamHumanCount(2)];
	    		
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ( (IsValidPlayer(i)) && (GetClientTeam(i) == 2) && (IsPlayerAlive(i)) && (i != LastVictimID) ) {
			pA[pC] = i;
			pC++;
		}
	}
	pC--;
	if (pC <= 0) return;
							
				VictimID = pA[GetRandomInt(0,pC)];
				LastVictimID = VictimID;
								
				PrintToChatAll("\x04[Xtreme] \x05%t - \x03%s - \x05%t", "Victimran1", GetName(VictimID), "victimchosen");
				if (SurvSpecialShield[VictimID] > 0) {
					PrintToChat(VictimID, "\x04%t \x04%t", "vicshieldrm", "Victimran1");
					SurvSpecialShield[VictimID] = 0;
				}
				if (SurvIncSpecialShield[VictimID] > 0) {
					PrintToChat(VictimID, "\x04%t \x04%t", "vicshieldrm1", "Victimran1");
					SurvIncSpecialShield[VictimID] = 0;
				}
								
				return;
	
}

bool:IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

public Action:VictimRegen(Handle:timer, any:client)
{
	if (IsEnd()) return;
	
	if (!IsValidPlayer(VictimID))  return;
	if (GetClientTeam(VictimID) == 1) return;
	if (points[VictimID] <= 0) return;
	
	new Health = GetClientHealth(VictimID);
	Health = Health + 1;
	if (Health <= 200) {
		SetEntityHealth(VictimID, Health);	
		points[VictimID] = points[VictimID] - 1;
	}
}

public Action:VictimRender(Handle:timer, any:client)
{
	if (IsEnd()) return;
	if (!IsValidPlayer(VictimID))  return;
	if (GetClientTeam(VictimID) == 1) return;
	//AttachParticle(VictimID, PARTICLE_SPIT, 5.0, 0.0);
	decl String:arg[255];
	Format(arg, sizeof(arg), "#%i 255 0 0", GetClientUserId(VictimID));
	//CheatCommand(VictimID, "sm_flareclient", arg);
	
	//if ( !IsValidEntRef(VictimRenderEnt[VictimID]) )
	//	VictimRenderEnt[VictimID] = CreateEnvSprite(VictimID, "0 255 255");	
	
	//L4D2_SetEntityGlow(VictimID, L4D2Glow_Constant, 100000, 0, {175, 5, 193}, true); // glow para victima
	AnimateBlock(VictimID, 175, 5, 193);
	
}

public Action:cmd_setvictim(client, args)
{
	//CreateTimer(1.0, SetVictim);
}

public Action:cmd_showtankdamage(client, args)
{
	if  (ShowTankDamage) {
		ShowTankDamage = false;
		PrintToChat(client, "ShowTankDamage: False");
	}
	else {
		ShowTankDamage = true;
		PrintToChat(client, "ShowTankDamage: True");	
	}	
	
}


public Action:cmd_whovictim(client, args) {
	
	if (!IsValidPlayer(client)) return;
	
	if (IsValidPlayer(VictimID)) {
		PrintHintText(client, "%t: %s", "Victim", GetName(VictimID));
		PrintToChat(client, "\x05%t\x01: \x03%s", "Victim", GetName(VictimID));
	}
	else {
		PrintHintText(client, "%t: %t", "Victim", "novictim");
		PrintToChat(client, "\x05%t\x01: \x03none", "Victim", "novictim");
	}
	
	PrintToChat(client, "\x05%t \x01%t,", "Victim", "VictimPhys");
	PrintToChat(client, "\x05%t \x01%t.", "Victim", "VictimPointsConvert");
	PrintToChat(client, "\x01%t \x05%t \x01%t.", "ForVictimDamage", "ToVictim", "ZombiesGetPoints");
	PrintToChat(client, "\x01%t \x05%t \x01 %t \x03+100 \x01%t.", "If", "Victim2", "VictimIncap", "Points");
	PrintToChat(client, "\x01%t \x05%t \x01 %t \x03+300 \x01%t.", "If", "Victim2", "VictimKilled", "Points");
	
	
	
}

public Action:CheckBankTimer(Handle:timer, any:client)
{
	if (IsEnd()) return;
	CheckBankActivate();
			
	for (new i = 1; i <= GetMaxClients(); i++) {
	
		if ((IsNormalPlayer(i)) && (GetClientTeam(i) == 2))  {
				
			new String:CurClassname[255];
			GetClientModel(i, CurClassname, sizeof(CurClassname));
			if ( (!StrEqual(CurClassname, SkinClassname[i])) && ((Shields[i] > 0) && (IsValidEdict(Shields[i])) && (IsValidEntity(Shields[i]))) )
				killshield(i);
			SkinClassname[i] = CurClassname;
				
			if (SurvSpecialShield[i] > 0) {
				if (!((Shields[i] > 0) && (IsValidEdict(Shields[i])) && (IsValidEntity(Shields[i])))) {
					if (IsClientAlive(i)) Shields[i] = CreateShield(i, 180.0, 0.0, 90.0);
				}
			}
			else if ( (Shields[i] > 0) && (IsValidEdict(Shields[i])) && (IsValidEntity(Shields[i])) ) { 
				killshield(i);
			}
		}
	}
		
		
}

string:GetTextByMassId(String:sid[255])
{
	decl String:result[255];
	Format(result, sizeof(result), "none");
	if(StrEqual(sid, "SurvMassSpeedUp")) Format(result, sizeof(result), "%t", "MassSpeedUp");
	else if(StrEqual(sid, "SurvMassRegen")) Format(result, sizeof(result), "%t", "MassRegen");
	else if(StrEqual(sid, "SurvAutoMiniGun")) Format(result, sizeof(result), "%t", "Turret");
	else if(StrEqual(sid, "SurvZombieSurprize")) Format(result, sizeof(result), "%t", "SurprizeZombies");
	else if(StrEqual(sid, "SurvUntouchable")) Format(result, sizeof(result), "%t", "Untouchable");
	else if(StrEqual(sid, "SurvPhysPower")) Format(result, sizeof(result), "%t", "PhysPower");
	else if(StrEqual(sid, "SurvVictimShield")) Format(result, sizeof(result), "%t", "SurvVictimShield");
	else if(StrEqual(sid, "InfMassSlow")) Format(result, sizeof(result), "%t", "SlowDown");
	else if(StrEqual(sid, "InfMassArmor")) Format(result, sizeof(result), "%t", "InfMassArmor");
	else if(StrEqual(sid, "InfTankChaos")) Format(result, sizeof(result), "%t", "TankChaos");
	else if(StrEqual(sid, "InfDeathCloud")) Format(result, sizeof(result), "%t", "DeathCloud");
	else if(StrEqual(sid, "InfZombieApoc")) Format(result, sizeof(result), "%t", "ZombieApocalypsis");
	else if(StrEqual(sid, "InfPoison")) Format(result, sizeof(result), "%t", "Poison");
	
	return result;
}

stock GetCostById(String:sid[255])
{
	if(StrEqual(sid, "SurvMassSpeedUp")) return SurvMassSpeedUp_Cost;
	else if(StrEqual(sid, "SurvMassRegen")) return SurvMassRegen_Cost;
	else if(StrEqual(sid, "SurvAutoMiniGun")) return SurvAutoMiniGun_Cost;
	else if(StrEqual(sid, "SurvZombieSurprize")) return SurvZombieSurprize_Cost;
	else if(StrEqual(sid, "SurvUntouchable")) return SurvUntouchable_Cost;
	else if(StrEqual(sid, "SurvPhysPower")) return SurvPhysPower_Cost;
	else if(StrEqual(sid, "SurvVictimShield")) return SurvVictimShield_Cost;
	else if(StrEqual(sid, "InfMassSlow")) return InfMassSlow_Cost;
	else if(StrEqual(sid, "InfMassArmor")) return InfMassArmor_Cost;
	else if(StrEqual(sid, "InfTankChaos")) return InfTankChaos_Cost;
	else if(StrEqual(sid, "InfDeathCloud")) return InfDeathCloud_Cost;
	else if(StrEqual(sid, "InfZombieApoc"))return InfZombieApoc_Cost;
	else if(StrEqual(sid, "InfPoison")) return InfPoison_Cost;
	
	return 0;
}

stock GetSumById(String:sid[255])
{
	if(StrEqual(sid, "SurvMassSpeedUp")) return SurvMassSpeedUp_Sum;
	else if(StrEqual(sid, "SurvMassRegen")) return SurvMassRegen_Sum;
	else if(StrEqual(sid, "SurvAutoMiniGun")) return SurvAutoMiniGun_Sum;
	else if(StrEqual(sid, "SurvZombieSurprize")) return SurvZombieSurprize_Sum;
	else if(StrEqual(sid, "SurvUntouchable")) return SurvUntouchable_Sum;
	else if(StrEqual(sid, "SurvPhysPower")) return SurvPhysPower_Sum;
	else if(StrEqual(sid, "SurvVictimShield")) return SurvVictimShield_Sum;
	else if(StrEqual(sid, "InfMassSlow")) return InfMassSlow_Sum;
	else if(StrEqual(sid, "InfMassArmor")) return InfMassArmor_Sum;
	else if(StrEqual(sid, "InfTankChaos")) return InfTankChaos_Sum;
	else if(StrEqual(sid, "InfDeathCloud")) return InfDeathCloud_Sum;
	else if(StrEqual(sid, "InfZombieApoc"))return InfZombieApoc_Sum;
	else if(StrEqual(sid, "InfPoison")) return InfPoison_Sum;
	
	return 0;
}

public Action:ResetSAM(Handle:timer) 
{
	if (TeamBonusDelayTimeLeftS > 0) {
		TeamBonusDelayTimeLeftS--;
		CreateTimer(1.0, ResetSAM);
		return;
	}
	if (SurvAllowMass != 1) PrintToChatAll("\x01[\x04Xtreme\x01] \x05%t \x01%t \x03%t\x01!", "TheSurvivors", "cannowactivate", "CommandBonus");
	SurvAllowMass = 1;
}

public Action:ResetIAM(Handle:timer) 
{
	if (TeamBonusDelayTimeLeftI > 0) {
		TeamBonusDelayTimeLeftI--;
		CreateTimer(1.0, ResetIAM);
		return;
	}
	if (InfAllowMass != 1) PrintToChatAll("\x01[\x04Xtreme\x01] \x05%t \x01%t \x03%t\x01!", "TheInfected", "cannowactivate", "CommandBonus");
	InfAllowMass = 1;
}

bool:IsAllAlive(team)
{
	new lc = 0;
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsNormalPlayer(i)) && (GetClientTeam(i) == team) && (IsPlayerAlive(i)))
			lc++;
	}
	
	new Handle:il = FindConVar("l4d_infected_limit");
	new mi;
	if (il > 0) mi = GetConVarInt(il);
	else mi = 4;
	
	if (lc < mi) return false;
	else return true;
	
}

public Action:CheckTanksTimer(Handle:timer, any:client)  //Escudo vip
{
	if (IsEnd()) return;
		
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i))
		if (GetClientTeam(i) == 2) {
			if (VipBonus[i][1] == 2) { //Si el jugador es vip2
				if (VictimID != i) {	//Si no es victima
					if (CurrentGamemodeID == 0) // Si el juego es coop
					SurvIncSpecialShield[i] = 5; //Escudo especial 2 para coop
					else SurvIncSpecialShield[i] = 2; //Escudo especial 2 para versus
					
					if (CurrentGamemodeID == 0) // Si el juego es coop
					SurvSpecialShield[i] = 10;  // Escudo especial 1 para coop
					else SurvSpecialShield[i] = 15; // Escudo especial 2 para versus
					
					//PrintToChat(i, "\x01%t: \x04%t %t: 10", "Activated", "SpecialShield", "disponible");
					//PrintToChat(i, "\x01%t: \x04%t 2 %t: 5", "Activated", "SpecialShield", "disponible");
				}
				
			}
			else if (VipBonus[i][1] == 3) { // Si el jugador es vip3
				if (CurrentGamemodeID == 0) { //Si el juego es coop
					if (VictimID != i) { // Si el jugador no es victima
						SurvIncSpecialShield[i] = 10; // Escudo especial 2 para vip3
						SurvSpecialShield[i] = 15; // Escudo especial 1 para vip3
						
						//PrintToChat(i, "\x01%t: \x04%t 2  \x01%t: 20", "Activated", "SpecialShield", "disponible");
						//PrintToChat(i, "\x01%t: \x04%t \x01%t: 30", "Activated", "SpecialShield", "disponible");
					}
					SurvShoving[i] = 600; // Resistencia para vip3 coop
					//SurvFirearmsMaster[i] = 600;
					
					
						//PrintToChat(i, "\x01%t: \x04%t \x01%t 10 %t.", "Activated", "Stamina", "Duration", "Minutes");
						//PrintToChat(i, "\x01%t: \x04%t \x01%t 10 %t.", "Activated", "SurvBulletDamage", "Duration", "Minutes");
				}
				else { // Si es versus para vip3
					if (VictimID != i) { // Si no es victima
						SurvIncSpecialShield[i] = 5; // Escudo especial 2 para vip3 versus
						SurvSpecialShield[i] = 10;	// Escudo especial 1 para vip3 versus
						
						//PrintToChat(i, "\x01%t: \x04%t 2  \x01%t: 5", "Activated", "SpecialShield", "disponible");
						//PrintToChat(i, "\x01%t: \x04%t \x01%t: 10", "Activated", "SpecialShield", "disponible");
					}
					SurvShoving[i] = 300; // Resistencia para vip3 versus
					//SurvFirearmsMaster[i] = 300;
					
					
					//PrintToChat(i, "\x01%t: \x04%t \x01%t 5 %t.", "Activated", "Stamina", "Duration", "Minutes");
					//PrintToChat(i, "\x01%t: \x04%t \x01%t 5 %t.", "Activated", "SurvBulletDamage", "Duration", "Minutes");
				}
																
				MA_Rebuild();
				//if (Timer22 == INVALID_HANDLE) Timer22 = CreateTimer(300.0, SurvShovingStop, i);
								
				
			}
			else if (VipBonus[i][1] == 4) { // Si el jugador es vip3
				if (CurrentGamemodeID == 0) { //Si el juego es coop
					if (VictimID != i) { // Si el jugador no es victima
						SurvIncSpecialShield[i] = 15; // Escudo especial 2 para vip3
						SurvSpecialShield[i] = 20; // Escudo especial 1 para vip3
						
						//PrintToChat(i, "\x01%t: \x04%t 2  \x01%t: 20", "Activated", "SpecialShield", "disponible");
						//PrintToChat(i, "\x01%t: \x04%t \x01%t: 30", "Activated", "SpecialShield", "disponible");
					}
					SurvShoving[i] = 600; // Resistencia para vip3 coop
					SurvFirearmsMaster[i] = 600;
					
					
						//PrintToChat(i, "\x01%t: \x04%t \x01%t 10 %t.", "Activated", "Stamina", "Duration", "Minutes");
						//PrintToChat(i, "\x01%t: \x04%t \x01%t 10 %t.", "Activated", "SurvBulletDamage", "Duration", "Minutes");
				}
				else { // Si es versus para vip3
					if (VictimID != i) { // Si no es victima
						SurvIncSpecialShield[i] = 10; // Escudo especial 2 para vip3 versus
						SurvSpecialShield[i] = 15;	// Escudo especial 1 para vip3 versus
						
						//PrintToChat(i, "\x01%t: \x04%t 2  \x01%t: 5", "Activated", "SpecialShield", "disponible");
						//PrintToChat(i, "\x01%t: \x04%t \x01%t: 10", "Activated", "SpecialShield", "disponible");
					}
					SurvShoving[i] = 300; // Resistencia para vip3 versus
					//SurvFirearmsMaster[i] = 300;
					
					
					//PrintToChat(i, "\x01%t: \x04%t \x01%t 5 %t.", "Activated", "Stamina", "Duration", "Minutes");
					//PrintToChat(i, "\x01%t: \x04%t \x01%t 5 %t.", "Activated", "SurvBulletDamage", "Duration", "Minutes");
				}
																
				MA_Rebuild();
				//if (Timer22 == INVALID_HANDLE) Timer22 = CreateTimer(300.0, SurvShovingStop, i);
								
				
			}
			
			if (VipBonus[i][17] > 0) {
				points[i] = points[i] + VipBonus[i][17];
				VipBonus[i][17] = 0;
			}
			
			if (VipBonus[i][1] > 0) VipBonus[i][1] = 0;
		}
		
		
		new hp = 0;
				
		if ((IsNormalPlayer(i)) && (IsPlayerAlive(i)) && (GetClientTeam(i) == 3) && (CurrentGamemodeID == 1)) {
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
			if ((InfHulk[i] > 0) && (IsTank(i))) {
				
				hp = GetClientHealth(i);
				if (hp > 1000) SetEntityRenderColor(i, 0, 255, 0, 255);
				else if (hp <= 1000) SetEntityRenderColor(i, 0, 200, 0, 255);
				else if (hp <= 900) SetEntityRenderColor(i, 0, 190, 0, 255);
				else if (hp <= 800) SetEntityRenderColor(i, 0, 170, 0, 255);
				else if (hp <= 700) SetEntityRenderColor(i, 0, 150, 0, 255);
				else if (hp <= 600) SetEntityRenderColor(i, 0, 130, 0, 255);
				else if (hp <= 500) SetEntityRenderColor(i, 0, 100, 0, 255);
				else if (hp <= 400) SetEntityRenderColor(i, 0, 80, 0, 255);
				else if (hp <= 300) SetEntityRenderColor(i, 0, 70, 0, 255);
				else if (hp <= 200) SetEntityRenderColor(i, 0, 60, 0, 255);
				else if (hp <= 100) SetEntityRenderColor(i, 0, 50, 0, 255);
							
				if (GetClientHealth(i) > HulkHP) {
					SetEntityHealth(i, HulkHP);
					OriginHealth[i] = GetClientHealth(i);
				}
				new iEntid = GetEntDataEnt2(i,g_iAbilityO);
				if (iEntid == -1) return;
				if (GetEntDataFloat(iEntid, g_iNextActO+8) < GetGameTime() + 1000.0) {
					SetEntDataFloat(iEntid, g_iNextActO+8, GetGameTime() + 10000.0, true);
				}
			}
			else if ((InfTankChaos > 0) || (TankChaos[i] > 0) || (TankChaosEvent == 1)) {
				if (IsTank(i)) {
					if (TankChaos[i] <= 0) TankChaos[i] = 1;
					
					SetEntityRenderMode(i, RENDER_TRANSCOLOR);
					SetEntityRenderColor(i, 0, 0, 255, 255);
					
					if (GetClientHealth(i) > InfTankChaos_HP) {
						SetEntityHealth(i, InfTankChaos_HP);
						OriginHealth[i] = GetClientHealth(i);
					}
					new iEntid = GetEntDataEnt2(i,g_iAbilityO);
					if (iEntid == -1) return;
					if (GetEntDataFloat(iEntid, g_iNextActO+8) < GetGameTime() + 1000.0) {
						SetEntDataFloat(iEntid, g_iNextActO+8, GetGameTime() + 10000.0, true);
					}
				}
				//if ((!IsTank(i)) && (TankChaos[i] > 0) && (IsValidPlayer(i))) {
				//	for (new j = 1; j <= GetMaxClients(); j++) {
				//		if (IsNormalPlayer(j))
				//			if ((IsFakeClient(j)) && (IsTank(j))) {
				//				L4D2_TakeOverZombieBot(i,j);
				//			}
				//	}
				//	CreateTimer(2.0, CheckClientTankChaos, i);
				//}
			}
			else if (IsTank(i)) {
				hp = GetClientHealth(i);
				if (hp >= 1000) SetEntityRenderColor(i, 255, 255, 255, 255);
				else if ((hp <= 1000) && (hp > 900)) SetEntityRenderColor(i, 50, 0, 0, 255);
				else if ((hp <= 900) && (hp > 800)) SetEntityRenderColor(i, 80, 0, 0, 255);
				else if ((hp <= 800) && (hp > 700)) SetEntityRenderColor(i, 100, 0, 0, 255);
				else if ((hp <= 700) && (hp > 600)) SetEntityRenderColor(i, 120, 0, 0, 255);
				else if ((hp <= 600) && (hp > 500)) SetEntityRenderColor(i, 140, 0, 0, 255);
				else if ((hp <= 500) && (hp > 400)) SetEntityRenderColor(i, 160, 0, 0, 255);
				else if ((hp <= 400) && (hp > 300)) SetEntityRenderColor(i, 180, 0, 0, 255);
				else if ((hp <= 300) && (hp > 200)) SetEntityRenderColor(i, 200, 0, 0, 255);
				else if ((hp <= 200) && (hp > 100)) SetEntityRenderColor(i, 230, 0, 0, 255);
				else if ((hp <= 100) && (hp > 0)) SetEntityRenderColor(i, 255, 0, 0, 255);
			}
			
		}
	}
}

// CTerrorPlayer::TakeOverZombieBot(CTerrorPlayer*)
// Client takes control of an Infected Bot - Tank included. Causes odd shit to happen if an alive client's current SI class doesnt match the taken over one, exception tank
// i suggest CullZombie or State Transitioning until classes match before calling this
stock L4D2_TakeOverZombieBot(client, target)
{
	//DebugPrintToAll("TakeOverZombieBot being called, client %N target %N", client, target);
	SDKCall(sdkTakeOverZombieBot, client, target);
}

public Action:CheckClientTankChaos(Handle:timer, any:client)
{
	if (!IsTank(client)) { 
		for (new j = 1; j <= GetMaxClients(); j++) {
			if (IsNormalPlayer(j))
			if ((IsFakeClient(j)) && (IsTank(j))) {
				L4D2_TakeOverZombieBot(client,j);
			}
		}
	}
	if (!IsTank(client)) { TankChaos[client] = 0; }
}

GetMinigunCount()
{
	decl String:Classname[128];
	new mCount = 0;
	
	for (new i = GetMaxClients(); i <= GetMaxEntities(); i++) {
		if (IsValidEntity(i)) {
			GetEdictClassname(i, Classname, sizeof(Classname));
			if(StrContains(Classname, "prop_minigun", false) != -1) {
				mCount++;
			}
		}
	}
	
	return mCount;
}

public Action:CheckMinigunTimer(Handle:timer, any:data) 
{
	//if (CurrentGamemodeID == 0) SurvAutoMiniGun_Limit = 2; else SurvAutoMiniGun_Limit = 1;
	if (GetMinigunCount() != MinigunStartCount + 1) {
		PrintToChatAll("\x01[\x03Xtreme\x01] Failed creating auto-gun, trying again");
		for (new i = 1; i <= GetMaxClients(); i++) {
			if (IsNormalPlayer(i)) 
			if ((GetClientTeam(i) == 2) && (IsClientAlive(i))) {
				ServerCommand("sm_machine #%i", GetClientUserId(i));
				PrintToChatAll("\x05%t \x01%t \x04%s", "Turret", "TurretAppear", GetName(i));
				MinigunTimeout--;
				if (MinigunTimeout > 0) CreateTimer(1.0, CheckMinigunTimer, INVALID_HANDLE);
				TurrelCount++;
				return;
			}
		}
	} else MinigunTimeout = 0;
}

GetBizonID()
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (StrEqual(GetName(i),"Natan"))) return i;
	}

}

public Event_FinaleVehicleLeaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	fVL = true;
}


public Action:cmd_ShowfVL(client, args)
{
	if (fVL == true) PrintToChat(client, "True");
	else PrintToChat(client, "False");
}

bool:IsEnd()
{
	if (RoundEnd > 0) return true;
	return false;
}

public GetClientVipStatus(any:client)
{
	if ( (!IsValidPlayer(client)) || (MapEnd > 0) || (db == INVALID_HANDLE) ) return;
	
	//LogToFile(logfilepath, "GetClientVipStatus: %i %s", client, GetName(client));	
	
	if (IsRegProcess) return;
	IsRegProcess = true;
	
	decl String:SteamID[255];
	decl String:query[1024];
    GetClientAuthString(client, SteamID, sizeof(SteamID));

	PrintToChat(client, "%t %s(%s)", "reqvip", GetName(client), SteamID);
	
	Format(query, sizeof(query), "SELECT status FROM reg_name WHERE steamid = '%s'", SteamID);
	SQL_TQuery(db, regnamequery2, query, client);
	
}

public regnamequery2(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if ( (hndl == INVALID_HANDLE) || (!IsValidPlayer(client)) || (MapEnd > 0) )
	{
		IsRegProcess = false;
		//LogToFile(logfilepath, "regnamequery2 failed: %i %s", client, GetName(client));	
		return;
	}

	if (!SQL_HasResultSet(hndl)) {
		IsRegProcess = false;
		//LogToFile(logfilepath, "regnamequery2 failed2: %i %s", client, GetName(client));	
		return;
	}
	
	//LogToFile(logfilepath, "regnamequery2: %i %s", client, GetName(client));	
	
	if (SQL_FetchRow(hndl))
	{		
		VipStatus[client] = SQL_FetchInt(hndl, 0);
		VipStatusWas[client] = VipStatus[client];
		if (VipStatusDisabled[client] == 1) {
			VipStatusWas[client] = VipStatus[client];
			VipStatus[client] = 1;
			EmitSoundToAll(VIPJOIN);
			PrintToChatAll("\x01%t \x04%s \x01 %t \x05%i", "eljugador", GetName(client), "setvip1", VipStatus[client]);
		}
		//if ( (hostport == 27226) && (VipStatus[client] > 1) ) VipStatus[client] = 1;
	}
	else VipStatus[client] = 0;
	
	VipBonus[client][1] = VipStatus[client];
	if (VipStatus[client] == 2) {		// Si el jugador es VIP2
		if (CurrentGamemodeID == 0) { //Si el juego es COOP
			VipBonus[client][2] = 2; //mira laser vip2 coop
			VipBonus[client][3] = 4; //Municion incendiaria vip2 coop
			VipBonus[client][4] = 4; //Municion explosiva vip2 coop
			VipBonus[client][5] = 4; //limite de AWP (no funca)
			//VipBonus[client][17] = 300; //Puntos al inicio del primer mapa 
		}
		else { 						   // Si el juego NO es COOP
			VipBonus[client][2] = 2; //mira laser vip2 vs
			VipBonus[client][3] = 4; //Municion incendiaria vip2 vs
			VipBonus[client][4] = 4; //Municion explosiva vip2 vs
			VipBonus[client][5] = 0; //limite de AWP (no funca)
			//VipBonus[client][17] = 0; //Puntos al inicio del primer mapa 
		}
	}
	if (VipStatus[client] == 3) 
	{
		if (CurrentGamemodeID == 0) 
		{
			VipBonus[client][2] = 4;
			VipBonus[client][3] = 6;
			VipBonus[client][4] = 6;
			VipBonus[client][5] = 2;
			//VipBonus[client][17] = 300;
			VipBonus[client][20] = 1;
			VipBonus[client][21] = 0;
			VipBonus[client][22] = 10;
		}
		else
		{
			VipBonus[client][2] = 4;
			VipBonus[client][3] = 6;
			VipBonus[client][4] = 6;
			VipBonus[client][5] = 1;
			//VipBonus[client][17] = 0;
			VipBonus[client][20] = 1;
			VipBonus[client][21] = 0;
			VipBonus[client][22] = 10;
		}
		
		if (VipStatus[client] == 3) {
			VipBonus[client][18] = 5;
			VipBonus[client][10] = 1;
			VipBonus[client][11] = 1;
			VipBonus[client][12] = 1;
			VipBonus[client][13] = 1;
			VipBonus[client][14] = 1;
			VipBonus[client][15] = 1;
			VipBonus[client][16] = 1;
		}
	}
	else if (VipStatus[client] == 4) {
		if (CurrentGamemodeID == 0) 
		{
			VipBonus[client][2] = 8;
			VipBonus[client][3] = 10;
			VipBonus[client][4] = 10;
			VipBonus[client][5] = 2;
			//VipBonus[client][17] = 300;
			VipBonus[client][20] = 1;
			VipBonus[client][21] = 1;
			VipBonus[client][22] = 10;
		}
		else
		{
			VipBonus[client][2] = 8;
			VipBonus[client][3] = 10;
			VipBonus[client][4] = 10;
			VipBonus[client][5] = 1;
			//VipBonus[client][17] = 0;
			VipBonus[client][20] = 1;
			VipBonus[client][21] = 1;
			VipBonus[client][22] = 10;
		}
		
		if (VipStatus[client] == 4) 
		{
			VipBonus[client][18] = 5;
			VipBonus[client][10] = 2;
			VipBonus[client][11] = 2;
			VipBonus[client][12] = 2;
			VipBonus[client][13] = 2;
			VipBonus[client][14] = 2;
			VipBonus[client][15] = 2;
			VipBonus[client][16] = 2;
		}
		}

	PrintToChat(client, "\x04[VIP] \x01%t.", "setvip2");
	
	CreateTimer(1.0, DelayedRegFinish, client);
}

public Action:DelayedRegFinish(Handle:timer, any:client)
{
	IsRegProcess = false;
		
	new toDel = FindValueInArray(toReg, client);
	if (toDel != -1) RemoveFromArray(toReg, toDel);
	
	if (GetArraySize(toReg) > 0)
		GetClientVipStatus(GetArrayCell(toReg, 0));
}

public Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
		
	if (!IsNormalPlayer(iCid)) return Plugin_Continue;
		
	TankSpawnCount++;
	if ( (TankSpawnCount == 1) && (IsFakeClient(iCid)) && (GetNotTankHumanCount() > 0) ) return Plugin_Continue;
	TankSpawnCount = 0;
	CreateTimer(1.5, TankSpawnCheck, iCid);	
	
	new Health;
	
	CreateTimer(0.5, ShowTankInfoTimer, iCid);
	
	if ( (CurrentGamemodeID == 0) && (IsNormalPlayer(iCid)) && (GetClientTeam(iCid) == 3) ) {
		new chance = 0;
		new bool: doColor = false;
						
		chance = GetRandomInt(1,100);
		
		if (chance <= 20) { InfBonusDamage[iCid] = 1; doColor = true; }
		chance = GetRandomInt(1,100);
		if (chance <= 20) { InfAcidClaws[iCid] = 1; doColor = true; }
		chance = GetRandomInt(1,100);
		if (chance <= 20) { InfMeeleShield[iCid] = 1; doColor = true; }
		chance = GetRandomInt(1,100);
		if (chance <= 20) { InfRegen[iCid] = 1; doColor = true; }
		chance = GetRandomInt(1,100);
		
		if (doColor)  {
			CreateTimer(0.5, DoColorTimer, iCid);
		}
	}
	
	if (InfHulk[iCid] == 1) {
		ResetClientInfAbilites(iCid);
		InfHulk[iCid] = 1;
		
		SetEntityRenderMode(iCid, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iCid, 0, 255, 0, 255);
		//CreateTimer(0.1, SetHulkHealth, iCid);
		//CreateTimer(0.5, SetHulkHealth, iCid);
		
		SetEntityHealth(iCid, HulkHP);
		Health = GetClientHealth(iCid);
		PrintToChat(iCid, "\x04%t: \x05%i", "hremain", Health);
		OriginHealth[iCid] = Health;
		
		FrustrationReset[iCid] = 2;
		CreateTimer(0.5, ResetFrustration, iCid);				
		
		//new Float:scale = GetEntPropFloat(iCid, Prop_Send, "m_flModelScale");
		//SetEntPropFloat(iCid, Prop_Send, "m_flModelScale", 0.5);
		
		if (InfTankChaos > 0) InfTankChaos--;
		
		return Plugin_Continue;
	}
	else if ((InfTankChaos > 0) || (TankChaos[iCid] > 0)) {
		
		return Plugin_Continue;
		ResetClientInfAbilites(iCid);
		
		//InfTankChaos--;
		//PrintToChatAll("Tank created, left: %i", InfTankChaos);
				
		TankChaos[iCid] = 1;
		FrustrationReset[iCid] = 2;
		CreateTimer(0.5, ResetFrustration, iCid);		
				
		SetEntityRenderMode(iCid, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iCid, 0, 0, 255, 255);
		
		CreateTimer(0.5, SetTankHPTimer, iCid);
		CreateTimer(0.5, BlockRocks, iCid);

		ChaosTankCount++;		
		
		if ((ChaosTankCount > 1) && (IsNormalPlayer(g_iTank_MainId))) {
			CreateTimer(0.5, TeleportToFirstTank, iCid);
		}
		else {
			g_iTank_MainId = iCid;
			if (InfTankChaos > 0) CreateTimer(1.0, SpawnTankTimer, 0);
		}
					
		if (InfTankChaos <= 0) ChaosTankCount = 0;
		
		return Plugin_Continue;
	} 
	else {
		CreateTimer(0.5, SetTankHPTimer, iCid);
		ResetClientInfAbilites(iCid);
	}
	
}

public Action:SetTankHPTimer(Handle:timer, any:client)
{
	SetTankHP(client);
}

public Action:TankSpawnCheck(Handle:timer, any:client)
{
	if (!IsNormalPlayer(client)) return;
	if (IsTank(client)) 
	{
		new thp = GetClientHealth(client);
		if (InfHulk[client] > 0) PrintToChatAll("\x04 %t\x01(\x03%s\x01) HP: \x03%i", "hulkcomes", GetName(client), thp);
		else if (TankChaos[client] > 0) PrintToChatAll("\x01Призван \x04ChaosTank\x01(\x03%s\x01) HP: \x03%i", GetName(client), thp);
		else PrintToChatAll("\x04 %t \x01(\x03%s\x01) HP: \x03%i", "tankcomes",GetName(client), thp);
		{
		switch(GetRandomInt(1,5))
			{
			case 1:
			EmitSoundToAll(TANKSPAWN1);
			case 2:
			EmitSoundToAll(TANKSPAWN2);
			case 3:
			EmitSoundToAll(TANKSPAWN3);
			case 4:
			EmitSoundToAll(TANKSPAWN4);
			case 5:
			EmitSoundToAll(TANKSPAWN5);
			}
		}
	}
}

public Action:cmd_regframe(client, args)
{
//	for (new iI=1 ; iI<=GetMaxClients() ; iI++)
//	{
//		if (IsValidPlayer(i)) && () 
		//{
//			g_iMARegisterCount++;
			//g_iMARegisterIndex[g_iMARegisterCount]=iI;
		//}
	//}	
}

public Action:event_heal_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	//if (CampaignOver || IsEnd()) return;
			
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new client_h = GetClientOfUserId(GetEventInt(event, "subject"));
	
	//CreateTimer(0.5, CheckClientHPTimer, client);
}

public Action:CheckClientHPTimer(Handle:timer, any:client)
{
	if (!IsNormalPlayer(client)) return;
	new ClientHP = GetClientHealth(client);
	if (ClientHP < 10) SetEntityHealth(client, 80);
}

public ResetPoisonClient()
{
	if (IsNormalPlayer(InfPoison)) {
		SetEntDataFloat(InfPoison, g_flLagMovement, 1.0, true);
		SetEntityRenderMode(InfPoison, RENDER_TRANSCOLOR);
		SetEntityRenderColor(InfPoison, 255, 255, 255, 255);
	}
}

ChosePoisonClient()
{
	InfPoison = 0;
	for (new i = 1; ((i <= GetMaxClients()) && (InfPoison == 0)); i++) {
		if ((IsNormalPlayer(i)) && (GetClientTeam(i) == 2) && (IsPlayerAlive(i)) && (!IsPlayerIncapped(i)) && (VipStatus[i] <= 2))	{
			InfPoison = i;
		}
	}
	
	if (InfPoison == 0) {
		for (new i = 1; ((i <= GetMaxClients()) && (InfPoison == 0)); i++) {
			if ((IsNormalPlayer(i)) && (GetClientTeam(i) == 2) && (IsPlayerAlive(i)) && (VipStatus[i] <= 2))	{
				InfPoison = i;
			}
		}
	}
	
	if (InfPoison == 0) {
		PrintToChatAll("\x04 %t.", "choosepoison");
		return 0;
	}
	
	
	if (SurvSpecialShield[InfPoison] < 10) {
		PrintToChat(InfPoison, "\x04[Xtreme] \x05%t \x03%t \x05%t", "poisoninf1", "SpecialShield", "poisoninf2");
		SurvSpecialShield[InfPoison] = 10;
	}
	return InfPoison;
	
}

public ResetPoisonEff()
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsNormalPlayer(i)) {
			SetEntDataFloat(i, g_flLagMovement, 1.0, true);
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
			SetEntityRenderColor(i, 255, 255, 255, 255);
		}
	}
}

public Action:cmd_gameframe(client, args)
{
	PrintToChat(client, "g_iMARegisterCount: %i", g_iMARegisterCount);
}

public Action:ForceSuicideTimer(Handle:timer, any:client)
{
	if (IsValidPlayer(client)) ForcePlayerSuicide(client);
}

public Action:AllowActivateBuyClientResetTimer(Handle:timer, any:client)
{
	AllowActivateBuyClient[client] = 1;
}

public RemoveUncommon(any: client)
{
	new String:class[255];
	for(new i = GetMaxClients()+1; i < GetMaxEntities(); i++)
		{
			if(IsValidEntity(i) && IsValidEdict(i))
			{
				GetEdictClassname(i, class,sizeof(class));
				PrintToChat(client, "class %i: %s", i, class);
				if (StrEqual(class, "infected"))
				{
													
				}
			}
		}
}

public TankChaosPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (!IsNormalPlayer(param1)) return;
	if (param2 == 1) TankChaosAllow[param1] = 1;
	else if (param2 == 2) TankChaosAllow[param1] = 0;
}

public Action:PounceTimer(Handle:timer, any:client)
{
	if ((IsEnd()) || (!IsNormalPlayer(client))) return;
	
	PounceTime[client] = PounceTime[client] + 1;
	
	if ( (((GetClientTeam(client) == 2) && (SurvSpecialShield[client] > 0)) || ((GetClientTeam(client) == 3) && (InfSpecialShield[client] > 0))) && (PounceTime[client] <= 5) && (IsPounced[client] == 1) ) {
		//ShowEffect(client);
		if (GetClientTeam(client) == 2) AttachParticle(client, EFFECT_PARTICLE_SURVIVOR, 1.0, 0.0);
		else if (GetClientTeam(client) == 3) AttachParticle(client, EFFECT_PARTICLE_INFECTED, 1.0, 0.0);
	}
	else 
	if ( (GetClientTeam(client) == 2) && (SurvSpecialShield[client] > 0) && ((PounceTime[client] > 5) || (IsPounced[client] == 0)) ) {
		SurvSpecialShield[client] -= 1;
		PrintToChat(client, "\x04%t \x03%i", "shieldrem", SurvSpecialShield[client]);
		return;
	}
	else 
	if ( (GetClientTeam(client) == 3) && (InfSpecialShield[client] > 0) && ((PounceTime[client] > 5) || (IsPounced[client] == 0))) {
		InfSpecialShield[client] -= 1;
		PrintToChat(client, "\x04%t \x03%i", "shieldrem", InfSpecialShield[client]);
		return;
	}
		
		
	if (IsPounced[client] == 1) CreateTimer(1.0, PounceTimer, client);
	
}

public Action:IncTimer(Handle:timer, any:client)
{
	if ((IsEnd()) || (!IsNormalPlayer(client))) return;
	
	IncTime[client] = IncTime[client] + 1;
	if ( ((GetClientTeam(client) == 2) && (SurvIncSpecialShield[client] > 0)) && (IncTime[client] <= 20) && (IsInc[client] == 1) ) {
		//ShowEffect(client);
		if (GetClientTeam(client) == 2) AttachParticle(client, EFFECT_PARTICLE_SURVIVOR, 1.0, 0.0);
		else if (GetClientTeam(client) == 3) AttachParticle(client, EFFECT_PARTICLE_INFECTED, 1.0, 0.0);
	}
	else if ((GetClientTeam(client) == 2) && (SurvIncSpecialShield[client] > 0) && ((IncTime[client] > 20) || (IsInc[client] == 0))) {
		SurvIncSpecialShield[client] =  SurvIncSpecialShield[client] - 1;	
		PrintToChat(client, "\x04%t \x03%i", "shield2rem", SurvIncSpecialShield[client]);
		return;
	}
	
	if (IsInc[client] == 1) CreateTimer(1.0, IncTimer, client);
	
}

CreateEnvSprite(client, const String:sColor[])
{
	new entity = CreateEntityByName("env_sprite");
	if( entity == -1)
	{
		LogError("Failed to create 'env_sprite'");
		return 0;
	}

	DispatchKeyValue(entity, "rendercolor", sColor);
	DispatchKeyValue(entity, "model", MODEL_SPRITE);
	DispatchKeyValue(entity, "spawnflags", "3");
	DispatchKeyValue(entity, "rendermode", "9");
	DispatchKeyValue(entity, "GlowProxySize", "0.3");
	DispatchKeyValue(entity, "renderamt", "230");
	DispatchKeyValue(entity, "scale", "0.7");
	DispatchSpawn(entity);

	// Attach
	SetVariantString("!activator"); 
	AcceptEntityInput(entity, "SetParent", client);
	SetVariantString("pills");
	AcceptEntityInput(entity, "SetParentAttachment");

	new Float:pos[3];
	SetVector(pos, 0.0, -2.0,  -2.0);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	return EntIndexToEntRef(entity);
}


public Event_Player_Class(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	new entity = VictimRenderEnt[iCid];
	if ( IsValidEntRef(entity) )	AcceptEntityInput(entity, "Kill");	
	new bid = GetBizonID();
	if (bid > 0) PrintToChat(bid, "\x04%s \x01Clase cambiada", GetName(iCid));
	//VictimRenderEnt[iCid] = 0;
}

public Action:cmd_vip(client, args) 
{
	if (!IsValidPlayer(client)) return;
	if (VipStatus[client] < 1) {
		PrintToChat(client, "\x04[VIP] \x01%s : \x04 VIP: %i", GetName(client), VipStatus[client]);
		PrintToChat(client, "\x04[VIP] \x01%t.\n\x04[VIP] \x01%t \x04 https://xtreme-infection.com/vip", "novip1", "noskins2");
		return;
	}
	
	if (GetClientTeam(client) == 1) {
		PrintToChat(client, "\x04[VIP]\x03%t.", "nospecmenu");
		return;
	}
		if (VipStatus[client] == 1)	{
			PrintToChat(client, "\x04[VIP] \x01%s : \x04 VIP: %i", GetName(client), VipStatus[client]);
			PrintToChat(client, "\x04[VIP] \x01%t: \x04%t \n\x04[VIP] \x01%t: \x04 %t \n\x04[VIP] \x01%t: \x04 https://xtreme-infection.com/vip", "Activated", "reserslot", "Activated", "nokick", "details");
			//return;
		}
	if 		
		(GetClientTeam(client) == 2) {
			(VipStatus[client] == 2);
			
			PrintToChat(client, "\x04[VIP] \x01%s : \x04 VIP: %i", GetName(client), VipStatus[client]);
			PrintToChat(client, "\x04[VIP] \x01%t: \x04%i \n\x04[VIP] \x01%t: \x04 %i \n\x04[VIP] \x01%t: \x04 https://xtreme-infection.com/vip", "LaserAim", VipBonus[client][2], "IncendiaryAmmo", VipBonus[client][3], "details");
		}
		if (GetClientTeam(client) == 3) {
			(VipStatus[client] == 2);	
			PrintToChat(client, "\x04[VIP] \x01%s : \x04 VIP: %i", GetName(client), VipStatus[client]);
			PrintToChat(client, "\x04[VIP] \x01%t \n\x04[VIP] \x01%t: \x04 https://xtreme-infection.com/vip", "novip2", "details");
		}
	SetGlobalTransTarget(client);
	
	new Handle:VipPanel = CreatePanel();
	new String:text[255];
	
	//Format(text, sizeof(text), "%s", GetName(client)); //Bugged with Country name prefix [CL] 29-04-18
	Format(text, sizeof(text), "Vip System");
	SetPanelTitle(VipPanel, text);
	
	Format(text, sizeof(text), "Your VIP status:%i", VipStatus[client]);
	DrawPanelText(VipPanel, text);
	
	DrawPanelText(VipPanel, "Choose what you like:");		
	if (GetClientTeam(client) == 2) {

		Format(text, sizeof(text), "%t: %i", "LaserAim", VipBonus[client][2]);			
		DrawPanelItem(VipPanel, text);
		Format(text, sizeof(text), "%t: %i", "IncendiaryAmmo", VipBonus[client][3]);			
		DrawPanelItem(VipPanel, text);
		Format(text, sizeof(text), "%t: %i", "ExplosiveAmmo", VipBonus[client][4]);			
		DrawPanelItem(VipPanel, text);
		//Format(text, sizeof(text), "Лимит %t: %i", "AWP", VipBonus[client][5]);			
		//DrawPanelText(VipPanel, text);
		Format(text, sizeof(text), "Skins Menu");
		DrawPanelItem(VipPanel, text);
		if (VipStatus[client] >= 3) {
			Format(text, sizeof(text), "Firearms: %i", VipBonus[client][20]);			
			DrawPanelItem(VipPanel, text);
			Format(text, sizeof(text), "Melee: %i", VipBonus[client][21]);			
			DrawPanelItem(VipPanel, text);
		}

	}
	else if (GetClientTeam(client) == 3) {
		
		/*if (VipStatus[client] != 3)	{
			PrintToChat(client, "Для данного VIP статуса данное меню не доступно.");
			return;
		}
		*/
		Format(text, sizeof(text), "%t Mutant-Bomb: %i", "Common", VipBonus[client][10]);			
		DrawPanelItem(VipPanel, text);
		Format(text, sizeof(text), "%t Mutant-Fire: %i", "Common", VipBonus[client][11]);			
		DrawPanelItem(VipPanel, text);
		Format(text, sizeof(text), "%t Mutant-Ghost: %i", "Common", VipBonus[client][12]);			
		DrawPanelItem(VipPanel, text);
		Format(text, sizeof(text), "%t Mutant-Mind: %i", "Common", VipBonus[client][13]);			
		DrawPanelItem(VipPanel, text);
		Format(text, sizeof(text), "%t Mutant-Smoke: %i", "Common", VipBonus[client][14]);			
		DrawPanelItem(VipPanel, text);
		Format(text, sizeof(text), "%t Mutant-Spit: %i", "Common", VipBonus[client][15]);			
		DrawPanelItem(VipPanel, text);
		Format(text, sizeof(text), "%t Mutant-Tesla: %i", "Common", VipBonus[client][16]);			
		DrawPanelItem(VipPanel, text);
	}

	Format(text, sizeof(text), "%t", "Close");			
	DrawPanelItem(VipPanel, text);	
		
	SendPanelToClient(VipPanel, client, VipPanelHandler, 30);
	CloseHandle(VipPanel);
	
}

public VipPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (param1 <= MAXPLAYERS+1) ShowDistance[param1] = 0;
	
	if (!IsValidPlayer(param1)) return;
	
	SetGlobalTransTarget(param1);
		
	if (GetClientTeam(param1) == 1) {
		PrintToChat(param1, "\x04[VIP] \x03%t", "nospecmenu");
		return;
	}
	//if (GetClientTeam(param1) == 3) {
//		PrintToChat(param1, "\x04[VIP] \x01Бонусы только для \x02Живых\x01.");
		//return;
	//}
	
	if (GetClientTeam(param1) == 2) {
		if (param2 == 1) {
			if (VipBonus[param1][2] > 0) {
				PrintToChat(param1, "\x05%t \x01%t.", "LaserAim", "Installed");
				RemoveFlags();
				FakeClientCommand(param1, "upgrade_add LASER_SIGHT");
				AddFlags();
				VipBonus[param1][2] -= 1;
			}
			else PrintToChat(param1, "\x04[VIP] \x01%t", "vipnoitem");
		}
		else if (param2 == 2) {
			if (VipBonus[param1][3] > 0) {
				PrintToChat(param1, "\x01%t: \x03%t", "Bought", "IncendiaryAmmo");
				RemoveFlags();
				FakeClientCommand(param1, "upgrade_add INCENDIARY_AMMO");
				AddFlags();
				LastUpgrade[param1] = 1;
				VipBonus[param1][3] -= 1;
			}
			else PrintToChat(param1, "\x04[VIP] \x01%t", "vipnoitem");
			
		}
		else if (param2 == 3) {
			if (VipBonus[param1][4] > 0) {
				PrintToChat(param1, "\x01%t: \x03%t", "Bought", "ExplosiveAmmo");
				RemoveFlags();
				FakeClientCommand(param1, "upgrade_add EXPLOSIVE_AMMO");
				AddFlags();	
				LastUpgrade[param1] = 2;
				VipBonus[param1][4] -= 1;
			}
			else PrintToChat(param1, "\x04[VIP] \x01%t", "vipnoitem");
		}
		else if (param2 == 5) {
			if (VipStatus[param1] < 3 ) return;
			VipWeaponsMenu(param1, 1);
		}
		else if (param2 == 4)
		{
		RemoveFlags();
		FakeClientCommand(param1, "sm_skins");
		AddFlags();	
		}
		else if (param2 == 6) {
			if (VipStatus[param1] < 3) return;
			VipWeaponsMenu(param1, 2);
		}
		else if (param2 == 7) {
			if (VipStatus[param1] < 3) return;
			VipWeaponsMenu(param1, 3);
		}
	}
	else if (GetClientTeam(param1) == 3) {
				
		//new Float:distance = GetDistance(param1, 800);
		//if (FloatCompare(distance, -1.0) != 0) {
	//		PrintToChat(param1, "\x05%t.", "ToClose");
	//		return;
	//	}
		if (param2 == 1) {
			if (VipBonus[param1][10] > 0) {
				PrintToChat(param1, "\x01%t: \x03Mutant-Bomb", "Common");
				RemoveFlags();
				MultiClientCmd(param1, "sm_mutantbomb", 10);
				AddFlags();		
				
				VipBonus[param1][10] -= 1;
			}
			else PrintToChat(param1, "\x04[VIP] \x01%t", "vipnoitem");
		}
		else if (param2 == 2) {
			if (VipBonus[param1][11] > 0) {
				PrintToChat(param1, "\x01%t: \x03Mutant-Fire", "Common");
				RemoveFlags();
				MultiClientCmd(param1, "sm_mutantfire", 11);
				AddFlags();				
				
				VipBonus[param1][11] -= 1;
			}
			else PrintToChat(param1, "\x04[VIP] \x01%t", "vipnoitem");
			
		}
		else if (param2 == 3) {
			if (VipBonus[param1][12] > 0) {
				PrintToChat(param1, "\x01%t: \x03Mutant-Ghost", "Common");
				RemoveFlags();
				MultiClientCmd(param1, "sm_mutantghost", 12);
				AddFlags();				
				
				VipBonus[param1][12] -= 1;
			}
			else PrintToChat(param1, "\x04[VIP] \x01%t", "vipnoitem");
			
		}
		else if (param2 == 4) {
			if (VipBonus[param1][13] > 0) {
				PrintToChat(param1, "\x01%t: \x03Mutant-Mind", "Common");
				RemoveFlags();
				MultiClientCmd(param1, "sm_mutantmind", 13);
				AddFlags();				
				
				VipBonus[param1][13] -= 1;
			}
			else PrintToChat(param1, "\x04[VIP] \x01%t", "vipnoitem");
			
		}
		else if (param2 == 5) {
			if (VipBonus[param1][14] > 0) {
				PrintToChat(param1, "\x01%t: \x03Mutant-Smoke", "Common");
				RemoveFlags();
				MultiClientCmd(param1, "sm_mutantsmoke", 14);
				AddFlags();			
				
				VipBonus[param1][14] -= 1;
			}
			else PrintToChat(param1, "\x04[VIP] \x01%t", "vipnoitem");
			
		}
		else if (param2 == 6) {
			if (VipBonus[param1][15] > 0) {
				PrintToChat(param1, "\x01%t: \x03Mutant-Spit", "Common");
				RemoveFlags();
				MultiClientCmd(param1, "sm_mutantspit", 15);
				AddFlags();			
				
				VipBonus[param1][15] -= 1;
			}
			else PrintToChat(param1, "\x04[VIP] \x01%t", "vipnoitem");
			
		}
		else if (param2 == 7) {
			if (VipBonus[param1][16] > 0) {
				PrintToChat(param1, "\x01%t: \x03Mutant-Tesla", "Common");
				RemoveFlags();
				MultiClientCmd(param1, "sm_mutanttesla", 16);
				AddFlags();	
				
				VipBonus[param1][16] -= 1;
			}
			else PrintToChat(param1, "\x04[VIP] \x01%t", "vipnoitem");
			
		}
	}
}
public CreateShield(any:client, Float: x,y,z)
{
	new ent;
	decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3]; 
	
	ent=CreateEntityByName("prop_dynamic_override"); 
	SetEntityModel(ent, MODEL_SHIELD);
	DispatchSpawn(ent);
	
	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 45;
	VecOrigin[1] += VecDirection[1] * 45;
	VecOrigin[2] += VecDirection[2] * 1;   
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	DispatchKeyValueVector(ent, "Angles", VecAngles);
	TeleportEntity(ent, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	new Float:ang[3];
	SetVector(ang, x, y, z);
	new Float:pos[3];
	SetVector(pos, -2.0, 14.0, 7.0);
	
	SetEntPropFloat(ent , Prop_Send,"m_flModelScale", 0.8);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	AttachEnt(client, ent, "medkit", pos, ang);
	
	return ent;
}

public Action:cmd_spawnshield(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spawnshield <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[255], String:arg3[255], String:arg4[255];
	GetCmdArg(1, arg, sizeof(arg));
		
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));	

	new Float: x = StringToFloat(arg2);
	new Float: y = StringToFloat(arg3);
	new Float: z = StringToFloat(arg4);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	new targetclient;
	if ((target_count = ProcessTargetString(
	arg,
	client,
	target_list,
	MAXPLAYERS,
	0,
	target_name,
	sizeof(target_name),
	tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			
			Shields[targetclient] = CreateShield(targetclient, x, y, z);
			ReplyToCommand(client, "SpawnShield on %s", GetName(targetclient));
		}
	}
	else
	{
		//ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}

AttachEnt(owner, ent, String:positon[]="medkit", Float:pos[3]=NULL_VECTOR,Float:ang[3]=NULL_VECTOR)
{
	decl String:tname[60];
	Format(tname, sizeof(tname), "target%d", owner);
	DispatchKeyValue(owner, "targetname", tname); 		
	DispatchKeyValue(ent, "parentname", tname);
	
	SetVariantString(tname);
	AcceptEntityInput(ent, "SetParent",ent, ent, 0); 	
	if(strlen(positon)!=0)
	{
		SetVariantString(positon); 
		AcceptEntityInput(ent, "SetParentAttachment");
	}
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
}

public Action:cmd_killshield(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_killshield <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
	GetCmdArg(1, arg, sizeof(arg));
			
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	new targetclient;
	if ((target_count = ProcessTargetString(
	arg,
	client,
	target_list,
	MAXPLAYERS,
	0,
	target_name,
	sizeof(target_name),
	tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			killshield(targetclient);
				
			ReplyToCommand(client, "KillShield on %s", GetName(targetclient));
		}
	}
	else
	{
		//ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public ResetAllShields()
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		killshield(i);
	}
}

public killshield(any: client)
{
	if ((Shields[client] > 0) && (IsValidEdict(Shields[client])) && (IsValidEntity(Shields[client]))) {
		AcceptEntityInput(Shields[client], "ClearParent");
		AcceptEntityInput(Shields[client], "Kill");
	}
	Shields[client] = 0;
}

public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
 	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));   
	 
	if (client > 0) killshield(client);
	if (bot > 0) killshield(bot);
}
public bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
 	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));   
	 
	if (client > 0) killshield(client);
	if (bot > 0) killshield(bot);

} 

public BuildBuyMenu10(any:client) 
{
	if (!IsValidPlayer(client)) return;
		decl String:text[40];
		decl String:title[40];
		
		SetGlobalTransTarget(client);
		
		new Handle:menu = CreateMenu(InfectedMenu);
					
		Format(text, sizeof(text),"%t (%i)", "Horde", GetConVarInt(PointsHorde));
		AddMenuItem(menu, "horde", text);
		
		Format(text, sizeof(text),"%t Riot Cop (%i)", "Horde", InfRiot_Cost);
		AddMenuItem(menu, "riot", text);

		Format(text, sizeof(text),"%t Ceda (%i)", "Horde", InfCeda_Cost);
		AddMenuItem(menu, "ceda", text);
		
		Format(text, sizeof(text),"%t Сlown (%i)", "Horde", InfClown_Cost);
		AddMenuItem(menu, "clown", text);
		
		Format(text, sizeof(text),"%t Mudman (%i)", "Horde", InfMudman_Cost);
		AddMenuItem(menu, "mud", text);
		
		Format(text, sizeof(text),"%t Roadcrew (%i)", "Horde", InfRoadcrew_Cost);
		AddMenuItem(menu, "roadcrew", text);
		
		Format(text, sizeof(text),"%t Jimmy (%i)", "Horde", InfJimmy_Cost);
		AddMenuItem(menu, "jimmy", text);
		
		Format(text, sizeof(text),"%t Fallen (%i)", "Horde", InfFallen_Cost);
		AddMenuItem(menu, "fallen", text);
				
		// 1 = riot, 2 = ceda, 4 = clown, 8 = mudman, 16 = roadcrew, 32 = jimmy, 64 = fallen); riot + ceda + roadcrew = 19
		
		Format(title, sizeof(title),"%t: %d", "YourPoints", points[client]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, 30);
} 

public BuildBuyMenu11(any:client)
{
	if (!IsValidPlayer(client)) return;
		decl String:text[40];
		decl String:title[40];
		
		SetGlobalTransTarget(client);
		
		ShowDistance[client] = 1;
		MinDistance[client] = 800;
		CreateTimer(0.1, ShowDistanceTimer, client);
		
		new Handle:menu = CreateMenu(InfectedMenu);
	
		Format(text, sizeof(text),"%t Riot Cop (%i)", "Common", InfOneRiot_Cost);
		AddMenuItem(menu, "one riot", text);

		Format(text, sizeof(text),"%t Ceda (%i)", "Common", InfOneCeda_Cost);
		AddMenuItem(menu, "one ceda", text);
		
		Format(text, sizeof(text),"%t Сlown (%i)", "Common", InfOneClown_Cost);
		AddMenuItem(menu, "one clown", text);
		
		Format(text, sizeof(text),"%t Mudman (%i)", "Common", InfOneMudman_Cost);
		AddMenuItem(menu, "one mud", text);
		
		Format(text, sizeof(text),"%t Roadcrew (%i)", "Common", InfOneRoadcrew_Cost);
		AddMenuItem(menu, "one roadcrew", text);
		
		Format(text, sizeof(text),"%t Jimmy (%i)", "Common", InfOneJimmy_Cost);
		AddMenuItem(menu, "one jimmy", text);
		
		Format(text, sizeof(text),"%t Fallen (%i)", "Common", InfOneFallen_Cost);
		AddMenuItem(menu, "one fallen", text);
								
		// 1 = riot, 2 = ceda, 4 = clown, 8 = mudman, 16 = roadcrew, 32 = jimmy, 64 = fallen); riot + ceda + roadcrew = 19
		
		Format(title, sizeof(title),"%t: %d", "YourPoints", points[client]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, 30);
} 

PushCommon(common, client)
{
	// TARGET
	new Float:vAng[3], Float:vPos[3], g_fConfTeslaForce = 500, g_fConfTeslaForceZ = 500;
	
	// TELEPORT
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);
	GetEntPropVector(client, Prop_Data, "m_angRotation", vAng);
	GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAng, vAng);
	ScaleVector(vAng, g_fConfTeslaForce);
	vAng[2] = g_fConfTeslaForceZ;
	TeleportEntity(common, NULL_VECTOR, NULL_VECTOR, vAng);
}

stock bool:makeexplosion(attacker = 0, inflictor = -1, const Float:attackposition[3], const String:weaponname[] = "", magnitude = 800, radiusoverride = 0, Float:damageforce = 0.0, flags = 0){ 
    
    new explosion = CreateEntityByName("env_physexplosion"); 
     
    if(explosion != -1) 
    { 
        DispatchKeyValueVector(explosion, "Origin", attackposition); 
         
        decl String:intbuffer[64]; 
        IntToString(magnitude, intbuffer, 64); 
        DispatchKeyValue(explosion,"iMagnitude", intbuffer); 
        if(radiusoverride > 0) 
        { 
            IntToString(radiusoverride, intbuffer, 64); 
            DispatchKeyValue(explosion,"iRadiusOverride", intbuffer); 
        } 
         
        if(damageforce > 0.0) 
            DispatchKeyValueFloat(explosion,"DamageForce", damageforce); 

        if(flags != 0) 
        { 
            IntToString(flags, intbuffer, 64); 
            DispatchKeyValue(explosion,"spawnflags", intbuffer); 
        } 

        if(!StrEqual(weaponname, "", false)) 
            DispatchKeyValue(explosion,"classname", weaponname); 

        DispatchSpawn(explosion); 
        if((IsClientConnected(attacker)) && (IsClientInGame(attacker))) 
                { 
            SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", attacker); 
                new clientTeam = GetEntProp(attacker, Prop_Send, "m_iTeamNum"); 
                        SetEntProp(explosion, Prop_Send, "m_iTeamNum", clientTeam); 
                } 

        if(inflictor != -1) 
            SetEntPropEnt(explosion, Prop_Data, "m_hInflictor", inflictor); 

             
        AcceptEntityInput(explosion, "Explode"); 
        AcceptEntityInput(explosion, "Kill"); 
         
        return (true); 
    } 
    else 
        return (false); 
}  

public Action:cmd_point_hurt(client, args)
{
	if (!IsValidPlayer(client)) return Plugin_Handled;

	if (GetCmdArgs() != 3) {
		PrintToChat(client, "Wrong arg count");
		return;
	}
	
	new String: arg1[100];
	decl String:arg2[100];
	decl String:arg3[100];
		
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	
	new dmg, dmg_type, dmg_radius;
	dmg = StringToInt(arg1);
	dmg_type = StringToInt(arg2);
	dmg_radius = StringToInt(arg3);
	
	new iEnt = GetClientAimTarget(client, false);
	decl String:iEntClassName[255];
	if (IsValidEdict(iEnt)) {
		GetEdictClassname(iEnt, iEntClassName, 255);
		PrintToChat(client, "target classname: \x05$%s", iEntClassName);
	}
	else return;
	
	HurtPoint(client, iEnt, dmg, dmg_type, dmg_radius);
}

HurtPoint(client, ent, dmg, dmg_type, dmg_radius)
{
	if (!IsValidPlayer(client)) return;
	if (!IsValidEdict(ent))  return;
	
	new Float: pos[3];
	decl String: StrDamage[16];
	decl String:StrDamageType[16];
	decl String:StrDamageRadius[16];
	decl String:strDamageTarget[16];
	
	Format(StrDamageType, sizeof(StrDamage), "%i", dmg);
	Format(StrDamageType, sizeof(StrDamageType), "%i", dmg_type);
	Format(StrDamageRadius, sizeof(StrDamageRadius), "%i", dmg_radius);
	Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", ent);
	
	//GetClientAbsOrigin(client, pos);
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	pos[2]+=1.0;
	
	new pointHurt = CreateEntityByName("point_hurt");    
	DispatchKeyValue(ent, "targetname", strDamageTarget);  
	DispatchKeyValue(pointHurt, "DamageTarget", strDamageTarget);	
	DispatchKeyValue(pointHurt, "Damage", StrDamage);        
	DispatchKeyValue(pointHurt, "DamageRadius", StrDamageRadius);    
	DispatchKeyValue(pointHurt, "DamageType", StrDamageType);   
	//DispatchKeyValue(pointHurt, "DamageDelay", "1.0");    
	DispatchSpawn(pointHurt); 
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(pointHurt, "Hurt", (client > 0 && client < MaxClients && IsClientInGame(client)) ? client : -1);
	
	//PrintToChat(client, "point_hurt: Damage %s, DamageType %s, DamageRadius %s, TargetName %s  successfully created", StrDamage, StrDamageType, StrDamageRadius, strDamageTarget);
	
	DispatchKeyValue(pointHurt, "classname", "point_hurt");
	DispatchKeyValue(ent, "targetname", "null");
	AcceptEntityInput(pointHurt, "Kill");
}

public Action:cmd_point_push(client, args)
{
	if (!IsValidPlayer(client)) return Plugin_Handled;

	if (GetCmdArgs() != 2) {
		PrintToChat(client, "Wrong arg count");
		return;
	}
	
	new String: arg1[100];
	decl String:arg2[100];
		
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
		
	new force, radius;
	force = StringToInt(arg1);
	radius = StringToInt(arg2);
		
	new iEnt = GetClientAimTarget(client, false);
	decl String:iEntClassName[255];
	if (IsValidEdict(iEnt)) {
		GetEdictClassname(iEnt, iEntClassName, 255);
		PrintToChat(client, "target classname: \x05$%s", iEntClassName);
	}
	else return;
	
	PushPoint(client, iEnt, force, radius);
}

PushPoint(client, ent, force, radius)
{
	if (!IsValidPlayer(client)) return;
	if (!IsValidEdict(ent))  return;
	
    new Float:pos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	pos[2]+=10;
	
	decl String: StrForce[16];
	decl String:StrRadius[16];
	decl String:StrTarget[16];
	
	Format(StrForce, sizeof(StrForce), "%i", force);
	Format(StrRadius, sizeof(StrRadius), "%i", radius);
	Format(StrTarget, sizeof(StrTarget), "pushme%d", ent);
	
    new push = CreateEntityByName("point_push");         
	DispatchKeyValue(ent, "targetname", StrTarget);    
    DispatchKeyValue(push, "magnitude", StrForce);                     
    DispatchKeyValue(push, "radius", StrRadius);                     
    SetVariantString("spawnflags 24"); 
    AcceptEntityInput(push, "AddOutput");
    DispatchSpawn(push);   
    TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
    AcceptEntityInput(push, "Enable");
    
	PrintToChat(client, "point_push: StrForce %s, StrRadius %s, StrTarget %s  successfully created", StrForce, StrRadius, StrTarget);
	
	CreateTimer(0.5, DeletePushForce, push);
}


public Action:DeletePushForce(Handle:timer, any:ent)
{
	 if (IsValidEntity(ent))
	 {
		 decl String:classname[64];
		 GetEdictClassname(ent, classname, sizeof(classname));
		 if (StrEqual(classname, "point_push", false))
				{
 					AcceptEntityInput(ent, "Disable");
					AcceptEntityInput(ent, "Kill"); 
					RemoveEdict(ent);
				}
	 }
}

public Action:cmd_explode(client, args)
{
	if (!IsValidPlayer(client)) return;
	
	new Float: pos[3];
	GetClientAbsOrigin(client, pos);
	if (makeexplosion(client, -1, pos, "", 800, 600, 0.0, 1) == true) 
		PrintToChat(client, "makeexplosion success");
	else PrintToChat(client, "makeexplosion failure");
	
}

public BuildBuyMenu12(any:client)
{
	if (!IsValidPlayer(client)) return;
		decl String:text[40];
		decl String:title[40];
		
		SetGlobalTransTarget(client);
		
		//ShowDistance[client] = 1;
		//MinDistance[client] = 800;
		//CreateTimer(0.1, ShowDistanceTimer, client);
		
		new Handle:menu = CreateMenu(InfectedMenu);
	
		Format(text, sizeof(text),"%t Mutant-Bomb (%i)", "Common", InfMutantBomb_Cost);
		AddMenuItem(menu, "mutantbomb", text);

		Format(text, sizeof(text),"%t Mutant-Fire (%i)", "Common", InfMutantFire_Cost);
		AddMenuItem(menu, "mutantfire", text);
						
		Format(text, sizeof(text),"%t Mutant-Ghost (%i)", "Common", InfMutantGhost_Cost);
		AddMenuItem(menu, "mutantghost", text);
		
		Format(text, sizeof(text),"%t Mutant-Mind (%i)", "Common", InfMutantMind_Cost);
		AddMenuItem(menu, "mutantmind", text);
		
		Format(text, sizeof(text),"%t Mutant-Smoke (%i)", "Common", InfMutantSmoke_Cost);
		AddMenuItem(menu, "mutantsmoke", text);
		
		Format(text, sizeof(text),"%t Mutant-Spit (%i)", "Common", InfMutantSpit_Cost);
		AddMenuItem(menu, "mutantspit", text);
		
		Format(text, sizeof(text),"%t Mutant-Tesla (%i)", "Common", InfMutantTesla_Cost);
		AddMenuItem(menu, "mutanttesla", text);
				
				
		Format(title, sizeof(title),"%t: %d", "YourPoints", points[client]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, 30);
} 

public MultiClientCmd(any: client, String: cmd[255], any: rcount)
{
	for(new i=0; i<=rcount; i++) {
		if (!IsValidPlayer(client)) return;
		FakeClientCommand(client, cmd);
	}
}

GetDistance(client, flMaxDistance)
{
	if (!IsNormalPlayer(client)) return -1;
	
	new Float: pos[3], tpos[3];
	new distance;
	
	GetClientAbsOrigin(client, pos);
		
	for(new i=1; i<=GetMaxClients(); i++) {
		if (IsNormalPlayer(i)) {
			if (GetClientTeam(i) == 2) {
				GetClientAbsOrigin(i, tpos);
				distance = RoundToNearest(GetVectorDistance(pos, tpos));
				//if (FloatCompare(distance, flMaxDistance) == -1) {
				if (distance < flMaxDistance) {
					return distance;
				}								
			}	
		}
	}
	
	return -1;
}

GetEntDistance(ent, flMaxDistance)
{
	if (!IsValidEntity(ent)) {
	  //PrintToChatAll("GetEntDistance: not valid ent");
	  return -1;
	}
	
	decl Float:entPos[3];
	decl Float:survivorPos[3];
	new distance;
	
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", entPos);
	//GetClientEyePosition(victim, survivorPos);
	//distance = GetVectorDistance(survivorPos, entPos);
	
	for(new i=1; i<=GetMaxClients(); i++) {
		if (IsNormalPlayer(i)) {
			if (GetClientTeam(i) == 2) {
				GetClientEyePosition(i, survivorPos);
				distance = RoundToNearest(GetVectorDistance(entPos, survivorPos));
				//PrintToChatAll("GetEntDistance: distance: %f", distance);
				//if (FloatCompare(distance, flMaxDistance) == -1) {
				if (distance < flMaxDistance) {
					return distance;
				}								
			}	
		}
	}
	//PrintToChatAll("GetEntDistance: clients not found");
	return -1;
}
	
public Action:ShowDistanceTimer(Handle:timer, any:client)
{
	if (!IsValidPlayer(client)) return;
	
	new distance = GetDistance(client, MinDistance[client]);
	//if (FloatCompare(distance, -1.0) == 0) 
	if (distance == -1)
		PrintHintText(client, "%t: OK", "distance", distance);
	else PrintHintText(client, "%t: %i / %i", "distance", distance, MinDistance[client]);
	
	if (ShowDistance[client] == 1) CreateTimer(0.5, ShowDistanceTimer, client);
}

// timer idea by dirtyminuth, damage dealing by pimpinjuice http://forums.alliedmods.net/showthread.php?t=111684
// added some L4D specific checks
static applyDamage2(damage, victim, attacker)
{ 
    new Handle:dataPack = CreateDataPack();
    WritePackCell(dataPack, damage);  
    WritePackCell(dataPack, victim);
    WritePackCell(dataPack, attacker);
    
    CreateTimer(0.10, timer_stock_applyDamage2, dataPack);
}

public Action:timer_stock_applyDamage2(Handle:timer, Handle:dataPack)
{
    ResetPack(dataPack);
    new damage = ReadPackCell(dataPack);  
    new victim = ReadPackCell(dataPack);
    new attacker = ReadPackCell(dataPack);
    CloseHandle(dataPack);
    
    decl Float:victimPos[3], String:strDamage[16], String:strDamageTarget[16];
    
    if (!IsClientInGame(victim)) return;
    GetClientEyePosition(victim, victimPos);
    IntToString(damage, strDamage, sizeof(strDamage));
    Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
    
    new entPointHurt = CreateEntityByName("point_hurt");
    if(!entPointHurt) return;
    
    // Config, create point_hurt
    DispatchKeyValue(victim, "targetname", strDamageTarget);
    DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
    DispatchKeyValue(entPointHurt, "Damage", strDamage);
    DispatchKeyValue(entPointHurt, "DamageType", "65536");
    DispatchSpawn(entPointHurt);
    
    // Teleport, activate point_hurt
    TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(entPointHurt, "Hurt", (attacker > 0 && attacker < MaxClients && IsClientInGame(attacker)) ? attacker : -1);
    
    // Config, delete point_hurt
    DispatchKeyValue(entPointHurt, "classname", "point_hurt");
    DispatchKeyValue(victim, "targetname", "null");
    RemoveEdict(entPointHurt);
}  

public Action:HulkAllowResetTimer(Handle:timer)
{
	if (!HulkAllow) PrintToChatAll("\x04%t", "notankrest");
	HulkAllow = true;
	HulkResetTimer = INVALID_HANDLE;

}

public Action:ShowTankInfoTimer(Handle:timer, any:client)
{
	if (!IsValidPlayer(client)) return;
	if (!IsTank(client)) return;

	new frust = GetEntData(client, g_iFrustrationO);
	//new hp = GetClientHealth(client);
	
	PrintHintText(client, "FRUSTRATION: %i ResetLeft: %i", (100-frust), FrustrationReset[client]);
	CreateTimer(0.5, ShowTankInfoTimer, client);
}

public Action:Event_TankFrustrated(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if ((InfHulk[client] > 0) || (TankChaos[client] > 0)) ForcePlayerSuicide(client);
		
}

public Action:cmd_coord(client, args) 
{
	if (!IsValidPlayer(client)) return;
	
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	PrintToChat(client, "pos[0]: %2.1f  pos[1]: %2.1f  pos[2]: %2.1f",pos[0], pos[1], pos[2]);
}

public Action:ResetTankChaosEvent(Handle:timer)
{
	TankChaosEvent = 0;
}

public Action:WitchAllowReset(Handle:timer, any:client)
{
	WitchAllow = true;
}

public bool: IsNormalAlt(any: client)
{
	new Float: MaxAlt, MinAlt;
	new Float: pos[3];
	new Float: distance;
	
	MaxAlt = 0.0;
	MinAlt = 999999.0;
	
	for(new i=1; i<=GetMaxClients(); i++) {
		if ((IsNormalPlayer(i)) && (GetClientTeam(i) == 2)) {
				GetClientAbsOrigin(i, pos);
				
				//PrintToChat(client, "%s pos[0]: %2.0f pos[1]: %2.0f pos[2]: %f2.0", GetName(i), pos[0], pos[1], pos[2]);
				
				if (FloatCompare(pos[2], MaxAlt) == 1) MaxAlt = pos[2];
				if (FloatCompare(pos[2], MinAlt) == -1) MinAlt = pos[2];
		}	
	}	
	
	//PrintToChat(client, "MaxAlt: %f2.0", MaxAlt);
	//PrintToChat(client, "MinAlt: %f2.0", MinAlt);
	
	GetClientAbsOrigin(client, pos);
	if (FloatCompare(pos[2], FloatAdd(MaxAlt, 200.0)) == 1) {
		//PrintToChat(client, "false");
		return false;
	}
	else {
		//PrintToChat(client, "true");
		return true;
	}
		
	
}

public Action:cmd_isnormalalt(client, args) 
{
	if (!IsValidPlayer(client)) return;
	
	if (IsNormalAlt(client)) {
		PrintToChat(client, "isnormalalt: true");
	}
	else PrintToChat(client, "isnormalalt: false");
}

public Action:cmd_resetshield(client, args) 
{
	if (ResetShieldAllow[client] == 0) return; 
	ResetShieldAllow[client] = 0;
 	CreateTimer(5.0, ResetShieldAllowTimer, client);
	
	if (IsNormalPlayer(client)) killshield(client);
}


public RoundStartInit()
{
	if (RoundStarted) return;
	
	RoundStarted = true;
	RoundEnd = 0;
	
	PrintToChatAll("RoundStart");
	LogToFile(logfilepath, "RoundStartInit: start");
		
////////1
	InfGlobalDamage = 0;

	ResetInfAbilities();
	ResetSurvAbilities();
	ResetMassAbilites();
	UpdateMassCosts();
	VictimTimerStarted = false;	
	
	LogToFile(logfilepath, "RoundStartInit: 1");
	
	ResetVars();
	//CheckCurrentMapDB();
	ResetMassAbilites();
	RoundStartTime = 0;
	UpdateMassCosts();
	//CreateTimer(0.1, ChaosTankResetTimer, 0);
	
	TurrelCount = 0;
	//ResetRankChangeCheck();
	CreateTimer(1.0, UpdateCostsTimer);
	if (GetTeamHumanCount(2) < 4) PrintToChatAll("\x04[Xtreme] \x01%t, \x05%t", "nopeople", "nopeople1");
	else PrintToChatAll("\x04[Xtreme] \x05%t.", "victim2");
	VictimID = 0;
	
	LogToFile(logfilepath, "RoundStartInit: 2");
	
	TankSpawnCount = 0;
	
	/*
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsNormalPlayer(i)) && (GetClientTeam(i) == 2)) 	{
			new Handle:hBf;
			hBf = StartMessageOne("Shake", i);
			BfWriteByte(hBf, 0);
			BfWriteFloat(hBf, 0.0);
			BfWriteFloat(hBf, 0.0);
			BfWriteFloat(hBf, 0.0);
			EndMessage();
			
			//if (hBf != INVALID_HANDLE) CloseHandle(hBf);
		}
	}
	*/
	//CreateTimer(1.0, SetVictimRoundTimer);
	
	//if (g_iNextPAttO == 5088)
	//{
		//L4D2, Windows
	//	g_iNextActO = 1068;
//		g_iAttackTimerO = 5436;
//	}
//	else if (g_iNextPAttO == 5104)
//	{
		////L4D2, Linux
		//g_iNextActO = 1092;
		//g_iAttackTimerO = 5448;
	//}



//////2
	//if (!IsModelPrecached("models/w_models/weapons/w_m60.mdl")) PrecacheModel("models/w_models/weapons/w_m60.mdl");
	//if (!IsModelPrecached("models/v_models/v_m60.mdl")) PrecacheModel("models/v_models/v_m60.mdl");
	if(IsAllowedReset())
	{
		for (new i=1; i<=MaxClients; i++)
		{
			points[i] = GetConVarInt(StartPoints);
			hurtcount[i] = 0;
			protectcount[i] = 0;
			headshotcount[i] = 0;
			killcount[i] = 0;
			wassmoker[i] = 0;
		}    
	}
	tanksspawned = 0;
	witchsspawned = 0;	
	
////////3
	
	fVL = false;
	
	HulkAllow = true;
	//ResetAllShields();
	//ResetAll();
	InfTankChaos = 0;
	
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		
		GLDmg[i] = 0;
		TankChaos[i] = 0;
		points[i] = 0;
		VipBonus[i][1] = VipStatus[i];
		if (VipStatus[i] == 2) {
			if (CurrentGamemodeID != 1) { //Bonus vip2 para Coop
				VipBonus[i][2] = 4;
				VipBonus[i][3] = 8;
				VipBonus[i][4] = 4;
				VipBonus[i][5] = 4;
				//VipBonus[i][17] = 300;
			}
			else {								// Bonus vip2 para versus u otro (que no sea coop)
				VipBonus[i][2] = 2;
				VipBonus[i][3] = 4;
				VipBonus[i][4] = 0;
				VipBonus[i][5] = 0;
				//VipBonus[i][17] = 0;
			}
		}
		if (VipStatus[i] >= 3) {
			if (CurrentGamemodeID != 1) {
				VipBonus[i][2] = 4; //laser sight
				VipBonus[i][3] = 8; //IncendiaryAmmo
				VipBonus[i][4] = 8; //ExplosiveAmmo
				VipBonus[i][5] = 2; //awp limit
				//VipBonus[i][17] = 500; //coop points
				VipBonus[i][20] = 1; //Armas vip3 coop
			}
			else {
				VipBonus[i][2] = 2;	//laser sight
				VipBonus[i][3] = 4;	//IncendiaryAmmo
				VipBonus[i][4] = 4;	//ExplosiveAmmo
				VipBonus[i][5] = 1;	//awp limit
				//VipBonus[i][17] = 0;	//coop points
				VipBonus[i][20] = 1; //Armas vip3 versus
			}
			
			if (VipStatus[i] == 3) {
				VipBonus[i][18] = 5;
				VipBonus[i][10] = 1; //mutants call
				VipBonus[i][11] = 1;
				VipBonus[i][12] = 1;
				VipBonus[i][13] = 1;
				VipBonus[i][14] = 1;
				VipBonus[i][15] = 1;
				VipBonus[i][16] = 1; //mutants call
			}
		}
		if (VipStatus[i] == 4) {
			VipBonus[i][20] = 1;
			VipBonus[i][21] = 1;
			VipBonus[i][22] = 10;
		}
		AllowActivateBuyClient[i] = 1;
	}
	PrintToChatAll("\x04[VIP]\x05 %t", "vipbonusset");
	
	LogToFile(logfilepath, "RoundStartInit: 3");
	
	if (Timer1 == INVALID_HANDLE) Timer1 = CreateTimer(60.0, timer_UpdatePlayers, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer2 == INVALID_HANDLE) Timer2 = CreateTimer(1.0, YellTimer, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer3 == INVALID_HANDLE) Timer3 = CreateTimer(60.0, SetVictim, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer4 == INVALID_HANDLE) Timer4 = CreateTimer(1.0, CheckTanksTimer, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer5 == INVALID_HANDLE) Timer5 = CreateTimer(1.0, VictimRegen, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer6 == INVALID_HANDLE) Timer6 = CreateTimer(10.5, VictimRender, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer7 == INVALID_HANDLE) Timer7 = CreateTimer(10.0, CheckBankTimer, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer8 == INVALID_HANDLE) Timer8 = CreateTimer(2.0, ApplyAcidDamage, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer9 == INVALID_HANDLE) Timer9 = CreateTimer(1.0, SpeedLogicTimer, 0, TIMER_REPEAT);
	if (Timer25 == INVALID_HANDLE) Timer25 = CreateTimer(1.0, CheckRegArrayTimer, 0, TIMER_REPEAT);

	LogToFile(logfilepath, "RoundStartInit: end");
	
}


CreateEnvSprite2(client, const String:sColor[], const String:scale[])
{
	if (!IsNormalPlayer(client)) return 0;
	
	new entity = CreateEntityByName("env_sprite");
	if( entity == -1)
	{
		LogError("Failed to create 'env_sprite'");
		return 0;
	}

	DispatchKeyValue(entity, "rendercolor", sColor);
	DispatchKeyValue(entity, "model", MODEL_SPRITE);
	DispatchKeyValue(entity, "spawnflags", "3");
	DispatchKeyValue(entity, "rendermode", "9");
	DispatchKeyValue(entity, "GlowProxySize", "0.1");
	DispatchKeyValue(entity, "renderamt", "175");
	DispatchKeyValue(entity, "scale", scale);
	DispatchSpawn(entity);

	// Attach
	SetVariantString("!activator"); 
	AcceptEntityInput(entity, "SetParent", client);
	//if (IsTank(client)) SetVariantString("rshoulder");
	//else
	if (IsPlayerBoomer(client)) SetVariantString("mouth");
	else SetVariantString("rhand");
	AcceptEntityInput(entity, "SetParentAttachment");

	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
	return EntIndexToEntRef(entity);
}

bool:IsPlayerBoomer (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == 2)
		return true;
	return false;
}

public Action:Event_Player_Use(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Entity = GetEventInt(event, "targetid");
		
	if ((IsValidEntity(Entity)) && (IsNormalPlayer(client)) && (GetClientTeam(client) == 2))
	{
		new String:entname[255];
		if(GetEdictClassname(Entity, entname, sizeof(entname)))
		{
			if ( (StrContains(entname, "upgradepack_explosive", false) != -1) || (StrContains(entname, "upgradepack_incendiary", false) != -1) )
			{
				//PrintToChat(client, "Использован upgradepack");
				
				new String:class[40];
				new wep = GetPlayerWeaponSlot(client, 0);
				if (IsValidEdict(wep)) GetEdictClassname(wep, class, sizeof(class));
				if ( ((StrContains(class, "m60", false) != -1) || (StrContains(class, "grenade_launcher", false) != -1)) && (SurvFirearmsMaster[client] <= 0) ) {
					PrintToChat(client, "\x01%t \x04%t", "masterfire1", "SurvBulletDamage");
					CreateTimer(0.5, RemoveUpgradeTimer, client);					
				}
			}
		}
	}
	return Plugin_Continue;
	
}

public Action:RemoveUpgradeTimer(Handle:timer, any:client) 
{
	RemoveFlags();
	FakeClientCommand(client, "upgrade_remove EXPLOSIVE_AMMO");
	FakeClientCommand(client, "upgrade_remove INCENDIARY_AMMO");
	AddFlags();		
}

public Action:event_Weapon_Reload(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsNormalPlayer(client)) return;
	
	new String: wep_name[40];
	GetClientWeapon(client, wep_name, sizeof(wep_name));
		
	if ( (StrContains(wep_name, "pistol", false) == -1) && (StrContains(wep_name, "m60", false) == -1) && (StrContains(wep_name, "grenade_launcher", false) == -1) ) {
		if (SurvUpgradeExplosive[client] > 0) {
			RemoveFlags();
			FakeClientCommand(client, "upgrade_add EXPLOSIVE_AMMO");
			AddFlags();	
			LastUpgrade[client] = 2;
			SurvUpgradeExplosive[client]--;
		} 
		else if (SurvUpgradeIncendiary[client] > 0) {
			RemoveFlags();
			FakeClientCommand(client, "upgrade_add INCENDIARY_AMMO");
			AddFlags();	
			LastUpgrade[client] = 1;
			SurvUpgradeIncendiary[client]--;
		}
	}
}

public AnimateBlock(any: client,R,G,B)
{
	if ( (!IsNormalPlayer(client)) || (RoundEnd > 0) ) return;
	
	new glowcolor = RGB_TO_INT(R, G, B);
	SetEntProp(client, Prop_Send, "m_iGlowType", 2);
	SetEntProp(client, Prop_Send, "m_bFlashing", 2);
	SetEntProp(client, Prop_Send, "m_glowColorOverride", glowcolor);
	if (NormalGlowTimer[client] == INVALID_HANDLE) NormalGlowTimer[client] = CreateTimer(0.3, NormalGlow, client);
}

public Action:NormalGlow(Handle:timer, any:client)
{
	if (IsNormalPlayer(client)) {
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);
		SetEntProp(client, Prop_Send, "m_bFlashing", 0);
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
	}
	NormalGlowTimer[client] = INVALID_HANDLE;
	
}

stock RGB_TO_INT(red, green, blue) 
{
	return (blue * 65536) + (green * 256) + red;
}

TeslaShock(common, client)
{
	return;
	// TARGET
	decl String:sTemp[32];
	new Float:vAng[3], Float:vPos[3];

	new entity = CreateEntityByName("info_particle_target");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "spawnflags", "0");
		Format(sTemp, sizeof(sTemp), "tesla%d%d%d", entity, common,client);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchSpawn(entity);

		SetVariantString("!activator"); 
		AcceptEntityInput(entity, "SetParent", client);

		vPos[2] = GetRandomFloat(10.0, 60.0);
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.5:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
	else
		LogError("Failed to created entity 'info_particle_target'");


	

}


public Action:CheckRegArrayTimer(Handle:timer)
{
	if (RoundEnd > 0) return;
	
	if ( (!IsRegProcess) && (!IsMuteProcess) ) {
		if (GetArraySize(toReg) > 0) {
			GetClientVipStatus(GetArrayCell(toReg, 0));
			RemoveFromArray(toReg, 0);
			return;
		}
		if (GetArraySize(toMute) > 0) {
			ReadClientRankMute(GetArrayCell(toMute, 0));
			RemoveFromArray(toMute, 0);
			return;
		}
		
	}
}

public PushIntoArray(Handle: arr, any: val)
{
	if (FindValueInArray(arr, val) == -1)
		PushArrayCell(arr, val);
}

UnHookDamage()
{
	for( new i = 1; i <= GetMaxClients(); i++ )
		if( IsClientInGame(i) )
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	
}

IsCommonInfected(entity)
{
	if( GetEntProp(entity, Prop_Data, "m_iHammerID") == 66260 )
		return false;

	if( GetEntPropFloat(entity, Prop_Send, "m_flModelScale") != 1.0 )
		return false;

	decl String:sTemp[64];
	GetEntPropString(entity, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));

	if( strcmp(sTemp, "models/infected/common_male_ceda.mdl") == 0 || strcmp(sTemp, "models/infected/common_male_clown.mdl") == 0 ||
		strcmp(sTemp, "models/infected/common_male_fallen_survivor.mdl") == 0 || strcmp(sTemp, "models/infected/common_male_jimmy.mdl") == 0 ||
		strcmp(sTemp, "models/infected/common_male_mud.mdl") == 0 || strcmp(sTemp, "models/infected/common_male_riot.mdl") == 0 ||
		strcmp(sTemp, "models/infected/common_male_roadcrew.mdl") == 0 )
	{
		return false;
	}

	return true;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if ( !(IsValidPlayer(client)) || (GetClientTeam(client) != 2) ) return Plugin_Continue;
	

	if ( (buttons & IN_ATTACK) && (SurvFirearmsMaster[client] > 0) )
	{
		
		new wep = GetPlayerWeaponSlot(client, 0);
		new String:class[40];
		if (wep != -1) {
			GetEdictClassname(wep, class, sizeof(class));
			new ammo = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
				
			new String: wep_name[40];
			GetClientWeapon(client, wep_name, sizeof(wep_name));	
				
			if ( (StrEqual(class, "weapon_rifle_m60", false)) && ((ammo-1) <= 0) && (StrContains(wep_name, "m60", false) != -1) ) {
				//SetEntProp(GetPlayerWeaponSlot(Attacker, 0), Prop_Send, "m_iClip1", 250);
				//else SetEntProp(GetPlayerWeaponSlot(Attacker, 0), Prop_Send, "m_iClip1", ammo+10);
				buttons &= ~IN_ATTACK;
				return Plugin_Handled;				
			}
			
		}

	}
	
	return Plugin_Continue;
	
}



public Action:cmd_show_vars(client, args)
{
	new Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Infected), 2, 3, TEAM_SURVIVORS);
	
	PrintToChat(client, "Score = %i", Score);
}

public VipWeaponsMenu(client, w_type) 
{
	if (!IsValidPlayer(client)) return;
	
	if (VipStatus[client] < 3) {
		PrintToChat(client, "\x04[VIP] \x01%t.", "vipgunsmenu");
		return;
	}
	
	if (GetClientTeam(client) != 2) {
		PrintToChat(client, "\x04%t", "vipnolive");
		return;
	}
	
	SetGlobalTransTarget(client);
	
	new Handle:menu = CreateMenu(VipMenuWeaponsHandler);
	new String:text[255];
	decl String:title[40];
		
	if (w_type == 1) 
	{
		if (VipStatus[client] != 4) 
		{ 
		//Format(text, sizeof(text),"AWP");
		//AddMenuItem(menu, "sniper_awp", text);
		Format(text, sizeof(text),"Scout");
		AddMenuItem(menu, "sniper_scout", text);
		Format(text, sizeof(text),"Hunting rifle");
		AddMenuItem(menu, "hunting_rifle", text);
		}
		else
		{
		Format(text, sizeof(text),"AWP");
		AddMenuItem(menu, "sniper_awp", text);
		Format(text, sizeof(text),"Scout");
		AddMenuItem(menu, "sniper_scout", text);
		Format(text, sizeof(text),"Hunting rifle");
		AddMenuItem(menu, "hunting_rifle", text);
		}
	}
	else if (w_type == 2) {
		Format(text, sizeof(text),"Fireaxe");
		AddMenuItem(menu, "fireaxe", text);
		Format(text, sizeof(text),"Frying pan");
		AddMenuItem(menu, "frying_pan", text);
		Format(text, sizeof(text),"Machete");
		AddMenuItem(menu, "machete", text);
		Format(text, sizeof(text),"Baseball bat");
		AddMenuItem(menu, "baseball_bat", text);
		Format(text, sizeof(text),"Crowbar");
		AddMenuItem(menu, "crowbar", text);
		Format(text, sizeof(text),"Cricket bat");
		AddMenuItem(menu, "cricket_bat", text);
		Format(text, sizeof(text),"Tonfa");
		AddMenuItem(menu, "tonfa", text);
		Format(text, sizeof(text),"Katana");
		AddMenuItem(menu, "katana", text);
		Format(text, sizeof(text),"Electric_guitar");
		AddMenuItem(menu, "electric_guitar", text);
		Format(text, sizeof(text),"Knife");
		AddMenuItem(menu, "knife", text);
		Format(text, sizeof(text),"Golfclub");
		AddMenuItem(menu, "golfclub", text);
	}
	
	Format(title, sizeof(title),"%t:", "meleevip");
	SetMenuTitle(menu, title);
	DisplayMenu(menu, client, 30);		
}


public VipMenuWeaponsHandler(Handle:menu, MenuAction:action, param1, param2)
{
	
	if (!IsValidPlayer(param1)) return;
	
	SetGlobalTransTarget(param1);
		
	if (GetClientTeam(param1) != 2) {
		PrintToChat(param1, "\x04[VIP] \x01%t.", "vipnolive");
		return;
	}
			
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			
			new String:item1[192];
			GetMenuItem(menu, param2, item1, sizeof(item1));

			new w_type = 0;
			if ( (StrEqual(item1, "sniper_awp", false)) 
			|| 
			(StrEqual(item1, "sniper_scout", false)) 
			||
			(StrEqual(item1, "hunting_rifle", false)) )
			w_type = 1;
			else
			w_type = 2;
			
			if ( ((w_type == 1) && (VipBonus[param1][20] <= 0)) || ((w_type == 2) && (VipBonus[param1][21] <= 0)) ) {
				PrintToChat(param1, "\x04[VIP] \x01%t.", "limitreached");
				return;
			}			
	
			PrintToChat(param1, "\x04[VIP] \x01%t %s", "vipitemgot", item1);
			RemoveFlags();
			FakeClientCommand(param1, "give %s", item1);
			AddFlags();	
			
			if (w_type == 1) VipBonus[param1][20] -= 1;
			else if (w_type == 2) VipBonus[param1][21] -= 1;
						
		}
	}
	
}


public Action:event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	return Plugin_Continue;
	
	if (StatsDisabled() || CampaignOver)
		return Plugin_Continue;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetEventInt(event, "entityid");
	
	if (!IsValidPlayer(Attacker)) return Plugin_Continue;
	
	new String:class[40];
	decl String:wep_name[40];
	GetClientWeapon(Attacker, wep_name, sizeof(wep_name));
	if ( (SurvFirearmsMaster[Attacker] > 0) && 
	((StrContains(wep_name, "sniper_awp", false) != -1) || (StrContains(wep_name, "sniper_scout", false) != -1)) ) {
		if (IsValidEntity(Victim)) {
			
			//SetEntityHealth(Victim, 0);
			//new h=GetEntProp(Victim, Prop_Data, "m_iHealth"); 
			//if (h > 0)
			new Handle:dataPack = CreateDataPack();
			WritePackCell(dataPack, Attacker);  
			WritePackCell(dataPack, Victim);
			CreateTimer(0.1, HurtInfTimer, dataPack);
			
			//2130706430
						
		}
	}
	
}

public Action:HurtInfTimer(Handle:timer, Handle:dataPack) 
{

	ResetPack(dataPack);
    new Attacker = ReadPackCell(dataPack);  
    new Victim = ReadPackCell(dataPack);
    CloseHandle(dataPack);
	
	if (RoundEnd > 0) return;
	
	if (IsValidEntity(Victim) && IsValidPlayer(Attacker)) {
		//if (iHurt[Attacker] == 0) {
			HurtPoint(Attacker, Victim, 100, 64, 5); 
		//iHurt[Attacker] = 1;
			PrintToChat(Attacker, "infected bonus daamage added: %i", Victim);
		//}
		//else iHurt[Attacker] = 0;
	}
			
}

public Action:Event_SpecialAmmo(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new upgradeid = GetEventInt(event, "upgradeid");
	decl String:class[256];
	GetEdictClassname(upgradeid, class, sizeof(class));

	//new bid = GetBizonID();
	//if ( (bid > 0) && (bid == client) ) PrintToChat(bid, "upgrade added: %s", class);
	
	if (StrEqual(class, "upgrade_laser_sight"))
		return;
	
	if (StrEqual(class, "upgrade_ammo_incendiary"))	
		LastUpgrade[client] = 1;
	else if (StrEqual(class, "upgrade_ammo_explosive"))	
		LastUpgrade[client] = 2;

		
	
}


public Action:Event_ExplAmmo(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidPlayer(client)) LastUpgrade[client] = 2;
}

public Action:Event_IncAmmo(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidPlayer(client)) LastUpgrade[client] = 1;
}

public Action:UpgradeAdd_Handler(client, args)
{
	decl String:upgradeName[256];
	decl String:initiatorName[MAX_NAME_LENGTH];
	GetClientName(client, initiatorName, sizeof(initiatorName));
	GetCmdArg(1,upgradeName,sizeof(upgradeName));
	
	//new bid = GetBizonID();
	//if ( (bid > 0) && (client == bid) ) PrintToChat(bid, "upgrade_add: %s", upgradeName);
	
	if (StrEqual(upgradeName, "INCENDIARY_AMMO", false))	
	LastUpgrade[client] = 1;
	else if (StrEqual(upgradeName, "EXPLOSIVE_AMMO", false))	
	LastUpgrade[client] = 2;
	
}

String:SafeString(String:str[])
{
	decl String:rValue[255];
	Format(rValue, sizeof(rValue),"%s",str);
	
	ReplaceString(rValue, sizeof(rValue), "<?php", "");
	ReplaceString(rValue, sizeof(rValue), "<?PHP", "");
	ReplaceString(rValue, sizeof(rValue), "?>", "");
	ReplaceString(rValue, sizeof(rValue), "\\", "");
	ReplaceString(rValue, sizeof(rValue), "'", "");
	ReplaceString(rValue, sizeof(rValue), ";", "");
	ReplaceString(rValue, sizeof(rValue), "ґ", "");
	ReplaceString(rValue, sizeof(rValue), "`", "");
		
	return rValue;
}

public Action:cmd_showmass(client, args)
{
	PrintToChat(client, "SurvMassSpeedUp: %i", SurvMassSpeedUp);
	PrintToChat(client, "SurvMassRegen: %i", SurvMassRegen);
	PrintToChat(client, "SurvAutoMiniGun: %i", SurvAutoMiniGun);
	PrintToChat(client, "SurvZombieSurprize: %i", SurvZombieSurprize);
	PrintToChat(client, "SurvUntouchable: %i", SurvUntouchable);
	PrintToChat(client, "SurvPhysPower: %i", SurvPhysPower);
	PrintToChat(client, "SurvVictimShield: %i", SurvVictimShield);
	new Float: CSpeed = GetEntDataFloat(client,g_flLagMovement);
	PrintToChat(client, "g_flLagMovement: %f", CSpeed);
	
}

public Action:cmd_vipswitch(client, args) 
{
	if (!IsValidPlayer(client)) return;
	if (VipStatus[client] <= 0) {
		PrintToChat(client, "%t.", "vipswitch0");
		return;
	}
	
	if (VipStatusDisabled[client] == 1) {
	  VipStatusDisabled[client] = 0;
      VipStatus[client] = VipStatusWas[client];
	}
	else {
		VipStatusDisabled[client] = 1;
	    VipStatus[client] = 1;
		for (new i=1; i<=MaxBonus-1; i++) VipBonus[client][i] = 0;
		InfSpecialShield[client] = 0;
		SurvSpecialShield[client] = 0;
		InfAcidClaws[client] = 0;
		InfBonusDamage[client] = 0;
		SurvShoving[client] = 0;
		SurvFirearmsMaster[client] = 0;
		PrintToChat(client, "\x01%t \x04%t", "disablebonus", "disables");
	}
	
	//PrintToChat(client, "\x04[VIPSWITCH]\x01%t \x04VIP \x01%t \x05%i", "vipswitch10", "vipswitch11", VipStatus[client]);
	PrintToChatAll("\x04[VIPSWITCH] \x01%t \x04%s \x01%t \x04VIP %t \x05%i", "eljugador", GetName(client), "cambio", "alnivel", VipStatus[client]);
}

public Action:cmd_viplist(client, args) 
{
    
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ( (IsValidPlayer(i)) && (IsValidPlayer(client)) ) {
			if (VipStatus[i] >= 1) PrintToChat(client, "\x04%s \x01VIP Status: \x05%i", GetName(i), VipStatus[i]);
		}
	}
}

public Action:ResetShieldAllowTimer(Handle:timer, any:client)
{
	ResetShieldAllow[client] = 1;
}
public Action:cmd_skins(client, args)
{
	if (!IsValidPlayer(client)) return;
	
	if (VipStatus[client] > 0) {
		RemoveFlags();
		FakeClientCommand(client, "sm_pepitopagadoble1234");
		AddFlags();	
	}
	else if ((IsValidPlayer(client)) && (IsAdmin(client))) 
	{
		FakeClientCommand(client, "sm_pepitopagadoble1234");
	}
	if (VipStatus[client] < 1 && (!IsAdmin(client)))
	{
	PrintToChat(client, "\x04[VIP] \x01%t.\n\x04[VIP] \x01%t \x04 https://xtreme-infection.com/vip", "noskins1", "noskins2");
	return;
	}

}