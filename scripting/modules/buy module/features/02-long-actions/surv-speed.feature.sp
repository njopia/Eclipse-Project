#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif
#include <left4dhooks>
#define SPEED_BASE	1.0
#define SPEED_BOOST 1.5
#define SOUND_PATH	"player/heartbeatloop.wav"

// --- Variables para tracking de tiempo ---
static float g_fSpeedBoostEnd[MAXPLAYERS + 1];

public Action Surv_SpeedBoost(int client)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != 2)
		return Plugin_Handled;
	EmitSoundToClient(client, SOUND_PATH, SOUND_FROM_PLAYER, SNDCHAN_AUTO,
					  SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0);
	EmitSoundToAll("player/survivor/voice/gambler/battlecry01.wav", client);
	L4D_ScreenFade(client, 255, 255, 255, 100, 0.5, FADE_IN);
	L4D_SetPlayerSpeed(client, SPEED_BOOST);
	PrintToChat(client, "\x05[Eclipse]\x01 ¡Velocidad aumentada a %.1fx por %.0f segundos!", SPEED_BOOST, CONFIG_SURV_SPEEDBOOST_DURATION);
	g_fSpeedBoostEnd[client] = GetGameTime() + CONFIG_SURV_SPEEDBOOST_DURATION;
	CreateTimer(CONFIG_SURV_SPEEDBOOST_DURATION, Timer_AutoStop, GetClientUserId(client));

	return Plugin_Handled;
}

public Action Timer_AutoStop(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client <= 0 || !IsClientInGame(client))
		return Plugin_Stop;

	L4D_SetPlayerSpeed(client, SPEED_BASE);
	// Detener el sonido automáticamente
	StopSound(client, SNDCHAN_AUTO, SOUND_PATH);
	PrintToChat(client, "[SM] Sonido detenido automáticamente.");
	g_fSpeedBoostEnd[client] = 0.0;

	return Plugin_Stop;
}

/**
 * Obtiene el tiempo restante del speed boost de sobreviviente
 */
stock float GetSurvSpeedBoostRemaining(int client)
{
	if (g_fSpeedBoostEnd[client] <= 0.0)
		return 0.0;

	float remaining = g_fSpeedBoostEnd[client] - GetGameTime();
	return (remaining > 0.0) ? remaining : 0.0;
}
