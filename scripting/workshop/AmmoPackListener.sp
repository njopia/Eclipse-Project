/**
 * AmmoPackListener.sp
 * Detecta uso/recogida de pilas de munición en L4D2 por:
 *  1) Evento item_pickup
 *  2) Evento player_use + lectura de targetid/classname
 *  3) SDKHook_Use sobre entidades de ammo/upgrade
 *
 * CVAR:
 *  ammolisten_debug (0/1)    -> activa logs y prints
 *
 * Comandos:
 *  sm_ammodebug <0/1>        -> cambia debug en runtime
 *  sm_testuse                -> raytrace frente al jugador y muestra classname (debug)
 */

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "AmmoPackListener",
    author      = "NJO • ChatGPT",
    description = "Detecta uso/recogida de pilas de munición en L4D2 (eventos + hooks)",
    version     = "1.0.0",
    url         = "https://forums.alliedmods.net/"
};

ConVar gCvarDebug;

static const char AMMO_CLASSES[][] =
{
    "weapon_ammo_spawn",        // pila verde (refill de munición)
    "upgrade_ammo_incendiary",  // caja de balas incendiarias
    "upgrade_ammo_explosive"    // caja de balas explosivas
};

public void OnPluginStart()
{
    gCvarDebug = CreateConVar("ammolisten_debug", "1", "Activa debug (0/1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    // Eventos del juego
    HookEvent("item_pickup", Event_ItemPickup, EventHookMode_Post);
    HookEvent("player_use",  Event_PlayerUse,  EventHookMode_Post);

    // Comandos utilitarios
    RegAdminCmd("sm_ammodebug", Cmd_AmmoDebug, ADMFLAG_GENERIC, "sm_ammodebug <0/1> - Activa/Desactiva debug");
    RegConsoleCmd("sm_testuse", Cmd_TestUse, "Raytrace frente al jugador y muestra classname (debug)");

    if (GetConVarBool(gCvarDebug))
        PrintToServer("[AmmoPackListener] Plugin cargado. Hooks instalados.");
}

/* -----------------------------------------------------------
 * 1) Hook entidad creada -> enganchar SDKHook_Use
 * ---------------------------------------------------------*/
public void OnEntityCreated(int entity, const char[] classname)
{
    if (!IsValidEntity(entity)) return;

    if (IsAmmoClass(classname))
    {
        SDKHook(entity, SDKHook_Use, OnAmmoEntityUse);
        DebugLog("SDKHook_Use enganchado para entidad %d (%s)", entity, classname);
    }
}

bool IsAmmoClass(const char[] classname)
{
    for (int i = 0; i < sizeof(AMMO_CLASSES); i++)
    {
        if (StrEqual(classname, AMMO_CLASSES[i], false))
            return true;
    }
    return false;
}

/* -----------------------------------------------------------
 * 2) SDKHook_Use -> uso real de la entidad
 * ---------------------------------------------------------*/
public Action OnAmmoEntityUse(int entity, int activator, int caller, UseType type, float value)
{
    if (activator >= 1 && activator <= MaxClients && IsClientInGame(activator))
    {
        char cls[64];
        GetEntityClassname(entity, cls, sizeof(cls));
        if (IsAmmoClass(cls))
        {
            PrintToChat(activator, "🔋pepe2 Has usado una pila de munición (%s).", cls);
            DebugLog("OnAmmoEntityUse: %N usó %s (ent=%d)", activator, cls, entity);

            // TODO: lógica personalizada (dar munición, efectos, etc.)
            // GiveFullAmmo(activator);
        }
    }
    return Plugin_Continue;
}

/* -----------------------------------------------------------
 * 3) Evento item_pickup -> recoger/activar item
 * ---------------------------------------------------------*/
public Action Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client)) return Plugin_Continue;

    char item[64];
    event.GetString("item", item, sizeof(item));

    if (StrContains(item, "ammo", false) != -1 || StrContains(item, "upgrade", false) != -1)
    {
        PrintToChat(client, "⚡ Has recogido/activado un item de munición (%s).", item);
        DebugLog("item_pickup: %N recogió %s", client, item);
        // GiveFullAmmo(client);
    }
    else
    {
        DebugLog("item_pickup: %N recogió %s (ignorado)", client, item);
    }

    return Plugin_Continue;
}

/* -----------------------------------------------------------
 * 4) Evento player_use -> leer targetid y classname
 * ---------------------------------------------------------*/
public Action Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client)) return Plugin_Continue;

    int target = event.GetInt("targetid");
    if (!IsValidEntity(target)) return Plugin_Continue;

    char cls[64];
    GetEntityClassname(target, cls, sizeof(cls));

    if (IsAmmoClass(cls) || StrContains(cls, "ammo", false) != -1 || StrContains(cls, "upgrade", false) != -1)
    {
        PrintToChat(client, "💥 pepe1 Has usado una pila de munición (%s).", cls);
        DebugLog("player_use: %N usó %s (ent=%d)", client, cls, target);
        // GiveFullAmmo(client);
    }
    else
    {
        DebugLog("player_use: %N usó %s (ignorado)", client, cls);
    }

    return Plugin_Continue;
}

/* -----------------------------------------------------------
 * Utilidades de debug
 * ---------------------------------------------------------*/
public Action Cmd_AmmoDebug(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[AmmoPackListener] ammolisten_debug = %d", GetConVarBool(gCvarDebug));
        return Plugin_Handled;
    }

    char buf[8];
    GetCmdArg(1, buf, sizeof(buf));
    int v = StringToInt(buf);
    SetConVarBool(gCvarDebug, v != 0);

    ReplyToCommand(client, "[AmmoPackListener] Debug -> %d", GetConVarBool(gCvarDebug));
    return Plugin_Handled;
}

public Action Cmd_TestUse(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;

    int ent = GetEntityInFront(client, 120.0);
    if (ent > MaxClients && IsValidEntity(ent))
    {
        char cls[64];
        GetEntityClassname(ent, cls, sizeof(cls));
        PrintToChat(client, "Ves: %s (ent=%d)", cls, ent);
        DebugLog("sm_testuse: %N ve %s (ent=%d)", client, cls, ent);
    }
    else
    {
        PrintToChat(client, "No hay entidad válida al frente.");
    }
    return Plugin_Handled;
}

int GetEntityInFront(int client, float maxDist = 120.0)
{
    float start[3], angles[3];
    GetClientEyePosition(client, start);
    GetClientEyeAngles(client, angles);

    float dir[3];
    GetAngleVectors(angles, dir, NULL_VECTOR, NULL_VECTOR);

    float end[3];
    end[0] = start[0] + dir[0] * maxDist;
    end[1] = start[1] + dir[1] * maxDist;
    end[2] = start[2] + dir[2] * maxDist;

    Handle trace = TR_TraceRayFilterEx(start, end, MASK_SOLID, RayType_EndPoint, TraceFilterSkipPlayers, client);
    int ent = -1;
    if (TR_DidHit(trace))
        ent = TR_GetEntityIndex(trace);

    CloseHandle(trace);
    return ent;
}

public bool TraceFilterSkipPlayers(int entity, int contentsMask, any data)
{
    // saltar jugadores; solo interesan entidades de mundo/items
    if (entity >= 1 && entity <= MaxClients) return false;
    return true;
}

stock void DebugLog(const char[] fmt, any ...)
{
    if (!GetConVarBool(gCvarDebug)) return;

    char msg[256];
    VFormat(msg, sizeof msg, fmt, 2);
    PrintToServer("[AmmoPackListener] %s", msg);
}

/* -----------------------------------------------------------
 * (Opcional) Dar munición completa - placeholder
 * Implementa tu propia lógica según tu mod (weapon slots, etc.)
 * ---------------------------------------------------------*/
stock void GiveFullAmmo(int client)
{
    // Ejemplo simple: forzar command; reemplaza por lógica específica si usas Left4DHooks para set de ammo
    // FakeClientCommand(client, "give ammo"); // (no existe en L4D2 vanilla)
    // Usa funciones de L4D2/Left4DHooks si manejas tipos por arma/slot.
    DebugLog("GiveFullAmmo: (placeholder) %N", client);
}
