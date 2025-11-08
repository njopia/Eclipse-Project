#include <sourcemod>
#include <sdktools>

new MaxClients;
new TankBonus;
new curr_client;
new TankTime;
new Handle:Timer1;
new Handle:Timer3;
new Handle:Timer4;
new InfectedRealCount;
new InfectedBotCount;
new InfectedBotQueue;
new GameMode;
new BoomerLimit;
new SmokerLimit;
new HunterLimit;
new SpitterLimit;
new JockeyLimit;
new ChargerLimit;
new MaxPlayerZombies;
new BotReady;
new ZOMBIECLASS_TANK;
new GetSpawnTime[66];
new PlayersInServer;
new InfectedSpawnTimeMax;
new InfectedSpawnTimeMin;
new InitialSpawnInt;
new TankLimit;
new TankFoundCount;
new BlockStart;
new RoundNum;
new bool:b_HasRoundStarted;
new bool:b_HasRoundEnded;
new bool:b_LeftSaveRoom;
new bool:canSpawnBoomer;
new bool:canSpawnSmoker;
new bool:canSpawnHunter;
new bool:canSpawnSpitter;
new bool:canSpawnJockey;
new bool:canSpawnCharger;
new bool:DirectorSpawn;
new bool:SpecialHalt;
new bool:PlayerLifeState[66];
new bool:InitialSpawn;
new bool:b_IsL4D2;
new bool:AlreadyGhosted[66];
new bool:AlreadyGhostedBot[66];
new bool:DirectorCvarsModified;
new bool:PlayerHasEnteredStart[66];
new bool:AdjustSpawnTimes;
new bool:Coordination;
new bool:DisableSpawnsTank;
new Handle:h_BoomerLimit;
new Handle:h_SmokerLimit;
new Handle:h_HunterLimit;
new Handle:h_SpitterLimit;
new Handle:h_JockeyLimit;
new Handle:h_ChargerLimit;
new Handle:h_MaxPlayerZombies;
new Handle:h_InfectedSpawnTimeMax;
new Handle:h_InfectedSpawnTimeMin;
new Handle:h_DirectorSpawn;
new Handle:h_GameMode;
new Handle:h_Coordination;
new Handle:h_idletime_b4slay;
new Handle:h_InitialSpawn;
new FightOrDieTimer[66];
new Handle:h_BotGhostTime;
new Handle:h_DisableSpawnsTank;
new Handle:h_TankLimit;
new Handle:h_AdjustSpawnTimes;
public Plugin:myinfo =
{
	name = "[L4D/L4D2] Infected Bots Control",
	description = "This plugin spawns infected bots in versus for L4D1 and gives greater control of the infected bots in L4D1/L4D2.",
	author = "djromero (SkyDavid), MI 5",
	version = "1.0.0",
	url = "http://forums.alliedmods.net/showthread.php?p=893938#post893938"
};
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	MarkNativeAsOptional("BfWriteBool");
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteChar");
	MarkNativeAsOptional("BfWriteShort");
	MarkNativeAsOptional("BfWriteWord");
	MarkNativeAsOptional("BfWriteNum");
	MarkNativeAsOptional("BfWriteFloat");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("BfWriteEntity");
	MarkNativeAsOptional("BfWriteAngle");
	MarkNativeAsOptional("BfWriteCoord");
	MarkNativeAsOptional("BfWriteVecCoord");
	MarkNativeAsOptional("BfWriteVecNormal");
	MarkNativeAsOptional("BfWriteAngles");
	MarkNativeAsOptional("BfReadBool");
	MarkNativeAsOptional("BfReadByte");
	MarkNativeAsOptional("BfReadChar");
	MarkNativeAsOptional("BfReadShort");
	MarkNativeAsOptional("BfReadWord");
	MarkNativeAsOptional("BfReadNum");
	MarkNativeAsOptional("BfReadFloat");
	MarkNativeAsOptional("BfReadString");
	MarkNativeAsOptional("BfReadEntity");
	MarkNativeAsOptional("BfReadAngle");
	MarkNativeAsOptional("BfReadCoord");
	MarkNativeAsOptional("BfReadVecCoord");
	MarkNativeAsOptional("BfReadVecNormal");
	MarkNativeAsOptional("BfReadAngles");
	MarkNativeAsOptional("BfGetNumBytesLeft");
	MarkNativeAsOptional("BfWrite.WriteBool");
	MarkNativeAsOptional("BfWrite.WriteByte");
	MarkNativeAsOptional("BfWrite.WriteChar");
	MarkNativeAsOptional("BfWrite.WriteShort");
	MarkNativeAsOptional("BfWrite.WriteWord");
	MarkNativeAsOptional("BfWrite.WriteNum");
	MarkNativeAsOptional("BfWrite.WriteFloat");
	MarkNativeAsOptional("BfWrite.WriteString");
	MarkNativeAsOptional("BfWrite.WriteEntity");
	MarkNativeAsOptional("BfWrite.WriteAngle");
	MarkNativeAsOptional("BfWrite.WriteCoord");
	MarkNativeAsOptional("BfWrite.WriteVecCoord");
	MarkNativeAsOptional("BfWrite.WriteVecNormal");
	MarkNativeAsOptional("BfWrite.WriteAngles");
	MarkNativeAsOptional("BfRead.ReadBool");
	MarkNativeAsOptional("BfRead.ReadByte");
	MarkNativeAsOptional("BfRead.ReadChar");
	MarkNativeAsOptional("BfRead.ReadShort");
	MarkNativeAsOptional("BfRead.ReadWord");
	MarkNativeAsOptional("BfRead.ReadNum");
	MarkNativeAsOptional("BfRead.ReadFloat");
	MarkNativeAsOptional("BfRead.ReadString");
	MarkNativeAsOptional("BfRead.ReadEntity");
	MarkNativeAsOptional("BfRead.ReadAngle");
	MarkNativeAsOptional("BfRead.ReadCoord");
	MarkNativeAsOptional("BfRead.ReadVecCoord");
	MarkNativeAsOptional("BfRead.ReadVecNormal");
	MarkNativeAsOptional("BfRead.ReadAngles");
	MarkNativeAsOptional("BfRead.GetNumBytesLeft");
	MarkNativeAsOptional("PbReadInt");
	MarkNativeAsOptional("PbReadFloat");
	MarkNativeAsOptional("PbReadBool");
	MarkNativeAsOptional("PbReadString");
	MarkNativeAsOptional("PbReadColor");
	MarkNativeAsOptional("PbReadAngle");
	MarkNativeAsOptional("PbReadVector");
	MarkNativeAsOptional("PbReadVector2D");
	MarkNativeAsOptional("PbGetRepeatedFieldCount");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetFloat");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbSetColor");
	MarkNativeAsOptional("PbSetAngle");
	MarkNativeAsOptional("PbSetVector");
	MarkNativeAsOptional("PbSetVector2D");
	MarkNativeAsOptional("PbAddInt");
	MarkNativeAsOptional("PbAddFloat");
	MarkNativeAsOptional("PbAddBool");
	MarkNativeAsOptional("PbAddString");
	MarkNativeAsOptional("PbAddColor");
	MarkNativeAsOptional("PbAddAngle");
	MarkNativeAsOptional("PbAddVector");
	MarkNativeAsOptional("PbAddVector2D");
	MarkNativeAsOptional("PbRemoveRepeatedFieldValue");
	MarkNativeAsOptional("PbReadMessage");
	MarkNativeAsOptional("PbReadRepeatedMessage");
	MarkNativeAsOptional("PbAddMessage");
	MarkNativeAsOptional("Protobuf.ReadInt");
	MarkNativeAsOptional("Protobuf.ReadFloat");
	MarkNativeAsOptional("Protobuf.ReadBool");
	MarkNativeAsOptional("Protobuf.ReadString");
	MarkNativeAsOptional("Protobuf.ReadColor");
	MarkNativeAsOptional("Protobuf.ReadAngle");
	MarkNativeAsOptional("Protobuf.ReadVector");
	MarkNativeAsOptional("Protobuf.ReadVector2D");
	MarkNativeAsOptional("Protobuf.GetRepeatedFieldCount");
	MarkNativeAsOptional("Protobuf.SetInt");
	MarkNativeAsOptional("Protobuf.SetFloat");
	MarkNativeAsOptional("Protobuf.SetBool");
	MarkNativeAsOptional("Protobuf.SetString");
	MarkNativeAsOptional("Protobuf.SetColor");
	MarkNativeAsOptional("Protobuf.SetAngle");
	MarkNativeAsOptional("Protobuf.SetVector");
	MarkNativeAsOptional("Protobuf.SetVector2D");
	MarkNativeAsOptional("Protobuf.AddInt");
	MarkNativeAsOptional("Protobuf.AddFloat");
	MarkNativeAsOptional("Protobuf.AddBool");
	MarkNativeAsOptional("Protobuf.AddString");
	MarkNativeAsOptional("Protobuf.AddColor");
	MarkNativeAsOptional("Protobuf.AddAngle");
	MarkNativeAsOptional("Protobuf.AddVector");
	MarkNativeAsOptional("Protobuf.AddVector2D");
	MarkNativeAsOptional("Protobuf.RemoveRepeatedFieldValue");
	MarkNativeAsOptional("Protobuf.ReadMessage");
	MarkNativeAsOptional("Protobuf.ReadRepeatedMessage");
	MarkNativeAsOptional("Protobuf.AddMessage");
	VerifyCoreVersion();
	return 0;
}

Float:operator/(Float:,_:)(Float:oper1, oper2)
{
	return oper1 / float(oper2);
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

PrintToChatAll(String:format[])
{
	decl String:buffer[192];
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, 192, format, 2);
			PrintToChat(i, "%s", buffer);
		}
		i++;
	}
	return 0;
}

SetEntityMoveType(entity, MoveType:mt)
{
	static bool:gotconfig;
	static String:datamap[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_MoveType", datamap, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(datamap, 32, "m_MoveType");
		}
		gotconfig = true;
	}
	SetEntProp(entity, PropType:1, datamap, mt, 4, 0);
	return 0;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:GameName[64];
	GetGameFolderName(GameName, 64);
	if (StrContains(GameName, "left4dead", false) == -1)
	{
		return APLRes:1;
	}
	if (StrEqual(GameName, "left4dead2", false))
	{
		b_IsL4D2 = true;
	}
	return APLRes:0;
}

public void:OnPluginStart()
{
	if (b_IsL4D2)
	{
		ZOMBIECLASS_TANK = 8;
	}
	else
	{
		ZOMBIECLASS_TANK = 5;
	}
	CreateConVar("l4d_infectedbots_version", "1.0.0", "Version of L4D Infected Bots", 401728, false, 0.0, false, 0.0);
	h_GameMode = FindConVar("mp_gamemode");
	RegConsoleCmd("sm_count", CheckQueue, "", 0);
	RegConsoleCmd("sm_diff", cmd_diff, "", 0);
	RegConsoleCmd("sm_addsbot", cmd_addsbot, "", 0);
	RegConsoleCmd("sm_initbots", cmd_initbots, "", 0);
	h_BoomerLimit = CreateConVar("l4d_infectedbots_boomer_limit", "1", "Sets the limit for boomers spawned by the plugin", 262208, false, 0.0, false, 0.0);
	h_SmokerLimit = CreateConVar("l4d_infectedbots_smoker_limit", "1", "Sets the limit for smokers spawned by the plugin", 262208, false, 0.0, false, 0.0);
	h_TankLimit = CreateConVar("l4d_infectedbots_tank_limit", "0", "Sets the limit for tanks spawned by the plugin (plugin treats these tanks as another infected bot) (does not affect director tanks)", 262208, false, 0.0, false, 0.0);
	if (b_IsL4D2)
	{
		h_SpitterLimit = CreateConVar("l4d_infectedbots_spitter_limit", "1", "Sets the limit for spitters spawned by the plugin", 262208, false, 0.0, false, 0.0);
		h_JockeyLimit = CreateConVar("l4d_infectedbots_jockey_limit", "1", "Sets the limit for jockeys spawned by the plugin", 262208, false, 0.0, false, 0.0);
		h_ChargerLimit = CreateConVar("l4d_infectedbots_charger_limit", "1", "Sets the limit for chargers spawned by the plugin", 262208, false, 0.0, false, 0.0);
		h_HunterLimit = CreateConVar("l4d_infectedbots_hunter_limit", "1", "Sets the limit for hunters spawned by the plugin", 262208, false, 0.0, false, 0.0);
	}
	else
	{
		h_HunterLimit = CreateConVar("l4d_infectedbots_hunter_limit", "2", "Sets the limit for hunters spawned by the plugin", 262208, false, 0.0, false, 0.0);
	}
	h_MaxPlayerZombies = CreateConVar("l4d_infectedbots_max_specials", "4", "Defines how many special infected can be on the map on all gamemodes (This affects the infected player limit as well)", 262208, false, 0.0, false, 0.0);
	h_InfectedSpawnTimeMax = CreateConVar("l4d_infectedbots_spawn_time_max", "30", "Sets the max spawn time for special infected spawned by the plugin in seconds", 262208, false, 0.0, false, 0.0);
	h_InfectedSpawnTimeMin = CreateConVar("l4d_infectedbots_spawn_time_min", "25", "Sets the minimum spawn time for special infected spawned by the plugin in seconds", 262208, false, 0.0, false, 0.0);
	h_DirectorSpawn = CreateConVar("l4d_infectedbots_director_spawn_times", "0", "If 1, the plugin will use the director's timing of the spawns, if the game is L4D2 and versus, it will activate Valve's bots", 262208, true, 0.0, true, 1.0);
	h_Coordination = CreateConVar("l4d_infectedbots_coordination", "0", "If 1, bots will only spawn when all other bot spawn timers are at zero", 262208, true, 0.0, true, 1.0);
	h_idletime_b4slay = CreateConVar("l4d_infectedbots_lifespan", "40", "Amount of seconds before a special infected bot is kicked", 262208, false, 0.0, false, 0.0);
	h_InitialSpawn = CreateConVar("l4d_infectedbots_initial_spawn_timer", "1", "The spawn timer in seconds used when infected bots are spawned for the first time in a map", 262208, false, 0.0, false, 0.0);
	h_BotGhostTime = CreateConVar("l4d_infectedbots_ghost_time", "2", "If higher than zero, the plugin will first spawn bots as ghosts before they fully spawn on versus/scavenge", 262208, false, 0.0, false, 0.0);
	h_DisableSpawnsTank = CreateConVar("l4d_infectedbots_spawns_disabled_tank", "0", "If 1, Plugin will disable bot spawning when a tank is on the field", 262208, true, 0.0, true, 1.0);
	h_AdjustSpawnTimes = CreateConVar("l4d_infectedbots_adjust_spawn_times", "0", "If 1, The plugin will adjust spawn timers depending on the gamemode, adjusts spawn timers based on number of survivor players in coop and based on amount of infected players in versus/scavenge", 262208, true, 0.0, true, 1.0);
	HookConVarChange(h_BoomerLimit, ConVarBoomerLimit);
	BoomerLimit = GetConVarInt(h_BoomerLimit);
	HookConVarChange(h_SmokerLimit, ConVarSmokerLimit);
	SmokerLimit = GetConVarInt(h_SmokerLimit);
	HookConVarChange(h_HunterLimit, ConVarHunterLimit);
	HunterLimit = GetConVarInt(h_HunterLimit);
	if (b_IsL4D2)
	{
		HookConVarChange(h_SpitterLimit, ConVarSpitterLimit);
		SpitterLimit = GetConVarInt(h_SpitterLimit);
		HookConVarChange(h_JockeyLimit, ConVarJockeyLimit);
		JockeyLimit = GetConVarInt(h_JockeyLimit);
		HookConVarChange(h_ChargerLimit, ConVarChargerLimit);
		ChargerLimit = GetConVarInt(h_ChargerLimit);
	}
	HookConVarChange(h_MaxPlayerZombies, ConVarMaxPlayerZombies);
	MaxPlayerZombies = GetConVarInt(h_MaxPlayerZombies);
	HookConVarChange(h_DirectorSpawn, ConVarDirectorSpawn);
	DirectorSpawn = GetConVarBool(h_DirectorSpawn);
	HookConVarChange(h_GameMode, ConVarGameMode);
	AdjustSpawnTimes = GetConVarBool(h_AdjustSpawnTimes);
	HookConVarChange(h_AdjustSpawnTimes, ConVarAdjustSpawnTimes);
	Coordination = GetConVarBool(h_Coordination);
	HookConVarChange(h_Coordination, ConVarCoordination);
	DisableSpawnsTank = GetConVarBool(h_DisableSpawnsTank);
	HookConVarChange(h_DisableSpawnsTank, ConVarDisableSpawnsTank);
	HookConVarChange(h_InfectedSpawnTimeMax, ConVarInfectedSpawnTimeMax);
	InfectedSpawnTimeMax = GetConVarInt(h_InfectedSpawnTimeMax);
	HookConVarChange(h_InfectedSpawnTimeMin, ConVarInfectedSpawnTimeMin);
	InfectedSpawnTimeMin = GetConVarInt(h_InfectedSpawnTimeMin);
	HookConVarChange(h_InitialSpawn, ConVarInitialSpawn);
	InitialSpawnInt = GetConVarInt(h_InitialSpawn);
	HookConVarChange(h_TankLimit, ConVarTankLimit);
	TankLimit = GetConVarInt(h_TankLimit);
	HookConVarChange(FindConVar("z_hunter_limit"), ConVarDirectorCvarChanged);
	if (!b_IsL4D2)
	{
		HookConVarChange(FindConVar("z_gas_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_exploding_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("holdout_max_boomers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("holdout_max_smokers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("holdout_max_hunters"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("holdout_max_specials"), ConVarDirectorCvarChanged);
	}
	else
	{
		HookConVarChange(FindConVar("z_smoker_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_boomer_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_jockey_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_spitter_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_charger_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_boomers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_smokers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_hunters"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_jockeys"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_spitters"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_chargers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_specials"), ConVarDirectorCvarChanged);
	}
	HookEvent("round_start", evtRoundStart, EventHookMode:1);
	HookEvent("round_end", evtRoundEnd, EventHookMode:0);
	HookEvent("player_death", evtPlayerDeath, EventHookMode:0);
	HookEvent("player_team", evtPlayerTeam, EventHookMode:1);
	HookEvent("player_spawn", evtPlayerSpawn, EventHookMode:1);
	HookEvent("create_panic_event", evtSurvivalStart, EventHookMode:1);
	HookEvent("finale_start", evtFinaleStart, EventHookMode:1);
	HookEvent("player_bot_replace", evtBotReplacedPlayer, EventHookMode:1);
	HookEvent("player_first_spawn", evtPlayerFirstSpawned, EventHookMode:1);
	HookEvent("player_entered_start_area", evtPlayerFirstSpawned, EventHookMode:1);
	HookEvent("player_entered_checkpoint", evtPlayerFirstSpawned, EventHookMode:1);
	HookEvent("player_transitioned", evtPlayerFirstSpawned, EventHookMode:1);
	HookEvent("player_left_start_area", evtPlayerFirstSpawned, EventHookMode:1);
	HookEvent("player_left_checkpoint", evtPlayerFirstSpawned, EventHookMode:1);
	AutoExecConfig(true, "l4dinfectedbots", "sourcemod");
	GameModeCheck();
	CreateTimer(2.0, CheckSpawnTimer, any:0, 1);
	if (!Timer4)
	{
		Timer4 = CreateTimer(1.0, DisposeOfCowards, any:0, 1);
	}
	return void:0;
}

public ConVarBoomerLimit(Handle:convar, String:oldValue[], String:newValue[])
{
	BoomerLimit = GetConVarInt(h_BoomerLimit);
	return 0;
}

public ConVarSmokerLimit(Handle:convar, String:oldValue[], String:newValue[])
{
	SmokerLimit = GetConVarInt(h_SmokerLimit);
	return 0;
}

public ConVarHunterLimit(Handle:convar, String:oldValue[], String:newValue[])
{
	HunterLimit = GetConVarInt(h_HunterLimit);
	return 0;
}

public ConVarSpitterLimit(Handle:convar, String:oldValue[], String:newValue[])
{
	SpitterLimit = GetConVarInt(h_SpitterLimit);
	return 0;
}

public ConVarJockeyLimit(Handle:convar, String:oldValue[], String:newValue[])
{
	JockeyLimit = GetConVarInt(h_JockeyLimit);
	return 0;
}

public ConVarChargerLimit(Handle:convar, String:oldValue[], String:newValue[])
{
	ChargerLimit = GetConVarInt(h_ChargerLimit);
	return 0;
}

public ConVarInfectedSpawnTimeMax(Handle:convar, String:oldValue[], String:newValue[])
{
	InfectedSpawnTimeMax = GetConVarInt(h_InfectedSpawnTimeMax);
	return 0;
}

public ConVarInfectedSpawnTimeMin(Handle:convar, String:oldValue[], String:newValue[])
{
	InfectedSpawnTimeMin = GetConVarInt(h_InfectedSpawnTimeMin);
	return 0;
}

public ConVarInitialSpawn(Handle:convar, String:oldValue[], String:newValue[])
{
	InitialSpawnInt = GetConVarInt(h_InitialSpawn);
	return 0;
}

public ConVarTankLimit(Handle:convar, String:oldValue[], String:newValue[])
{
	TankLimit = GetConVarInt(h_TankLimit);
	return 0;
}

public ConVarDirectorCvarChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	DirectorCvarsModified = true;
	return 0;
}

public ConVarAdjustSpawnTimes(Handle:convar, String:oldValue[], String:newValue[])
{
	AdjustSpawnTimes = GetConVarBool(h_AdjustSpawnTimes);
	return 0;
}

public ConVarCoordination(Handle:convar, String:oldValue[], String:newValue[])
{
	Coordination = GetConVarBool(h_Coordination);
	return 0;
}

public ConVarDisableSpawnsTank(Handle:convar, String:oldValue[], String:newValue[])
{
	DisableSpawnsTank = GetConVarBool(h_DisableSpawnsTank);
	return 0;
}

public ConVarMaxPlayerZombies(Handle:convar, String:oldValue[], String:newValue[])
{
	MaxPlayerZombies = GetConVarInt(h_MaxPlayerZombies);
	CreateTimer(0.1, MaxSpecialsSet, any:0, 0);
	return 0;
}

public ConVarDirectorSpawn(Handle:convar, String:oldValue[], String:newValue[])
{
	DirectorSpawn = GetConVarBool(h_DirectorSpawn);
	if (!DirectorSpawn)
	{
		TweakSettings();
		CheckIfBotsNeeded(true, false);
	}
	else
	{
		DirectorStuff();
	}
	return 0;
}

public ConVarGameMode(Handle:convar, String:oldValue[], String:newValue[])
{
	GameModeCheck();
	if (!DirectorSpawn)
	{
		TweakSettings();
	}
	else
	{
		DirectorStuff();
	}
	return 0;
}

public Action:JoinSpectator(client, args)
{
	if (client)
	{
		ChangeClientTeam(client, 1);
	}
	return Action:0;
}

TweakSettings()
{
	ResetCvars();
	switch (GameMode)
	{
		case 1:
		{
			if (b_IsL4D2)
			{
				SetConVarInt(FindConVar("z_smoker_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_boomer_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_hunter_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_spitter_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_jockey_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_charger_limit"), 0, false, false);
			}
			else
			{
				SetConVarInt(FindConVar("z_gas_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_exploding_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_hunter_limit"), 0, false, false);
			}
		}
		case 2:
		{
			if (b_IsL4D2)
			{
				SetConVarInt(FindConVar("z_smoker_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_boomer_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_hunter_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_spitter_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_jockey_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_charger_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_jockey_leap_time"), 0, false, false);
				SetConVarInt(FindConVar("z_spitter_max_wait_time"), 0, false, false);
			}
			else
			{
				SetConVarInt(FindConVar("z_gas_limit"), 999, false, false);
				SetConVarInt(FindConVar("z_exploding_limit"), 999, false, false);
				SetConVarInt(FindConVar("z_hunter_limit"), 999, false, false);
			}
			SetConVarFloat(FindConVar("smoker_tongue_delay"), 0.0, false, false);
			SetConVarFloat(FindConVar("boomer_vomit_delay"), 0.0, false, false);
			SetConVarFloat(FindConVar("boomer_exposed_time_tolerance"), 0.0, false, false);
			SetConVarInt(FindConVar("hunter_leap_away_give_up_range"), 0, false, false);
			SetConVarInt(FindConVar("z_hunter_lunge_distance"), 5000, false, false);
			SetConVarInt(FindConVar("hunter_pounce_ready_range"), 1500, false, false);
			SetConVarFloat(FindConVar("hunter_pounce_loft_rate"), 0.055, false, false);
			SetConVarFloat(FindConVar("z_hunter_lunge_stagger_time"), 0.0, false, false);
		}
		case 3:
		{
			if (b_IsL4D2)
			{
				SetConVarInt(FindConVar("survival_max_smokers"), 0, false, false);
				SetConVarInt(FindConVar("survival_max_boomers"), 0, false, false);
				SetConVarInt(FindConVar("survival_max_hunters"), 0, false, false);
				SetConVarInt(FindConVar("survival_max_spitters"), 0, false, false);
				SetConVarInt(FindConVar("survival_max_jockeys"), 0, false, false);
				SetConVarInt(FindConVar("survival_max_chargers"), 0, false, false);
				SetConVarInt(FindConVar("survival_max_specials"), MaxPlayerZombies, false, false);
				SetConVarInt(FindConVar("z_smoker_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_boomer_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_hunter_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_spitter_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_jockey_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_charger_limit"), 0, false, false);
			}
			else
			{
				SetConVarInt(FindConVar("holdout_max_smokers"), 0, false, false);
				SetConVarInt(FindConVar("holdout_max_boomers"), 0, false, false);
				SetConVarInt(FindConVar("holdout_max_hunters"), 0, false, false);
				SetConVarInt(FindConVar("holdout_max_specials"), MaxPlayerZombies, false, false);
				SetConVarInt(FindConVar("z_gas_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_exploding_limit"), 0, false, false);
				SetConVarInt(FindConVar("z_hunter_limit"), 0, false, false);
			}
		}
		default:
		{
		}
	}
	SetConVarInt(FindConVar("z_attack_flow_range"), 50000, false, false);
	SetConVarInt(FindConVar("director_spectate_specials"), 1, false, false);
	SetConVarInt(FindConVar("z_spawn_safety_range"), 250, false, false);
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000, false, false);
	DirectorCvarsModified = false;
	if (b_IsL4D2)
	{
		SetConVarInt(FindConVar("versus_special_respawn_interval"), 99999999, false, false);
	}
	return 0;
}

ResetCvars()
{
	if (GameMode == 1)
	{
		ResetConVar(FindConVar("director_no_specials"), true, true);
		ResetConVar(FindConVar("boomer_vomit_delay"), true, true);
		ResetConVar(FindConVar("smoker_tongue_delay"), true, true);
		ResetConVar(FindConVar("hunter_leap_away_give_up_range"), true, true);
		ResetConVar(FindConVar("boomer_exposed_time_tolerance"), true, true);
		ResetConVar(FindConVar("z_hunter_lunge_distance"), true, true);
		ResetConVar(FindConVar("hunter_pounce_ready_range"), true, true);
		ResetConVar(FindConVar("hunter_pounce_loft_rate"), true, true);
		ResetConVar(FindConVar("z_hunter_lunge_stagger_time"), true, true);
		if (b_IsL4D2)
		{
			ResetConVar(FindConVar("survival_max_smokers"), true, true);
			ResetConVar(FindConVar("survival_max_boomers"), true, true);
			ResetConVar(FindConVar("survival_max_hunters"), true, true);
			ResetConVar(FindConVar("survival_max_spitters"), true, true);
			ResetConVar(FindConVar("survival_max_jockeys"), true, true);
			ResetConVar(FindConVar("survival_max_chargers"), true, true);
			ResetConVar(FindConVar("survival_max_specials"), true, true);
			ResetConVar(FindConVar("z_jockey_leap_time"), true, true);
			ResetConVar(FindConVar("z_spitter_max_wait_time"), true, true);
		}
		else
		{
			ResetConVar(FindConVar("holdout_max_smokers"), true, true);
			ResetConVar(FindConVar("holdout_max_boomers"), true, true);
			ResetConVar(FindConVar("holdout_max_hunters"), true, true);
			ResetConVar(FindConVar("holdout_max_specials"), true, true);
		}
	}
	else
	{
		if (GameMode == 2)
		{
			if (b_IsL4D2)
			{
				ResetConVar(FindConVar("survival_max_smokers"), true, true);
				ResetConVar(FindConVar("survival_max_boomers"), true, true);
				ResetConVar(FindConVar("survival_max_hunters"), true, true);
				ResetConVar(FindConVar("survival_max_spitters"), true, true);
				ResetConVar(FindConVar("survival_max_jockeys"), true, true);
				ResetConVar(FindConVar("survival_max_chargers"), true, true);
				ResetConVar(FindConVar("survival_max_specials"), true, true);
			}
			else
			{
				ResetConVar(FindConVar("holdout_max_smokers"), true, true);
				ResetConVar(FindConVar("holdout_max_boomers"), true, true);
				ResetConVar(FindConVar("holdout_max_hunters"), true, true);
				ResetConVar(FindConVar("holdout_max_specials"), true, true);
			}
		}
		if (GameMode == 3)
		{
			ResetConVar(FindConVar("z_hunter_limit"), true, true);
			if (b_IsL4D2)
			{
				ResetConVar(FindConVar("z_smoker_limit"), true, true);
				ResetConVar(FindConVar("z_boomer_limit"), true, true);
				ResetConVar(FindConVar("z_hunter_limit"), true, true);
				ResetConVar(FindConVar("z_spitter_limit"), true, true);
				ResetConVar(FindConVar("z_jockey_limit"), true, true);
				ResetConVar(FindConVar("z_charger_limit"), true, true);
				ResetConVar(FindConVar("z_jockey_leap_time"), true, true);
				ResetConVar(FindConVar("z_spitter_max_wait_time"), true, true);
			}
			else
			{
				ResetConVar(FindConVar("z_gas_limit"), true, true);
				ResetConVar(FindConVar("z_exploding_limit"), true, true);
			}
			ResetConVar(FindConVar("boomer_vomit_delay"), true, true);
			ResetConVar(FindConVar("director_no_specials"), true, true);
			ResetConVar(FindConVar("smoker_tongue_delay"), true, true);
			ResetConVar(FindConVar("hunter_leap_away_give_up_range"), true, true);
			ResetConVar(FindConVar("boomer_exposed_time_tolerance"), true, true);
			ResetConVar(FindConVar("z_hunter_lunge_distance"), true, true);
			ResetConVar(FindConVar("hunter_pounce_ready_range"), true, true);
			ResetConVar(FindConVar("hunter_pounce_loft_rate"), true, true);
			ResetConVar(FindConVar("z_hunter_lunge_stagger_time"), true, true);
		}
	}
	return 0;
}

ResetCvarsDirector()
{
	if (GameMode != 2)
	{
		if (b_IsL4D2)
		{
			ResetConVar(FindConVar("z_smoker_limit"), true, true);
			ResetConVar(FindConVar("z_boomer_limit"), true, true);
			ResetConVar(FindConVar("z_hunter_limit"), true, true);
			ResetConVar(FindConVar("z_spitter_limit"), true, true);
			ResetConVar(FindConVar("z_jockey_limit"), true, true);
			ResetConVar(FindConVar("z_charger_limit"), true, true);
			ResetConVar(FindConVar("survival_max_smokers"), true, true);
			ResetConVar(FindConVar("survival_max_boomers"), true, true);
			ResetConVar(FindConVar("survival_max_hunters"), true, true);
			ResetConVar(FindConVar("survival_max_spitters"), true, true);
			ResetConVar(FindConVar("survival_max_jockeys"), true, true);
			ResetConVar(FindConVar("survival_max_chargers"), true, true);
			ResetConVar(FindConVar("survival_max_specials"), true, true);
		}
		else
		{
			ResetConVar(FindConVar("z_hunter_limit"), true, true);
			ResetConVar(FindConVar("z_exploding_limit"), true, true);
			ResetConVar(FindConVar("z_gas_limit"), true, true);
			ResetConVar(FindConVar("holdout_max_smokers"), true, true);
			ResetConVar(FindConVar("holdout_max_boomers"), true, true);
			ResetConVar(FindConVar("holdout_max_hunters"), true, true);
			ResetConVar(FindConVar("holdout_max_specials"), true, true);
		}
	}
	else
	{
		if (b_IsL4D2)
		{
			SetConVarInt(FindConVar("z_smoker_limit"), 2, false, false);
			ResetConVar(FindConVar("z_boomer_limit"), true, true);
			SetConVarInt(FindConVar("z_hunter_limit"), 2, false, false);
			ResetConVar(FindConVar("z_spitter_limit"), true, true);
			ResetConVar(FindConVar("z_jockey_limit"), true, true);
			ResetConVar(FindConVar("z_charger_limit"), true, true);
		}
		ResetConVar(FindConVar("z_hunter_limit"), true, true);
		ResetConVar(FindConVar("z_exploding_limit"), true, true);
		ResetConVar(FindConVar("z_gas_limit"), true, true);
	}
	return 0;
}

public Action:evtRoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	if (b_HasRoundStarted)
	{
		return Action:0;
	}
	b_LeftSaveRoom = false;
	b_HasRoundEnded = false;
	b_HasRoundStarted = true;
	GameModeCheck();
	new flags = GetConVarFlags(FindConVar("z_max_player_zombies"));
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBounds:0, false, 0.0);
	SetConVarFlags(FindConVar("z_max_player_zombies"), flags & -257);
	CreateTimer(0.4, MaxSpecialsSet, any:0, 0);
	if (!Timer4)
	{
		Timer4 = CreateTimer(1.0, DisposeOfCowards, any:0, 1);
	}
	if (!Timer1)
	{
		Timer1 = CreateTimer(1.0, CheckTanksToSpawn, any:0, 1);
	}
	TankTime = 0;
	InfectedBotQueue = 0;
	BotReady = 0;
	SpecialHalt = false;
	InitialSpawn = false;
	if (!DirectorSpawn)
	{
		TweakSettings();
	}
	else
	{
		DirectorStuff();
	}
	if (GameMode != 3)
	{
		if (RoundNum > 1)
		{
			BlockStart = 1;
			CreateTimer(30.0, ResetBlockStartTimer, any:2, 0);
		}
		CreateTimer(1.0, PlayerLeftStart, any:0, 2);
	}
	return Action:0;
}

public Action:evtPlayerFirstSpawned(Handle:event, String:name[], bool:dontBroadcast)
{
	if (b_HasRoundEnded)
	{
		return Action:0;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (!client)
	{
		return Action:0;
	}
	if (IsFakeClient(client))
	{
		return Action:0;
	}
	if (PlayerHasEnteredStart[client])
	{
		return Action:0;
	}
	AlreadyGhosted[client] = 0;
	PlayerHasEnteredStart[client] = 1;
	return Action:0;
}

GameModeCheck()
{
	decl String:GameName[16];
	GetConVarString(h_GameMode, GameName, 16);
	if (StrEqual(GameName, "survival", false))
	{
		GameMode = 3;
	}
	else
	{
		new var1;
		if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false) || StrEqual(GameName, "mutation12", false) || StrEqual(GameName, "mutation13", false) || StrEqual(GameName, "mutation15", false) || StrEqual(GameName, "mutation11", false))
		{
			GameMode = 2;
		}
		new var2;
		if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false) || StrEqual(GameName, "mutation3", false) || StrEqual(GameName, "mutation9", false) || StrEqual(GameName, "mutation1", false) || StrEqual(GameName, "mutation7", false) || StrEqual(GameName, "mutation10", false) || StrEqual(GameName, "mutation2", false) || StrEqual(GameName, "mutation4", false) || StrEqual(GameName, "mutation5", false) || StrEqual(GameName, "mutation14", false))
		{
			GameMode = 1;
		}
		GameMode = 1;
	}
	return 0;
}

public Action:MaxSpecialsSet(Handle:Timer)
{
	SetConVarInt(FindConVar("z_max_player_zombies"), MaxPlayerZombies, false, false);
	return Action:0;
}

DirectorStuff()
{
	SpecialHalt = false;
	SetConVarInt(FindConVar("z_spawn_safety_range"), 250, false, false);
	SetConVarInt(FindConVar("director_spectate_specials"), 1, false, false);
	if (b_IsL4D2)
	{
		ResetConVar(FindConVar("versus_special_respawn_interval"), true, true);
	}
	if (!DirectorCvarsModified)
	{
		ResetCvarsDirector();
	}
	return 0;
}

public Action:evtRoundEnd(Handle:event, String:name[], bool:dontBroadcast)
{
	if (!b_HasRoundEnded)
	{
		b_HasRoundEnded = true;
		b_HasRoundStarted = false;
		b_LeftSaveRoom = false;
		RoundNum += 1;
		new i = 1;
		while (i <= MaxClients)
		{
			PlayerHasEnteredStart[i] = 0;
			FightOrDieTimer[i] = 0;
			i++;
		}
		if (Timer1)
		{
			CloseHandle(Timer1);
			Timer1 = MissingTAG:0;
		}
		if (Timer3)
		{
			CloseHandle(Timer3);
			Timer3 = MissingTAG:0;
		}
		if (Timer4)
		{
			CloseHandle(Timer4);
			Timer4 = MissingTAG:0;
		}
	}
	return Action:0;
}

public void:OnMapEnd()
{
	b_HasRoundStarted = false;
	b_HasRoundEnded = true;
	b_LeftSaveRoom = false;
	RoundNum = 0;
	new i = 1;
	while (i <= MaxClients)
	{
		FightOrDieTimer[i] = 0;
		i++;
	}
	if (Timer1)
	{
		CloseHandle(Timer1);
		Timer1 = MissingTAG:0;
	}
	if (Timer3)
	{
		CloseHandle(Timer3);
		Timer3 = MissingTAG:0;
	}
	return void:0;
}

public Action:PlayerLeftStart(Handle:Timer)
{
	new var1;
	if (LeftStartArea() && BlockStart)
	{
		if (!b_LeftSaveRoom)
		{
			decl String:GameName[16];
			GetConVarString(h_GameMode, GameName, 16);
			if (StrEqual(GameName, "mutation15", false))
			{
				SetConVarInt(FindConVar("survival_max_smokers"), 0, false, false);
				SetConVarInt(FindConVar("survival_max_boomers"), 0, false, false);
				SetConVarInt(FindConVar("survival_max_hunters"), 0, false, false);
				SetConVarInt(FindConVar("survival_max_jockeys"), 0, false, false);
				SetConVarInt(FindConVar("survival_max_spitters"), 0, false, false);
				SetConVarInt(FindConVar("survival_max_chargers"), 0, false, false);
				return Action:0;
			}
			b_LeftSaveRoom = true;
			canSpawnBoomer = true;
			canSpawnSmoker = true;
			canSpawnHunter = true;
			if (b_IsL4D2)
			{
				canSpawnSpitter = true;
				canSpawnJockey = true;
				canSpawnCharger = true;
			}
			InitialSpawn = true;
			CheckIfBotsNeeded(false, true);
			CreateTimer(3.0, InitialSpawnReset, any:0, 2);
		}
	}
	else
	{
		CreateTimer(1.0, PlayerLeftStart, any:0, 2);
	}
	return Action:0;
}

public Action:evtSurvivalStart(Handle:event, String:name[], bool:dontBroadcast)
{
	if (GameMode == 3)
	{
		if (!b_LeftSaveRoom)
		{
			new bid = GetBizonID();
			if (0 < bid)
			{
				PrintToChat(bid, "A player triggered the survival event, spawning bots");
			}
			TankBonus = 0;
			b_LeftSaveRoom = true;
			canSpawnBoomer = true;
			canSpawnSmoker = true;
			canSpawnHunter = true;
			if (b_IsL4D2)
			{
				canSpawnSpitter = true;
				canSpawnJockey = true;
				canSpawnCharger = true;
			}
			InitialSpawn = true;
			CheckIfBotsNeeded(false, true);
			CreateTimer(3.0, InitialSpawnReset, any:0, 2);
		}
	}
	return Action:0;
}

public Action:InitialSpawnReset(Handle:Timer)
{
	InitialSpawn = false;
	return Action:0;
}

public Action:BotReadyReset(Handle:Timer)
{
	BotReady = 0;
	return Action:0;
}

public Action:InfectedBotBooterVersus(Handle:Timer)
{
	new var1;
	if (GameMode == 2 && b_IsL4D2)
	{
		return Action:0;
	}
	new total;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 3)
			{
				new var3;
				if (!IsPlayerTank(i) || (IsPlayerTank(i) && !PlayerIsAlive(i)))
				{
					total++;
				}
			}
		}
		i++;
	}
	if (InfectedBotQueue + total > MaxPlayerZombies)
	{
		new kick = InfectedBotQueue + total - MaxPlayerZombies;
		new kicked;
		new i = 1;
		while (i <= MaxClients && kicked < kick)
		{
			new var5;
			if (IsClientInGame(i) && IsFakeClient(i))
			{
				if (GetClientTeam(i) == 3)
				{
					new var7;
					if (!IsPlayerTank(i) || (IsPlayerTank(i) && !PlayerIsAlive(i)))
					{
						CreateTimer(0.1, kickbot, i, 0);
						kicked++;
					}
				}
			}
			i++;
		}
	}
	return Action:0;
}

public void:OnClientPutInServer(client)
{
	if (IsFakeClient(client))
	{
		return void:0;
	}
	PlayersInServer += 1;
	return void:0;
}

public Action:CheckGameMode(client, args)
{
	if (client)
	{
		PrintToChat(client, "GameMode = %i", GameMode);
	}
	return Action:0;
}

public Action:CheckQueue(client, args)
{
	if (client)
	{
		CountInfected();
		PrintToChat(client, "InfectedBotQueue = %i, InfectedBotCount = %i, InfectedRealCount = %i", InfectedBotQueue, InfectedBotCount, InfectedRealCount);
	}
	return Action:0;
}

public Action:evtPlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	new var1;
	if (!client || !IsClientInGame(client))
	{
		return Action:0;
	}
	if (GetClientTeam(client) != 3)
	{
		return Action:0;
	}
	new var2;
	if (DirectorSpawn && GameMode != 2)
	{
		if (IsPlayerSmoker(client))
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client, 0);
					new BotNeeded = 1;
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded, 0);
				}
			}
		}
		if (IsPlayerBoomer(client))
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client, 0);
					new BotNeeded = 2;
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded, 0);
				}
			}
		}
		if (IsPlayerHunter(client))
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client, 0);
					new BotNeeded = 3;
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded, 0);
				}
			}
		}
		new var3;
		if (IsPlayerSpitter(client) && b_IsL4D2)
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client, 0);
					new BotNeeded = 4;
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded, 0);
				}
			}
		}
		new var4;
		if (IsPlayerJockey(client) && b_IsL4D2)
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client, 0);
					new BotNeeded = 5;
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded, 0);
				}
			}
		}
		new var5;
		if (IsPlayerCharger(client) && b_IsL4D2)
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client, 0);
					new BotNeeded = 6;
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded, 0);
				}
			}
		}
	}
	if (IsFakeClient(client))
	{
		FightOrDieTimer[client] = 0;
	}
	new var6;
	if (IsFakeClient(client) && GameMode == 2 && !IsPlayerTank(client))
	{
		CreateTimer(0.1, Timer_SetUpBotGhost, client, 2);
	}
	return Action:0;
}

public Action:evtBotReplacedPlayer(Handle:event, String:name[], bool:dontBroadcast)
{
	new bot = GetClientOfUserId(GetEventInt(event, "bot", 0));
	AlreadyGhostedBot[bot] = 1;
	return Action:0;
}

public Action:DisposeOfCowards(Handle:timer, any:coward)
{
	if (b_HasRoundEnded)
	{
		return Action:0;
	}
	new threats;
	new coward = 1;
	while (GetMaxClients() >= coward)
	{
		new var1;
		if (IsClientInGame(coward) && IsFakeClient(coward) && GetClientTeam(coward) == 3 && PlayerIsAlive(coward))
		{
			threats = GetEntProp(coward, PropType:0, "m_hasVisibleThreats", 4, 0);
			if (threats)
			{
				FightOrDieTimer[coward] = 0;
				return Action:0;
			}
			FightOrDieTimer[coward]++;
			new TimeLimit;
			if (IsPlayerTank(coward))
			{
				TimeLimit = 60;
			}
			else
			{
				TimeLimit = 30;
			}
			if (FightOrDieTimer[coward] >= TimeLimit)
			{
				AcceptEntityInput(coward, "Kill", -1, -1, 0);
				if (!DirectorSpawn)
				{
					new SpawnTime = GetURandomIntRange(InfectedSpawnTimeMin, InfectedSpawnTimeMax);
					new var2;
					if (GameMode == 2 && AdjustSpawnTimes && HumansOnInfected() != MaxPlayerZombies)
					{
						SpawnTime /= MaxPlayerZombies - HumansOnInfected();
					}
					else
					{
						new var3;
						if (GameMode == 1 && AdjustSpawnTimes)
						{
							SpawnTime -= TrueNumberOfSurvivors();
						}
					}
					CreateTimer(float(SpawnTime), Spawn_InfectedBot, any:0, 0);
					InfectedBotQueue += 1;
				}
			}
		}
		coward++;
	}
	return Action:0;
}

public Action:Timer_SetUpBotGhost(Handle:timer, any:client)
{
	if (IsValidEntity(client))
	{
		if (!AlreadyGhostedBot[client])
		{
			SetGhostStatus(client, true);
			SetEntityMoveType(client, MoveType:0);
			CreateTimer(GetConVarFloat(h_BotGhostTime), Timer_RestoreBotGhost, client, 2);
		}
		AlreadyGhostedBot[client] = 0;
	}
	return Action:0;
}

public Action:Timer_RestoreBotGhost(Handle:timer, any:client)
{
	if (IsValidEntity(client))
	{
		SetGhostStatus(client, false);
		SetEntityMoveType(client, MoveType:2);
	}
	return Action:0;
}

public Action:evtPlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new var1;
	if (b_HasRoundEnded || !b_LeftSaveRoom)
	{
		return Action:0;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	FightOrDieTimer[client] = 0;
	new var2;
	if (!client || !IsClientInGame(client))
	{
		return Action:0;
	}
	if (GetClientTeam(client) != 3)
	{
		return Action:0;
	}
	new var3;
	if (GetEventBool(event, "victimisbot", false) && !DirectorSpawn)
	{
		if (!IsPlayerTank(client))
		{
			new SpawnTime = GetURandomIntRange(InfectedSpawnTimeMin, InfectedSpawnTimeMax);
			new var4;
			if (AdjustSpawnTimes && HumansOnInfected() != MaxPlayerZombies)
			{
				SpawnTime /= MaxPlayerZombies - HumansOnInfected();
			}
			CreateTimer(float(SpawnTime), Spawn_InfectedBot, any:0, 0);
			InfectedBotQueue += 1;
		}
	}
	if (IsPlayerTank(client))
	{
		CheckIfBotsNeeded(false, false);
	}
	else
	{
		new var5;
		if (GameMode != 2 && DirectorSpawn)
		{
			new SpawnTime = GetURandomIntRange(InfectedSpawnTimeMin, InfectedSpawnTimeMax);
			GetSpawnTime[client] = SpawnTime;
		}
	}
	new var6;
	if (IsFakeClient(client) && !IsPlayerSpitter(client))
	{
		CreateTimer(0.1, kickbot, client, 0);
	}
	return Action:0;
}

public Action:Spawn_InfectedBot_Director(Handle:timer, any:BotNeeded)
{
	if (b_HasRoundEnded)
	{
		return Action:0;
	}
	new bool:resetGhost[66];
	new bool:resetLife[66];
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == 3)
			{
				if (IsPlayerGhost(i))
				{
					resetGhost[i] = true;
					SetGhostStatus(i, false);
				}
				if (!PlayerIsAlive(i))
				{
					AlreadyGhosted[i] = 0;
					SetLifeState(i, true);
				}
			}
		}
		i++;
	}
	new anyclient = GetAnyClient();
	new bool:temp;
	if (anyclient == -1)
	{
		anyclient = CreateFakeClient("Bot");
		if (!anyclient)
		{
			LogError("[L4D] Infected Bots: CreateFakeClient returned 0 -- Infected bot was not spawned");
		}
		temp = true;
	}
	SpecialHalt = true;
	switch (BotNeeded)
	{
		case 1:
		{
			CheatCommand(anyclient, "z_spawn_old", "smoker auto");
		}
		case 2:
		{
			CheatCommand(anyclient, "z_spawn_old", "boomer auto");
		}
		case 3:
		{
			CheatCommand(anyclient, "z_spawn_old", "hunter auto");
		}
		case 4:
		{
			CheatCommand(anyclient, "z_spawn_old", "spitter auto");
		}
		case 5:
		{
			CheatCommand(anyclient, "z_spawn_old", "jockey auto");
		}
		case 6:
		{
			CheatCommand(anyclient, "z_spawn_old", "charger auto");
		}
		default:
		{
		}
	}
	SpecialHalt = false;
	new i = 1;
	while (i <= MaxClients)
	{
		if (resetGhost[i])
		{
			SetGhostStatus(i, true);
		}
		if (resetLife[i])
		{
			SetLifeState(i, true);
		}
		i++;
	}
	if (temp)
	{
		CreateTimer(0.1, kickbot, anyclient, 0);
	}
	return Action:0;
}

public Action:evtPlayerTeam(Handle:event, String:name[], bool:dontBroadcast)
{
	if (GetEventBool(event, "isbot", false))
	{
		return Action:0;
	}
	new newteam = GetEventInt(event, "team", 0);
	new oldteam = GetEventInt(event, "oldteam", 0);
	new var1;
	if (!b_HasRoundEnded && b_LeftSaveRoom && GameMode == 2)
	{
		new var2;
		if (oldteam == 3 || newteam == 3)
		{
			CheckIfBotsNeeded(false, false);
		}
		if (newteam == 3)
		{
			CreateTimer(1.0, InfectedBotBooterVersus, any:0, 2);
		}
	}
	return Action:0;
}

public void:OnClientDisconnect(client)
{
	if (IsFakeClient(client))
	{
		return void:0;
	}
	PlayerLifeState[client] = 0;
	GetSpawnTime[client] = 0;
	AlreadyGhosted[client] = 0;
	PlayerHasEnteredStart[client] = 0;
	PlayersInServer -= 1;
	if (!(GetHumanCount()))
	{
		b_LeftSaveRoom = false;
		b_HasRoundEnded = true;
		b_HasRoundStarted = false;
		DirectorCvarsModified = false;
		new i = 1;
		while (i <= MaxClients)
		{
			AlreadyGhosted[i] = 0;
			PlayerHasEnteredStart[i] = 0;
			i++;
		}
		new i = 1;
		while (i <= MaxClients)
		{
			FightOrDieTimer[i] = 0;
			i++;
		}
	}
	return void:0;
}

public Action:CheckIfBotsNeededLater(Handle:timer, any:spawn_immediately)
{
	CheckIfBotsNeeded(spawn_immediately, false);
	return Action:0;
}

CheckIfBotsNeeded(bool:spawn_immediately, bool:initial_spawn)
{
	if (!DirectorSpawn)
	{
		new var2;
		if (b_HasRoundEnded || (!b_LeftSaveRoom && GameMode != 3))
		{
			return 0;
		}
		CountInfected();
		new SurvCount;
		new i = 1;
		while (GetMaxClients() >= i)
		{
			new var3;
			if (IsNormalPlayer(i) && GetClientTeam(i) == 2)
			{
				SurvCount++;
			}
			i++;
		}
		new diff = MaxPlayerZombies - InfectedRealCount + InfectedBotCount + InfectedBotQueue;
		if (GameMode == 3)
		{
			diff = SurvCount - InfectedBotCount + InfectedRealCount;
		}
		if (0 < diff)
		{
			new i;
			while (i < diff)
			{
				if (spawn_immediately)
				{
					InfectedBotQueue += 1;
					CreateTimer(0.5, Spawn_InfectedBot, any:0, 0);
				}
				else
				{
					if (initial_spawn)
					{
						InfectedBotQueue += 1;
						CreateTimer(float(InitialSpawnInt), Spawn_InfectedBot, any:0, 0);
					}
					InfectedBotQueue += 1;
					new var4;
					if (GameMode == 2 && AdjustSpawnTimes && HumansOnInfected() != MaxPlayerZombies)
					{
						CreateTimer(float(InfectedSpawnTimeMax) / MaxPlayerZombies - HumansOnInfected(), Spawn_InfectedBot, any:0, 0);
					}
					new var5;
					if (GameMode == 1 && AdjustSpawnTimes)
					{
						CreateTimer(float(InfectedSpawnTimeMax - TrueNumberOfSurvivors()), Spawn_InfectedBot, any:0, 0);
					}
					CreateTimer(float(InfectedSpawnTimeMax), Spawn_InfectedBot, any:0, 0);
				}
				i++;
			}
		}
	}
	return 0;
}

CountInfected()
{
	InfectedBotCount = 0;
	InfectedRealCount = 0;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 3)
			{
				if (IsFakeClient(i))
				{
					InfectedBotCount += 1;
				}
				InfectedRealCount += 1;
			}
		}
		i++;
	}
	return 0;
}

public Action:evtFinaleStart(Handle:event, String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, CheckIfBotsNeededLater, any:1, 0);
	return Action:0;
}

BotTimePrepare()
{
	CreateTimer(1.0, BotTypeTimer, any:0, 0);
	return 0;
}

public Action:BotTypeTimer(Handle:timer)
{
	BotTypeNeeded();
	return Action:0;
}

BotTypeNeeded()
{
	new boomers;
	new smokers;
	new hunters;
	new spitters;
	new jockeys;
	new chargers;
	new tanks;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			new var1;
			if (GetClientTeam(i) == 3 && PlayerIsAlive(i))
			{
				if (IsPlayerSmoker(i))
				{
					smokers++;
				}
				if (IsPlayerBoomer(i))
				{
					boomers++;
				}
				if (IsPlayerHunter(i))
				{
					hunters++;
				}
				if (IsPlayerTank(i))
				{
					tanks++;
				}
				new var2;
				if (b_IsL4D2 && IsPlayerSpitter(i))
				{
					spitters++;
				}
				new var3;
				if (b_IsL4D2 && IsPlayerJockey(i))
				{
					jockeys++;
				}
				new var4;
				if (b_IsL4D2 && IsPlayerCharger(i))
				{
					chargers++;
				}
			}
		}
		i++;
	}
	if (b_IsL4D2)
	{
		new random = GetURandomIntRange(1, 6);
		if (random == 2)
		{
			new var5;
			if (smokers < SmokerLimit && canSpawnSmoker)
			{
				return 2;
			}
		}
		else
		{
			if (random == 3)
			{
				new var6;
				if (boomers < BoomerLimit && canSpawnBoomer)
				{
					return 3;
				}
			}
			if (random == 1)
			{
				new var7;
				if (hunters < HunterLimit && canSpawnHunter)
				{
					return 1;
				}
			}
			if (random == 4)
			{
				new var8;
				if (spitters < SpitterLimit && canSpawnSpitter)
				{
					return 4;
				}
			}
			if (random == 5)
			{
				new var9;
				if (jockeys < JockeyLimit && canSpawnJockey)
				{
					return 5;
				}
			}
			if (random == 6)
			{
				new var10;
				if (chargers < ChargerLimit && canSpawnCharger)
				{
					return 6;
				}
			}
			if (random == 7)
			{
				if (tanks < TankLimit)
				{
					return 7;
				}
			}
		}
		return BotTimePrepare();
	}
	new random = GetURandomIntRange(1, 4);
	if (random == 2)
	{
		new var11;
		if (smokers < SmokerLimit && canSpawnSmoker)
		{
			return 2;
		}
	}
	else
	{
		if (random == 3)
		{
			new var12;
			if (boomers < BoomerLimit && canSpawnBoomer)
			{
				return 3;
			}
		}
		if (random == 1)
		{
			new var13;
			if (hunters < HunterLimit && canSpawnHunter)
			{
				return 1;
			}
		}
		if (random == 4)
		{
			if (GetConVarInt(h_TankLimit) > tanks)
			{
				return 7;
			}
		}
	}
	return BotTimePrepare();
}

public Action:Spawn_InfectedBot(Handle:timer)
{
	new bid;
	if (0 < bid)
	{
		PrintToChat(bid, "Spawn_InfectedBot 1");
	}
	new var1;
	if (b_HasRoundEnded || !b_HasRoundStarted || !b_LeftSaveRoom)
	{
		return Action:0;
	}
	if (0 < bid)
	{
		PrintToChat(bid, "Spawn_InfectedBot 1.5");
	}
	new Infected = MaxPlayerZombies;
	new var2;
	if (Coordination && !DirectorSpawn && !InitialSpawn)
	{
		BotReady += 1;
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == 3)
				{
					if (!IsFakeClient(i))
					{
						Infected--;
					}
				}
			}
			i++;
		}
		if (BotReady >= Infected)
		{
			CreateTimer(3.0, BotReadyReset, any:0, 2);
		}
		InfectedBotQueue -= 1;
		return Action:0;
	}
	if (0 < bid)
	{
		PrintToChat(bid, "Spawn_InfectedBot 2");
	}
	CountInfected();
	new var3;
	if (InfectedBotCount + InfectedRealCount >= MaxPlayerZombies || InfectedBotCount + InfectedRealCount + InfectedBotQueue > MaxPlayerZombies)
	{
		InfectedBotQueue -= 1;
		return Action:0;
	}
	if (DisableSpawnsTank)
	{
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == 3)
				{
					new var4;
					if (IsPlayerTank(i) && IsPlayerAlive(i))
					{
						InfectedBotQueue -= 1;
						return Action:0;
					}
				}
			}
			i++;
		}
	}
	new bool:resetGhost[66];
	new bool:resetLife[66];
	if (0 < bid)
	{
		PrintToChat(bid, "Spawn_InfectedBot 3");
	}
	new i = 1;
	while (i <= MaxClients)
	{
		new var5;
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == 3)
			{
				if (IsPlayerGhost(i))
				{
					resetGhost[i] = true;
					SetGhostStatus(i, false);
				}
				if (!PlayerIsAlive(i))
				{
					resetLife[i] = true;
					SetLifeState(i, false);
				}
			}
		}
		i++;
	}
	if (0 < bid)
	{
		PrintToChat(bid, "Spawn_InfectedBot 4");
	}
	new anyclient = GetAnyClient();
	new bool:temp;
	if (anyclient == -1)
	{
		anyclient = CreateFakeClient("Bot");
		if (!anyclient)
		{
			LogError("[L4D] Infected Bots: CreateFakeClient returned 0 -- Infected bot was not spawned");
			return Action:0;
		}
		temp = true;
	}
	new var6;
	if (b_IsL4D2 && GameMode != 2)
	{
		new bot = CreateFakeClient("Infected Bot");
		if (bot)
		{
			ChangeClientTeam(bot, 3);
			CreateTimer(0.1, kickbot, bot, 0);
		}
	}
	new bot_type = BotTypeNeeded();
	if (0 < bid)
	{
		PrintToChat(bid, "Spawn_InfectedBot 5");
	}
	switch (bot_type)
	{
		case 0:
		{
		}
		case 1:
		{
			CheatCommand(anyclient, "z_spawn_old", "hunter auto");
		}
		case 2:
		{
			CheatCommand(anyclient, "z_spawn_old", "smoker auto");
		}
		case 3:
		{
			CheatCommand(anyclient, "z_spawn_old", "boomer auto");
		}
		case 4:
		{
			CheatCommand(anyclient, "z_spawn_old", "spitter auto");
		}
		case 5:
		{
			CheatCommand(anyclient, "z_spawn_old", "jockey auto");
		}
		case 6:
		{
			CheatCommand(anyclient, "z_spawn_old", "charger auto");
		}
		case 7:
		{
			CheatCommand(anyclient, "z_spawn_old", "tank auto");
		}
		default:
		{
		}
	}
	new i = 1;
	while (i <= MaxClients)
	{
		if (resetGhost[i] == true)
		{
			SetGhostStatus(i, true);
		}
		if (resetLife[i] == true)
		{
			SetLifeState(i, true);
		}
		i++;
	}
	if (temp)
	{
		CreateTimer(0.1, kickbot, anyclient, 0);
	}
	InfectedBotQueue -= 1;
	CreateTimer(1.0, CheckIfBotsNeededLater, any:1, 0);
	return Action:0;
}

GetAnyClient()
{
	new target = curr_client + 1;
	while (GetMaxClients() >= target)
	{
		new var1;
		if (IsNormalPlayer(target) && GetClientTeam(target) == 2 && IsPlayerAlive(target) && !IsPlayerIncapped(target))
		{
			curr_client = target;
			return target;
		}
		target++;
	}
	new target = curr_client + 1;
	while (GetMaxClients() >= target)
	{
		if (IsNormalPlayer(target))
		{
			curr_client = target;
			return target;
		}
		target++;
	}
	new target = 1;
	while (target <= curr_client)
	{
		new var2;
		if (IsNormalPlayer(target) && GetClientTeam(target) == 2 && IsPlayerAlive(target) && !IsPlayerIncapped(target))
		{
			curr_client = target;
			return target;
		}
		target++;
	}
	new target = 1;
	while (target <= curr_client)
	{
		if (IsNormalPlayer(target))
		{
			curr_client = target;
			return target;
		}
		target++;
	}
	return -1;
}

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, PropType:0, "m_isIncapacitated", 1, 0))
	{
		return true;
	}
	return false;
}

public Action:kickbot(Handle:timer, any:client)
{
	new var1;
	if (IsClientInGame(client) && !IsClientInKickQueue(client))
	{
		if (IsFakeClient(client))
		{
			KickClient(client, "");
		}
	}
	return Action:0;
}

bool:IsPlayerGhost(client)
{
	if (GetEntProp(client, PropType:0, "m_isGhost", 4, 0))
	{
		return true;
	}
	return false;
}

bool:PlayerIsAlive(client)
{
	if (!GetEntProp(client, PropType:0, "m_lifeState", 4, 0))
	{
		return true;
	}
	return false;
}

bool:IsPlayerSmoker(client)
{
	if (GetEntProp(client, PropType:0, "m_zombieClass", 4, 0) == 1)
	{
		return true;
	}
	return false;
}

bool:IsPlayerBoomer(client)
{
	if (GetEntProp(client, PropType:0, "m_zombieClass", 4, 0) == 2)
	{
		return true;
	}
	return false;
}

bool:IsPlayerHunter(client)
{
	if (GetEntProp(client, PropType:0, "m_zombieClass", 4, 0) == 3)
	{
		return true;
	}
	return false;
}

bool:IsPlayerSpitter(client)
{
	if (GetEntProp(client, PropType:0, "m_zombieClass", 4, 0) == 4)
	{
		return true;
	}
	return false;
}

bool:IsPlayerJockey(client)
{
	if (GetEntProp(client, PropType:0, "m_zombieClass", 4, 0) == 5)
	{
		return true;
	}
	return false;
}

bool:IsPlayerCharger(client)
{
	if (GetEntProp(client, PropType:0, "m_zombieClass", 4, 0) == 6)
	{
		return true;
	}
	return false;
}

bool:IsPlayerTank(client)
{
	if (ZOMBIECLASS_TANK == GetEntProp(client, PropType:0, "m_zombieClass", 4, 0))
	{
		return true;
	}
	return false;
}

SetGhostStatus(client, bool:ghost)
{
	if (ghost)
	{
		SetEntProp(client, PropType:0, "m_isGhost", any:1, 4, 0);
	}
	else
	{
		SetEntProp(client, PropType:0, "m_isGhost", any:0, 4, 0);
	}
	return 0;
}

SetLifeState(client, bool:ready)
{
	if (ready)
	{
		SetEntProp(client, PropType:0, "m_lifeState", any:1, 4, 0);
	}
	else
	{
		SetEntProp(client, PropType:0, "m_lifeState", any:0, 4, 0);
	}
	return 0;
}

TrueNumberOfSurvivors()
{
	new TotalSurvivors;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				TotalSurvivors++;
			}
		}
		i++;
	}
	return TotalSurvivors;
}

HumansOnInfected()
{
	new TotalHumans;
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i))
		{
			TotalHumans++;
		}
		i++;
	}
	return TotalHumans;
}

bool:LeftStartArea()
{
	new ent = -1;
	new maxents = GetMaxEntities();
	new i = MaxClients + 1;
	while (i <= maxents)
	{
		if (IsValidEntity(i))
		{
			decl String:netclass[64];
			GetEntityNetClass(i, netclass, 64);
			if (StrEqual(netclass, "CTerrorPlayerResource", true))
			{
				ent = i;
				if (ent > -1)
				{
					if (GetEntProp(ent, PropType:0, "m_hasAnySurvivorLeftSafeArea", 4, 0))
					{
						return true;
					}
				}
				return false;
			}
		}
		i++;
	}
	if (ent > -1)
	{
		if (GetEntProp(ent, PropType:0, "m_hasAnySurvivorLeftSafeArea", 4, 0))
		{
			return true;
		}
	}
	return false;
}

GetURandomIntRange(min, max)
{
	return min + GetURandomInt() % max - min + 1;
}

CheatCommand(client, String:command[], String:arguments[])
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, 16384);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & -16385);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
	return 0;
}

public Action:CheckSpawnTimer(Handle:timer, any:client)
{
	CheckIfBotsNeeded(true, false);
	return Action:0;
}

public Action:cmd_diff(client, args)
{
	if (!client)
	{
		return Action:0;
	}
	CountInfected();
	new diff = MaxPlayerZombies - InfectedRealCount + InfectedBotCount + InfectedBotQueue;
	PrintToChat(client, "diff: %i", diff);
	return Action:0;
}

public Action:cmd_addsbot(client, args)
{
	if (!client)
	{
		return Action:0;
	}
	if (b_HasRoundEnded)
	{
		return Action:0;
	}
	new bot = CreateFakeClient("Infected Bot");
	if (bot)
	{
		ChangeClientTeam(bot, 3);
		CreateTimer(0.1, kickbot, bot, 0);
	}
	new anyclient = GetAnyClient();
	if (anyclient)
	{
		CheatCommand(anyclient, "z_spawn_old", "hunter auto");
	}
	PrintToChat(client, "Bot added.");
	return Action:0;
}

public Action:cmd_initbots(client, args)
{
	BlockStart = 0;
	b_LeftSaveRoom = true;
	b_HasRoundStarted = true;
	b_HasRoundEnded = false;
	CreateTimer(1.0, PlayerLeftStart, any:0, 2);
	return Action:0;
}

GetHumanCount()
{
	new humans;
	new i = 1;
	while (GetMaxClients() >= i)
	{
		new var1;
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			humans++;
		}
		i++;
	}
	return humans;
}

public Action:SpawnTank(Handle:Timer)
{
	if (b_HasRoundEnded)
	{
		return Action:0;
	}
	new anyclient = GetAnyClient();
	new bool:temp;
	if (anyclient == -1)
	{
		anyclient = CreateFakeClient("Bot");
		if (!anyclient)
		{
			LogError("[L4D] Infected Bots: CreateFakeClient returned 0 -- Infected bot was not spawned");
			return Action:0;
		}
		temp = true;
	}
	new bot = CreateFakeClient("Infected Bot");
	if (bot)
	{
		ChangeClientTeam(bot, 3);
		CreateTimer(0.1, kickbot, bot, 0);
	}
	CheatCommand(anyclient, "z_spawn_old", "tank auto");
	if (temp)
	{
		CreateTimer(0.1, kickbot, anyclient, 0);
	}
	return Action:0;
}

public Action:SpawnTanks(Handle:Timer)
{
	if (b_HasRoundEnded)
	{
		return Action:0;
	}
	PrintToChatAll("А вот и танки!");
	TankBonus += 1;
	new tanks;
	TankFoundCount = 0;
	new i = 1;
	while (GetMaxClients() >= i)
	{
		new var1;
		if (IsNormalPlayer(i) && GetClientTeam(i) == 3 && IsPlayerTank(i))
		{
			tanks++;
		}
		i++;
	}
	new CurTankLimit = TankLimit;
	decl String:CurMap[256];
	GetCurrentMap(CurMap, 255);
	new var2;
	if (StrEqual(CurMap, "c2m5_concert", true) || StrEqual(CurMap, "c11m5_runway", true))
	{
		CurTankLimit = TankBonus + TankLimit;
	}
	new i = tanks;
	while (i < CurTankLimit)
	{
		if (i)
		{
			CreateTimer(float(i), SpawnTank, any:0, 0);
		}
		else
		{
			CreateTimer(0.1, SpawnTank, any:0, 0);
		}
		i++;
	}
	Timer3 = MissingTAG:0;
	return Action:0;
}

public Action:CheckTanksToSpawn(Handle:Timer)
{
	if (b_HasRoundEnded)
	{
		return Action:0;
	}
	TankTime += 1;
	if (TankTime >= 360)
	{
		TankTime = 0;
		new tanks;
		new i = 1;
		while (GetMaxClients() >= i)
		{
			new var1;
			if (IsNormalPlayer(i) && GetClientTeam(i) == 3 && IsPlayerTank(i))
			{
				tanks++;
			}
			i++;
		}
		PrintToChatAll("А вот и танки!");
		new CurTankLimit = TankLimit;
		decl String:CurMap[256];
		GetCurrentMap(CurMap, 255);
		new var2;
		if (StrEqual(CurMap, "c2m5_concert", true) || StrEqual(CurMap, "c11m5_runway", true))
		{
			CurTankLimit = TankLimit + 2;
		}
		new i = tanks;
		while (i < CurTankLimit)
		{
			if (i)
			{
				CreateTimer(float(i), SpawnTank, any:0, 0);
			}
			else
			{
				CreateTimer(0.1, SpawnTank, any:0, 0);
			}
			i++;
		}
	}
	return Action:0;
}

public IsNormalPlayer(client)
{
	if (client)
	{
		if (!IsClientConnected(client))
		{
			return 0;
		}
		if (!IsClientInGame(client))
		{
			return 0;
		}
		return 1;
	}
	return 0;
}

public Action:ResetBlockStartTimer(Handle:timer, any:client)
{
	PrintToChatAll("ResetBlockStart");
	BlockStart = 0;
	return Action:0;
}

public void:OnMapStart()
{
	RoundNum = 1;
	BlockStart = 1;
	CreateTimer(80.0, ResetBlockStartTimer, any:0, 0);
	if (!Timer4)
	{
		Timer4 = CreateTimer(1.0, DisposeOfCowards, any:0, 1);
	}
	return void:0;
}

public Action:HurtTank(Handle:Timer, any:tank)
{
	if (b_HasRoundEnded)
	{
		return Action:0;
	}
	new alive = GetAnyClient();
	new var1;
	if (!IsNormalPlayer(tank) || !IsNormalPlayer(alive))
	{
		return Action:0;
	}
	HurtPoint(alive, tank, 1, 0, 10);
	return Action:0;
}

HurtPoint(client, ent, dmg, dmg_type, dmg_radius)
{
	if (!IsNormalPlayer(client))
	{
		return 0;
	}
	if (!IsValidEdict(ent))
	{
		return 0;
	}
	new Float:pos[3] = 0.0;
	decl String:StrDamage[16];
	decl String:StrDamageType[16];
	decl String:StrDamageRadius[16];
	decl String:strDamageTarget[16];
	Format(StrDamageType, 16, "%i", dmg);
	Format(StrDamageType, 16, "%i", dmg_type);
	Format(StrDamageRadius, 16, "%i", dmg_radius);
	Format(strDamageTarget, 16, "hurtme%d", ent);
	GetEntPropVector(ent, PropType:0, "m_vecOrigin", pos, 0);
	pos[2] += 1.0;
	new pointHurt = CreateEntityByName("point_hurt", -1);
	DispatchKeyValue(ent, "targetname", strDamageTarget);
	DispatchKeyValue(pointHurt, "DamageTarget", strDamageTarget);
	DispatchKeyValue(pointHurt, "Damage", StrDamage);
	DispatchKeyValue(pointHurt, "DamageRadius", StrDamageRadius);
	DispatchKeyValue(pointHurt, "DamageType", StrDamageType);
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);
	new var1;
	if (client > 0 && client < MaxClients && IsClientInGame(client))
	{
		var2 = client;
	}
	else
	{
		var2 = -1;
	}
	AcceptEntityInput(pointHurt, "Hurt", var2, -1, 0);
	DispatchKeyValue(pointHurt, "classname", "point_hurt");
	DispatchKeyValue(ent, "targetname", "null");
	AcceptEntityInput(pointHurt, "Kill", -1, -1, 0);
	return 0;
}

GetBizonID()
{
	new i = 1;
	while (GetMaxClients() >= i)
	{
		new var1;
		if (IsNormalPlayer(i) && StrEqual(GetRealName(i), "Woonan", true))
		{
			return i;
		}
		i++;
	}
	return 0;
}

String:GetRealName(client, _arg1)
{
	new String:name[32] = "noname";
	if (IsNormalPlayer(client))
	{
		GetClientName(client, name, 32);
	}
	return name;
}

