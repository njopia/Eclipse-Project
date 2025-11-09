//==================================================
// === POLYMORPH ABILITY (Level 39) ===
// Transform common zombies into useable items by attacking them
// 1-2% chance this could go wrong (explode)
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

#define POLYMORPH_SUCCESS_CHANCE 98  // 98% de éxito, 2% de fallo

char g_szPolymorph_Items[][] = {
	"weapon_first_aid_kit",
	"weapon_pain_pills",
	"weapon_adrenaline",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_ammo_pack"
};

/**
 * Activa Polymorph
 */
bool Ability_Polymorph_Activate(int client)
{
	// Efecto visual cyan/turquesa
	int clients[1];
	clients[0] = client;
	int color[4] = {0, 255, 255, 90};
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

	PrintToChat(client, "\x04[Polymorph]\x01 ¡Transforma zombies en items! Cuidado: 2%% de fallo (explosión).");
	return true;
}

/**
 * Desactiva Polymorph
 */
void Ability_Polymorph_Deactivate(int client)
{
	if (!IsClientInGame(client))
		return;

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
 * Hook cuando el jugador mata un infectado común
 */
public void Polymorph_OnInfectedKilled(int attacker, int victim)
{
	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return;

	if (!Abilities_IsActive(attacker, Ability_Polymorph))
		return;

	// Verificar que sea un infectado común
	char className[64];
	GetEdictClassname(victim, className, sizeof(className));
	if (!StrEqual(className, "infected"))
		return;

	// Obtener posición del infectado muerto
	float victimPos[3];
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);

	// Probabilidad de éxito
	int roll = GetRandomInt(1, 100);

	if (roll <= POLYMORPH_SUCCESS_CHANCE)
	{
		// Éxito: Spawnear item
		Polymorph_SpawnItem(victimPos);

		// Efecto visual de éxito
		TE_SetupGlowSprite(victimPos, PrecacheModel("sprites/blueglow1.vmt"), 0.5, 1.0, 200);
		TE_SendToAll();

		PrintHintText(attacker, "Polymorph: ¡Item creado!");
	}
	else
	{
		// Fallo: Explosión
		Polymorph_CreateExplosion(victimPos, attacker);

		// Efecto visual de fallo
		TE_SetupGlowSprite(victimPos, PrecacheModel("sprites/redglow1.vmt"), 0.5, 1.0, 200);
		TE_SendToAll();

		PrintHintText(attacker, "Polymorph: ¡FALLÓ! Explosión!");
	}
}

/**
 * Spawnea un item aleatorio
 */
void Polymorph_SpawnItem(float pos[3])
{
	// Elegir item aleatorio
	int randomIndex = GetRandomInt(0, sizeof(g_szPolymorph_Items) - 1);
	char itemName[64];
	strcopy(itemName, sizeof(itemName), g_szPolymorph_Items[randomIndex]);

	// Crear item
	int item = CreateEntityByName(itemName);
	if (item == -1)
		return;

	// Posicionar
	pos[2] += 10.0;  // Elevar un poco
	TeleportEntity(item, pos, NULL_VECTOR, NULL_VECTOR);

	// Spawn
	DispatchSpawn(item);
	ActivateEntity(item);

	// Crear efecto de partículas
	TE_SetupBeamRingPoint(pos, 10.0, 100.0, PrecacheModel("materials/sprites/laserbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.5, 5.0, 0.0, {0, 255, 255, 255}, 10, 0);
	TE_SendToAll();
}

/**
 * Crea una explosión
 */
void Polymorph_CreateExplosion(float pos[3], int attacker)
{
	// Crear explosión con env_explosion
	int explosion = CreateEntityByName("env_explosion");
	if (explosion == -1)
		return;

	DispatchKeyValue(explosion, "iMagnitude", "100");  // Daño
	DispatchKeyValue(explosion, "iRadiusOverride", "200");  // Radio
	DispatchKeyValue(explosion, "spawnflags", "828");  // Flags (daño, humo, etc)

	TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);

	DispatchSpawn(explosion);
	AcceptEntityInput(explosion, "Explode");

	// Aplicar daño al atacante si está cerca
	float attackerPos[3];
	GetClientAbsOrigin(attacker, attackerPos);

	float distance = GetVectorDistance(pos, attackerPos);
	if (distance <= 200.0)
	{
		int damage = RoundToFloor(50.0 * (1.0 - (distance / 200.0)));
		if (damage > 0)
		{
			SDKHooks_TakeDamage(attacker, explosion, explosion, float(damage), DMG_BLAST);
			PrintToChat(attacker, "\x04[Polymorph]\x01 ¡Explosión! -%d HP", damage);
		}
	}

	// Remover la explosión después de 0.1 segundos
	CreateTimer(0.1, Timer_RemoveExplosion, EntIndexToEntRef(explosion));
}

/**
 * Timer: Remover explosión
 */
public Action Timer_RemoveExplosion(Handle timer, int ref)
{
	int explosion = EntRefToEntIndex(ref);
	if (explosion != INVALID_ENT_REFERENCE)
	{
		RemoveEntity(explosion);
	}

	return Plugin_Stop;
}
