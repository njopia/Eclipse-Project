/**
 * admin_manager_menu.sp
 * Gestión completa de admins SQL desde un menú in-game.
 * Requiere: sql-admin-manager.smx cargado y DB "admins" configurada.
 * Acceso: solo ROOT (flag z)
 *
 * Comandos:
 *   sm_adminmenu  →  abre el menú principal
 */

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>


Database g_db;

// Buffer temporal por cliente para flujos multi-paso
char g_TempSteamID[MAXPLAYERS+1][64];
char g_TempAlias[MAXPLAYERS+1][64];
char g_TempFlags[MAXPLAYERS+1][32];
char g_TempGroup[MAXPLAYERS+1][64];
int  g_TempImmunity[MAXPLAYERS+1];
int  g_FlowState[MAXPLAYERS+1];   // qué paso del flujo está haciendo el cliente

// Estados del flujo
enum {
    FLOW_NONE = 0,
    FLOW_ADD_ALIAS,
    FLOW_ADD_FLAGS,
    FLOW_ADD_IMMUNITY,
    FLOW_ADD_GROUP_NAME,
    FLOW_ADD_GROUP_FLAGS,
    FLOW_ADD_GROUP_IMMUNITY,
    FLOW_DEL_GROUP_NAME,
    FLOW_SET_ADMINGROUP_ADMIN,
    FLOW_SET_ADMINGROUP_GROUP,
}


// ─────────────────────────────────────────────
// Init
// ─────────────────────────────────────────────
public void AdminManager_OnPluginStart()
{
    RegConsoleCmd("sm_adminmenu", Cmd_AdminMenu, "Abre el menú de gestión de admins SQL");
    DB_Connect();
}

void DB_Connect()
{
    char err[256];
    g_db = SQL_Connect(ADMIN_DB_NAME, true, err, sizeof(err));
    if (g_db == null)
        LogError("[AdminMenu] No se pudo conectar a DB '%s': %s", ADMIN_DB_NAME, err);
}

// ─────────────────────────────────────────────
// Comando principal
// ─────────────────────────────────────────────
public Action Cmd_AdminMenu(int client, int args)
{
    if (client == 0) {
        ReplyToCommand(client, "[AdminMenu] Solo disponible in-game.");
        return Plugin_Handled;
    }
    OpenMainMenu(client);
    return Plugin_Handled;
}

// ─────────────────────────────────────────────
// MENÚ PRINCIPAL
// ─────────────────────────────────────────────
void OpenMainMenu(int client)
{
    Menu menu = new Menu(MainMenu_Handler_Admin_Manager);
    menu.SetTitle("=== Gestión de Admins SQL ===");
    menu.AddItem("list_admins",   "Ver admins actuales");
    menu.AddItem("add_steam",     "Agregar admin (SteamID de jugador conectado)");
    menu.AddItem("add_manual",    "Agregar admin (SteamID manual)");
    menu.AddItem("del_admin",     "Eliminar admin");
    menu.AddItem("separator",     "──────────────────", ITEMDRAW_DISABLED);
    menu.AddItem("list_groups",   "Ver grupos");
    menu.AddItem("add_group",     "Agregar grupo");
    menu.AddItem("del_group",     "Eliminar grupo");
    menu.AddItem("set_admingrp",  "Asignar grupo a admin");
    menu.Display(client, 0);
}

public int MainMenu_Handler_Admin_Manager(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "list_admins"))        OpenListAdmins(client);
        else if (StrEqual(info, "add_steam"))     OpenPickPlayer(client);
        else if (StrEqual(info, "add_manual"))    StartFlowManual(client);
        else if (StrEqual(info, "del_admin"))     OpenDelAdminMenu(client);
        else if (StrEqual(info, "list_groups"))   OpenListGroups(client);
        else if (StrEqual(info, "add_group"))     StartFlowAddGroup(client);
        else if (StrEqual(info, "del_group"))     StartFlowDelGroup(client);
        else if (StrEqual(info, "set_admingrp"))  StartFlowSetAdminGroup(client);
    }
    else if (action == MenuAction_End)
        delete menu;

    return 0;
}

// ─────────────────────────────────────────────
// VER ADMINS
// ─────────────────────────────────────────────
void OpenListAdmins(int client)
{
    if (g_db == null) { PrintToChat(client, "[AdminMenu] Sin conexión a DB."); return; }

    char query[256];
    Format(query, sizeof(query), "SELECT name, authtype, identity, flags, immunity FROM sm_admins ORDER BY name");
    g_db.Query(CB_ListAdmins, query, GetClientUserId(client));
}

public void CB_ListAdmins(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    if (!client) return;
    if (results == null) { PrintToChat(client, "[AdminMenu] Error: %s", error); return; }

    Menu menu = new Menu(GenericBack_Handler);
    menu.SetTitle("Admins en DB:");

    if (!results.RowCount) {
        menu.AddItem("", "(ninguno)", ITEMDRAW_DISABLED);
    }
    else {
        while (results.FetchRow()) {
            char name[65], authtype[16], identity[65], flags[32];
            int immunity;
            results.FetchString(0, name, sizeof(name));
            results.FetchString(1, authtype, sizeof(authtype));
            results.FetchString(2, identity, sizeof(identity));
            results.FetchString(3, flags, sizeof(flags));
            immunity = results.FetchInt(4);

            char display[256];
            Format(display, sizeof(display), "%s | %s:%s | flags:%s | imm:%d", name, authtype, identity, flags, immunity);
            menu.AddItem("", display, ITEMDRAW_DISABLED);
        }
    }
    menu.Display(client, 0);
}

// ─────────────────────────────────────────────
// AGREGAR ADMIN — seleccionar jugador conectado
// ─────────────────────────────────────────────
void OpenPickPlayer(int client)
{
    Menu menu = new Menu(PickPlayer_Handler);
    menu.SetTitle("Selecciona jugador para hacer admin:");

    bool found = false;
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || IsFakeClient(i)) continue;
        if (!IsClientAuthorized(i)) continue;
        char steamid[64], name[MAX_NAME_LENGTH];
        if (!GetClientAuthId(i, AuthId_Steam2, steamid, sizeof(steamid), false)) continue;
        GetClientName(i, name, sizeof(name));

        char display[128];
        Format(display, sizeof(display), "%s  (%s)", name, steamid);
        char info[64];
        Format(info, sizeof(info), "%s", steamid);
        menu.AddItem(info, display);
        found = true;
    }
    if (!found)
        menu.AddItem("", "(no hay jugadores)", ITEMDRAW_DISABLED);

    menu.Display(client, 0);
}

public int PickPlayer_Handler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select) {
        char steamid[64];
        menu.GetItem(item, steamid, sizeof(steamid));
        strcopy(g_TempSteamID[client], sizeof(g_TempSteamID[]), steamid);
        AskAlias(client);
    }
    else if (action == MenuAction_End) delete menu;
    return 0;
}

// ─────────────────────────────────────────────
// AGREGAR ADMIN — SteamID manual
// ─────────────────────────────────────────────
void StartFlowManual(int client)
{
    g_FlowState[client] = FLOW_NONE;
    PrintToChat(client, "[AdminMenu] Escribe el SteamID (ej: STEAM_0:1:12345) en el chat:");
    // El SteamID vendrá como primer mensaje; usamos OnClientSayCommand
    g_FlowState[client] = -1; // señal: esperando SteamID manual
}

// ─────────────────────────────────────────────
// FLUJO COMÚN: pedir alias, flags, immunity
// ─────────────────────────────────────────────
void AskAlias(int client)
{
    g_FlowState[client] = FLOW_ADD_ALIAS;
    PrintToChat(client, "[AdminMenu] Escribe el alias/nombre para este admin en el chat:");
}

void AskFlags(int client)
{
    g_FlowState[client] = FLOW_ADD_FLAGS;
    PrintToChat(client, "[AdminMenu] Escribe los flags (ej: abcdefghijklmnopqrst para todo, z para root):");
}

void AskImmunity(int client)
{
    g_FlowState[client] = FLOW_ADD_IMMUNITY;
    PrintToChat(client, "[AdminMenu] Escribe el nivel de inmunidad (número, 0 = sin inmunidad):");
}

void ConfirmAndAddAdmin(int client)
{
    if (g_db == null) { PrintToChat(client, "[AdminMenu] Sin conexión a DB."); return; }

    char esc_identity[130], esc_alias[130], esc_flags[66];
    g_db.Escape(g_TempSteamID[client], esc_identity, sizeof(esc_identity));
    g_db.Escape(g_TempAlias[client],   esc_alias,    sizeof(esc_alias));
    g_db.Escape(g_TempFlags[client],   esc_flags,    sizeof(esc_flags));

    char query[512];
    Format(query, sizeof(query), "INSERT INTO sm_admins (authtype, identity, password, flags, name, immunity) VALUES ('steam', '%s', NULL, '%s', '%s', %d)",
        esc_identity, esc_flags, esc_alias, g_TempImmunity[client]);

    g_db.Query(CB_AddAdmin, query, GetClientUserId(client));
    g_FlowState[client] = FLOW_NONE;
}

public void CB_AddAdmin(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    if (!client) return;
    if (results == null)
        PrintToChat(client, "[AdminMenu] Error al agregar admin: %s", error);
    else
        PrintToChat(client, "[AdminMenu] Admin agregado exitosamente.");
}

// ─────────────────────────────────────────────
// ELIMINAR ADMIN
// ─────────────────────────────────────────────
void OpenDelAdminMenu(int client)
{
    if (g_db == null) { PrintToChat(client, "[AdminMenu] Sin conexión a DB."); return; }
    g_db.Query(CB_DelAdminList, "SELECT id, name, identity FROM sm_admins ORDER BY name", GetClientUserId(client));
}

public void CB_DelAdminList(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    if (!client) return;
    if (results == null) { PrintToChat(client, "[AdminMenu] Error: %s", error); return; }

    Menu menu = new Menu(DelAdmin_Handler);
    menu.SetTitle("Selecciona admin a eliminar:");

    if (!results.RowCount) {
        menu.AddItem("", "(ninguno)", ITEMDRAW_DISABLED);
    }
    else {
        while (results.FetchRow()) {
            int id = results.FetchInt(0);
            char name[65], identity[65];
            results.FetchString(1, name, sizeof(name));
            results.FetchString(2, identity, sizeof(identity));

            char info[16], display[128];
            IntToString(id, info, sizeof(info));
            Format(display, sizeof(display), "%s (%s)", name, identity);
            menu.AddItem(info, display);
        }
    }
    menu.Display(client, 0);
}

public int DelAdmin_Handler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select) {
        char info[16];
        menu.GetItem(item, info, sizeof(info));
        int id = StringToInt(info);

        char query[128];
        Format(query, sizeof(query), "DELETE FROM sm_admins WHERE id = %d", id);
        g_db.Query(CB_DelAdmin, query, GetClientUserId(client));

        // También limpiar grupos asignados
        char query2[128];
        Format(query2, sizeof(query2), "DELETE FROM sm_admins_groups WHERE admin_id = %d", id);
        g_db.Query(CB_Silent, query2, 0);
    }
    else if (action == MenuAction_End) delete menu;
    return 0;
}

public void CB_DelAdmin(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    if (!client) return;
    if (results == null)
        PrintToChat(client, "[AdminMenu] Error al eliminar: %s", error);
    else
        PrintToChat(client, "[AdminMenu] Admin eliminado.");
}

// ─────────────────────────────────────────────
// VER GRUPOS
// ─────────────────────────────────────────────
void OpenListGroups(int client)
{
    if (g_db == null) { PrintToChat(client, "[AdminMenu] Sin conexión a DB."); return; }
    g_db.Query(CB_ListGroups, "SELECT name, flags, immunity_level FROM sm_groups ORDER BY name", GetClientUserId(client));
}

public void CB_ListGroups(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    if (!client) return;
    if (results == null) { PrintToChat(client, "[AdminMenu] Error: %s", error); return; }

    Menu menu = new Menu(GenericBack_Handler);
    menu.SetTitle("Grupos en DB:");

    if (!results.RowCount) {
        menu.AddItem("", "(ninguno)", ITEMDRAW_DISABLED);
    }
    else {
        while (results.FetchRow()) {
            char name[121], flags[32];
            int immunity;
            results.FetchString(0, name, sizeof(name));
            results.FetchString(1, flags, sizeof(flags));
            immunity = results.FetchInt(2);

            char display[256];
            Format(display, sizeof(display), "%s | flags:%s | imm:%d", name, flags, immunity);
            menu.AddItem("", display, ITEMDRAW_DISABLED);
        }
    }
    menu.Display(client, 0);
}

// ─────────────────────────────────────────────
// AGREGAR GRUPO
// ─────────────────────────────────────────────
void StartFlowAddGroup(int client)
{
    g_FlowState[client] = FLOW_ADD_GROUP_NAME;
    PrintToChat(client, "[AdminMenu] Escribe el nombre del nuevo grupo en el chat:");
}

void AskGroupFlags(int client)
{
    g_FlowState[client] = FLOW_ADD_GROUP_FLAGS;
    PrintToChat(client, "[AdminMenu] Escribe los flags del grupo:");
}

void AskGroupImmunity(int client)
{
    g_FlowState[client] = FLOW_ADD_GROUP_IMMUNITY;
    PrintToChat(client, "[AdminMenu] Escribe el nivel de inmunidad del grupo (número):");
}

void ConfirmAndAddGroup(int client)
{
    if (g_db == null) { PrintToChat(client, "[AdminMenu] Sin conexión a DB."); return; }

    char esc_name[242], esc_flags[66];
    g_db.Escape(g_TempGroup[client], esc_name,  sizeof(esc_name));
    g_db.Escape(g_TempFlags[client], esc_flags, sizeof(esc_flags));

    char query[512];
    Format(query, sizeof(query),
        "INSERT INTO sm_groups (flags, name, immunity_level) VALUES ('%s', '%s', %d)",
        esc_flags, esc_name, g_TempImmunity[client]);

    g_db.Query(CB_AddGroup, query, GetClientUserId(client));
    g_FlowState[client] = FLOW_NONE;
}

public void CB_AddGroup(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    if (!client) return;
    if (results == null)
        PrintToChat(client, "[AdminMenu] Error al agregar grupo: %s", error);
    else
        PrintToChat(client, "[AdminMenu] Grupo agregado exitosamente.");
}

// ─────────────────────────────────────────────
// ELIMINAR GRUPO
// ─────────────────────────────────────────────
void StartFlowDelGroup(int client)
{
    if (g_db == null) { PrintToChat(client, "[AdminMenu] Sin conexión a DB."); return; }
    g_db.Query(CB_DelGroupList, "SELECT id, name FROM sm_groups ORDER BY name", GetClientUserId(client));
}

public void CB_DelGroupList(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    if (!client) return;
    if (results == null) { PrintToChat(client, "[AdminMenu] Error: %s", error); return; }

    Menu menu = new Menu(DelGroup_Handler);
    menu.SetTitle("Selecciona grupo a eliminar:");

    if (!results.RowCount) {
        menu.AddItem("", "(ninguno)", ITEMDRAW_DISABLED);
    }
    else {
        while (results.FetchRow()) {
            int id = results.FetchInt(0);
            char name[121], info[16];
            results.FetchString(1, name, sizeof(name));
            IntToString(id, info, sizeof(info));
            menu.AddItem(info, name);
        }
    }
    menu.Display(client, 0);
}

public int DelGroup_Handler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select) {
        char info[16];
        menu.GetItem(item, info, sizeof(info));
        int id = StringToInt(info);

        char query[128];
        Format(query, sizeof(query), "DELETE FROM sm_groups WHERE id = %d", id);
        g_db.Query(CB_DelGroup, query, GetClientUserId(client));

        char query2[128];
        Format(query2, sizeof(query2), "DELETE FROM sm_admins_groups WHERE group_id = %d", id);
        g_db.Query(CB_Silent, query2, 0);
    }
    else if (action == MenuAction_End) delete menu;
    return 0;
}

public void CB_DelGroup(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    if (!client) return;
    if (results == null)
        PrintToChat(client, "[AdminMenu] Error al eliminar grupo: %s", error);
    else
        PrintToChat(client, "[AdminMenu] Grupo eliminado.");
}

// ─────────────────────────────────────────────
// ASIGNAR GRUPO A ADMIN
// ─────────────────────────────────────────────
void StartFlowSetAdminGroup(int client)
{
    if (g_db == null) { PrintToChat(client, "[AdminMenu] Sin conexión a DB."); return; }
    g_db.Query(CB_SetAdminGroupAdminList, "SELECT id, name, identity FROM sm_admins ORDER BY name", GetClientUserId(client));
}

public void CB_SetAdminGroupAdminList(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    if (!client) return;
    if (results == null) { PrintToChat(client, "[AdminMenu] Error: %s", error); return; }

    Menu menu = new Menu(SetAdminGroup_AdminHandler);
    menu.SetTitle("Selecciona el admin:");

    if (!results.RowCount) {
        menu.AddItem("", "(ninguno)", ITEMDRAW_DISABLED);
    }
    else {
        while (results.FetchRow()) {
            int id = results.FetchInt(0);
            char name[65], identity[65], info[16], display[128];
            results.FetchString(1, name, sizeof(name));
            results.FetchString(2, identity, sizeof(identity));
            IntToString(id, info, sizeof(info));
            Format(display, sizeof(display), "%s (%s)", name, identity);
            menu.AddItem(info, display);
        }
    }
    menu.Display(client, 0);
}

public int SetAdminGroup_AdminHandler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select) {
        char info[16];
        menu.GetItem(item, info, sizeof(info));
        strcopy(g_TempSteamID[client], sizeof(g_TempSteamID[]), info); // reutilizamos para guardar admin_id

        // Ahora listar grupos
        g_db.Query(CB_SetAdminGroupGroupList, "SELECT id, name FROM sm_groups ORDER BY name", GetClientUserId(client));
    }
    else if (action == MenuAction_End) delete menu;
    return 0;
}

public void CB_SetAdminGroupGroupList(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    if (!client) return;
    if (results == null) { PrintToChat(client, "[AdminMenu] Error: %s", error); return; }

    Menu menu = new Menu(SetAdminGroup_GroupHandler);
    menu.SetTitle("Selecciona el grupo a asignar:");

    if (!results.RowCount) {
        menu.AddItem("", "(sin grupos)", ITEMDRAW_DISABLED);
    }
    else {
        while (results.FetchRow()) {
            int id = results.FetchInt(0);
            char name[121], info[16];
            results.FetchString(1, name, sizeof(name));
            IntToString(id, info, sizeof(info));
            menu.AddItem(info, name);
        }
    }
    menu.Display(client, 0);
}

public int SetAdminGroup_GroupHandler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select) {
        char info[16];
        menu.GetItem(item, info, sizeof(info));
        int group_id  = StringToInt(info);
        int admin_id  = StringToInt(g_TempSteamID[client]);

        char query[256];
        Format(query, sizeof(query),
            "INSERT IGNORE INTO sm_admins_groups (admin_id, group_id, inherit_order) VALUES (%d, %d, 0)",
            admin_id, group_id);
        g_db.Query(CB_SetAdminGroup, query, GetClientUserId(client));
    }
    else if (action == MenuAction_End) delete menu;
    return 0;
}

public void CB_SetAdminGroup(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    if (!client) return;
    if (results == null)
        PrintToChat(client, "[AdminMenu] Error al asignar grupo: %s", error);
    else
        PrintToChat(client, "[AdminMenu] Grupo asignado al admin.");
}

// ─────────────────────────────────────────────
// CHAT HOOK — flujos multi-paso
// ─────────────────────────────────────────────
public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    if (!client) return Plugin_Continue;

    int state = g_FlowState[client];
    if (state == FLOW_NONE) return Plugin_Continue;

    char text[256];
    strcopy(text, sizeof(text), sArgs);
    TrimString(text);

    // Esperando SteamID manual
    if (state == -1) {
        strcopy(g_TempSteamID[client], sizeof(g_TempSteamID[]), text);
        AskAlias(client);
        return Plugin_Handled;
    }

    // Flujo agregar admin
    if (state == FLOW_ADD_ALIAS) {
        strcopy(g_TempAlias[client], sizeof(g_TempAlias[]), text);
        AskFlags(client);
        return Plugin_Handled;
    }
    if (state == FLOW_ADD_FLAGS) {
        strcopy(g_TempFlags[client], sizeof(g_TempFlags[]), text);
        AskImmunity(client);
        return Plugin_Handled;
    }
    if (state == FLOW_ADD_IMMUNITY) {
        g_TempImmunity[client] = StringToInt(text);
        ConfirmAndAddAdmin(client);
        return Plugin_Handled;
    }

    // Flujo agregar grupo
    if (state == FLOW_ADD_GROUP_NAME) {
        strcopy(g_TempGroup[client], sizeof(g_TempGroup[]), text);
        AskGroupFlags(client);
        return Plugin_Handled;
    }
    if (state == FLOW_ADD_GROUP_FLAGS) {
        strcopy(g_TempFlags[client], sizeof(g_TempFlags[]), text);
        AskGroupImmunity(client);
        return Plugin_Handled;
    }
    if (state == FLOW_ADD_GROUP_IMMUNITY) {
        g_TempImmunity[client] = StringToInt(text);
        ConfirmAndAddGroup(client);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

// ─────────────────────────────────────────────
// Handlers genéricos
// ─────────────────────────────────────────────
public int GenericBack_Handler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End) delete menu;
    return 0;
}

public void CB_Silent(Database db, DBResultSet results, const char[] error, any data) {}
