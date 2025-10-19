#if !defined  EMS_MAIN_FILE
	 #error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

bool g_bDebugConvertHP = false;

public void ConvertHealth(int client)
{
	if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] ConvertHealth: Iniciando para el cliente %d.", client);
	int TempHealth = GetClientTempHealth(client);
	if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] ConvertHealth: GetClientTempHealth devolvió %d.", TempHealth);
	if (TempHealth > 0)
	{
		int PermHealth = GetClientHealth(client);
		if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] ConvertHealth: Salud permanente: %d, Salud temporal: %d.", PermHealth, TempHealth);
		int total = PermHealth + TempHealth;
		if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] ConvertHealth: Salud total calculada: %d.", total);

		RemoveTempHealth(client);
		SetEntityHealth(client, total);
		if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] ConvertHealth: Nueva salud establecida para el cliente %d: %d.", client, GetClientHealth(client));
	}
}
stock int GetClientTempHealth(int client)
{
	// First filter -> Must be a valid client, successfully in-game and not an spectator (The dont have health).
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| IsClientObserver(client)
		|| GetClientTeam(client) != 2)
	{
		if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] GetClientTempHealth: El cliente %d no pasó la validación inicial.", client);
		return -1;
	}

	// First, we get the amount of temporal health the client has
	// float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float buffer = L4D_GetTempHealth(client);
	if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] GetClientTempHealth: Buffer de salud para el cliente %d: %f.", client, buffer);

	// We are the permanent and temporal health variables
	float TempHealth;

	// In case the buffer is 0 or less, we set the temporal health as 0, because the client has not used any pills or adrenaline yet
	if (buffer <= 0.0)
	{
		TempHealth = 0.0;
		if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] GetClientTempHealth: El buffer es <= 0, salud temporal establecida en 0.");
	}

	// In case it is higher than 0, we proceed to calculate the temporl health
	else
	{
		// This is the difference between the time we used the temporal item, and the current time
		float difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] GetClientTempHealth: Diferencia de tiempo: %f.", difference);

		// We get the decay rate from this convar (NoteAdrenaline uses this value)
		float decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
		if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] GetClientTempHealth: Tasa de decaimiento (decay): %f.", decay);

		// This is a constant we create to determine the amount of health. This is the amount of time it has to pass
		// before 1 Temporal HP is consumed.
		float constant = 1.0 / decay;
		if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] GetClientTempHealth: Constante de cálculo: %f.", constant);

		// Then we do the calcs
		TempHealth = buffer - (difference / constant);
		if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] GetClientTempHealth: Salud temporal calculada: %f.", TempHealth);
	}

	// If the temporal health resulted less than 0, then it is just 0.
	if (TempHealth < 0.0)
	{
		TempHealth = 0.0;
		if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] GetClientTempHealth: La salud temporal calculada es < 0, estableciendo a 0.");
	}

	// Return the value
	if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] GetClientTempHealth: Devolviendo salud temporal final (redondeada): %d.", RoundToFloor(TempHealth));
	return RoundToFloor(TempHealth);
}
stock void RemoveTempHealth(int client)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| IsClientObserver(client)
		|| GetClientTeam(client) != 2)
	{
		if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] RemoveTempHealth: El cliente %d no pasó la validación.", client);
		return;
	}
	if (g_bDebugConvertHP) PrintToChatAll("[DEBUG] RemoveTempHealth: Eliminando salud temporal para el cliente %d.", client);
	CTerrorPlayer_SetHealthBuffer(client, 0.0, 0.0, 1.0);
}

stock void CTerrorPlayer_SetHealthBuffer(int client, float newBuffer, float decay, float extra /*o bool reset*/)
{
	if (client <= 0 || !IsClientInGame(client)) return;
	SDKCall(g_hSetHB, client, newBuffer, decay, extra);
	// Si fuera la versión (float,float) usa: SDKCall(g_hSetHB, client, newBuffer, decay);
}