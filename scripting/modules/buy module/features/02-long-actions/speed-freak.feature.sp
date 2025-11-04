#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === SPEED FREAK ACTIVE ABILITY ===
// Velocidad extrema pero solo 50 HP
// Nivel: 31
// Duración: 60 segundos
// Cooldown: 5 minutos (300 segundos)
//==================================================

// --- ConVars ---
Handle cvar_SpeedFreak_Duration		   = INVALID_HANDLE;
Handle cvar_SpeedFreak_Cooldown		   = INVALID_HANDLE;
Handle cvar_SpeedFreak_SpeedMultiplier = INVALID_HANDLE;

// --- Estado del jugador ---
bool   g_bSpeedFreak_Active[MAXPLAYERS + 1];
int	   g_iSpeedFreak_TimeRemaining[MAXPLAYERS + 1];
int	   g_iSpeedFreak_Cooldown[MAXPLAYERS + 1];
int	   g_iSpeedFreak_PreviousMaxHealth[MAXPLAYERS + 1];
Handle g_hSpeedFreak_Timer[MAXPLAYERS + 1];
float  g_fSpeedFreak_EndTime[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de Speed Freak
 */
public void SpeedFreak_OnPluginStart()
{
	cvar_SpeedFreak_Duration = CreateConVar(
		"ability_speedfreak_duration",
		"60",
		"Duración de Speed Freak en segundos",
		FCVAR_PLUGIN);

	cvar_SpeedFreak_Cooldown = CreateConVar(
		"ability_speedfreak_cooldown",
		"30",
		"Cooldown de Speed Freak en segundos",
		FCVAR_PLUGIN);

	cvar_SpeedFreak_SpeedMultiplier = CreateConVar(
		"ability_speedfreak_speed",
		"2.5",
		"Multiplicador de velocidad de Speed Freak",
		FCVAR_PLUGIN);
}

/**
 * Resetea el estado al conectar
 */
public void SpeedFreak_OnClientConnect(int client)
{
	g_bSpeedFreak_Active[client]			= false;
	g_iSpeedFreak_TimeRemaining[client]		= 0;
	g_iSpeedFreak_Cooldown[client]			= 0;
	g_iSpeedFreak_PreviousMaxHealth[client] = 100;
	g_hSpeedFreak_Timer[client]				= INVALID_HANDLE;
	g_fSpeedFreak_EndTime[client]			= 0.0;
}

/**
 * Limpia recursos al desconectar
 */
public void SpeedFreak_OnClientDisconnect(int client)
{
	// Matar timer si existe
	if (g_hSpeedFreak_Timer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hSpeedFreak_Timer[client]);
		g_hSpeedFreak_Timer[client] = INVALID_HANDLE;
	}

	SpeedFreak_Deactivate(client);
	g_iSpeedFreak_Cooldown[client] = 0;
	g_fSpeedFreak_EndTime[client]  = 0.0;
}

/**
 * Actualiza timers cada segundo
 */
public void SpeedFreak_OnSecondTick(int client)
{
	// Reducir cooldown
	if (g_iSpeedFreak_Cooldown[client] > 0)
	{
		g_iSpeedFreak_Cooldown[client]--;
	}

	// Actualizar tiempo restante para display
	if (g_bSpeedFreak_Active[client])
	{
		float currentTime					= GetGameTime();
		float remaining						= g_fSpeedFreak_EndTime[client] - currentTime;
		g_iSpeedFreak_TimeRemaining[client] = RoundToFloor(remaining);

		// Mantener night vision durante toda la duración
		if (g_iSpeedFreak_TimeRemaining[client] > 0)
		{
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);

			// Mostrar hint con tiempo restante
			char hintText[128];
			Format(hintText, sizeof(hintText), "⚡ Speed Freak: %ds restantes | Velocidad x2.5", g_iSpeedFreak_TimeRemaining[client]);
			PrintHintText(client, hintText);
		}
	}
}

/**
 * Hook OnPlayerRunCmd para mantener velocidad constante
 * Se ejecuta cada tick del servidor
 */
public Action SpeedFreak_OnPlayerRunCmd(int client)
{
	if (!g_bSpeedFreak_Active[client])
		return Plugin_Continue;

	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	// Reaplicar velocidad constantemente para evitar que otros sistemas la sobrescriban
	SpeedFreak_ApplySpeed(client);

	return Plugin_Continue;
}

/**
 * Verifica si el jugador puede usar Speed Freak
 */
public bool SpeedFreak_CanUse(int client, int level)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		PrintToChat(client, "\x05[Eclipse]\x01 Debes estar vivo para usar Speed Freak");
		return false;
	}

	if (g_bSpeedFreak_Active[client])
	{
		PrintToChat(client, "\x05[Eclipse]\x01 Speed Freak ya está activo");
		return false;
	}

	if (g_iSpeedFreak_Cooldown[client] > 0)
	{
		int minutes = g_iSpeedFreak_Cooldown[client] / 60;
		int seconds = g_iSpeedFreak_Cooldown[client] % 60;
		PrintToChat(client, "\x05[Eclipse]\x01 Speed Freak en cooldown: %dm %ds", minutes, seconds);
		return false;
	}

	return true;
}

/**
 * Activa Speed Freak
 */
public void SpeedFreak_Activate(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	int duration						= GetConVarInt(cvar_SpeedFreak_Duration);
	int cooldown						= GetConVarInt(cvar_SpeedFreak_Cooldown);

	g_bSpeedFreak_Active[client]		= true;
	g_iSpeedFreak_TimeRemaining[client] = duration;
	g_iSpeedFreak_Cooldown[client]		= cooldown;

	// Guardar tiempo de finalización
	float currentTime					= GetGameTime();
	g_fSpeedFreak_EndTime[client]		= currentTime + float(duration);

	// DEBUG: Notificar activación
	PrintToChat(client, "\x04[ABILITY ACTIVATED]\x01 Speed Freak - Duration: %ds, Speed: 1.5x", duration);

	// Guardar HP máximo actual
	g_iSpeedFreak_PreviousMaxHealth[client] = GetEntProp(client, Prop_Send, "m_iMaxHealth");

	// Reducir HP a 50
	int currentHealth						= GetClientHealth(client);
	SetEntProp(client, Prop_Send, "m_iMaxHealth", 50);

	if (currentHealth > 50)
	{
		SetEntProp(client, Prop_Send, "m_iHealth", 50);
	}

	// Cancelar timer anterior si existe
	if (g_hSpeedFreak_Timer[client] != INVALID_HANDLE)
		KillTimer(g_hSpeedFreak_Timer[client]);

	// Crear timer para mantener la velocidad (cada 0.1 segundos como team bonus)
	g_hSpeedFreak_Timer[client] = CreateTimer(
		0.1,
		Timer_SpeedFreak_MaintainSpeed,
		client,
		TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	// Aplicar velocidad inicial
	SpeedFreak_ApplySpeed(client);

	// Activar night vision
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);

	PrintToChat(client, "\x04[Eclipse]\x01 ¡Speed Freak activado! Velocidad \x05x2.5\x01 por \x05%ds\x01 - HP máximo reducido a \x0350 HP\x01", duration);
}

/**
 * Desactiva Speed Freak
 */
public void SpeedFreak_Deactivate(int client)
{
	if (!g_bSpeedFreak_Active[client])
		return;

	g_bSpeedFreak_Active[client]		= false;
	g_iSpeedFreak_TimeRemaining[client] = 0;
	g_fSpeedFreak_EndTime[client]		= 0.0;

	// Matar timer si existe
	if (g_hSpeedFreak_Timer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hSpeedFreak_Timer[client]);
		g_hSpeedFreak_Timer[client] = INVALID_HANDLE;
	}

	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		// Obtener HP actual antes de restaurar
		int currentHealth = GetClientHealth(client);

		// Restaurar HP máximo al valor previo
		SetEntProp(client, Prop_Send, "m_iMaxHealth", g_iSpeedFreak_PreviousMaxHealth[client]);

		// Si el jugador estaba a HP completo (50/50), restaurarlo proporcionalmente
		if (currentHealth >= 50)
		{
			SetEntityHealth(client, g_iSpeedFreak_PreviousMaxHealth[client]);
		}
		// Si tenía HP parcial, mantener ese HP (puede curarse hasta el nuevo máximo)

		// Reaplicar Health Bonus si corresponde (el timer lo hará automáticamente después)
		// Al desactivar Speed Freak, Health Bonus_EnsureMaxHealth volverá a funcionar

		// Restaurar velocidad normal (usar Prop_Send)
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);

		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
		PrintToChat(client, "\x04[Eclipse]\x01 Speed Freak desactivado - HP máximo restaurado a \x05%d HP\x01", g_iSpeedFreak_PreviousMaxHealth[client]);
	}
	else if (IsClientInGame(client))
	{
		// Cliente no está vivo, solo limpiar efectos visuales
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
	}
}

/**
 * Modifica la velocidad del jugador
 */
public void SpeedFreak_ModifySpeed(int client, float &speed)
{
	if (!g_bSpeedFreak_Active[client])
		return;

	float multiplier = GetConVarFloat(cvar_SpeedFreak_SpeedMultiplier);
	speed *= multiplier;
}

/**
 * Modifica la velocidad de uso de items de curación
 */
public void SpeedFreak_ModifyHealingSpeed(int client)
{
	if (!g_bSpeedFreak_Active[client])
		return;

	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	// Detectar si está usando un item de curación
	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (activeWeapon <= 0 || !IsValidEntity(activeWeapon))
		return;

	char weaponName[64];
	GetEntityClassname(activeWeapon, weaponName, sizeof(weaponName));

	// Acelerar uso de items de curación
	if (StrEqual(weaponName, "weapon_first_aid_kit", false) || StrEqual(weaponName, "weapon_pain_pills", false) || StrEqual(weaponName, "weapon_adrenaline", false) || StrEqual(weaponName, "weapon_defibrillator", false))
	{
		// Aumentar velocidad de uso
		float nextAttack = GetEntPropFloat(activeWeapon, Prop_Send, "m_flNextPrimaryAttack");
		SetEntPropFloat(activeWeapon, Prop_Send, "m_flNextPrimaryAttack", nextAttack - 0.5);
	}
}

/**
 * Obtiene si Speed Freak está activo
 */
public bool SpeedFreak_IsActive(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bSpeedFreak_Active[client];
}

/**
 * Obtiene el cooldown restante
 */
public int SpeedFreak_GetCooldown(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	return g_iSpeedFreak_Cooldown[client];
}

/**
 * Obtiene el tiempo restante de la habilidad
 */
public int SpeedFreak_GetTimeRemaining(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	return g_iSpeedFreak_TimeRemaining[client];
}

/**
 * Resetea el cooldown de Speed Freak para un jugador
 */
stock void SpeedFreak_ResetCooldown(int client)
{
	g_iSpeedFreak_Cooldown[client] = 0;
	g_iSpeedFreak_TimeRemaining[client] = 0;
	g_bSpeedFreak_Active[client] = false;
}

/**
 * Aplica la velocidad aumentada al cliente
 */
static void SpeedFreak_ApplySpeed(int client)
{
	if (!IsClientInGame(client))
		return;

	if (!IsPlayerAlive(client))
		return;

	float speedMultiplier = GetConVarFloat(cvar_SpeedFreak_SpeedMultiplier);
	// Usar Prop_Send en lugar de Prop_Data para consistencia con el sistema
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speedMultiplier);
}

/**
 * Timer para mantener la velocidad aumentada
 */
public Action Timer_SpeedFreak_MaintainSpeed(Handle timer, int client)
{
	float currentTime = GetGameTime();

	if (!IsClientInGame(client))
	{
		g_hSpeedFreak_Timer[client]	  = INVALID_HANDLE;
		g_fSpeedFreak_EndTime[client] = 0.0;
		return Plugin_Stop;
	}

	if (!IsPlayerAlive(client))
	{
		g_hSpeedFreak_Timer[client]	  = INVALID_HANDLE;
		g_fSpeedFreak_EndTime[client] = 0.0;
		return Plugin_Stop;
	}

	// Verificar si el boost ha expirado
	if (currentTime >= g_fSpeedFreak_EndTime[client])
	{
		SpeedFreak_Deactivate(client);
		return Plugin_Stop;
	}

	// Mantener el boost aplicado
	SpeedFreak_ApplySpeed(client);

	return Plugin_Continue;
}
