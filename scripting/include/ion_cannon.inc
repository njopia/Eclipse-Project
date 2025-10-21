/**
 * Ion Cannon API for Buy Systems
 * Version: 2.0.0
 *
 * Provides a public API for integrating the Ion Cannon with buy/shop systems.
 */

#if defined _ion_cannon_included
 #endinput
#endif
#define _ion_cannon_included

/**
 * Verifica si un cliente puede usar el Ion Cannon
 *
 * @param client    Índice del cliente
 * @return          true si puede usarlo, false si no
 */
native bool Ion_CanUse(int client);

/**
 * Activa el Ion Cannon para un cliente (llamado desde sistema de compras)
 *
 * @param client    Índice del cliente que compró el Ion
 * @return          true si se activó correctamente, false si falló
 */
native bool Ion_Activate(int client);

/**
 * Obtiene el tiempo de cooldown restante para un cliente
 *
 * @param client    Índice del cliente
 * @return          Segundos restantes de cooldown (0 = disponible)
 */
native float Ion_GetCooldown(int client);

/**
 * Obtiene las cargas restantes de un cliente
 *
 * @param client    Índice del cliente
 * @return          Número de cargas restantes
 */
native int Ion_GetCharges(int client);

/**
 * Establece las cargas de un cliente (útil para eventos especiales)
 *
 * @param client    Índice del cliente
 * @param charges   Número de cargas a establecer
 */
native void Ion_SetCharges(int client, int charges);

/**
 * Forward llamado cuando el Ion Cannon se activa
 *
 * @param client    Cliente que activó el Ion
 */
forward void Ion_OnActivate(int client);

/**
 * Forward llamado cuando el Ion Cannon termina
 *
 * @param client    Cliente cuyo Ion terminó
 * @param kills     Número de infectados eliminados
 */
forward void Ion_OnComplete(int client, int kills);

public SharedPlugin __pl_ion_cannon =
{
	name = "ion_cannon",
	file = "ion.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_ion_cannon_SetNTVOptional()
{
	MarkNativeAsOptional("Ion_CanUse");
	MarkNativeAsOptional("Ion_Activate");
	MarkNativeAsOptional("Ion_GetCooldown");
	MarkNativeAsOptional("Ion_GetCharges");
	MarkNativeAsOptional("Ion_SetCharges");
}
#endif
