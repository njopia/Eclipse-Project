//==================================================
// === FLAMESHIELD ABILITY (Level 16) ===
// Creates a shield of fire that ignites nearby zombies
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

#define FLAMESHIELD_RADIUS 200.0
#define FLAMESHIELD_DAMAGE 5.0  // Daño por tick
#define FLAMESHIELD_DAMAGE_INTERVAL 0.5  // Cada 0.5 segundos

Handle g_hFlameshield_Timer[MAXPLAYERS + 1];
int g_iFlameshield_ParticleRef[MAXPLAYERS + 1];

/**
 * Activa Flameshield
 */
bool Ability_Flameshield_Activate(int client)
{
	// Crear efecto de partículas de fuego
	Flameshield_CreateFireEffect(client);

	// Iniciar timer de daño
	g_hFlameshield_Timer[client] = CreateTimer(FLAMESHIELD_DAMAGE_INTERVAL, Timer_Flameshield_Damage, GetClientUserId(client), TIMER_REPEAT);

	// Efecto visual naranja
	int clients[1];
	clients[0] = client;
	int color[4] = {255, 100, 0, 120};
	int duration = 60000;
	int flags = 0x0001;

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, 500);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
		EndMessage();
	}

	PrintToChat(client, "\x04[Flameshield]\x01 ¡Escudo de fuego activado! Quemas a zombies cercanos.");
	return true;
}

/**
 * Desactiva Flameshield
 */
void Ability_Flameshield_Deactivate(int client)
{
	if (!IsClientInGame(client))
		return;

	// Detener timer
	if (g_hFlameshield_Timer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hFlameshield_Timer[client]);
		g_hFlameshield_Timer[client] = INVALID_HANDLE;
	}

	// Remover efecto de partículas
	if (g_iFlameshield_ParticleRef[client] != 0)
	{
		int particle = EntRefToEntIndex(g_iFlameshield_ParticleRef[client]);
		if (particle != INVALID_ENT_REFERENCE)
		{
			RemoveEntity(particle);
		}
		g_iFlameshield_ParticleRef[client] = 0;
	}

	// Limpiar efecto visual
	int clients[1];
	clients[0] = client;
	int color[4] = {0, 0, 0, 0};

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, 500);
		BfWriteShort(message, 500);
		BfWriteShort(message, 0x0002);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
		EndMessage();
	}
}

/**
 * Timer: Daño de Flameshield a infectados cercanos
 */
public Action Timer_Flameshield_Damage(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	if (!Abilities_IsActive(client, Ability_Flameshield))
		return Plugin_Stop;

	// Obtener posición del jugador
	float clientPos[3];
	GetClientAbsOrigin(client, clientPos);

	int infectadosQuemados = 0;

	// Buscar infectados cercanos (especiales)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			float targetPos[3];
			GetClientAbsOrigin(i, targetPos);

			float distance = GetVectorDistance(clientPos, targetPos);
			if (distance <= FLAMESHIELD_RADIUS)
			{
				// Aplicar daño e incendiar
				SDKHooks_TakeDamage(i, client, client, FLAMESHIELD_DAMAGE, DMG_BURN);

				// Incendiar al infectado
				Flameshield_IgniteEntity(i, client, 3.0);
				infectadosQuemados++;
			}
		}
	}

	// También buscar infectados comunes cercanos
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != -1)
	{
		float targetPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", targetPos);

		float distance = GetVectorDistance(clientPos, targetPos);
		if (distance <= FLAMESHIELD_RADIUS)
		{
			// Incendiar infectado común
			Flameshield_IgniteEntity(entity, client, 3.0);
			infectadosQuemados++;
		}
	}

	// Debug: mostrar cuántos infectados se quemaron
	if (infectadosQuemados > 0)
	{
		PrintHintText(client, "Flameshield: %d infectados quemados", infectadosQuemados);
	}

	return Plugin_Continue;
}

/**
 * Crea efecto de partículas de fuego
 */
void Flameshield_CreateFireEffect(int client)
{
	// Crear partícula de fuego
	int particle = CreateEntityByName("info_particle_system");
	if (particle == -1)
		return;

	char targetName[32];
	Format(targetName, sizeof(targetName), "flameshield_%d", client);

	DispatchKeyValue(client, "targetname", targetName);
	DispatchKeyValue(particle, "targetname", "flameshield_particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", "fire_medium_02");

	DispatchSpawn(particle);
	ActivateEntity(particle);

	// Parent al jugador
	SetVariantString(targetName);
	AcceptEntityInput(particle, "SetParent");

	// Iniciar efecto
	AcceptEntityInput(particle, "Start");

	// Guardar referencia
	g_iFlameshield_ParticleRef[client] = EntIndexToEntRef(particle);
}

/**
 * Wrapper para incendiar entidades (compatible con y sin Left4DHooks)
 */
stock void Flameshield_IgniteEntity(int entity, int attacker, float duration)
{
	#pragma unused attacker

	if (!IsValidEntity(entity))
		return;

	// Si Left4DHooks está disponible, usar la función nativa
	#if defined _l4dhooks_included
		L4D2_Ignite(entity, duration);
		return;
	#endif

	// Para jugadores (infectados especiales): usar IgniteEntity de SDKTools
	if (entity > 0 && entity <= MaxClients)
	{
		if (IsClientInGame(entity))
		{
			IgniteEntity(entity, duration);
		}
		return;
	}

	// Para entidades (infectados comunes): usar método extendido
	ExtinguishEntity(entity); // Apagar fuego existente primero
	IgniteEntity(entity, duration); // Intentar IgniteEntity primero

	// Método adicional para asegurar que se vea el fuego
	char targetName[32];
	Format(targetName, sizeof(targetName), "flameshield_t_%d", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	int flame = CreateEntityByName("entityflame");
	if (flame != -1)
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);

		DispatchKeyValue(flame, "target", targetName);
		DispatchKeyValueFloat(flame, "lifetime", duration);
		DispatchKeyValue(flame, "damagescale", "2.0");

		DispatchSpawn(flame);
		TeleportEntity(flame, pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(flame);
		AcceptEntityInput(flame, "TurnOn");

		// Parent al infectado
		SetVariantString(targetName);
		AcceptEntityInput(flame, "SetParent");

		// Auto-destruir
		CreateTimer(duration + 0.5, Timer_RemoveFlame, EntIndexToEntRef(flame), TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * Timer para remover la llama
 */
public Action Timer_RemoveFlame(Handle timer, int flameRef)
{
	int flame = EntRefToEntIndex(flameRef);
	if (flame != INVALID_ENT_REFERENCE && IsValidEntity(flame))
	{
		RemoveEntity(flame);
	}
	return Plugin_Stop;
}
