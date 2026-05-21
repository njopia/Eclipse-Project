#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

public Action Cmd_Reload_Plugins(int client, int args)
{
	ServerCommand("sm plugins reload");
	char message[128];
	Format(message, sizeof(message), "%T", "System_PluginsReloaded", client);
	PrintToChat(client, "\x04[System]\x01 %s", message);
	return Plugin_Handled;
}

public Action Cmd_Reload_Translations(int client, int args)
{
	char reloadingMsg[128];
	Format(reloadingMsg, sizeof(reloadingMsg), "%T", "System_TranslationsReloading", LANG_SERVER);
	CPrintToChatAll("\x04[System]\x01 %s", reloadingMsg);

	ServerCommand("sm_reload_translations");

	char reloadedMsg[128];
	Format(reloadedMsg, sizeof(reloadedMsg), "%T", "System_TranslationsReloaded", client);
	PrintToChat(client, "\x04[System]\x01 %s", reloadedMsg);
	return Plugin_Handled;
}