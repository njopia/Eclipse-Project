#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//////////////////////////////////////////
// HUD SYSTEM DISPLAY - Buy System Info  //
//////////////////////////////////////////

/**
 * Este módulo extiende l4d2_scripted_hud para mostrar información dinámica
 * del sistema !buy en el HUD scripted del juego.
 *
 * Muestra:
 * - Tiempo restante de Team Speed Boost
 * - Cooldown de Team Speed Boost
 * - Tiempo restante de Team Heal
 * - Cooldown de Team Heal
 * - Estados y duraciones de deployables
 */

// --- Defines ---
#define HUD_UPDATE_INTERVAL 0.5  // Actualizar HUD cada 0.5 segundos

// --- Forward declarations ---
// Estas funciones deben estar disponibles en otros módulos del sistema

// Desde team-speed-boost.feature.sp
forward public float GetTeamSpeedBoostRemaining(int client);
forward public float GetTeamSpeedBoostCooldown(int client);

// Desde team-heal.feature.sp
forward public float GetTeamHealCooldown(int client);

// --- Variables de buffers para HUD ---
static char g_sHUD2_CustomText[512]  = "";
static char g_sHUD3_CustomText[512]  = "";

// ============================================
// INICIALIZACIÓN DEL MÓDULO
// ============================================

/**
 * Inicializa el sistema de HUD dinámico
 * Llamar desde buyMenuOnPluginStart()
 */
stock void HUDSystemDisplay_OnPluginStart()
{
	// Crear timer para actualizar valores dinámicos del HUD
	CreateTimer(HUD_UPDATE_INTERVAL, Timer_UpdateHUDDisplayValues, _, TIMER_REPEAT);

	LogToFile(logfilepath, "[HUD Display] Sistema de HUD dinámico iniciado");
}

/**
 * Timer principal para actualizar los valores del HUD
 */
public Action Timer_UpdateHUDDisplayValues(Handle timer)
{
	// Construir texto para HUD2 (Team Bonuses)
	BuildTeamBonusesHUDText();

	// Construir texto para HUD3 (Deployables)
	BuildDeployablesHUDText();

	return Plugin_Continue;
}

// ============================================
// CONSTRUCCIÓN DE TEXTOS PARA HUD2
// ============================================

/**
 * Construye el texto dinámico para mostrar estado de Team Bonuses
 * Este texto será consumido por GetHUD2_Text() en l4d2_scripted_hud.sp
 */
static void BuildTeamBonusesHUDText()
{
	char buffer[512];
	char tempBuffer[256];
	int survivors = 0;
	float speedBoostTime = 0.0;
	float teamHealTime = 0.0;

	// Contar supervivientes activos y obtener tiempos
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsSurvivor(client) || !IsPlayerAlive(client))
			continue;

		survivors++;

		// Obtener tiempo restante de Team Speed Boost
		float tsbRemaining = GetTeamSpeedBoostRemaining(client);
		if (tsbRemaining > speedBoostTime)
			speedBoostTime = tsbRemaining;

		// Obtener tiempo restante de Team Heal (si existe)
		float thRemaining = GetTeamHealRemaining(client);
		if (thRemaining > teamHealTime)
			teamHealTime = thRemaining;
	}

	// Encabezado
	FormatEx(buffer, sizeof(buffer), "=== TEAM BONUSES ===\n");

	// Team Speed Boost
	if (speedBoostTime > 0.0)
	{
		int minutes = RoundToNearest(speedBoostTime) / 60;
		int seconds = RoundToNearest(speedBoostTime) % 60;
		Format(tempBuffer, sizeof(tempBuffer), "Speed Boost: %d:%02d\n", minutes, seconds);
		StrCat(buffer, sizeof(buffer), tempBuffer);
	}
	else
	{
		StrCat(buffer, sizeof(buffer), "Speed Boost: READY\n");
	}

	// Team Heal - mostrar cooldown
	// NOTA: Team Heal en la implementación actual es instantáneo por ticks,
	// así que solo mostramos el cooldown (tiempo hasta que pueda activarse de nuevo)
	float teamHealCooldown = GetTeamHealCooldown(1);  // Usar primer survivor como referencia
	if (teamHealCooldown > 0.0)
	{
		int seconds = RoundToNearest(teamHealCooldown);
		Format(tempBuffer, sizeof(tempBuffer), "Team Heal CD: %ds\n", seconds);
		StrCat(buffer, sizeof(buffer), tempBuffer);
	}
	else
	{
		StrCat(buffer, sizeof(buffer), "Team Heal: READY\n");
	}

	// Mostrar número de supervivientes
	Format(tempBuffer, sizeof(tempBuffer), "Survivors: %d/%d", survivors, GetMaxSurvivors());
	StrCat(buffer, sizeof(buffer), tempBuffer);

	// Almacenar en variable global
	strcopy(g_sHUD2_CustomText, sizeof(g_sHUD2_CustomText), buffer);
}

/**
 * Construye el texto dinámico para mostrar estado de Deployables
 * Este texto será consumido por GetHUD3_Text() en l4d2_scripted_hud.sp
 */
static void BuildDeployablesHUDText()
{
	char buffer[512];
	char tempBuffer[256];
	int deployablesActive = 0;

	FormatEx(buffer, sizeof(buffer), "=== DEPLOYABLES ===\n");

	// Contar y listar deployables activos
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsSurvivor(client))
			continue;

		// Verificar UV Light activo
		if (IsUVLightActive(client))
		{
			float remaining = GetUVLightRemaining(client);
			if (remaining > 0.0)
			{
				int seconds = RoundToNearest(remaining);
				Format(tempBuffer, sizeof(tempBuffer), "UV Light: %ds\n", seconds);
				StrCat(buffer, sizeof(buffer), tempBuffer);
				deployablesActive++;
			}
		}

		// Verificar Healing Station activa
		if (IsHealingStationActive(client))
		{
			float remaining = GetHealingStationRemaining(client);
			if (remaining > 0.0)
			{
				int seconds = RoundToNearest(remaining);
				Format(tempBuffer, sizeof(tempBuffer), "Healing Station: %ds\n", seconds);
				StrCat(buffer, sizeof(buffer), tempBuffer);
				deployablesActive++;
			}
		}
	}

	// Si no hay deployables, mostrar mensaje
	if (deployablesActive == 0)
	{
		StrCat(buffer, sizeof(buffer), "None active");
	}

	// Almacenar en variable global
	strcopy(g_sHUD3_CustomText, sizeof(g_sHUD3_CustomText), buffer);
}

// ============================================
// FUNCIONES DE ACCESO PARA l4d2_scripted_hud
// ============================================

/**
 * Obtiene el texto personalizado para HUD2 (Team Bonuses)
 * Llamar desde GetHUD2_Text() en l4d2_scripted_hud.sp
 */
stock void GetTeamBonusesHUDText(char[] output, int size)
{
	strcopy(output, size, g_sHUD2_CustomText);
}

/**
 * Obtiene el texto personalizado para HUD3 (Deployables)
 * Llamar desde GetHUD3_Text() en l4d2_scripted_hud.sp
 */
stock void GetDeployablesHUDText(char[] output, int size)
{
	strcopy(output, size, g_sHUD3_CustomText);
}

// ============================================
// FUNCIONES AUXILIARES
// ============================================

/**
 * Obtiene el número máximo de supervivientes en la ronda
 */
static int GetMaxSurvivors()
{
	int count = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsSurvivor(client))
		{
			count++;
		}
	}
	return count;
}

/**
 * Verifica si UV Light está activo para un cliente
 */
static bool IsUVLightActive(int client)
{
	// Esta función depende de la implementación en uv-light.feature.sp
	// Retorna true si tiene UV Light activo
	// Por ahora retornamos false como placeholder
	return false;
}

/**
 * Obtiene tiempo restante de UV Light para un cliente
 */
static float GetUVLightRemaining(int client)
{
	// Esta función depende de la implementación en uv-light.feature.sp
	// Por ahora retornamos 0.0 como placeholder
	return 0.0;
}

/**
 * Verifica si Healing Station está activa para un cliente
 */
static bool IsHealingStationActive(int client)
{
	// Esta función depende de la implementación en healing-station.feature.sp
	// Retorna true si tiene Healing Station activa
	// Por ahora retornamos false como placeholder
	return false;
}

/**
 * Obtiene tiempo restante de Healing Station para un cliente
 */
static float GetHealingStationRemaining(int client)
{
	// Esta función depende de la implementación en healing-station.feature.sp
	// Por ahora retornamos 0.0 como placeholder
	return 0.0;
}

/**
 * Obtiene tiempo restante de Team Heal para un cliente
 *
 * NOTA: Team Heal en la implementación actual solo tiene cooldown, no duración activa.
 * Por lo tanto, solo verificamos el cooldown (cuando está "en recarga")
 */
static float GetTeamHealRemaining(int client)
{
	// Team Heal solo utiliza cooldown (g_fNextTeamHeal)
	// No tiene duración activa como Team Speed Boost
	// Por lo tanto, siempre retorna 0.0 (la curación es instantánea por ticks)
	return 0.0;

	// Si en el futuro Team Heal se modifica para tener duración,
	// agregar variable g_fTeamHealEnd[client] similar a Team Speed Boost
	// y descomentar:
	// float remaining = g_fTeamHealEnd[client] - GetGameTime();
	// return (remaining > 0.0) ? remaining : 0.0;
}
