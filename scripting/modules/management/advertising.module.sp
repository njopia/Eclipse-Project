#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

#define _ADVERTISING_MODULE_

//==================================================
// === ADVERTISING MODULE ===
// Muestra mensajes de tips/publicidad rotando cada N segundos.
// Cada mensaje se envía en el idioma personal de cada jugador.
//==================================================

#define ADVERT_MAX_MESSAGES 32
#define ADVERT_PREFIX       "\x04[Eclipse]\x01 "

static char   g_sAdvertKeys[ADVERT_MAX_MESSAGES][64];
static int    g_iAdvertCount  = 0;
static int    g_iAdvertIndex  = 0;
static Handle g_hAdvertTimer  = INVALID_HANDLE;
static ConVar g_hAdvertInterval;

/**
 * Inicializa el módulo de publicidad
 */
public void Advertising_OnPluginStart()
{
	g_hAdvertInterval = CreateConVar(
		"advert_interval",
		"60",
		"Segundos entre mensajes de publicidad (0 = desactivado)",
		FCVAR_PLUGIN
	);
	g_hAdvertInterval.AddChangeHook(Advert_OnIntervalChanged);

	// Registrar todos los mensajes en orden de rotación
	Advert_Add("Advert_Menu");
	Advert_Add("Advert_Buy");
	Advert_Add("Advert_LevelXP");
	Advert_Add("Advert_Abilities");
	Advert_Add("Advert_Deployables");
	Advert_Add("Advert_TeamFeatures");
	Advert_Add("Advert_Bombardments");
	Advert_Add("Advert_Specials");
	Advert_Add("Advert_Hat");
	Advert_Add("Advert_ShoulderCannon");
	Advert_Add("Advert_SentryControl");
	Advert_Add("Advert_Currency");
	Advert_Add("Advert_GameModes");
	Advert_Add("Advert_Players");
	Advert_Add("Advert_Frags");
	Advert_Add("Advert_MapVote");
	Advert_Add("Advert_Language");
	Advert_Add("Advert_JoinAfk");

	Advert_StartTimer();
}

/**
 * Limpia el timer al cambiar de mapa para reiniciar el ciclo
 */
public void Advertising_OnMapStart()
{
	g_iAdvertIndex = 0;
	Advert_StartTimer();
}

/**
 * Cuando cambia el intervalo por ConVar, reinicia el timer
 */
public void Advert_OnIntervalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Advert_StartTimer();
}

/**
 * Inicia (o reinicia) el timer de publicidad
 */
static void Advert_StartTimer()
{
	if (g_hAdvertTimer != INVALID_HANDLE)
	{
		KillTimer(g_hAdvertTimer);
		g_hAdvertTimer = INVALID_HANDLE;
	}

	float interval = g_hAdvertInterval.FloatValue;
	if (interval <= 0.0 || g_iAdvertCount == 0)
		return;

	g_hAdvertTimer = CreateTimer(interval, Timer_Advertise, _, TIMER_REPEAT);
}

/**
 * Agrega una phrase key a la lista de rotación
 */
static void Advert_Add(const char[] phraseKey)
{
	if (g_iAdvertCount >= ADVERT_MAX_MESSAGES)
		return;

	strcopy(g_sAdvertKeys[g_iAdvertCount], 64, phraseKey);
	g_iAdvertCount++;
}

/**
 * Timer principal: envía el mensaje actual en el idioma de cada jugador
 */
public Action Timer_Advertise(Handle timer)
{
	if (g_iAdvertCount == 0)
		return Plugin_Continue;

	char msg[256];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		Format(msg, sizeof(msg), "%T", g_sAdvertKeys[g_iAdvertIndex], i);
		PrintToChat(i, "%s%s", ADVERT_PREFIX, msg);
	}

	g_iAdvertIndex = (g_iAdvertIndex + 1) % g_iAdvertCount;
	return Plugin_Continue;
}
