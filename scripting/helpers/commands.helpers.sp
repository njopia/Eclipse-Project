#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

/**
 * Centralized registration for all Eclipse Management System commands.
 * This function is called from OnPluginStart in the main file.
 */
void RegisterEMSCommands()
{
	// =========================================================================
	// PLAYER COMMANDS (Public Access)
	// =========================================================================
	
	// Buy System
	#if defined _BUY_MENU_MODULE_
		RegConsoleCmd("buy",          Cmd_Buy,                "Opens the Eclipse Buy Menu");
		RegConsoleCmd("sm_buy",       Cmd_Buy,                "Opens the Eclipse Buy Menu");
	#endif

	// Deployables
	#if defined _DEPLOYABLES_MODULE_
		RegConsoleCmd("sm_deployables", Cmd_Deployables,      "Desplegar equipamiento de campo (!deployables)");
		RegConsoleCmd("deployables",    Cmd_Deployables,      "Desplegar equipamiento de campo");
	#endif

	// Specials
	#if defined _SPECIALS_MODULE_
		RegConsoleCmd("sm_specials",    Cmd_Specials,         "Habilidades especiales de alto nivel (!specials)");
		RegConsoleCmd("specials",       Cmd_Specials,         "Habilidades especiales de alto nivel");
	#endif

	// Sentry Gun config
	#if defined _SENTRY_GUN_FEATURE_
		RegConsoleCmd("sm_sentrycontrol", Cmd_SentryControl, "Configurar objetivo de la Sentry Gun");
		RegConsoleCmd("sentrycontrol",    Cmd_SentryControl, "Configurar objetivo de la Sentry Gun");
	#endif

	// Hats (acceso directo al selector de hat)
	#if defined _HATS_MODULE_
		RegConsoleCmd("sm_choosehat",   Cmd_ChooseHat,        "Elige tu sombrero cosmético (!choosehat)");
		RegConsoleCmd("choosehat",      Cmd_ChooseHat,        "Elige tu sombrero cosmético");
		RegConsoleCmd("hat",            Cmd_ChooseHat,        "Elige tu sombrero cosmético");
	#endif


	// Leveling & XP
	#if defined _LEVELING_UI_MODULE_
		RegConsoleCmd("sm_level",     Cmd_ShowLevelInfo,      "Shows current level and XP progress");
		RegConsoleCmd("sm_xp",        Cmd_ShowLevelInfo,      "Alias for sm_level");
		RegConsoleCmd("sm_exp",       Cmd_ShowLevelInfo,      "Alias for sm_level");
	#endif

	// Abilities
	#if defined _ABILITIES_SYSTEM_MODULE_
		RegConsoleCmd("sm_abilities", Command_AbilitiesMenu,  "Opens the Active Abilities menu");
		RegConsoleCmd("sm_ability",    Command_AbilitiesMenu,  "Opens the Active Abilities menu");
		
		// Individual Ability Commands
		RegConsoleCmd("sm_detectzombie", Command_ActivateAbility_DetectZombie, "Activate Detect Zombie");
		RegConsoleCmd("sm_berserker",    Command_ActivateAbility_Berserker,    "Activate Berserker");
		RegConsoleCmd("sm_acidbath",     Command_ActivateAbility_AcidBath,     "Activate Acid Bath");
		RegConsoleCmd("sm_lifestealer",  Command_ActivateAbility_Lifestealer,  "Activate Lifestealer");
		RegConsoleCmd("sm_flameshield",  Command_ActivateAbility_Flameshield,  "Activate Flameshield");
		RegConsoleCmd("sm_nightcrawler", Command_ActivateAbility_Nightcrawler, "Activate Nightcrawler");
		RegConsoleCmd("sm_rapidfire",    Command_ActivateAbility_RapidFire,    "Activate Rapid Fire");
		RegConsoleCmd("sm_chainsaw",     Command_ActivateAbility_ChainsawMassacre, "Activate Chainsaw Massacre");
		RegConsoleCmd("sm_heatseeker",   Command_ActivateAbility_HeatSeeker,   "Activate Heat Seeker");
		RegConsoleCmd("sm_speedfreak",   Command_ActivateAbility_SpeedFreak,   "Activate Speed Freak");
		RegConsoleCmd("sm_healingaura",  Command_ActivateAbility_HealingAura,  "Activate Healing Aura");
		RegConsoleCmd("sm_soulshield",   Command_ActivateAbility_Soulshield,   "Activate Soulshield");
		RegConsoleCmd("sm_polymorph",    Command_ActivateAbility_Polymorph,    "Activate Polymorph");
		RegConsoleCmd("sm_instagib",     Command_ActivateAbility_Instagib,     "Activate Instagib");
		
		// Shoulder Cannon menu
		RegConsoleCmd("shouldercannon",  Command_ShoulderCannonMenu,           "Shoulder Cannon configuration");
		RegConsoleCmd("sm_cannonmenu",   Command_ShoulderCannonMenu,           "Shoulder Cannon configuration");
	#endif

	// Management (AFK/Join)
	#if defined _AFK_JOIN_MODULE_
		RegConsoleCmd("sm_join",      Afk_Join_CmdJoin,       "Join the Survivor team");
		RegConsoleCmd("sm_afk",       Afk_Join_CmdAfk,        "Move to Spectators");
	#endif

	// Utilities
	#if defined _LANGUAGE_MODULE_
		RegConsoleCmd("sm_lang",      Command_Language,       "Change your personal language settings");
		RegConsoleCmd("sm_language",  Command_Language,       "Change your personal language settings");
	#endif

	#if defined _PLAYERS_LIST_MODULE_
		RegConsoleCmd("sm_players",   PlayersList_CmdMenu,    "Show active players list and levels");
	#endif

	#if defined _FRAGS_SYSTEM_MODULE_
		RegConsoleCmd("sm_frags",     FragsSystem_Command_Frags, "Show the frags and top killers panel");
	#endif

	// Main Menu
	#if defined _MAIN_MENU_MODULE_
		RegConsoleCmd("menu",         Command_MainMenu,       "Opens the main menu");
		RegConsoleCmd("sm_menu",      Command_MainMenu,       "Opens the main menu");
		RegConsoleCmd("sm_mainmenu",  Command_MainMenu,       "Opens the main menu");
	#endif


	// =========================================================================
	// ADMIN & ECONOMY COMMANDS
	// =========================================================================

	#if defined _ADMIN_MANAGER_MODULE_
		RegAdminCmd("sm_givemoney",   AdminMoney_CmdGive,     ADMFLAG_BAN,    "Give currency to a player");
		RegAdminCmd("sm_setmoney",    AdminMoney_CmdSet,      ADMFLAG_RCON,   "Set a player's exact currency balance");
	#endif

	#if defined _SCRIPTED_HUD_MODULE_
		RegAdminCmd("sm_reload_hud",  ScriptedHUD_Cmd_ReloadMessages,  ADMFLAG_CONFIG, "Force reload HUD messages from database");
	#endif

	#if defined _MAPVOTE_MODULE_
		RegAdminCmd("sm_custom",      MapVote_Cmd_AdminMapChange, ADMFLAG_CHANGEMAP, "Cambiar campaña directamente (admin)");
	#endif


	// =========================================================================
	// EMERGENCY & MAINTENANCE (Root Access)
	// =========================================================================

	RegAdminCmd("rp",             Cmd_Reload_Plugins,     ADMFLAG_ROOT,   "Quick reload of EMS modules");
	RegAdminCmd("rt",             Cmd_Reload_Translations, ADMFLAG_ROOT,   "Refresh all localization files");
	RegAdminCmd("sm_precache_reload", EMS_CmdPrecacheReload, ADMFLAG_CONFIG, "Reload all precached resources");
	
	// Visual Fixes (White screen recovery)
	RegAdminCmd("sm_clearfade",      Cmd_ClearFade,       ADMFLAG_GENERIC, "Purge screen fade effects");
	RegAdminCmd("sm_clearfog",       Cmd_ClearFog,        ADMFLAG_GENERIC, "Remove all fog controllers");
	RegAdminCmd("sm_fixwhitescreen", Cmd_FixWhiteScreen,  ADMFLAG_GENERIC, "Full white-screen recovery (Fade + Fog)");

	PrintToServer("[EMS] Commands centralized and registered successfully.");
}

stock CheatCommand(int client, const char[] command, const char[] arguments)
{
	PrintToChat(client, "%s", arguments);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}