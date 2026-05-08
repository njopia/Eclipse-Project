#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === HATS MODULE ===
// Sombrero cosmético persistido en cookie.
// El hat se equipa al hacer spawn y sigue al jugador.
// Se requiere nivel 50 (validado en specials.module.sp).
//==================================================

#define _HATS_MODULE_

#define HATS_COUNT 35
#define HATS_NONE  0

// Modelos nativos de L4D2 — sin archivos externos requeridos.
// Las rutas pueden ajustarse si alguna no existe en el servidor.
static const char g_sHatModels[HATS_COUNT][] =
{
	"models/props_junk/gnome.mdl",                   //  1 Gnome
	"models/w_models/weapons/w_eq_propane_tank.mdl", //  2 Propane Tank
	"models/props_equipment/oxygen_tank.mdl",         //  3 Oxygen Tank
	"models/props_urban/traffic_cone001.mdl",         //  4 Traffic Cone
	"models/props_junk/coffee_mug001.mdl",            //  5 Coffee Mug
	"models/props_junk/garbage_metalcan001a.mdl",     //  6 Metal Can
	"models/props_junk/rock001a.mdl",                 //  7 Rock
	"models/props_junk/cardboard_box001a.mdl",        //  8 Cardboard Box
	"models/props_junk/propane_tank001a.mdl",         //  9 Gas Tank
	"models/w_models/weapons/w_eq_gascan.mdl",        // 10 Gas Can
	"models/props_waterfront/dock_chair001.mdl",      // 11 Chair
	"models/props_urban/fire_hydrant001.mdl",         // 12 Fire Hydrant
	"models/props_industrial/barrel_fuel.mdl",        // 13 Barrel
	"models/props_junk/garbage_bag001a.mdl",          // 14 Garbage Bag
	"models/props_junk/flare.mdl",                   // 15 Flare
	"models/props_junk/food_can01.mdl",               // 16 Food Can
	"models/props_waterfront/dock_crate001.mdl",      // 17 Crate
	"models/props_urban/folding_chair001.mdl",        // 18 Folding Chair
	"models/props_junk/garbage_can001.mdl",           // 19 Garbage Can
	"models/props_equipment/police_radio.mdl",        // 20 Police Radio
	"models/props_junk/beer_bottle001.mdl",           // 21 Beer Bottle
	"models/props_junk/cola_bottle001.mdl",           // 22 Cola Bottle
	"models/props_equipment/first_aid_kit.mdl",       // 23 First Aid Kit
	"models/props_junk/rock002a.mdl",                 // 24 Rock 2
	"models/props_junk/garbage_bag001b.mdl",          // 25 Garbage Bag 2
	"models/props_junk/trash_metal_basket001.mdl",    // 26 Metal Basket
	"models/props_vehicles/car_tire.mdl",             // 27 Car Tire
	"models/props_foliage/tree_squirrel01.mdl",       // 28 Squirrel
	"models/props_junk/dumpster.mdl",                // 29 Dumpster
	"models/props_foliage/bush_deciduous001a.mdl",    // 30 Bush
	"models/props_junk/rock003a.mdl",                 // 31 Rock 3
	"models/props_junk/sofa_01.mdl",                  // 32 Sofa
	"models/props_urban/street_sign001.mdl",          // 33 Street Sign
	"models/props_misc/dollar_bill_stack.mdl",        // 34 Money Stack
	"models/props_junk/garbage_metalcan002a.mdl",     // 35 Metal Can 2
};

static const char g_sHatNames[HATS_COUNT][] =
{
	"Gnome",          "Propane Tank",  "Oxygen Tank",  "Traffic Cone", "Coffee Mug",
	"Metal Can",      "Rock",          "Cardboard Box","Gas Tank",     "Gas Can",
	"Chair",          "Fire Hydrant",  "Barrel",       "Garbage Bag",  "Flare",
	"Food Can",       "Crate",         "Folding Chair","Garbage Can",  "Police Radio",
	"Beer Bottle",    "Cola Bottle",   "First Aid Kit","Rock 2",       "Garbage Bag 2",
	"Metal Basket",   "Car Tire",      "Squirrel",     "Dumpster",     "Bush",
	"Rock 3",         "Sofa",          "Street Sign",  "Money Stack",  "Metal Can 2",
};

int    g_iHatEntRef[MAXPLAYERS + 1];
int    g_iSelectedHat[MAXPLAYERS + 1];
Handle g_hHatCookie = INVALID_HANDLE;

stock void Hats_GetName(int hatIndex, char[] buf, int maxlen)
{
	if (hatIndex > 0 && hatIndex <= HATS_COUNT)
		strcopy(buf, maxlen, g_sHatNames[hatIndex - 1]);
	else
		strcopy(buf, maxlen, "Ninguno");
}

// =============================================================================
// LIFECYCLE
// =============================================================================

void Hats_OnPluginStart()
{
	g_hHatCookie = RegClientCookie("eclipse_hat", "Selected hat cosmetic index", CookieAccess_Private);
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iHatEntRef[i]    = INVALID_ENT_REFERENCE;
		g_iSelectedHat[i]  = HATS_NONE;
	}
}

void Hats_OnMapStart()
{
	for (int i = 0; i < HATS_COUNT; i++)
		PrecacheModel(g_sHatModels[i], true);
}

void Hats_OnClientCookiesCached(int client)
{
	char buf[8];
	GetClientCookie(client, g_hHatCookie, buf, sizeof(buf));
	g_iSelectedHat[client] = (strlen(buf) > 0) ? StringToInt(buf) : HATS_NONE;
}

void Hats_OnClientDisconnect(int client)
{
	Hats_RemoveHat(client);
	g_iSelectedHat[client] = HATS_NONE;
	g_iHatEntRef[client]   = INVALID_ENT_REFERENCE;
}

void Hats_OnPlayerSpawn(int client)
{
	if (!IsSurvivor(client)) return;
	if (g_iSelectedHat[client] <= HATS_NONE) return;

	// Delay one tick so the player entity is fully initialized
	CreateTimer(0.1, _Hats_TimerSpawnDelay, GetClientUserId(client));
}

public Action _Hats_TimerSpawnDelay(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && IsSurvivor(client))
		Hats_SpawnHat(client, g_iSelectedHat[client]);
	return Plugin_Stop;
}

void Hats_OnPlayerDeath(int client)
{
	Hats_RemoveHat(client);
}

// =============================================================================
// CORE
// =============================================================================

void Hats_SpawnHat(int client, int hatIndex)
{
	Hats_RemoveHat(client);
	if (hatIndex <= 0 || hatIndex > HATS_COUNT) return;

	int ent = CreateEntityByName("prop_dynamic_override");
	if (ent < 1) return;

	DispatchKeyValue(ent, "model",          g_sHatModels[hatIndex - 1]);
	DispatchKeyValue(ent, "solid",          "0");
	DispatchKeyValue(ent, "disableshadows", "1");
	DispatchKeyValue(ent, "rendermode",     "0");
	DispatchSpawn(ent);

	// Position at eye level + small offset to sit on top of the head
	float vPos[3], vAng[3];
	GetClientEyePosition(client, vPos);
	GetClientAbsAngles(client, vAng);
	vPos[2] += 8.0;
	vAng[0]  = 0.0; // no pitch tilt

	TeleportEntity(ent, vPos, vAng, NULL_VECTOR);

	// Parent to player entity — hat follows body rotation (yaw)
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, client);

	g_iHatEntRef[client] = EntIndexToEntRef(ent);
}

void Hats_RemoveHat(int client)
{
	if (g_iHatEntRef[client] == INVALID_ENT_REFERENCE) return;
	int ent = EntRefToEntIndex(g_iHatEntRef[client]);
	if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
		RemoveEntity(ent);
	g_iHatEntRef[client] = INVALID_ENT_REFERENCE;
}

void Hats_SetHat(int client, int hatIndex)
{
	g_iSelectedHat[client] = hatIndex;

	char buf[8];
	IntToString(hatIndex, buf, sizeof(buf));
	SetClientCookie(client, g_hHatCookie, buf);

	if (!IsClientInGame(client) || !IsPlayerAlive(client) || !IsSurvivor(client)) return;

	if (hatIndex > HATS_NONE)
		Hats_SpawnHat(client, hatIndex);
	else
		Hats_RemoveHat(client);
}

// =============================================================================
// MENU
// =============================================================================

public Action Cmd_ChooseHat(int client, int args)
{
	if (!IsSurvivor(client))
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Solo disponible para sobrevivientes.");
		return Plugin_Handled;
	}
	if (Leveling_GetPlayerLevel(client) < SPEC_LVL_HATS)
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Necesitas nivel \x05%d\x01 para usar hats.", SPEC_LVL_HATS);
		return Plugin_Handled;
	}
	Hats_ShowMenu(client, 0);
	return Plugin_Handled;
}

void Hats_ShowMenu(int client, int page)
{
	Menu menu = new Menu(Hats_MenuHandler);
	menu.SetTitle("Elige tu Hat\nActual: %s", g_iSelectedHat[client] > HATS_NONE ? g_sHatNames[g_iSelectedHat[client] - 1] : "Ninguno");

	menu.AddItem("0", "-- Sin hat --");
	for (int i = 0; i < HATS_COUNT; i++)
	{
		char info[4];
		IntToString(i + 1, info, sizeof(info));
		menu.AddItem(info, g_sHatNames[i]);
	}

	menu.ExitButton = true;
	menu.DisplayAt(client, page, 30);
}

public int Hats_MenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[4];
		menu.GetItem(item, info, sizeof(info));
		int hatIndex = StringToInt(info);

		Hats_SetHat(client, hatIndex);

		if (hatIndex > HATS_NONE)
			PrintToChat(client, "\x04[Eclipse]\x01 Hat equipado: \x05%s\x01.", g_sHatNames[hatIndex - 1]);
		else
			PrintToChat(client, "\x04[Eclipse]\x01 Hat removido.");
	}
	else if (action == MenuAction_End)
		delete menu;

	return 0;
}
