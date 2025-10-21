#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

public Action Cmd_Reload_Plugins(int client, int args)
{
	ServerCommand("sm plugins reload");
	PrintToChat(client, "Plugins Reloaded");
	return Plugin_Handled;
}

public Action Cmd_Reload_Translations(int client, int args)
{
	PrintToChatAll("Reloading Translations");
	ServerCommand("sm_reload_translations");
	PrintToChat(client, "Translations Reloaded");
	return Plugin_Handled;
}