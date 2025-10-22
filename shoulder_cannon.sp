/**
 * ====================================================================================
 * Shoulder Cannon - L4D2 SourceMod Plugin
 * ====================================================================================
 *
 * Descripción:
 *   Este plugin proporciona un cañón montado en el hombro con capacidades de
 *   disparo automático y ajustes manuales. Es un arma valiosa contra las hordas zombies.
 *
 * Características:
 *   - Auto-disparo con selección de prioridades de objetivos
 *   - Sistema de munición (500 balas, recargables)
 *   - Configuración de velocidad de disparo
 *   - Filtros de objetivos (nunca atacar ciertos tipos)
 *   - Efectos visuales (trazadores, destellos, partículas)
 *
 * Comandos:
 *   shouldercannon - Abre el menú de configuración del Shoulder Cannon
 *
 * Extraído de: Master_3_46[BACKUP] (2).txt
 * Autor original: Desconocido (Lethal-Injection mod)
 * Extracción: Claude Code
 * Fecha: 2025
 *
 * ====================================================================================
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.0"

// =========================
// Models and Sounds
// =========================
#define MODEL_M60 "models/w_models/weapons/w_m60.mdl"
#define SOUND_M60_FIRE "weapons/machinegun_m60/gunfire/machinegun_fire_1.wav"

// =========================
// Particles
// =========================
#define PARTICLE_BLOOD "blood_impact_red_01"
#define PARTICLE_50CAL_TRACER "weapon_tracers_50cal"
#define PARTICLE_RIFLE_FLASH "weapon_muzzle_flash_assaultrifle"

// =========================
// Plugin Info
// =========================
public Plugin:myinfo =
{
	name = "[L4D2] Shoulder Cannon",
	author = "Unknown (Extracted by Claude Code)",
	description = "Shoulder-mounted auto-cannon for survivors",
	version = PLUGIN_VERSION,
	url = ""
};

// =========================
// Global Variables
// =========================
static CannonEnt[33];           // Entity index del cañón
static CannonAmmo[33];          // Munición disponible
static CannonOn[33];            // 0 = encendido, 1 = deshabilitado
static CannonNeverTarget[33];  // Tipos de enemigos que nunca atacará
static CannonTargetFirst[33];  // Prioridad de objetivos
static Float:CannonRate[33];   // Velocidad de disparo
static CannonEquip[33];         // Auto-equipar al respawn

static iRound = 0;
static Handle:hViewTimer[33];

// ConVars para debug
new Handle:g_hDebugMode = INVALID_HANDLE;
new bool:g_bDebugMode = true;

// =========================
// Plugin Start
// =========================
public OnPluginStart()
{
	// ConVar de debug
	g_hDebugMode = CreateConVar("sc_debug", "1", "Enable debug logging (0=off, 1=on)", FCVAR_NOTIFY);
	g_bDebugMode = GetConVarBool(g_hDebugMode);
	HookConVarChange(g_hDebugMode, OnDebugModeChanged);

	// Registrar comandos (sin ! o /, SourceMod los maneja automáticamente)
	RegConsoleCmd("sm_sc", ShoulderCannonMenu);
	RegConsoleCmd("shouldercannon", ShoulderCannonMenu);

	// Listener para comandos en el chat (!sc y /sc)
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");

	// Hooks de eventos
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", Event_PlayerDisconnect);

	// Inicializar arrays
	for (new i = 1; i <= MaxClients; i++)
	{
		CannonEnt[i] = 0;
		CannonAmmo[i] = 500;
		CannonOn[i] = 0;
		CannonNeverTarget[i] = 0;
		CannonTargetFirst[i] = 0;
		CannonRate[i] = 0.15;
		CannonEquip[i] = 0;
		hViewTimer[i] = INVALID_HANDLE;
	}

	LogMessage("[Shoulder Cannon] Plugin loaded v%s - Debug mode: %s", PLUGIN_VERSION, g_bDebugMode ? "ENABLED" : "DISABLED");
	PrintToServer("[Shoulder Cannon] Plugin loaded v%s - Debug mode: %s", PLUGIN_VERSION, g_bDebugMode ? "ENABLED" : "DISABLED");
}

public OnDebugModeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bDebugMode = GetConVarBool(g_hDebugMode);
	LogMessage("[Shoulder Cannon] Debug mode changed to: %s", g_bDebugMode ? "ENABLED" : "DISABLED");
}

// Función de debug logging
stock DebugLog(const String:format[], any:...)
{
	if (!g_bDebugMode)
		return;

	decl String:buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);
	LogMessage("[SC_DEBUG] %s", buffer);
	PrintToServer("[SC_DEBUG] %s", buffer);
}

// =========================
// Map Start
// =========================
public OnMapStart()
{
	// Precache models
	PrecacheModel(MODEL_M60, true);

	// Precache sounds
	PrecacheSound(SOUND_M60_FIRE, true);

	// Precache particles
	PrecacheParticle(PARTICLE_BLOOD);
	PrecacheParticle(PARTICLE_50CAL_TRACER);
	PrecacheParticle(PARTICLE_RIFLE_FLASH);
}

stock PrecacheParticle(const String:ParticleName[])
{
	// Los efectos de partículas se cargan automáticamente en L4D2
	// Esta función es por compatibilidad
	#pragma unused ParticleName
}

// =========================
// Chat Command Listener
// =========================
public Action:Command_Say(client, const String:command[], argc)
{
	if (client == 0 || !IsClientInGame(client))
		return Plugin_Continue;

	decl String:text[192];
	if (GetCmdArgString(text, sizeof(text)) < 1)
		return Plugin_Continue;

	// Remover comillas
	new startidx = 0;
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	// DEBUG: Mostrar el texto capturado
	DebugLog("Command_Say from client %d: %s", client, text[startidx]);

	// Verificar si es el comando !sc o /sc
	if (StrEqual(text[startidx], "!sc", false) || StrEqual(text[startidx], "/sc", false))
	{
		DebugLog("Command !sc or /sc detected from client %d", client);

		if (GetClientTeam(client) == 2)
		{
			DebugLog("Client %d is on team 2 (survivors), opening menu", client);
			ShoulderCannonMenuFunc(client);
		}
		else
		{
			DebugLog("Client %d is NOT on team 2 (team: %d)", client, GetClientTeam(client));
			PrintToChat(client, "\x04[Shoulder Cannon]\x01 Only survivors can use this command.");
		}

		// Plugin_Handled bloquea que el mensaje aparezca en el chat
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

// =========================
// Events
// =========================
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	iRound++;

	// Resetear munición de todos los jugadores
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			CannonAmmo[i] = 500;
		}
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Remover todos los cañones
	for (new i = 1; i <= MaxClients; i++)
	{
		RemoveShoulderCannon(i);
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		// Auto-equipar si está habilitado
		if (CannonEquip[client] == 1)
		{
			CreateTimer(1.0, Timer_AutoEquip, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Timer_AutoEquip(Handle:timer, any:client)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		EquipShoulderCannon(client);
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client > 0)
	{
		RemoveShoulderCannon(client);
	}
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client > 0)
	{
		RemoveShoulderCannon(client);

		if (hViewTimer[client] != INVALID_HANDLE)
		{
			CloseHandle(hViewTimer[client]);
			hViewTimer[client] = INVALID_HANDLE;
		}
	}
}

// =========================
// Main Functions
// =========================
stock bool:HasCannon(client)
{
	if (client > 0 && IsClientInGame(client))
	{
		if (CannonEnt[client] > 0 && IsValidEntity(CannonEnt[client]))
		{
			return true;
		}
	}
	return false;
}

stock EquipShoulderCannon(client)
{
	DebugLog("EquipShoulderCannon called for client %d", client);

	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		DebugLog("Client %d passed validation checks", client);

		if (CannonEnt[client] <= 0)
		{
			DebugLog("Client %d doesn't have cannon, creating new one", client);

			if (CannonRate[client] < 0.05)
			{
				CannonRate[client] = 0.15;
			}

			new entity = CreateEntityByName("prop_dynamic_override");
			DebugLog("CreateEntityByName('prop_dynamic_override') returned: %d", entity);

			if (entity == -1)
			{
				LogMessage("[Shoulder Cannon] ERROR: Failed to create prop_dynamic_override, trying prop_dynamic");
				entity = CreateEntityByName("prop_dynamic");
				DebugLog("CreateEntityByName('prop_dynamic') returned: %d", entity);
			}

			if (IsValidEntity(entity))
			{
				DebugLog("Entity %d is valid, setting up...", entity);

				// Set model BEFORE spawn
				DispatchKeyValue(entity, "model", MODEL_M60);
				DebugLog("Model set to: %s", MODEL_M60);

				// Set spawnflags for client visibility
				DispatchKeyValue(entity, "spawnflags", "2");  // 2 = Start with collision on
				DebugLog("Spawnflags set");

				DispatchSpawn(entity);
				DebugLog("Entity %d spawned", entity);

				// Activate entity
				ActivateEntity(entity);
				DebugLog("Entity %d activated", entity);

				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", client);
				DebugLog("Entity %d parented to client %d", entity, client);

				SetVariantString("eyes");
				AcceptEntityInput(entity, "SetParentAttachment");
				DebugLog("Parent attachment set to 'eyes'");

				AcceptEntityInput(entity, "DisableCollision");
				AcceptEntityInput(entity, "DisableShadow");
				SetEntProp(entity, Prop_Data, "m_iEFlags", 0);
				SetEntPropFloat(entity, Prop_Data, "m_flModelScale", 0.43);
				DebugLog("Collision/shadow disabled, scale set to 0.43");

				CannonEnt[client] = entity;

				new Float:Origin[3] = {-5.0, -5.0, -6.0};
				new Float:Angles[3] = {-15.0, 0.0, 90.0};
				TeleportEntity(entity, Origin, Angles, NULL_VECTOR);
				DebugLog("Entity %d teleported to offset position", entity);

				RunRepeater(iRound, client, entity);
				DebugLog("RunRepeater started for client %d with entity %d", client, entity);

				SDKHook(entity, SDKHook_SetTransmit, Transmit_ShoulderCannon);
				DebugLog("SDKHook_SetTransmit hooked");

				LogMessage("[Shoulder Cannon] Cannon entity %d equipped to client %d successfully", entity, client);
				PrintToChat(client, "\x04[Shoulder Cannon]\x01 Equipped! Ammo: \x05%i\x01", CannonAmmo[client]);
			}
			else
			{
				LogMessage("[Shoulder Cannon] ERROR: Failed to create valid entity for client %d", client);
			}
		}
		else
		{
			DebugLog("Client %d already has cannon (entity: %d)", client, CannonEnt[client]);
		}
	}
	else
	{
		DebugLog("Client %d failed validation - InGame: %d, IsBot: %d, Alive: %d, Team: %d",
			client,
			IsClientInGame(client),
			IsFakeClient(client),
			IsPlayerAlive(client),
			GetClientTeam(client));
	}
}

stock RemoveShoulderCannon(client)
{
	new entity = CannonEnt[client];
	if (entity > 0 && IsValidEntity(entity))
	{
		new String:classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic", false))
		{
			decl String:model[34];
			GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_M60, false))
			{
				SetEntPropFloat(entity, Prop_Data, "m_flModelScale", 1.0);
				AcceptEntityInput(entity, "Kill");
				CannonEnt[client] = 0;
			}
		}
	}
}

public Action:Transmit_ShoulderCannon(entity, client)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (CannonEnt[i] == entity)
				{
					// Show to everyone (owner and other players)
					// Plugin_Continue = allow the entity to be transmitted
					return Plugin_Continue;
				}
			}
		}
	}
	return Plugin_Continue;
}

// =========================
// Targeting System
// =========================
stock RunRepeater(round, client, entity)
{
	if (CannonRate[client] <= 0.0)
	{
		LogMessage("[Shoulder Cannon] ERROR: Invalid fire rate %.2f for client %d, using default 0.15", CannonRate[client], client);
		CannonRate[client] = 0.15;
	}

	new Handle:Pack = CreateDataPack();
	WritePackCell(Pack, round);
	WritePackCell(Pack, client);
	WritePackCell(Pack, entity);

	DebugLog("RunRepeater: Creating timer with rate %.3f seconds", CannonRate[client]);
	new Handle:timer = CreateTimer(CannonRate[client], CannonRepeater, Pack, TIMER_FLAG_NO_MAPCHANGE);

	if (timer == INVALID_HANDLE)
	{
		LogMessage("[Shoulder Cannon] ERROR: Failed to create timer! Pack handle: %d", Pack);
		CloseHandle(Pack);
	}
	else
	{
		DebugLog("RunRepeater: Timer created successfully");
	}
}

public Action:CannonRepeater(Handle:timer, any:Pack)
{
	ResetPack(Pack, false);
	new round = ReadPackCell(Pack);
	new client = ReadPackCell(Pack);
	new cannon = ReadPackCell(Pack);
	CloseHandle(Pack);

	DebugLog("CannonRepeater: round=%d, client=%d, cannon=%d, iRound=%d", round, client, cannon, iRound);

	if (iRound != round || !IsServerProcessing())
	{
		DebugLog("CannonRepeater: Stopping - round mismatch or server not processing");
		return;
	}

	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		DebugLog("CannonRepeater: Client %d is valid and alive", client);

		if (cannon > 0 && IsValidEntity(cannon) && cannon == CannonEnt[client])
		{
			DebugLog("CannonRepeater: Cannon entity %d is valid", cannon);

			new String:classname[16];
			GetEdictClassname(cannon, classname, sizeof(classname));
			DebugLog("CannonRepeater: Entity classname: %s", classname);

			if (StrEqual(classname, "prop_dynamic", false))
			{
				decl String:model[34];
				GetEntPropString(cannon, Prop_Data, "m_ModelName", model, sizeof(model));
				DebugLog("CannonRepeater: Model name: %s", model);

				if (StrEqual(model, MODEL_M60, false))
				{
					new targetfirst = CannonTargetFirst[client];
					new nevertarget = CannonNeverTarget[client];

					DebugLog("CannonRepeater: CannonOn=%d, Incap=%d, Held=%d", CannonOn[client], IsPlayerIncap(client), IsPlayerHeld(client));

					if (CannonOn[client] == 1 || IsPlayerIncap(client) || IsPlayerHeld(client))
					{
						DebugLog("CannonRepeater: Cannon disabled or player incap/held, looping...");
						RunRepeater(round, client, cannon);
						return;
					}

					new ammo = CannonAmmo[client];
					new Float:Origin[3], Float:TOrigin[3], Float:storeddist = 0.0, Float:distance = 0.0;
					new zombie = 0, special = 0, tank = 0, witch = 0;

					DebugLog("CannonRepeater: Searching for targets - Ammo: %d", ammo);

					if (ammo > 0)
					{
						new zombieCount = 0, specialCount = 0, tankCount = 0, witchCount = 0;

						// Buscar zombies comunes
						new entity = -1;
						while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
						{
							zombieCount++;
							if (nevertarget != 1 && nevertarget != 5 && nevertarget != 6)
							{
								new ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
								if (ragdoll == 0)
								{
									GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
									GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
									distance = GetVectorDistance(Origin, TOrigin);
									if (distance < 600)
									{
										if (storeddist == 0.0 || storeddist > distance)
										{
											if (IsClientViewing(client, entity))
											{
												storeddist = distance;
												zombie = entity;
											}
										}
									}
								}
							}
						}
						DebugLog("Found %d common infected", zombieCount);

						// Buscar witches
						entity = -1;
						while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
						{
							witchCount++;
							if (nevertarget != 3 && nevertarget != 6 && nevertarget != 7)
							{
								new ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
								if (ragdoll == 0)
								{
									GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
									GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
									distance = GetVectorDistance(Origin, TOrigin);
									if (distance < 600)
									{
										if (storeddist == 0.0 || storeddist > distance)
										{
											if (IsClientViewing(client, entity))
											{
												storeddist = distance;
												witch = entity;
											}
										}
									}
								}
							}
						}
						DebugLog("Found %d witches", witchCount);

						// Buscar infectados especiales y tanks
						entity = -1;
						while ((entity = FindEntityByClassname(entity, "player")) != INVALID_ENT_REFERENCE)
						{
							if (IsClientInGame(entity) && IsPlayerAlive(entity) && !IsPlayerGhost(entity) && GetClientTeam(entity) == 3)
							{
								if (IsTank(entity) && nevertarget != 4 && nevertarget != 7)
								{
									tankCount++;
									GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
									GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
									distance = GetVectorDistance(Origin, TOrigin);
									if (distance < 600)
									{
										if (storeddist == 0.0 || storeddist > distance)
										{
											if (IsClientViewing(client, entity))
											{
												storeddist = distance;
												tank = entity;
											}
										}
									}
								}
								else if (IsSpecialInfected(entity) && nevertarget != 2 && nevertarget != 5)
								{
									specialCount++;
									GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
									GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
									distance = GetVectorDistance(Origin, TOrigin);
									if (distance < 600)
									{
										if (storeddist == 0.0 || storeddist > distance)
										{
											if (IsClientViewing(client, entity))
											{
												storeddist = distance;
												special = entity;
											}
										}
									}
								}
							}
						}
						DebugLog("Found %d specials, %d tanks", specialCount, tankCount);
						DebugLog("Target selection - zombie:%d special:%d witch:%d tank:%d, priority:%d", zombie, special, witch, tank, targetfirst);

						// Seleccionar objetivo basado en prioridad
						switch(targetfirst)
						{
							case 0: // Commons first
							{
								if (zombie > 0)
								{
									DestroyTarget(client, zombie, 2);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
								else if (special > 0)
								{
									DestroyTarget(client, special, 1);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
								else if (witch > 0)
								{
									DestroyTarget(client, witch, 2);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
								else if (tank > 0)
								{
									DestroyTarget(client, tank, 1);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
							}
							case 1: // Specials first
							{
								if (special > 0)
								{
									DestroyTarget(client, special, 1);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
								else if (witch > 0)
								{
									DestroyTarget(client, witch, 2);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
								else if (tank > 0)
								{
									DestroyTarget(client, tank, 1);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
								else if (zombie > 0)
								{
									DestroyTarget(client, zombie, 2);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
							}
							case 2: // Witches first
							{
								if (witch > 0)
								{
									DestroyTarget(client, witch, 2);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
								else if (tank > 0)
								{
									DestroyTarget(client, tank, 1);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
								else if (zombie > 0)
								{
									DestroyTarget(client, zombie, 2);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
								else if (special > 0)
								{
									DestroyTarget(client, special, 1);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
							}
							case 3: // Tanks first
							{
								if (tank > 0)
								{
									DestroyTarget(client, tank, 1);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
								else if (zombie > 0)
								{
									DestroyTarget(client, zombie, 2);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
								else if (special > 0)
								{
									DestroyTarget(client, special, 1);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
								else if (witch > 0)
								{
									DestroyTarget(client, witch, 2);
									CannonAmmo[client] -= 1;
									RunRepeater(round, client, cannon);
									return;
								}
							}
						}
					}
					else if (ammo == 0)
					{
						DebugLog("Out of ammo!");
						CannonAmmo[client] = -1;
						PrintToChat(client, "\x04[Shoulder Cannon]\x01 Out of Ammo.");
						RunRepeater(round, client, cannon);
						return;
					}
					else if (ammo < 0)
					{
						DebugLog("Ammo is negative, waiting...");
						RunRepeater(round, client, cannon);
						return;
					}

					DebugLog("No targets found, continuing loop...");
					RunRepeater(round, client, cannon);
				}
				else
				{
					DebugLog("ERROR: Model mismatch! Expected: %s, Got: %s", MODEL_M60, model);
				}
			}
			else
			{
				DebugLog("ERROR: Entity classname mismatch! Expected: prop_dynamic, Got: %s", classname);
			}
		}
		else
		{
			DebugLog("ERROR: Cannon entity invalid or mismatch - cannon:%d, CannonEnt[%d]:%d", cannon, client, CannonEnt[client]);
		}
	}
	else
	{
		DebugLog("ERROR: Client %d not valid, not in game, or dead", client);
	}
}

stock DestroyTarget(client, target, entitytype)
{
	DebugLog("DestroyTarget called - client:%d, target:%d, type:%d", client, target, entitytype);

	new cannon = CannonEnt[client];
	if (cannon > 0 && IsValidEntity(cannon))
	{
		DebugLog("Cannon %d is valid, firing at target %d", cannon, target);

		ShowMuzzleFlash(cannon, PARTICLE_RIFLE_FLASH);
		AttachParticle(target, PARTICLE_BLOOD, 0.1, 0.0, 0.0, 30.0);
		CreateTracerParticles(cannon, target);
		EmitSoundToAll(SOUND_M60_FIRE, client);

		DebugLog("Effects created, dealing damage...");

		switch(entitytype)
		{
			case 1:
			{
				DebugLog("Dealing player damage to target %d", target);
				DealDamagePlayer(target, client, 2, 12, "shoulder_cannon");
			}
			case 2:
			{
				DebugLog("Dealing entity damage to target %d", target);
				DealDamageEntity2(target, client, 2, 12, "shoulder_cannon");
			}
		}

		DebugLog("DestroyTarget completed for target %d", target);
	}
	else
	{
		DebugLog("ERROR: Cannon %d is invalid or not found!", cannon);
	}
}

// =========================
// Particle Effects
// =========================
stock CreateTracerParticles(entity, target)
{
	if (entity > 32 && IsValidEntity(entity) && target > 0 && IsValidEntity(target))
	{
		decl String:name[8];
		decl Float:Origin[3], Float:TOrigin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", TOrigin);
		TOrigin[2] += 30.0;

		new endpoint = CreateEntityByName("info_particle_target");
		if (endpoint > 0 && IsValidEntity(endpoint))
		{
			Format(name, sizeof(name), "cpt%i", endpoint);
			DispatchKeyValue(endpoint, "targetname", name);
			DispatchKeyValueVector(endpoint, "origin", TOrigin);
			DispatchSpawn(endpoint);
			ActivateEntity(endpoint);
			SetVariantString("OnUser1 !self:Kill::0.1:-1");
			AcceptEntityInput(endpoint, "AddOutput");
			AcceptEntityInput(endpoint, "FireUser1");
		}

		new particle = CreateEntityByName("info_particle_system");
		if (particle > 0 && IsValidEntity(particle))
		{
			DispatchKeyValue(particle, "effect_name", PARTICLE_50CAL_TRACER);
			DispatchKeyValue(particle, "cpoint1", name);
			DispatchKeyValueVector(particle, "origin", Origin);
			DispatchSpawn(particle);
			ActivateEntity(particle);
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity);
			SetVariantString("muzzle_flash");
			AcceptEntityInput(particle, "SetParentAttachment");
			AcceptEntityInput(particle, "start");
			SetVariantString("OnUser1 !self:Kill::0.1:-1");
			AcceptEntityInput(particle, "AddOutput");
			AcceptEntityInput(particle, "FireUser1");
			AcceptEntityInput(particle, "ClearParent");
		}
	}
}

stock ShowMuzzleFlash(target, const String:ParticleName[])
{
	if (target > 0 && IsValidEntity(target))
	{
		new particle = CreateEntityByName("info_particle_system");
		if (particle > 0 && IsValidEntity(particle))
		{
			new Float:Origin[3], Float:Angles[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", Origin);
			DispatchKeyValue(particle, "effect_name", ParticleName);
			DispatchKeyValueVector(particle, "origin", Origin);
			DispatchKeyValueVector(particle, "angles", Angles);
			DispatchSpawn(particle);
			ActivateEntity(particle);

			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", target);
			SetVariantString("muzzle_flash");
			AcceptEntityInput(particle, "SetParentAttachment");
			AcceptEntityInput(particle, "Enable");
			AcceptEntityInput(particle, "start");
			GetEntPropVector(particle, Prop_Send, "m_angRotation", Angles);
			Angles[0] -= 90.0;
			TeleportEntity(particle, NULL_VECTOR, Angles, NULL_VECTOR);
			SetVariantString("OnUser1 !self:Kill::0.1:-1");
			AcceptEntityInput(particle, "AddOutput");
			AcceptEntityInput(particle, "FireUser1");
			AcceptEntityInput(particle, "ClearParent");
		}
	}
}

stock AttachParticle(target, const String:ParticleName[], Float:time, Float:x, Float:y, Float:z)
{
	if (target > 0 && IsValidEntity(target))
	{
		new particle = CreateEntityByName("info_particle_system");
		if (IsValidEntity(particle))
		{
			new String:text[28];
			new Float:Origin[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", Origin);
			Origin[0] += x;
			Origin[1] += y;
			Origin[2] += z;
			TeleportEntity(particle, Origin, NULL_VECTOR, NULL_VECTOR);

			DispatchKeyValue(particle, "effect_name", ParticleName);
			DispatchSpawn(particle);
			ActivateEntity(particle);
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", target);
			AcceptEntityInput(particle, "Enable");
			AcceptEntityInput(particle, "start");
			Format(text, sizeof(text), "OnUser1 !self:Kill::%f:-1", time);
			SetVariantString(text);
			AcceptEntityInput(particle, "AddOutput");
			AcceptEntityInput(particle, "FireUser1");
		}
	}
}

// =========================
// Damage Functions
// =========================
stock DealDamagePlayer(target, attacker, dmgtype, dmg, String:inflictor[])
{
	if (target > 0 && target <= 32)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target))
		{
			decl String:damage[16], String:type[16];
			IntToString(dmg, damage, sizeof(damage));
			IntToString(dmgtype, type, sizeof(type));

			new pointHurt = CreateEntityByName("point_hurt");
			if (pointHurt)
			{
				DispatchKeyValue(target, "targetname", "hurtme");
				DispatchKeyValue(pointHurt, "Damage", damage);
				DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
				DispatchKeyValue(pointHurt, "DamageType", type);
				DispatchKeyValue(pointHurt, "classname", inflictor);
				DispatchSpawn(pointHurt);
				AcceptEntityInput(pointHurt, "Hurt", (attacker > 0 && IsClientInGame(attacker))?attacker:-1);
				AcceptEntityInput(pointHurt, "Kill");
				DispatchKeyValue(target, "targetname", "donthurtme");
			}
		}
	}
}

stock DealDamageEntity2(target, attacker, dmgtype, dmg, String:inflictor[])
{
	if (target > 32)
	{
		if (IsValidEntity(target))
		{
			decl String:damage[16], String:type[16];
			IntToString(dmg, damage, sizeof(damage));
			IntToString(dmgtype, type, sizeof(type));

			new pointHurt = CreateEntityByName("point_hurt");
			if (pointHurt)
			{
				if (IsInfected(target) || IsWitch(target))
				{
					new ragdoll = GetEntProp(target, Prop_Data, "m_bClientSideRagdoll");
					if (ragdoll == 0)
					{
						if (IsInfected(target))
						{
							new health = GetEntProp(target, Prop_Data, "m_iHealth");
							if (health <= dmg)
							{
								SetEntProp(target, Prop_Send, "m_iRequestedWound1", GetRandomInt(21,25));
								SetEntProp(target, Prop_Data, "m_bClientSideRagdoll", 1);
							}
						}

						DispatchKeyValue(target, "targetname", "hurtme");
						DispatchKeyValue(pointHurt, "Damage", damage);
						DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
						DispatchKeyValue(pointHurt, "DamageType", type);
						DispatchKeyValue(pointHurt, "classname", inflictor);
						DispatchSpawn(pointHurt);
						if (IsClientInGame(attacker))
						{
							AcceptEntityInput(pointHurt, "Hurt", attacker);
						}
						DispatchKeyValue(target, "targetname", "donthurtme");
					}
				}
				AcceptEntityInput(pointHurt, "Kill");
			}
		}
	}
}

// =========================
// Helper Functions
// =========================
stock bool:IsPlayerGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	return false;
}

stock bool:IsPlayerIncap(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

stock bool:IsPlayerHeld(client)
{
	new jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	new charger = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	new hunter = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	new smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (jockey > 0 || charger > 0 || hunter > 0 || smoker > 0)
	{
		return true;
	}
	return false;
}

stock bool:IsSpecialInfected(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		decl String:classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Smoker", false) || StrEqual(classname, "Boomer", false) ||
			StrEqual(classname, "Hunter", false) || StrEqual(classname, "Spitter", false) ||
			StrEqual(classname, "Jockey", false) || StrEqual(classname, "Charger", false))
		{
			return true;
		}
	}
	return false;
}

stock bool:IsTank(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		decl String:classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Tank", false))
		{
			return true;
		}
	}
	return false;
}

stock bool:IsInfected(entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "infected", false))
		{
			return true;
		}
	}
	return false;
}

stock bool:IsWitch(entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "witch", false))
			return true;
		return false;
	}
	return false;
}

stock bool:IsClientViewing(client, target)
{
	// Simplified visibility check - just verify target is within reasonable FOV
	// The cannon is automatic and should attack visible enemies more liberally

	decl Float:fViewPos[3];
	decl Float:fViewAng[3];
	decl Float:fTargetPos[3];
	decl Float:fViewDir[3];
	decl Float:fTargetDir[3];
	decl Float:fDistance[3];

	GetClientEyePosition(client, fViewPos);
	GetClientEyeAngles(client, fViewAng);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", fTargetPos);
	fTargetPos[2] += 30;

	// Calculate view direction (remove vertical tilt for level view)
	fViewAng[0] = 0.0;  // Remove pitch (up/down)
	GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);

	// Calculate vector to target
	fDistance[0] = fTargetPos[0] - fViewPos[0];
	fDistance[1] = fTargetPos[1] - fViewPos[1];
	fDistance[2] = 0.0;

	// Check if target is within reasonable FOV (less restrictive: 0.35 instead of 0.73)
	// 0.35 allows ~70 degree cone instead of ~43 degree cone
	NormalizeVector(fDistance, fTargetDir);
	new Float:dotProduct = GetVectorDotProduct(fViewDir, fTargetDir);

	DebugLog("IsClientViewing: client=%d target=%d dotProduct=%.2f (threshold=0.35)", client, target, dotProduct);

	if (dotProduct < 0.35)
	{
		DebugLog("IsClientViewing: Target outside FOV cone");
		return false;
	}

	// Optional: Check for line of sight (disabled for more aggressive targeting)
	// Uncomment below if you want to require line of sight
	/*
	new Handle:hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
	if (TR_DidHit(hTrace))
	{
		CloseHandle(hTrace);
		DebugLog("IsClientViewing: Line of sight blocked");
		return false;
	}
	CloseHandle(hTrace);
	*/

	DebugLog("IsClientViewing: Target is valid");
	return true;
}

public bool:ClientViewsFilter(Entity, Mask, any:Junk)
{
	if (Entity <= MaxClients)
	{
		return false;
	}
	return true;
}

stock ExternalView(client, Float:time)
{
	if (client > 0 && IsClientInGame(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", GetGameTime() + time);
	}
}

// =========================
// Menu System
// =========================
public Action:ShoulderCannonMenu(client, args)
{
	if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		ShoulderCannonMenuFunc(client);
	}
	return Plugin_Handled;
}

public Action:ShoulderCannonMenuFunc(client)
{
	DebugLog("ShoulderCannonMenuFunc called for client %d", client);

	if (client > 0)
	{
		decl String:name[34];
		decl String:text[84];
		new cannon = HasCannon(client);
		new enabled = CannonOn[client];
		new equip = CannonEquip[client];
		new nevertarget = CannonNeverTarget[client];
		new targetfirst = CannonTargetFirst[client];
		new Float:cRate = CannonRate[client];

		DebugLog("Creating menu - HasCannon: %d, Ammo: %d", cannon, CannonAmmo[client]);

		new Handle:menu = CreateMenu(SCMHandler);
		Format(text, sizeof(text), "Shoulder Cannon Menu\n====================\nAmmo Count: %i\n====================", CannonAmmo[client]);
		SetMenuTitle(menu, text);
		DebugLog("Menu title set");

		switch(cannon)
		{
			case 0:
			{
				Format(name, sizeof(name), "[ ] Equip Shoulder Cannon");
				AddMenuItem(menu, name, name);
			}
			case 1:
			{
				Format(name, sizeof(name), "[X] Equip Shoulder Cannon");
				AddMenuItem(menu, name, name);

				switch(equip)
				{
					case 0:
					{
						Format(name, sizeof(name), "[ ] Auto Equip Cannon");
						AddMenuItem(menu, name, name);
					}
					case 1:
					{
						Format(name, sizeof(name), "[X] Auto Equip Cannon");
						AddMenuItem(menu, name, name);
					}
				}

				switch(enabled)
				{
					case 0:
					{
						Format(name, sizeof(name), "[ ] Disable Cannon");
						AddMenuItem(menu, name, name);
					}
					case 1:
					{
						Format(name, sizeof(name), "[X] Disable Cannon");
						AddMenuItem(menu, name, name);
					}
				}

				switch(nevertarget)
				{
					case 0:
					{
						Format(name, sizeof(name), "[None] Never Target");
						AddMenuItem(menu, name, name);
					}
					case 1:
					{
						Format(name, sizeof(name), "[Commons] Never Target");
						AddMenuItem(menu, name, name);
					}
					case 2:
					{
						Format(name, sizeof(name), "[Specials] Never Target");
						AddMenuItem(menu, name, name);
					}
					case 3:
					{
						Format(name, sizeof(name), "[Witches] Never Target");
						AddMenuItem(menu, name, name);
					}
					case 4:
					{
						Format(name, sizeof(name), "[Tanks] Never Target");
						AddMenuItem(menu, name, name);
					}
					case 5:
					{
						Format(name, sizeof(name), "[Commons/Specials] Never Target");
						AddMenuItem(menu, name, name);
					}
					case 6:
					{
						Format(name, sizeof(name), "[Commons/Witches] Never Target");
						AddMenuItem(menu, name, name);
					}
					case 7:
					{
						Format(name, sizeof(name), "[Witches/Tanks] Never Target");
						AddMenuItem(menu, name, name);
					}
				}

				switch(targetfirst)
				{
					case 0:
					{
						Format(name, sizeof(name), "[Commons] Target First");
						AddMenuItem(menu, name, name);
					}
					case 1:
					{
						Format(name, sizeof(name), "[Specials] Target First");
						AddMenuItem(menu, name, name);
					}
					case 2:
					{
						Format(name, sizeof(name), "[Witches] Target First");
						AddMenuItem(menu, name, name);
					}
					case 3:
					{
						Format(name, sizeof(name), "[Tanks] Target First");
						AddMenuItem(menu, name, name);
					}
				}

				if (cRate == 0.05)
				{
					Format(name, sizeof(name), "[+0.05] Fastest Fire Rate");
					AddMenuItem(menu, name, name);
				}
				else if (cRate == 0.10)
				{
					Format(name, sizeof(name), "[+0.10] Faster Fire Rate");
					AddMenuItem(menu, name, name);
				}
				else if (cRate == 0.15)
				{
					Format(name, sizeof(name), "[+0.15] Default Fire Rate");
					AddMenuItem(menu, name, name);
				}
				else if (cRate == 0.20)
				{
					Format(name, sizeof(name), "[+0.20] Slower Fire Rate");
					AddMenuItem(menu, name, name);
				}
				else if (cRate == 0.25)
				{
					Format(name, sizeof(name), "[+0.25] Slowest Fire Rate");
					AddMenuItem(menu, name, name);
				}
			}
		}

		SetMenuExitBackButton(menu, true);
		DebugLog("Displaying menu to client %d", client);
		DisplayMenu(menu, client, 40);
	}
	else
	{
		DebugLog("ERROR: client is 0 or invalid");
	}
	return Plugin_Handled;
}

public SCMHandler(Handle:menu, MenuAction:action, client, param1)
{
	DebugLog("SCMHandler called - action:%d, client:%d, param1:%d", action, client, param1);

	decl String:name[34];
	if (action == MenuAction_Select || action == MenuAction_DrawItem)
	{
		GetMenuItem(menu, param1, name, sizeof(name), _, name, sizeof(name));
		DebugLog("SCMHandler selected item: %s", name);
	}

	if (action == MenuAction_End)
	{
		DebugLog("Menu ended");
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		DebugLog("Menu cancelled - reason: %d", param1);
	}
	else if (action == MenuAction_Select)
	{
		GetMenuItem(menu, param1, name, sizeof(name), _, name, sizeof(name));
		DebugLog("Menu item selected: %s", name);

		if (StrEqual(name, "[ ] Equip Shoulder Cannon", false))
		{
			DebugLog("Equipping cannon for client %d", client);

			if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				if (IsPlayerAlive(client))
				{
					DebugLog("Client %d is alive, calling EquipShoulderCannon", client);
					EquipShoulderCannon(client);
					ExternalView(client, 1.3);
				}
				else
				{
					DebugLog("Client %d is dead, cannot equip", client);
					PrintToChat(client,"\x04[Shoulder Cannon]\x01 You can't equip this while you are dead.");
				}
				FakeClientCommand(client, "shouldercannon");
			}
		}
		else if (StrEqual(name, "[X] Equip Shoulder Cannon", false))
		{
			if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				if (IsPlayerAlive(client))
				{
					RemoveShoulderCannon(client);
					PrintToChat(client,"\x04[Shoulder Cannon]\x01 Unequipped.");
				}
				else
				{
					PrintToChat(client,"\x04[Shoulder Cannon]\x01 You can't unequip this while you are dead.");
				}
				FakeClientCommand(client, "shouldercannon");
			}
		}
		else if (StrEqual(name, "[ ] Auto Equip Cannon", false))
		{
			CannonEquip[client] = 1;
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Auto-equip \x05enabled\x01.");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[X] Auto Equip Cannon", false))
		{
			CannonEquip[client] = 0;
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Auto-equip \x03disabled\x01.");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[ ] Disable Cannon", false))
		{
			CannonOn[client] = 1;
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Cannon \x03disabled\x01.");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[X] Disable Cannon", false))
		{
			CannonOn[client] = 0;
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Cannon \x05enabled\x01.");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[None] Never Target", false))
		{
			CannonNeverTarget[client] = 1;
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Never target: \x05Commons\x01");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[Commons] Never Target", false))
		{
			CannonNeverTarget[client] = 2;
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Never target: \x05Specials\x01");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[Specials] Never Target", false))
		{
			CannonNeverTarget[client] = 3;
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Never target: \x05Witches\x01");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[Witches] Never Target", false))
		{
			CannonNeverTarget[client] = 4;
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Never target: \x05Tanks\x01");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[Tanks] Never Target", false))
		{
			CannonNeverTarget[client] = 5;
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Never target: \x05Commons/Specials\x01");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[Commons/Specials] Never Target", false))
		{
			CannonNeverTarget[client] = 6;
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Never target: \x05Commons/Witches\x01");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[Commons/Witches] Never Target", false))
		{
			CannonNeverTarget[client] = 7;
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Never target: \x05Witches/Tanks\x01");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[Witches/Tanks] Never Target", false))
		{
			CannonNeverTarget[client] = 0;
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Never target: \x05None\x01");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[Commons] Target First", false))
		{
			CannonTargetFirst[client] = 0;  // FIX: case 0 = Commons first
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Target priority: \x05Commons\x01");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[Specials] Target First", false))
		{
			CannonTargetFirst[client] = 1;  // FIX: case 1 = Specials first
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Target priority: \x05Specials\x01");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[Witches] Target First", false))
		{
			CannonTargetFirst[client] = 2;  // FIX: case 2 = Witches first
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Target priority: \x05Witches\x01");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[Tanks] Target First", false))
		{
			CannonTargetFirst[client] = 3;  // FIX: case 3 = Tanks first
			PrintToChat(client,"\x04[Shoulder Cannon]\x01 Target priority: \x05Tanks\x01");
			FakeClientCommand(client, "shouldercannon");
		}
		else if (StrEqual(name, "[+0.05] Fastest Fire Rate", false))
		{
			if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				if (IsPlayerAlive(client))
				{
					CannonRate[client] = 0.25;
					RemoveShoulderCannon(client);
					EquipShoulderCannon(client);
					PrintToChat(client,"\x04[Shoulder Cannon]\x01 Fire rate: \x05Slowest\x01");
				}
				else
				{
					PrintToChat(client,"\x04[Shoulder Cannon]\x01 You can't adjust this while you are dead.");
				}
				FakeClientCommand(client, "shouldercannon");
			}
		}
		else if (StrEqual(name, "[+0.10] Faster Fire Rate", false))
		{
			if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				if (IsPlayerAlive(client))
				{
					CannonRate[client] = 0.05;
					RemoveShoulderCannon(client);
					EquipShoulderCannon(client);
					PrintToChat(client,"\x04[Shoulder Cannon]\x01 Fire rate: \x05Fastest\x01");
				}
				else
				{
					PrintToChat(client,"\x04[Shoulder Cannon]\x01 You can't adjust this while you are dead.");
				}
				FakeClientCommand(client, "shouldercannon");
			}
		}
		else if (StrEqual(name, "[+0.15] Default Fire Rate", false))
		{
			if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				if (IsPlayerAlive(client))
				{
					CannonRate[client] = 0.10;
					RemoveShoulderCannon(client);
					EquipShoulderCannon(client);
					PrintToChat(client,"\x04[Shoulder Cannon]\x01 Fire rate: \x05Faster\x01");
				}
				else
				{
					PrintToChat(client,"\x04[Shoulder Cannon]\x01 You can't adjust this while you are dead.");
				}
				FakeClientCommand(client, "shouldercannon");
			}
		}
		else if (StrEqual(name, "[+0.20] Slower Fire Rate", false))
		{
			if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				if (IsPlayerAlive(client))
				{
					CannonRate[client] = 0.15;
					RemoveShoulderCannon(client);
					EquipShoulderCannon(client);
					PrintToChat(client,"\x04[Shoulder Cannon]\x01 Fire rate: \x05Default\x01");
				}
				else
				{
					PrintToChat(client,"\x04[Shoulder Cannon]\x01 You can't adjust this while you are dead.");
				}
				FakeClientCommand(client, "shouldercannon");
			}
		}
		else if (StrEqual(name, "[+0.25] Slowest Fire Rate", false))
		{
			if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				if (IsPlayerAlive(client))
				{
					CannonRate[client] = 0.20;
					RemoveShoulderCannon(client);
					EquipShoulderCannon(client);
					PrintToChat(client,"\x04[Shoulder Cannon]\x01 Fire rate: \x05Slower\x01");
				}
				else
				{
					PrintToChat(client,"\x04[Shoulder Cannon]\x01 You can't adjust this while you are dead.");
				}
				FakeClientCommand(client, "shouldercannon");
			}
		}
	}
}
