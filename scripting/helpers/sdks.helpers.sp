Handle g_hConf, g_hSetHB;

#define L4DHOOKS_GAMEDATA "left4dhooks.l4d2"

public void HandleSdk()
{
	g_hConf = LoadGameConfigFile(L4DHOOKS_GAMEDATA);
	if (g_hConf == null)
	{
		SetFailState("No se pudo cargar gamedata left4dhooks.l4d2");
	}

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(g_hConf, SDKConf_Signature, "CTerrorPlayer_SetHealthBuffer"))
	{
		SetFailState("Firma CTerrorPlayer_SetHealthBuffer no encontrada en left4dhooks.l4d2");
	}

	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);

	g_hSetHB = EndPrepSDKCall();
	if (g_hSetHB == null)
	{
		SetFailState("No se pudo preparar SDKCall: CTerrorPlayer_SetHealthBuffer");
	}
}