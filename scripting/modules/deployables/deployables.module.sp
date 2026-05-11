#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === DEPLOYABLES MODULE ===
// Permite a sobrevivientes desplegar equipamiento.
// Desbloqueados por defecto (sin nivel), se compran en !buy.
//==================================================

#define _DEPLOYABLES_MODULE_

// Los niveles ahora son 1 para permitir acceso inmediato
#define DEPL_LVL_AMMO    1
#define DEPL_LVL_UV      1
#define DEPL_LVL_HS      1
#define DEPL_LVL_SENTRY  1
#define DEPL_LVL_DG      1

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
	// En lugar de su propio menu, abrimos el de la tienda para que paguen puntos
	DeployablesMenu(client); 
	return Plugin_Handled;
}
