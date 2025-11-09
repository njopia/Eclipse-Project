//==================================================
// === DETECT ZOMBIE ABILITY (Level 3) ===
// See special infected and tanks through walls using clones
// Duration: 60 seconds
// Cooldown: 5 minutes
// Based on backup implementation
//==================================================

// Clone tracking arrays
int g_iDetectZombie_Clones[MAXPLAYERS + 1];  // Clone entity for each infected
bool g_bDetectZombie_Active[MAXPLAYERS + 1];  // Is detect active for this survivor
Handle g_hDetectZombie_UpdateTimer = INVALID_HANDLE;  // Global timer for all updates

/**
 * Initialize on plugin start
 */
void DetectZombie_OnPluginStart()
{
	// Start global update timer (1 second interval)
	g_hDetectZombie_UpdateTimer = CreateTimer(1.0, Timer_DetectZombie_Update, _, TIMER_REPEAT);
}

/**
 * Initialize on map start
 */
void DetectZombie_OnMapStart()
{
	// Precache models if needed
}

/**
 * Activa Detect Zombie
 */
bool Ability_DetectZombie_Activate(int client)
{
	if (!IsValidClient(client))
		return false;

	// Enable night vision effect
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
	g_bDetectZombie_Active[client] = true;

	PrintToChat(client, "\x04[Detect Zombie]\x01 Special infected are now visible through walls!");
	return true;
}

/**
 * Desactiva Detect Zombie
 */
void Ability_DetectZombie_Deactivate(int client)
{
	if (!IsValidClient(client))
		return;

	// Disable night vision
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
	g_bDetectZombie_Active[client] = false;

	// Kill all clones
	DetectZombie_KillAllClones();
}

/**
 * Global update timer - creates/updates clones for all infected
 */
public Action Timer_DetectZombie_Update(Handle timer)
{
	// Check if any survivor has detect zombie active
	bool anyActive = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && g_bDetectZombie_Active[i])
		{
			anyActive = true;
			break;
		}
	}

	// If no one has it active, skip clone creation
	if (!anyActive)
		return Plugin_Continue;

	// Create/update clones for each infected
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			int zombieClass = GetEntProp(i, Prop_Send, "m_zombieClass");

			// Only for special infected (1-8, excluding common infected)
			if (zombieClass >= 1 && zombieClass <= 8)
			{
				DetectZombie_CreateOrUpdateClone(i);
			}
		}
		else
		{
			// Not infected or dead, kill clone if exists
			DetectZombie_KillClone(i);
		}
	}

	return Plugin_Continue;
}

/**
 * Creates or updates a clone for an infected
 */
void DetectZombie_CreateOrUpdateClone(int client)
{
	int clone = g_iDetectZombie_Clones[client];

	// If clone doesn't exist, create it
	if (clone <= 0 || !IsValidEntity(clone))
	{
		// Get infected model
		char model[PLATFORM_MAX_PATH];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));

		// Get position and angles
		float origin[3], angles[3];
		GetClientAbsOrigin(client, origin);
		GetClientEyeAngles(client, angles);

		// Create prop_dynamic_override
		int entity = CreateEntityByName("prop_dynamic_override");
		if (entity == -1)
			return;

		SetEntityModel(entity, model);
		DispatchSpawn(entity);
		TeleportEntity(entity, origin, angles, NULL_VECTOR);

		// Disable collision and shadows
		AcceptEntityInput(entity, "DisableCollision");
		AcceptEntityInput(entity, "DisableShadow");
		SetEntProp(entity, Prop_Data, "m_iEFlags", 0);

		// Make invisible but with glow
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 0);

		// Set glow color (yellow for all, or different for tanks)
		int zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		int glowColor = (zombieClass == 8) ? RGBToInt(255, 100, 0) : RGBToInt(250, 250, 0);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", glowColor);
		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);

		// Hook transmit to control visibility
		SDKHook(entity, SDKHook_SetTransmit, Hook_DetectZombie_Transmit);

		g_iDetectZombie_Clones[client] = entity;
	}
	else
	{
		// Clone exists, update position
		float origin[3], angles[3];
		GetClientAbsOrigin(client, origin);
		GetClientEyeAngles(client, angles);
		TeleportEntity(clone, origin, angles, NULL_VECTOR);
	}
}

/**
 * Controls clone visibility - only visible to players with detect zombie active
 */
public Action Hook_DetectZombie_Transmit(int entity, int client)
{
	// Only show to survivors with detect zombie active
	if (IsValidClient(client) && GetClientTeam(client) == 2 && g_bDetectZombie_Active[client])
	{
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

/**
 * Kills a specific clone
 */
void DetectZombie_KillClone(int client)
{
	int clone = g_iDetectZombie_Clones[client];
	if (clone > 0 && IsValidEntity(clone))
	{
		RemoveEntity(clone);
	}
	g_iDetectZombie_Clones[client] = 0;
}

/**
 * Kills all clones
 */
void DetectZombie_KillAllClones()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		DetectZombie_KillClone(i);
	}
}

/**
 * Convert RGB to integer for glow color
 */
int RGBToInt(int r, int g, int b)
{
	return (r + (256 * g) + (65536 * b));
}
