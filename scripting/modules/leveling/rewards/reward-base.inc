#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === REWARD BASE INTERFACE ===
// Define la interfaz común para todas las recompensas
//==================================================

/**
 * Tipos de recompensas disponibles
 */
enum RewardType
{
	Reward_Passive,  // Habilidades pasivas siempre activas
	Reward_Active    // Habilidades activas que requieren activación
}

/**
 * Estructura de datos de una recompensa
 */
enum struct RewardData
{
	char name[64];           // Nombre de la recompensa
	char description[256];   // Descripción
	int requiredLevel;       // Nivel requerido
	RewardType type;         // Tipo de recompensa
	bool isEnabled[MAXPLAYERS + 1];  // Si está habilitada para cada jugador
}

/**
 * Interfaz que debe implementar cada reward module:
 *
 * - void RewardName_OnPluginStart()
 *   Inicializa CVars, hooks, etc.
 *
 * - void RewardName_OnClientConnect(int client)
 *   Resetea el estado del cliente
 *
 * - void RewardName_OnClientDisconnect(int client)
 *   Limpia recursos del cliente
 *
 * - void RewardName_OnPlayerSpawn(int client, int level)
 *   Aplica la recompensa al spawn (silencioso)
 *
 * - void RewardName_OnLevelUp(int client, int level)
 *   Aplica la recompensa al subir de nivel (con mensaje)
 *
 * - bool RewardName_IsUnlocked(int client, int level)
 *   Verifica si el jugador tiene la recompensa desbloqueada
 *
 * - void RewardName_OnPlayerRunCmd(int client, int &buttons, ...)
 *   (Opcional) Para recompensas que necesiten procesamiento por tick
 */
