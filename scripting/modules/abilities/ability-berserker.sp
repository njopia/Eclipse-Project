//==================================================
// === BERSERKER ABILITY (Level 5) ===
// Gives adrenaline effect for increased speed and attack rate
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

/**
 * Activa Berserker
 */
bool Ability_Berserker_Activate(int client)
{
	if (!IsValidClient(client))
		return false;

	// Activar night vision (efecto visual)
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);

	// Aplicar efecto de adrenalina por 60 segundos
	// Esto aumenta velocidad de movimiento y velocidad de ataque
	L4D2_AdrenalineUsed(client, 60.0);

	// Grito de habilidad (efecto de sonido)
	AbilityShout(client);

	PrintToChat(client, "\x04[Berserker]\x01 Adrenaline rush activated!");
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

	PrintToChat(client, "\x04[Berserker]\x01 Berserker deactivated");
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
