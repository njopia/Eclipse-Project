#define PLUGIN_VERSION "2.0"
#define PLUGIN_NAME "onepiece"
#define DB_CONF_NAME "default"
#define DB_CONF_NAME_STATS "hlstats"
#define L4D_MAXCLIENTS GetMaxClients()
#define L4D_MAXCLIENTS_PLUS1 (L4D_MAXCLIENTS + 1)
#define MAX_LINE_WIDTH 64

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
//#include "gamerules.inc"

#define UNLOCK 0
#define LOCK 1

#define GAMEMODE_UNKNOWN -1
#define GAMEMODE_COOP 0
#define GAMEMODE_VERSUS 1
#define GAMEMODE_REALISM 2
#define GAMEMODE_SURVIVAL 3
#define GAMEMODE_SCAVENGE 4
#define GAMEMODE_REALISMVERSUS 5
#define GAMEMODE_MUTATIONS 6
#define GAMEMODES 7

#define SAFEDOOR_CLASS "prop_door_rotating_checkpoint"
#define SAFEDOOR_MODEL_01 "models/props_doors/checkpoint_door_01.mdl"
#define SAFEDOOR_MODEL_02 "models/props_doors/checkpoint_door_-01.mdl"

static	bool:g_bLateLoad;

new fTrigger;

new hostport_xtremecoop1 = 27015;
new hostport_xtremeversus1 = 27016;
new hostport_xtremecoop2 = 27017;
new hostport_xtremeversus2 = 27018;

new bool: AllowWarning = true;
new bool: RoundStarted = false;
new MapStart = 0;
new Handle:cvar_Gamemode = INVALID_HANDLE;

new VoteMapTime = 0;
new entDoorStart = 0;
new entDoorGoal = 0;
new StartMarker = 0;
new bool: DoorInited = false;
new bool: BlockConnect = false;
new bool: BlockConnectStart = false;

new Handle:toCheckReg;
new Handle:toUpdateSkill;

new String:CurrentGamemode[MAX_LINE_WIDTH];
new String:CurrentGamemodeLabel[MAX_LINE_WIDTH];
new CurrentGamemodeID = GAMEMODE_UNKNOWN;

new Handle:fSetCampaignScores = INVALID_HANDLE;
new Handle:fGetTeamScore = INVALID_HANDLE;
new oCurrentStamp = -1;
new bool:DoorUnlocked = true;
new RoundNum = 0;

new NoHumanTime = 0;

new AllDeadCount = 0;

new LastKnownScoreTeamA;
new LastKnownScoreTeamB;

new vmpg = 8;

new Float: SpawnFixPos[MAXPLAYERS + 1][3];

new PlayerChangedTeam[MAXPLAYERS + 1];
new RegProcess[MAXPLAYERS + 1];
new ExClients[MAXPLAYERS + 1];
new ExClientsCount = 0;

new SkillProcess = 0;
new skillclient,clienttokick;
new SkillParam;
new AllowPass[MAXPLAYERS + 1];
new AllowSkill[MAXPLAYERS + 1];
new ClientSkill[MAXPLAYERS + 1];
new DoDataMove[MAXPLAYERS + 1];
new RegDone[MAXPLAYERS + 1];
new DataMovePanelShowing[MAXPLAYERS + 1];
new ForceAfk[MAXPLAYERS + 1];

new ShowInfo[MAXPLAYERS + 1];

new String: sv_pass[100];
new RestartTime = 10;

new bool:MapLoaded = false;
new bool:IsReady[MAXPLAYERS+1] = false;
new Float:g_Eye_Position[MAXPLAYERS+1][3]; 
new Float:StartPos[3];
new bool:IsPluginStarted = false;
new TimeToStartLeft = 60;
new bool:Freeze = false;

new ScoreATeam = 0;
new ScoreBTeam = 0;
new RoundCount = 0;
new ClientLogickTeam[MAXPLAYERS + 1];

new String:acLogin[255][255];
new String:acPass[255][255];
new acCount = 0;

new String:WarningReason[MAXPLAYERS + 1][255];
new WarningLvl[MAXPLAYERS + 1];
new PunishLvl[MAXPLAYERS + 1];
new String:BadNames[255][255];
new String:AdminIds[255][255];
new bnCount = 0;
new iaCount = 0;

new Handle:Timer1 = INVALID_HANDLE;
new Handle:Timer2 = INVALID_HANDLE;
new Handle:Timer3 = INVALID_HANDLE;
new Handle:Timer4 = INVALID_HANDLE;
new Handle:Timer5 = INVALID_HANDLE;
new Handle:Timer6 = INVALID_HANDLE;
new Handle:Timer7 = INVALID_HANDLE;
new Handle:TimerOnStart = INVALID_HANDLE;
new Handle:DoorLockTimer = INVALID_HANDLE;
new Handle:TimerBC = INVALID_HANDLE;

new PostAdminCheckRetryCounter[MAXPLAYERS + 1];

new Float:STop20 = 0;
new Float:ITop20 = 0;
new Float:STop100 = 0;
new Float:ITop100 = 0;
new Float:STop1k = 0;
new Float:ITop1k = 0;
new Float:SOther = 0;
new Float:IOther = 0;
new Float:SSkill1 = 0;
new Float:ISkill1 = 0;
new Float:SSkill2 = 0;
new Float:ISkill2 = 0;
new Float:SSkill3 = 0;
new Float:ISkill3 = 0;

new SSkill[11];
new ISkill[11];

new ent_safedoor;
new ent_safedoor_check;

enum VoteManager_Vote
{
	Voted_No = 0,
	Voted_Yes,
	Voted_CantVote,
	Voted_CanVote
};

new RoundEnd = 0;
new MapEnd = 0;
new hint = 1;
new bool:AllowBalance = true;
new bool:AllowVoteBalance = true;
new AllowSkillBalance = 1;
new InBalance;
new String:DB_PLAYERS_TOTALPOINTS[1024] = "points + points_survivors + points_infected + points_realism + points_realism_survivors + points_realism_infected + points_mutations";
new ClientPoints[MAXPLAYERS + 1];
new ClientWish[MAXPLAYERS + 1];
new SpecPanelSwitch[MAXPLAYERS + 1];
new AllowVote[MAXPLAYERS + 1];


new Handle:gConf = INVALID_HANDLE;
new Handle:fSHS = INVALID_HANDLE;
new Handle:fTOB = INVALID_HANDLE;
new Handle:db = INVALID_HANDLE;
new Handle:db2 = INVALID_HANDLE;

new bool:AllowJoin[MAXPLAYERS + 1];
new Frags[MAXPLAYERS + 1];
new FragsLine[MAXPLAYERS + 1];

new Dmg[MAXPLAYERS + 1];
new LastDmg[MAXPLAYERS + 1];
new SessionDmg[MAXPLAYERS + 1];
new DmgLine[MAXPLAYERS + 1];

new bool:NameDelay[MAXPLAYERS + 1];

new RespawnTime[MAXPLAYERS + 1] = 0;

new IsRegName[MAXPLAYERS + 1];
new VipStatus[MAXPLAYERS + 1];
new ClientRank[MAXPLAYERS + 1];
new AllowMsg[MAXPLAYERS + 1];
new AllowName[MAXPLAYERS + 1];
new HLSSkill[MAXPLAYERS + 1];
new String:glogin[255];
new String:gpass[255];
new Bool:IsRegProcess = 0;
new Bool:IsCheckRegProcess = false;
new Bool:IsUpdateSkillProcess = false;
new propinfoghost;
new NewTank = 1;
new LastHurt[MAXPLAYERS + 1];
new NewComer[MAXPLAYERS + 1];
new BanSrok;
new VoteType, VoteClient;
new humanscount;
new Bool:isvote = 0;
new Bool:isvotedelay = 0;
new yes,no;
//new maxinfected,maxsurvivors;
new String:VoteReason[255];
new String:VoteTitle[255];
new String:VoteSteamID[255];
new ClientTeam[MAXPLAYERS + 1];
new TimerCount = 0;
new hostport;
new String: hostip[255];
new AllowRP = 1;

new UserMsg:g_SayText2;

#define LOG_PATH						"logs\\onepiece.log"
static String:	logfilepath[256];


public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "Woonan modified by Xtreme-Infection",
	description = "Private Plugin modified by Xtreme-Infection ",
	version = PLUGIN_VERSION,
	url = "https://xtreme-infection.com"
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
	return APLRes_Success;
}

public OnPluginStart() 
{
	
	BuildPath(Path_SM, logfilepath, sizeof(logfilepath), LOG_PATH);
	LogToFile(logfilepath, "|               PLUGIN START                |");
			
	toCheckReg = CreateArray();
	toUpdateSkill = CreateArray();
	
	PrepareAllSDKCalls();

	IsPluginStarted = true;
	
	//if (!ConnectDBstats()) {
//		SetFailState("Connecting to database failed(smod).");
		//return;
	//}
	
	if (!ConnectDB()) {
		SetFailState("Connecting to database failed(smod).");
		return;
	}
		
		
		
	//if (!g_bLateLoad) {
	//	LogToFile(logfilepath, "!LateLoad, blocking connect");
	//	BlockConnectStart = true;
	//	CreateTimer(20.0, ResetBlockConnectStart, INVALID_HANDLE);		
	//}
		
	LoadTranslations("onepiece");
	
	SetNameDelay(false);
	HookUserMessage(GetUserMessageId("SayText2"), UserMessageHook, true); 
	
	hostport = GetConVarInt(FindConVar("hostport"));
	GetConVarString(FindConVar("hostip"), hostip, sizeof(hostip));

	AddCommandListener(Command_Setinfo, "setinfo");	
	
	cvar_Gamemode = FindConVar("mp_gamemode");
	GetConVarString(cvar_Gamemode, CurrentGamemode, sizeof(CurrentGamemode));
	CurrentGamemodeID = GetCurrentGamemodeID();
	HookConVarChange(cvar_Gamemode, action_GamemodeChanged);
	
	CreateTimer(1.0, RegConsoleCmdTimer, INVALID_HANDLE);	
		
	SetNewComers(0);
			
	HookConVarChange(FindConVar("sb_all_bot_game"), sballbotgamechanged);
	if (GetConVarInt(FindConVar("sb_all_bot_game")) == 0) SetConVarInt(FindConVar("sb_all_bot_game"), 1);
	propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");

	//HookEvent("survival_round_start", event_SurvivalStart); // Timed Maps event
	HookEvent("player_afk", Event_PlayerWentAFK, EventHookMode_Pre);
	HookEvent("player_bot_replace", Event_BotReplacedPlayer, EventHookMode_Post);	
	HookEvent("tank_spawn", Event_TankSpawn);	
	HookEvent("player_left_checkpoint", event_LeftStart, EventHookMode_Pre);
	HookEvent("player_entered_checkpoint", event_EnterStart, EventHookMode_Pre);
	HookEvent("round_end", event_RoundEnd, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_team", event_PlayerTeam);	
	HookEvent("round_freeze_end", 	Event_RoundFreezeEnd, 	EventHookMode_Post)
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("map_transition", event_MapTransition);
	HookEvent("player_death", event_PlayerDeath);	
	HookEvent("player_spawn", event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_start_post_nav", OnRoundStartPostNav);
	HookEvent("player_use", Event_Player_Use, EventHookMode_Pre);
		
	CreateTimer(5.0, BalanceTimer, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer5 == INVALID_HANDLE) Timer5 = CreateTimer(60.0, HordeTimer, INVALID_HANDLE, TIMER_REPEAT);	
		
	SetAllAllowJoin(1);
	SetAllAllowSkill();
		
	SetAllAllowMsg();
	ResetTeams();
	
	CreateTimer(1.0, ExecAllCfg, INVALID_HANDLE);
	
	oCurrentStamp = FindSendPropInfo("CTerrorPlayer", "m_ghostSpawnClockCurrentDelay");
		
	VoteMapTime = 10;
	
	ResetAllFrags();
	UpdateFragsLine();
		
	vmpg = GetConVarInt(FindConVar("sv_visiblemaxplayers"));
			
	if (Timer6 == INVALID_HANDLE) Timer6 = CreateTimer(1.0, CheckRegArrayTimer, INVALID_HANDLE, TIMER_REPEAT);
			
	LogToFile(logfilepath, "RefreshAllTimer");
	CreateTimer(2.0, RefreshAllTimer, INVALID_HANDLE);	
	
	
}

public SetNewComers(value) {
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			NewComer[i] = value;
		}
	}
}

bool:ConnectDB()
{
	LogToFile(logfilepath, "ConnectDB 1");
	if (SQL_CheckConfig(DB_CONF_NAME))
	{
		LogToFile(logfilepath, "ConnectDB 2");
		new String:Error[256];
		db = SQL_Connect(DB_CONF_NAME, true, Error, sizeof(Error));
		LogToFile(logfilepath, "ConnectDB 3");
		if (db == INVALID_HANDLE)
		{
			LogToFile(logfilepath, "Failed to connect to database: %s", Error);
			LogError("Failed to connect to database: %s", Error);
			return false;
		}
		else if (!SQL_FastQuery(db, "SET NAMES utf8;"))
		{
			LogToFile(logfilepath, "Failed to update encoding to UTF8: %s", Error);
			if (SQL_GetError(db, Error, sizeof(Error)))
				LogError("Failed to update encoding to UTF8: %s", Error);
			else
			LogError("Failed to update encoding to UTF8: unknown");
		}
		LogToFile(logfilepath, "ConnectDB 6");
	}
	else
	{
		LogToFile("Databases.cfg missing '%s' entry!", DB_CONF_NAME);
		LogError("Databases.cfg missing '%s' entry!", DB_CONF_NAME);
		return false;
	}
	LogToFile(logfilepath, "ConnectDB end");
	return true;
}

bool:ConnectDBstats()
{
	LogToFile(logfilepath, "ConnectDBstats 1");
	if (SQL_CheckConfig(DB_CONF_NAME_STATS))
	{
		LogToFile(logfilepath, "ConnectDBstats 2");
		new String:Error[256];
		db2 = SQL_Connect(DB_CONF_NAME_STATS, true, Error, sizeof(Error));
		LogToFile(logfilepath, "ConnectDBstats 3");
		if (db2 == INVALID_HANDLE)
		{
			LogToFile(logfilepath, "ConnectDBstats 4");
			LogError("Failed to connect to database: %s", Error);
			return false;
		}
		else if (!SQL_FastQuery(db2, "SET NAMES utf8;"))
		{
			LogToFile(logfilepath, "ConnectDBstats 5");
			if (SQL_GetError(db2, Error, sizeof(Error)))
				LogError("Failed to update encoding to UTF8: %s", Error);
			else
			LogError("Failed to update encoding to UTF8: unknown");
			LogToFile(logfilepath, "ConnectDBstats 6");
		}
	}
	else
	{
		LogToFile(logfilepath, "ConnectDBstats 7");
		LogError("Databases.cfg missing '%s' entry!", DB_CONF_NAME_STATS);
		return false;
	}
	LogToFile(logfilepath, "ConnectDBstats end");
	return true;
}

public checkreg(any:client)
{
		
	if ( (!IsValidPlayer(client)) || (MapEnd > 0) || (db == INVALID_HANDLE) ) return;
			
	LogToFile(logfilepath, "checkreg: %i %s", client, GetName(client));
	PrintToChat(client, "Авторизация ...");
	
	if (IsCheckRegProcess) return;
	IsCheckRegProcess = true;

	VipStatus[client] = 0;	
	
	decl String:login[255];
	GetClientInfo(client,"login",login,sizeof(login));
	
	decl String:pass[255];
	GetClientInfo(client,"pass",pass,sizeof(pass));
	
	decl String:SteamID[255];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	TrimString(login);
	TrimString(pass);
	
	decl String:sChar;
	decl String:sArg[255];
	
	Format(sArg, sizeof(sArg), "%s%s", login, pass);
	
	new i = 0;
	while (i<strlen(sArg)) {
		sChar = sArg[i];
		if (IsCharMB(sChar)) {
			PrintToChat(client, "Разрешены только латинские символы.");
			return;
		}
		i+=GetCharBytes(sArg[i]);
	}
	
		
	decl String:query[512];
		
	if ((strlen(login) == 0) || (strlen(pass) == 0)) {
		PrintToChat(client,"\x05%t", "authorize1");
		PrintToChat(client,"\x01%t \x04sm_enter \"%t\" \"%t\"", "authorize7", "login", "pass");
		PrintToChat(client,"\x01%t \x04sm_reg \"%t\" \"%t\"", "authorize2", "login", "pass");
		PrintToChat(client,"%t \x03autoexec.cfg \x01%t", "authorize3", "authorize4");
		PrintToChat(client,"\x04setinfo login \"%t\"", "login");
		PrintToChat(client,"\x04setinfo pass \"%t\"", "pass");
		PrintToChat(client,"%t", "authorize5");
		PrintToChat(client,"%t \x05%t", "authorize6", "siteurl");
		IsRegName[client] = 0;
		
		GetClientRegData(client);
		return;
	}
	
	
	//SQL_FastQuery(db, "SET NAMES utf8;")
	Format(query, sizeof(query), "SELECT * FROM reg_name WHERE login = '%s' and pass = '%s'", login, pass);
	SQL_TQuery(db, regnamequery, query, client);
	
	
	
}

public isadminquery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if ( (hndl == INVALID_HANDLE) || (!IsValidPlayer(client)) || (MapEnd > 0) )
		return;
	
		
}

public regnamequery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if ( (hndl == INVALID_HANDLE) || (!IsValidPlayer(client)) || (MapEnd > 0) )
	{
		IsCheckRegProcess = false;
		LogToFile(logfilepath, "regnamequery failed: %i %s", client, GetName(client));
		return;
	}
	
	LogToFile(logfilepath, "regnamequery: %i %s", client, GetName(client));
	
	new String:basename[255];
	new String:basesteamid[255];
	new String:clientpass[255];
	new String:clientlogin[255];
	new String:basepass[255];
	new String:baselogin[255];
	new String:teamname[255];
	new String:baseaftor[255];
	new String:steamname[255];
	new String:query[255];
	new String:buf[255] = "";
	
	if (!SQL_HasResultSet(hndl)) {
		IsCheckRegProcess = false;
		return;	
	}

	if (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, basename, sizeof(basename));
		SQL_FetchString(hndl, 1, basepass, sizeof(basepass));
		SQL_FetchString(hndl, 2, teamname, sizeof(teamname));
		SQL_FetchString(hndl, 4, steamname, sizeof(steamname));
		SQL_FetchString(hndl, 8, baseaftor, sizeof(baseaftor));
		SQL_FetchString(hndl, 9, basesteamid, sizeof(basesteamid));
		SQL_FetchString(hndl, 14, baselogin, sizeof(baselogin));
			
		GetClientInfo(client,"login",clientlogin,sizeof(clientlogin));
		GetClientInfo(client,"pass",clientpass,sizeof(clientpass));
		
		if ((strlen(clientlogin) <= 0) || (strlen(clientpass) <= 0)) {
			GetClientRegData(client);
			return;
		}
		
		IsRegName[client] = 1;
		PrintToChat(client,"\x04%t", "authorize10");
		
		decl String:SteamID[255];
		GetClientAuthString(client, SteamID, sizeof(SteamID));
		
		if (!StrEqual(SteamID,basesteamid)) {
			if ((strlen(SteamID) < 13) || (StrContains(SteamID, "STEAM", false) == -1)) {
				PrintToChat(client,"\x05Внимание\x01, Ваш(\x03%s\x01) \x04SteamID \x01сменился, но новый \x04%s\x01 не соответвует формату. \x05Замена отменена\x01.",GetRealName(client),SteamID);
				GetClientRegData(client);
				return;
			}
			
			
			if (DoDataMove[client] == 0) {
				DataMovePanelShowing[client] = 1;
				ShowMovePanel(client, basesteamid, SteamID);
				RegProcess[client] = 0;
				IsCheckRegProcess = false;
				return;
			}
			
			PrintToChat(client,"\x05Внимание\x01, Ваш(\x03%s\x01) \x04SteamID \x01сменился, статистика со \x04старого %s \x01перенесена на \x04новый %s",GetRealName(client),basesteamid,SteamID);
			//PrintToChat(client,"\x05Внимание\x01, Ваш(\x03%s\x01) \x04SteamID \x01отличается \x04был %s \x01текущий \x04%s",GetRealName(client),basesteamid,SteamID);
			
			
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack,client);
			WritePackString(hPack,SteamID);
			WritePackString(hPack,basesteamid);
			WritePackString(hPack,baselogin);
			WritePackString(hPack,basepass);
			
			Format(query, sizeof(query), "DELETE from reg_name where steamid = '%s'", SteamID);
			SQL_TQuery(db, CheckRegHandle1, query, hPack);
			Format(query, sizeof(query), "update ignore skills set aftor_steamid = '%s' where aftor_steamid = '%s'", SteamID, basesteamid);
			SQL_TQuery(db, NullHandle, query, 0);
			Format(query, sizeof(query), "update ignore skills set skill_steamid = '%s' where skill_steamid = '%s'", SteamID, basesteamid);
			SQL_TQuery(db, NullHandle, query, 0);
			PrintToChat(client, "\x01Ваши \x04оценки мастерства \x01перенесены на новый \x03SteamID\x01: %s", SteamID);
			
			return;
		}
		
		
	}
	else {
		PrintToChat(client,"\x04%t", "authorize11");
		IsRegName[client] = 0;
		
	}
	
	GetClientRegData(client);
}

public GetClientRegData(any:client)
{
	if ( (!IsValidPlayer(client)) || (MapEnd > 0) ) {
		LogToFile(logfilepath, "GetClientRegData failed: %i %s", client, GetName(client));
		IsCheckRegProcess = false;
		return;
	}
	
	LogToFile(logfilepath, "GetClientRegData: %i %s", client, GetName(client));
	
	decl String:SteamID[255];
	decl String:query[1024];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	Format(query, sizeof(query), "SELECT steamid, pass, status, entertext, datediff(status_end, now()), warnings, punish FROM reg_name WHERE steamid = '%s'", SteamID);
	SQL_TQuery(db, regnamequery2, query, client);
	
}

public regnamequery2(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if ( (hndl == INVALID_HANDLE) || (!IsValidPlayer(client)) || (MapEnd > 0) )
	{
		LogToFile(logfilepath, "regnamequery2 failed: %i %s", client, GetName(client));
		IsCheckRegProcess = false;
		return;
	}
	
	LogToFile(logfilepath, "regnamequery2: %i %s", client, GetName(client));
	
	new String:steamid[255];
	new String:clientpass[255];
	new String:basepass[255];
	new String:teamname[255];
	new String:steamname[255];
	new String:buf[255] = "";
	new String:entertext[255] = "";
	new String:query[255];
	new DateDiff = 0;
	
	decl String:SteamID[255];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	if (!SQL_HasResultSet(hndl)) {
		IsCheckRegProcess = false;
		return;
	}
	
	if (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
		SQL_FetchString(hndl, 1, basepass, sizeof(basepass));
		VipStatus[client] = SQL_FetchInt(hndl, 2);
		//if ( (hostport == 27226) && (VipStatus[client] > 1) ) VipStatus[client] = 1;
		SQL_FetchString(hndl, 3, entertext, sizeof(entertext));
		if ((!SQL_IsFieldNull(hndl, 4)) && (VipStatus[client] > 1)) {
			DateDiff = SQL_FetchInt(hndl, 4);
			if (DateDiff <= 0) {
				PrintToChat(client, "\x04[VIP] \x01Ваш VIP статус закончился.");
				PrintHintText(client, "\x04[VIP] \x01Ваш VIP статус закончился.");
				new String:query2[255];
				Format(query2, sizeof(query2), "UPDATE reg_name SET status = was_status, status_end = '0000-00-00 00:00' where steamid = '%s'", SteamID);
				SQL_TQuery(db, NullHandle, query2, 0);
			}
		}
		
		GetClientInfo(client,"pass",clientpass,sizeof(clientpass));
		Format(query, sizeof(query), "UPDATE reg_name SET name = '%s', connect_time = now() where steamid = '%s'", GetName(client), SteamID);
		
		WarningLvl[client] = SQL_FetchInt(hndl, 5);
		PunishLvl[client] = SQL_FetchInt(hndl, 6);
		
		if (WarningLvl[client] >= 3) {
			new PunishTime = (PunishLvl[client]*(24*60))+(24*60);
			ServerCommand("sm_ban #%i %i \"%s\"", GetClientUserId(client), PunishTime, "Warning 3/3");
			//BanClient(client, PunishTime, BANFLAG_AUTHID, "Warnings 3/3","Warnings 3/3");
			
			decl String:query2[512];
			Format(query2, sizeof(query2), "update reg_name set warnings = 0, punish = punish + 1 where steamid = '%s'", SteamID);
			SQL_TQuery(db, NullHandle, query2, 0);
			IsCheckRegProcess = false;
			KickClient(client, "Warning 3/3");
			return;
		}
		
	}
	else {
		Format(query, sizeof(query), "insert into reg_name (name, steamid, connect_time, skillparam, skill, status) values ('%s','%s',now(), 0, 5, 0)", GetName(client), SteamID);
		//RoundFloat(FloatDiv(MaxSkillParam - MinSkillParam,4))
		VipStatus[client] = 0;
		PrintToChatAll("\x05%t \x04%s", "newplayer", GetRealName(client));
		WarningLvl[client] = 0;
		PunishLvl[client] = 0;
	}
	
	
	
	if (VipStatus[client] > 0) {
		PrintToChatAll("\x01%t \x03%s \x01%t \x05VIP \x01%t %i", "for1", GetRealName(client), "for2", "status", VipStatus[client]);
		//if (GetClientTeam(client) == 2) ServerCommand("sm_lightclient #%i 0 255 20", GetClientUserId(client));
	}
	if ( (strlen(entertext)>0) && (VipStatus[client] > 0) ) PrintToChatAll("\x05%s\x01: \x03%s",GetRealName(client),entertext);
	
	//SQL_FastQuery(db, "SET NAMES utf8;")
	SQL_TQuery(db, TimeSetHandle, query, client);
}

public TimeSetHandle(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if ( (db == INVALID_HANDLE) || (!IsValidPlayer(client)) ) {
		LogToFile(logfilepath, "TimeSetHandle failed: %i %s", client, GetName(client));
		IsCheckRegProcess = false;
		return;
	}
	
	LogToFile(logfilepath, "TimeSetHandle: %i %s", client, GetName(client));
		
	RegDone[client] == 1;
	
	CreateTimer(1.0, DelayedRegFinish, client);
		
}
public Action:DelayedRegFinish(Handle:timer, any:client)
{
	IsCheckRegProcess = false;
		
	new toDel = FindValueInArray(toCheckReg, client);
	if (toDel != -1) RemoveFromArray(toCheckReg, toDel);
	
	if (GetArraySize(toCheckReg) > 0)
		checkreg(GetArrayCell(toCheckReg, 0));
}

public NullHandle(Handle:owner, Handle:hndl, const String:error[], any:hPack)
{

}

public CheckRegHandle1(Handle:owner, Handle:hndl, const String:error[], any:hPack)
{
		
	if (hndl == INVALID_HANDLE) {
		IsCheckRegProcess = false;
		LogToFile(logfilepath, "CheckRegHandle1 failed");
		return;
	}
		
	ResetPack(hPack);
	new String:SteamID[255];
	new String:basesteamid[255];
	new String:baselogin[255];
	new String:basepass[255];
	new client = ReadPackCell(hPack);
	
	ReadPackString(hPack,SteamID,sizeof(SteamID));
	ReadPackString(hPack,basesteamid,sizeof(basesteamid));
	ReadPackString(hPack,baselogin,sizeof(baselogin));
	ReadPackString(hPack,basepass,sizeof(basepass));
	
	decl String:query[255];
	
	//SQL_FastQuery(db, "SET NAMES utf8;")
	
	Format(query, sizeof(query), "UPDATE reg_name SET steamid = '%s' where login = '%s' and pass = '%s'", SteamID, baselogin, basepass);
	SQL_TQuery(db, CheckRegHandle2, query, hPack);
	
}

public CheckRegHandle2(Handle:owner, Handle:hndl, const String:error[], any:hPack)
{
	if (hndl == INVALID_HANDLE) {
		IsCheckRegProcess = false;
		LogToFile(logfilepath, "CheckRegHandle2 failed");
		return;
	}
	
	ResetPack(hPack);
	new String:SteamID[255];
	new String:basesteamid[255];
	new String:baselogin[255];
	new String:basepass[255];
	new client = ReadPackCell(hPack);
	
	ReadPackString(hPack,SteamID,sizeof(SteamID));
	ReadPackString(hPack,basesteamid,sizeof(basesteamid));
	ReadPackString(hPack,baselogin,sizeof(baselogin));
	ReadPackString(hPack,basepass,sizeof(basepass));
	/*
	PrintToChat(client, "\x05Перенос статистики отключен.");
	GetClientRegData(client);
	return;
	
	if (IsValidPlayer(client)) PrintToChat(client, "\x05Перенос статистики/рейтинга ...");
		
	decl String:query[255];
	Format(query, sizeof(query), "update hlstats_PlayerUniqueIds set uniqueid = concat(uniqueid,'_',now()) where uniqueid = '%s' and game = 'l4d2'", CutSteamID(SteamID));
	SQL_TQuery(db2, CheckRegHandle3, query, hPack);
	*/
	decl String:query[255];//, game[20];
	//if (CurrentGamemodeID == 0) Format(game, sizeof(game), "l4d2_coop"); else Format(game, sizeof(game), "l4d2");
	Format(query, sizeof(query), "select * from stats_move where old_id = '%s' and new_id = '%s' and game = 'l4d2' and status = 0", CutSteamID(basesteamid), CutSteamID(SteamID));
	SQL_TQuery(db, CheckRegHandle3, query, hPack);
	//Format(query, sizeof(query), "select * from stats_move where old_id = '%s' and new_id = '%s' and game = 'l4d2_coop' and status = 0", CutSteamID(basesteamid), CutSteamID(SteamID));
	//SQL_TQuery(db, CheckRegHandle3, query, hPack);
	
	if (IsValidPlayer(client)) PrintToChat(client, "%t", "stats1");
		
	//GetClientRegData(client);	*/
}

public CheckRegHandle3(Handle:owner, Handle:hndl, const String:error[], any:hPack)
{

	if (hndl == INVALID_HANDLE) {
		IsCheckRegProcess = false;
		LogToFile(logfilepath, "CheckRegHandle3 failed");
		return;
	}
	
	ResetPack(hPack);
	new String:SteamID[255];
	new String:basesteamid[255];
	new String:baselogin[255];
	new String:basepass[255];
	new client = ReadPackCell(hPack);
	
	ReadPackString(hPack,SteamID,sizeof(SteamID));
	ReadPackString(hPack,basesteamid,sizeof(basesteamid));
	ReadPackString(hPack,baselogin,sizeof(baselogin));
	ReadPackString(hPack,basepass,sizeof(basepass));
	
	/*decl String:query[255];
	Format(query, sizeof(query), "update hlstats_PlayerUniqueIds set uniqueid = '%s' where uniqueid = '%s' and game = 'l4d2'", CutSteamID(SteamID), CutSteamID(basesteamid));
	//PrintToChat(client, query);
	SQL_TQuery(db2, CheckRegHandle4, query, client);
	*/
	//if (IsValidPlayer(client)) PrintToChat(client, "Cтатистика/рейтинг будут перенесены на новый steamid в течении минуты.");
	//CloseHandle(hPack);
	//GetClientRegData(client);
	
	//if (!SQL_HasResultSet(hndl)) {
		//IsCheckRegProcess = false;
	//	return;
	//}
	
	if (!SQL_FetchRow(hndl))
    {
		decl String:query[255];//, game[20];
		//if (CurrentGamemodeID == 0) Format(game, sizeof(game), "l4d2_coop"); else Format(game, sizeof(game), "l4d2");
		Format(query, sizeof(query), "insert into stats_move (old_id, new_id, game, status) values ('%s', '%s', 'l4d2', 0)", CutSteamID(basesteamid), CutSteamID(SteamID));
		SQL_TQuery(db, CheckRegHandle4, query, client);
	}
	else {
		if (IsValidPlayer(client))  {
			PrintToChat(client, "\x05%t", "stats2")
			GetClientRegData(client);
		}
	}
	CloseHandle(hPack);
}

public CheckRegHandle4(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	
	if (hndl == INVALID_HANDLE) {
		IsCheckRegProcess = false;
		LogToFile(logfilepath, "CheckRegHandle4 failed");
		return;
	}
		
	if (IsValidPlayer(client))  {
		PrintToChat(client, "\x05%t", "stats2")
		GetClientRegData(client);
	}
	else IsCheckRegProcess = false;
}

public Action:ClientPostAdminCheck(Handle:timer, any:client)
{
	LogToFile(logfilepath, "ClientPostAdminCheckTimer start: %i: %s", client, GetName(client));
	
	if (!IsValidPlayer(client))  return;
    	
	if (Freeze) {
		PrintToChat(client, "%t", "start1");
		PrintToChat(client, "%t", "start2");
		PrintToChat(client, "%t", "start3");
		PrintToChat(client, "%t", "start4");
	}
	
	AllowPass[client] = 1;
	AllowJoin[client] = 1;
	SpecPanelSwitch[client] = 0;
	AllowSkill[client] = 1;		
	Frags[client] = 0;
	AllowName[client] = 1;
	DoDataMove[client] = 0;
	Dmg[client] = 0;
	SessionDmg[client] = 0;
	LastDmg[client] = 0;
	RegProcess[client] = 0;
	AllowMsg[client] = 1;
		
	new Float:ct;
	ct = GetClientTime(client);
	
	LogToFile(logfilepath, "ClientPostAdminCheckTimer 2: %i: %s", client, GetName(client));
	
	if (IsBadName(client)) {
		PrintHintText(client, "%t", "start5");
		PrintToChat(client,"\x05%t", "start5");
		PrintToChat(client,"\x05%t \x03!name %t \x05%t \x03sm_name \"%\"", "start6", "start7", "start8", "start7");
	}
	
	if (FloatCompare(ct, 120.0) == -1) {
		
		NewComer[client] = 1;
		ClientTeam[client] = 0;
		ClientRank[client] = 0;
		ShowInfo[client] = 1;
		if (CurrentGamemodeID != 1) ClientWish[client] = 2;
		else ClientWish[client] = 0;
	
		LogToFile(logfilepath, "ClientPostAdminCheckTimer 3 newcomer: %i: %s", client, GetName(client));
	}
	else  {
		NewComer[client] = 0;
		
	}
	
	LogToFile(logfilepath, "ClientPostAdminCheckTimer 4: %i: %s", client, GetName(client));
	
	VipStatus[client] = 0;
	PushIntoArray(toCheckReg, client);
	PushIntoArray(toUpdateSkill, client);	
			
	PrintHintText(client, "%t", "hint18");
	
	LogToFile(logfilepath, "ClientPostAdminCheckTimer end: %i: %s", client, GetName(client));
		
}

public OnClientPostAdminCheck(client)
{
	
	if (!IsFakeClient(client)) LogToFile(logfilepath, "OnClientPostAdminCheck start: %i: %s", client, GetName(client));
	RegDone[client] = 0;
	NameDelay[client] = false;
	AllowVote[client] = 1;
	ForceAfk[client] = 0;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

	//CreateTimer(0.5, TimerTakeOverBotAuto, client, TIMER_FLAG_NO_MAPCHANGE);
	
	if (!IsFakeClient(client)) CreateTimer(1.0, ClientPostAdminCheck, client);	
}

String:GetRealName(client)
{
	decl String:name[MAX_NAME_LENGTH] = "noname";
	if (IsNormalPlayer(client)) 
		GetClientName(client, name, MAX_NAME_LENGTH);
	
	return name;
}

public IsValidPlayer (client)
{
	if (client <= 0) return false;
	if (!IsClientConnected(client))	return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	
	return true;
}

String:GetName(client)
{
	decl String:name[MAX_NAME_LENGTH];
	Format(name,sizeof(name),"noname");
	if ((client <= 0) || (client > GetMaxClients()) || (!IsClientConnected(client))) return name;
	
	GetClientName(client, name, MAX_NAME_LENGTH);
	
	ReplaceString(name, sizeof(name), "<?php", "");
	ReplaceString(name, sizeof(name), "<?PHP", "");
	ReplaceString(name, sizeof(name), "?>", "");
	ReplaceString(name, sizeof(name), "\\", "");
	ReplaceString(name, sizeof(name), "'", "");
	ReplaceString(name, sizeof(name), ";", "");
	ReplaceString(name, sizeof(name), "ґ", "");
	ReplaceString(name, sizeof(name), "`", "");
	
	return name;
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

public Action:cmd_Enter(client, args)
{
	if (!IsValidPlayer(client)) return Plugin_Handled;
	
	if (IsRegName[client] > 0) {
		PrintToChat(client,"\x05%t", "enter1");
		return Plugin_Handled;
	}
	
	PrintToChat(client, "%t", "enter2");
	
	GetCmdArg(1, glogin, sizeof(glogin));
	GetCmdArg(2, gpass, sizeof(gpass));
	
	if (strlen(glogin) == 0) {
		PrintToChat(client,"%t sm_enter \"%t\" \"%t\"", "enter3", "login", "pass");
		return Plugin_Handled;
	}
	
	if (strlen(gpass) == 0) {
		PrintToChat(client,"%t sm_enter \"%t\" \"%t\"", "enter4", "login", "pass");
		return Plugin_Handled;
	}
	
	decl String:sChar;
	decl String:sArg[255];
	
	GetCmdArgString(sArg, sizeof(sArg));
	
	new i = 0;
	while (i<strlen(sArg)) {
		sChar = sArg[i];
		if (IsCharMB(sChar)) {
			PrintToChat(client, "%t", "enter5");
			return Plugin_Handled;
		}
		i+=GetCharBytes(sArg[i]);
	}
	
	SetClientInfo(client, "login", glogin);
	SetClientInfo(client, "pass", gpass);
	
	//checkreg(client);
	PushIntoArray(toCheckReg, client);
	PrintToChat(client, "%t(%s %s)", "enter6", glogin, gpass);
	
}

public Action:cmd_Reg(client, args)
{
	if (!IsValidPlayer(client)) return Plugin_Handled;
	
	if (IsRegName[client] > 0) {
		PrintToChat(client,"\x05%t", "enter7");
		PrintToConsole(client,"%t", "enter7");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, glogin, sizeof(glogin));
	GetCmdArg(2, gpass, sizeof(gpass));
	
	TrimString(glogin);
	TrimString(gpass);
	
	if (strlen(glogin) == 0) {
		PrintToChat(client,"%t sm_reg \"%t\" \"%t\"", "enter3", "login", "pass");
		PrintToConsole(client,"%t sm_reg \"%t\" \"%t\"", "enter3", "login", "pass");
		return Plugin_Handled;
	}
	
	if (strlen(gpass) == 0) {
		PrintToChat(client,"%t sm_reg \"%t\" \"%t\"", "enter4", "login", "pass");
		PrintToConsole(client,"%t sm_reg \"%t\" \"%t\"", "enter4", "login", "pass");
		return Plugin_Handled;
	}
	
	if ( (strlen(glogin) >= 255) || (strlen(gpass) >= 255) ) {
		PrintToChat(client,"%t", "enter8");
		PrintToConsole(client,"%t", "enter8");
		return Plugin_Handled;
	}

	
	decl String:sChar;
	decl String:sArg[255];
	
	GetCmdArgString(sArg, sizeof(sArg));
		
	new i = 0;
	while (i<strlen(sArg)) {
		sChar = sArg[i];
		if (IsCharMB(sChar)) {
			PrintToChat(client, "%t", "enter5");
			return Plugin_Handled;
		}
		i+=GetCharBytes(sArg[i]);
	}
		
	
	
	if ( (StrContains(glogin, ")", false) != -1) ||
	(StrContains(glogin, "(", false) != -1) ||
	(StrContains(glogin, "%", false) != -1) ||
	(StrContains(glogin, "#", false) != -1) ||
	(StrContains(glogin, "\\", false) != -1) ||
	(StrContains(glogin, "`", false) != -1) ||
	(StrContains(glogin, "'", false) != -1) ||
	(StrContains(glogin, ";", false) != -1) ||
	(StrContains(glogin, "?>", false) != -1) ||
	(StrContains(glogin, "<?", false) != -1) ||
	(StrContains(glogin, "ґ", false) != -1) ||
	
	(StrContains(gpass, ")", false) != -1) ||
	(StrContains(gpass, "(", false) != -1) ||
	(StrContains(gpass, "%", false) != -1) ||
	(StrContains(gpass, "#", false) != -1) ||
	(StrContains(gpass, "\\", false) != -1) ||
	(StrContains(gpass, "`", false) != -1) ||
	(StrContains(gpass, "'", false) != -1) ||
	(StrContains(gpass, ";", false) != -1) ||
	(StrContains(gpass, "?>", false) != -1) ||
	(StrContains(gpass, "<?", false) != -1) ||
	(StrContains(gpass, "ґ", false) != -1) 
	) {
		PrintToChat(client, "\x04[Reg] \x01%t", "enter9");
		return Plugin_Handled;
	}
	
	if (db == INVALID_HANDLE)
		return Plugin_Handled;
	
	if (IsRegProcess) {
		PrintToChat(client,"%t", "enter10")
		PrintToConsole(client,"%t", "enter10")
		return Plugin_Handled;
	}
	IsRegProcess = 1;
	CreateTimer(2.0, ResetRegProcess, INVALID_HANDLE);	
	
	new String:query[512];
	Format(query, sizeof(query), "SELECT * FROM reg_name WHERE login = '%s'", glogin);
	SQL_TQuery(db, RegisterQuery1, query, client);
	
	
}

public RegisterQuery1(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("RegisterQuery failed: %s", error);
		return;
	}
	if (!SQL_HasResultSet(hndl)) return;
	if (SQL_FetchRow(hndl))
	{
		PrintToChat(client,"\x05%t", "enter11");
		PrintToConsole(client,"%t", "enter11");
		return;
	}
	
	decl String:SteamID[255];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	new String:query[512];
	
	Format(query, sizeof(query), "SELECT * FROM reg_name WHERE steamid = '%s'", SteamID);
	SQL_TQuery(db, RegisterQuery2, query, client);
}
public RegisterQuery2(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("RegisterQuery failed: %s", error);
		return;
	}
	if (!SQL_HasResultSet(hndl)) return;
	
	new String:baselogin[255];
	new String:basesteamid[255];
	
	if (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 9, basesteamid, sizeof(basesteamid));
		SQL_FetchString(hndl, 14, baselogin, sizeof(baselogin));
	}
	
	new String:query[512];
	
	decl String:SteamID[255];
	if (!IsValidPlayer(client)) return;
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	//Format(query, sizeof(query), "DELETE FROM reg_name WHERE steamid = '%s'", SteamID);
	//SQL_TQuery(db, SQLErrorCheckCallback, query);
	
	if (StrEqual(basesteamid,SteamID)) {
		if (strlen(baselogin) > 0) {
			PrintToChat(client, "\x01%t(\x05%s\x01) %t", "enter12", SteamID, "enter13");
			PrintToConsole(client, "%t(%s) %t", "enter12", SteamID, "enter13");
			return;
		}
		Format(query, sizeof(query), "update reg_name SET name = '%s', pass = '%s', login = '%s' where steamid = '%s'", GetName(client), gpass, glogin, SteamID);
	}
	else {
		Format(query, sizeof(query), "INSERT IGNORE INTO reg_name SET steamid = '%s', name = '%s', pass = '%s', login = '%s'", SteamID, GetName(client), gpass, glogin);
	}
	
	//SQL_FastQuery(db, "SET NAMES utf8;")
	SQL_TQuery(db, RegHandle, query, client);
	
	PrintToChat(client,"\x03%t", "reg1");
	PrintToChat(client,"\x01%t \x05%s", "reg2", SteamID);
	PrintToChat(client,"\x01%t \x05%s", "reg3", glogin);
	PrintToChat(client,"\x01%t \x05%s", "reg4", gpass);
	PrintToChat(client,"\x04%t \x03setinfo login \"%s\"", "reg5", glogin);
	PrintToChat(client,"\x04%t \x03setinfo pass \"%s\"", "reg6", gpass);
	PrintToChat(client,"\x01%t \x05autoexec.cfg", "reg7");
	PrintToChat(client,"\x04%t", "reg8");
	PrintToChat(client,"\x04%t %t", "reg9", "siteurl");
	PrintToChat(client,"\x03%t", "reg10");
	
	PrintToConsole(client,"%t", "reg1");
	PrintToConsole(client,"%t %s", "reg2", SteamID);
	PrintToConsole(client,"%t %s", "reg3", glogin);
	PrintToConsole(client,"%t %s", "reg4", gpass);
	PrintToConsole(client,"%t setinfo login \"%s\"", "reg5", glogin);
	PrintToConsole(client,"%t setinfo pass \"%s\"", "reg6", gpass);
	PrintToConsole(client,"%t", "reg7");
	PrintToConsole(client,"%t", "reg8");
	PrintToConsole(client,"%t %t", "reg9", "siteurl");
	PrintToConsole(client,"%t", "reg10");
	
}

public RegHandle(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("regnamequery Query failed: %s", error);
		return;
	}
	
	SetClientInfo(client, "login", glogin);
	SetClientInfo(client, "pass", gpass);
	
	PushIntoArray(toCheckReg, client);
	//checkreg(client);
	
}

public Action:ResetRegProcess(Handle:timer, any:client)
{
	IsRegProcess = false;
}

public Action:RefreshAllTimer(Handle:timer, any:client)
{
	RefreshAll();
}

public RefreshAll()
{
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {	
			DoDataMove[i] = 0;
			DataMovePanelShowing[i] = 0;
			PushIntoArray(toCheckReg, i);
			PushIntoArray(toUpdateSkill, i);
			ShowInfo[i] = 1;
			
		}
	}
	LogToFile(logfilepath, "RefreshAll Done");
}

public Action:cmd_Say(client, args)
{
	decl String:Text[192];
	new String:Command[64];
	new Start = 0;
	
	GetCmdArgString(Text, sizeof(Text));
	if (strlen(Text) <= 0) return Plugin_Continue;
	
	if (Text[strlen(Text)-1] == '"')
	{
		Text[strlen(Text)-1] = '\0';
		Start = 1;
	}
	
	if (strcmp(Command, "say2", false) == 0)
		Start += 4;
	
	return HandleCommands(client, Text[Start]);
}

public Action:HandleCommands(client, const String:Text[]) 
{
	if ((StrContains(Text, "sm_reg", false) > -1) || (StrContains(Text, "sm_enter", false) > -1)) {
		PrintToChat(client, "\x01Команды \x04sm_reg, sm_enter \x01нужно вводить в \x03консоле.");
		return Plugin_Handled;
	}
	
	if (((strcmp(Text, "automovet", false) == 0) || (strcmp(Text, "!automovet", false) == 0)) && (CurrentGamemodeID == 1))
	{
		SpecPanelSwitch[client] = 1;
	}
	
	else if ((strcmp(Text, "online", false) == 0) || (strcmp(Text, "!online", false) == 0))
	{
		CreateTimer(0.1, ShowOnline, client);
		return Plugin_Handled;
	}
	else if (((strcmp(Text, "movet", false) == 0) || (strcmp(Text, "!movet", false) == 0) 
	|| (strcmp(Text, "!teams", false) == 0) || (strcmp(Text, "teams", false) == 0)) && (CurrentGamemodeID == 1))
	{
		DisplayMovetMenu(client);
		//return Plugin_Handled;
	}
	else if ((strcmp(Text, "join", false) == 0) || (strcmp(Text, "!join", false) == 0))
	{
		MovetPlayer(client); 
	}
	else if ((strcmp(Text, "autojoin", false) == 0) || (strcmp(Text, "!autojoin", false) == 0))
	{
		SpecPanelSwitch[client] = 1;
	}
	else if (((strcmp(Text, "!ji", false) == 0) || (strcmp(Text, "ji", false) == 0) || (strcmp(Text, "joininfected", false) == 0)) && (CurrentGamemodeID == 1))
	{
		cmd_movetoinfected(client);
	}
	else if (((strcmp(Text, "!js", false) == 0) || (strcmp(Text, "js", false) == 0) || (strcmp(Text, "joinsurvivor", false) == 0)) && (CurrentGamemodeID != 1))
	{
		cmd_movetosurvivors(client);
	}
	else if ( ((strcmp(Text, "!spectate", false) == 0) || (strcmp(Text, "spectate", false) == 0) || (strcmp(Text, "spec", false) == 0) || (strcmp(Text, "!spec", false) == 0)
	|| (strcmp(Text, "!afk", false) == 0) || (strcmp(Text, "joinspec", false) == 0)) )
	{
		ClientTeam[client] = 1;
		ClientWish[client] = 1;
		cmd_movetospecs(client);
	}
	else if ((strcmp(Text, "!admins", false) == 0) || (strcmp(Text, "admins", false) == 0))
	{
		cmd_showadmins();
	}
	
}

PlayersMenu(client, MenuHandler:PlayersMenuHandler, IsSS=0)
{
	decl String:Title[255];
	
	Format(Title, sizeof(Title), "Кого:");
	new Handle:menu = CreateMenu(PlayersMenuHandler);
	
	SetMenuTitle(menu, Title);
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);
	
	decl String:text[255];
	decl String:id[10];
	
	//if (PlayersMenuHandler == Menu_PlayersMenuHandler) {
	if (IsSS == 1) {
		for (new i = 1; i <= GetMaxClients(); i++) {
			if ((IsValidPlayer(i)) && (GetClientTeam(i) == 2))
			{
				Format(text,sizeof(text),"%s : %s", GetName(i), GetSkillText(ClientSkill[i]));
				Format(id,sizeof(id),"%i",i);
				AddMenuItem(menu, id, text);
			}
		}
		for (new i = 1; i <= GetMaxClients(); i++) {
			if ((IsValidPlayer(i)) && (GetClientTeam(i) == 3))
			{
				Format(text,sizeof(text),"%s : %s", GetName(i), GetSkillText(ClientSkill[i]));
				Format(id,sizeof(id),"%i",i);
				AddMenuItem(menu, id, text);
			}
		}
		for (new i = 1; i <= GetMaxClients(); i++) {
			if ((IsValidPlayer(i)) && (GetClientTeam(i) == 1))
			{
				Format(text,sizeof(text),"%s : %s", GetName(i), GetSkillText(ClientSkill[i]));
				Format(id,sizeof(id),"%i",i);
				AddMenuItem(menu, id, text);
			}
		}
	}
	else {
		
		for (new i = 1; i <= GetMaxClients(); i++) {
			if (IsValidPlayer(i) && (i != client)) 
			{
				Format(text,sizeof(text),"%s", GetName(i));
				Format(id,sizeof(id),"%i",i);
				AddMenuItem(menu, id, text);
			}
		}
		
	}
	DisplayMenu(menu, client, 60);
}

public VoteMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE) {
		return;
	}
	
	if (action == MenuAction_End) {
		CloseHandle(menu);
		return;
	}
	
	if (action != MenuAction_Select || param1 <= 0 || (!IsValidPlayer(param1))) {
		return;
	}
	
	decl String:Info[255];
	new bool:found = GetMenuItem(menu, param2, Info, sizeof(Info));
	
	if (!found) {
		return;
	}
	
	if (isvote) {
		PrintToChat(param1,"%t", "vote1");
		return;
	}
	
	VoteClient = StringToInt(Info);
	GetClientAuthString(VoteClient, VoteSteamID, sizeof(VoteSteamID));
	
	if (VipStatus[VoteClient] > 0) {
		if (VoteType == 1) {PrintToChatAll("\x05%s \x01%t \x03%s\x01, %t \x05VIP \x04%t.", GetName(param1), "vote2", GetName(VoteClient), "vote3", "vote4"); }
		else if (VoteType == 2) {PrintToChatAll("\x05%s \x01%t \x03%s\x01, %t \x05VIP \x04%t.", GetName(param1), "vote5", GetName(VoteClient), "vote6", "vote4"); }
		return;
	}
	
	if (!IsAdmin(VoteClient)) {
		//if (VoteType == 1) { KickClientWR(VoteClient,param1); }
		//else if (VoteType == 2) { BanClientWR(VoteClient,param1); }
	}
	else {
		if (VoteType == 1) {PrintToChatAll("\x05%s \x01%t \x03%s\x01, %t \x04%t", GetName(param1), "vote2", GetName(VoteClient), "vote7", "vote4"); }
		else if (VoteType == 2) {PrintToChatAll("\x05%s \x01%t \x03%s\x01, %t \x04%t.", GetName(param1), "vote5", GetName(VoteClient), "vote8", "vote4"); }
	}
	
}


public BanClientWR(ToKick, VoteStarted)
{
	if (isvotedelay) {
		PrintToChat(VoteStarted,"%t", "vote9");
		return Plugin_Handled;
	}
	
	if (isvote) {
		PrintToChat(VoteStarted, "%t", "vote1");
		return;
	}
	
	PrintToChatAll("\x01%s \x01%t \x03%s\x01",GetName(VoteStarted), "vote10", GetName(VoteClient));
	PrintToChatAll("\x01%t.", "vote11");
	PrintToChatAll("%t", "vote12");
	
	Format(VoteTitle, sizeof(VoteTitle), "%t %s?", "vote13", GetName(VoteClient));
	Format(VoteReason, sizeof(VoteReason), "voteban");	
	BanSrok = 30;
	
	CreateTimer(30.0, FinishVoteTimer, INVALID_HANDLE);
	CreateTimer(120.0, FinishVoteDelayTimer, INVALID_HANDLE);
	isvote = 1; isvotedelay = 1;
	yes = 1; no = 0;
	humanscount = (GetTeamHumanCount(2) + GetTeamHumanCount(3)) - 2;
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (i != VoteClient) && (i != VoteStarted) && (GetClientTeam(i) != 1)) {
			ShowVotePanel(i);
		}
	}
}


public VoteBalance(VoteStarted)
{
	if ((isvotedelay) && (IsValidPlayer(VoteStarted))) {
		PrintToChat(VoteStarted, "%t", "vote9");
		return Plugin_Handled;
	}
	
	if ((isvote) && (IsValidPlayer(VoteStarted))) {
		PrintToChat(VoteStarted, "%t", "vote1");
		return;
	}
	
	if  (IsValidPlayer(VoteStarted)) {
		PrintToChatAll("\x01%s \x01%t", GetName(VoteStarted), "vote14");
	}
	else PrintToChatAll("%t", "vote15");
	PrintToChatAll("\x01%t \x05За\x01.", "vote11");
	PrintToChatAll("%t", "vote12");
	
	Format(VoteTitle, sizeof(VoteTitle), "%t", "vote16");
	
	CreateTimer(30.0, FinishVoteTimer, INVALID_HANDLE);
	CreateTimer(120.0, FinishVoteDelayTimer, INVALID_HANDLE);
	
	isvote = 1; isvotedelay = 1;
	
	if  (IsValidPlayer(VoteStarted)) yes = 1; else yes = 0;
	no = 0;
	humanscount = (GetTeamHumanCount(2) + GetTeamHumanCount(3)) - yes;
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) &&  (i != VoteStarted) && (GetClientTeam(i) != 1)) {
			ShowVotePanel(i);
		}
	}
}

ShowVotePanel(any:client)
{
	new Handle:TeamPanel = CreatePanel();
	
	decl String:text[255];
	
	SetPanelTitle(TeamPanel, VoteTitle);
	
	Format(text, sizeof(text), "%t", "vote15");
	DrawPanelText(TeamPanel, text);
	
	Format(text, sizeof(text),"%t", "yes");
	DrawPanelItem(TeamPanel, text);
	
	Format(text, sizeof(text),"%t", "no");
	DrawPanelItem(TeamPanel, text);
	
	SendPanelToClient(TeamPanel, client, PanelVoteHandler, 60);
	CloseHandle(TeamPanel);
}	

public PanelVoteHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if ((!isvote) || (!IsValidPlayer(param1))) {
		
		return;
	}
	
	if ((param2 == 1) || (param2 == 2)) {
		
		if (param2 == 1) { yes++; }
		else if (param2 == 2) { no++; }
		
		PrintToChatAll("\x04%i\x01/\x04%i \x01%t: \x05%i %t\x01, \x03%i %t\x01.", yes+no, humanscount, "vote17", yes, "votefor", no, "voteagainst");
		if (yes+no >= humanscount) {
			FinishVote();
		}
	}	
	else CreateTimer(1.0, VotePanelTimer, param1);
	
	
}

public FinishVote()
{
	if (!isvote) {
		PrintToChatAll("%t", "vote18");
		return;
	}
	
	if (yes+no < 4) {
		PrintToChatAll("%t", "vote19");
		isvote = 0;
		return;
	}
	
	new float:percents = FloatMul(FloatDiv(yes, humanscount),100.0);
	new float:rate = 50.0;
	
	//if (VoteType == 1) { kickrate = 50.0; }
	//else if (VoteType == 2) { kickrate = 70.0; }
	//else if (VoteType == 3) { kickrate = 50.0; }
	//else if (VoteType == 4) { kickrate = 50.0; }
	
	if (yes > no) {
		//decl String:SteamID[255];
		//GetClientAuthString(VoteClient, SteamID, sizeof(SteamID));
		//if (!StrEqual(VoteSteamID, SteamID)) {
		//	PrintToChatAll("Отмена голосования.");
		//	return;
		//}
		
		//if (VoteType == 1) {
		//	PrintToChatAll("\x01[\x05%s\x01]Решение принято(\x03%2.1f percent \x01За): \x04выпинываем.",GetName(VoteClient),percents);
		//	ServerCommand("sm_kick #%i \"%s\"", GetClientUserId(VoteClient),VoteReason);
		//}
		//else if (VoteType == 2) {
		//	PrintToChatAll("\x01[\x05%s\x01]Решение принято(\x03%2.1f percent \x01За): \x04фбаню на %i минут.",GetName(VoteClient),percents,BanSrok);
		//	//BanClient(clienttokick,  BanSrok,  BANFLAG_AUTHID,  VoteReason, VoteReason);
		//	ServerCommand("sm_ban #%i %i \"%s\"", GetClientUserId(VoteClient), BanSrok, VoteReason);
		//}
		SetBalance(0,0);
		
	}
	else {
		PrintToChatAll("\x01%t(\x03%2.1f percent \x01За): \x04%t.", "vote20", percents, "vote21");
	}
	
	isvote = 0;
	yes = 0;
	no = 0;
}

public Action:FinishVoteTimer(Handle:timer, any:client)
{
	if (isvote) FinishVote();
}

public Action:FinishVoteDelayTimer(Handle:timer, any:client)
{
	isvotedelay = 0;
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

stock GetTeamHumanCount(team)
{
	new humans = 0;
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsValidPlayer(i) && GetClientTeam(i) == team)
		{
			humans++
		}
	}
	
	return humans;
}

stock GetTeamBotCount(team)
{
	new bots = 0;
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if ( IsNormalPlayer(i) && IsFakeClient(i) && (GetClientTeam(i) == team) )
		{
			bots++
		}
	}
	
	return bots;
}


stock GetTeamNormalCount(team)
{
	new humans = 0;
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsNormalPlayer(i) && GetClientTeam(i) == team)
		{
			humans++
		}
	}
	
	return humans;
}

public OnMapStart()
{
	if (MapStart > 0) return;
	
	if (TimerBC != INVALID_HANDLE) {
		KillTimer(TimerBC);
		TimerBC = INVALID_HANDLE;
	}
	TimerBC = CreateTimer(10.0, ResetBlockConnect, INVALID_HANDLE);
		
	new String: cmap[255];
	GetCurrentMap(cmap, sizeof(cmap));	
	LogToFile(logfilepath, "MapStart: %s", cmap);
	
	MapStart++;
	MapEnd = 0;
	RoundNum = 1;

	AllowWarning = true;
	
	SetConVarInt(FindConVar("precache_all_survivors"), 1);
	
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
	
	
	if (!IsPluginStarted)  {
		
		CheckSafeRoomDoor();
		if (ent_safedoor > 0) LockTheDoor();		
		
		MapLoaded = true;
		Freeze = true;
		//FreezeAll(3, true);
		DoorUnlocked = false;
		//if (TimerOnStart != INVALID_HANDLE) KillTimer(TimerOnStart);
		TimeToStartLeft = 80;
		StartMarker = 1;
		
		if (CurrentGamemodeID != 3)	CreateTimer(1.0, StartTimer, INVALID_HANDLE);
		StartPos[0] = 0; StartPos[1] = 0; StartPos[2] = 0;
		CreateTimer(1.0, GetFirstPosTimer, INVALID_HANDLE);
				
		//CreateTimer(1.0, GetEntitySafeRoomDoor);
		//CreateTimer(0.5, LockDoorTimer, entDoorStart);
		//directorStop();
						
		PrintToChatAll("%t", "start1");
		PrintToChatAll("%t", "start2");
		PrintToChatAll("%t", "start3");
		PrintToChatAll("%t", "start4");
		
		VoteMapTime = 10;
						
	} 
	else {
		IsPluginStarted = false;
	}
	
	LogToFile(logfilepath, "MapStart: 1");
	
	/*
	if (g_bLateLoad)
	{
		LogToFile(logfilepath, "MapStart: g_bLateLoad");
		
		for (new i = 1; i <= GetMaxClients(); i++) {
			if (IsNormalPlayer(i)) {
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		g_bLateLoad = false;
	}
	*/

	LogToFile(logfilepath, "MapStart: 3");
	
	isvote = 0;
	isvotedelay = 0;
	//SetNewComers(0);
		
	if (CurrentGamemodeID == 1) {
		
		LogToFile(logfilepath, "MapStart: 4");
		SetScoreTeams();
		
		PrintToChatAll("Включен режим восстановления команд, длительность 2-е минуты.");
		TimerCount = 120;
		CreateTimer(1.0, SetTeamsTimer, 0);
	
	}
	
	LogToFile(logfilepath, "MapStart: 5");
	
	SetAllAllowSkill();
	
	CreateTimer(5.0, FillAllowArrayTimer, 0);
	CreateTimer(5.0, FillBadNamesArrayTimer, 0);
	
	LogToFile(logfilepath, "MapStart: 6");
	
	//RoundStartInit();
	
	LogToFile(logfilepath, "MapStart: end");
}



public Action:VotePanelTimer(Handle:timer, any:client)
{
	ShowVotePanel(client);
}

public OnClientDisconnect(client)
{
	if ((client == VoteClient) && (isvote)) { 
		isvote = 0;
	}
	//NewComer[client] = 0;
	ClientSkill[client] = 0;
	VipStatus[client] = 0;
	
	if (IsClientInGame(client))
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	
}

public Action:cmd_myrank(client, args)
{
	if (IsValidPlayer(client)) PrintToChat(client, " caca %t: %i", "rank1", ClientRank[client]);
}

public Action:ReloadAllPlugins(Handle:timer, any:client)
{
	if (AllowRP == 1) ReloadPlugins(0,0);
}

public Action:ReloadPlugins(client, args) 
{
	decl String:query[255];
	Format(query, sizeof(query), "SELECT * from plugins_list where status=1");
	SQL_TQuery(db, ReloadPluginsHandle, query, 0);
}

public ReloadPluginsHandle(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("ReloadPlugins Query failed: %s", error);
		return;
	}
	
	new String:Plugin_Name[255];
	new Float:i = 1.0;
	new PluginID;
	if (!SQL_HasResultSet(hndl)) return;
	
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 2, Plugin_Name, sizeof(Plugin_Name));
		PluginID = SQL_FetchInt(hndl, 0);
		CreateTimer(i, ReloadPluginTimer, PluginID);
		i++;
	}
}

public Action:ReloadPluginTimer(Handle:timer, any:PluginID)
{
	decl String:query[255];
	Format(query, sizeof(query), "SELECT * from plugins_list where id=%i",PluginID);
	SQL_TQuery(db, ReloadPluginHandle, query, 0);
}

public ReloadPluginHandle(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("ReloadPlugin Query failed: %s", error);
		return;
	}
	
	new String:Plugin_Name[255];
	new Float:i = 1.0;
	new PluginID;
	
	if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 2, Plugin_Name, sizeof(Plugin_Name));
		PluginID = SQL_FetchInt(hndl, 0);
		//if (GetBizonID()>0) PrintToChat(GetBizonID(),"\x05%s \x01перегружен", Plugin_Name);
		ServerCommand("sm plugins reload %s", Plugin_Name);
		PrintToServer("%s перегружен", Plugin_Name);
	}
}

GetBizonID()
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (StrEqual(GetRealName(i),"Natan"))) return i;
	}
	
}

public Action:ShowOnline(Handle:timer, any:client)
{
	if (!IsValidPlayer(client)) return;
	showteamspanel(client);
}

public showteamspanel(any:client)
{
	if (!IsValidPlayer(client)) return;
	
	new Handle:TeamPanel = CreatePanel();
	//	SetPanelTitle(TeamPanel, "Online list:");
	
	decl String:text[255];
	decl String:IsNoob[255];
	decl String:IsAd[255];
	decl String:pStatus[255];
	decl String:pTeam[255];
	decl String:pName[255];
	decl String:pVictim[255];
	decl String:bN[255];
	new String: VipText[30] = "";
	new String:AId[2] = "";
	
	//	DrawPanelText(TeamPanel, " \n");
	//if (CurrentGamemodeID == 0) maxsurvivors = GetConVarInt(FindConVar("sv_visiblemaxplayers"));
	Format(text,sizeof(text),"Survivors(%i/%i):",GetTeamHumanCount(2), GetTeamMaxHumans(2));
	DrawPanelText(TeamPanel, text);
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (GetClientTeam(i) == 2)) {
			if (IsAdmin(i)) IsAd = "Admin"
			else IsAd = "";
			
			if(!IsPlayerAlive(i)) pStatus = "D"
			else if(IsPlayerIncapped(i)) pStatus = "INC"
			else Format(pStatus, sizeof(pStatus),"HP:%i", GetClientHealth(i));
			
			if (IsBadName(i)) { bN = "BN"; } else { bN = ""; }
			
			if ((IsFakeClient(i)) && (CurrentGamemodeID != 1)) pName = "BOT";
			else pName = GetName(i);
			ReplaceString(pName, sizeof(pName), "[", "|");
			ReplaceString(pName, sizeof(pName), "]", "|");
			decl String:text[255];
			
			if (VipStatus[i] > 0) Format(VipText, sizeof(VipText), "V:%i", VipStatus[i]);
			else Format(VipText, sizeof(VipText), "");
			
			if (IsAdminId(i)) Format(AId, sizeof(AId), "*");
			else Format(AId, sizeof(AId), "");			
			
			Format(text,sizeof(text),"%s (%s) S:%i %s %s %s %s", pName, pStatus, ClientSkill[i],  VipText, IsAd, bN, AId);
			DrawPanelText(TeamPanel, text);
		}
	}
	
	if (CurrentGamemodeID == 1) {
	DrawPanelText(TeamPanel, " \n");
	Format(text,sizeof(text),"Infected:(%i/%i):",GetTeamHumanCount(3),GetTeamMaxHumans(3));
	DrawPanelText(TeamPanel, text);
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (GetClientTeam(i) == 3)) {
			if (IsAdmin(i)) IsAd = "Admin"
			else IsAd = "";
			
			if(!IsPlayerAlive(i)) pStatus = "D"
			else if (IsPlayerSpawnGhost(i)) pStatus = "G"
			else if (GetClientTeam(client) != 2) Format(pStatus, sizeof(pStatus),"HP:%i", GetClientHealth(i));
			else Format(pStatus, sizeof(pStatus),"L");
			
			if (IsBadName(i)) { bN = "BN"; } else { bN = ""; }
			
			pName = GetName(i);
			ReplaceString(pName, sizeof(pName), "[", "|");
			ReplaceString(pName, sizeof(pName), "]", "|");
			decl String:text[255];
			if (VipStatus[i] > 0) Format(VipText, sizeof(VipText), "V:%i", VipStatus[i]);
			else Format(VipText, sizeof(VipText), "");
			if (IsAdminId(i)) Format(AId, sizeof(AId), "*");
			else Format(AId, sizeof(AId), "");			
			Format(text,sizeof(text),"%s (%s) S:%i %s %s %s %s", pName, pStatus, ClientSkill[i], VipText, IsAd, bN, AId);
			DrawPanelText(TeamPanel, text);
		}
	}
	
	}
	
	DrawPanelText(TeamPanel, " \n");
	DrawPanelText(TeamPanel, "Spectators:");
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (GetClientTeam(i) == 1)) {
			if (IsAdmin(i)) IsAd = "Admin"
			else IsAd = "";
			
			if (IsBadName(i)) { bN = "BN"; } else { bN = ""; }
			
			pName = GetName(i);
			ReplaceString(pName, sizeof(pName), "[", "|");
			ReplaceString(pName, sizeof(pName), "]", "|");
			if (VipStatus[i] > 0) Format(VipText, sizeof(VipText), "V:%i", VipStatus[i]);
			else Format(VipText, sizeof(VipText), "");
			if (IsAdminId(i)) Format(AId, sizeof(AId), "*");
			else Format(AId, sizeof(AId), "");			
			Format(text,sizeof(text),"%s S:%i %s %s %s %s", pName, ClientSkill[i], VipText, IsAd, bN, AId);
			DrawPanelText(TeamPanel, text);
		}
	}
	DrawPanelText(TeamPanel, " \n");
	DrawPanelText(TeamPanel, "1. Close");
	SendPanelToClient(TeamPanel, client, TeamPanelHandler, 60);
	CloseHandle(TeamPanel);
}

//public maxhumanschanged(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
//{
	//maxinfected = GetConVarInt(FindConVar("l4d_infected_limit"));
	//maxsurvivors = GetConVarInt(FindConVar("l4d_survivor_limit"));	
//}

public sballbotgamechanged(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
	if (StrEqual(strNewValue, "0")) SetConVarInt(FindConVar("sb_all_bot_game"), 1);
}


stock bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

bool:IsPlayerSpawnGhost(client)
{
	if(GetEntData(client, propinfoghost, 1)) return true;
	else return false;
}

public TeamPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		
	}
	
}

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, TankSpawn, GetEventInt(event, "userid"));
}

public Action:TankSpawn(Handle:timer, any:userid) 
{
	new client =  GetClientOfUserId(userid);
	
	// Tank instantly change owner, so skip this spawn
	if (client == 0)
		return;
	
	//SetTankHP(client);
}

public Action:SetTankHP(any:client) 
{
	if ( (!IsClientConnected(client)) || (!IsClientInGame(client)) ) return;
	
	new TankHP = 6000;
	decl String:CurMap[255];
	GetCurrentMap(CurMap, sizeof(CurMap)) ;
	if (StrEqual(CurMap,"c1m1_hotel")) { TankHP = 4000; }
	else { TankHP = 10000; }
	
	if(TankHP>65535) TankHP=65535;
	
	//PrintToChatAll("\x01Танк HP: \x05%i",TankHP);
	//SetEntityHealth(client, TankHP);
	
	if (NewTank == 1) { NewTank++; } else NewTank = 1;
}

public Action:StopRP(client, args)
{
	AllowRP = 0;
	//if (GetBizonID() > 0) PrintToChat(GetBizonID(),"Перегрузка плагинов отменена.");
	PrintToServer("Reload Plugins canceled.");
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (MapEnd > 0) return;
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "dmg_health");
	
	if ((target == 0) || (attacker == 0)) return;
	LastHurt[target] = attacker;
	
	decl i_UserID, i_Client, String:s_ModelName[64]
	
	i_UserID = GetEventInt(event, "userid")
	i_Client = GetClientOfUserId(i_UserID)
	
	GetEntPropString(i_Client, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName))
	
	// Если урон получил танк
	if (StrContains(s_ModelName, "hulk") != -1)
	{
		//new bid = GetBizonID();
		decl String:s_Weapon[16], i_Type
		
		i_Type = GetEventInt(event, "type")
		GetEventString(event, "weapon", s_Weapon, sizeof(s_Weapon))
		
		// Способ №1
		// Если урон получен от огня
		// s_Weapon = entityflame - танк горит от молотова, канистры, фейерверка, зажигательных патронов
		// s_Weapon = inferno - танк находится в месте, где горит огонь от молотова, канистры, фейерверка
		// s_Weapon = "" (!s_Weapon[0]) - танк загорелся от огня, находящегося на карте (бочки, костеры и т.д)
		if (StrEqual(s_Weapon, "entityflame") || StrEqual(s_Weapon, "inferno") || !s_Weapon[0])
		{
			// Действие
		}
		
		// Способ №2
		// Если урон получен от огня
		// i_Type = 8 || 2056 - танк находится в месте, где горит огонь от молотова, канистры, фейерверка или огонь, находящийся на карте (бочки, костеры и т.д)
		// i_Type = 268435464 - танк горит от молотова, канистры, фейерверка, зажигательных патронов или от огня, находящегося на карте (бочки, костеры и т.д)
		if (i_Type == 8 || i_Type == 2056 || i_Type == 268435464)
		{
			//new health = GetClientHealth(target);
			//new plusdamage = 0;
			//if (health-plusdamage < 0) SetEntityHealth(target, 0);
			//else SetEntityHealth(target, health-plusdamage);
			//new health2 = GetClientHealth(target);   
			//if (bid > 0) PrintHintText(bid,"Танк %s: -%i HP, нанес огонь %s, HP: %i",GetRealName(target), damage+plusdamage,  s_Weapon, health2);
		}
		else {
			//new health2 = GetClientHealth(target);   
			//if (bid > 0) PrintHintText(GetBizonID(),"Танк %s: -%i HP, нанес %s, HP: %i",GetRealName(target), damage, GetRealName(attacker), health2);
		}
	}
	
	if ((IsValidPlayer(attacker)) && (IsNormalPlayer(target)) && (GetClientTeam(attacker) == 3) && (GetClientTeam(target) == 2)) {
		Dmg[attacker] += damage;
		if (SessionDmg[attacker] == 0) {
			LastDmg[attacker] = Dmg[attacker];
			CreateTimer(5.0, CheckShowDamageTimer, attacker);
		}
		SessionDmg[attacker] += damage;
	}
	
}

public Action:CheckShowDamageTimer(Handle:timer, any:client)
{
	if ((!IsValidPlayer(client)) || (SessionDmg[client] == 0)) return;
	if (LastDmg[client] == Dmg[client]) {
		
		for (new i = 1; i <= GetMaxClients(); i++) {
			if ((IsValidPlayer(i)) && (ShowInfo[i] == 1)) {
				//Natan ha matado a Charger Charger, Frags: 1, Lugar: 1
				PrintToChat(i, "\x03[%t: %i] \x04%s \x01%t \x05%t\x01: \x03%i(%t: \x03%i\x01), ", "damage4", GetDmgPos(client), GetRealName(client), "damage1", "damage2", SessionDmg[client], "damage3", Dmg[client]);
			}
		}
		
		SessionDmg[client] = 0;
		UpdateFragsLine();
	} else {
		LastDmg[client] = Dmg[client];
		CreateTimer(5.0, CheckShowDamageTimer, client);
	}
}

public DisplayMovetMenu(client)
{
	decl String:Title[255], String:text[255];
	
	Format(Title, sizeof(Title), "%t", "ChoseTeam");
	
	new Handle:menu = CreateMenu(Menu_CreateMovetMenuHandler);
	
	SetMenuTitle(menu, Title);
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);
	
	Format(text, sizeof(text), "%t", "GoToInfected");
	AddMenuItem(menu, "1", text);
	Format(text, sizeof(text), "%t", "GoToSurvivors");
	AddMenuItem(menu, "2", text);
	Format(text, sizeof(text), "%t", "GoToSpectators");
	AddMenuItem(menu, "3", text);
	
	DisplayMenu(menu, client, 30);
}

public Menu_CreateMovetMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (menu == INVALID_HANDLE)
		return;
	
	if (action == MenuAction_End) {
		CloseHandle(menu);
		return;
	}
	
	if (action != MenuAction_Select || param1 <= 0 || (!IsValidPlayer(param1))) {
		
		return;
	}
	
	decl String:Info[255];
	new bool:found = GetMenuItem(menu, param2, Info, sizeof(Info));
	
	if (!found)
		return;
	
	if (strcmp(Info, "1", false) == 0)
	{
		if (CurrentGamemodeID == 1) cmd_movetoinfected(param1);
		return;
	}
	else if (strcmp(Info, "2", false) == 0)
	{
		cmd_movetosurvivors(param1);
		return;
	}
	else if (strcmp(Info, "3", false) == 0)
	{
		cmd_movetospecs(param1);
		return;
	}
}


public cmd_movetoinfected(any:client)
{
	if ( (!IsValidPlayer(client)) || (RoundEnd > 0) ) return;
	
	if (GetClientTeam(client) == 3) {
		PrintToChat(client,"%t", "info1");
		return;
	}
	
	if (CurrentGamemodeID != 1) return;
	
	//maxinfected = GetConVarInt(FindConVar("l4d_infected_limit"));
	//maxsurvivors = GetConVarInt(FindConVar("l4d_survivor_limit"));	
	
	new sc, ic;
	sc = GetTeamHumanCount(2);
	ic = GetTeamHumanCount(3);
	
	if (ic >= GetTeamMaxHumans(3)) {
		PrintToChat(client, "\x05%t", "info2");
		return;
	}
	if ( ((ic-sc) > 0) && (!IsAdmin(client)) ) {
		PrintToChat(client, "\x05%t", "info3");
		return;
	}
	if ((!AllowJoin[client]) && !IsAdmin(client)) {
		PrintToChat(client,"\x05%t", "info4");
		return;
	}
	AllowJoin[client] = 0;
	CreateTimer(60.0, SetAllowJoin, client);
	
	if (!ChangePlayerTeam(client,3)) PrintToChat(client,"\x05[sync] \x01%t", "info5");
	
	
	
	//PrintToChat(client,"Мест нет.");
	
}

public cmd_movetosurvivors(any:client)
{
	if ( (!IsValidPlayer(client)) || (RoundEnd > 0) ) return;
	
	if (GetClientTeam(client) == 2) {
		PrintToChat(client,"%t", "info6");
		return;
	}
	
	//maxinfected = GetConVarInt(FindConVar("l4d_infected_limit"));
	//maxsurvivors = GetConVarInt(FindConVar("l4d_survivor_limit"));	
	
	if ((!AllowJoin[client]) && !IsAdmin(client)) {
		PrintToChat(client,"\x05%t", "info4");
		return;
	}
	
	AllowJoin[client] = 0;
	CreateTimer(60.0, SetAllowJoin, client);
		
	if (CurrentGamemodeID != 1) {
		if (!ChangePlayerTeam(client,2)) 
			PrintToChat(client,"\x05[sync] \x01%t", "info5");
		return;
	}
	
	new sc, ic;
	sc = GetTeamHumanCount(2);
	ic = GetTeamHumanCount(3);
	
	if (sc >= GetTeamMaxHumans(2)) {
		PrintToChat(client, "\x05%t", "info2");
		return;
	}
	if ( ((sc-ic) > 0) && (!IsAdmin(client)) ) {
		PrintToChat(client, "\x05%t", "info3");
		return;
	}
			
	if (!ChangePlayerTeam(client,2)) PrintToChat(client,"\x05[sync] \x01%t", "info5");
	
}

public cmd_movetospecs(any:client)
{
	if (RoundEnd > 0) return;
	if (!IsValidPlayer(client))  return;
	
	if (GetClientTeam(client) == 1) {
		PrintToChat(client, "%t", "info7");
		return;
	}
	
	ForceAfk[client] = 1;
	
	ChangePlayerTeam(client,1);
	
	AllowJoin[client] = 0;
	CreateTimer(10.0, SetAllowJoin, client);
}

public SetAllAllowJoin(any:v)
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			AllowJoin[i] = v;
			AllowMsg[i] = 1;
		}
	}
}

public Action:SetAllowJoin(Handle:timer, any:client)
{
	AllowJoin[client] = 1;
}

stock bool:ChangePlayerTeam(client, team)
{
	if (!IsValidPlayer(client)) return false;
	if (RoundEnd > 0) return false;
	if (GetClientTeam(client) == team) return true;
		
	if ((GetTeamHumanCount(team) >= GetTeamMaxHumans(team)) && (GetClientTeam(client) > 1)) return false;
	
	if(team != 2)
	{
		//we can always swap to infected or spectator, it has no actual limit
		ChangeClientTeam(client, team);
		return true;
	}
	
	//for survivors its more tricky
	for (new bot = 1; bot <= GetMaxClients(); bot++) {
		if ( (IsNormalPlayer(bot)) && (IsFakeClient(bot)) && (GetClientTeam(bot) == 2) ) {

			decl String:sname[255];
			sname = GetName(bot);
			if ( (StrContains(sname, "bebop_bot_fakeclient", false) == -1) && (StrContains(sname, "survivorbot", false) == -1) ) {		
			
				//if (CurrentGamemodeID == 0) LogToFile(logfilepath, "ChangePlayerTeam - clientname: %s botname: %s", GetName(client), sname);
				SDKCall(fSHS, bot, client);
				SDKCall(fTOB, client, true);
		
				//if (GetClientTeam(client) == 2) { 
				//	if (CurrentGamemodeID == 0) LogToFile(logfilepath, "ChangePlayerTeam - clientname: %s botname: %s done success", GetName(client), sname);
				return true;		
				//} else if (CurrentGamemodeID == 0) LogToFile(logfilepath, "ChangePlayerTeam - clientname: %s botname: %s done failed", GetName(client), sname);
			}
		}
	}
	return false;

}

stock GetTeamMaxHumans(team)
{
	
	if(team == 2)
	{
		if (CurrentGamemodeID != 1) return 20;
		else {
			new Handle: slh = FindConVar("l4d_survivor_limit");
			if (slh == INVALID_HANDLE) return 10;
			else {
				return GetConVarInt(slh);
			}
		}
	}
	else if(team == 3)
	{
		if (CurrentGamemodeID != 1) return 0;
		else {
			new Handle: ilh = FindConVar("l4d_infected_limit");
			if (ilh == INVALID_HANDLE) return 10;
			else {
				return GetConVarInt(ilh);
			}
			
		}
	}
	else if(team == 1)
	{
		return 4;
	}
	
	return -1;
}

public OnPluginEnd()
{
	if (fSHS != INVALID_HANDLE) CloseHandle(fSHS);
	if (fTOB != INVALID_HANDLE) CloseHandle(fTOB);
	if (db != INVALID_HANDLE) CloseHandle(db);
	if (db2 != INVALID_HANDLE) CloseHandle(db2);
	if (gConf != INVALID_HANDLE) CloseHandle(gConf);
	
	if (toCheckReg != INVALID_HANDLE) CloseHandle(toCheckReg);
	if (toUpdateSkill != INVALID_HANDLE) CloseHandle(toUpdateSkill);

	UnHookDamage();
	
}

PrepareAllSDKCalls()
{
	gConf = LoadGameConfigFile("left4downtown.l4d2");
	if(gConf == INVALID_HANDLE)
	{
		ThrowError("Could not load gamedata/left4downtown.l4d2.txt");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	fSHS = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	fTOB = EndPrepSDKCall();
	
	
	// SetCampaignScores
	StartPrepSDKCall(SDKCall_GameRules);
	if(PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetCampaignScores"))
	{
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		fSetCampaignScores = EndPrepSDKCall();
		if(fSetCampaignScores == INVALID_HANDLE)
		{
			PrintToServer("[TEST] Function 'SetCampaignScores' found, but something went wrong.");
		}
		else
		{
			PrintToServer("[TEST] Function 'SetCampaignScores' initialized.");
		}
	}
	else
	{
		PrintToServer("[TEST] Function 'SetCampaignScores' not found.");
	}
	
	// GetTeamScores
	StartPrepSDKCall(SDKCall_GameRules);
	if(PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "GetTeamScore"))
	{
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		fGetTeamScore = EndPrepSDKCall();
		
		if(fGetTeamScore == INVALID_HANDLE) {
			PrintToServer("[TEST] Function 'GetTeamScore' found, but something went wrong.");
		}
		else
		{
			PrintToServer("[TEST] Function 'GetTeamScore' initialized.");
		}
	}
	else
	{
		PrintToServer("[TEST] Function 'GetTeamScore' not found.");
	}
	
}

public MovetPlayer(any:client)
{
	if ( (!IsValidPlayer(client)) || (RoundEnd > 0) ) return;
	
	if (GetClientTeam(client) > 1) {
		PrintToChat(client,"\x03[\x04%е\x03] \x01%t", "server", "info8");
		return;
	}
	
	if ((!AllowJoin[client]) && !IsAdmin(client)) {
		PrintToChat(client,"\x05%t", "info9");
		return;
	}
	AllowJoin[client] = 0;
	CreateTimer(10.0, SetAllowJoin, client);
	
	PrintToChat(client,"\x03[\x04%t\x03] \x01%t \x05%s \x01...", "server", "info10", GetRealName(client));
	
	new sc = GetTeamHumanCount(2);
	new ic = GetTeamHumanCount(3);
	new spc = GetTeamHumanCount(1);
	
	if (CurrentGamemodeID != 1) {
		
		//if (sc < GetTeamMaxHumans(2))
		if (GetTeamBotCount(2) > 0) { ChangePlayerTeam(client,2); }
		else if (VipStatus[client] > 0) MovetVIP(client);
		else PrintToChat(client,"%t", "info11");
		
		return;
	}
	
	
	if ((sc < GetTeamMaxHumans(2)) && (sc <= ic)) { ChangePlayerTeam(client,2); }
	else if ((ic < GetTeamMaxHumans(3)) && (ic <= sc)) { ChangePlayerTeam(client,3); }
	else if (GetTeamHumanCount(2) < GetTeamMaxHumans(2)) { ChangePlayerTeam(client,2); }
	else if (GetTeamHumanCount(3) < GetTeamMaxHumans(3)) { ChangePlayerTeam(client,3); }
	else if (VipStatus[client] > 0) MovetVIP(client);
	else PrintToChat(client,"%t", "info11");
	
	if (GetClientTeam(client) == 1) SpecPanelSwitch[client] = 1;
	
}

public Action:event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (MapEnd > 0) return;
	if (RoundEnd > 0) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new NewTeam = GetEventInt(event, "team");
	new OldTeam = GetEventInt(event, "oldteam");
	new bool:IsDisconnect = GetEventBool(event, "disconnect");
	
	PlayerChangedTeam[client] = 1;
	
	if (NewTeam == 1) SpecPanelSwitch[client] = 1;
	else if (OldTeam > 1) ClientWish[client] = 0;
	
	//if ((OldTeam != 0) && (NewTeam != 0)) {
	//	ClientTeam[client] = 0;
	//}
	
	if (VipStatus[client] > 0) {
		//if (GetClientTeam(client) == 2) ServerCommand("sm_lightclient #%i 0 255 20", GetClientUserId(client));
	}
}



public Action:Timer_SpecPanel(Handle:timer)
{
	
	if (RoundEnd > 0) return;
	
	new Float:sc, ic, ispc;
	new isc, iic, spc;
	new ClientToKick = 0;
	
	ispc = GetTeamHumanCount(1);
	isc = GetTeamHumanCount(2);
	if (CurrentGamemodeID != 1) iic = 0; else iic = GetTeamHumanCount(3);
	
	decl String:login[255];
	
	//UpdateFragsLine();
	new bool: stop = false;
	if ( (((isc+iic) >= (GetTeamMaxHumans(2)+GetTeamMaxHumans(3))) && (CurrentGamemodeID == 1)) ||
	 ((isc >= GetTeamMaxHumans(2)) && (CurrentGamemodeID != 1)) ) {
		for (new i = 1; ((i <= GetMaxClients()) && (!stop)); i++) {
			if (IsValidPlayer(i) && IsBadName(i) && (GetClientTeam(i) > 1)) {
				KickClient(i, "Ban name, this slot is for normal players");
				stop = true;
			}
		}
	}
	
	new max_limit = vmpg;
	//if (CurrentGamemodeID == 0) max_limit = 20; else max_limit = 20;
	
	
	if (ispc+isc+iic >= max_limit) {
		for (new i = 1; ((i <= GetMaxClients()) && (ClientToKick == 0)); i++) 
			if ((IsValidPlayer(i)) && (GetClientTeam(i) == 1) && (!IsAdmin(i)) && (VipStatus[i] <= 0)) ClientToKick = i;
		
		if (ClientToKick == 0) { //если не находим ищем из випов статус 1
			for (new i = 1; ((i <= GetMaxClients()) && (ClientToKick == 0)); i++) 
				if ((IsValidPlayer(i)) && (GetClientTeam(i) == 1) && (!IsAdmin(i)) && (VipStatus[i] < 2)) ClientToKick = i;
		}
		if (ClientToKick == 0) { //если не находим ищем из випов статус 2
			for (new i = 1; ((i <= GetMaxClients()) && (ClientToKick == 0)); i++) 
				if ((IsValidPlayer(i)) && (GetClientTeam(i) == 1) && (!IsAdmin(i)) && (VipStatus[i] < 3)) ClientToKick = i;
		}
		if (ClientToKick == 0) { //если не находим ищем из випов всех
			for (new i = 1; ((i <= GetMaxClients()) && (ClientToKick == 0)); i++) 
				if ((IsValidPlayer(i)) && (GetClientTeam(i) == 1) && (!IsAdmin(i))) ClientToKick = i;
		}
		
		if (IsValidPlayer(ClientToKick)) KickClient(ClientToKick, "This is reserved slot");
		else {
			ClientToKick = 0;
			for (new i = 1; ((i <= GetMaxClients()) && (ClientToKick == 0)); i++) {
				if (IsValidPlayer(i)) {
					GetClientInfo(i,"login",login,sizeof(login));
					if ((GetClientTeam(i) == 1) && (!StrEqual("Woonan", login))) ClientToKick = i;
				}
			}
			if (IsValidPlayer(ClientToKick)) KickClient(ClientToKick, "This is reserved slot");
		}
	}
	
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			if (IsBadName(i)) {
				PrintHintText(i, "%t", "start5");				
			}
			//if ((SpecPanelSwitch[i] == 1) || (NewComer[i] == 1)) AutoTeam(i)
			
			if (SpecPanelSwitch[i] == 1) AutoTeam(i);// else AutoTeamHud(i);
			
			if ( (ClientWish[i] > 0) && (GetClientTeam(i) != ClientWish[i]) ) AutoMove(i);
			else ClientWish[i] = 0;
		}
	}
	
	
	//AllowBalance = false;
	if (CurrentGamemodeID != 1) return;
	
	if ((AllowBalance) && ((isc+iic) >= 4)) {
		
		spc = float(ispc);
		sc = float(isc);
		ic = float(iic);
		
		if (FloatAbs(FloatSub(sc,ic)) > 2.0) {
			InBalance += 1;
		}
		else InBalance = 0;
		
		if (InBalance == 10) {
			PrintToChatAll("\x05%t \x03(%t: %i, %t: %i) \x01через минуту.", "Autobalance", "Survivors", isc, "Infected", iic);	
			PrintToChatAll("\x01%t: \x05js\x01(%t), \x05ji\x01(%t).", "ChangeTeamInChat", "Survivors", "Infected");	
		} 
		if (InBalance == 25) {
			PrintToChatAll("\x05%t \x03(%t: %i, %t: %i) \x01 %t.", "Autobalance", "Survivors", isc, "Infected", iic, "In30s");
			PrintToChatAll("\x01%t: \x05js\x01(%t), \x05ji\x01(%t).", "ChangeTeamInChat", "Survivors", "Infected");	
		}
		if (InBalance == 45) {
			PrintToChatAll("\x05%t \x03(%t: %i, %t: %i) \x01%t.", "Autobalance", "Survivors", isc, "Infected", iic, "In10s");
			PrintToChatAll("\x01%t: \x05js\x01(%t), \x05ji\x01(%t).", "ChangeTeamInChat", "Survivors", "Infected");	
		}
		if (InBalance >= 50) {
			TeamBalance();
			InBalance = 0;
		}
	}
}

public AutoTeamHud(any:i)
{
	if (IsValidPlayer(i) && (GetClientTeam(i) == 1) && (!IsAdmin(i))) {
		SetGlobalTransTarget(i);
		PrintHintText(i,"%t", "AutomovetHint");
	}
}

public AutoMove(any:i)
{
	if (RoundEnd > 0) return;
	if (IsValidPlayer(i) && (GetClientTeam(i) == 1) && (ClientWish[i] > 1)) {
		
		LogToFile(logfilepath, "AutoMove start: %i: %s ClientWish: %i", i, GetName(i), ClientWish[i]);
		
		new TeamSurvCount = GetTeamHumanCount(2);
		new TeamInfCount = GetTeamHumanCount(3);
		new TeamSpecCount = GetTeamHumanCount(1);
		decl String:sel[50];
		
		if (CurrentGamemodeID != 1) {
			if ((ClientWish[i] == 2) && (TeamSurvCount < GetTeamMaxHumans(2))) {
				if (ChangePlayerTeam(i,2)) { 
					ClientWish[i] = 0; 
					FinishAutoMove(i);
				}
			}
			LogToFile(logfilepath, "AutoMove 1: %i: %s ClientWish: %i", i, GetName(i), ClientWish[i]);
			return;
		}
		
		LogToFile(logfilepath, "AutoMove 2: %i: %s ClientWish: %i", i, GetName(i), ClientWish[i]);
		
		if ((ClientWish[i] == 2) && (TeamSurvCount < GetTeamMaxHumans(2)) && (TeamSurvCount <= TeamInfCount)) { 
			ChangePlayerTeam(i,2); 
			ClientWish[i] = 0; 
			FinishAutoMove(i);
		}
		else if ((ClientWish[i] == 3) && (TeamInfCount < GetTeamMaxHumans(3)) && (TeamInfCount <= TeamSurvCount)) { 
			ChangePlayerTeam(i,3);
			ClientWish[i] = 0; 
			FinishAutoMove(i);
		}
		else if ((ClientWish[i] == 4) && (TeamSurvCount+TeamInfCount < GetTeamMaxHumans(2)+GetTeamMaxHumans(3))) {
			if ((TeamSurvCount < GetTeamMaxHumans(2)) && (TeamInfCount >= TeamSurvCount)) { 
				ChangePlayerTeam(i,2); 
			}
			else if ((TeamInfCount < GetTeamMaxHumans(3)) && (TeamSurvCount >= TeamInfCount)) { 
				ChangePlayerTeam(i,3); 
			}
			if (GetClientTeam(i) != 1) {
				ClientWish[i] = 0; 
				FinishAutoMove(i);
			}
		}
	}
	LogToFile(logfilepath, "AutoMove end: %i: %s ClientWish: %i", i, GetName(i), ClientWish[i]);
	
}

public FinishAutoMove(any:i)
{
	if ( (GetClientTeam(i) < 2) || (RoundEnd > 0) ) return;
	
	SetGlobalTransTarget(i);
	new Handle:FinishTeamPanel = CreatePanel();
	decl String:text[255];
	Format(text, sizeof(text), "%t", "InGame");
	DrawPanelText(FinishTeamPanel, text);
	SendPanelToClient(FinishTeamPanel, i, FinishTeamPanelHandler, 5);
	CloseHandle(FinishTeamPanel);
}

public AutoTeam(any:i)
{
	if ( (!IsValidPlayer(i)) || (RoundEnd > 0) ) return;
	
	new Handle:AutoTeamPanel = CreatePanel();
	
	decl String:text[255];
	
	//if (NewComer[i] == 1) {
	//			
	//if (GetClientTeam(i) != 1) ChangePlayerTeam(i,1);
	//	  
	//Format(text,sizeof(text),"Добро пожаловать на сервер synczone.ru");
	//DrawPanelText(AutoTeamPanel, text);
	//
	//Format(text,sizeof(text),"Чтобы войти в игру закройте эту панель или выберите команду.");
	//DrawPanelText(AutoTeamPanel, text);
	//		
	//Format(text,sizeof(text),"Основные возможности на сервере:");
	//DrawPanelText(AutoTeamPanel, text);
	//		
	//Format(text,sizeof(text),"Перки (модифицированные)");
	//DrawPanelText(AutoTeamPanel, text);
	//		
	//		Format(text,sizeof(text),"SyncPoints (система покупки за поинты)");
	//		DrawPanelText(AutoTeamPanel, text);
	//
	//Format(text,sizeof(text),"Сервер приближен к классическому геймплею, но с массой изменений.");
	//DrawPanelText(AutoTeamPanel, text);
	//		
	//		Format(text,sizeof(text),"");
	//DrawPanelText(AutoTeamPanel, text);
	//
	//DrawPanelText(AutoTeamPanel,"");
	//
	//Format(text,sizeof(text),"Закрыть / close");
	//DrawPanelItem(AutoTeamPanel, text);
	//
	//		SendPanelToClient(AutoTeamPanel, i, AutoTeamPanelHandler2, 666666);
	//	}
	//	else if ((GetClientTeam(i) == 1) && (NewComer[i] == 0)) {
	
	if (DataMovePanelShowing[i] == 1) return;
	
	if (GetClientTeam(i) == 1) {
		SetGlobalTransTarget(i);
		//if (GetTeamHumanCount(2) < maxsurvivors) { ChangePlayerTeam(i,2); }
		//else if (GetTeamHumanCount(3) < maxinfected) { ChangePlayerTeam(i,3); }
		//else if (IsAdmin(i)) { cmd_movetoinfected(i); }
		//else KickClient(i,"Мест нет.");
		
		if (CurrentGamemodeID != 1) 
			Format(text,sizeof(text),"%t: %i/%i %t: %i", "Survivors", GetTeamHumanCount(2),GetTeamMaxHumans(2), "Spectators", GetTeamHumanCount(1));
		else
			Format(text,sizeof(text),"%t: %i/%i %t: %i/%i %t: %i", "Survivors", GetTeamHumanCount(2),GetTeamMaxHumans(2), "Infected", GetTeamHumanCount(3),GetTeamMaxHumans(3), "Spectators", GetTeamHumanCount(1));
		DrawPanelText(AutoTeamPanel, text);
		
		if ( ((GetTeamHumanCount(2)+GetTeamHumanCount(3) >= GetTeamMaxHumans(2)+GetTeamMaxHumans(3)) && (CurrentGamemodeID == 1)) || 
		((GetTeamHumanCount(2) >= GetTeamMaxHumans(2)) && (CurrentGamemodeID != 1)) )
			Format(text,sizeof(text), "%t", "NoFreeSlots")
		else
			Format(text,sizeof(text), "%t", "FreeSlots")
		DrawPanelText(AutoTeamPanel, text);
		
		Format(text,sizeof(text),"%t", "EnterAuto3");
		DrawPanelText(AutoTeamPanel, text);
		Format(text,sizeof(text),"%t", "EnterAuto2");
		DrawPanelText(AutoTeamPanel, text);
		Format(text,sizeof(text),"%t", "EnterAuto");
		DrawPanelText(AutoTeamPanel, text);
		
		decl String:sel[50];
		
		if (ClientWish[i] == 1) Format(text,sizeof(text),"[%t]", "Spectators")
		else Format(text,sizeof(text),"%t", "Spectators");
		DrawPanelItem(AutoTeamPanel, text);
		
		if (ClientWish[i] == 2) Format(text,sizeof(text),"[%t]", "Survivors")
		else Format(text,sizeof(text),"%t", "Survivors");
		DrawPanelItem(AutoTeamPanel, text);
		
		if (CurrentGamemodeID == 1) {
			if (ClientWish[i] == 3) Format(text,sizeof(text),"[%t]", "Infected")
			else Format(text,sizeof(text),"%t", "Infected");
			DrawPanelItem(AutoTeamPanel, text);
		
			if (ClientWish[i] == 4) Format(text,sizeof(text),"[%t]", "Automatic")
			else Format(text,sizeof(text),"%t", "Automatic");
			DrawPanelItem(AutoTeamPanel, text);
		}
		
		DrawPanelText(AutoTeamPanel,"");
		
		Format(text,sizeof(text),"%t", "Close");
		DrawPanelItem(AutoTeamPanel, text);
		
		SendPanelToClient(AutoTeamPanel, i, AutoTeamPanelHandler, 60);
		
	}
	
	CloseHandle(AutoTeamPanel);
}


public FinishTeamPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	
}

public AutoTeamPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	
	if ( ((CurrentGamemodeID != 1) && (param2 == 3)) || ((CurrentGamemodeID == 1) && (param2 == 5)) ) {
		SpecPanelSwitch[param1] = 0;
		return;
	}
	
	if (param2 == 1) { ClientWish[param1] = 1; }
	else if (param2 == 2) { ClientWish[param1] = 2; }
	else if (param2 == 3) { ClientWish[param1] = 3; }
	else if (param2 == 4) { ClientWish[param1] = 4; }
		
	AutoTeam(param1);
	
	
}

public AutoTeamPanelHandler2(Handle:menu, MenuAction:action, param1, param2)
{
	if (param2 == 1) 
		if (IsValidPlayer(param1)) {
		NewComer[param1] = 0; 
		ClientWish[param1] = 4
	}
	
	
}

public Action:cmd_teambalance(client, args)
{
	if (CurrentGamemodeID != 1) {
		PrintToChat(client, "disabled, gamemode is coop");
		return;
	}
	TeamBalance();
}

public TeamBalance()
{
	new bool:StopIT = false;
	new ClientToMove;
	new Float:sc, ic;
	
	sc = float(GetTeamHumanCount(2));
	ic = float(GetTeamHumanCount(3));
	new isc, iic;
	isc = GetTeamHumanCount(2);
	iic = GetTeamHumanCount(3);
	
	PrintToChatAll("\x05%t \x03(%t: %i, %t: %i) \x01%t.", "Autobalance", "Survivors", isc, "Infected", iic, "Balancing");
	
	while ((FloatAbs(FloatSub(sc,ic)) > 1.0) && (!StopIT)) {
		if (FloatCompare(sc,ic) == 1) {
			ClientToMove = GetFirstClientID(2);
			if (ClientToMove > 0) {
				ChangePlayerTeam(ClientToMove, 3);
				PrintToChat(ClientToMove, "\x05%t \x03%t \x05%t.", "info12", "info13", "info15");
			}
			else StopIT = true;
		}
		else if (FloatCompare(sc,ic) == -1) {
			ClientToMove = GetFirstClientID(3);
			if (ClientToMove > 0) {
				ChangePlayerTeam(ClientToMove, 2);
				PrintToChat(ClientToMove, "\x05%t \x03%t \x05%t.", "info12", "info14", "info15");
			}
			else StopIT = true;
		}
		sc = float(GetTeamHumanCount(2));
		ic = float(GetTeamHumanCount(3));
	}
}

GetFirstClientID(team)
{
	for (new i = 1; i <= GetMaxClients(); i++) 
		if (IsValidPlayer(i) && (GetClientTeam(i) == team) && (!IsAdmin(i))) return i;
	
	return 0;
}

public Action:AllowBalanceTimer(Handle:timer, any:client)
{
	AllowBalance = true;
}

public Action:SetAllowVoteTimer(Handle:timer, any:client)
{
	AllowVote[client] = 1;
}

public Action:Callvote_Handler(client, args)
{
	
	// return Plugin_Handled;  - to prevent the vote from going through
	// return Plugin_Continue; - to allow the vote to go like normal
	
	if (!IsValidPlayer(client)) return Plugin_Continue;
	
	if (RoundEnd > 0) {
		PrintToChat(client, "\x03%t", "info16")
		return Plugin_Handled;
	}
	
	
	if ((AllowVote[client] == 0) && (!IsAdmin(client))) {
		PrintToChat(client, "%t", "info17");
		return Plugin_Handled;
	}
	AllowVote[client] = 0;
	CreateTimer(120.0, SetAllowVoteTimer, client);
	
	
	new bool:DoVote = true;
	new NotIncapCount = 0;
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsNormalPlayer(i)) {
			if ((GetClientTeam(i) == 3) && (IsTank(i))) {
				if (CurrentGamemodeID == 1) DoVote = false;
			}
			if ((GetClientTeam(i) == 2) && (!IsPlayerIncapped(i)) && (IsPlayerAlive(i))) {
				NotIncapCount++;
			}
		}
	}
	if (NotIncapCount <= 1) DoVote = false;
		
	if (!DoVote) {
		PrintToChat(client, "\x03%t", "info16")
		return Plugin_Handled;
	}
		
	decl String:voteName[32];
	decl String:initiatorName[MAX_NAME_LENGTH];
	GetClientName(client, initiatorName, sizeof(initiatorName));
	GetCmdArg(1,voteName,sizeof(voteName));
		
	//new Bool:VipPresent = false;
	//for (new i = 1; i <= GetMaxClients(); i++) {
	//	if (IsValidPlayer(i) && (VipStatus[i] > 0)) VipPresent = true;
	//}
	
	if (IsBadName(client)) {
		PrintToChat(client, "%t", "info18");
		return Plugin_Handled;
	}
	
	if ((GetClientTeam(client) == 1) && (!IsAdmin(client)) && (VipStatus[client] < 1)) {
		PrintToChat(client, "%t", "info19");
		return Plugin_Handled;
	}
	
//	if (!hasVoteAccess(client, voteName)) {
//		PrintToChat(client, "Голосование запрещено");
//		return Plugin_Handled;
//	}

	decl String:arg1[256] = "";
	decl String:arg2[256] = "";
	decl String:arg3[256] = "";
	decl String:arg4[256] = "";
	decl String:arg5[256] = "";
	new arg_count = GetCmdArgs();
	if (arg_count > 0) GetCmdArg(1, arg1, sizeof(arg1));
	if (arg_count > 1) GetCmdArg(2, arg2, sizeof(arg2));
	if (arg_count > 2) GetCmdArg(3, arg3, sizeof(arg3));
	if (arg_count > 3) GetCmdArg(4, arg4, sizeof(arg4));
	if (arg_count > 4) GetCmdArg(5, arg5, sizeof(arg5));
	
	decl String:SteamID[255];
	decl String:query[1024];
	decl String:hname[255];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	GetConVarString(FindConVar("hostname"), hname, sizeof(hname));		
	
	new target = 0;
	if ( (strcmp(voteName,"Kick",false) == 0) || (strcmp(voteName,"Ban",false) == 0) ) {
		target = GetClientOfUserId(StringToInt(arg2));
		arg2 = GetName(target);
	}
		
	Format(query, sizeof(query), "INSERT INTO public_logs (steamid, client_name, action, arg1, arg2, arg3, arg4, arg5, hostname) VALUES ('%s','%s','callvote','%s','%s','%s','%s','%s','%s')", SteamID, GetName(client), arg1, arg2, arg3, arg4, arg5, hname);
	//SQL_TQuery(db, NullHandle, query, 0); -> down
	
	
	if (strcmp(voteName,"ChangeDifficulty",false) == 0)  {
		
		/*if (hostport == hostport_coop3) {
			decl String:voteArg[32];
			GetCmdArg(2,voteArg,sizeof(voteArg));
			LogToFile(logfilepath, "callvote ChangeDifficulty %s", voteArg);
			if (StrEqual(voteArg, "easy", false)) {
				PrintToChat(client, "Данное голосование запрещено.");
				return Plugin_Handled;
			}
		}
		else if (hostport != hostport_coop4) {
			*/
			PrintToChat(client, "%t", "info20");
			return Plugin_Handled;
		//}
	}
	
if ( ( (hostport == hostport_xtremecoop1) 
	|| (hostport == hostport_xtremeversus1)
	|| (hostport == hostport_xtremecoop2) 
	|| (hostport == hostport_xtremeversus2))
	&& (VipStatus[client] < 1) ) {
			PrintToChat(client, "\x05%t \x03VIP %t", "info21", "info20");
			return Plugin_Handled;	
	}
		
		
	if ( (strcmp(voteName,"ReturnToLobby",false) == 0) || 
	 (strcmp(voteName,"RestartGame",false) == 0) || (strcmp(voteName,"Custom",false) == 0) )
	{
		PrintToChat(client, "%t", "info20");
		return Plugin_Handled;
	}
	else if ( ((strcmp(voteName,"ChangeMission",false) == 0) || (strcmp(voteName,"ChangeChapter",false) == 0)) && 
	(VoteMapTime > 0) && (!IsAdmin(client)) && (VipStatus[client] == 0) )
	{
		
		if ( (!IsPlayerAlive(client)) && (!IsAdmin(client)) && (VipStatus[client] == 0) ) {
			PrintToChat(client, "%t", "info23");
			return Plugin_Handled;	
		}
		PrintToChat(client, "%t %i %t", "info24", VoteMapTime, "info25");
		return Plugin_Handled;
	}
	else if (strcmp(voteName,"Kick",false) == 0)
	{
		SQL_TQuery(db, NullHandle, query, 0);
		// this function must return either Plugin_Handled or Plugin_Continue
		return Kick_Vote_Logic(client, args);
	}
	//SQL_TQuery(db, NullHandle, query, 0);
}

public hasVoteAccess(client, String:voteName[32])
{
	
	// rcon always has access
	if (client==0)
		return true;
	
	if (IsAdmin(client)) return true;
	//if (strcmp(voteName,"Kick",false) == 0) return true;
	//if (VipStatus[client] > 0)	return true;
	//if (ClientRank[client] <= 20) return true;
	
	if (strcmp(voteName,"ReturnToLobby",false) == 0) 
	{
		return false;
	}
	else if (strcmp(voteName,"ChangeDifficulty",false) == 0) 
	{
		return false;
	}
	else if (strcmp(voteName,"ChangeMission",false) == 0) 
	{
		return true;
	}
	else if (strcmp(voteName,"RestartGame",false) == 0) 
	{
		return true;
	}
	else if (strcmp(voteName,"Kick",false) == 0) 
	{
		return true;
	}
	else if (strcmp(voteName,"Custom",false) == 0) 
	{
		return true;
	}
	else if (strcmp(voteName,"ChangeChapter",false) == 0) 
	{
		return true;
	}
	
	return true;
	
}

public MovetVIP(any:client)
{
	if (RoundEnd > 0) return;
	new rID = 0;
	
	
	if (VipStatus[client] >= 1) {
		for (new i = 1; ((i <= GetMaxClients()) && (rID == 0)) ; i++) {
			if ((IsValidPlayer(i)) && (IsBadName(i)) && (GetClientTeam(i) != 1) && (!IsAdmin(i)) && (VipStatus[i] == 0))
				rID = i;
		}
	}
	if ( (rID == 0) && ((VipStatus[client] >= 2)) ) { // || ((VipStatus[client] > 0) && (hostport == 27226)) )) {
		for (new i = 1; ((i <= GetMaxClients()) && (rID == 0)); i++) {
			if ((IsValidPlayer(i)) && (ClientSkill[i] >= 8) && (GetClientTeam(i) != 1) && (!IsAdmin(i)) && (VipStatus[i] == 0))
				rID = i;
		}
	}
	if ((rID == 0) && (VipStatus[client] >= 3)) {
		for (new i = 1; ((i <= GetMaxClients()) && (rID == 0)); i++) {
			if ((IsValidPlayer(i)) && ((ClientSkill[i] >= 5) || (ClientSkill[i] == 0)) && (GetClientTeam(i) != 1) && (!IsAdmin(i)) && (VipStatus[i] == 0))
				rID = i;
		}
	}
	
	if ((rID == 0) && (IsAdmin(client))) {
		for (new i = 1; ((i <= GetMaxClients()) && (rID == 0)); i++) {
			if ((IsValidPlayer(i)) && ((ClientSkill[i] >= 8) || ClientSkill[i] == 0) && (GetClientTeam(i) != 1) && (!IsAdmin(i)) && (VipStatus[i] == 0))
				rID = i;
		}
	}
	if ((rID == 0) && (IsAdmin(client))) {
		for (new i = 1; ((i <= GetMaxClients()) && (rID == 0)); i++) {
			if ((IsValidPlayer(i)) && ((ClientSkill[i] >= 5) || (ClientSkill[i] == 0)) && (GetClientTeam(i) != 1) && (!IsAdmin(i)) && (VipStatus[i] == 0))
				rID = i;
		}
	}
	
	if (IsValidPlayer(rID)) {
		
		new rIDTeam = GetClientTeam(rID);
		
		ClientWish[rID] = 0;
		ClientTeam[rID] = 0;
		ClientWish[client] = 0;
		ClientTeam[client] = rIDTeam;
		
		ChangePlayerTeam(rID, 1);
		ChangePlayerTeam(client, rIDTeam);
		
		PrintToChat(rID, "\x01%t \x05VIP \x01%t \x05VIP \x01 %t \x03%t", "vip1", "vip2", "vip3", "siteurl");
	}
	else PrintToChat(client, "\x05%t", "vip4");
}

public Action:cmd_scale(client, args)
{
	PrintToChat(client, "\x05Уменьшаем");
	
	if(!client)
	{
		PrintToServer("[SM] Unable to execute this command from the server console!");
		return Plugin_Handled;
	}
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_sizetarget [scale]");
	}
	new target = client;//GetClientAimTarget(client, false);
	if(!IsValidEntity(target) || !IsValidEdict(target))
	{
		PrintToChat(client, "[SM] Invalid entity or looking to nothing");
	}
	decl String:arg[256];
	GetCmdArg(1, arg, sizeof(arg));
	new Float:scale = StringToFloat(arg);
	SetEntPropFloat(target, Prop_Send, "m_flModelScale", scale);
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	
	PrintToChat(client, "\x05%s Уменьшен", GetName(client));
	
	return Plugin_Handled;
}

public cmd_showadmins()
{
	new AdminsCount = 0;
	decl String:admins[255] = "";
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (IsAdmin(i))) {
			new AdminId:id = GetUserAdmin(i);
			AdminsCount++;
			Format(admins,sizeof(admins),"%s \x05%s\x01(skill:\x03%i \x01lvl:\x03%i\x01)",admins,GetRealName(i),ClientSkill[i],GetAdminImmunityLevel(id));
		}
	}
	PrintToChatAll("\x04Админы в игре: %s",admins);
}

public Action:ShowHint(Handle:timer, any:client)
{
	if (hostport == hostport_xtremeversus1) Format(hostip, sizeof(hostip), "192.223.27.143")
	else if (hostport == hostport_xtremeversus2) Format(hostip, sizeof(hostip), "192.223.27.143")
	if ( (hostport == hostport_xtremecoop1) || (hostport == hostport_xtremecoop2) ) Format(hostip, sizeof(hostip), "192.223.27.143")
	else Format(hostip, sizeof(hostip), "192.223.27.143");

	if (hint == 1) PrintHintTextToAll("%t", "hint1");
	else if (hint == 2) PrintHintTextToAll("%t", "hint2");
	else if (hint == 3) PrintHintTextToAll("%t", "hint3");
	else if (hint == 4) PrintHintTextToAll("%t %t", "hint4", "siteurl");
	else if (hint == 5) PrintHintTextToAll("%t sm_reg \"%t\" \"%t\"", "hint5", "login", "pass");
	else if (hint == 6) PrintHintTextToAll("%t", "hint6");
	else if (hint == 7) PrintHintTextToAll("%t", "hint7");
	else if (hint == 8) PrintHintTextToAll("%t", "hint8");
	else if (hint == 9) PrintHintTextToAll("%t %t", "hint9", "siteurl");
	else if (hint == 10) PrintToChatAll("\x05%t \x03connect %s:%i", "hint10", hostip, hostport);
	else if (hint == 11) PrintHintTextToAll("%t", "hint11");
	else if (hint == 12) PrintHintTextToAll("%t %t/forum", "hint12", "siteurl");
	else if (hint == 13) PrintHintTextToAll("%t", "hint13");
	else if (hint == 14) PrintHintTextToAll("%t", "hint14");
	else if (hint == 15) PrintHintTextToAll("%t", "hint15");
	else if (hint == 16) PrintHintTextToAll("%t", "hint16");
	if (hint == 15) hint = 1; else hint++;
	
	PrintToChatAll("\x01%t \x05!menu\x01 %t", "hint17", "hint18");
	if ( (hostport == hostport_xtremecoop1)
			|| (hostport == hostport_xtremeversus1)
			|| (hostport == hostport_xtremeversus2)	
			|| (hostport == hostport_xtremecoop2)			
		) 
		{
		PrintToChatAll("\x03%t(\x04sm_mapvote\x03),", "hint19");
		PrintToChatAll("\x03%t", "hint20");
		PrintToChatAll("\x05%t", "siteurl");
		}
}



public Action:cmd_msg(client, args)
{
	if (!IsValidPlayer(client)) return Plugin_Handled;
	
	if ((AllowMsg[client] == 0) && (!IsAdmin(client))) {
		PrintToChat(client, "%t", "allowlimit1");
		return;
	}
	AllowMsg[client] = 0;
	CreateTimer(300.0, SetAllowMsgTimer, client);
	
	decl String:msg[2024];
	decl String:query[512];
	
	//GetCmdArg(1, glogin, sizeof(glogin));
	GetCmdArgString(msg, sizeof(msg));
	
	decl String:SteamID[255];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	Format(query, sizeof(query), "insert into sync_msgs (steamid, pname, msg, server, insertdt) values ('%s', '%s', '%s', 'l4d2 8vs8', now())", SteamID, GetName(client), msg);
	//SQL_FastQuery(db, "SET NAMES utf8;")
	SQL_TQuery(db, msgquery, query, client);	
}

public msgquery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (db == INVALID_HANDLE)
		return;
	
	PrintToChat(client, "\x05Ваше сообщение отправлено.");	
}

public Action:cmd_setmsg(client, args)
{
	if (!IsValidPlayer(client)) return Plugin_Handled;
	
	if (VipStatus[client] < 1) {
		PrintToChat(client, "%t", "info26");
		return;
	}
	
	if ((AllowMsg[client] == 0) && (!IsAdmin(client))) {
		PrintToChat(client, "", "allowlimit1");
		return;
	}
	AllowMsg[client] = 0;
	CreateTimer(300.0, SetAllowMsgTimer, client);
	
	decl String:msg[2024];
	decl String:query[512];
	
	//GetCmdArg(1, glogin, sizeof(glogin));
	GetCmdArgString(msg, sizeof(msg));
	
	ReplaceString(msg, sizeof(msg), "<?php", "");
	ReplaceString(msg, sizeof(msg), "<?PHP", "");
	ReplaceString(msg, sizeof(msg), "?>", "");
	ReplaceString(msg, sizeof(msg), "\\", "");
	ReplaceString(msg, sizeof(msg), "'", "");
	ReplaceString(msg, sizeof(msg), ";", "");
	ReplaceString(msg, sizeof(msg), "ґ", "");
	ReplaceString(msg, sizeof(msg), "`", "");
	
	if ( (strlen(msg) < 5) && (strlen(msg) > 0) ) {
		PrintToChat(client, "%t", "info27");
		return;
	}
	
	decl String:SteamID[255];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	Format(query, sizeof(query), "update reg_name set entertext = '%s' where steamid = '%s'", msg, SteamID);
	SQL_FastQuery(db, "SET NAMES utf8;")
	SQL_TQuery(db, setmsgquery, query, client);	
	
	if (strlen(msg) == 0) PrintToChat(client, "%t", "info28");
	
}

public setmsgquery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (db == INVALID_HANDLE)
		return;
	
	PrintToChat(client, "\x05%t", "info29");	
}

public SetAllAllowMsg()
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			AllowMsg[i] = 1;
			AllowName[i] = 1;
		}
	}
}

public Action:SetAllowMsgTimer(Handle:timer, any:client)
{
	AllowMsg[client] = 1;
}

public Action:ShowConnectMsg(Handle:timer, any:client)
{
	if (IsValidPlayer(client)) 
		PrintToChat(client, "\x05Вы можете оставить свой \x03отзыв или предложение \x01о сервере командой \x04sm_msg \x05\"текст сообщения\"");
}

public Action:Kick_Vote_Logic(client, args)
{
	
	// return Plugin_Handled;  - to prevent the vote from going through
	// return Plugin_Continue; - to allow the vote to go like normal
	
	decl String:initiatorName[MAX_NAME_LENGTH];
	GetClientName(client, initiatorName, sizeof(initiatorName));
	
	decl String:arg2[12];
	GetCmdArg(2, arg2, sizeof(arg2));
	new target = GetClientOfUserId(StringToInt(arg2));
	
	if (VipStatus[target] > 0) {
		PrintToChatAll("\x05%s \x01%t \x04%s\x01, %t.",initiatorName, "info30", GetName(target), "info31");
		return Plugin_Handled; 
	}
	
	if (IsAdmin(target)) {
		PrintToChatAll("\x05%s \x01%t \x04%s\x01, %t.", initiatorName, "info30", GetName(target), "info32");
		return Plugin_Handled; 
	}
	
	//if (ClientRank[target] <= 20) {
	//	PrintToChatAll("\x05%s \x01пытался начать голосование против \x04%s\x01, кикать \x03Top20 \x01игроков \x05запрещено.",initiatorName, GetName(target));
	//	return Plugin_Handled; 
	//}	
	
	return Plugin_Continue;
}

public Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//RoundStartInit();	
	CreateTimer(0.5, RoundStartInitTimer);	
}

public bool:OnClientConnect(client, String:rejectmsg[], size)
{
	if (IsFakeClient(client)) return true;
	
	new Float:ct;
	ct = GetClientTime(client);

	/*
	if (BlockConnect) LogToFile(logfilepath, "OnClientConnect: BlockConnect=true: %f", ct);
	else LogToFile(logfilepath, "OnClientConnect: BlockConnect=false: %f", ct);
		
	if ( ( BlockConnect && (FloatCompare(ct, 3.0) == -1) ) || (BlockConnectStart) )  {
		Format(rejectmsg, size, "Connect blocked, please try again in few seconds.");
		LogToFile(logfilepath, "OnClientConnect block: %i: %s", client, GetName(client));
		return false;
	}
	*/
		
	BlockConnect = true;	
	if (TimerBC == INVALID_HANDLE) TimerBC = CreateTimer(1.0, ResetBlockConnect, INVALID_HANDLE);		
		
	LogToFile(logfilepath, "OnClientConnect start: %i: %s", client, GetName(client));
		
	decl String:login[255];
	GetClientInfo(client,"login",login,sizeof(login));
	decl String:pass[255];
	GetClientInfo(client,"pass",pass,sizeof(pass));
	
	decl String:client_psw[100];
	GetClientInfo(client,"svpsw",client_psw,sizeof(client_psw));
	
	LogToFile(logfilepath, "OnClientConnect 2: %i: %s", client, GetName(client));
	
	if ((strlen(sv_pass) > 0) && (!StrEqual(client_psw, sv_pass))) {
		if (!StrEqual(client_psw, "RockNRoll")) {
			Format(rejectmsg, size, "Wrong password");
			return false;
		}
	}
	
	new isc, iic, ispc;
	new bool:IsVip = false;
	
	ispc = GetTeamHumanCount(1);
	isc = GetTeamHumanCount(2);
	if (CurrentGamemodeID != 1) iic = 0; else iic = GetTeamHumanCount(3);
	
	
	LogToFile(logfilepath, "OnClientConnect 3: %i: %s", client, GetName(client));
	
	for (new i = 1; i <= acCount; i ++) {
		if ((StrEqual(login, acLogin[i], false)) && (StrEqual(pass, acPass[i], false))) 
			IsVip = true;
	}
	
	//new vmp = GetConVarInt(FindConVar("sv_visiblemaxplayers"));
	new MaxPlayers = 24;
	new hc = GetHumanCount();
	new mt;
	if (CurrentGamemodeID != 1) mt = 24; else mt = GetTeamMaxHumans(3) + GetTeamMaxHumans(2);
	
	//if ( ((CurrentGamemodeID == 0) && (hc > MaxPlayers)) || ((CurrentGamemodeID != 0) && ((isc+iic >= mt) || (hc >= vmpg))) ) {
	if ( (isc+iic >= mt) || (hc >= vmpg) )   {
		 
		if (IsVip) return true;
		PrintToChatAll("No free slots: Kicked %s. Current players: %i.", GetName(client), GetHumanCount());
		Format(rejectmsg, size, "No hay cupo. Largo de aqui");
		LogToFile(logfilepath, "OnClientConnect no free slots: %i: %s CurrentGamemodeID: %i GetHumanCount: %i", client, GetName(client), CurrentGamemodeID, GetHumanCount());
		return false;
		
	}
	
	LogToFile(logfilepath, "OnClientConnect end: %i: %s", client, GetName(client));
	
	return true;
}

public Action:HeartBeat(Handle:timer, any:client)
{
	if (RoundEnd > 0) return;
	
	ServerCommand("heartbeat");
	PrintToServer("Send heartbeat");
	
	//if (CurrentGamemodeID != 0) RefreshAllClientRank();
}

public OnMapEnd()
{
	
	if (MapEnd > 0) return;
		
	new String: cmap[255];
	GetCurrentMap(cmap, sizeof(cmap));	
	LogToFile(logfilepath, "MapEnd: %s", cmap);
	
	MapEnd++;
	RoundNum = 0;
	MapStart = 0;

	BlockConnect = true;
	for (new i = 1; i <= GetMaxClients(); i++) 
		if ( (IsClientConnected(i)) && (!IsClientInGame(i)) )
		  KickClient(i, "Map change starting, please try connect in few seconds.");
		
	UnHookDamage();
	RoundEndProc();	
	
	LogToFile(logfilepath, "MapEnd end: %s", cmap);
		
}

public Action:CheckRegTimer(Handle:timer, any:client)
{
	if (IsValidPlayer(client)) 
		PushIntoArray(toCheckReg, client);
	//checkreg(client);
}

public SaveTeams()
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		ClientTeam[i] = 0;
		ClientWish[i] = 0;
		if (IsValidPlayer(i)) {
			ClientTeam[i] = GetClientTeam(i);
			ClientWish[i] = ClientTeam[i];
		}
	}
}

public SetTeams()
{
	//if (GetBizonID()>0) PrintToChat(GetBizonID(),"SetTeams tick %i", TimerCount);
	if (RoundEnd > 0) return;
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			if ((ClientTeam[i] !=  GetClientTeam(i)) && (ClientTeam[i] > 1)) {
				
				if (GetTeamHumanCount(ClientTeam[i]) < GetTeamMaxHumans(ClientTeam[i])) {
					ChangePlayerTeam(i, ClientTeam[i]);
				}
				else {
					if (MoveIllegal(ClientTeam[i]) == true) ChangePlayerTeam(i, ClientTeam[i]);
					else ChangePlayerTeam(i, 1);
				}
			}
			else if ((ClientTeam[i] !=  GetClientTeam(i)) && (ClientTeam[i] == 1)) {
				ChangePlayerTeam(i, 1);
				ClientTeam[i] = 0;
			}
		}
	}
}

bool:MoveIllegal(team)
{
	if (RoundEnd > 0) return true;
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) 
			if ((GetClientTeam(i) == team) && ((GetClientTeam(i) != ClientTeam[i]) || (ClientTeam[i] == 0)) && (!IsAdmin(i))) {
			ChangePlayerTeam(i, 1);
			PrintToChat(i, "\x05[system] \x01%t", "info33");
			return true;
		}
	}
	return false;
}

public ResetTeams()
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		ClientTeam[i] = 0;
	}
}

public ChangeClientTeams()
{
	SaveTeams();
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (ClientTeam[i] == 2) ClientTeam[i] = 4;
	}
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (ClientTeam[i] == 3) ClientTeam[i] = 2;
	}
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (ClientTeam[i] == 4) ClientTeam[i] = 3;
	}
}


public Action:event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundEndProc();
}

public RoundEndProc()
{
	RoundEnd++;
	LogToFile(logfilepath, "RoundEndProc start: %i", RoundEnd);
		
	if (RoundEnd == 1) {
		
		LogToFile(logfilepath, "RoundEndProc 1: %i", RoundEnd);
		
		RoundStarted = false;
		TimerCount = 0;
		RoundNum++;
		
		//for (new i = 1; i <= GetMaxClients(); i++) {
		//	if ( (IsClientConnected(i)) && (!IsClientInGame(i)) ) {
		//		KickClient(i, "Change map in process, please try again in few seconds.");
		//	}
		//}
		
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
			
		UnhookEntityOutput("trigger_finale","FinaleStart",OnFinaleStart);
				
		entDoorStart = 0;
		entDoorGoal = 0;
		TimerCount = 0;
						
		if (CurrentGamemodeID != 1) {
			
			//SetConVarInt(FindConVar("director_panic_forever"), 0);
			
			LogToFile(logfilepath, "RoundEndProc 2: %i", RoundEnd);
			SaveTeams();
			return;
		}
		
		LogToFile(logfilepath, "RoundEndProc 3: %i", RoundEnd);
		
		PrintToChatAll("A:%i B:%i", LastKnownScoreTeamA, LastKnownScoreTeamB);
		for (new i = 1; i <= GetMaxClients(); i++) {
			if (IsValidPlayer(i)) {
				if (GetClientTeam(i) == ScoreATeam) { PrintToChat(i, "Ваша команда: А"); }
				else if (GetClientTeam(i) == ScoreBTeam) { PrintToChat(i, "Ваша команда: B"); }
			}
		}
		
		LogToFile(logfilepath, "RoundEndProc 4: %i", RoundEnd);
		
		if (RoundCount == 1) {
			new b = ScoreATeam;
			ScoreATeam = ScoreBTeam;
			ScoreBTeam = b;
			ChangeClientTeams();
			RoundCount = 2;
		}
		else if (RoundCount > 1) {
			RoundCount = 1;
			if (LastKnownScoreTeamA > LastKnownScoreTeamB) {
				if (ScoreATeam != 2) {
					ScoreATeam = 2;
					ScoreBTeam = 3;
					ChangeClientTeams();
				} else SaveTeams();
			}
			else if (ScoreBTeam != 2) {
				ScoreBTeam = 2;
				ScoreATeam = 3;
				ChangeClientTeams();
			} else SaveTeams();
			
		} else ChangeClientTeams();
		
		LogToFile(logfilepath, "RoundEndProc 5: %i", RoundEnd);
		
	}
	
	LogToFile(logfilepath, "RoundEndProc end: %i", RoundEnd);
}

public Action:FillAllowArrayTimer(Handle:timer, any:client)
{
	FillAllowArray();
}

public Action:FillBadNamesArrayTimer(Handle:timer, any:client)
{
	FillBadNamesArray();
	FillAdminIdsArray();
}

public Action:SetTeamsTimer(Handle:timer, any:client)
{
	TimerCount--;
	if (TimerCount > 0) {
		CreateTimer(1.0, SetTeamsTimer, 0);
		SetTeams();
	}
	else {
		PrintToChatAll("Режим восстановления команд закончен");
		SaveTeams();
	}
}

public Action:ShowTArray_cmd(client, args)
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			PrintToChat(client, "%i %s team:%i", i, GetName(i), ClientTeam[i]);
		}
	}
}

public Action:SaveTeams_cmd(client, args)
{
	SaveTeams();
}

public Action:SetTeams_cmd(client, args)
{
	if (CurrentGamemodeID != 1) {
		PrintToChat(client, "disabled, gamemode is not versus");
		return;
	}
	SetTeams();
}

public Action:L4D_OnSetCampaignScores(&scoreA, &scoreB)
{
	LastKnownScoreTeamA = scoreA;
	LastKnownScoreTeamB = scoreB;
	
	return Plugin_Continue;
}

public Action:cmd_SetSkill(client, args)
{
	if (!IsValidPlayer(client)) return;
	PlayersMenu(client, Menu_PlayersMenuHandler, 1);
}

string:GetSkillText(skill)
{
	decl String:skilltext[255];
	
	if (skill == 0) Format(skilltext,sizeof(skilltext),"%t", "skill0")
	else if (skill == 1) Format(skilltext,sizeof(skilltext),"%t", "skill1");
	else if (skill == 2) Format(skilltext,sizeof(skilltext),"%t", "skill2")
	else if (skill == 3) Format(skilltext,sizeof(skilltext),"%t", "skill3")
	else if (skill == 4) Format(skilltext,sizeof(skilltext),"%t", "skill4")
	else if (skill == 5) Format(skilltext,sizeof(skilltext),"%t", "skill5")
	else if (skill == 6) Format(skilltext,sizeof(skilltext),"%t", "skill6")
	else if (skill == 7) Format(skilltext,sizeof(skilltext),"%t", "skill7")
	else if (skill == 8) Format(skilltext,sizeof(skilltext),"%t", "skill8")
	else if (skill == 9) Format(skilltext,sizeof(skilltext),"%t", "skill9")
	else if (skill == 10) Format(skilltext,sizeof(skilltext),"%t", "skill10");
	
	return skilltext;
}

public Menu_PlayersMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;
	
	if (action == MenuAction_End) {
		CloseHandle(menu);
		return;
	}
	
	if (action != MenuAction_Select || param1 <= 0 || (!IsValidPlayer(param1))){
		
		return;
	}
	
	decl String:Info[255];
	new bool:found = GetMenuItem(menu, param2, Info, sizeof(Info));
	
	if (!found) return;
	
	//if (SkillProcess == 1) { 
	//	PrintToChat(param1,"Занят, попробуйте чуть позжее.");
	//		return; 
	//	}
	//	SkillProcess = 1;
	
	skillclient = StringToInt(Info);
	SetSkill(StringToInt(Info),param1);
	
	
}


public SetSkill(any:toclient,client)
{
	decl String:Title[MAX_LINE_WIDTH];
	
	Format(Title, sizeof(Title), "%t: %s", "info34", GetName(toclient));
	new Handle:menu = CreateMenu(Menu_SkillMenuHandler);
	
	SetMenuTitle(menu, Title);
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);
	
	decl String:text[255];
	
	Format(text,sizeof(text),"%t", "skill1");
	AddMenuItem(menu, "1", text);
	
	Format(text,sizeof(text),"%t", "skill2");
	AddMenuItem(menu, "2", text);
	
	Format(text,sizeof(text),"%t", "skill3");
	AddMenuItem(menu, "3", text);
	
	Format(text,sizeof(text),"%t", "skill4");
	AddMenuItem(menu, "4", text);
	
	Format(text,sizeof(text),"%t", "skill5");
	AddMenuItem(menu, "5", text);
	
	Format(text,sizeof(text),"%t", "skill6");
	AddMenuItem(menu, "6", text);
	
	Format(text,sizeof(text),"%t", "skill7");
	AddMenuItem(menu, "7", text);
	
	Format(text,sizeof(text),"%t", "skill8");
	AddMenuItem(menu, "8", text);
	
	Format(text,sizeof(text),"%t", "skill9");
	AddMenuItem(menu, "9", text);
	
	Format(text,sizeof(text),"%t", "skill10");
	AddMenuItem(menu, "10", text);
	
	DisplayMenu(menu, client, 60);
}

public Menu_SkillMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;
	
	if (action == MenuAction_End) {
		CloseHandle(menu);
		return;
	}
	
	if (action != MenuAction_Select || param1 <= 0 || (!IsValidPlayer(param1)) || (!IsValidPlayer(skillclient))) {
		
		return;
	}
	
	decl String:Info[255];
	new bool:found = GetMenuItem(menu, param2, Info, sizeof(Info));
	
	if (!found)
		return;
	
	decl String:query[512];
	
	SkillParam = StringToInt(Info);
	
	if ((AllowSkill[param1] == 0) && (!IsAdmin(param1))) {
		PrintToChat(param1, "%t.", "info35")
		return;
	}
	CreateTimer(60.0, SetAllowSkill, param1);
	AllowSkill[param1] = 0;
	
	
	
	decl String:aftorsteamid[255];
	decl String:skillsteamid[255];
	GetClientAuthString(param1, aftorsteamid, sizeof(aftorsteamid));
	GetClientAuthString(skillclient, skillsteamid, sizeof(skillsteamid));
	
	Format(query, sizeof(query), "SELECT * FROM skills WHERE aftor_steamid = '%s' and skill_steamid = '%s'", aftorsteamid, skillsteamid);
	SQL_TQuery(db, SetSkillQuery, query, param1);
	
}

public SetSkillQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("RegisterQuery failed: %s", error);
		return;
	}
	
	decl String:query[512];
	decl String:aftorsteamid[255];
	decl String:skillsteamid[255];
	GetClientAuthString(client, aftorsteamid, sizeof(aftorsteamid));
	GetClientAuthString(skillclient, skillsteamid, sizeof(skillsteamid));
	
	if (StrEqual(aftorsteamid,skillsteamid)) {
		//PrintToChat(client, "\x05Ваша \x01самооценка принята к сведению.");	
		PrintToChatAll("\x05%s \x01%t: \x03%s\x01, %t",GetName(skillclient), "info36", GetSkillText(SkillParam), "info37");	
		return;
	}
	
	new String:baselogin[255];
	decl String:basesteamid[255];
	decl String:skilltype[255];
	
	new iAdmin = 0;
	new iVip = 0;
	if (IsAdmin(client)) iAdmin = 1; else iAdmin = 0;
	if (VipStatus[client] > 0) iVip = 1; else iVip = 0;
	if (!SQL_HasResultSet(hndl)) return;
	if (SQL_FetchRow(hndl)) 	{
		SQL_FetchString(hndl, 2, aftorsteamid, sizeof(aftorsteamid));
		SQL_FetchString(hndl, 3, skillsteamid, sizeof(skillsteamid));
		
		Format(skilltype, sizeof(skilltype),"%t", "info38");
		Format(query, sizeof(query), "UPDATE skills SET skill = %i, isadmin = %i, isvip = %i where aftor_steamid = '%s' and skill_steamid = '%s'", SkillParam, iAdmin, iVip, aftorsteamid, skillsteamid);
		SQL_TQuery(db, UpdateSkillCallback, query, skillclient);		
		
	}
	else {
		Format(skilltype, sizeof(skilltype),"%t", "info39");
		Format(query, sizeof(query), "INSERT INTO skills (aftor_steamid,skill_steamid,skill,isadmin, isvip) VALUES ('%s','%s',%i,%i, %i)", aftorsteamid, skillsteamid, SkillParam, iAdmin, iVip);
		SQL_TQuery(db, UpdateSkillCallback, query, skillclient);
	}
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			if (IsAdmin(i)) {
				PrintToChat(i,"\x01%t \x05%s \x01%s \x04%t\x01: \x03%s \x01(%s)", "info40", GetName(skillclient), skilltype, "info41", GetSkillText(SkillParam), GetName(client));	
			}
			else PrintToChat(i,"\x01%t \x05%s \x01%s \x04%t\x01: \x03%s", "info40", GetName(skillclient), skilltype, "info41", GetSkillText(SkillParam));	
		}
	}
	PrintToChatAll("%t", "info42");
			
	//UpdateClientSkill(skillclient);
	//ClientSkill[skillclient] = SkillParam;
	//Format(query, sizeof(query), "SELECT * FROM reg_name WHERE steamid = '%s'", skillsteamid);
	//SQL_TQuery(db, SetSkillQuery2, query, client);
	
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:queryid)
{
	if (db == INVALID_HANDLE)
		return;
	
	if(!StrEqual("", error))
	{
		LogError("SQL Error: %s", error);
	}
}

public UpdateSkillCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (db == INVALID_HANDLE)
		return;
	
	if(!StrEqual("", error))
	{
		LogError("SQL Error: %s", error);
	}
	//UpdateClientSkill(skillclient);
	PushIntoArray(toUpdateSkill, skillclient);
}



public Action:SetAllowSkill(Handle:timer, any:client)
{
	AllowSkill[client] = 1;
}

public Action:UpdateClientSkillTimer(Handle:timer, any:client)
{
	if (!IsValidPlayer(client)) return;
	PushIntoArray(toUpdateSkill, client);
	//UpdateClientSkill(client);
}

UpdateClientSkill(client)
{
	if ( (!IsValidPlayer(client)) || (MapEnd > 0) ) return;
	
	LogToFile(logfilepath, "UpdateClientSkill: %i %s", client, GetName(client));
	
	if (IsUpdateSkillProcess) return;
	IsUpdateSkillProcess = true;
	
	decl String:query[2048];
	decl String: skillsteamid[255];
	GetClientAuthString(client, skillsteamid, sizeof(skillsteamid));
	
	Format(query, sizeof(query), "select (select round(avg(skill)) from skills where skill_steamid = '%s' and isadmin = 1) as adminskill, (select round(avg(skill)) from skills where skill_steamid = '%s' and isadmin = 0) as commonskill, (select count(1) from skills where skill_steamid = '%s' and isadmin = 1) as admincount, (select count(1) from skills where skill_steamid = '%s' and isadmin = 0) as commoncount,(select round(avg(skill)) from skills where skill_steamid = '%s' and isvip = 1) as vipskill, (select count(1) from skills where skill_steamid = '%s' and isvip = 1) as vipcount from skills limit 1", skillsteamid, skillsteamid, skillsteamid, skillsteamid, skillsteamid, skillsteamid);
	SQL_TQuery(db, UpdateClientSkill_Query, query, client);		
	
	
}

public UpdateClientSkill_Query(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if ( (hndl == INVALID_HANDLE) || (MapEnd > 0) || (!IsValidPlayer(client)) )
	{
		IsUpdateSkillProcess = false;
		LogToFile(logfilepath, "UpdateClientSkill_Query failed: %i %s", client, GetName(client));
		return;
	}
	
	LogToFile(logfilepath, "UpdateClientSkill_Query: %i %s", client, GetName(client));
	
	new AdminSkill = 0;
	new CommonSkill = 0;	
	new AdminCount = 0;	
	new CommonCount = 0;	
	new VipSkill = 0;
	new VipCount = 0;
	
	if (!SQL_HasResultSet(hndl)) {
		IsUpdateSkillProcess = false;
		return;
	}
	
	if (SQL_FetchRow(hndl)) 	{
		AdminSkill = SQL_FetchInt(hndl, 0);
		CommonSkill = SQL_FetchInt(hndl, 1);
		AdminCount = SQL_FetchInt(hndl, 2);
		CommonCount = SQL_FetchInt(hndl, 3);
		VipSkill = SQL_FetchInt(hndl, 4);
		VipCount = SQL_FetchInt(hndl, 5);
	}
	
	new SkillSum;
	
	if ((AdminSkill > 0) && (CommonCount >= 3)) {
		SkillSum = 	AdminSkill;
		if ((CommonSkill > AdminSkill) && (SkillSum < 10)) SkillSum ++;
		else if ((CommonSkill < AdminSkill) && (SkillSum > 1)) SkillSum --;
		//ClientSkill[client] = RoundFloat(FloatDiv(SkillSum, 2));
		ClientSkill[client] = SkillSum;
	}
	else if ((AdminSkill > 0) && (CommonCount < 3)) { 
		ClientSkill[client] = AdminSkill; 
	}
	else if ((VipSkill > 0) && (CommonCount >= 3)) {
		SkillSum = 	VipSkill;
		if ((CommonSkill > VipSkill) && (SkillSum < 10)) SkillSum ++;
		else if ((CommonSkill < VipSkill) && (SkillSum > 1)) SkillSum --;
		//ClientSkill[client] = RoundFloat(FloatDiv(SkillSum, 2));
		ClientSkill[client] = SkillSum;
	}
	else if ((VipSkill > 0) && (CommonCount < 3)) { 
		ClientSkill[client] = VipSkill; 
	}
	else if (CommonCount > 3) { 
		ClientSkill[client] = CommonSkill; 
	}
	else ClientSkill[client] = 0;
	
	CreateTimer(1.0, DelayedSkillFinish, client);
	
}
public Action:DelayedSkillFinish(Handle:timer, any:client)
{
	IsUpdateSkillProcess = false;
	
	new toDel = FindValueInArray(toUpdateSkill, client);
	if (toDel != -1) RemoveFromArray(toUpdateSkill, toDel);
	
	if (GetArraySize(toUpdateSkill) > 0) UpdateClientSkill(GetArrayCell(toUpdateSkill, 0));
}
	

	


public Action:cmd_ShowSkills(client, args)
{
	if (!IsValidPlayer(client)) return;
	showskillpanel(client);
}

public showskillpanel(any:client)
{
	if (!IsValidPlayer(client)) return;
	
	//SetFinalSkill(client);
	
	new Handle:TeamPanel = CreatePanel();
	//	SetPanelTitle(TeamPanel, "Online list:");
	
	decl String:text[255];
	decl String:Skill[255];
	decl String:pName[255];
	
	Format(text,sizeof(text),"Survivors:(%i/%i):",GetTeamHumanCount(2),GetTeamMaxHumans(2));
	//	PrintToChat(client,"\x04Survivors\x01:(%i/%i):",GetTeamHumanCount(2),maxsurvivors);
	DrawPanelText(TeamPanel, text);
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (GetClientTeam(i) == 2)) {
			decl String:text[255];
			
			pName = GetName(i);
			ReplaceString(pName, sizeof(pName), "[", "|");
			ReplaceString(pName, sizeof(pName), "]", "|");
			//Format(text,sizeof(text),"%s: %s [установил: %s]", pName,GetSkillText(ClientSkill[i]), ClientSkillAftor[i]);
			Format(text,sizeof(text),"%s: %s", pName, GetSkillText(ClientSkill[i]));
			//PrintToChat(client,"\x03%s\x01: \x05%s", pName,GetSkillText(ClientSkill[i]));
			DrawPanelText(TeamPanel, text);
		}
	}
	
	DrawPanelText(TeamPanel, " \n");
	DrawPanelItem(TeamPanel, "Далее");
	SendPanelToClient(TeamPanel, client, TeamPanelHandler1, 60);
	CloseHandle(TeamPanel);
}

public showskillpanel2(any:client)
{
	if (!IsValidPlayer(client)) return;
	
	new Handle:TeamPanel = CreatePanel();
	//	SetPanelTitle(TeamPanel, "Online list:");
	
	decl String:text[255];
	decl String:Skill[255];
	decl String:pName[255];
	
	DrawPanelText(TeamPanel, " \n");
	Format(text,sizeof(text),"Infected:(%i/%i):",GetTeamHumanCount(3),GetTeamMaxHumans(3));
	//PrintToChat(client,"\x04Infected\x01:(%i/%i):",GetTeamHumanCount(3),maxinfected);
	DrawPanelText(TeamPanel, text);
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (GetClientTeam(i) == 3)) {
			decl String:text[255];
			
			pName = GetName(i);
			ReplaceString(pName, sizeof(pName), "[", "|");
			ReplaceString(pName, sizeof(pName), "]", "|");
			//Format(text,sizeof(text),"%s: %s", pName,GetSkillText(ClientSkill[i]));
			Format(text,sizeof(text),"%s: %s", pName, GetSkillText(ClientSkill[i]));
			//PrintToChat(client,"\x03%s\x01: \x05%s", pName,GetSkillText(ClientSkill[i]));
			DrawPanelText(TeamPanel, text);
		}
	}
	
	
	DrawPanelText(TeamPanel, " \n");
	DrawPanelItem(TeamPanel, "Далее");
	DrawPanelItem(TeamPanel, "Назад");
	SendPanelToClient(TeamPanel, client, TeamPanelHandler2, 60);
	CloseHandle(TeamPanel);
}

public showskillpanel3(any:client)
{
	if (!IsValidPlayer(client)) return;
	
	new Handle:TeamPanel = CreatePanel();
	//	SetPanelTitle(TeamPanel, "Online list:");
	
	decl String:text[255];
	decl String:Skill[255];
	decl String:pName[255];
	
	Format(text,sizeof(text),"Spectators:(%i):",GetTeamHumanCount(1));
	DrawPanelText(TeamPanel, text);
	//	PrintToChat(client,"\x04Spectators\x01:(%i):",GetTeamHumanCount(1));
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (GetClientTeam(i) == 1)) {
			decl String:text[255];
			pName = GetName(i);
			ReplaceString(pName, sizeof(pName), "[", "|");
			ReplaceString(pName, sizeof(pName), "]", "|");
			//Format(text,sizeof(text),"%s: %s", pName,GetSkillText(ClientSkill[i]));
			Format(text,sizeof(text),"%s: %s", pName, GetSkillText(ClientSkill[i]));
			//			PrintToChat(client,"\x03%s\x01: \x05%s", pName,GetSkillText(ClientSkill[i]));
			DrawPanelText(TeamPanel, text);
		}
	}
	DrawPanelText(TeamPanel, " \n");
	DrawPanelItem(TeamPanel, "Закрыть");
	DrawPanelItem(TeamPanel, "Назад");
	SendPanelToClient(TeamPanel, client, TeamPanelHandler3, 60);
	CloseHandle(TeamPanel);
}

public TeamPanelHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	
	
	if (action != MenuAction_Select)
		return;
	
	if (param2 == 1) { showskillpanel2(param1); }
}
public TeamPanelHandler2(Handle:menu, MenuAction:action, param1, param2)
{
	
	
	if (action != MenuAction_Select)
		return;
	if (param2 == 1) { showskillpanel3(param1); }
	else if (param2 == 2) { showskillpanel(param1); }
	
}
public TeamPanelHandler3(Handle:menu, MenuAction:action, param1, param2)
{
	
	
	if (action != MenuAction_Select)
		return;
	if (param2 == 1) { return; }
	else if (param2 == 2) { showskillpanel2(param1); }
}

public SetAllAllowSkill()
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			AllowSkill[i] = 1;
			AllowPass[i] = 1;
		}
	}
}

public Action:SetBalance(client, args)
{
	if (RoundEnd > 0) return;
	if (CurrentGamemodeID != 1) {
		PrintToChat(client, "disabled, gamemode is coop");
		PrintToServer("SetBalance disabled, gamemode is coop");
		return;
	}
	PrintToServer("SetBalance in process");
	
	//if (AllowSkillBalance == 0) {
	//	PrintToChat(client,"Не так часто!");
	//	return;
	//}
	
	//if ((IsValidPlayer(client)) && (GetClientTeam(client) == 1)) {
	//	PrintToChat(client, "\x01[\x04sync\x01] Зрителям запрещен запуск голосования.");
	//	return;
	//}
	
	//AllowSkillBalance = 0;
	//CreateTimer(60.0, SetAllowSkillBalance, INVALID_HANDLE);
	
	//new bool:DoVote = true;
	if (IsValidPlayer(client)) PrintToChat(client, "%s: %t", GetName(client), "info43");
	new NotIncapCount = 0;
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsNormalPlayer(i)) {
			if ((GetClientTeam(i) == 2) && (!IsPlayerIncapped(i)) && (IsPlayerAlive(i))) {
				NotIncapCount++;
			}
		}
	}
	if ((NotIncapCount <= 1) || (RoundEnd > 0)) {
		PrintToChatAll("%t", "info44");
		return;
	}
	
	PrintToChatAll("%t", "info45");
	
	TimerCount = 0;
	
	//new bid = GetBizonID();
	
	new dBalance[GetMaxClients() + 1];
	for (new i = 1; i <= GetMaxClients(); i++) {
		dBalance[i] = 0;
		if ((IsValidPlayer(i)) && (GetClientTeam(i) == 1)) dBalance[i] = 1;
		
		//if (bid>0) if (IsValidPlayer(i)) PrintToChat(bid, "%s зритель: %i", GetName(i), dBalance[i]);
	}
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (GetClientTeam(i) != 1)) 
			ChangePlayerTeam(i, 1);
	}	
	
	
	new team = 2;
	new firstone = 1;
	new step = 1;
	for (new i = 1; i <= 11; i++) {
		if (i == 11) i = 0;
		for (new j = 1; j <= GetMaxClients(); j++) {
			if ((IsValidPlayer(j)) && (GetClientTeam(j) == 1) && (ClientSkill[j] == i) && (dBalance[j] != 1)) {
				//if ((IsValidPlayer(j)) && (ClientSkill[j] == i) && (dBalance[j] != 1)) {
				ChangePlayerTeam(j, team);
				ClientWish[j] = team;
				//if (bid>0) if (IsValidPlayer(j)) PrintToChat(bid, "%s перемещен в %i", GetName(j), team);
				
				if (firstone == 1) {
					firstone = 0;
					team = 3;
				}
				else {
					if (step > 1) {
						if (team == 2) team = 3; else team = 2;
						step = 0;
					}
					step ++;
				}
			}
		}
		if (i == 0) i = 11;
	}
	
	SaveTeams();
	TimerCount = 300;
	CreateTimer(1.0, SetTeamsTimer, 0);
	
	PrintToChatAll("%t", "info46");
}

public CheckBalance()
{	
	STop20 = 0;
	ITop20 = 0;
	STop100 = 0;
	ITop100 = 0;
	STop1k = 0;
	ITop1k = 0;
	SOther = 0;
	IOther = 0;
	SSkill1 = 0;
	ISkill1 = 0;
	SSkill2 = 0;
	ISkill2 = 0;
	SSkill3 = 0;
	ISkill3 = 0;
	
	for (new i = 0; i <= 10; i++) {
		SSkill[i] = 0;
		ISkill[i] = 0;
	}
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			if (GetClientTeam(i) == 2) {
				if ((ClientSkill[i]>=1) && (ClientSkill[i]<=3)) { SSkill1 = SSkill1 + 1; }
				else if ((ClientSkill[i]>=4) && (ClientSkill[i]<=6)) { SSkill2 = SSkill2 + 1; }
				else if ((ClientSkill[i]>=7) && (ClientSkill[i]<=10)) { SSkill3 = SSkill3 + 1; }
				
				if ((ClientSkill[i] >= 0) && (ClientSkill[i] <= 10)) SSkill[ClientSkill[i]]++;
			}
			else if (GetClientTeam(i) == 3) {
				if ((ClientSkill[i]>=1) && (ClientSkill[i]<=3)) { ISkill1 = ISkill1 + 1; }
				else if ((ClientSkill[i]>=4) && (ClientSkill[i]<=6)) { ISkill2 = ISkill2 + 1; }
				else if ((ClientSkill[i]>=7) && (ClientSkill[i]<=10)) { ISkill3 = ISkill3 + 1; }
				
				if ((ClientSkill[i] >= 0) && (ClientSkill[i] <= 10)) ISkill[ClientSkill[i]]++;
				
			}
		}
	}	
}

GetSkillCount(any: skill, team)
{
	new sCount = 0;
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			if ((GetClientTeam(i) == team) && (ClientSkill[i] == skill)) {
				sCount ++;
			}
		}
	}
	return sCount;
}

public Action:SetAllowSkillBalance(Handle:timer, any:client)
{
	AllowSkillBalance = 1;
}

GetFirstSkillClientID(team,from,to)
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i) && (GetClientTeam(i) == team) && (ClientSkill[i] >= from) && (ClientSkill[i] <= to)) {
			return i; 
		}
	}
	
	return 0;
}

GetNoSkillClient(any: team)
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i) && (GetClientTeam(i) == team) && (ClientSkill[i] == 0)) {
			return i;
		}
	}
	return 0;
}

GetMinSkillClientID(team, from, to, exid)
{
	new MinSkill = from;
	new MinSkillClient = 0;
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i) && (GetClientTeam(i) == team) && (ClientSkill[i] >= from) && (ClientSkill[i] <= to) && (i != exid)) {
			if ((ClientSkill[i] > MinSkill)) {
				MinSkillClient = i; 
				MinSkill = ClientSkill[i];
			}
		}
	}
	return MinSkillClient;
}

GetMaxSkillClientID(team,from,to)
{
	new MaxSkill = to;
	new MaxSkillClient = 0;
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i) && (GetClientTeam(i) == team) && (ClientSkill[i] >= from) && (ClientSkill[i] <= to)) {
			if ((ClientSkill[i] < MaxSkill)) {
				MaxSkillClient = i; 
				MaxSkill = ClientSkill[i];
			}
		}
	}
	return MaxSkillClient;
}


public Action:ShowBalance(client, args) 
{
	if (CurrentGamemodeID != 1) {
		PrintToChat(client, "disabled, gamemode is coop");
		return;
	}
	
	CheckBalance();
	
	if (client > 0) {
		PrintToChat(client, "%t", "info47");
		for (new i = 0; i <= 10; i++) 
			if ((SSkill[i] > 0) || (ISkill[i] > 0)) PrintToChat(client, "\x03%t: %i \x04%i :%t \x01- \x05%s", "info14", SSkill[i], ISkill[i], "info13", GetSkillText(i));
	}	
	else {
		PrintToChatAll("%t", "info47");
		for (new i = 0; i <= 10; i++) 
			if ((SSkill[i] > 0) || (ISkill[i] > 0)) PrintToChatAll("\x03%t: %i \x04%i :%t \x01- \x05%s", "info14", SSkill[i], ISkill[i], "info13", GetSkillText(i));
	}
}

public Action:Command_VoteVeto(client, args)
{
	if (!IsValidPlayer(client)) return Plugin_Handled;
	
	if ( (!IsAdmin(client)) && (VipStatus[client] < 3) ) { //&& (!IsAdminId(client))
		PrintToChat(client, "%t", "info49");
		return Plugin_Handled;
	}
	if ( (IsAdmin(client)) ) { // Permite veto ilimitado para admins.
		for(new i=1;i<=MaxClients;i++)
		if (IsValidPlayer(i)) VoteManagerSetVoted(i, Voted_No);
		PrintToChatAll ("\x03[\x04Admin-Veto\x03] \x05 %s \x03 %t", GetName(client), "pressveto");
		return Plugin_Continue;
		}
		
	new String:SteamID[255];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	LogToFile(logfilepath, "%s(%s) using veto", GetName(client), SteamID);
	
	decl String:query[1024];
	decl String:hname[255];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	GetConVarString(FindConVar("hostname"), hname, sizeof(hname));	
	Format(query, sizeof(query), "INSERT INTO public_logs (steamid, client_name, action, hostname) VALUES ('%s','%s','veto','%s')", SteamID, GetName(client), hname);
	SQL_TQuery(db, NullHandle, query, 0);
	
	for(new i=1;i<=MaxClients;i++)
		if (IsValidPlayer(i)) VoteManagerSetVoted(i, Voted_No);
	
	return Plugin_Handled;
}

public Action:Command_VotePassvote(client, args)
{
	if (!IsValidPlayer(client)) return Plugin_Handled;
	
	if ( (!IsAdmin(client)) && (VipStatus[client] < 4) ) { //&& (!IsAdminId(client))
		PrintToChat(client, "%t", "info50");
		return Plugin_Handled; // Tell sourcemod we are done
	}
	if ( (IsAdmin(client)) ) { // Permite pass ilimitado para admins.
		for(new i=1;i<=MaxClients;i++)
		if (IsValidPlayer(i)) VoteManagerSetVoted(i, Voted_Yes);
		PrintToChatAll ("\x03[\x04Admin-Pass\x03] \x05 %s \x03 %t", GetName(client), "presspass");
		return Plugin_Handled; // Lets further actions happen
	}
	if (AllowPass[client] != 1) {
		PrintToChat(client, "[Anti-Abuse] You can use Pass every 5 minutes.")
		return Plugin_Handled;
	}
	AllowPass[client] = 0;
	CreateTimer(300.0, SetAllowPass, client);
	
	new String:SteamID[255];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	LogToFile(logfilepath, "%s(%s) using pass", GetName(client), SteamID);
	
	decl String:query[1024];
	decl String:hname[255];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	GetConVarString(FindConVar("hostname"), hname, sizeof(hname));		
	
	Format(query, sizeof(query), "INSERT INTO public_logs (steamid, client_name, action, hostname) VALUES ('%s','%s','pass','%s')", SteamID, GetName(client), hname);
	SQL_TQuery(db, NullHandle, query, 0);
	
	for(new i=1;i<=MaxClients;i++)
		if (IsValidPlayer(i)) VoteManagerSetVoted(i, Voted_Yes);
	return Plugin_Handled;
}


public Action:SetAllowPass(Handle:timer, any:client)
{
	AllowPass[client] = 1;
}

stock VoteManagerSetVoted(client, VoteManager_Vote:vote)
{
	switch(vote)
	{
		case Voted_Yes:
		{
			FakeClientCommand(client, "Vote Yes");
		}	
		case Voted_No:
		{
			FakeClientCommand(client, "Vote No");
		}
	}
	
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

public IsNormalPlayer(client)
{
	if (client <= 0) return false;
	if (client > GetMaxClients()) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	
	return true;
}


public Action:cmd_updateskill(client, args)
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			PushIntoArray(toUpdateSkill, i);
			//UpdateClientSkill(i);
		}
	}	
}

public Action:cmd_aim(client, args)
{
	if (!IsValidPlayer(client)) return;
	new iEnt = GetClientAimTarget(client, false);
	decl String:iEntClassName[255];
	if (IsValidEdict(iEnt)) {
		GetEdictClassname(iEnt, iEntClassName, 255);
		PrintToChat(client, "classname: \x05$%s", iEntClassName);
	}
	PrintToChat(client, "minigun count: %i", GetMinigunCount());
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


public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
		
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:AttackerIsBot = GetEventBool(event, "attackerisbot");
	new bool:VictimIsBot = GetEventBool(event, "victimisbot");
	new VictimTeam = -1;
	
	if ( (RoundEnd > 0) || (!IsNormalPlayer(Victim)) ) return;
	
	if ( (IsValidPlayer(Victim)) && (GetClientTeam(Victim) == 2) ) RespawnTime[Victim] = 0;
	
	if ( (Freeze) && (GetClientTeam(Victim) == 3) && (CurrentGamemodeID == 1) )
    	SetEntityMoveType(Victim, MOVETYPE_WALK);
	
	if (Attacker == Victim)	return;
	
	decl String:AttackerName[MAX_LINE_WIDTH];
	//decl String:AttackerID[MAX_LINE_WIDTH];
	//GetClientAuthString(Attacker, AttackerID, sizeof(AttackerID));
	decl String:VictimClass[MAX_LINE_WIDTH];
	new VictimInfType = -1;
	Format(VictimClass, sizeof(VictimClass), "")
	
	if (IsNormalPlayer(Victim)) {
		VictimInfType = GetInfType(Victim);
		
		if (VictimInfType == 1) Format(VictimClass, sizeof(VictimClass), "%t", "class1");
		else if (VictimInfType == 2) Format(VictimClass, sizeof(VictimClass), "%t", "class2");
		else if (VictimInfType == 3) Format(VictimClass, sizeof(VictimClass), "%t", "class3");
		else if (VictimInfType == 4) Format(VictimClass, sizeof(VictimClass), "%t", "class4");
		else if (VictimInfType == 5) Format(VictimClass, sizeof(VictimClass), "%t", "class5");
		else if (VictimInfType == 6) Format(VictimClass, sizeof(VictimClass), "%t", "class6");
		else if (VictimInfType == 7) Format(VictimClass, sizeof(VictimClass), "%t", "class7");
		else if (VictimInfType == 8) Format(VictimClass, sizeof(VictimClass), "%t", "class8");
		
	}
	
	
	if ((IsValidPlayer(Attacker)) && (IsNormalPlayer(Victim))) {
		if ((GetClientTeam(Attacker) == 2) && (GetClientTeam(Victim) == 3)){
			Frags[Attacker] ++;
			UpdateFragsLine();
			for (new i = 1; i <= GetMaxClients(); i++) {
				if ((IsValidPlayer(i)) && (ShowInfo[i] == 1)) {
					PrintToChat(i, "\x04[%t: %i]  \x03%s \x01%t \x05%s (\x04%s)", "info53", GetFragsPos(Attacker), GetRealName(Attacker), "info51", GetRealName(Victim), VictimClass);
					//PrintToChat(i, "\x04[%t: %i]  \x03%s \x01%t \x05%s (\x04%s) \x01,\x03%t: %i", "info53", GetFragsPos(Attacker), GetRealName(Attacker), "info51", VictimClass, GetRealName(Victim),  "info52",  Frags[Attacker]);
				}
			}
			
		}
	}
	
	if ((IsNormalPlayer(Victim)) && (GetClientTeam(Victim) == 2) && (IsNormalPlayer(Attacker)) && (GetClientTeam(Attacker) == 3))
		PrintToChatAll("\x05%t\x01, \x03%s \x01%t \x04%s", "info54", GetRealName(Attacker), "info55", GetRealName(Victim));
	else if ((IsNormalPlayer(Victim)) && (GetClientTeam(Victim) == 2)) 
		PrintToChatAll("\x05%t\x01, %t \x04%s", "info54", "info56", GetRealName(Victim));
}

GetInfType(Client)
{
	new InfType = GetEntProp(Client, Prop_Send, "m_zombieClass");
	return InfType;
}

ResetAllFrags()
{
	for (new i = 1; i <= GetMaxClients(); i++) {	
		Frags[i] = 0;
		Dmg[i] = 0;
		SessionDmg[i] = 0;
		LastDmg[i] = 0;
	}
}

UpdateFragsLine()
{
	ResetExClients();
	for (new i = 1; i <= GetTeamHumanCount(2); i++) 
		FragsLine[i] = GetMaxFragsClient();
	
	ResetExClients();	
	for (new i = 1; i <= GetTeamHumanCount(3); i++) 
		DmgLine[i] = GetMaxDamageClient();	
}

ShowFragsPanel(any: client)
{
	if (!IsValidPlayer(client)) return;
	
	new Handle:TeamPanel = CreatePanel();
	
	decl String:text[255];
	
	SetPanelTitle(TeamPanel, "Current statistic:");
	
	DrawPanelText(TeamPanel, "Survivors frags:");
	for (new i = 1; i <= GetTeamHumanCount(2); i++) {
		if ((IsValidPlayer(FragsLine[i])) && (GetClientTeam(FragsLine[i]) == 2)) {
			Format(text, sizeof(text),"%i %s frags: %i", i, GetRealName(FragsLine[i]), Frags[FragsLine[i]]);
			DrawPanelText(TeamPanel, text);
		}
	}
	
	DrawPanelText(TeamPanel, "Infected damages:");
	for (new i = 1; i <= GetTeamHumanCount(3); i++) {
		if ((IsValidPlayer(DmgLine[i])) && (GetClientTeam(DmgLine[i]) == 3)) {
			Format(text, sizeof(text),"%i %s damage: %i", i, GetRealName(DmgLine[i]), Dmg[DmgLine[i]]);
			DrawPanelText(TeamPanel, text);
		}
	}
	
	DrawPanelText(TeamPanel, " \n");
	DrawPanelItem(TeamPanel, "Закрыть");
	
	SendPanelToClient(TeamPanel, client, PanelFragsHandler, 60);
	CloseHandle(TeamPanel);	
}

public PanelFragsHandler(Handle:menu, MenuAction:action, param1, param2)
{
	
}

public Action:cmd_frags(client, args)
{
	ShowFragsPanel(client);
}

AddToExClients(any: client)
{
	ExClientsCount++;
	ExClients[ExClientsCount] = client;
}

bool:CheckExClient(any: client)
{
	for (new i = 1; i <= ExClientsCount; i++) {
		if (ExClients[i] == client) return true;
	}
	return false;
}

ResetExClients()
{
	for (new i = 1; i <= ExClientsCount; i++) 
		ExClients[i] = 0;
	ExClientsCount = 0;
}

GetMaxFragsClient()
{
	new MaxFrags = 0;
	new MaxFragsClient = 0;
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (GetClientTeam(i) == 2) && (Frags[i] >= MaxFrags) && (!CheckExClient(i))) {
			MaxFragsClient = i;
			MaxFrags = Frags[i];
		}
	}
	
	AddToExClients(MaxFragsClient);
	return MaxFragsClient;
}

GetMaxDamageClient()
{
	new MaxDamage = 0;
	new MaxDamageClient = 0;
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (GetClientTeam(i) == 3) && (Dmg[i] >= MaxDamage) && (!CheckExClient(i))) {
			MaxDamageClient = i;
			MaxDamage = Dmg[i];
		}
	}
	
	AddToExClients(MaxDamageClient);
	return MaxDamageClient;
}

GetFragsPos(any: client)
{
	for (new i = 1; i <= GetTeamMaxHumans(2); i++) {
		if (FragsLine[i] == client) return i;
	}
	return 0;
}

GetDmgPos(any: client)
{
	for (new i = 1; i <= GetTeamMaxHumans(3); i++) {
		if (DmgLine[i] == client) return i;
	}
	return 0;
}

FillAllowArray()
{
	
	decl String:query[255];
	Format(query, sizeof(query), "SELECT login, pass FROM reg_name WHERE status > 0 and login <> '' and pass <> ''");
	SQL_TQuery(db, FillAllowArrayQuery, query, 0);	
}

public FillAllowArrayQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE) 
	{
		LogError("FillAllowArrayQuery Query failed: %s", error);
		return;
	}
	
	decl String:login[255];
	decl String:pass[255];
	
	acCount = 0;
	
	//new bid = GetBizonID();
	//if (bid > 0) PrintToChat(bid, "Запрос белого листа");
	if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, login, sizeof(login));
		SQL_FetchString(hndl, 1, pass, sizeof(pass));
		if ( (sizeof(login) > 255) || (sizeof(pass) > 255) || (acCount >= 255) ) {
			PrintToServer("FillAllowArrayError: login or pass size or acCount > 255");
			return;
		}
		acCount ++;
		Format(acLogin[acCount], 255, "%s", login);
		Format(acPass[acCount], 255, "%s", pass);
		
		//if (bid > 0) PrintToChat(bid, "%s %s", login, pass);
	}
	PrintToChatAll("WhiteList refreshed")
	
}

public Action:cmd_allowed(client, args)
{
	PrintToChat(client, "Распечатка белого списка:");
	for (new i = 1; i <= acCount; i++) {
		PrintToChat(client, "%s %s", acLogin[i], acPass[i]);
	}
}

public Action:cmd_refreshallowed(client, args) 
{
	PrintToChat(client, "WhiteList refresh");
	FillAllowArray();
}

public Action:cmd_name(client, args)
{
	return Plugin_Handled;
	if (!IsValidPlayer(client)) return Plugin_Handled;
	
	if ((AllowName[client] == 0) && (!IsAdmin(client))) {
		PrintToChat(client, "Разрешено только одно изменение имени каждые 5 минут.");
		return Plugin_Handled;
	}
	AllowName[client] = 0;
	CreateTimer(300.0, SetAllowNameTimer, client);
	
	decl String:name[80];
	GetCmdArgString(name, sizeof(name));
	
	SetClientInfo(client, "name", name);	
}

public Action:SetAllowNameTimer(Handle:timer, any:client)
{
	AllowName[client] = 1;
}

FillBadNamesArray()
{
	
	decl String:query[255];
	Format(query, sizeof(query), "SELECT bname FROM badnames");
	SQL_TQuery(db, FillBadNamesArrayQuery, query, 0);	
}

public FillBadNamesArrayQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE) 
	{
		LogError("FillBadNamesArrayQuery Query failed: %s", error);
		return;
	}
	
	decl String:bname[255];
	bnCount = 0;
	if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, bname, sizeof(bname));
		if ( (sizeof(bname) > 255) || (bnCount >= 255) )  {
			PrintToServer("FillBadNamesArrayError: bname or bnCount size > 255");
			return;
		}
		bnCount ++;
		
		Format(BadNames[bnCount], 255, "%s", bname);
	}
	PrintToChatAll("Bad names list is refreshed")
	
}

FillAdminIdsArray()
{
	
	decl String:query[255];
	Format(query, sizeof(query), "select steamid from admin_ids");
	SQL_TQuery(db, FillIsAdminArrayQuery, query, 0);	
}


public FillIsAdminArrayQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE) 
	{
		LogError("FillIsAdminArrayQuery Query failed: %s", error);
		return;
	}
	
	decl String:steamid[255];
	iaCount = 0;
	if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
		if ( (sizeof(steamid) > 255) || (iaCount >= 255) )  {
			PrintToServer("FillIsAdminArrayQuery: steamid or bnCount size > 255");
			return;
		}
		iaCount ++;
		
		Format(AdminIds[iaCount], 255, "%s", steamid);
	}
	PrintToChatAll("Admin ids list is refreshed")
	
}

public Action:cmd_badnames(client, args)
{
	PrintToChat(client, "Распечатка списка Плохих ников:");
	for (new i = 1; i <= bnCount; i++) {
		PrintToChat(client, "%s", BadNames[i]);
	}
}

public Action:cmd_adminids(client, args)
{
	PrintToChat(client, "Распечатка списка steamid админов:");
	for (new i = 1; i <= iaCount; i++) {
		PrintToChat(client, "%s", AdminIds[i]);
	}
}

bool:IsAdminId(any: client)
{
	if (!IsValidPlayer(client)) return false
	
	decl String:SteamID[255];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	for (new j = 1; j <= iaCount; j++) {
		if (StrContains(SteamID, AdminIds[j], false) > -1) {
			return true;
		}
	}
	return false;
}

bool:IsBadName(any: client)
{
	if (!IsValidPlayer(client)) return false
	
	decl String:bname[255];
	Format(bname, sizeof(bname), "%s", GetRealName(client));
	
	for (new j = 1; j <= bnCount; j++) {
		if (StrContains(bname, BadNames[j], false) > -1) {
			return true;
		}
	}
	return false;
}

stock GetHumanCount()
{
	new humans = 0;
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if ((IsClientConnected(i)) && (!IsFakeClient(i)))
		{
			humans++
		}
	}
	
	return humans;
}

public SetScoreTeams()
{
	decl String:CurMap[255];
	GetCurrentMap(CurMap, sizeof(CurMap)) ;
	if (StrContains(CurMap, "m1_", false) > -1) {//&& (ScoreATeam == 0) && (ScoreBTeam == 0)) { 
		ScoreATeam = 2;
		ScoreBTeam = 3;
		RoundCount = 1;
		PrintToChatAll("Команды установлены, раунд первый.");
	}
	
}

public Action:cmd_balance(client, args)
{
	if (CurrentGamemodeID != 1) {
		PrintToChat(client, "disabled, gamemode is coop");
		return;
	}
	
	if (AllowVoteBalance) VoteBalance(client);
	else PrintToChat(client, "Баланс возможен только в начале карты.")
		
}

public Action:cmd_ip(client, args)
{
	//PrintToChatAll("Server IP: %s", hostip);
}

public checkname(any:client)
{
	if (!IsValidPlayer(client)) return;
	
	decl String:query[512];
	Format(query, sizeof(query), "SELECT login, pass, name FROM reg_name WHERE lower(cast(name as char(255))) = lower('%s')", GetName(client));
	SQL_TQuery(db, checknamequery, query, client);
}

public checknamequery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if ((hndl == INVALID_HANDLE) || (!IsValidPlayer(client)))
	{
		LogError("checknamequery Query failed: %s", error);
		return;
	}
	
	decl String:login[255];
	GetClientInfo(client,"login",login,sizeof(login));
	decl String:pass[255];
	GetClientInfo(client,"pass",pass,sizeof(pass));
	
	new String: basepass[255];
	decl String:baselogin[255];
	decl String:basename[255];
	
	if (!SQL_HasResultSet(hndl)) return;
	if (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, baselogin, sizeof(baselogin));
		SQL_FetchString(hndl, 1, basepass, sizeof(basepass));
		
		if ((StrEqual(baselogin, login, false)) && (StrEqual(basepass, pass, false))) return;
		NameDelay[client] = false;
		PrintToChat(client, "\x01%t(\x04%s\x01) %t(\x03sm_enter \"login\" \"pass\"\x01) для его использования.", "authorize8", basename, "authorize9")
		SetClientInfo(client, "name", "synczone.ru");
	}
}

public Action:UserMessageHook(UserMsg:MsgId, Handle:hBitBuffer, const iPlayers[], iNumPlayers, bool:bReliable, bool:bInit) 
{ 
	decl String:strMessage[256]=""; 
	
	// Skip the first two bytes 
	BfReadByte(hBitBuffer); 
	BfReadByte(hBitBuffer); 
	
	// Read the message 
	BfReadString(hBitBuffer, strMessage, sizeof(strMessage), true); 
	//Next BfReadString is prev name, next is current name (changed to) 
	
	//#Cstrike_Name_Change 
	if (StrContains(strMessage, "Name_Change") != -1)  
	{ 
		return Plugin_Handled; 
	} 
	return Plugin_Continue; 
}  

/*
public Action:SayText2Hook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
decl String:message[256], oldname[256], newname[256];

new client = GetClientOfUserId(BfReadShort(bf));
BfReadString(bf, message, sizeof(message));
BfReadString(bf, oldname, sizeof(oldname));
BfReadString(bf, newname, sizeof(newname));

return Plugin_Handled;

if (!IsValidPlayer(client)) return Plugin_Continue;	

if (StrContains(message, "Name_Change") != -1) {
if (StrEqual(oldname, newname))	return Plugin_Handled;

if ((NameDelay[client]) && (!IsAdmin)) {
PrintToChat(client, "Разрешено только одно изменение имени каждую минуту.");
return Plugin_Handled;
}
NameDelay[client] = true;
CreateTimer(60.0, SetNameDelayTimer, client); 
CreateTimer(1.0, CheckNameTimer, client);
}

return Plugin_Continue;

new bid = GetBizonID();
if (bid > 0) {
PrintToChat(bid, "client: %i", client);
PrintToChat(bid, "message: %s", message);
PrintToChat(bid, "oldname: %s", oldname);
PrintToChat(bid, "newname: %s", newname);
}
} 
*/

public Action:CheckNameTimer(Handle:timer, any:client)
{
	checkname(client);
}

public Action:SetNameDelayTimer(Handle:timer, any:client)
{
	NameDelay[client] = false;
}

public Action:CheckPluginsTimer(Handle:timer, any:client)
{
	//ServerCommand("sm plugins refresh");
	new Handle: vmpgh = FindConVar("sv_visiblemaxplayers");
	if (vmpgh == INVALID_HANDLE) vmpg = 24;
	else vmpg = GetConVarInt(vmpgh);
}

public SetNameDelay(bool: val)
{
	for(new i=1; i<=GetMaxClients(); i++)	{
		NameDelay[i] = val;
	}
	
}

public Action:cmd_swapto(client, args)
{
	if (RoundEnd > 0) return Plugin_Handled;
	if (!IsValidPlayer(client)) return Plugin_Handled;
	
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));
	
	if (StrEqual(arg, "1")) ChangePlayerTeam(client, 1);
	else if (StrEqual(arg, "2")) ChangePlayerTeam(client, 2);
	else if (StrEqual(arg, "3")) ChangePlayerTeam(client, 3);
}

public Action:cmd_lockteam(client, args)
{
	ClientTeam[client] = GetClientTeam(client);
	PrintToChat(client, "\x04[Swap] \x01Teams already fixed");
}

public Action:cmd_info(client, args)
{
	if (RoundEnd > 0) return Plugin_Handled;
	
	new hport = GetConVarInt(FindConVar("hostport"));
	new String:hname[255];
	new String:hip[255];
	new String:cmap[255];
	new String:huptime[255];
	GetConVarString(FindConVar("hostname"), hname, sizeof(hname));	
	GetConVarString(FindConVar("ip"), hip, sizeof(hip));	
	GetCurrentMap(cmap, sizeof(cmap)) ;	
	
	new Float:theTime;
	new days, hours, minutes, seconds, milli;
	
	Format(huptime, sizeof(huptime), "%i дней %i часов %i минут", days, hours, minutes);
	
	PrintToServer("%s", hname);
	PrintToServer("192.223.27.143:%i", hport);
	PrintToServer("%s", cmap);
	
	decl String:text[255];
	decl String:IsNoob[255];
	decl String:IsAd[255];
	decl String:pStatus[255];
	decl String:pTeam[255];
	decl String:pName[255];
	decl String:pVictim[255];
	decl String:bN[255];
	
	if (CurrentGamemodeID == 3) {
		PrintToServer("%i / %i", 0, 0);
		PrintToServer("%i / %i", 0, 0);	
	}
	else {
		if (ScoreATeam == 2) {
			//PrintToServer("%i", LastKnownScoreTeamA); 
			//PrintToServer("%i", LastKnownScoreTeamB);
			PrintToServer("%i / %i", L4D_GetTeamScore(1,true),L4D_GetTeamScore(1,false));
			if (CurrentGamemodeID == 1) PrintToServer("%i / %i", L4D_GetTeamScore(2,true),L4D_GetTeamScore(2,false));
			else PrintToServer("%i / %i", 0, 0);
		}
		else {
			//PrintToServer("%i", LastKnownScoreTeamB); 
			//PrintToServer("%i", LastKnownScoreTeamA);
			PrintToServer("%i / %i", L4D_GetTeamScore(2,true),L4D_GetTeamScore(2,false));
			if (CurrentGamemodeID == 1) PrintToServer("%i / %i", L4D_GetTeamScore(1,true),L4D_GetTeamScore(1,false));
			else PrintToServer("%i / %i", 0, 0);
		}
	}
	
	//new Handle:vmph = FindConVar("sv_visiblemaxplayers");
	new vmp = vmpg;
	//if (vmph > 0) vmp = GetConVarInt(vmph); else vmp = 0;
	
	PrintToServer("%i", vmp);
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsClientConnected(i) && !IsFakeClient(i)) {
			if (IsAdmin(i)) { IsAd = "A"; } else { IsAd = "N"; }
			
			pStatus = "X";
			if (!IsClientInGame(i)) pStatus = "X"
			else if ((GetClientTeam(i) == 2) && (IsPlayerIncapped(i))) pStatus = "I"
			else if ((GetClientTeam(i) == 3) && (IsPlayerSpawnGhost(i))) pStatus = "G"
			else if (IsPlayerAlive(i)) Format(pStatus, sizeof(pStatus),"%i", GetClientHealth(i))
			else pStatus = "D";
			
			if (IsBadName(i)) { bN = "1"; } else { bN = "0"; }
			
			pName = GetName(i);
			ReplaceString(pName, sizeof(pName), "[", "|");
			ReplaceString(pName, sizeof(pName), "]", "|");
			ReplaceString(pName, sizeof(pName), "#", "");
			
			decl String:text[255];
			decl String:ctime[255];
			decl String:cteam[255];
			new fr;
			
			if (IsClientInGame(i)) { 
				Format(ctime, sizeof(ctime), "%f", GetClientTime(i)); 
				Format(cteam, sizeof(cteam), "%i", GetClientTeam(i));  
				if (GetClientTeam(i) == 2) fr = Frags[i]; else if (GetClientTeam(i) == 3) fr = Dmg[i];
			}
			else {
				Format(ctime, sizeof(ctime), "0"); 
				Format(cteam, sizeof(cteam), "0"); 
				fr = 0;
			}
			
			Format(text,sizeof(text),"%s#%s#%s#%i#%s#%s#%s#%i#%i#%i", cteam, pName, pStatus, ClientSkill[i], IsAd, bN, ctime, ClientRank[i], VipStatus[i], fr);
			PrintToServer(text);
		}
	}	
	
	
	return Plugin_Handled;
}

public Action:cmd_kickbn(client, args)
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ((IsValidPlayer(i)) && (!IsAdmin(i)) && (IsBadName(i))) {
			KickClient(i, "Bad name");
		}
	}
}

public CPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	
	
	DataMovePanelShowing[param1] = 0;
	if (!IsValidPlayer(param1))  return;
	
	if (param2 == 1) { 
		DoDataMove[param1] = 1;	
		PushIntoArray(toCheckReg, param1);
		//checkreg(param1);
	}
	else { 
		DoDataMove[param1] = 0;	
	}
	
}

public ShowMovePanel(any: client, String: basesteamid[], String: SteamID[])
{
	new Handle:CPanel = CreatePanel();
	decl String:text[255];
	Format(text, sizeof(text), "%t", "info62");
	SetPanelTitle(CPanel, text);
	Format(text, sizeof(text), "%t(%s) %t,", "info57", GetRealName(client), "info58");
	DrawPanelText(CPanel, text);
	Format(text, sizeof(text), "%t %s %t %s", "info59", basesteamid, "info60", SteamID);
	DrawPanelText(CPanel, text);
	Format(text, sizeof(text), "%t", "info61");
	DrawPanelText(CPanel, text);
	Format(text, sizeof(text),"%t", "yes");
	DrawPanelItem(CPanel, text);
	Format(text, sizeof(text),"%t", "no");
	DrawPanelItem(CPanel, text);
	SendPanelToClient(CPanel, client, CPanelHandler, 60);
	CloseHandle(CPanel);
}

public 	GetClientRank(any:client)
{
	//return;
	if (!IsValidPlayer(client)) return;
	
	new bid = GetBizonID();
	new String:SteamID[255] = "";
	decl String:query[1024] = "";
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	ClientRank[client] = 99;
	HLSSkill[client] = 88;
	
	if (bid > 0) PrintToConsole(bid, "GetClientRank client: %i name: %s steamid: %s", client, GetName(client), SteamID);
	
	ReplaceString(SteamID,sizeof(SteamID),"STEAM_0:","");
	ReplaceString(SteamID,sizeof(SteamID),"STEAM_1:","");
	ReplaceString(SteamID,sizeof(SteamID),"STEAM_2:","");
	
	if (StrContains(SteamID, ":", false) == -1) {
		PrintToChat(client, "Invalid SteamID: %s", SteamID);
		return;
	}
	
	//Format(query, sizeof(query), "SELECT p.playerid,p.skill,p.lastname FROM hlstats_Players p LEFT JOIN hlstats_PlayerUniqueIds pid ON p.playerid = pid.playerid WHERE pid.game='l4d2' AND pid.uniqueid= '%s'", SteamID); 
	Format(query, sizeof(query), "SELECT p.skill FROM hlstats_Players p LEFT JOIN hlstats_PlayerUniqueIds pid ON p.playerid = pid.playerid WHERE pid.game='l4d2' AND pid.uniqueid= '%s'", SteamID); 
	
	if (bid > 0) PrintToConsole(bid, "GetClientRank client: %i name: %s query: %s", client, GetName(client), query);
	SQL_TQuery(db2, GetRankHandle, query, client);
}

public GetRankHandle(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("getrankhandle Query failed: %s", error);
		return;
	}
	if (!SQL_HasResultSet(hndl)) return;
	if (SQL_FetchRow(hndl)) {
		HLSSkill[client] = SQL_FetchInt(hndl, 1);
	}
	
	new String:query[1024] = "";
	Format(query, sizeof(query), "SELECT count(*) FROM hlstats_Players WHERE game='l4d2' AND skill >= %i and hideranking = 0 and kills >= 1", HLSSkill[client]);
	
	
	new bid = GetBizonID();
	if (bid > 0) PrintToConsole(bid, "GetRankHandle client: %i name: %s query: %s", client, GetName(client), query);
	SQL_TQuery(db2, GetRankHandle2, query, client);
	
}

public GetRankHandle2(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("getrankhandle2 Query failed: %s", error);
		return;
	}
	if (!SQL_HasResultSet(hndl)) return;
	if (SQL_FetchRow(hndl)) {
		ClientRank[client] = SQL_FetchInt(hndl, 0);
	}
	
	new bid = GetBizonID();
	if (bid > 0) PrintToConsole(bid, "GetRankHandle2 client: %i name: %s clientrank: %i", client, GetName(client), ClientRank[client]);
	
}

RefreshAllClientRank()
{
	return;
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			GetClientRank(i);
		}
		
	}
}

public Action:StartTimer(Handle:timer, any:client)
{
	new ReadyCount = 0, LoadCount = 0;
	new Float: ClientPos[3];
	new Float: distance;
	decl String:text[255];
	
	//new Handle:Panel = CreatePanel();
	//SetPanelTitle(Panel, "Новая карта, ждем всех!");
	
	//Format(text, sizeof(text), "Старт через: %i сек.", TimeToStartLeft);
	//DrawPanelText(Panel, text);
	
	//Format(text, sizeof(text), "Загружаются:");
	//DrawPanelText(Panel, text);
	for(new i=1;i<=GetMaxClients();i++) {
		if ((IsClientConnected(i)) && (!IsFakeClient(i)) && (!IsClientInGame(i))) {
			//Format(text, sizeof(text), "%s", GetName(i));
			//DrawPanelText(Panel, text);
			LoadCount++;
		}
		else 
		if (IsValidPlayer(i)) ReadyCount++;
	}
	
	
	//Format(text, sizeof(text), "Готовы к игре: %i", LoadCount);
	//DrawPanelText(Panel, text);
	
	//for(new i=1;i<=GetMaxClients();i++) {
	//		if ((IsValidPlayer(i)) && (GetClientTeam(i) != 1)) {
	//SendPanelToClient(Panel, i, SPanelHandler, 2);
	PrintHintTextToAll("%t: %i %t: %i %t: %i", "info63", LoadCount, "info64", ReadyCount, "info65", TimeToStartLeft);
	//		}
	//}
	
	//CloseHandle(Panel);
	
	/*if ((StartPos[0] != 0) && (StartPos[0] != 0) && (StartPos[0] != 0)) {
		
		for(new i=1;i<=GetMaxClients();i++) {
			if ((IsValidPlayer(i)) && (GetClientTeam(i) == 2)) {
				GetClientAbsOrigin(i, ClientPos);
				distance = RoundToNearest(GetVectorDistance(ClientPos, StartPos));
				if (FloatCompare(distance, 400) == 1) {
					TeleportEntity(i,StartPos,NULL_VECTOR,NULL_VECTOR);	
					PrintToChatAll("\x04%s \x01возвращен в начало, подождите пока все загрузятся.", GetName(i));
					
				}
			}
			
		}
	}
	*/
	
	if (CurrentGamemodeID == 1 &&
	((TimeToStartLeft == 30) || (LoadCount == 0) || 
	((GetTeamHumanCount(2) == 8) && (GetTeamHumanCount(3) == 8)))
	&& (TimeToStartLeft > 29) ) {
		TimeToStartLeft = 30;
		PrintToChatAll("%t", "info66");
		//directorStart();
		CreateTimer(1.0, SetSpawnTimer, 1);
	}
	
	if (TimeToStartLeft <= 0)  {
						
		PrintToChatAll("\x05%t", "info67");
		PrintHintTextToAll("%t", "info67");
				
		if (ent_safedoor > 0) UnlockTheDoor();		
				
		if (CurrentGamemodeID == 0) {
			PrintToChatAll("Шарманка поперла!");
			
			//SetConVarInt(FindConVar("director_panic_forever"), 1);
			CheatCommand(_, "director_force_panic_event", "");
			
			if (Timer5 == INVALID_HANDLE) Timer5 = CreateTimer(60.0, HordeTimer, INVALID_HANDLE, TIMER_REPEAT);
		}
		else FreezeAll(3, false);
		
		Freeze = false;
								
		return;	
	}
	
	CreateTimer(1.0, StartTimer, INVALID_HANDLE);
	TimeToStartLeft--;
	return;
	
	
}


stock CheatCommand(client = 0, String:command[], String:arguments[]="")
{
	if (!client || !IsClientInGame(client))
	{
		for (new target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target))
			{
				client = target;
				break;
			}
		}
		
		if (!client || !IsClientInGame(client)) return;
	}
	
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

public Action:HordeTimer(Handle:timer, any:client)
{
	if ( (CurrentGamemodeID == 1) || (GetHumanCount() == 0) ) return;
		
	//new dpf = GetConVarInt(FindConVar("director_panic_forever"));
	
	//if (dpf == 1) SetConVarInt(FindConVar("director_panic_forever"), 0);
	//else SetConVarInt(FindConVar("director_panic_forever"), 1);
	
	CheatCommand(_, "director_force_panic_event", "");
	
}

public Action:GetFirstPosTimer(Handle:timer, any:client)
{
	for(new i=1;i<=GetMaxClients();i++) {
		if ((IsValidPlayer(i)) && (GetClientTeam(i) == 2) && (IsPlayerAlive(i)))	{
			GetClientAbsOrigin(i, StartPos);
			return;
		}
	}
	
	//if (Freeze) CreateTimer(1.0, GetFirstPosTimer, INVALID_HANDLE);
	if ( (StartPos[0] == 0) && (StartPos[1] == 0) && (StartPos[2] == 0) ) CreateTimer(1.0, GetFirstPosTimer, INVALID_HANDLE);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	decl String:name[64], dtype[64];
	if (!IsValidEdict(inflictor)) return Plugin_Continue;
	GetEdictClassname(inflictor, name, sizeof(name));
		
	if ( (!IsNormalPlayer(victim)) || (!IsNormalPlayer(attacker)) ) return Plugin_Continue;

    if ((Freeze) && (GetClientTeam(victim) == 2) && (CurrentGamemodeID != 3)) damage = 0.0;	
	
	if ( (VipStatus[victim] > 2) && (GetClientTeam(victim) == 2) && (GetClientTeam(attacker) == 2) && (!StrEqual(name, "entityflame")) && (!StrEqual(name, "inferno")) && (victim != attacker) ) {
	  	  damage = 0.0;
	}
		
	return Plugin_Changed;
}

public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CurrentGamemodeID != 1) return;
	
	new Player = GetClientOfUserId(GetEventInt(event, "userid"));
	if ((Freeze) && (IsNormalPlayer(Player)) && (GetClientTeam(Player) == 3)) {
		if (IsValidPlayer(Player)) 
			PrintToChatAll("\x04%s, \x01%t", GetName(Player), "info68");
			
		SetEntityMoveType(Player, MOVETYPE_NONE);	
			
		//ForcePlayerSuicide(Player);
		//CreateTimer(0.5, ReghostTimer, Player);
		//SetEntData(Player, propinfoghost, 1);
		
	}
	
	
	if ( (IsValidPlayer(Player)) && (GetClientTeam(Player) == 3) && (!IsTank(Player)) && (!IsPlayerBoomer(Player)) ) {
		//new Float: pos[3];
		if (PlayerChangedTeam[Player] == 1) {
			PlayerChangedTeam[Player] = 0;
			return;
		}
		GetClientAbsOrigin(Player, SpawnFixPos[Player]);
		CreateTimer(0.1, SpawnFixTimer, Player);
		
	}
	
}

public Action:SpawnFixTimer(Handle:timer, any:client)
{
	if (!IsValidPlayer(client)) return;
	if (IsTank(client)) return;
	new Float: vel[3];
	vel[0] = 0; vel[1] = 0; vel[2] = 0;
	TeleportEntity(client, SpawnFixPos[client], NULL_VECTOR, vel);
	//SetEntityMoveType(client, MOVETYPE_WALK);
	//PrintToChat(client, "spawnfix %i %i %i", SpawnFixPos[client][0], SpawnFixPos[client][1], SpawnFixPos[client][2]);
}

public SPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{


}

public Action:GetEntitySafeRoomDoor(Handle:timer)
{
	
	decl String:sClassname[] = "prop_door_rotating_checkpoint";
	new door_start = -1;
	new door_goal = -1;	
	new index = -1;
	while((index = FindEntityByClassname(index, sClassname)) != -1){
		if(GetEntProp(index, Prop_Data, "m_bLocked") > 0){
			door_start = index;
		}
		else{
			door_goal = index;
		}
		
		
	}
	
	entDoorStart = door_start;
	entDoorGoal = door_goal;
	
}

public Action:OnRoundStartPostNav(Handle:event, const String:name[], bool:dontBroadcast)
{
	return;
	
	
}


public Action:Event_Player_Use(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Entity = GetEventInt(event, "targetid");
		
	if ((IsValidEntity(Entity)) && (IsNormalPlayer(client)) && (GetClientTeam(client) == 2))
	{
		new String:entname[255];
		if(GetEdictClassname(Entity, entname, sizeof(entname)))
		{			
			if(StrEqual(entname, "prop_door_rotating_checkpoint"))
			{
				if (Freeze) {
					if (entDoorStart != Entity) entDoorStart = Entity;
					CreateTimer(0.5, LockDoorTimer, Entity);
				}
				else if (entDoorStart == Entity)
					CreateTimer(0.5, UnLockDoorTimer, Entity);
			}
		}
	}
	return Plugin_Continue;
	
}

public ControlDoor(Entity, Operation)
{
	if (!IsValidEntity(Entity)) return;
	
	if(Operation == LOCK)
	{
		/* Close and lock */
		//AcceptEntityInput(Entity, "ForceClosed");
		AcceptEntityInput(Entity, "Close");
		AcceptEntityInput(Entity, "Lock");
		SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", LOCK);
	}
	else if(Operation == UNLOCK)
	{
		/* Unlock and open */
		SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);
		AcceptEntityInput(Entity, "Unlock");
		//AcceptEntityInput(Entity, "ForceClosed");
		AcceptEntityInput(Entity, "Open");
		//SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", LOCK);
	}
}

directorStop()
{
	SetConVarInt(FindConVar("director_no_bosses"), 1);
	SetConVarInt(FindConVar("director_no_specials"), 1);
	//SetConVarInt(FindConVar("director_no_mobs"), 1);
	SetConVarInt(FindConVar("director_ready_duration"), 0);
	//SetConVarInt(FindConVar("z_common_limit"), 0);
	//SetConVarInt(FindConVar("z_mega_mob_size"), 1); //why not 0? only Valve knows
			
}

directorStart()
{
	ResetConVar(FindConVar("director_no_bosses"));
	ResetConVar(FindConVar("director_no_specials"));
	//ResetConVar(FindConVar("director_no_mobs"));
	ResetConVar(FindConVar("director_ready_duration"));
	//ResetConVar(FindConVar("z_common_limit"));
	//ResetConVar(FindConVar("z_mega_mob_size"));
}

public Action:LockDoorTimer(Handle:timer, any:ent)
{
	if (!IsValidEntity(ent)) return;
	if ((!Freeze) || (GetEntProp(ent, Prop_Data, "m_bLocked") == 1)) return;
	
	ControlDoor(ent, LOCK);	
	CreateTimer(0.5, LockDoorTimer, ent);

}

public Action:UnLockDoorTimer(Handle:timer, any:ent)
{
	if (!IsValidEntity(ent)) return;
	
	if ((Freeze) || (GetEntProp(ent, Prop_Data, "m_bLocked") == 0)) {
		SetEntProp(ent, Prop_Data, "m_hasUnlockSequence", LOCK);
		AcceptEntityInput(ent, "Lock");
		return;
	}
		
	ControlDoor(ent, UNLOCK);	
	CreateTimer(0.5, UnLockDoorTimer, ent);
	
	AcceptEntityInput(ent, "Kill");
	//DoorUnlocked = true;
	
}

public Action:StartMarkerTimer(Handle:timer, any:val)
{
	StartMarker = val;
}

public Action:ReghostTimer(Handle:timer, any:client)
{
	SetEntData(client, propinfoghost, 1);
}

public Action:cmd_setpsw(client, args)
{
	if (GetCmdArgs() > 1) {
		if (IsValidPlayer(client)) PrintToChat(client, "Wrong arg count");
		else PrintToServer("Wrong arg count");
		return;
	}
	
	if (GetCmdArgs() == 0) {
		if (IsValidPlayer(client)) PrintToChat(client, "Server password is disabled");
		else PrintToServer("Server password is disabled");
		Format(sv_pass, sizeof(sv_pass), "");
		return;
	}
		
	new String: srvpsw[100];
	GetCmdArg(1, srvpsw, sizeof(srvpsw));
		
	if (strlen(srvpsw) > 100) {
		if (IsValidPlayer(client)) PrintToChat(client, "Too long psw, max 100");
		else PrintToServer("Too long psw, max 100");
		return;
	}
	if (strlen(srvpsw) < 3) {
		if (IsValidPlayer(client)) PrintToChat(client, "Too small psw, min 3");
		else PrintToServer("Too small psw, min 3");
		return;
	}

	Format(sv_pass, sizeof(sv_pass), "%s", srvpsw);
	if (IsValidPlayer(client)) PrintToChat(client, "Server password is activated");
	else PrintToServer("Server password is activated");
}

public Action:SetSpawnTimer(Handle:timer, any:val)
{
	for(new i=1;i<=GetMaxClients();i++) {
		if ((IsValidPlayer(i)) && (GetClientTeam(i) == 3))	{
			SetEntData(i, oCurrentStamp, val);
		}
	}
	
}


public Action:RenderClients(Handle:timer, any:client)
{
	for(new i=1;i<=GetMaxClients();i++) {
		if ((IsValidPlayer(i)) && (GetClientTeam(i) == 2) && (IsBadName(i)))	{
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
			SetEntityRenderColor(i, 0, 0, 0, 120);
		}
	}
}

public Action:event_LeftStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsNormalPlayer(client)) return;	
	
	if ( (Freeze) && (CurrentGamemodeID != 3) ) {
		if ( (GetClientTeam(client) == 3) && (IsPlayerAlive(client)) && (!IsPlayerSpawnGhost(client))) ForcePlayerSuicide(client);
		
		if (((StartPos[0] == 0) && (StartPos[1] == 0) && (StartPos[2] == 0)) || (GetClientTeam(client) != 2)) return;
		
		TeleportEntity(client,StartPos,NULL_VECTOR,NULL_VECTOR);	
		PrintToChat(client, "\x04%s \x01%t", GetName(client), "info69");
		
	}
	
}

public Action:event_EnterStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsNormalPlayer(client)) return;	
	
	if (Freeze) {
		if ( (GetClientTeam(client) == 3) && (IsPlayerAlive(client)) && (!IsPlayerSpawnGhost(client))) ForcePlayerSuicide(client);
		
	}
	
}


String: CutSteamID(String:SteamID[])
{
	decl String:rValue[255];
	Format(rValue, sizeof(rValue),"%s",SteamID);
	ReplaceString(rValue,sizeof(rValue),"STEAM_0:","",false);
	ReplaceString(rValue,sizeof(rValue),"STEAM_1:","",false);
	ReplaceString(rValue,sizeof(rValue),"STEAM_2:","",false);
	ReplaceString(rValue,sizeof(rValue),"STEAM_3:","",false);
		
	return rValue;
}

public Action:cmd_refreshreg(client, args)
{
	RefreshAll();
	if (IsValidPlayer(client)) PrintToChat(client, "Refreshed.");
	else PrintToServer("Refreshed");
	
}

public Action:cmd_showinfo(client, args)
{
	if (!IsValidPlayer(client)) return;
	
	if (ShowInfo[client] == 1) {
		ShowInfo[client] = 0;
		PrintToChat(client, "%t", "info70")
	}
	else {
		ShowInfo[client] = 1;
		PrintToChat(client, "%t", "info71")
	}
}


public Action:BalanceTimer(Handle:timer, any:client)
{
	
	new th, wh;
	new s_th, s_wh;
	//PrintToChatAll("BalanceTimer tick");
	if (CurrentGamemodeID == 1)   return Plugin_Stop;
		
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(FindConVar("z_difficulty"), Difficulty, sizeof(Difficulty));
	
	//if (StrEqual(Difficulty, "normal", false)) Format(DiffSQL, sizeof(DiffSQL), "nor");
	//else if (StrEqual(Difficulty, "hard", false)) Format(DiffSQL, sizeof(DiffSQL), "adv");
	//else if (StrEqual(Difficulty, "impossible", false)) Format(DiffSQL, sizeof(DiffSQL), "exp");
	//else return;
		
	
	new bl1, bl2, bl3, bl4, bl5, bl6, bl7;
	new st_min, st_max;
	new mms_min, mms_max;
	new ms;
	
	new s_bl1, s_bl2, s_bl3, s_bl4, s_bl5, s_bl6, s_bl7;
	new s_st_min, s_st_max;
	new s_mms_min, s_mms_max;
	new s_ms;
	
	new t2count = GetT2Count();
	new hCount = GetTeamNormalCount(2); 
	new Float: prc;
	new tHPmult = 1;
	
	
	prc = FloatMul(FloatDiv(float(t2count), float(hCount)), 100.0);
	if (FloatCompare(prc, 50.0) == 1) tHPmult = 2; else tHPmult = 1;
	
	ms = GetConVarInt(FindConVar("l4d_infectedbots_max_specials"));
	
	mms_min  = GetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"));
	mms_max  = GetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"));
		
	bl1 = GetConVarInt(FindConVar("l4d_infectedbots_boomer_limit"));
	bl2 = GetConVarInt(FindConVar("l4d_infectedbots_charger_limit"));
	bl3 = GetConVarInt(FindConVar("l4d_infectedbots_hunter_limit"));
	bl4 = GetConVarInt(FindConVar("l4d_infectedbots_jockey_limit"));
	bl5 = GetConVarInt(FindConVar("l4d_infectedbots_smoker_limit"));
	bl6 = GetConVarInt(FindConVar("l4d_infectedbots_spitter_limit"));
	bl7 = GetConVarInt(FindConVar("l4d_infectedbots_tank_limit"));
	
	st_min = GetConVarInt(FindConVar("l4d_infectedbots_spawn_time_min"));
	st_max = GetConVarInt(FindConVar("l4d_infectedbots_spawn_time_max"));

	th = GetConVarInt(FindConVar("z_tank_health"));	
	wh = GetConVarInt(FindConVar("z_witch_health"));
	
	new TankBonus = 0, s_ms_bonus = 0, s_st_min_bonus = 0; s_st_min_bonus = 0;
	s_st_min_bonus = GetMastersCount(5);
	if (GetMastersCount(5) > 3) { TankBonus = 0; s_ms_bonus = 1; }
 	if (GetMastersCount(5) > 6) { TankBonus = 1; s_ms_bonus = 2; }
	
	
	//GetConVarInt(FindConVar("l4d_infectedbots_max_specials"));
	
	new hc = GetTeamHumanCount(2);// GetHumanCount();
	if (hc > 4) s_ms = hc; else s_ms = 4;
	s_ms = s_ms + s_ms_bonus;
	if (hc <= 4) {
		s_bl1 = 1, s_bl2 = 1, s_bl3 = 1, s_bl4 = 1, s_bl5 = 1, s_bl6 = 1, s_bl7 = 1;
		s_st_min = 20 - s_st_min_bonus, s_st_max = 30;
		s_th = 5000, s_wh = 1000;
		s_mms_min = 90, s_mms_max = 180;
	}
	else if (hc == 5) {
		s_bl1 = 2, s_bl2 = 1, s_bl3 = 1, s_bl4 = 1, s_bl5 = 1, s_bl6 = 1, s_bl7 = 1;
		s_st_min = 20 - s_st_min_bonus, s_st_max = 30;
		s_th = 6000, s_wh = 1000;
		s_mms_min = 90, s_mms_max = 170;
	}
	else if (hc == 6) {
		s_bl1 = 2, s_bl2 = 1, s_bl3 = 2, s_bl4 = 1, s_bl5 = 1, s_bl6 = 1, s_bl7 = 1;
		s_st_min = 20 - s_st_min_bonus, s_st_max = 30;
		s_th = 7000, s_wh = 1500;
		s_mms_min = 90, s_mms_max = 160;
	}
	else if (hc == 7) {
		s_bl1 = 2, s_bl2 = 1, s_bl3 = 2, s_bl4 = 2, s_bl5 = 1, s_bl6 = 2, s_bl7 = 2;
		s_st_min = 20 - s_st_min_bonus, s_st_max = 30;
		s_th = 8000, s_wh = 1800;
		s_mms_min = 90, s_mms_max = 150;
	}
	else if (hc == 8) {
		s_bl1 = 2, s_bl2 = 1, s_bl3 = 2, s_bl4 = 2, s_bl5 = 2, s_bl6 = 2, s_bl7 = 2+TankBonus;
		s_st_min = 20 - s_st_min_bonus, s_st_max = 30;
		s_th = 6000, s_wh = 3000;
		s_mms_min = 90, s_mms_max = 140;
	}
	else if (hc == 9) {
		s_bl1 = 2, s_bl2 = 2, s_bl3 = 2, s_bl4 = 2, s_bl5 = 2, s_bl6 = 2, s_bl7 = 2+TankBonus;
		s_st_min = 19 - s_st_min_bonus, s_st_max = 29;
		s_th = 7000, s_wh = 3300;
		s_mms_min = 90, s_mms_max = 130;
	}
	else if (hc == 10) {
		s_bl1 = 3, s_bl2 = 2, s_bl3 = 3, s_bl4 = 2, s_bl5 = 2, s_bl6 = 2, s_bl7 = 2+TankBonus;
		s_st_min = 18 - s_st_min_bonus, s_st_max = 28;
		s_th = 8000, s_wh = 3500;
		s_mms_min = 80, s_mms_max = 110;
	}
	else if (hc == 11) {
		s_bl1 = 3, s_bl2 = 2, s_bl3 = 3, s_bl4 = 3, s_bl5 = 2, s_bl6 = 2, s_bl7 = 2+TankBonus;
		s_st_min = 17 - s_st_min_bonus, s_st_max = 27;
		s_th = 6000, s_wh = 4000;
		s_mms_min = 70, s_mms_max = 100;
	}
	else if (hc == 12) {
		s_bl1 = 3, s_bl2 = 2, s_bl3 = 3, s_bl4 = 3, s_bl5 = 3, s_bl6 = 2, s_bl7 = 2+TankBonus;
		s_st_min = 16 - s_st_min_bonus, s_st_max = 26;
		s_th = 7000, s_wh = 4100;
		s_mms_min = 60, s_mms_max = 90;
	}
	else if (hc == 13) {
		s_bl1 = 3, s_bl2 = 2, s_bl3 = 3, s_bl4 = 3, s_bl5 = 3, s_bl6 = 3, s_bl7 = 2+TankBonus;
		s_st_min = 15 - s_st_min_bonus, s_st_max = 25;
		s_th = 8000, s_wh = 4200;
		s_mms_min = 50, s_mms_max = 80;
	}
	else if (hc == 14) {
		s_bl1 = 3, s_bl2 = 3, s_bl3 = 3, s_bl4 = 3, s_bl5 = 3, s_bl6 = 3, s_bl7 = 3+TankBonus;
		s_st_min = 14 - s_st_min_bonus, s_st_max = 24;
		s_th = 8000, s_wh = 4300;
		s_mms_min = 50, s_mms_max = 80;
	}
	else if (hc == 15) {
		s_bl1 = 4, s_bl2 = 3, s_bl3 = 3, s_bl4 = 3, s_bl5 = 3, s_bl6 = 3, s_bl7 = 3+TankBonus;
		s_st_min = 13 - s_st_min_bonus, s_st_max = 23;
		s_th = 9000, s_wh = 4500;
		s_mms_min = 50, s_mms_max = 80;
	}
	else if (hc == 16) {
		s_bl1 = 4, s_bl2 = 3, s_bl3 = 4, s_bl4 = 3, s_bl5 = 3, s_bl6 = 3, s_bl7 = 3+TankBonus;
		s_st_min = 12 - s_st_min_bonus, s_st_max = 22;
		s_th = 10000, s_wh = 4600;
		s_mms_min = 50, s_mms_max = 80;
	}
	else if (hc == 17) {
		s_bl1 = 4, s_bl2 = 3, s_bl3 = 4, s_bl4 = 4, s_bl5 = 3, s_bl6 = 3, s_bl7 = 4+TankBonus;
		s_st_min = 11 - s_st_min_bonus, s_st_max = 21;
		s_th = 9000, s_wh = 4700;
		s_mms_min = 50, s_mms_max = 80;
	}
	else if (hc == 18) {
		s_bl1 = 4, s_bl2 = 3, s_bl3 = 4, s_bl4 = 4, s_bl5 = 4, s_bl6 = 4, s_bl7 = 4+TankBonus;
		s_st_min = 10 - s_st_min_bonus, s_st_max = 20;
		s_th = 10000, s_wh = 4800;
		s_mms_min = 50, s_mms_max = 80;
	}
	else if (hc == 19) {
		s_bl1 = 4, s_bl2 = 3, s_bl3 = 4, s_bl4 = 4, s_bl5 = 4, s_bl6 = 4, s_bl7 = 4+TankBonus;
		s_st_min = 10 - s_st_min_bonus, s_st_max = 20;
		s_th = 11000, s_wh = 4900;
		s_mms_min = 40, s_mms_max = 80;
	}
	else if (hc == 20) {
		s_bl1 = 4, s_bl2 = 4, s_bl3 = 4, s_bl4 = 4, s_bl5 = 4, s_bl6 = 4, s_bl7 = 4+TankBonus;
		s_st_min = 10 - s_st_min_bonus, s_st_max = 20;
		s_th = 12000, s_wh = 5000;
		s_mms_min = 30, s_mms_max = 80;
	}
	else if (hc > 20) {
		s_bl1 = 4, s_bl2 = 4, s_bl3 = 4, s_bl4 = 4, s_bl5 = 4, s_bl6 = 4, s_bl7 = 5;
		s_st_min = 10 - s_st_min_bonus, s_st_max = 20;
		s_th = 12000, s_wh = 5000;
		s_mms_min = 20, s_mms_max = 80;
	}
	
	if (CurrentGamemodeID == 3) {
		//s_st_min = s_st_min - 10;
		//s_st_max = s_st_max - 10;
		if (s_st_min < 1) s_st_min = 1;
		if (s_st_max < 2) s_st_max = 2;
		/*
		s_bl1 = s_bl1 + s_bl1;
		s_bl2 = s_bl2 + s_bl2;
		s_bl3 = s_bl3 + s_bl3; 
		s_bl4 = s_bl4 + s_bl4; 
		s_bl5 = s_bl5 + s_bl5; 
		s_bl6 = s_bl6 + s_bl6;
		s_bl7 = s_bl7 + s_bl7;
		*/
	}
	
	if (CurrentGamemodeID != 3) {
		if (StrEqual(Difficulty, "hard", false)) s_th = s_th - 5000;
	//	else if (StrEqual(Difficulty, "impossible", false)) s_th = s_th - 8000;
	}

	//PrintToChatAll("hc: %i  bl1: %i  s_bl1: %i",hc, bl1, s_bl1);
	
	if (bl1 != s_bl1) SetConVarInt(FindConVar("l4d_infectedbots_boomer_limit"), s_bl1);
	if (bl2 != s_bl2) SetConVarInt(FindConVar("l4d_infectedbots_charger_limit"), s_bl2);
	if (bl3 != s_bl3) SetConVarInt(FindConVar("l4d_infectedbots_hunter_limit"), s_bl3);
	if (bl4 != s_bl4) SetConVarInt(FindConVar("l4d_infectedbots_jockey_limit"), s_bl4);
	if (bl5 != s_bl5) SetConVarInt(FindConVar("l4d_infectedbots_smoker_limit"), s_bl5);
	if (bl6 != s_bl6) SetConVarInt(FindConVar("l4d_infectedbots_spitter_limit"), s_bl6);
	if (bl7 != s_bl7) SetConVarInt(FindConVar("l4d_infectedbots_tank_limit"), s_bl7);
	
	if (st_min != s_st_min) SetConVarInt(FindConVar("l4d_infectedbots_spawn_time_min"), s_st_min);
	if (st_max != s_st_max) SetConVarInt(FindConVar("l4d_infectedbots_spawn_time_max"), s_st_max);
	
	if (tHPmult == 2) s_th = s_th + s_th;
	if (th != s_th) SetConVarInt(FindConVar("z_tank_health"), s_th);	
	if (wh != s_wh) SetConVarInt(FindConVar("z_witch_health"), s_wh);
	
	if (mms_min != s_mms_min) {
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), s_mms_min);
		SetConVarInt(FindConVar("z_mega_mob_spawn_min_interval"), s_mms_min);
	}
	if (mms_max != s_mms_max) {
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), s_mms_max);
		SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), s_mms_max);
	}
	
	if (ms != s_ms) SetConVarInt(FindConVar("l4d_infectedbots_max_specials"), s_ms);
	
}

public Action:cmd_evilmove(client, args) 
{
	if ((!IsValidPlayer(client)) || (RoundEnd > 0)) return;

	if (CurrentGamemodeID != 1) {
		PrintToChat(client, "disabled, gamemode is coop");
		return;
	}
	
	decl String: SteamID[255];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	new MoveTo = 0;
	new sClient = 0;
	
	if (StrContains(SteamID, "13797426") != -1) sClient = GetClientIDBySteamID("61368501"); 
	else if (StrContains(SteamID, "61368501") != -1) sClient = GetClientIDBySteamID("13797426");
	else if (StrContains(SteamID, "45695652") != -1) {
		sClient = GetClientIDBySteamID("13797426");
		if (sClient == 0) sClient = GetClientIDBySteamID("61368501");
	}
	else 
	{
		PrintToChat(client, "sorry, this is private cmd");
		return;
	}
	
	
	if (IsValidPlayer(sClient)) MoveTo = GetClientTeam(sClient);
	else {
		PrintToChat(client, "пичаль, Ваш возлюбленный не найден, некуда переходить");
		return;
	}
	
	
	if (GetClientTeam(client) == MoveTo) {
		PrintToChat(client, "Вы уже в той же команде.");
		return;
	}
	
	if (MoveTo == 1) {
		PrintToChat(client, "Ваш друг в зрителях.")
		return;
	}
	 
	ClientWish[client] = 0;
	ClientTeam[client] = MoveTo;
	
	if (GetTeamHumanCount(MoveTo) < GetTeamMaxHumans(2)) {
		ChangePlayerTeam(client, MoveTo);
		PrintToChat(client, "Вы перешли в команду к другу.");
	}
	else {
		ForceMoveTo(client, MoveTo);
	}
}

GetClientIDBySteamID(String: SteamID[])
{
	decl String: cSteamID[255];
	for(new i=1;i<=GetMaxClients();i++) {	
		if (IsValidPlayer(i)) {
			GetClientAuthString(i, cSteamID, sizeof(cSteamID));
			if (StrContains(cSteamID, SteamID) != -1) return i;
		}
	}
	
	return 0;
}

public ForceMoveTo(any:client, team)
{
	if (RoundEnd > 0) return;
	new rID = 0;
		
	for (new i = 1; ((i <= GetMaxClients()) && (rID == 0)) ; i++) {
		if ((IsValidPlayer(i)) && (IsBadName(i)) && (GetClientTeam(i) != 1) && (!IsAdmin(i)) && (VipStatus[i] == 0) && (GetClientTeam(i) == team))
			rID = i;
	}
	
	if (rID == 0) {
		for (new i = 1; ((i <= GetMaxClients()) && (rID == 0)); i++) {
			if ((IsValidPlayer(i)) && (ClientSkill[i] >= 8) && (GetClientTeam(i) != 1) && (!IsAdmin(i)) && (VipStatus[i] == 0) && (GetClientTeam(i) == team))
				rID = i;
		}
	}
	if (rID == 0) {
		for (new i = 1; ((i <= GetMaxClients()) && (rID == 0)); i++) {
			if ((IsValidPlayer(i)) && ((ClientSkill[i] >= 5) || (ClientSkill[i] == 0)) && (GetClientTeam(i) != 1) && (!IsAdmin(i)) && (VipStatus[i] == 0) && (GetClientTeam(i) == team))
				rID = i;
		}
	}
	
	if (rID == 0) {
		for (new i = 1; ((i <= GetMaxClients()) && (rID == 0)); i++) {
			if ((IsValidPlayer(i)) && ((ClientSkill[i] >= 8) || ClientSkill[i] == 0) && (GetClientTeam(i) != 1) && (!IsAdmin(i)) && (VipStatus[i] == 0) && (GetClientTeam(i) == team))
				rID = i;
		}
	}
	if (rID == 0) {
		for (new i = 1; ((i <= GetMaxClients()) && (rID == 0)); i++) {
			if ((IsValidPlayer(i)) && ((ClientSkill[i] >= 5) || (ClientSkill[i] == 0)) && (GetClientTeam(i) != 1) && (!IsAdmin(i)) && (VipStatus[i] == 0) && (GetClientTeam(i) == team))
				rID = i;
		}
	}
	
	if (IsValidPlayer(rID)) {
		
		new rIDTeam = GetClientTeam(rID);
		
		ClientWish[rID] = 0;
		ClientTeam[rID] = 0;
		ClientWish[client] = 0;
		ClientTeam[client] = rIDTeam;
		
		ChangePlayerTeam(rID, 1);
		ChangePlayerTeam(client, rIDTeam);
				
		PrintToChat(rID, "\x01%t \x05VIP \x01%t \x05VIP \x01%t \x03%t", "vip1", "vip2", "vip3", "siteurl");
				
		if (rIDTeam == 2) rIDTeam = 3; else rIDTeam = 2;
		ClientWish[rID] = rIDTeam;
		ClientTeam[rID] = rIDTeam;
		ChangePlayerTeam(rID, rIDTeam);
		
	}
	else PrintToChat(client, "\x05%t", "vip4");
}

public Action:StopBalance(Handle:timer, any:client)
{
	AllowVoteBalance = false;
}

public Action:cmd_ftrigger(client, args)
{
	if (!IsValidPlayer(client)) return;
	
	new fTrigger;
	fTrigger = FindEntityByClassname(-1, "trigger_finale");
	
	if (IsValidEntity(fTrigger)) {
		PrintToChat(client, "fTrigger found");
		AcceptEntityInput(fTrigger, "AdvanceFinaleState");
		PrintToChat(client, "AdvanceFinaleState");
	}
	else PrintToChat(client, "fTrigger not found");
}

public OnFinaleStart(const String:output[], caller, activator, Float:delay)
{
	PrintToChatAll("Final started. Happy zombie hunting and fresh brains for zombies!");
	
	if (Timer3 == INVALID_HANDLE) Timer3 = CreateTimer(300.0, FinaleTriggerTimer, 0, TIMER_REPEAT);
}

public Action:FinaleTriggerTimer(Handle:timer, any:client)
{

	new fTrigger = -1;
	
	decl String:CurMap[255];
	GetCurrentMap(CurMap, sizeof(CurMap)) ;
		
	for (new i = 1; i <= GetMaxClients(); i++) 
		if (IsTank(i)) return;
		
	if (StrEqual(CurMap,"c1m4_atrium")) return;
	//if ( (CurrentGamemodeID != 1) && ( (!StrEqual(CurMap,"c2m5_concert")) && (!StrEqual(CurMap,"c8m5_rooftop"))  
	//&& (!StrEqual(CurMap,"с10м5_houseboat")) ) )
	//  return;
		
	
	while ((fTrigger = FindEntityByClassname(fTrigger, "trigger_finale")) != -1) {
		
		if (IsValidEntity(fTrigger)) {
			PrintToChatAll("fTrigger found");
			AcceptEntityInput(fTrigger, "AdvanceFinaleState");
			PrintToChatAll("AdvanceFinaleState");
		}
		else PrintToChatAll("fTrigger not found");
	}
}

GetT2Count()
{
	new t2count = 0;
	new wep = -1; 
	new String:class[40];
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsNormalPlayer(i)) {
			new wep = GetPlayerWeaponSlot(i, 0);
			if (wep != -1) {
				GetEdictClassname(wep, class, sizeof(class));
				if (StrContains(class, "rifle", false) != -1)
					t2count ++;
				else	
				if ( (StrContains(class, "grenade", false) != -1) || (StrContains(class, "sniper", false) != -1) )
					t2count+=3;
			}
		}
	}
	
	return t2count;
}

public GoAwayFromKeyboard(client)
{
	if (!client || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) return Plugin_Handled;

	FakeClientCommand(client, "go_away_from_keyboard");

	if (GetClientTeam(client) == 1)
		PrintToChatAll("%N has become a spectator.", client);

	return Plugin_Handled;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.5, RoundStartInitTimer);	
	
}

public Action:RoundStartInitTimer(Handle:timer)
{
  RoundStartInit();	
}


public RoundStartInit()
{
	if (RoundStarted) return;

	PrintToChatAll("RoundStartInit");
	LogToFile(logfilepath, "RoundStartInit: start");
		
	RoundStarted = true;
	RoundEnd = 0;	
	
	AllowBalance = false;
	AllowVoteBalance = true;
	CreateTimer(200.0, StopBalance, 0);
	
	LogToFile(logfilepath, "RoundStartInit: 1");
		
	if (CurrentGamemodeID == 1) CreateTimer(60.0, AllowBalanceTimer, INVALID_HANDLE);
	
	CheckSafeRoomDoor();
	
	if (RoundNum > 1) {
		
		LogToFile(logfilepath, "RoundStartInit: 2");
		
		if (ent_safedoor > 0) LockTheDoor();		
	
		//if (CurrentGamemodeID != 3) {
			DoorUnlocked = false;
			Freeze = true;
			//FreezeAll(3, true);
			TimeToStartLeft = 20;
			CreateTimer(1.0, StartTimer, INVALID_HANDLE);
			//directorStop();
		//}
		//else Freeze = false;
		LogToFile(logfilepath, "RoundStartInit: 3");
	}
	
	LogToFile(logfilepath, "RoundStartInit: 4");
	
	ResetAllFrags();
	SetNameDelay(false);
	CreateTimer(2.0, CheckPluginsTimer, 0);
	
	LogToFile(logfilepath, "RoundStartInit: 5");
	
	
	if (Timer1 == INVALID_HANDLE) Timer1 = CreateTimer(2.0, Timer_SpecPanel, INVALID_HANDLE, TIMER_REPEAT);	
	if (Timer2 == INVALID_HANDLE) Timer2 = CreateTimer(120.0, ShowHint, INVALID_HANDLE, TIMER_REPEAT);	
	if (Timer4 == INVALID_HANDLE) Timer4 = CreateTimer(60.0, VoteMapTimer, INVALID_HANDLE, TIMER_REPEAT);	
	if (Timer6 == INVALID_HANDLE) Timer6 = CreateTimer(1.0, CheckRegArrayTimer, INVALID_HANDLE, TIMER_REPEAT);
	if (Timer7 == INVALID_HANDLE) Timer7 = CreateTimer(300.0, AdminTimeTimer, INVALID_HANDLE, TIMER_REPEAT);
	
	HookEntityOutput("trigger_finale","FinaleStart",OnFinaleStart);	
	
	LogToFile(logfilepath, "RoundStartInit: end");
}

GetGamemodeID(const String:Gamemode[])
{
	if (StrEqual(Gamemode, "coop", false))
		return GAMEMODE_COOP;
	else if (StrEqual(Gamemode, "survival", false))
		return GAMEMODE_SURVIVAL;
	else if (StrEqual(Gamemode, "versus", false))
		return GAMEMODE_VERSUS;
	else if (StrEqual(Gamemode, "teamversus", false))
		return GAMEMODE_VERSUS;
	else if (StrEqual(Gamemode, "scavenge", false))
		return GAMEMODE_SCAVENGE;
	else if (StrEqual(Gamemode, "teamscavenge", false)) 
		return GAMEMODE_SCAVENGE;
	else if (StrEqual(Gamemode, "realism", false))
		return GAMEMODE_REALISM;
	else if (StrEqual(Gamemode, "mutation12", false))
		return GAMEMODE_REALISMVERSUS;
	else if (StrEqual(Gamemode, "teamrealismversus", false))
		return GAMEMODE_REALISMVERSUS;
	else if (StrContains(Gamemode, "mutation", false) == 0)
		return GAMEMODE_MUTATIONS;

	return GAMEMODE_UNKNOWN;
}

public action_GamemodeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_Gamemode)
	{
		GetConVarString(cvar_Gamemode, CurrentGamemode, sizeof(CurrentGamemode));
		CurrentGamemodeID = GetCurrentGamemodeID();
		//SetCurrentGamemodeName();
	}
}

GetCurrentGamemodeID()
{
	new String:CurrentMode[16];
	GetConVarString(cvar_Gamemode, CurrentMode, sizeof(CurrentMode));

	return GetGamemodeID(CurrentMode);
}

public Action:RegConsoleCmdTimer(Handle:timer, any:client)
{
					
	RegAdminCmd("sm_setteams", SetTeams_cmd, ADMFLAG_CHAT, "");
	RegAdminCmd("sm_setbalance", SetBalance, ADMFLAG_CHAT, "sm_setbalance");
	RegAdminCmd("sm_teambalance", cmd_teambalance, ADMFLAG_ROOT, "sm_teambalance");
	
	RegAdminCmd("sm_info", cmd_info, ADMFLAG_BAN, "sm_info");
	RegAdminCmd("sm_kickbn", cmd_kickbn, ADMFLAG_BAN, "sm_kickbn");
	RegAdminCmd("sm_allowed", cmd_allowed, ADMFLAG_ROOT, "sm_allowed");
	RegAdminCmd("sm_badnames", cmd_badnames, ADMFLAG_ROOT, "sm_badnames");
	RegAdminCmd("sm_adminids", cmd_adminids, ADMFLAG_ROOT, "sm_adminids");
	RegAdminCmd("sm_lockteam", cmd_lockteam, ADMFLAG_BAN, "sm_lockteam");
	RegAdminCmd("sm_swapto", cmd_swapto, ADMFLAG_BAN, "sm_swapto");
	RegAdminCmd("sm_refreshallowed", cmd_refreshallowed, ADMFLAG_ROOT, "sm_refreshallowed");
	RegAdminCmd("sm_aim", cmd_aim, ADMFLAG_ROOT, "sm_aim");
	RegAdminCmd("sm_ftrigger", cmd_ftrigger, ADMFLAG_CHAT, "");
	RegAdminCmd("sm_stoprp", StopRP, ADMFLAG_CHAT, "");
	RegAdminCmd("sm_showtarray", ShowTArray_cmd, ADMFLAG_CHAT, "");
	RegAdminCmd("sm_saveteams", SaveTeams_cmd, ADMFLAG_CHAT, "");
	RegAdminCmd("sm_updateskill", cmd_updateskill, ADMFLAG_CHAT, "sm_updateskill");
	RegAdminCmd("sm_refreshreg", cmd_refreshreg, ADMFLAG_CHAT, "");
	RegAdminCmd("sm_scale", cmd_scale, ADMFLAG_GENERIC, "");
	RegAdminCmd("sm_setpsw", cmd_setpsw, ADMFLAG_GENERIC, "");
	RegAdminCmd("sm_rp", ReloadPlugins, ADMFLAG_ROOT, "");
	RegAdminCmd("sm_steamidlist", steamidlist_cmd, ADMFLAG_CHAT, "");
	
	RegAdminCmd("sm_getscore", getscore_cmd, ADMFLAG_CHAT, "");
	RegAdminCmd("sm_setscore", setscore_cmd, ADMFLAG_CHAT, "");
	
	
	RegConsoleCmd("sm_showbalance", ShowBalance, "sm_showbalance");
	RegConsoleCmd("sm_evilmove", cmd_evilmove, "sm_evilmove");
	RegConsoleCmd("sm_balance", cmd_balance, "sm_balance");
	
	RegConsoleCmd("sm_pass", Command_VotePassvote, "Pass a current vote");
	RegConsoleCmd("sm_veto", Command_VoteVeto, "Veto a current vote");
	RegConsoleCmd("sm_frags", cmd_frags, "sm_frags");
	RegConsoleCmd("sm_ip", cmd_ip, "sm_ip");
	RegConsoleCmd("sm_enter", cmd_Enter, "sm_enter \"login\" \"password\"");
	RegConsoleCmd("sm_reg", cmd_Reg, "sm_reg \"login\" \"password\"");
	RegConsoleCmd("sm_setmsg", cmd_setmsg, "sm_setmsg \"ваше сообщение при входе\"");
	RegConsoleCmd("sm_name", cmd_name, "sm_name");
	RegConsoleCmd("sm_ran", cmd_myrank, "sm_myrank");
	RegConsoleCmd("say", cmd_Say);
	RegConsoleCmd("say_team", cmd_Say);
	RegConsoleCmd("sm_setskill", cmd_SetSkill);
	RegConsoleCmd("sm_showskills", cmd_ShowSkills);
	RegConsoleCmd("callvote", Callvote_Handler);
	RegConsoleCmd("sm_showinfo", cmd_showinfo);	
	RegConsoleCmd("sm_menu", cmd_menu);	
	RegConsoleCmd("sm_nohumantime", cmd_shownohumantime);	
	RegConsoleCmd("sm_warning", cmd_warning);	
	RegAdminCmd("sm_force", cmd_force, ADMFLAG_CHAT, "sm_force door at start");
}

public Action:VoteMapTimer(Handle:timer, any:client)
{
	if (VoteMapTime > 0) {
		VoteMapTime --;
		if (VoteMapTime <= 0) PrintToChatAll("Mapvote Unlocked!.");
	}
	
	if (GetHumanCount() == 0) NoHumanTime++; else NoHumanTime = 0;
	
	if (NoHumanTime >= 10) // Tiempo en minutos para detectar humanos en el juego antes de resetear server.
	{
		NoHumanTime = 0;
		LogToFile(logfilepath, "NoHumanTime >= 10, restarting");
		PrintToServer("Reseteando la pesca");
		ServerCommand("sm_map c5m1_waterfront");
		//ServerCommand("_restart");
	}
	/*
	CurrentGamemodeID = GetCurrentGamemodeID();
	if ( ((hostport == hostport_xtremecoop1) || (hostport == hostport_xtremecoop2))&& (CurrentGamemodeID != 0) ) {
		LogToFile(logfilepath, "1 wrong gamemode, restarting(hostport %i  CurrentGamemodeID: %i", hostport, CurrentGamemodeID);
		ServerCommand("sm_cvar mp_gamemode coop");
		//ServerCommand("_restart");
		ServerCommand("sm_map c5m1_waterfront");
	}
	else if ( ((hostport == hostport_xtremeversus1)	 || (hostport == hostport_xtremeversus2) ) && (CurrentGamemodeID != 1) ) {
		LogToFile(logfilepath, "2 wrong gamemode, restarting(hostport_vers1: %i  hostport %i  CurrentGamemodeID: %i", hostport_xtremeversus1, hostport, CurrentGamemodeID);
		ServerCommand("sm_cvar mp_gamemode versus");
		PrintToServer("reseteando la pesca");
		ServerCommand("sm_map c5m1_waterfront");
		//ServerCommand("_restart");
	}
	// Restart timer para survival gamemode
	//else if (CurrentGamemodeID != 3) {
	//	LogToFile(logfilepath, "3 wrong gamemode, restarting(hostport_vers1: %i  hostport %i  CurrentGamemodeID: %i", hostport_vers1, hostport, CurrentGamemodeID);
	//	ServerCommand("_restart");
	//}
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ( (IsValidPlayer(i)) && (GetClientTeam(i) == 1) ) 
		 PrintHintText(i, "%t", "info72"); //Mapas de ampliacion y bla bla !!
	}*/
}

bool:IsAllIncapped()
{
	new NotIncapCount = 0;
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsNormalPlayer(i)) {
			if ((GetClientTeam(i) == 2) && (!IsPlayerIncapped(i)) && (IsPlayerAlive(i))) {
				NotIncapCount++;
			}
		}
	}
	
	if (NotIncapCount > 1) return false;
	else return true;

}

public Action:event_MapTransition(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundEndProc();
}

DisplayGameMenu(client)
{
	new String:title[100], String:text[255];
	new Handle:menu = CreatePanel();
	
	Format(title, sizeof(title),"%s", GetRealName(client));
	SetPanelTitle(menu, title);
	
	Format(text, sizeof(text),"Ранк: %i", ClientRank[client]);
	DrawPanelText(menu, text);
	
	Format(text, sizeof(text),"%t: %i", "info73", VipStatus[client]);
	DrawPanelText(menu, text);
	
	Format(text, sizeof(text),"Skill: %s", GetSkillText(ClientSkill[client]));
	DrawPanelText(menu, text);
	
	if (IsRegName[client] == 1) Format(text, sizeof(text),"%t: %t", "info74", "yes");
	else Format(text, sizeof(text),"%t: %t", "info74", "no");
	DrawPanelText(menu, text);
	
	Format(text, sizeof(text),"%t: %i/3", "info75", WarningLvl[client]);
	DrawPanelText(menu, text);
	
	Format(text, sizeof(text),"%t", "info76");
	DrawPanelText(menu, text);
	Format(text, sizeof(text), "%t", "info77");
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%t", "info78");
	DrawPanelItem(menu, text);
	
	Format(text, sizeof(text), "%t", "info79");
	DrawPanelText(menu, text);
	Format(text, sizeof(text), "%t", "info80");
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%t", "info81");
	DrawPanelItem(menu, text);

	Format(text, sizeof(text), "%t", "info82");
	DrawPanelText(menu, text)
	Format(text, sizeof(text), "%t", "info83");
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%t", "info84");
	DrawPanelItem(menu, text)
	Format(text, sizeof(text), "%t", "info85");
	DrawPanelItem(menu, text);
	
	Format(text, sizeof(text), "%t", "info86");
	DrawPanelText(menu, text);
	Format(text, sizeof(text), "%t", "info87");
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%t", "info88");
	DrawPanelItem(menu, text);
	DrawPanelText(menu, "");
	Format(text, sizeof(text), "%t", "Close");
	DrawPanelItem(menu, text);
		
	SendPanelToClient(menu, client, GameMenuHandler, MENU_TIME_FOREVER);
}

public GameMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			new String:SteamID[255],query[1024];
			GetClientAuthString(param1, SteamID, sizeof(SteamID));
			
			if (param2 == 1)
			{
				FakeClientCommand(param1, "sm_rankmutetoggle");
				DisplayGameMenu(param1);
			}
			if (param2 == 2)
			{
				FakeClientCommand(param1, "sm_showinfo");
				DisplayGameMenu(param1);
			}
			if (param2 == 3)
			{
				FakeClientCommand(param1, "sm_votekick");
			}
			if (param2 == 4)
			{
				if (CurrentGamemodeID != 1) {
					PrintToChat(param1, "Данная команда отключена.");
					return;
				}
				FakeClientCommand(param1, "sm_balance");
			}
			if (param2 == 5)
			{
				FakeClientCommand(param1,"sm_perks");
			}
			if (param2 == 6)
			{
				FakeClientCommand(param1,"sm_buy");
			}
			if (param2 == 7)
			{
				//PrintToChat(param1, "\x01Чтобы установить текст приветствия наберите в \x05консоле \x03sm_setmsg \"\x04текст приветствия\x03\"");
				FakeClientCommand(param1,"sm_victim");
			}			
			if (param2 == 8)
			{
				new Handle:CPanel = CreatePanel();
				decl String:text[255];
				Format(text, sizeof(text), "%t", "portalname");
				SetPanelTitle(CPanel, text);
				Format(text, sizeof(text), "%t", "menu1");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "menu2");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "menu3");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "menu4");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "menu5");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "menu6");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "menu7");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "menu8");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "menu9");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "menu10");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "menu11");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "menu12");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "menu13");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "close");
				DrawPanelItem(CPanel, text);
				SendPanelToClient(CPanel, param1, PanelHandlerVoid, 60);
				CloseHandle(CPanel);
			}
			if (param2 == 9) {
				new Handle:CPanel = CreatePanel();
				decl String:text[255];
				Format(text, sizeof(text), "%t", "portalname");
				SetPanelTitle(CPanel, text);
				Format(text, sizeof(text), "%t", "menu14");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t/store/store.php", "siteurl");
				DrawPanelText(CPanel, text);
				Format(text, sizeof(text), "%t", "close");
				DrawPanelItem(CPanel, text);
				SendPanelToClient(CPanel, param1, PanelHandlerVoid, 60);
				CloseHandle(CPanel);
			}
				
		}
	}
}	

public Action:cmd_menu(client, args)
{
	DisplayGameMenu(client);
}
public Action:cmd_force(client, args)
{
	TimeToStartLeft == 0;
	PrintToChatAll("[DEBUG] Forzando comienzo...");
}

public Action:cmd_shownohumantime(client, args)
{
	PrintToServer("NoHumanTime: %i", NoHumanTime);
}

public PanelHandlerVoid(Handle:menu, MenuAction:action, param1, param2)
{
	
}


public Action:Command_Setinfo(client, const String:command[], args)
{
    decl String:arg[32];
    GetCmdArg(1, arg, sizeof(arg));
    
    if (StrEqual(arg, "name", false))
        return Plugin_Handled;
    
    return Plugin_Continue;
}  

public Action:steamidlist_cmd(client, args) 
{
	new String:SteamID[255];
	
	for (new i=1; i<=GetMaxClients(); i++) {
		if (IsValidPlayer(i)) {
			GetClientAuthString(i, SteamID, sizeof(SteamID));
			PrintToServer("name: %s steamid: %s", GetRealName(i), SteamID);
		}
	}
	
}

public Action:ExecAllCfg(Handle:timer, any:client)
{
	ServerCommand("exec exec_all.cfg");
}

FillVipArray()
{
	decl String:query[255];
	Format(query, sizeof(query), "SELECT login, pass FROM reg_name WHERE status > 0 and login <> '' and pass <> ''");
	SQL_TQuery(db, FillAllowArrayQuery, query, 0);	
}


public FillVipArrayQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE) 
	{
		LogError("FillVipArrayQuery Query failed: %s", error);
		return;
	}
	
	decl String:login[255];
	decl String:pass[255];
	
	acCount = 0;
	
	//new bid = GetBizonID();
	//if (bid > 0) PrintToChat(bid, "Запрос белого листа");
	if (!SQL_HasResultSet(hndl)) return;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, login, sizeof(login));
		SQL_FetchString(hndl, 1, pass, sizeof(pass));
		acCount ++;
		Format(acLogin[acCount], 255, "%s", login);
		Format(acPass[acCount], 255, "%s", pass);
		
		//if (bid > 0) PrintToChat(bid, "%s %s", login, pass);
	}
	PrintToChatAll("WhiteList refreshed")
	
}

public Action:CheckRegArrayTimer(Handle:timer)
{
	if (RoundEnd > 0) return;
	
	new RespawnTimeLimit = 100;
	
	if (CurrentGamemodeID != 1) {
		for( new i = 1; i <= GetMaxClients(); i++ )
			if ( (IsValidPlayer(i)) && (!IsPlayerAlive(i)) && (GetClientTeam(i) == 2) ) {
				
				if (VipStatus[i] == 0) RespawnTimeLimit = 100; //100 segundos de respawn para los jugadores normales
				else if	(VipStatus[i] == 1) RespawnTimeLimit = 100;	//100 segundos de respawn para los vip1
				else if	(VipStatus[i] == 2) RespawnTimeLimit = 80;	//80 segundos de respawn para los vip2
				else if	(VipStatus[i] == 3) RespawnTimeLimit = 60;	//60 segundos de respawn para los iguales a vip3		
				else if (VipStatus[i] == 4) RespawnTimeLimit = 40;	//40 segundos de respawn para los iguales a vip4
				//else if (hostport != hostport_coop3) RespawnTimeLimit = 120; //Limitar a 120 segundos el hostport3 (que no existe xD)
				else continue;
				
				if (RespawnTime[i] >= RespawnTimeLimit)  {
					ServerCommand("sm_respawn #%i", GetClientUserId(i));
					PrintToChat(i, "%t", "info90");
					
					CreateTimer(1.0, TeleportToSurv, i);
					
					RespawnTime[i] = 0;
				}
				else {
					RespawnTime[i]++;
					PrintHintText(i, "%t %i %t. \n %t ", "info91", RespawnTimeLimit-RespawnTime[i], "info92", "respawnpromo");
				}
			}
	}
	
	if ( (!IsCheckRegProcess) && (!IsUpdateSkillProcess) ) {
		if (GetArraySize(toCheckReg) > 0) {
			checkreg(GetArrayCell(toCheckReg, 0));
			RemoveFromArray(toCheckReg, 0);
			return;
		}
		if (GetArraySize(toUpdateSkill) > 0) {
			UpdateClientSkill(GetArrayCell(toUpdateSkill, 0));
			RemoveFromArray(toUpdateSkill, 0);
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
		if (IsClientInGame(i))
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	
}

public Action:ResetBlockConnect(Handle:timer, any:client)
{
	BlockConnect = false;
	TimerBC = INVALID_HANDLE;
}

public Action:ResetBlockConnectStart(Handle:timer, any:client)
{
	BlockConnectStart = false;

}

/*public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{

	if( buttons & IN_FORWARD && GetClientTeam(client) == 3 && Freeze )
	{
		
		buttons &= ~IN_FORWARD;
		return Plugin_Handled;
		
		
		if( g_iPlayerEnum[client] & POUNCED )		// Player pounced
		{
			buttons &= ~IN_FORWARD;					// Stop pressing forward!
			return Plugin_Handled;					// Plugin_Continue allows them to move slightly, handled does not but freezes progress bar when reviving.
		}

		
	}
	
	return Plugin_Continue;
	
}*/


public FreezeAll(any: team, bool: freeze)
{
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ( (IsNormalPlayer(i)) && (GetClientTeam(i) == team) )
			if (freeze) {
				SetEntityMoveType(i, MOVETYPE_NONE);
			}
			else {
				SetEntityMoveType(i, MOVETYPE_WALK);
			}
	}
}


public Action:OnClientCommand(client, args)
{
    //new String:cmd[16];
    //GetCmdArg(0, cmd, sizeof(cmd));
 
	if ( (RoundEnd > 0) && (GetHumanCount() > 0) ) return Plugin_Handled;
	
    return Plugin_Continue;
}



bool:HasRussian(String:text[])
{
	new textlen = strlen(text) - 1;
			
	for (new i = 0; i <= textlen; i++)
	{
		if (IsCharMB(text[i]))
		{
			return true;
	
		}
	}
	return false;
}



GetMastersCount(any:skill)
{
	new mCount = 0;
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ( (IsValidPlayer(i)) && (GetClientTeam(i) == 2) && (ClientSkill[i] <= skill) && (ClientSkill[i] > 0) ) mCount++;
	}
	return mCount;
}

public Action:TeleportToSurv(Handle:timer, any:client)
{
	if (RoundEnd > 0) return;
	
	new Float:TPos[3];
	TPos[0] = 0; TPos[1] = 0; TPos[2] = 0;
	for(new i=1;( (i<=GetMaxClients()) && (TPos[0] == 0) && (TPos[1] == 0) && (TPos[2] == 0) );i++) {
		if ( (IsValidPlayer(i)) && (GetClientTeam(i) == 2) && (IsPlayerAlive(i)) && (i != client) )	{
			GetClientAbsOrigin(i, TPos);
		}
	}
	if ( !((TPos[0] == 0) && (TPos[1] == 0) && (TPos[2] == 0)) ) 
		TeleportEntity(client,TPos,NULL_VECTOR,NULL_VECTOR);
}

bool:IsPlayerBoomer (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == 2)
		return true;
	return false;
}

public Action:Event_BotReplacedPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Event is triggered when a bot takes over a player    
	return;	
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	
	if ( (GetClientTeam(client) == 3) || (CurrentGamemodeID == 1) ) return;
	
	if (ForceAfk[client] == 1) {
		ForceAfk[client] = 0;
		return; 
	}
	
	new bid = GetBizonID();
	//if (IsValidPlayer(bid)) PrintToChat(bid, "Bot Replaced Player: %s", GetName(client));	
	
	new Handle:datapack = CreateDataPack();
	WritePackCell(datapack, client);
	WritePackCell(datapack, bot);   
	CreateTimer(0.5, TimerTakeOverBot, datapack, TIMER_FLAG_NO_MAPCHANGE);
	
}

public Action:Event_PlayerWentAFK(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Event is triggered when a player goes AFK
			
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	//PlayerWentAFK[client] = true;
	//SurvivorCharacter[client] = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	
	new bid = GetBizonID();
	if (IsValidPlayer(bid)) PrintToChat(bid, "Player went AFK: %s", GetName(client));
}

public Action:TimerTakeOverBot(Handle:Timer, any:datapack)
{
	// Reset the data pack
	ResetPack(datapack);
	
	// Retrieve values from datapack
	new client = ReadPackCell(datapack);
	new bot = ReadPackCell(datapack);
	
	if (IsNormalPlayer(bot) && IsNormalPlayer(client) && (GetClientTeam(bot) == 2) && (GetClientTeam(client) == 1)) {
		SDKCall(fSHS, bot, client);
		SDKCall(fTOB, client, true);	
	}
	
}

public Action:TimerTakeOverBotAuto(Handle:Timer, any:client)
{	
    if (!IsValidPlayer(client)) return;
	if (GetClientTeam(client) == 2) return;
	
	new bot = GetEntProp(client, Prop_Send, "m_hObserverTarget");
	if (!IsFakeClient(bot)) return;
	
	if ( IsNormalPlayer(bot) && IsNormalPlayer(client) &&
	(GetClientTeam(bot) == 2) && (GetClientTeam(client) == 1) )  {
		SDKCall(fSHS, bot, client);
		SDKCall(fTOB, client, true);	
		return;
	}
	
	//CreateTimer(0.5, TimerTakeOverBotAuto, client, TIMER_FLAG_NO_MAPCHANGE);
	
}

public Action:getscore_cmd(client, args)
{
	if(fGetTeamScore == INVALID_HANDLE)
	{
		
		return Plugin_Handled;
	}

	if (!IsValidPlayer(client)) return Plugin_Handled;
	
	//new score = GameRules_GetProp("m_iSurvivorScore");
	new score = SDKCall(fGetTeamScore, 2, 0);
	
	PrintToChat(client, "surv score: %i", score);
	
}


public Action:setscore_cmd(client, args)
{
	if(fGetTeamScore == INVALID_HANDLE)
	{
		
		return Plugin_Handled;
	}

	if (!IsValidPlayer(client)) return Plugin_Handled;
	
	//new score = GameRules_GetProp("m_iSurvivorScore");
	new score = SDKCall(fGetTeamScore, 2, 0);
	PrintToChat(client, "was surv score: %i", score);
	
	//GameRules_SetProp("m_iSurvivorScore", score + 10, 4, 0, true);
	SDKCall(fSetCampaignScores, 2, score + 10);
	
	//score = GameRules_GetProp("m_iSurvivorScore");
	score = SDKCall(fGetTeamScore, 2, 0);
	PrintToChat(client, "new surv score: %i", score);
	
	return Plugin_Handled;
}

public Action:AdminTimeTimer(Handle:timer)
{
	if (RoundEnd > 0) return;
	
	decl String:SteamID[255];
	decl String:query[255];
	decl String:server_name[255];
	GetConVarString(FindConVar("hostname"), server_name, sizeof(server_name));	
	
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if ( (IsValidPlayer(i)) && (IsAdmin(i)) ) {
			
			GetClientAuthString(i, SteamID, sizeof(SteamID));
	
			Format(query, sizeof(query), "insert into admin_time (steamid, play_date, play_time, server_name) values ('%s', now(), 5, '%s') on duplicate key update play_time = play_time + 5", SteamID, server_name);
			SQL_TQuery(db, NullHandle, query, 0);	
		}
	}
	
	
}


public Action:cmd_warning(client, args)
{
	if (!IsValidPlayer(client)) return;
	//if (!IsAdminId(client)) return;
	
	decl String:sArg[255];
	GetCmdArgString(sArg, sizeof(sArg));
	if (strlen(sArg) < 3) {
		PrintToChat(client, "Размер текста причины должен быть более 3 символов.");
		return;
	}
	sArg = SafeString(sArg);
	WarningReason[client] = sArg;
	
	if (!AllowWarning) {
		PrintToChat(client, "Данная команда временно заблокирована, попробуйте снова через 10 секунд.");
		return;
	}
	AllowWarning = false;
	CreateTimer(10.0, SetAllowWarning, 0);
			
	PlayersMenu(client, Menu_WarningHandler);
}

public Action:SetAllowWarning(Handle:timer, any:client)
{
	AllowWarning = true;
}


public Menu_WarningHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;
	
	if (action == MenuAction_End) {
		CloseHandle(menu);
		return;
	}
	
	if (action != MenuAction_Select || (!IsValidPlayer(param1))){
		
		return;
	}
	
	decl String:Info[255];
	new bool:found = GetMenuItem(menu, param2, Info, sizeof(Info));
	
	if (!found) return;
		
	new client = StringToInt(Info);
	WarningUp(client,param1);
	
	
}

public WarningUp(clientid, adminid)
{
	if ( (!IsValidPlayer(clientid)) || (!IsValidPlayer(adminid)) ) return;
	
	new String:query[512];
	decl String: client_steamid[255];
	decl String:admin_steamid[255];
	GetClientAuthString(clientid, client_steamid, sizeof(client_steamid));
	GetClientAuthString(adminid, admin_steamid, sizeof(admin_steamid));
	
	decl String: server_name[255];
	GetConVarString(FindConVar("hostname"), server_name, sizeof(server_name));	
	
	Format(query, sizeof(query), "insert into warning_logs (client_steamid, admin_steamid, w_reason, w_type, server_name) values ('%s', '%s', '%s', 1, '%s')", client_steamid, admin_steamid, WarningReason[adminid], server_name);
	SQL_TQuery(db, NullHandle, query, 0);
	
	Format(query, sizeof(query), "update reg_name set warnings = warnings + 1 where steamid = '%s'", client_steamid);
	SQL_TQuery(db, NullHandle, query, 0);
	
	PrintToChat(clientid, "\x05Внимание! \x01Вам был увеличен уровень предупреждений.");
	PrintToChat(clientid, "\x05Причина: \x01%s", WarningReason[adminid]);	
	
	PrintToChat(adminid, "\x01Вы увеличи уровень предупреждений для игрока %s", GetName(clientid));
	PrintToChat(adminid, "\x05Причина: \x01%s", WarningReason[adminid]);	
	
	WarningLvl[clientid]++;	
	
	new Handle:CPanel = CreatePanel();
	decl String:text[255];
	SetPanelTitle(CPanel, "Внимание!");
	DrawPanelText(CPanel, "Вам был увеличен уровень предупреждений.");
	Format(text, sizeof(text), "Текущий уровень: %i/3", WarningLvl[clientid]);
	DrawPanelText(CPanel, text);
	DrawPanelText(CPanel, "Причина:");
	Format(text, sizeof(text), "%s", WarningReason[adminid]);
	DrawPanelText(CPanel, text);
	DrawPanelItem(CPanel, "Закрыть");
	SendPanelToClient(CPanel, clientid, PanelHandlerVoid, 60);
	CloseHandle(CPanel);
	
	
}


public Action:event_SurvivalStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//RoundStartInit();	
}



CheckSafeRoomDoor()
{
	ent_safedoor_check = -1;
	while ((ent_safedoor_check = FindEntityByClassname(ent_safedoor_check, SAFEDOOR_CLASS)) != -1)
	if (ent_safedoor_check > 0)
	{
		new spawn_flags;
		decl String:model[255];
		GetEntPropString(ent_safedoor_check, Prop_Data, "m_ModelName", model, sizeof(model));
		spawn_flags = GetEntProp(ent_safedoor_check, Prop_Data, "m_spawnflags");

		if (((strcmp(model, SAFEDOOR_MODEL_01) == 0) && ((spawn_flags == 8192) || (spawn_flags == 0))) || ((strcmp(model, SAFEDOOR_MODEL_02) == 0) && ((spawn_flags == 8192) || (spawn_flags == 0))))
		{
			ent_safedoor = ent_safedoor_check;
		}
	}
}


LockTheDoor()
{
	if (IsValidEntity(ent_safedoor)) 
	  DispatchKeyValue(ent_safedoor, "spawnflags", "585728");
}

UnlockTheDoor()
{
  if (IsValidEntity(ent_safedoor))
	DispatchKeyValue(ent_safedoor, "spawnflags", "8192");
}

