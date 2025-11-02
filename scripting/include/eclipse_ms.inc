/**
 * Eclipse Management System - Include File
 * Permite a otros plugins acceder a los datos del sistema de leveling
 */

#if defined _eclipse_ms_included
	#endinput
#endif
#define _eclipse_ms_included

/**
 * Obtiene el nivel actual del jugador
 *
 * @param client    Índice del cliente
 * @return          Nivel del jugador (0 si es inválido)
 */
native int EMS_GetPlayerLevel(int client);

/**
 * Obtiene el XP actual del jugador dentro de su nivel actual
 *
 * @param client    Índice del cliente
 * @return          XP actual del jugador
 */
native int EMS_GetPlayerCurrentXP(int client);

/**
 * Obtiene el XP total acumulado del jugador desde el inicio
 *
 * @param client    Índice del cliente
 * @return          XP total acumulado
 */
native int EMS_GetPlayerTotalXP(int client);

/**
 * Obtiene el XP requerido para alcanzar el siguiente nivel
 *
 * @param client    Índice del cliente
 * @return          XP necesario para subir de nivel
 */
native int EMS_GetXPForNextLevel(int client);

/**
 * Obtiene el progreso del jugador hacia el siguiente nivel
 *
 * @param client    Índice del cliente
 * @return          Porcentaje de progreso (0-100)
 */
native int EMS_GetLevelProgress(int client);

/**
 * Obtiene la moneda/puntos actuales del jugador
 *
 * @param client    Índice del cliente
 * @return          Cantidad de currency/puntos
 */
native int EMS_GetPlayerCurrency(int client);

public SharedPlugin __pl_eclipse_ms = 
{
	name = "eclipse_ms",
	file = "Eclipse Management System.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_eclipse_ms_SetNTVOptional()
{
	MarkNativeAsOptional("EMS_GetPlayerLevel");
	MarkNativeAsOptional("EMS_GetPlayerCurrentXP");
	MarkNativeAsOptional("EMS_GetPlayerTotalXP");
	MarkNativeAsOptional("EMS_GetXPForNextLevel");
	MarkNativeAsOptional("EMS_GetLevelProgress");
	MarkNativeAsOptional("EMS_GetPlayerCurrency");
}
#endif