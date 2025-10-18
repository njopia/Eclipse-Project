#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif
// Zombie Classes (para claridad al leer el código)
#define ZOMBIECLASS_SMOKER  1
#define ZOMBIECLASS_BOOMER  2
#define ZOMBIECLASS_HUNTER  3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY  5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_WITCH   7
#define ZOMBIECLASS_TANK    8
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
stock bool IsTank (int entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank", false))
		{
			return true;
		}
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