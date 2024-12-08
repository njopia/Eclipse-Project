#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif
stock bool IsInfected(int entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "infected", false))
		{
			return true;
		}
	}
	return false;
}
stock bool IsWitch(int entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "witch", false))
			return true;
		return false;
	}
	return false;
}
stock bool IsSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}
stock bool IsSpectator(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1)
	{
		return true;
	}
	return false;
}