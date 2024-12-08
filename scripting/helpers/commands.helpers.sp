#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif
stock CheatCommand(int client, const char[] command, const char[] arguments)
{
	PrintToChat(client, "%s", arguments);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}