//==================================================
// === BERSERKER ABILITY (Level 5) ===
// Gives adrenaline effect + faster melee attacks
// Duration: 60 seconds
// Cooldown: 5 minutes
// Based on backup implementation
//==================================================

Handle g_hBerserker_HintTimer[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};

/**
 * Activa Berserker
 */
bool Ability_Berserker_Activate(int client)
{
	if (!IsValidClient(client))
		return false;

	// Activar night vision (efecto visual)
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);

	// Aplicar efecto de adrenalina por 60 segundos (aumenta velocidad de movimiento)
	L4D2_UseAdrenaline(client, 60.0);

	// Grito de habilidad (efecto de sonido)
	AbilityShout(client);

	// Iniciar timer de hint para mostrar tiempo restante
	if (g_hBerserker_HintTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hBerserker_HintTimer[client]);
	}
	g_hBerserker_HintTimer[client] = CreateTimer(1.0, Timer_Berserker_Hint, GetClientUserId(client), TIMER_REPEAT);

	PrintToChat(client, "\x04[Berserker]\x01 Adrenaline rush + melee speed boost activated!");
	return true;
}

/**
 * Desactiva Berserker
 */
void Ability_Berserker_Deactivate(int client)
{
	if (!IsValidClient(client))
		return;

	// Desactivar night vision
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);

	// Detener timer de hint
	if (g_hBerserker_HintTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hBerserker_HintTimer[client]);
		g_hBerserker_HintTimer[client] = INVALID_HANDLE;
	}

	PrintToChat(client, "\x04[Berserker]\x01 Berserker deactivated");
}

/**
 * Timer de hint para mostrar tiempo restante
 */
public Action Timer_Berserker_Hint(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client <= 0 || !IsClientInGame(client))
	{
		g_hBerserker_HintTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	if (!Abilities_IsActive(client, Ability_Berserker))
	{
		g_hBerserker_HintTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	// Calcular tiempo restante
	float remaining = Abilities_GetDurationRemaining(client, Ability_Berserker);
	if (remaining > 0.0)
	{
		int seconds = RoundToFloor(remaining);
		PrintHintText(client, "Berserker: %d segundos restantes", seconds);
	}

	return Plugin_Continue;
}

/**
 * Llamado cada frame para modificar velocidad de ataque melee
 * Debe ser llamado desde OnGameFrame o un timer rápido
 */
void Berserker_UpdateMeleeSpeed(int client)
{
	if (!Abilities_IsActive(client, Ability_Berserker))
		return;

	// Solo si tiene arma melee equipada
	int weapon = GetPlayerWeaponSlot(client, 1);
	if (weapon <= 0 || !IsValidEntity(weapon))
		return;

	// Obtener propiedades del arma
	float m_flNextPrimaryAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
	float m_flNextSecondaryAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack");
	float m_flCycle = GetEntPropFloat(weapon, Prop_Send, "m_flCycle");

	// Si el arma está en reposo (m_flCycle == 0), acelerar ataque
	if (m_flCycle == 0.0)
	{
		SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", 2.5);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", m_flNextPrimaryAttack - 0.50);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", m_flNextSecondaryAttack - 0.50);
	}
}

/**
 * Grito de habilidad (efecto de sonido)
 */
void AbilityShout(int client)
{
	if (!IsValidClient(client))
		return;

	// Emitir grito de sobreviviente
	char sound[64];
	int random = GetRandomInt(1, 3);

	switch (random)
	{
		case 1: Format(sound, sizeof(sound), "player/survivor/voice/biker/reactionapprehensive01.wav");
		case 2: Format(sound, sizeof(sound), "player/survivor/voice/biker/reactionapprehensive02.wav");
		case 3: Format(sound, sizeof(sound), "player/survivor/voice/biker/reactionapprehensive03.wav");
	}

	EmitSoundToAll(sound, client, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
}
