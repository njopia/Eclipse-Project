#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif
// Zombie Classes (para claridad al leer el codigo)
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_WITCH	7
#define ZOMBIECLASS_TANK	8
stock bool IsInfected(int entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "infected", false))
		{
			return true;
		}
	}
	return false;
}
stock bool IsWitch(int entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "witch", false))
			return true;
		return false;
	}
	return false;
}
stock bool IsTank(int entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank", false))
		{
			return true;
		}
	}
	return false;
}
stock bool IsSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}
stock bool IsSpectator(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1)
	{
		return true;
	}
	return false;
}
stock void L4D_SetPlayerSpeed(int client, float speed)
{
	if (!IsClientInGame(client))
		return;

	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
}
#include <sourcemod>
#include <sdktools>

// Flags para tipo de fade (segun engine)
#define FADE_IN	   (0x0001)
#define FADE_OUT   (0x0002)
#define FADE_PURGE (0x0010)

/**
 * Muestra un fade en pantalla al jugador.
 *
 * @param client    Jugador
 * @param r, g, b, a  Color (0–255)
 * @param duration   Duracion del fade (en segundos)
 * @param flags      Tipo (FADE_IN, FADE_OUT, etc.)
 */
stock void L4D_ScreenFade(int client, int r, int g, int b, int a, float duration, int flags = FADE_IN)
{
	if (client <= 0 || !IsClientInGame(client))
		return;

	Handle hFade = StartMessageOne("Fade", client);
	if (hFade == null)
		return;

	// El mensaje espera 4 shorts (duracion y hold)
	// luego 4 bytes de color y 2 bytes de flags

	int durationMS = RoundFloat(duration * 1000.0);
	int holdTimeMS = 0;	   // cuanto tiempo mantener antes de revertir

	// Duracion / hold
	BfWriteShort(hFade, durationMS);
	BfWriteShort(hFade, holdTimeMS);

	// Color RGBA
	BfWriteByte(hFade, r);
	BfWriteByte(hFade, g);
	BfWriteByte(hFade, b);
	BfWriteByte(hFade, a);

	// Flags
	BfWriteShort(hFade, flags);

	EndMessage();
}
