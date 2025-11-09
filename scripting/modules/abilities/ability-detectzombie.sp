//==================================================
// === DETECT ZOMBIE ABILITY (Level 3) ===
// See special infected and tanks through walls
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

#define GLOW_COLOR_SPECIAL {255, 0, 0, 255}  // Rojo para especiales
#define GLOW_COLOR_TANK {255, 100, 0, 255}   // Naranja para tanks

int g_iDetectZombie_GlowEntities[MAXPLAYERS + 1][32];  // Guardar refs de glow entities
int g_iDetectZombie_GlowCount[MAXPLAYERS + 1];

/**
 * Activa Detect Zombie
 */
bool Ability_DetectZombie_Activate(int client)
{
	g_iDetectZombie_GlowCount[client] = 0;

	// Crear glow en todos los infectados especiales y tanks
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			int zombieClass = GetEntProp(i, Prop_Send, "m_zombieClass");

			// Solo infectados especiales (no common infected)
			if (zombieClass >= 1 && zombieClass <= 8)
			{
				// Crear glow
				DetectZombie_CreateGlow(client, i, zombieClass == 8); // true si es tank
			}
		}
	}

	PrintToChat(client, "\x04[Detect Zombie]\x01 ¡Puedes ver infectados especiales a través de paredes!");
	return true;
}

/**
 * Desactiva Detect Zombie
 */
void Ability_DetectZombie_Deactivate(int client)
{
	// Remover todos los glow entities
	for (int i = 0; i < g_iDetectZombie_GlowCount[client]; i++)
	{
		int entity = g_iDetectZombie_GlowEntities[client][i];
		if (IsValidEntity(entity))
		{
			RemoveEntity(entity);
		}
	}

	g_iDetectZombie_GlowCount[client] = 0;
}

/**
 * Crea un glow entity para un infectado
 */
void DetectZombie_CreateGlow(int client, int target, bool isTank)
{
	// Crear prop_dynamic_glow
	int glow = CreateEntityByName("prop_dynamic_glow");
	if (glow == -1)
		return;

	// Obtener modelo del target
	char model[PLATFORM_MAX_PATH];
	GetEntPropString(target, Prop_Data, "m_ModelName", model, sizeof(model));

	// Configurar glow
	DispatchKeyValue(glow, "model", model);
	DispatchKeyValue(glow, "disablereceiveshadows", "1");
	DispatchKeyValue(glow, "disableshadows", "1");
	DispatchKeyValue(glow, "solid", "0");
	DispatchKeyValue(glow, "spawnflags", "256");

	// Color según tipo
	if (isTank)
	{
		DispatchKeyValue(glow, "glowcolor", "255 100 0");
	}
	else
	{
		DispatchKeyValue(glow, "glowcolor", "255 0 0");
	}

	DispatchKeyValue(glow, "glowrange", "9999");
	DispatchKeyValue(glow, "glowrangemin", "0");

	// Spawn
	DispatchSpawn(glow);

	// Posicionar en el target
	float pos[3], ang[3];
	GetClientAbsOrigin(target, pos);
	GetClientAbsAngles(target, ang);
	TeleportEntity(glow, pos, ang, NULL_VECTOR);

	// Parent al target para que siga su movimiento
	SetVariantString("!activator");
	AcceptEntityInput(glow, "SetParent", target);

	// Hacer visible solo para este cliente
	SetEntProp(glow, Prop_Send, "m_iGlowType", 3);
	SetEntProp(glow, Prop_Send, "m_glowColorOverride", 16711680); // Rojo en decimal

	// Guardar referencia
	if (g_iDetectZombie_GlowCount[client] < 32)
	{
		g_iDetectZombie_GlowEntities[client][g_iDetectZombie_GlowCount[client]] = EntIndexToEntRef(glow);
		g_iDetectZombie_GlowCount[client]++;
	}
}
