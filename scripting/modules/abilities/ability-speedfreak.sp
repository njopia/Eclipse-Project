#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === SPEED FREAK ABILITY (Level 31) ===
// Velocidad extrema + HP reducido a 50 durante el efecto.
// Duración: 60 segundos — Cooldown: 5 minutos
//==================================================

#define SPEEDFREAK_SPEED	  2.5	  // 250% velocidad
#define SPEEDFREAK_DURATION	  60.0	  // segundos
#define SPEEDFREAK_HP		  50	  // HP durante el efecto
#define SPEEDFREAK_HP_RESTORE 100	  // HP mínimo al restaurar

static int g_iSpeedFreak_OriginalHealth[MAXPLAYERS + 1];

/**
 * Activa Speed Freak para un cliente.
 *
 * @param client    Índice del cliente.
 * @return          true si se activó correctamente.
 */
bool	   Ability_SpeedFreak_Activate(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return false;

	// Guardar HP original
	g_iSpeedFreak_OriginalHealth[client] = GetClientHealth(client);

	// Reducir HP a 50
	SetEntityHealth(client, SPEEDFREAK_HP);

	// Aplicar velocidad via speed manager con duración automática
	SPD_Apply(client, SpeedLayer_SpeedFreak, SPEEDFREAK_SPEED, SPEEDFREAK_DURATION);

	// Efecto visual azul (Fade In)
	FX_SetFade(client, 60000, 500, FFADE_IN, 0, 100, 255, 60);

	// Partícula en el jugador
	FX_AttachParticle(client, PARTICLE_ADRENALINE, SPEEDFREAK_DURATION);

	PrintToChat(client, "\x04[Speed Freak]\x01 ¡Velocidad máxima! HP reducido a \x04%d\x01.", SPEEDFREAK_HP);

	// Timer para restaurar HP y efectos al expirar
	CreateTimer(SPEEDFREAK_DURATION, _SpeedFreak_TimerExpire, client, TIMER_FLAG_NO_MAPCHANGE);

	return true;
}

/**
 * Desactiva Speed Freak para un cliente.
 * Puede llamarse antes de que expire el timer (por muerte, desconexión, etc.).
 *
 * @param client    Índice del cliente.
 */
void Ability_SpeedFreak_Deactivate(int client)
{
	if (!IsClientInGame(client)) return;

	// Remover capa de velocidad — el manager restaura automáticamente
	// la siguiente capa activa (ej: TeamBoost si estaba activo)
	SPD_Remove(client, SpeedLayer_SpeedFreak);

	// Restaurar HP si sigue vivo
	if (IsPlayerAlive(client))
	{
		int currentHP = GetClientHealth(client);
		if (currentHP < SPEEDFREAK_HP_RESTORE && g_iSpeedFreak_OriginalHealth[client] >= SPEEDFREAK_HP_RESTORE)
			SetEntityHealth(client, SPEEDFREAK_HP_RESTORE);
	}

	g_iSpeedFreak_OriginalHealth[client] = 0;

	// Limpiar efecto visual (Fade Out)
	FX_ClearFade(client);

	PrintToChat(client, "\x05[Speed Freak]\x01 Efecto terminado. Velocidad restaurada.");
}

/**
 * Retorna true si Speed Freak está activo para el cliente.
 */
stock bool SpeedFreak_IsActive(int client)
{
	return SPD_HasLayer(client, SpeedLayer_SpeedFreak);
}

/**
 * Limpieza al desconectar (llamar desde OnClientDisconnect).
 */
stock void SpeedFreak_OnClientDisconnect(int client)
{
	g_iSpeedFreak_OriginalHealth[client] = 0;
	// SPD_OnClientDisconnect ya limpia la capa, no necesita llamarse aquí
	// si TeamSpeedBoost_OnClientDisconnect ya lo invoca.
}

// =============================================================================
// INTERNAL
// =============================================================================
public Action _SpeedFreak_TimerExpire(Handle timer, int client)
{
	// Solo desactivar si sigue activo (evita doble deactivate si se llamó manualmente)
	if (SpeedFreak_IsActive(client))
		Ability_SpeedFreak_Deactivate(client);

	return Plugin_Stop;
}
