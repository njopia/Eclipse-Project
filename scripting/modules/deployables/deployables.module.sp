#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === DEPLOYABLES MODULE ===
// Permite a sobrevivientes desplegar equipamiento
// de campo sin costo de currency, solo por nivel.
// Niveles requeridos (identicos al backup original):
//   Ammo Pile:       nivel  1
//   UV Light:        nivel  7
//   Healing Station: nivel 21
//   Defense Grid:    nivel 42
//==================================================

#define _DEPLOYABLES_MODULE_

#define DEPL_LVL_AMMO    1
#define DEPL_LVL_UV      7
#define DEPL_LVL_HS      21
#define DEPL_LVL_SENTRY  28
#define DEPL_LVL_DG      42

// =============================================================================
// COMANDO
// =============================================================================

public Action Cmd_Deployables(int client, int args)
{
	if (!IsSurvivor(client))
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Solo disponible para sobrevivientes.");
		return Plugin_Handled;
	}
	Deployables_ShowMenu(client);
	return Plugin_Handled;
}

// =============================================================================
// MENU
// =============================================================================

void Deployables_ShowMenu(int client)
{
	int playerLevel = Leveling_GetPlayerLevel(client);

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	Menu menu = new Menu(Deployables_MenuHandler);
	menu.SetTitle("Deployables\n%s | Nivel %d\n=================", name, playerLevel);

	char text[64];

	// Ammo Pile
	if (playerLevel >= DEPL_LVL_AMMO)
	{
		if (!AmmoPile_IsReady(client, AMMO_PILE))
			Format(text, sizeof(text), "Ammo Pile [CD]");
		else
			Format(text, sizeof(text), "Ammo Pile");
		menu.AddItem("ammo", text);
	}
	else
	{
		Format(text, sizeof(text), "Ammo Pile [Nivel %d]", DEPL_LVL_AMMO);
		menu.AddItem("locked_ammo", text, ITEMDRAW_DISABLED);
	}

	// UV Light
	if (playerLevel >= DEPL_LVL_UV)
	{
		if (UVLightTimer[client] > 0)
			Format(text, sizeof(text), "UV Light [%ds]", UVLightTimer[client]);
		else
			Format(text, sizeof(text), "UV Light");
		menu.AddItem("uv", text);
	}
	else
	{
		Format(text, sizeof(text), "UV Light [Nivel %d]", DEPL_LVL_UV);
		menu.AddItem("locked_uv", text, ITEMDRAW_DISABLED);
	}

	// Healing Station
	if (playerLevel >= DEPL_LVL_HS)
	{
		if (HSTimer[client] > 0)
			Format(text, sizeof(text), "Healing Station [%ds]", HSTimer[client]);
		else
			Format(text, sizeof(text), "Healing Station");
		menu.AddItem("hs", text);
	}
	else
	{
		Format(text, sizeof(text), "Healing Station [Nivel %d]", DEPL_LVL_HS);
		menu.AddItem("locked_hs", text, ITEMDRAW_DISABLED);
	}

	// Sentry Gun
#if defined _SENTRY_GUN_FEATURE_
	if (playerLevel >= DEPL_LVL_SENTRY)
	{
		int sCD = SentryGun_GetCooldownRemaining(client);
		if (SentryGun_IsActive(client))
			Format(text, sizeof(text), "Sentry Gun [Activa]");
		else if (sCD > 0)
			Format(text, sizeof(text), "Sentry Gun [CD: %ds]", sCD);
		else
			Format(text, sizeof(text), "Sentry Gun");
		menu.AddItem("sg", text);
	}
	else
	{
		Format(text, sizeof(text), "Sentry Gun [Nivel %d]", DEPL_LVL_SENTRY);
		menu.AddItem("locked_sg", text, ITEMDRAW_DISABLED);
	}
#endif

	// Defense Grid
	if (playerLevel >= DEPL_LVL_DG)
	{
		int dgCooldown = DefenseGrid_GetCooldown(client);
		int dgTime     = DefenseGrid_GetTimeRemaining(client);
		if (dgTime > 0)
			Format(text, sizeof(text), "Defense Grid [Activo: %ds]", dgTime);
		else if (dgCooldown > 0)
			Format(text, sizeof(text), "Defense Grid [CD: %ds]", dgCooldown);
		else
			Format(text, sizeof(text), "Defense Grid");
		menu.AddItem("dg", text);
	}
	else
	{
		Format(text, sizeof(text), "Defense Grid [Nivel %d]", DEPL_LVL_DG);
		menu.AddItem("locked_dg", text, ITEMDRAW_DISABLED);
	}

	menu.ExitButton = true;
	menu.Display(client, 20);
}

public int Deployables_MenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(item, info, sizeof(info));
		int playerLevel = Leveling_GetPlayerLevel(client);

		if (StrEqual(info, "ammo"))
		{
			if (playerLevel < DEPL_LVL_AMMO)
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Necesitas nivel \x05%d\x01 para Ammo Pile.", DEPL_LVL_AMMO);
				return 0;
			}
			if (!AmmoPile_IsReady(client, AMMO_PILE))
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Ammo Pile aun en cooldown.");
				return 0;
			}
			SpawnAmmoByName(client, "pile");
			PrintToChat(client, "\x04[Deployables]\x01 Ammo Pile desplegado.");
		}
		else if (StrEqual(info, "uv"))
		{
			if (playerLevel < DEPL_LVL_UV)
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Necesitas nivel \x05%d\x01 para UV Light.", DEPL_LVL_UV);
				return 0;
			}
			if (UVLightTimer[client] > 0)
			{
				PrintToChat(client, "\x04[Eclipse]\x01 UV Light en cooldown: \x05%ds\x01.", UVLightTimer[client]);
				return 0;
			}
			if (!(GetEntityFlags(client) & FL_ONGROUND))
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Debes estar en el suelo para desplegar UV Light.");
				return 0;
			}
			SpawnUVLight(client);
			UpdateUVLight(client);
			PrintToChat(client, "\x04[Deployables]\x01 UV Light desplegada.");
		}
		else if (StrEqual(info, "hs"))
		{
			if (playerLevel < DEPL_LVL_HS)
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Necesitas nivel \x05%d\x01 para Healing Station.", DEPL_LVL_HS);
				return 0;
			}
			if (HSTimer[client] > 0)
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Healing Station en cooldown: \x05%ds\x01.", HSTimer[client]);
				return 0;
			}
			if (!(GetEntityFlags(client) & FL_ONGROUND))
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Debes estar en el suelo para desplegar Healing Station.");
				return 0;
			}
			SpawnHealingStation(client);
			PrintToChat(client, "\x04[Deployables]\x01 Healing Station desplegada.");
		}
#if defined _SENTRY_GUN_FEATURE_
		else if (StrEqual(info, "sg"))
		{
			if (playerLevel < DEPL_LVL_SENTRY)
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Necesitas nivel \x05%d\x01 para Sentry Gun.", DEPL_LVL_SENTRY);
				return 0;
			}
			if (SentryGun_IsActive(client))
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Tu Sentry Gun ya esta desplegada.");
				return 0;
			}
			if (!SentryGun_CanDeploy(client))
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Sentry Gun en cooldown: \x05%ds\x01.", SentryGun_GetCooldownRemaining(client));
				return 0;
			}
			SentryGun_Deploy(client);
		}
#endif
		else if (StrEqual(info, "dg"))
		{
			if (playerLevel < DEPL_LVL_DG)
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Necesitas nivel \x05%d\x01 para Defense Grid.", DEPL_LVL_DG);
				return 0;
			}
			if (!DefenseGrid_CanDeploy(client)) return 0;
			DefenseGrid_Deploy(client);
		}
	}
	else if (action == MenuAction_End)
		delete menu;

	return 0;
}
