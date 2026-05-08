#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif
#define _ABILITIES_SYSTEM_MODULE_

//==================================================
// === ABILITIES SYSTEM MODULE ===
// Sistema de habilidades desbloqueables por nivel
// No requieren currency, se activan automaticamente al alcanzar el nivel
//==================================================

// Cooldown de 5 minutos para todas las abilities (como en el backup)
#define ABILITY_COOLDOWN 300.0

// Duracion de 60 segundos para todas las abilities
#define ABILITY_DURATION 60.0

// Variables globales de estado de abilities
bool   g_bAbilityActive[MAXPLAYERS + 1][16];	  // Estado activo de cada ability
float  g_fAbilityCooldown[MAXPLAYERS + 1][16];	  // Tiempo de cooldown
Handle g_hAbilityTimer[MAXPLAYERS + 1][16];		  // Timers de duracion
float  g_fAbilityEndTime[MAXPLAYERS + 1][16];	  // Tiempo de finalizacion de la ability
float  g_fHUDClearUntil[MAXPLAYERS + 1];		  // Hasta cuando enviar hint vacio para limpiar el HUD

// Indices de abilities
enum AbilityIndex
{
	Ability_None			 = 0,
	Ability_DetectZombie	 = 1,	  // Lvl 3
	Ability_Berserker		 = 2,	  // Lvl 5
	Ability_AcidBath		 = 3,	  // Lvl 9
	Ability_Lifestealer		 = 4,	  // Lvl 12
	Ability_Flameshield		 = 5,	  // Lvl 16
	Ability_Nightcrawler	 = 6,	  // Lvl 18
	Ability_RapidFire		 = 7,	  // Lvl 23
	Ability_ChainsawMassacre = 8,	  // Lvl 25
	Ability_HeatSeeker		 = 9,	  // Lvl 27
	Ability_SpeedFreak		 = 10,	  // Lvl 31
	Ability_HealingAura		 = 11,	  // Lvl 33
	// Ability_ShoulderCannon removed - now available in !buy -> Specials
	Ability_Soulshield		 = 13,	  // Lvl 37
	Ability_Polymorph		 = 14,	  // Lvl 39
	Ability_Instagib		 = 15	  // Lvl 46
}

// ConVars
ConVar cvar_AbilitiesEnabled;
ConVar cvar_AbilitiesDebug;

/**
 * Inicializa el sistema de abilities
 */
public void Abilities_OnPluginStart()
{
	// ConVars
	cvar_AbilitiesEnabled = CreateConVar("abilities_enabled", "1", "Habilita el sistema de abilities (1 = habilitado, 0 = deshabilitado)", FCVAR_PLUGIN);
	cvar_AbilitiesDebug	  = CreateConVar("abilities_debug", "0", "Modo debug para abilities", FCVAR_PLUGIN);

	// Timer para actualizar velocidad de melee (Berserker)
	CreateTimer(0.1, Timer_UpdateAbilities, _, TIMER_REPEAT);

	// Precache de Shoulder Cannon
	Ability_ShoulderCannon_Precache();

	// Initialize Detect Zombie
	DetectZombie_OnPluginStart();
	// Timer para el HUD de habilidades (cada 1.0 segundos es suficiente y eficiente)
	CreateTimer(1.0, Timer_UpdateAbilitiesHUD, _, TIMER_REPEAT);
}

/**
 * Inicializa el sistema al cambiar de mapa
 */
public void Abilities_OnMapStart()
{
	// Reset de todas las variables
	for (int i = 1; i <= MaxClients; i++)
	{
		Abilities_ResetPlayer(i);
	}

	// Initialize Detect Zombie for map
	DetectZombie_OnMapStart();
}

/**
 * Limpieza al finalizar el mapa
 */
public void Abilities_OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		Abilities_CleanupTimers(i);
	}
}

/**
 * Reset de un jugador al conectarse
 */
public void Abilities_OnClientConnect(int client)
{
	Abilities_ResetPlayer(client);
}

/**
 * Reset de un jugador
 */
void Abilities_ResetPlayer(int client)
{
	for (int i = 0; i < 16; i++)
	{
		g_bAbilityActive[client][i]	  = false;
		g_fAbilityCooldown[client][i] = 0.0;
		g_fAbilityEndTime[client][i]  = 0.0;

		if (g_hAbilityTimer[client][i] != INVALID_HANDLE)
		{
			KillTimer(g_hAbilityTimer[client][i]);
			g_hAbilityTimer[client][i] = INVALID_HANDLE;
		}
	}

	g_fHUDClearUntil[client] = 0.0;

	// Clean up Detect Zombie clones (the deactivate function handles state reset)
	DetectZombie_KillClone(client);
}

/**
 * Limpia todos los timers de un jugador
 */
void Abilities_CleanupTimers(int client)
{
	for (int i = 0; i < 16; i++)
	{
		if (g_hAbilityTimer[client][i] != INVALID_HANDLE)
		{
			KillTimer(g_hAbilityTimer[client][i]);
			g_hAbilityTimer[client][i] = INVALID_HANDLE;
		}
	}
}

/**
 * Obtiene el nivel requerido para una ability
 */
int Abilities_GetRequiredLevel(AbilityIndex ability)
{
	switch (ability)
	{
		case Ability_DetectZombie: return 3;
		case Ability_Berserker: return 5;
		case Ability_AcidBath: return 9;
		case Ability_Lifestealer: return 12;
		case Ability_Flameshield: return 16;
		case Ability_Nightcrawler: return 18;
		case Ability_RapidFire: return 23;
		case Ability_ChainsawMassacre: return 25;
		case Ability_HeatSeeker: return 27;
		case Ability_SpeedFreak: return 31;
		case Ability_HealingAura: return 33;
		case Ability_Soulshield: return 37;
		case Ability_Polymorph: return 39;
		case Ability_Instagib: return 46;
		default: return 999;
	}
}

/**
 * Obtiene el nombre de una ability
 */
void Abilities_GetName(AbilityIndex ability, char[] buffer, int maxlen)
{
	switch (ability)
	{
		case Ability_DetectZombie: strcopy(buffer, maxlen, "Detect Zombie");
		case Ability_Berserker: strcopy(buffer, maxlen, "Berserker");
		case Ability_AcidBath: strcopy(buffer, maxlen, "Acid Bath");
		case Ability_Lifestealer: strcopy(buffer, maxlen, "Lifestealer");
		case Ability_Flameshield: strcopy(buffer, maxlen, "Flameshield");
		case Ability_Nightcrawler: strcopy(buffer, maxlen, "Nightcrawler");
		case Ability_RapidFire: strcopy(buffer, maxlen, "Rapid Fire");
		case Ability_ChainsawMassacre: strcopy(buffer, maxlen, "Chainsaw Massacre");
		case Ability_HeatSeeker: strcopy(buffer, maxlen, "Heat Seeker");
		case Ability_SpeedFreak: strcopy(buffer, maxlen, "Speed Freak");
		case Ability_HealingAura: strcopy(buffer, maxlen, "Healing Aura");
		case Ability_Soulshield: strcopy(buffer, maxlen, "Soulshield");
		case Ability_Polymorph: strcopy(buffer, maxlen, "Polymorph");
		case Ability_Instagib: strcopy(buffer, maxlen, "Instagib");
		default: strcopy(buffer, maxlen, "Unknown");
	}
}

/**
 * Verifica si el jugador tiene acceso a una ability
 */
bool Abilities_HasAccess(int client, AbilityIndex ability)
{
	if (!IsValidClient(client))
		return false;

	int playerLevel	  = Leveling_GetPlayerLevel(client);
	int requiredLevel = Abilities_GetRequiredLevel(ability);

	return playerLevel >= requiredLevel;
}

/**
 * Verifica si una ability esta en cooldown
 */
bool Abilities_IsOnCooldown(int client, AbilityIndex ability)
{
	if (!IsValidClient(client))
		return true;

	return (GetGameTime() < g_fAbilityCooldown[client][ability]);
}

/**
 * Obtiene el tiempo restante de cooldown
 */
float Abilities_GetCooldownRemaining(int client, AbilityIndex ability)
{
	if (!IsValidClient(client))
		return 0.0;

	float remaining = g_fAbilityCooldown[client][ability] - GetGameTime();
	return (remaining > 0.0) ? remaining : 0.0;
}

/**
 * Obtiene el tiempo restante de duracion de una ability activa
 */
float Abilities_GetDurationRemaining(int client, AbilityIndex ability)
{
	if (!IsValidClient(client) || !Abilities_IsActive(client, ability))
		return 0.0;

	// Calcular tiempo restante basado en el tiempo de finalizacion
	float remaining = g_fAbilityEndTime[client][ability] - GetGameTime();
	return (remaining > 0.0) ? remaining : 0.0;
}

/**
 * Verifica si una ability esta activa
 */
bool Abilities_IsActive(int client, AbilityIndex ability)
{
	if (!IsValidClient(client))
		return false;

	return g_bAbilityActive[client][ability];
}

/**
 * Activa una ability
 */
bool Abilities_Activate(int client, AbilityIndex ability)
{
	if (!IsValidClient(client))
		return false;

	// Verificar si el sistema esta habilitado
	if (!GetConVarBool(cvar_AbilitiesEnabled))
	{
		PrintToChat(client, "\x04[Abilities]\x01 El sistema de abilities esta deshabilitado.");
		return false;
	}

	// Verificar equipo
	if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "\x04[Abilities]\x01 Solo los Survivors pueden usar abilities.");
		return false;
	}

	// Verificar si esta vivo
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "\x04[Abilities]\x01 Debes estar vivo para usar esta ability.");
		return false;
	}

	// Verificar nivel
	if (!Abilities_HasAccess(client, ability))
	{
		int required = Abilities_GetRequiredLevel(ability);
		PrintToChat(client, "\x04[Abilities]\x01 Necesitas nivel %d para usar esta ability.", required);
		return false;
	}

	// Verificar cooldown
	if (Abilities_IsOnCooldown(client, ability))
	{
		float remaining = Abilities_GetCooldownRemaining(client, ability);
		int	  minutes	= RoundToFloor(remaining / 60.0);
		int	  seconds	= RoundToFloor(remaining) % 60;
		PrintToChat(client, "\x04[Abilities]\x01 Cooldown: %d:%02d restantes.", minutes, seconds);
		return false;
	}

	// Verificar si ya esta activa
	if (Abilities_IsActive(client, ability))
	{
		PrintToChat(client, "\x04[Abilities]\x01 Esta ability ya esta activa.");
		return false;
	}
	if (Abilities_HasAnyActive(client))
	{
		PrintToChat(client, "\x04[Abilities]\x01 Ya tienes una habilidad activa. Espera a que termine.");
		return false;
	}

	// Verificar si ya esta activa (esta es la que ya tenias, puedes dejarla o quitarla ya que la de arriba cubre todo)
	if (Abilities_IsActive(client, ability))
	{
		PrintToChat(client, "\x04[Abilities]\x01 Esta ability ya esta activa.");
		return false;
	}
	// Activar la ability segun su tipo
	bool success = false;
	char abilityName[64];
	Abilities_GetName(ability, abilityName, sizeof(abilityName));

	switch (ability)
	{
		case Ability_DetectZombie: success = Ability_DetectZombie_Activate(client);
		case Ability_Berserker: success = Ability_Berserker_Activate(client);
		case Ability_AcidBath: success = Ability_AcidBath_Activate(client);
		case Ability_Lifestealer: success = Ability_Lifestealer_Activate(client);
		case Ability_Flameshield: success = Ability_Flameshield_Activate(client);
		case Ability_Nightcrawler: success = Ability_Nightcrawler_Activate(client);
		case Ability_RapidFire: success = Ability_RapidFire_Activate(client);
		case Ability_ChainsawMassacre: success = Ability_ChainsawMassacre_Activate(client);
		case Ability_HeatSeeker: success = Ability_HeatSeeker_Activate(client);
		case Ability_SpeedFreak: success = Ability_SpeedFreak_Activate(client);
		case Ability_HealingAura: success = Ability_HealingAura_Activate(client);
		case Ability_Soulshield: success = Ability_Soulshield_Activate(client);
		case Ability_Polymorph: success = Ability_Polymorph_Activate(client);
		case Ability_Instagib: success = Ability_Instagib_Activate(client);
	}

	if (success)
	{
		// Marcar como activa
		g_bAbilityActive[client][ability]	= true;

		// Establecer cooldown
		g_fAbilityCooldown[client][ability] = GetGameTime() + ABILITY_COOLDOWN;

		// Guardar tiempo de finalizacion para tracking de duracion
		g_fAbilityEndTime[client][ability]	= GetGameTime() + ABILITY_DURATION;

		// Crear timer de duracion
		Handle data;
		CreateDataTimer(ABILITY_DURATION, Timer_AbilityEnd, data);
		WritePackCell(data, GetClientUserId(client));
		WritePackCell(data, view_as<int>(ability));

		PrintToChat(client, "\x04[%s]\x01 Ability activada! Duracion: %.0f segundos.", abilityName, ABILITY_DURATION);

		if (GetConVarBool(cvar_AbilitiesDebug))
		{
			PrintToChat(client, "\x03[DEBUG]\x01 Cooldown establecido: %.0f segundos.", ABILITY_COOLDOWN);
		}
	}

	return success;
}

/**
 * Timer: Fin de duracion de ability
 */
public Action Timer_AbilityEnd(Handle timer, Handle data)
{
	ResetPack(data);
	int			 userid	 = ReadPackCell(data);
	AbilityIndex ability = view_as<AbilityIndex>(ReadPackCell(data));

	int			 client	 = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client))
		return Plugin_Stop;

	// Desactivar la ability
	Abilities_Deactivate(client, ability);

	char abilityName[64];
	Abilities_GetName(ability, abilityName, sizeof(abilityName));
	PrintToChat(client, "\x04[%s]\x01 Ability desactivada.", abilityName);

	return Plugin_Stop;
}

/**
 * Timer para actualizar abilities que necesitan actualizaciones continuas
 */
public Action Timer_UpdateAbilities(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
			continue;

		// Actualizar velocidad de melee para Berserker
		if (Abilities_IsActive(i, Ability_Berserker))
		{
			Berserker_UpdateMeleeSpeed(i);
		}
	}

	return Plugin_Continue;
}

/**
 * Desactiva una ability
 */
void Abilities_Deactivate(int client, AbilityIndex ability)
{
	if (!IsValidClient(client))
		return;

	g_bAbilityActive[client][ability] = false;
	g_fHUDClearUntil[client]		  = GetGameTime() + 5.0;
	// Llamar a la funcion de desactivacion especifica
	switch (ability)
	{
		case Ability_DetectZombie: Ability_DetectZombie_Deactivate(client);
		case Ability_Berserker: Ability_Berserker_Deactivate(client);
		case Ability_AcidBath: Ability_AcidBath_Deactivate(client);
		case Ability_Lifestealer: Ability_Lifestealer_Deactivate(client);
		case Ability_Flameshield: Ability_Flameshield_Deactivate(client);
		case Ability_Nightcrawler: Ability_Nightcrawler_Deactivate(client);
		case Ability_RapidFire: Ability_RapidFire_Deactivate(client);
		case Ability_ChainsawMassacre: Ability_ChainsawMassacre_Deactivate(client);
		case Ability_HeatSeeker: Ability_HeatSeeker_Deactivate(client);
		case Ability_SpeedFreak: Ability_SpeedFreak_Deactivate(client);
		case Ability_HealingAura: Ability_HealingAura_Deactivate(client);
		case Ability_Soulshield: Ability_Soulshield_Deactivate(client);
		case Ability_Polymorph: Ability_Polymorph_Deactivate(client);
		case Ability_Instagib: Ability_Instagib_Deactivate(client);
	}
}

/**
 * Utilidad: Verifica si un cliente es valido
 */
stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

//==================================================
// === COMANDOS ===
//==================================================

/**
 * Comando: Menu de abilities
 */
public Action Command_AbilitiesMenu(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	ShowAbilitiesMenu(client);
	return Plugin_Handled;
}

/**
 * Muestra el menu de abilities
 */
void ShowAbilitiesMenu(int client)
{
	int level = Leveling_GetPlayerLevel(client);

	// Nivel minimo para acceder al menu (basado en la primera habilidad: Detect Zombie nivel 3)
	if (level < 3)
	{
		PrintToChat(client, "\x04[Abilities]\x01 Necesitas alcanzar el nivel 3 para desbloquear habilidades.");
		return;
	}

	Menu menu = new Menu(AbilitiesMenu_Handler);
	menu.SetTitle("=== MENU DE HABILIDADES ===\nNivel: %d\n ", level);

	char display[128];
	char info[8];

	// Verificamos si ya hay alguna habilidad activa globalmente para este cliente
	bool bAnyActive = Abilities_HasAnyActive(client);

	// Listar SOLO las habilidades desbloqueadas
	for (int i = 1; i < 16; i++)
	{
		AbilityIndex ability  = view_as<AbilityIndex>(i);
		int			 reqLevel = Abilities_GetRequiredLevel(ability);

		// Solo mostrar habilidades que ya han sido desbloqueadas por nivel
		if (level >= reqLevel)
		{
			char abilityName[64];
			Abilities_GetName(ability, abilityName, sizeof(abilityName));

			int style = ITEMDRAW_DEFAULT;

			// CASO 1: La habilidad esta actualmente activa
			if (Abilities_IsActive(client, ability))
			{
				Format(display, sizeof(display), "%s [ACTIVA]", abilityName);
				// Opcional: style = ITEMDRAW_DISABLED; // Si no quieres que puedan clickear la activa
			}
			// CASO 2: La habilidad esta en Cooldown
			else if (Abilities_IsOnCooldown(client, ability))
			{
				float remaining = Abilities_GetCooldownRemaining(client, ability);
				int	  minutes	= RoundToFloor(remaining / 60.0);
				int	  seconds	= RoundToFloor(remaining) % 60;
				Format(display, sizeof(display), "%s [CD: %d:%02d]", abilityName, minutes, seconds);
				style = ITEMDRAW_DISABLED;
			}
			// CASO 3: Hay OTRA habilidad activa (Bloqueo de simultaneidad)
			else if (bAnyActive)
			{
				Format(display, sizeof(display), "%s [ESPERA]", abilityName);
				style = ITEMDRAW_DISABLED;
			}
			// CASO 4: Lista para usar
			else
			{
				Format(display, sizeof(display), "%s [LISTO]", abilityName);
				style = ITEMDRAW_DEFAULT;
			}

			Format(info, sizeof(info), "%d", i);
			menu.AddItem(info, display, style);
		}
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menu de abilities
 */
public int AbilitiesMenu_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));

		AbilityIndex ability = view_as<AbilityIndex>(StringToInt(info));
		Abilities_Activate(client, ability);

		// Reabrir menu despues de un segundo
		CreateTimer(1.0, Timer_ReopenAbilitiesMenu, GetClientUserId(client));
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		// Volver al menu principal si existe
		// FakeClientCommand(client, "sm_menu");
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Timer: Reabrir menu de abilities
 */
public Action Timer_ReopenAbilitiesMenu(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client))
	{
		ShowAbilitiesMenu(client);
	}

	return Plugin_Stop;
}

//==================================================
// === COMANDOS INDIVIDUALES ===
//==================================================
public Action Command_ActivateAbility_DetectZombie(int client, int args)
{
	Abilities_Activate(client, Ability_DetectZombie);
	return Plugin_Handled;
}

public Action Command_ActivateAbility_Berserker(int client, int args)
{
	Abilities_Activate(client, Ability_Berserker);
	return Plugin_Handled;
}

public Action Command_ActivateAbility_AcidBath(int client, int args)
{
	Abilities_Activate(client, Ability_AcidBath);
	return Plugin_Handled;
}

public Action Command_ActivateAbility_Lifestealer(int client, int args)
{
	Abilities_Activate(client, Ability_Lifestealer);
	return Plugin_Handled;
}

public Action Command_ActivateAbility_Flameshield(int client, int args)
{
	Abilities_Activate(client, Ability_Flameshield);
	return Plugin_Handled;
}

public Action Command_ActivateAbility_Nightcrawler(int client, int args)
{
	Abilities_Activate(client, Ability_Nightcrawler);
	return Plugin_Handled;
}

public Action Command_ActivateAbility_RapidFire(int client, int args)
{
	Abilities_Activate(client, Ability_RapidFire);
	return Plugin_Handled;
}

public Action Command_ActivateAbility_ChainsawMassacre(int client, int args)
{
	Abilities_Activate(client, Ability_ChainsawMassacre);
	return Plugin_Handled;
}

public Action Command_ActivateAbility_HeatSeeker(int client, int args)
{
	Abilities_Activate(client, Ability_HeatSeeker);
	return Plugin_Handled;
}

public Action Command_ActivateAbility_SpeedFreak(int client, int args)
{
	Abilities_Activate(client, Ability_SpeedFreak);
	return Plugin_Handled;
}

public Action Command_ActivateAbility_HealingAura(int client, int args)
{
	Abilities_Activate(client, Ability_HealingAura);
	return Plugin_Handled;
}

// Command_ActivateAbility_ShoulderCannon removed - Shoulder Cannon now available in !buy -> Specials
public Action Command_ActivateAbility_Soulshield(int client, int args)
{
	Abilities_Activate(client, Ability_Soulshield);
	return Plugin_Handled;
}

public Action Command_ActivateAbility_Polymorph(int client, int args)
{
	Abilities_Activate(client, Ability_Polymorph);
	return Plugin_Handled;
}

public Action Command_ActivateAbility_Instagib(int client, int args)
{
	Abilities_Activate(client, Ability_Instagib);
	return Plugin_Handled;
}

/**
 * Comando para abrir el menu de Configuracion del Shoulder Cannon
 */
public Action Command_ShoulderCannonMenu(int client, int args)
{
	if (client <= 0 || !IsClientInGame(client))
		return Plugin_Handled;

	ShoulderCannon_ShowMenu(client);
	return Plugin_Handled;
}
/**
 * Verifica si el jugador tiene ALGUNA habilidad activa actualmente.
 */
bool Abilities_HasAnyActive(int client)
{
	for (int i = 1; i < 16; i++)
	{
		if (g_bAbilityActive[client][i])
		{
			return true;
		}
	}
	return false;
}

public Action Timer_UpdateAbilitiesHUD(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
			continue;

		bool bFoundActive = false;
		for (int slot = 1; slot < 16; slot++)
		{
			AbilityIndex ability = view_as<AbilityIndex>(slot);

			if (Abilities_IsActive(i, ability))
			{
				bFoundActive	  = true;
				float remaining = Abilities_GetDurationRemaining(i, ability);
				int	  seconds	= RoundToFloor(remaining);

				char abilityName[64];
				Abilities_GetName(ability, abilityName, sizeof(abilityName));

				if (seconds > 0)
					PrintHintText(i, "%s: %ds restantes", abilityName, seconds);

				break;
			}
		}

		// Si no hay ability activa pero quedo un hint visible, sobreescribir con vacio
		if (!bFoundActive && GetGameTime() < g_fHUDClearUntil[i])
			PrintHintText(i, "");
	}
	return Plugin_Continue;
}