Handle g_hConf, g_hSetHB;

#define ECLIPSE_GAMEDATA_TITLE "eclipse.l4d2"

public void HandleSdk()
{
	g_hConf = LoadGameConfigFile(ECLIPSE_GAMEDATA_TITLE);
	if (g_hConf == null)
	{
		SetFailState("No se pudo cargar gamedata l4d2_sethealthbuffer");
		PrintToServer("No se pudo cargar gamedata l4d2_sethealthbuffer");
	}

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(g_hConf, SDKConf_Signature, "CTerrorPlayer_SetHealthBuffer"))
	{
		PrintToServer("Firma CTerrorPlayer::SetHealthBuffer no encontrada");
		SetFailState("Firma CTerrorPlayer::SetHealthBuffer no encontrada");
	}

	// PrepSDKCall_SetReturnInfo(SDKType_Void);

	// Ajusta los parámetros si tu firma difiere:
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	// Si en tu build es bool al final:
	// PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);

	g_hSetHB = EndPrepSDKCall();
	if (g_hSetHB == null)
	{
		SetFailState("No se pudo preparar SDKCall: CTerrorPlayer::SetHealthBuffer");
		PrintToServer("No se pudo preparar SDKCall: CTerrorPlayer::SetHealthBuffer");
	}
}
