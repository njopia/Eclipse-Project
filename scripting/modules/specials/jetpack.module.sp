#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === JETPACK MODULE ===
// Solo disponible durante el finale.
// Controles: mantener IN_JUMP mientras se está
// en el aire aplica impulso vertical.
// Cada uso consume un "charge"; recarga en cooldown.
// Se requiere nivel 49 (validado en specials.module.sp).
//==================================================

#define _JETPACK_MODULE_

#define JETPACK_MODEL     "models/props_junk/propane_tank001a.mdl"
#define JETPACK_CHARGES   5       // cargas por spawn
#define JETPACK_VELOCITY  350.0   // impulso vertical por charge
#define JETPACK_COOLDOWN  3.0     // segundos entre cargas
#define JETPACK_PARTICLE  "fire_medium_01"

bool  g_bJetpackEquipped[MAXPLAYERS + 1];
int   g_iJetpackCharges[MAXPLAYERS + 1];
float g_fJetpackNextUse[MAXPLAYERS + 1];
int   g_iJetpackPropRef[MAXPLAYERS + 1];
int   g_iJetpackPrevButtons[MAXPLAYERS + 1];

// =============================================================================
// LIFECYCLE
// =============================================================================

void Jetpack_OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bJetpackEquipped[i] = false;
		g_iJetpackCharges[i]  = 0;
		g_fJetpackNextUse[i]  = 0.0;
		g_iJetpackPropRef[i]  = INVALID_ENT_REFERENCE;
		g_iJetpackPrevButtons[i] = 0;
	}
}

void Jetpack_OnMapStart()
{
	PrecacheModel(JETPACK_MODEL, true);
	PrecacheParticle(JETPACK_PARTICLE);
}

void Jetpack_OnPlayerDeath(int client)
{
	Jetpack_Unequip(client);
}

void Jetpack_OnClientDisconnect(int client)
{
	Jetpack_Unequip(client);
}

// =============================================================================
// CORE
// =============================================================================

bool Jetpack_IsEquipped(int client)
{
	return g_bJetpackEquipped[client];
}

void Jetpack_Equip(int client)
{
	if (!DiffBase_IsFinaleActive())
	{
		PrintToChat(client, "\x04[Eclipse]\x01 El Jetpack solo esta disponible durante el finale.");
		return;
	}
	if (g_bJetpackEquipped[client])
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Ya tienes el Jetpack equipado.");
		return;
	}

	g_bJetpackEquipped[client] = true;
	g_iJetpackCharges[client]  = JETPACK_CHARGES;
	g_fJetpackNextUse[client]  = 0.0;

	_Jetpack_SpawnProp(client);

	PrintToChat(client, "\x04[Eclipse]\x01 Jetpack equipado! \x05%d\x01 cargas. Mantén SALTO en el aire para activar.", JETPACK_CHARGES);
}

void Jetpack_Unequip(int client)
{
	if (!g_bJetpackEquipped[client]) return;

	g_bJetpackEquipped[client] = false;
	g_iJetpackCharges[client]  = 0;
	g_fJetpackNextUse[client]  = 0.0;
	g_iJetpackPrevButtons[client] = 0;

	_Jetpack_RemoveProp(client);
}

void Jetpack_OnPlayerRunCmd(int client, int buttons)
{
	if (!g_bJetpackEquipped[client]) return;
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return;

	bool jumpHeld     = (buttons & IN_JUMP) != 0;
	bool jumpWasHeld  = (g_iJetpackPrevButtons[client] & IN_JUMP) != 0;
	bool justPressed  = jumpHeld && !jumpWasHeld;
	g_iJetpackPrevButtons[client] = buttons;

	if (!justPressed) return;
	if (GetEntityFlags(client) & FL_ONGROUND) return; // debe estar en el aire
	if (g_iJetpackCharges[client] <= 0)
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Sin cargas de Jetpack.");
		return;
	}

	float now = GetGameTime();
	if (now < g_fJetpackNextUse[client]) return; // cooldown activo

	// Aplicar impulso vertical
	float vVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
	vVel[2] = JETPACK_VELOCITY;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);

	// Consumir carga y registrar cooldown
	g_iJetpackCharges[client]--;
	g_fJetpackNextUse[client] = now + JETPACK_COOLDOWN;

	// Efecto de partícula en la posición del prop
	_Jetpack_EmitParticle(client);

	PrintHintText(client, "Jetpack: %d cargas restantes", g_iJetpackCharges[client]);
}

// =============================================================================
// HELPERS INTERNOS
// =============================================================================

static void _Jetpack_SpawnProp(int client)
{
	_Jetpack_RemoveProp(client);

	int ent = CreateEntityByName("prop_dynamic_override");
	if (ent < 1) return;

	DispatchKeyValue(ent, "model",          JETPACK_MODEL);
	DispatchKeyValue(ent, "solid",          "0");
	DispatchKeyValue(ent, "disableshadows", "1");
	DispatchSpawn(ent);

	// Posicionar en la espalda del jugador
	float vPos[3], vAng[3];
	GetClientAbsOrigin(client, vPos);
	GetClientAbsAngles(client, vAng);

	float fwd[3];
	GetAngleVectors(vAng, fwd, NULL_VECTOR, NULL_VECTOR);
	vPos[0] -= fwd[0] * 12.0;
	vPos[1] -= fwd[1] * 12.0;
	vPos[2] += 35.0; // altura media de la espalda
	vAng[0]  = 0.0;

	TeleportEntity(ent, vPos, vAng, NULL_VECTOR);

	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, client);

	g_iJetpackPropRef[client] = EntIndexToEntRef(ent);
}

static void _Jetpack_RemoveProp(int client)
{
	if (g_iJetpackPropRef[client] == INVALID_ENT_REFERENCE) return;
	int ent = EntRefToEntIndex(g_iJetpackPropRef[client]);
	if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
		RemoveEntity(ent);
	g_iJetpackPropRef[client] = INVALID_ENT_REFERENCE;
}

static void _Jetpack_EmitParticle(int client)
{
	float vPos[3], vAng[3];
	GetClientEyePosition(client, vPos);
	GetClientAbsAngles(client, vAng);

	float fwd[3];
	GetAngleVectors(vAng, fwd, NULL_VECTOR, NULL_VECTOR);
	vPos[0] -= fwd[0] * 12.0;
	vPos[1] -= fwd[1] * 12.0;
	vPos[2] -= 20.0; // por debajo de la espalda (exhausts van hacia abajo)

	int particle = CreateEntityByName("info_particle_system");
	if (particle < 1) return;

	char sPos[64];
	Format(sPos, sizeof(sPos), "%f %f %f", vPos[0], vPos[1], vPos[2]);
	DispatchKeyValue(particle, "origin",        sPos);
	DispatchKeyValue(particle, "effect_name",   JETPACK_PARTICLE);
	DispatchKeyValue(particle, "start_active",  "1");
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "Start");

	// Auto-destruir tras 1 segundo (efecto breve)
	CreateTimer(1.0, _Jetpack_KillParticle, EntIndexToEntRef(particle));
}

public Action _Jetpack_KillParticle(Handle timer, int entRef)
{
	int ent = EntRefToEntIndex(entRef);
	if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "Stop");
		RemoveEntity(ent);
	}
	return Plugin_Stop;
}
