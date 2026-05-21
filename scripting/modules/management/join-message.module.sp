#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

#define _JOIN_MESSAGE_MODULE_

//==================================================
// === JOIN MESSAGE MODULE ===
// Muestra un mensaje global cuando un jugador se conecta,
// con su nivel, XP total y país cargados vía GeoIP.
//==================================================

#define JOIN_SOUND "ui/hint.wav"

public void JoinMessage_OnMapStart()
{
	PrecacheSound(JOIN_SOUND);
}

public void JoinMessage_OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client))
		return;

	CreateTimer(2.0, JoinMessage_Timer_WaitData, GetClientUserId(client));
}

public Action JoinMessage_Timer_WaitData(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Stop;

	if (!g_bPlayerDataLoaded[client])
	{
		CreateTimer(1.5, JoinMessage_Timer_WaitData, userid);
		return Plugin_Stop;
	}

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	char ip[32];
	GetClientIP(client, ip, sizeof(ip));

	char country[64];
	if (!GeoipCountry(ip, country, sizeof(country)))
		Format(country, sizeof(country), "%T", "UI_Unknown", LANG_SERVER);

	int level   = g_iPlayerLevel[client];
	int totalXP = g_iTotalPlayerXP[client];

	EmitSoundToAll(JOIN_SOUND);
	char shopLine[256];
	Format(shopLine, sizeof(shopLine), "%T", "JoinMsg_UseShop", LANG_SERVER);
	CPrintToChatAll("%s", shopLine);

	char infoLine[256];
	if (totalXP == 0 && level == 0)
		Format(infoLine, sizeof(infoLine), "%T", "JoinMsg_New", LANG_SERVER, name, country);
	else
		Format(infoLine, sizeof(infoLine), "%T", "JoinMsg_Returning", LANG_SERVER, name, country, level, totalXP);
	CPrintToChatAll("%s", infoLine);

	return Plugin_Stop;
}
