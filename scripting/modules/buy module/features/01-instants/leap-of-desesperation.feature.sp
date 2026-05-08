#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

public void Activate_LeapOfDesperation(int client)
{
	if (!IsNormalPlayer(client) || !IsPlayerAlive(client)) return;

	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(7);	// Duracion total en segundos
	pack.WriteCell(0);	// Contador de gritos

	CreateTimer(1.0, Timer_LeapOfDesperation, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	PrintToChat(client, "\x05[Eclipse]\x01 Activando Salto de Desesperacion!");
}

public Action Timer_LeapOfDesperation(Handle timer, DataPack pack)
{
	pack.Reset();
	int client	 = pack.ReadCell();
	int duration = pack.ReadCell();
	int count	 = pack.ReadCell();

	if (!IsNormalPlayer(client) || !IsPlayerAlive(client) || count >= duration)
	{
		delete pack;
		return Plugin_Stop;
	}

	Yell(client);
	FX_AttachParticle(client, "electrical_arc_01_system", 1.0);

	pack.Reset();
	pack.WriteCell(client);
	pack.WriteCell(duration);
	pack.WriteCell(count + 1);

	return Plugin_Continue;
}
