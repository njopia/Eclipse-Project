//==================================================
// === INSTAGIB ABILITY (Level 46) ===
// Anti-virus coated ammunition - extremely deadly
// Massive damage multiplier against infected
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

#define INSTAGIB_DAMAGE_MULTIPLIER 10.0  // 10x dano contra infectados
#define INSTAGIB_CRIT_CHANCE 100  // 100% de probabilidad de instakill - SIEMPRE MATA

// Efectos de explosion
#define PARTICLE_BLOOD_EXPLODE "boomer_explode_D"
#define PARTICLE_EXPLODE "boomer_explode"

// Sonidos de explosion (se reproducen aleatoriamente)
char g_szInstagib_ExplosionSounds[][] = {
	"player/boomer/explode/explo_medium_09.wav",
	"player/boomer/explode/explo_medium_10.wav",
	"player/boomer/explode/explo_medium_14.wav"
};

/**
 * Activa Instagib
 */
bool Ability_Instagib_Activate(int client)
{
	// Activar night vision para efecto dramatico
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);

	PrintToChat(client, "\x04[Instagib]\x01 Municion anti-virus! Dano 10x + \x03INSTAKILL GARANTIZADO\x01 (explosion de cuerpos)");
	return true;
}

/**
 * Desactiva Instagib
 */
void Ability_Instagib_Deactivate(int client)
{
	if (!IsClientInGame(client))
		return;

	// Desactivar night vision
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
}

/**
 * Hook de dano para Instagib
 */
public Action Instagib_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Si el atacante tiene Instagib activo
	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (!Abilities_IsActive(attacker, Ability_Instagib))
		return Plugin_Continue;

	// CASO 1: Victim es un jugador infectado (infectado especial o tank)
	if (victim > 0 && victim <= MaxClients && IsClientInGame(victim) && GetClientTeam(victim) == 3)
	{
		// Multiplicar dano
		damage *= INSTAGIB_DAMAGE_MULTIPLIER;

		// Probabilidad de instakill (100% - siempre mata)
		int roll = GetRandomInt(1, 100);
		if (roll <= INSTAGIB_CRIT_CHANCE)
		{
			damage = 999999.0;  // Instakill
			PrintHintText(attacker, "INSTAGIB!");

			// Obtener posicion para efectos
			float victimPos[3];
			GetClientAbsOrigin(victim, victimPos);

			// Efecto visual de beam ring
			TE_SetupBeamRingPoint(victimPos, 10.0, 200.0, PrecacheModel("materials/sprites/laserbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.3, 10.0, 0.0, {255, 255, 255, 255}, 10, 0);
			TE_SendToAll();

			// Efecto de explosion del cuerpo
			Instagib_CreateExplosion(victimPos);
		}

		return Plugin_Changed;
	}

	// CASO 2: Victim es una entidad (infected comun, witch, etc)
	if (victim > MaxClients && IsValidEntity(victim))
	{
		char className[64];
		GetEdictClassname(victim, className, sizeof(className));

		if (StrContains(className, "infected") != -1 || StrContains(className, "witch") != -1)
		{
			// Multiplicar dano
			damage *= INSTAGIB_DAMAGE_MULTIPLIER;

			// Probabilidad de instakill (100% - siempre mata)
			int roll = GetRandomInt(1, 100);
			if (roll <= INSTAGIB_CRIT_CHANCE)
			{
				damage = 999999.0;  // Instakill
				PrintHintText(attacker, "INSTAGIB!");

				// Obtener posicion para efectos
				float victimPos[3];
				GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);

				// Efecto visual de beam ring
				TE_SetupBeamRingPoint(victimPos, 10.0, 200.0, PrecacheModel("materials/sprites/laserbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.3, 10.0, 0.0, {255, 255, 255, 255}, 10, 0);
				TE_SendToAll();

				// Efecto de explosion del cuerpo
				Instagib_CreateExplosion(victimPos);
			}

			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

/**
 * Crea efecto de explosion en una posicion
 */
void Instagib_CreateExplosion(float origin[3])
{
	// Crear particula de explosion de boomer
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		TeleportEntity(particle, origin, NULL_VECTOR, NULL_VECTOR);

		DispatchKeyValue(particle, "effect_name", PARTICLE_EXPLODE);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Enable");
		AcceptEntityInput(particle, "start");

		// Auto-destruir despues de 0.1 segundos
		char output[64];
		Format(output, sizeof(output), "OnUser1 !self:Kill::0.1:-1");
		SetVariantString(output);
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
	}

	// Reproducir sonido de explosion aleatorio
	int randomSound = GetRandomInt(0, sizeof(g_szInstagib_ExplosionSounds) - 1);
	EmitSoundToAll(g_szInstagib_ExplosionSounds[randomSound], SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, origin);
}
